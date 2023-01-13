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

import Foundation
import Combine
import GroundSdk

private extension ULogTag {
    static let tag = ULogTag(name: "FPRecoveryInfoService")
}

/// Service listening flight plan recovery information.
public protocol FlightPlanRecoveryInfoService {
}

/// Implementation of `FlightPlanRecoveryInfoService`.
public class FlightPlanRecoveryInfoServiceImpl {

    /// Flight plan manager.
    private let flightPlanManager: FlightPlanManager
    /// Flight plan run manager.
    private let runManager: FlightPlanRunManager
    /// Flight plan project manager.
    private let projectService: ProjectManager
    /// Mission store.
    private let missionsStore: MissionsStore
    /// Current mission manager.
    private let currentMissionManager: CurrentMissionManager
    /// Reference to flight plan piloting interface.
    private var flightPlanPilotingRef: Ref<FlightPlanPilotingItf>?
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()

    /// Constructor.
    ///
    /// - Parameters:
    ///   - currentDroneHolder: current drone holder
    ///   - connectedDroneHolder: current drone holder
    ///   - flightPlanManager: flight plan manager
    ///   - projectService: flight plan project manager
    ///   - missionsStore: mission store
    ///   - currentMissionManager: current mission manager
    init(connectedDroneHolder: ConnectedDroneHolder,
         currentDroneHolder: CurrentDroneHolder,
         flightPlanManager: FlightPlanManager,
         runManager: FlightPlanRunManager,
         projectService: ProjectManager,
         missionsStore: MissionsStore,
         currentMissionManager: CurrentMissionManager) {
        self.flightPlanManager = flightPlanManager
        self.runManager = runManager
        self.projectService = projectService
        self.missionsStore = missionsStore
        self.currentMissionManager = currentMissionManager

        // Listen drone connections / disconnections.
        connectedDroneHolder.dronePublisher.sink { [unowned self] drone in
            // No need to check that `connectionState == .connected` for a `ConnectedDroneHolder`.
            // If drone exists means it's connected.
            guard let drone = drone else { return }
            // Catch up a running flight plan if available.
            catchUpFlightPlan(drone: drone)
        }
        .store(in: &cancellables)

        currentDroneHolder.dronePublisher.sink { [unowned self] in
            listenFlightPlanPiloting(drone: $0)
        }
        .store(in: &cancellables)
    }

    /// Listens flight plan piloting interface.
    ///
    /// - Parameters:
    ///    - drone: the current drone
    private func listenFlightPlanPiloting(drone: Drone) {
        flightPlanPilotingRef = drone.getPilotingItf(PilotingItfs.flightPlan) { [unowned self] pilotingItf in
            guard let pilotingItf = pilotingItf else { return }
            checkRecoveryInfo(pilotingItf: pilotingItf)
        }
    }

    /// Only called when the drone is connected.
    /// When flight plan piloting interface is active, we redirect the HUD to FP HUD.
    /// Saving recovery in the flight plan state machine.
    ///
    /// - Parameters:
    ///    - drone: the current drone
    private func catchUpFlightPlan(drone: Drone) {
        // As the recoveryInfo contains information about the last started FP,
        // if the itf is active its recoveryInfo points to the active FP
        guard let pilotingItf = drone.getPilotingItf(PilotingItfs.flightPlan) else {
            ULog.i(.tag, "Drone did connect but Flight Plan Piloting Interface is not accessible.")
            return
        }
        guard let recoveryInfo = pilotingItf.recoveryInfo else {
            ULog.e(.tag, "RecoveryInfo is nil, nothing to do.")
            return
        }
        guard let flightPlan = flightPlanManager.flightPlan(uuid: recoveryInfo.customId) else {
            ULog.e(.tag, "Flight Plan '\(recoveryInfo.customId)' not found locally. Ignore recovery info.")
            return
        }
        guard let project = projectService.project(for: flightPlan) else {
            ULog.e(.tag, "Unable to find a project for Flight Plan '\(recoveryInfo.customId)'.")
            return
        }
        guard pilotingItf.state == .active else {
            ULog.i(.tag, "Piloting Interface is not active")
            return
        }

        // Following requirements to catch up an FP are met:
        //   • The Flight Plan Piloting Interface has recovery information.
        //   • The recovered Flight Plan and its project are known by the app.
        //   • The piloting interface is active.

        // Catch up the running flight plan.
        catchUpRunningFlightPlan(project: project,
                                 flightPlan: flightPlan,
                                 recoveryInfo: recoveryInfo)
        // Then tell the drone to clear its recovery info.
        pilotingItf.clearRecoveryInfo()
    }

    /// Process recovery information provided by flight plan piloting interface.
    /// For a Piloting Interface not active, we are reading the recovery info.
    /// The flight plan will be updated and saved if his current state is 'not completed'.
    /// Then recovery info is cleared.
    ///
    /// - Parameters:
    ///    - pilotingItf: flight plan piloting interface
    private func checkRecoveryInfo(pilotingItf: FlightPlanPilotingItf) {
        // The Recovery Info is only treated when the Piloting Interface is not active.
        guard pilotingItf.state != .active else { return }
        // Ensure Recovery Info is available.
        guard let recoveryInfo = pilotingItf.recoveryInfo else { return }
        // Get the local FP from the recovery info's customId (the FP's uuid).
        guard let flightPlan = flightPlanManager.flightPlan(uuid: recoveryInfo.customId) else { return }

        ULog.d(.tag, "checkRecoveryInfo recoveryInfo: \(recoveryInfo)")

        // A Flight Plan is considered as 'not completed' when
        // it's in a running state (.flying or .stopped) or not yet launched (.editable state).
        let notCompletedStates: [FlightPlanModel.FlightPlanState] = [.editable, .flying, .stopped]
        // The Recovery Info is only treated when the local Flight Plan is in a 'not completed' state.
        if notCompletedStates.contains(where: {$0 == flightPlan.state}) {
            // The Local FP is updated with the recovery information.
            // Then we check if the last FP's way point has been reached
            // to handle, if necessary, the FP as 'finished offline'.
            updateFlightPlanFromRecoveryInfo(flightPlan,
                                             recoveryInfo: recoveryInfo,
                                             isPaused: pilotingItf.isPaused) { success in
                guard success else {
                    ULog.e(.tag, "Unable to store the updated flight plan in data base. Do not send the clear recovery command.")
                    return
                }
                // Recovery is correctly handled. Ask the drone to clear it.
                pilotingItf.clearRecoveryInfo()
            }
        } else {
            // The piloting interface is not active, the recovery info can be cleared.
            pilotingItf.clearRecoveryInfo()
        }
    }

    /// Update flight plan when receiving recovery information.
    /// When flight plan state is running, the flight plan has reached the last waypoint and the RTH is not paused,
    /// the state machine is updated to handle the flight plan as completed offline.
    ///
    /// - Parameters:
    ///    - flightPlan: flight plan
    ///    - recoveryInfo: recovery info
    ///    - isPaused: whether the piloting interface is paused
    ///    - databaseUpdateCompletion: the completion block called when data base has been updated
    private func updateFlightPlanFromRecoveryInfo(_ flightPlan: FlightPlanModel,
                                                  recoveryInfo: RecoveryInfo,
                                                  isPaused: Bool,
                                                  databaseUpdateCompletion: ((_ status: Bool) -> Void)? = nil) {
        ULog.d(.tag, "updatePassedFlightPlan '\(flightPlan.uuid)'")
        let flightPlan = flightPlanManager.update(flightPlan: flightPlan,
                                                  lastMissionItemExecuted: Int(recoveryInfo.latestMissionItemExecuted),
                                                  recoveryResourceId: recoveryInfo.resourceId,
                                                  databaseUpdateCompletion: databaseUpdateCompletion)
        // Check if the current FP:
        //  • is currently flying or stopped
        //  • has reached the last way point (completed)
        //  • the run manager is not in .rth state
        //  • the piloting interface has not been paused (e.g by an over-piloting)
        // In case of all conditions are met, FP is handled as finished offline.
        guard [.flying, .stopped].contains(flightPlan.state),
              flightPlan.hasReachedLastWayPoint,
              !runManager.state.isRthState,
              !isPaused else { return }
        // Ensure flight plan has a valid mission.
        guard let missionMode = missionsStore.missionFor(flightPlan: flightPlan)?.mission else {
            ULog.e(.tag, "Trying to update an FP with an undefined mission")
            return
        }
        // Ensure we can access the FP State Machine.
        guard let stateMachine = missionMode.stateMachine else {
            ULog.e(.tag, "Unable to get the FP State Machine")
            return
        }
        // Tell to the State Machine the FP finished off line.
        ULog.i(.tag, "Updating Flight Plan State Machine")
        stateMachine.handleFinishedOfflineFlightPlan(flightPlan: flightPlan)
    }

    private func catchUpRunningFlightPlan(project: ProjectModel,
                                          flightPlan: FlightPlanModel,
                                          recoveryInfo: RecoveryInfo) {
        ULog.d(.tag, "catchUpRunningFlightPlan '\(flightPlan.uuid)'")
        guard let (provider, mode) = missionsStore.missionFor(flightPlan: flightPlan) else { return }
        Services.hub.ui.hudTopBarService.allowTopBarDisplay()
        currentMissionManager.set(provider: provider)
        currentMissionManager.set(mode: mode)
        projectService.setCurrent(project, completion: nil)
        mode.stateMachine?.catchUp(flightPlan: flightPlan,
                                   lastMissionItemExecuted: Int(recoveryInfo.latestMissionItemExecuted),
                                   recoveryResourceId: recoveryInfo.resourceId,
                                   runningTime: recoveryInfo.runningTime)
    }
}

extension FlightPlanRecoveryInfoServiceImpl: FlightPlanRecoveryInfoService {
}
