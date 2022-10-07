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
import Combine
import GroundSdk

private extension ULogTag {
    static let tag = ULogTag(name: "EditableState")
}

public protocol EditableStateDelegate: AnyObject {
    func flightPlanIsEditable(_ flightPlan: FlightPlanModel, startAvailability: FlightPlanStartAvailability)
}

open class EditableState: GKState {

    private weak var delegate: EditableStateDelegate?
    private let flightPlanManager: FlightPlanManager
    private let projectManager: ProjectManager
    private let startAvailabilityWatcher: FlightPlanStartAvailabilityWatcher
    private let edition: FlightPlanEditionService
    private var cancellables = Set<AnyCancellable>()

    var flightPlan: FlightPlanModel!

    required public init(delegate: EditableStateDelegate,
                         flightPlanManager: FlightPlanManager,
                         projectManager: ProjectManager,
                         startAvailabilityWatcher: FlightPlanStartAvailabilityWatcher,
                         edition: FlightPlanEditionService) {
        self.delegate = delegate
        self.flightPlanManager = flightPlanManager
        self.startAvailabilityWatcher = startAvailabilityWatcher
        self.projectManager = projectManager
        self.edition = edition
        super.init()
    }

    public override func didEnter(from previousState: GKState?) {
        if flightPlan.state != .editable {
            forceEditable()
        }
        edition.setupFlightPlan(flightPlan)
        startAvailabilityWatcher.availabilityForSendingMavlinkPublisher.combineLatest(edition.currentFlightPlanPublisher)
            .sink { [unowned self] in
                let (availability, flightPlan) = $0
                guard let fPlan = flightPlan else { return }
                delegate?.flightPlanIsEditable(fPlan, startAvailability: availability)
            }
            .store(in: &cancellables)
    }

    public func forceEditable() {
        guard flightPlan.state != .editable,
              let editableFP = flightPlanManager.editableFlightPlansFor(projectId: flightPlan.projectUuid).first else {
            ULog.e(.tag, "forceEditable failed: flightPlan.state = \(flightPlan.state) or editableFP not found")
            return
        }
        ULog.d(.tag, "forceEditable with flight plan \(editableFP)")
        // Delete, if needed, the previous execution.
        if mustDelete(flightPlan: flightPlan) {
            flightPlanManager.delete(flightPlan: flightPlan)
            projectManager.cancelLastExecution(forProjectId: flightPlan.projectUuid)
        }
        // Update the current FP.
        flightPlan = editableFP
    }

    open func flightPlanWasUpdated(_ flightPlan: FlightPlanModel, propagateToEditionService: Bool) {
        self.flightPlan = flightPlan
        if propagateToEditionService {
            edition.setupFlightPlan(flightPlan)
        }
    }

    public override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is StartedNotFlyingState.Type
            || stateClass is IdleState.Type
    }

    public override func willExit(to nextState: GKState) {
        cancellables = []
    }
}

// MARK: - Private extension
private extension EditableState {
    /// Whether the flight plan must be deleted.
    ///  - Parameter flightPlan: the flight plan to check
    ///  - Returns `true` if flight plan must be deleted and `false` otherwise
    ///
    ///  - Note: An execution (i.e. a 'non editable' FP) must be deleted if it has been stopped
    ///          before reaching its first way point.
    func mustDelete(flightPlan: FlightPlanModel) -> Bool {
        // If flight plan has reached the first way point, it's a 'valid' execution
        // and it must not be deleted.
        guard !flightPlan.hasReachedFirstWayPoint else { return false }
        // There are some cases where the Drone still continues the execution
        // even if the app tried to stop it (e.g. opening another project when connection
        // with drone is lost after the execution started).
        // In these specific cases, execution must not be deleted to let the possibility
        // to catch up the running execution after the re-connection.
        // Ensure the drone is not disconnected the delete the execution which have not
        // reached the firdt WP.
        return startAvailabilityWatcher.availabilityForRunning != .unavailable(.droneDisconnected)
    }
}
