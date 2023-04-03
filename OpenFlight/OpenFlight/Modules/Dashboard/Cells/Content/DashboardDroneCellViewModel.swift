//    Copyright (C) 2023 Parrot Drones SAS
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

import Combine

class DashboardDroneCellViewModel {
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    private let firmwareUpdateService = Services.hub.drone.firmwareUpdateService
    private let airsdkMissionsManager = Services.hub.drone.airsdkMissionsManager
    private let updateService = Services.hub.update
    private let batteryGaugeUpdaterService = Services.hub.drone.batteryGaugeUpdaterService

    @Published var updateState: UpdateState?
    @Published var stateButtonTitle: String = ""
    @Published var missionsCount: Int = 0
    @Published var shouldUpdateBattery: Bool = false

    init() {
        listenFirmwareAndMissions()
        updateService.droneUpdatePublisher
            .removeDuplicates()
            .sink { self.updateState = $0 }
            .store(in: &cancellables)
    }

    private func listenFirmwareAndMissions() {
        firmwareUpdateService.isUpToDatePublisher
            .combineLatest(
                firmwareUpdateService.idealVersionPublisher,
                airsdkMissionsManager.allPotentialMissionsToUpdatePublisher,
                batteryGaugeUpdaterService.statePublisher
            )
            .sink { [weak self] isUpToDate, idealVersion, allMissionsToUpdate, batteryGaugeUpdateState in
                guard let self = self else { return }
                self.missionsCount = allMissionsToUpdate.count
                if !isUpToDate {
                    // The firmware must be updated.
                    self.stateButtonTitle = idealVersion?.description ?? ""
                } else if allMissionsToUpdate.count == 1, let mission = allMissionsToUpdate.first {
                    // A mission must be updated.
                    self.stateButtonTitle = mission.missionName ?? mission.internalName
                } else if allMissionsToUpdate.count > 1 {
                    // Multiple missions must be updated.
                    self.stateButtonTitle = L10n.firmwareMissionUpdateMissions
                    // The battery gauge firmware must be updated.
                } else if batteryGaugeUpdateState == .readyToPrepare || batteryGaugeUpdateState == .readyToUpdate {
                    self.shouldUpdateBattery = true
                    self.stateButtonTitle = L10n.battery
                } else {
                    self.shouldUpdateBattery = false
                    self.stateButtonTitle = ""
                }
            }
            .store(in: &cancellables)
    }
}
