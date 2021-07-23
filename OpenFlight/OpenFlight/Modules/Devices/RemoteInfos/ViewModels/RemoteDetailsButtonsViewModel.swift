//
//  Copyright (C) 2020 Parrot Drones SAS.
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
import SwiftyUserDefaults

/// State for `RemoteDetailsButtonsViewModel`.
final class RemoteDetailsButtonsState: DevicesConnectionState {
    // MARK: - Internal Properties
    fileprivate(set) var droneName: String = Style.dash
    fileprivate(set) var needCalibration: Bool = false
    fileprivate(set) var wifiStrength: WifiStrength = WifiStrength.offline
    fileprivate(set) var softwareVersion: String = Style.dash
    fileprivate(set) var idealVersion: String = Style.dash
    fileprivate(set) var needUpdate: Bool = false

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - droneConnectionState: drone connection state
    ///    - remoteControlConnectionState: remote control connection state
    ///    - droneName: current drone name
    ///    - needCalibration: check if remote need calibration
    ///    - wifiStrength: wifi signal
    ///    - softwareVersion: software version
    ///    - idealVersion: ideal target software version
    ///    - needUpdate: check if remote need an update
    init(droneConnectionState: DeviceConnectionState?,
         remoteControlConnectionState: DeviceConnectionState?,
         droneName: String,
         needCalibration: Bool,
         wifiStrength: WifiStrength,
         softwareVersion: String,
         idealVersion: String,
         needUpdate: Bool) {
        super.init(droneConnectionState: droneConnectionState,
                   remoteControlConnectionState: remoteControlConnectionState)

        self.droneName = droneName
        self.needCalibration = needCalibration
        self.wifiStrength = wifiStrength
        self.softwareVersion = softwareVersion
        self.idealVersion = idealVersion
        self.needUpdate = needUpdate
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DevicesConnectionState) -> Bool {
        guard let other = other as? RemoteDetailsButtonsState else { return false }

        return super.isEqual(to: other)
            && self.droneName == other.droneName
            && self.needCalibration == other.needCalibration
            && self.wifiStrength == other.wifiStrength
            && self.softwareVersion == other.softwareVersion
            && self.idealVersion == other.idealVersion
            && self.needUpdate == other.needUpdate
    }

    override func copy() -> RemoteDetailsButtonsState {
        let copy = RemoteDetailsButtonsState(droneConnectionState: self.droneConnectionState,
                                             remoteControlConnectionState: self.remoteControlConnectionState,
                                             droneName: self.droneName,
                                             needCalibration: self.needCalibration,
                                             wifiStrength: self.wifiStrength,
                                             softwareVersion: self.softwareVersion,
                                             idealVersion: self.idealVersion,
                                             needUpdate: self.needUpdate)
        return copy
    }
}

// MARK: - Internal Properties
/// Provides Helpers for button state.
extension RemoteDetailsButtonsState {
    /// Returns a model for remote calibration device view.
    var calibrationModel: DeviceDetailsButtonModel {
        let backgroundColor: ColorName = needCalibration ? .errorColor : .white
        let titleColor: ColorName = needCalibration ? .white : .defaultTextColor
        let subtitleColor: ColorName = needCalibration ? .white : .highlightColor
        return DeviceDetailsButtonModel(mainImage: Asset.Common.Icons.icRemoteControl.image,
                                        title: L10n.remoteDetailsCalibration,
                                        subtitle: needCalibration ? L10n.remoteCalibrationRequired : L10n.droneDetailsCalibrationOk,
                                        backgroundColor: backgroundColor,
                                        mainImageTintColor: titleColor,
                                        titleColor: titleColor,
                                        subtitleColor: subtitleColor)
    }

    /// Returns a model for drone status linked to remote connection state.
    var droneStatusModel: DeviceDetailsButtonModel {
        let isRemoteConnected = remoteControlConnectionState?.isConnected() == true
        let isDroneConnected = droneConnectionState?.isConnected() == true
        if isRemoteConnected {
            let backgroundColor: ColorName = isDroneConnected ? .white : .highlightColor
            let titleColor: ColorName = isDroneConnected ? .defaultTextColor : .white
            let subtitleColor: ColorName = isDroneConnected ? .highlightColor : .white
            return DeviceDetailsButtonModel(mainImage: Asset.Common.Icons.icWifi.image,
                                            title: L10n.settingsAdvancedCategoryConnection,
                                            subtitle: isDroneConnected ? droneName : L10n.pairingLookingForDrone,
                                            backgroundColor: backgroundColor,
                                            mainImageTintColor: titleColor,
                                            titleColor: titleColor,
                                            subtitleColor: subtitleColor)
        } else {
            return DeviceDetailsButtonModel(mainImage: Asset.Remote.icSdCardUsb.image,
                                            title: L10n.settingsAdvancedCategoryConnection,
                                            subtitle: L10n.disconnected,
                                            backgroundColor: .white,
                                            subtitleColor: .defaultTextColor80)

        }
    }

    /// Returns a model for remote software information view.
    var softwareModel: DeviceDetailsButtonModel {
        return DeviceDetailsButtonModel(mainImage: Asset.Drone.iconDownload.image,
                                        title: L10n.remoteDetailsSoftware,
                                        subImage: needUpdate ? nil : Asset.Common.Checks.icChecked.image,
                                        subtitle: softwareVersion,
                                        complementarySubtitle: needUpdate ? idealVersion : nil)
    }
}

/// View Model for Remote details buttons screen.
final class RemoteDetailsButtonsViewModel: DevicesStateViewModel<RemoteDetailsButtonsState> {
    // MARK: - Internal Properties
    /// Returns true if the remote doesn't have enough battery for the update.
    var isBatteryLevelTooLow: Bool {
        let updater = remoteControl?.getPeripheral(Peripherals.updater)
        return updater?.updateUnavailabilityReasons.contains(.notEnoughBattery) == true
    }

    // MARK: - Private Properties
    private var droneNameRef: Ref<String>?
    private var magnetometerRef: Ref<Magnetometer>?
    private var networkControlRef: Ref<NetworkControl>?
    private let groundSdk = GroundSdk()
    private var updaterRef: Ref<Updater>?
    private var systemInfoRef: Ref<SystemInfo>?

    // MARK: - Init
    override init() {
        super.init()

        queryRemoteUpdate()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenDroneName(drone)
        listenNetworkControl(drone)
    }

    override func listenRemoteControl(remoteControl: RemoteControl) {
        super.listenRemoteControl(remoteControl: remoteControl)

        listenMagnetometer(remoteControl)
        listenRemoteUpdate(remoteControl)
        listenSystemInfo(remoteControl)
    }

    /// Check if the drone is currently flying.
    func isDroneFlying() -> Bool {
        return drone?.isStateFlying == true
    }
}

// MARK: - Private Funcs
private extension RemoteDetailsButtonsViewModel {
    /// Starts watcher for drone name.
    func listenDroneName(_ drone: Drone) {
        droneNameRef = drone.getName(observer: { [weak self] name in
            let copy = self?.state.value.copy()
            copy?.droneName = name ?? Style.dash
            self?.state.set(copy)
        })
    }

    /// Starts watcher for drone network control.
    func listenNetworkControl(_ drone: Drone) {
        networkControlRef = drone.getPeripheral(Peripherals.networkControl) { [weak self] networkControl in
            let copy = self?.state.value.copy()
            copy?.wifiStrength = networkControl?.wifiStrength ?? WifiStrength.offline
            self?.state.set(copy)
        }
    }

    /// Starts watcher for remote update.
    func listenRemoteUpdate(_ remoteControl: RemoteControl) {
        updaterRef = remoteControl.getPeripheral(Peripherals.updater) { [weak self] updater in
            if let updater = updater {
                let copy = self?.state.value.copy()
                copy?.needUpdate = !updater.isUpToDate
                copy?.idealVersion = updater.idealVersion?.description ?? ""
                self?.state.set(copy)
            }
        }
    }

    /// Starts watcher for remote service info.
    func listenSystemInfo(_ remoteControl: RemoteControl) {
        systemInfoRef = remoteControl.getPeripheral(Peripherals.systemInfo) { [weak self] systemInfo in
            let copy = self?.state.value.copy()
            copy?.softwareVersion = systemInfo?.firmwareVersion ?? Style.dash
            self?.state.set(copy)
        }
    }

    /// Starts watcher for remote Magnetometer.
    func listenMagnetometer(_ remoteControl: RemoteControl) {
        magnetometerRef = remoteControl.getPeripheral(Peripherals.magnetometer) { [weak self] magnetometer in
            let copy = self?.state.value.copy()
            copy?.needCalibration = magnetometer?.calibrationState == .required
            self?.state.set(copy)
        }
    }

    /// Query remote update.
    /// Used to know if updates are available on Parrot server.
    func queryRemoteUpdate() {
        groundSdk.getFacility(Facilities.firmwareManager)?.queryRemoteUpdates()
    }
}
