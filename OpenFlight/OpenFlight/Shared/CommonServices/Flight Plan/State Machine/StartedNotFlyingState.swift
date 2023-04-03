//    Copyright (C) 2021 Parrot Drones SAS
//
//    Redistribution and use in source and binary forms, with or without
//    modification, are permitted provided that the following conditions
//    are met:
//    * Redistributions of source code must retain the above copyright
//      notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright
//      notice, this list of conditions and the following disclaimer in
//      the documentation and/or other materials provided with the
//      distribution.
//    * Neither the name of the Parrot Company nor the names
//      of its contributors may be used to endorse or promote products
//      derived from this software without specific prior written
//      permission.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
//    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
//    PARROT COMPANY BE LIABLE FOR ANY DIRECT, INDIRECT,
//    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
//    OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
//    AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
//    OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
//    SUCH DAMAGE.

import GameKit
import GroundSdk

private extension ULogTag {
    static let tag = ULogTag(name: "FPStartedNotFlyingState")
}

public protocol StartedNotFlyingStateDelegate: AnyObject {

    func mavlinkGenerationStarted(flightPlan: FlightPlanModel)

    func mavlinkSendingStarted(flightPlan: FlightPlanModel)

    func handleMavlinkGenerationError(flightPlan: FlightPlanModel, _ error: Error)

    func handleMavlinkSendingError(flightPlan: FlightPlanModel, _ error: Error)

    func handleMavlinkSendingSuccess(flightPlan: FlightPlanModel, commands: [MavlinkStandard.MavlinkCommand])

    /// Handles execution starting prohibited.
    ///
    /// - Parameters:
    ///   - flightPlan: the flight plan
    ///   - reason: the start prohibited reason
    func handleStartProhibited(for flightPlan: FlightPlanModel, reason: StartProhibitedReason)
}

/// Reasons preventing to start an execution.
public enum StartProhibitedReason: Error {
    /// The first way point is too far from the current Drone location.
    case firstWayPointTooFar
}

open class StartedNotFlyingState: GKState {

    /// Plan File State.
    enum PlanFileState { case generating, uploading }

    private weak var delegate: StartedNotFlyingStateDelegate?
    private let flightPlanManager: FlightPlanManager
    private let projectManager: ProjectManager
    private let planFileGenerator: PlanFileGenerator
    private let planFileSender: PlanFileDroneSender
    private let filesManager: FlightPlanFilesManager
    private let locationTracker: LocationsTracker
    private var stopped = false
    private var planFileProcessingTask: Task<Void, Never>?

    var flightPlan: FlightPlanModel!

    required public init(delegate: StartedNotFlyingStateDelegate,
                         flightPlanManager: FlightPlanManager,
                         projectManager: ProjectManager,
                         planFileGenerator: PlanFileGenerator,
                         planFileSender: PlanFileDroneSender,
                         filesManager: FlightPlanFilesManager,
                         locationTracker: LocationsTracker) {
        self.delegate = delegate
        self.flightPlanManager = flightPlanManager
        self.projectManager = projectManager
        self.planFileGenerator = planFileGenerator
        self.planFileSender = planFileSender
        self.filesManager = filesManager
        self.locationTracker = locationTracker
        super.init()
    }

    open override func didEnter(from previousState: GKState?) {
        stopped = false

        // if flightPlan is editable, we duplicate the editable flight plan to use like execution.
        if flightPlan.pictorModel.state == .editable {
            // set and get the next execution rank of the flight plan's project
            let nextExecutionRank = projectManager.setNextExecutionRank(forProjectId: flightPlan.pictorModel.projectUuid)
            // duplicate the flightplan to use like execution
            var newFlightPlan = flightPlanManager.newFlightPlan(basedOn: flightPlan)
            // set the execution rank
            newFlightPlan.executionRank = nextExecutionRank
            // update custom title with executionRank
            newFlightPlan.pictorModel.name = projectManager.executionCustomTitle(for: nextExecutionRank)

            // `newFlightPlan` is no more the project's editable FP.
            // It's the new execution, with the updated custom title, which must be considered as `.flying` state.
            flightPlan = flightPlanManager.update(flightplan: newFlightPlan, with: .flying)
        }

        // Start File Processing.
        planFileProcessingTask = Task {
            ULog.i(.tag, "Generating Plan File")
            var planFileState = PlanFileState.generating
            await handleMavlinkGenerationStarted(for: flightPlan)
            do {
                // Generate the Plan.
                let planGenerationResult = try await planFileGenerator.generatePlan(for: flightPlan)
                try Task.checkCancellation()
                // Ensure nothing prevents to start the FP (e.g. first WP too far).
                try ensureExecutionIsPossible(for: planGenerationResult.plan)
                ULog.i(.tag, "Uploading Plan File to the Drone")
                planFileState = .uploading
                try await planFileSender.sendToDevice(planGenerationResult.path,
                                                      customFlightPlanId: flightPlan.uuid)
                try Task.checkCancellation()
                // Inform about FP has been successfully uploaded to the Drone.
                await handlePlanFileSent(for: planGenerationResult.flightPlan,
                                         with: planGenerationResult.commands)
            } catch is CancellationError {
                // Don't call delegate error in case of Task Cancellation.
            } catch let reason as StartProhibitedReason {
                await handleStartProhibited(for: flightPlan, reason: reason)
            } catch {
                await handlePlanFileError(error, for: planFileState, flightPlan: flightPlan)
            }
        }
    }

    open func flightPlanWasUpdated(_ flightPlan: FlightPlanModel) {
        self.flightPlan = flightPlan
    }

    open override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is StartedFlyingState.Type
            || stateClass is EditableState.Type
            || stateClass is IdleState.Type
    }

    open override func willExit(to nextState: GKState) {
        stop()
        planFileProcessingTask = nil
    }

    open func stop() {
        planFileSender.cleanup()
        planFileProcessingTask?.cancel()
        stopped = true
        // The Plan file is no more needed, it can be removed from the filesystem.
        try? filesManager.removePlanFile(of: flightPlan)
    }
}

// MARK: - StartedNotFlyingStateDelegate
// Handle delegate calls on Main thread as it was done previously.
extension StartedNotFlyingState {
    @MainActor private func handleMavlinkGenerationStarted(for flightPlan: FlightPlanModel) {
        delegate?.mavlinkGenerationStarted(flightPlan: flightPlan)
    }

    @MainActor private func handlePlanFileError(_ error: Error, for state: PlanFileState, flightPlan: FlightPlanModel) {
        switch state {
        case .generating:
            delegate?.handleMavlinkGenerationError(flightPlan: flightPlan, error)
        case .uploading:
            try? filesManager.removePlanFile(of: flightPlan)
            delegate?.handleMavlinkSendingError(flightPlan: flightPlan, error)
        }
    }

    @MainActor private func handlePlanFileSent(for flightPlan: FlightPlanModel, with commands: [MavlinkStandard.MavlinkCommand]) {
        delegate?.handleMavlinkSendingSuccess(flightPlan: flightPlan,
                                              commands: commands)
    }

    @MainActor private func handleStartProhibited(for flightPlan: FlightPlanModel, reason: StartProhibitedReason) {
        delegate?.handleStartProhibited(for: flightPlan, reason: reason)
    }
}

// MARK: - Start Prohibition extension.
private extension StartedNotFlyingState {
    enum Constants {
        /// Farthest distance, in meters, between the drone and the FP's first WP, before preventing a start.
        static let droneFirstWpFarthestDistance: CLLocationDistance = 50_000
    }

    func ensureExecutionIsPossible(for plan: Plan) throws {
        guard locationTracker.isDroneGpsFixed,
              let droneLocation = locationTracker.drone3DLocation(absoluteAltitude: false).clLocation else {
            // No drone location found (i.e. GPS not fixed). Don't prevent the start
            // to let the possibility to the drone to fix a GPS location while flying
            // to the first WP.
            return
        }
        // Avoid the start if the first way point is farther than the max distance with the Drone.
        if let firstWayPointLocation = plan.mavlinkCommands.firstWayPointLocation,
           firstWayPointLocation.distance(from: droneLocation) > Constants.droneFirstWpFarthestDistance {
            throw StartProhibitedReason.firstWayPointTooFar
        }
    }
}
