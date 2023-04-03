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
import GroundSdk

struct FirmwareUpdateButtonProperties {
    var subtitle: String
    var subImage: UIImage?
    var titleColor: ColorName
    var backgroundColor: ColorName
    var subImageTintColor: ColorName
    var isEnabled: Bool

}

class FirmwareUpdateButtonViewModel {
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    private let firmwareUpdateService: FirmwareUpdateService
    private let airSdkMissionsManager: AirSdkMissionsManager
    private let currentDroneHolder: CurrentDroneHolder
    private let updateService: UpdateService
    private let batteryGaugeUpdaterService: BatteryGaugeUpdaterService
    private var connectionStateRef: Ref<DeviceState>?

    @Published var buttonProperties: FirmwareUpdateButtonProperties
    @Published var isDroneConnected: Bool = false

    init(
        firmwareUpdateService: FirmwareUpdateService,
        airSdkMissionsManager: AirSdkMissionsManager,
        currentDroneHolder: CurrentDroneHolder,
        updateService: UpdateService,
        batteryGaugeUpdaterService: BatteryGaugeUpdaterService
    ) {
        self.firmwareUpdateService = firmwareUpdateService
        self.airSdkMissionsManager = airSdkMissionsManager
        self.currentDroneHolder = currentDroneHolder
        self.updateService = updateService
        self.batteryGaugeUpdaterService = batteryGaugeUpdaterService
        self.buttonProperties = FirmwareUpdateButtonProperties(
            subtitle: Style.dash,
            titleColor: .defaultTextColor,
            backgroundColor: .white,
            subImageTintColor: .white,
            isEnabled: false)

        currentDroneHolder.dronePublisher
            .sink { [weak self] drone in
                self?.listenConnectionState(drone)
            }
            .store(in: &cancellables)

        listenFirmwareAndMissions()
    }

    /// Starts watcher for drone's connection state.
    ///
    /// - Parameter drone: the current drone
    func listenConnectionState(_ drone: Drone) {
        connectionStateRef = drone.getState { [weak self] state in
            self?.isDroneConnected = state?.connectionState == .connected
        }
    }

    func listenFirmwareAndMissions() {
        let firmwaresPublisher = firmwareUpdateService.firmwareVersionPublisher
            .combineLatest(firmwareUpdateService.idealVersionPublisher, batteryGaugeUpdaterService.statePublisher)
        updateService.droneUpdatePublisher
            .combineLatest($isDroneConnected, firmwaresPublisher,
                           airSdkMissionsManager.allPotentialMissionsToUpdatePublisher)
            .sink { [weak self] updateState, isDroneConnected, firmwares, allMissionsToUpdate in
                guard let self = self else { return }
                let (firmwareVersion, idealVersion, batteryGaugeUpdaterState) = firmwares
                guard let firmwareVersion = firmwareVersion, isDroneConnected else {
                    self.buttonProperties = FirmwareUpdateButtonProperties(
                        subtitle: Style.dash,
                        titleColor: .defaultTextColor,
                        backgroundColor: .white,
                        subImageTintColor: .white,
                        isEnabled: false)
                    return
                }
                if updateState?.isAvailable == true {
                    // The firmware must be updated.
                    self.buttonProperties = FirmwareUpdateButtonProperties(
                        subtitle: String(format: "%@%@%@", firmwareVersion, Style.arrow, idealVersion?.description ?? ""),
                        titleColor: .white,
                        backgroundColor: updateState == .recommended ? .warningColor : .errorColor,
                        subImageTintColor: .white,
                        isEnabled: true)
                } else if allMissionsToUpdate.count == 1, let mission = allMissionsToUpdate.first {
                    // A mission must be updated.
                    let missionName = mission.missionName ?? mission.internalName
                    self.buttonProperties = FirmwareUpdateButtonProperties(
                        subtitle: missionName,
                        titleColor: .white,
                        backgroundColor: .warningColor,
                        subImageTintColor: .white,
                        isEnabled: true)
                } else if allMissionsToUpdate.count > 1 {
                    // Multiple missions must be updated.
                    self.buttonProperties = FirmwareUpdateButtonProperties(
                        subtitle: L10n.firmwareMissionUpdateMissions,
                        titleColor: .white,
                        backgroundColor: .warningColor,
                        subImageTintColor: .white,
                        isEnabled: true)
                } else if batteryGaugeUpdaterState == .readyToPrepare || batteryGaugeUpdaterState == .readyToUpdate {
                    // Battery gauge firmware must be updated.
                    self.buttonProperties = FirmwareUpdateButtonProperties(
                        subtitle: L10n.battery,
                        titleColor: .white,
                        backgroundColor: .warningColor,
                        subImageTintColor: .white,
                        isEnabled: true)
                } else if updateState == .upToDate {
                    // all up to date
                    self.buttonProperties = FirmwareUpdateButtonProperties(
                        subtitle: firmwareVersion,
                        subImage: Asset.Common.Checks.icCheckedSmall.image,
                        titleColor: .defaultTextColor,
                        backgroundColor: .white,
                        subImageTintColor: .highlightColor,
                        isEnabled: true)
                } else {
                    // not initialized - default
                    self.buttonProperties = FirmwareUpdateButtonProperties(
                        subtitle: Style.dash,
                        titleColor: .defaultTextColor,
                        backgroundColor: .white,
                        subImageTintColor: .white,
                        isEnabled: false)
                }
            }
            .store(in: &cancellables)
    }
}
