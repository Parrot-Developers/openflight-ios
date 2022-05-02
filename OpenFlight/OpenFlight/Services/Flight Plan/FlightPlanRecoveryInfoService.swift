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
         projectService: ProjectManager,
         missionsStore: MissionsStore,
         currentMissionManager: CurrentMissionManager) {
        self.flightPlanManager = flightPlanManager
        self.projectService = projectService
        self.missionsStore = missionsStore
        self.currentMissionManager = currentMissionManager

        connectedDroneHolder.dronePublisher.sink { [unowned self] drone in
            guard let drone = drone else { return }
            if drone.state.connectionState == .connected {
                catchUpFlightPlan(drone: drone)
            }
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
        guard let pilotingItf = drone.getPilotingItf(PilotingItfs.flightPlan) else { return }

        guard let recoveryInfo = pilotingItf.recoveryInfo,
              let flightPlan = flightPlanManager.flightPlan(uuid: recoveryInfo.customId),
              let project = projectService.project(for: flightPlan) else {
                  if pilotingItf.state == .active, pilotingItf.recoveryInfo == nil {
                      ULog.e(.tag, "catchUpFlightPlan recoveryInfo is nil, flight plan state is ignored")
                  }
                  return
              }

        if pilotingItf.state == .active {
            catchUpRunningFlightPlan(project: project,
                                     flightPlan: flightPlan,
                                     recoveryInfo: recoveryInfo)
            pilotingItf.clearRecoveryInfo()

        }
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
            updateFlightPlanFromRecoveryInfo(flightPlan, recoveryInfo: recoveryInfo)
        }

        // The piloting interface is not active, the recovery info can be cleared.
        pilotingItf.clearRecoveryInfo()
    }

    /// Update flight plan when receiving recovery information.
    /// When flight plan state is running, and when flight plan has reached the last waypoint, the state machine is updated.
    ///
    /// - Parameters:
    ///    - flightPlan: flight plan
    ///    - recoveryInfo: recovery info
    private func updateFlightPlanFromRecoveryInfo(_ flightPlan: FlightPlanModel,
                                                  recoveryInfo: RecoveryInfo) {
        ULog.d(.tag, "updatePassedFlightPlan '\(flightPlan.uuid)'")
        let flightPlan = flightPlanManager.update(flightPlan: flightPlan,
                                                  lastMissionItemExecuted: Int(recoveryInfo.latestMissionItemExecuted),
                                                  recoveryResourceId: recoveryInfo.resourceId)
        if flightPlan.state == .flying,
           let missionMode = missionsStore.missionFor(flightPlan: flightPlan)?.mission,
           flightPlan.hasReachedLastWayPoint {
            missionMode.stateMachine?.handleFinishedOfflineFlightPlan(flightPlan: flightPlan)
        }
    }

    private func catchUpRunningFlightPlan(project: ProjectModel,
                                          flightPlan: FlightPlanModel,
                                          recoveryInfo: RecoveryInfo) {
        ULog.d(.tag, "catchUpRunningFlightPlan '\(flightPlan.uuid)'")
        guard let (provider, mode) = missionsStore.missionFor(flightPlan: flightPlan) else { return }
        Services.hub.ui.hudTopBarService.allowTopBarDisplay()
        currentMissionManager.set(provider: provider)
        currentMissionManager.set(mode: mode)
        projectService.setCurrent(project)
        mode.stateMachine?.catchUp(flightPlan: flightPlan,
                                   lastMissionItemExecuted: Int(recoveryInfo.latestMissionItemExecuted),
                                   recoveryResourceId: recoveryInfo.resourceId,
                                   runningTime: recoveryInfo.runningTime)
    }
}

extension FlightPlanRecoveryInfoServiceImpl: FlightPlanRecoveryInfoService {
}
