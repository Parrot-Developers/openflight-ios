//
//  Copyright (C) 2021 Parrot Drones SAS.
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

public protocol MissionCatchUpService {

}

public class MissionCatchUpServiceImpl {

    private var cancellables = Set<AnyCancellable>()
    private let flightPlanManager: FlightPlanManager
    private let projectService: ProjectManager
    private let missionsStore: MissionsStore
    private let currentMissionManager: CurrentMissionManager

    init(connectedDroneHolder: ConnectedDroneHolder,
         flightPlanManager: FlightPlanManager,
         projectService: ProjectManager,
         missionsStore: MissionsStore,
         currentMissionManager: CurrentMissionManager) {
        self.flightPlanManager = flightPlanManager
        self.projectService = projectService
        self.missionsStore = missionsStore
        self.currentMissionManager = currentMissionManager
        connectedDroneHolder.dronePublisher.sink { [unowned self] in
            if let pilotingItf = $0?.getPilotingItf(PilotingItfs.flightPlan),
               let recoveryInfo = pilotingItf.recoveryInfo,
               let flightPlan = flightPlanManager.flightPlan(uuid: recoveryInfo.customId),
               let project = projectService.project(for: flightPlan) {
                switch flightPlan.state {
                case .editable, .flying, .stopped:
                    // Onlys these states are valid
                    break
                case .completed, .uploading, .processing, .processed, .unknown:
                    return
                }
                if pilotingItf.state == .active {
                    // As the recoveryInfo contains information about the last started FP,
                    // if the itf is active its recoveryInfo points to the active FP
                    catchUpRunningFlightPlan(project: project, flightPlan: flightPlan, lastItem: recoveryInfo.latestMissionItemExecuted)
                } else {
                    // Just persist the progress
                    _ = flightPlanManager.update(flightPlan: flightPlan, lastMissionItemExecuted: recoveryInfo.latestMissionItemExecuted)
                    // TODO if completed change the state
                }
                pilotingItf.clearRecoveryInfo()
            }
        }
        .store(in: &cancellables)
    }

    private func catchUpRunningFlightPlan(project: ProjectModel, flightPlan: FlightPlanModel, lastItem: Int) {
        // Get mission matching flightPlan
        var missionProvider: MissionProvider?
        var missionMode: MissionMode?
        for provider in missionsStore.allMissions {
            for mode in provider.mission.modes {
                if mode.flightPlanProvider?.hasFlightPlanType(flightPlan.type) ?? false {
                    missionProvider = provider
                    missionMode = mode
                }
            }
        }
        guard let mProvider = missionProvider, let mMode = missionMode else { return }
        currentMissionManager.set(provider: mProvider)
        currentMissionManager.set(mode: mMode)
        projectService.setCurrent(project)
        mMode.stateMachine?.catchUp(flightPlan: flightPlan, lastMissionItemExecuted: lastItem)
    }

}

extension MissionCatchUpServiceImpl: MissionCatchUpService {
    
}
