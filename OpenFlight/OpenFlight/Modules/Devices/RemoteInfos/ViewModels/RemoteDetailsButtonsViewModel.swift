//    Copyright (C) 2020 Parrot Drones SAS
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

import UIKit
import GroundSdk
import Combine

/// View Model for Remote details buttons screen.
final class RemoteDetailsButtonsViewModel {
    // MARK: - Internal Properties

    @Published private(set) var droneName: String = Style.dash
    @Published private(set) var needCalibration: Bool = false
    @Published private(set) var wifiStrength: WifiStrength = WifiStrength.offline
    @Published private(set) var softwareVersion: String = Style.dash
    @Published private(set) var idealVersion: String = Style.dash
    @Published private(set) var updateState: UpdateState = .upToDate
    @Published private(set) var needDownload: Bool = false

    private var isVersionUnknown: AnyPublisher<Bool, Never> {
        $softwareVersion
            .map { $0 == Style.dash }
            .eraseToAnyPublisher()
    }

    /// Returns true if the remote doesn't have enough battery for the update.
    var isBatteryLevelTooLow: Bool {
        let updater = currentRemoteControlHolder.remoteControl?.getPeripheral(Peripherals.updater)
        return updater?.updateUnavailabilityReasons.contains(.notEnoughBattery) == true
    }

    // MARK: - Private Properties
    private var droneNameRef: Ref<String>?
    private var magnetometerRef: Ref<Magnetometer>?
    private var networkControlRef: Ref<NetworkControl>?
    private let groundSdk = GroundSdk()
    private var updaterRef: Ref<Updater>?
    private var systemInfoRef: Ref<SystemInfo>?

    private var connectedDroneHolder: ConnectedDroneHolder
    private var currentRemoteControlHolder: CurrentRemoteControlHolder
    private var connectedRemoteControlHolder: ConnectedRemoteControlHolder
    private var updateService: UpdateService

    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()

    init(connectedDroneHoler: ConnectedDroneHolder,
         currentRemoteControlHolder: CurrentRemoteControlHolder,
         connectedRemoteControlHolder: ConnectedRemoteControlHolder,
         updateService: UpdateService) {
        self.connectedDroneHolder = connectedDroneHoler
        self.currentRemoteControlHolder = currentRemoteControlHolder
        self.connectedRemoteControlHolder = connectedRemoteControlHolder
        self.updateService = updateService

        listenUpdateService()
        queryRemoteUpdate()

        connectedDroneHoler.dronePublisher
            .sink { [weak self] drone in
                guard let self = self else { return }
                self.listenDroneName(drone)
                self.listenNetworkControl(drone)
            }
            .store(in: &cancellables)

        currentRemoteControlHolder.remoteControlPublisher
            .sink { [weak self] remoteControl in
                guard let self = self else { return }
                self.listenMagnetometer(remoteControl)
                self.listenRemoteUpdate(remoteControl)
                self.listenSystemInfo(remoteControl)
            }
            .store(in: &cancellables)
    }

    /// Check if the drone is currently flying.
    func isDroneFlying() -> Bool {
        return connectedDroneHolder.drone?.isStateFlying == true
    }

    var softwareButtonViewEnabled: AnyPublisher<Bool, Never> {
        connectedRemoteControlHolder.remoteControlPublisher
            .removeDuplicates()
            .combineLatest($needDownload)
            .map { (remoteControl, needDownload) in
                return self.updateState.isAvailable && remoteControl?.isConnected == true || needDownload
            }
            .eraseToAnyPublisher()
    }

    var droneStatusViewEnabled: AnyPublisher<Bool, Never> {
        connectedRemoteControlHolder.remoteControlPublisher
            .removeDuplicates()
            .map { remoteControl in
                return remoteControl?.isConnected == true
            }
            .eraseToAnyPublisher()
    }

    /// Returns a model for remote calibration device view.
    var calibrationModel: AnyPublisher<DeviceDetailsButtonModel, Never> {
        connectedRemoteControlHolder.remoteControlPublisher
            .removeDuplicates()
            .combineLatest($needCalibration.removeDuplicates())
            .map { (remoteControl, needCalibration) in
                var backgroundColor: ColorName
                var subtitle: String

                if !(remoteControl?.isConnected == true) {
                    backgroundColor = .white
                    subtitle = Style.dash
                } else {
                    backgroundColor = needCalibration ? .errorColor : .white
                    subtitle = needCalibration ? L10n.remoteCalibrationRequired : L10n.droneDetailsCalibrationOk
                }
                let titleColor: ColorName = needCalibration ? .white : .defaultTextColor
                let subtitleColor: ColorName = needCalibration ? .white : (remoteControl?.isConnected == true ? .highlightColor : .defaultTextColor)

                return DeviceDetailsButtonModel(mainImage: Asset.Remote.icRemoteController.image,
                                                title: L10n.remoteDetailsCalibration,
                                                subtitle: subtitle,
                                                backgroundColor: backgroundColor,
                                                mainImageTintColor: titleColor,
                                                titleColor: titleColor,
                                                subtitleColor: subtitleColor)
            }
            .eraseToAnyPublisher()
    }

    /// Returns a model for drone status linked to remote connection state.
    var droneStatusModel: AnyPublisher<DeviceDetailsButtonModel, Never> {
        connectedRemoteControlHolder.remoteControlPublisher
            .removeDuplicates()
            .combineLatest(connectedDroneHolder.dronePublisher.removeDuplicates(),
                           $droneName.removeDuplicates())
            .map { (remoteControl, drone, droneName) in
                if remoteControl?.isConnected == true {
                    let backgroundColor: ColorName = drone?.isConnected == true ? .white : .warningColor
                    let titleColor: ColorName = drone?.isConnected == true ? .defaultTextColor : .white
                    let subtitleColor: ColorName = drone?.isConnected == true ? .highlightColor : .white
                    return DeviceDetailsButtonModel(mainImage: Asset.Drone.iconDrone.image,
                                                    title: L10n.remoteDetailsConnectedDrone,
                                                    subtitle: drone?.isConnected == true ? droneName : L10n.pairingLookingForDrone,
                                                    backgroundColor: backgroundColor,
                                                    mainImageTintColor: titleColor,
                                                    titleColor: titleColor,
                                                    subtitleColor: subtitleColor)
                } else {
                    return DeviceDetailsButtonModel(mainImage: Asset.Remote.icSdCardUsb.image,
                                                    title: L10n.remoteDetailsConnectedDrone,
                                                    subtitle: Style.dash,
                                                    backgroundColor: .white,
                                                    subtitleColor: .defaultTextColor80)
                }
            }
            .eraseToAnyPublisher()
    }

    /// Returns a model for remote software information view.
    var softwareModel: AnyPublisher<DeviceDetailsButtonModel, Never> {
        connectedRemoteControlHolder.remoteControlPublisher
            .removeDuplicates()
            .combineLatest($needDownload.removeDuplicates(),
                           isVersionUnknown.removeDuplicates())
            .map { (remoteControl, needDownload, isVersionUnknown) in
                let isReadyForUpdate = self.updateState.isAvailable && remoteControl?.isConnected == true
                let canShowAvailableUpdate = needDownload || isReadyForUpdate
                let subtitle = canShowAvailableUpdate
                ? String(format: "%@%@%@", self.softwareVersion, Style.arrow, self.idealVersion)
                : remoteControl?.isConnected == true ? self.softwareVersion : Style.dash
                let titleColor: ColorName = canShowAvailableUpdate ? .white : .defaultTextColor
                let subImage = !(remoteControl?.isConnected == true) || canShowAvailableUpdate
                || isVersionUnknown ? nil : Asset.Common.Checks.icCheckedSmall.image
                let backgroundColor: ColorName = self.updateState == .required && remoteControl?.isConnected == true
                                                 ? .errorColor
                                                 : canShowAvailableUpdate ? .warningColor : .white

                return DeviceDetailsButtonModel(mainImage: Asset.Remote.icRemoteFirmware.image,
                                                title: L10n.remoteDetailsSoftware,
                                                subImage: subImage,
                                                subtitle: subtitle,
                                                backgroundColor: backgroundColor,
                                                mainImageTintColor: titleColor,
                                                titleColor: titleColor,
                                                subtitleColor: titleColor)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private Funcs
private extension RemoteDetailsButtonsViewModel {
    /// Starts watcher for drone name.
    func listenDroneName(_ drone: Drone?) {
        droneNameRef = drone?.getName(observer: { [weak self] name in
            guard let self = self else { return }
            self.droneName = name ?? Style.dash
        })
    }

    /// Starts watcher for drone network control.
    func listenNetworkControl(_ drone: Drone?) {
        networkControlRef = drone?.getPeripheral(Peripherals.networkControl) { [weak self] networkControl in
            guard let self = self else { return }
            self.wifiStrength = networkControl?.wifiStrength ?? WifiStrength.offline
        }
    }

    /// Starts watcher for remote update.
    func listenRemoteUpdate(_ remoteControl: RemoteControl?) {
        updaterRef = remoteControl?.getPeripheral(Peripherals.updater) { [weak self] updater in
            guard let self = self else { return }
            if let updater = updater {
                self.needDownload = !updater.downloadableFirmwares.isEmpty
                self.idealVersion = updater.idealVersion?.description ?? ""
            }
        }
    }

    /// Starts watcher for remote service info.
    func listenSystemInfo(_ remoteControl: RemoteControl?) {
        systemInfoRef = remoteControl?.getPeripheral(Peripherals.systemInfo) { [weak self] systemInfo in
            guard let self = self else { return }
            self.softwareVersion = systemInfo?.firmwareVersion ?? Style.dash
        }
    }

    /// Starts watcher for remote Magnetometer.
    func listenMagnetometer(_ remoteControl: RemoteControl?) {
        magnetometerRef = remoteControl?.getPeripheral(Peripherals.magnetometer) { [weak self] magnetometer in
            guard let self = self else { return }
            self.needCalibration = magnetometer?.calibrationState == .required
        }
    }

    /// Listens to update state changes.
    func listenUpdateService() {
        updateService.remoteUpdatePublisher
            .removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                guard let updateState = $0 else { return }
                self.updateState = updateState
            }
            .store(in: &cancellables)
    }

    /// Query remote update.
    /// Used to know if updates are available on Parrot server.
    func queryRemoteUpdate() {
        groundSdk.getFacility(Facilities.firmwareManager)?.queryRemoteUpdates()
    }
}
