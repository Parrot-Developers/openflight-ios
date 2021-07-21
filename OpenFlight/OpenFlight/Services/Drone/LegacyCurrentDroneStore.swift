// Copyright (C) 2020 Parrot Drones SAS
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

import GroundSdk
import Combine

/// Legacy class that performs side-effects on drone connection
public final class LegacyCurrentDroneStore {
    // MARK: - Internal Enums
    enum NotificationKeys {
        static let flightPlanRunningNotificationKey: String = "flightPlanRunningNotificationKey"
    }

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var stateRef: Ref<DeviceState>?
    private var mediaMetadataRef: Ref<Camera2MediaMetadata>?
    private var isFlightPlanAlreadyShown: Bool = false
    private unowned var currentMissionManager: CurrentMissionManager

    // MARK: - Init
    public init(droneHolder: CurrentDroneHolder, currentMissionManager: CurrentMissionManager) {
        self.currentMissionManager = currentMissionManager
        droneHolder.dronePublisher.sink { [unowned self] drone in
            listenState(drone)
        }
        .store(in: &cancellables)
    }
}

// MARK: - Private Funcs
private extension LegacyCurrentDroneStore {
    /// Listens drone state.
    func listenState(_ drone: Drone) {
        stateRef = drone.getState { [weak self] state in
            guard state?.connectionState == .connected else { return }
            self?.updateDroneState(drone)
            self?.resetMediaCustomIdIfNecessary(drone: drone)
            self?.updateFlightPlanExecutionState(drone)
        }
    }

    /// Updates drone state.
    func updateDroneState(_ drone: Drone) {
        // Enable streaming by default.
        if !drone.isUpdating {
            drone.getPeripheral(Peripherals.streamServer)?.enabled = true
        }

        if let flightCameraRecorder = drone.getPeripheral(Peripherals.flightCameraRecorder) {
            flightCameraRecorder.activePipelines.value = flightCameraRecorder.activePipelines.supportedValues
        }
    }

    /// Updates Flight Plan execution informations.
    func updateFlightPlanExecutionState(_ drone: Drone) {
        // Gets last flight plan information with recovery field.
        // Database must be updated if recoveryInfo is not nil.
        guard let pilotingItf = drone.getPilotingItf(PilotingItfs.flightPlan),
              let recoveryInfo = pilotingItf.recoveryInfo else {
            return
        }

        var currentFlightPlanId: String?

        // Gets last execution of the recovered flight plan and update its last item executed.
        let flightPlanExecution = CoreDataManager
            .shared
            .executions(forRecoveryId: recoveryInfo.id)
            .first

        guard flightPlanExecution?.state != .completed else {
            pilotingItf.clearRecoveryInfo()
            return
        }

        flightPlanExecution?.saveLatestItemExecuted(with: recoveryInfo.latestMissionItemExecuted)

        if let path = flightPlanExecution?.mavlinkUrl?.path,
           FileManager.default.fileExists(atPath: path),
           let mavlinkCommands: [MavlinkStandard.MavlinkCommand] = (try? MavlinkStandard.MavlinkFiles.parse(filepath: path)) {
            var lastItemIndex = mavlinkCommands.count - 1

            // Decrease total item count if there is one Return to Home MavlinkCommand.
            // RTH usually occurs at the end of the Flight plan.
            if mavlinkCommands.first(where: {
                $0 is MavlinkStandard.ReturnToLaunchCommand
            }) != nil {
                lastItemIndex -= 1
            }

            // Updates execution status if Flight Plan is finish.
            if lastItemIndex == recoveryInfo.latestMissionItemExecuted {
                flightPlanExecution?.saveExecutionState(with: .completed)
            }
        }

        // Save current flight plan Id.
        currentFlightPlanId = flightPlanExecution?.flightPlanId

        if pilotingItf.state == .active,
           drone.isStateFlying,
           !isFlightPlanAlreadyShown,
           let flightPlanId = currentFlightPlanId {

            if let currentViewModel = CoreDataManager.shared.loadFlightPlan(for: flightPlanId),
               let type = currentViewModel.state.value.type {

                // Set Flight Plan as last used to be automatically open.
                currentViewModel.setAsLastUsed()

                // Setup Mission as a Flight Plan mission (may be custom).
                currentMissionManager.set(provider: type.missionProvider)
                currentMissionManager.set(mode: type.missionMode)
                isFlightPlanAlreadyShown = true
            }
        } else {
            // Clear recovery info after execution updates, only if a FP is not active.
            pilotingItf.clearRecoveryInfo()
        }
    }

    /// Resets the media customId if it is necessary.
    /// Can happen if there is a crash/killing app during a flight plan execution.
    func resetMediaCustomIdIfNecessary(drone: Drone) {
        mediaMetadataRef = drone.getPeripheral(Peripherals.mainCamera2)?.getComponent(Camera2Components.mediaMetadata) { [weak self] mediaMetadata in
            if let mediaCustomId = mediaMetadata?.customId,
               !mediaCustomId.isEmpty,
               self?.isDroneStillRunningFlightPlan(drone: drone, executionId: mediaCustomId) == false {
                drone.getPeripheral(Peripherals.mainCamera2)?.resetCustomMediaMetadata()
            }

            // Resets the media reference to avoid callback being called more than one time.
            self?.mediaMetadataRef = nil
        }
    }

    /// Checks if drone is running the flight plan after a connection lost.
    ///
    /// - Parameters:
    ///    - drone: drone
    ///    - executionId: flight plan execution
    func isDroneStillRunningFlightPlan(drone: Drone, executionId: String) -> Bool {
        guard drone.getPilotingItf(PilotingItfs.flightPlan)?.state == .active,
              let executions = FlightPlanManager.shared.currentFlightPlanViewModel?.executions,
              let execution = executions.first(where: { $0.executionId == executionId }) else {
            return false
        }

        return execution.state != .completed
    }
}
