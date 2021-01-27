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

/// State for `RemoteDetailsViewModel`.

final class RemoteDetailsState: DevicesConnectionState {
    // MARK: - Internal Properties
    fileprivate(set) var droneName: String?
    fileprivate(set) var remoteName: String?
    fileprivate(set) var batteryLevel: BatteryValueModel?
    fileprivate(set) var needCalibration: Bool?
    fileprivate(set) var wifiStrength: WifiStrength = WifiStrength.none

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
    ///    - remoteName: current remote name
    ///    - batteryLevel: drone battery level
    ///    - needCalibration: check if remote need calibration
    ///    - wifiStrength: wifi signal
    init(droneConnectionState: DeviceConnectionState?,
         remoteControlConnectionState: DeviceConnectionState?,
         droneName: String?,
         remoteName: String?,
         batteryLevel: BatteryValueModel?,
         needCalibration: Bool?,
         wifiStrength: WifiStrength) {
        super.init(droneConnectionState: droneConnectionState, remoteControlConnectionState: remoteControlConnectionState)
        self.droneName = droneName
        self.remoteName = remoteName
        self.batteryLevel = batteryLevel
        self.needCalibration = needCalibration
        self.wifiStrength = wifiStrength
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DevicesConnectionState) -> Bool {
        guard let other = other as? RemoteDetailsState else {
            return false
        }
        return super.isEqual(to: other)
            && self.droneName == other.droneName
            && self.remoteName == other.remoteName
            && self.batteryLevel == other.batteryLevel
            && self.needCalibration == other.needCalibration
            && self.wifiStrength == other.wifiStrength
    }

    override func copy() -> RemoteDetailsState {
        let copy = RemoteDetailsState(droneConnectionState: self.droneConnectionState,
                                      remoteControlConnectionState: self.remoteControlConnectionState,
                                      droneName: self.droneName,
                                      remoteName: self.remoteName,
                                      batteryLevel: self.batteryLevel,
                                      needCalibration: self.needCalibration,
                                      wifiStrength: self.wifiStrength)
        return copy
    }
}

/// View Model for Remote details screen. This view model is in charge of providing datas from remote and drone.

final class RemoteDetailsViewModel: DevicesStateViewModel<RemoteDetailsState> {
    // MARK: - Private Properties
    private var batteryRef: Ref<BatteryInfo>?
    private var droneNameRef: Ref<String>?
    private var remoteNameRef: Ref<String>?
    private var magnetometerRef: Ref<Magnetometer>?
    private var radioRef: Ref<Radio>?
    private let groundSdk = GroundSdk()

    // MARK: - Init
    override init(stateDidUpdate: ((RemoteDetailsState) -> Void)? = nil) {
        super.init(stateDidUpdate: stateDidUpdate)
        queryRemoteUpdate()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)
        listenDroneName(drone)
        listenRadio(drone)
    }

    override func listenRemoteControl(remoteControl: RemoteControl) {
        super.listenRemoteControl(remoteControl: remoteControl)
        listenBatteryLevel(remoteControl)
        listenRemoteName(remoteControl)
        listenMagnetometer(remoteControl)
    }

    // MARK: - Internal Funcs
    /// Reset the remote to factory state.
    func resetRemote() {
        _ = remoteControl?.getPeripheral(Peripherals.systemInfo)?.factoryReset()
    }

    /// Check if the drone get enough battery for the update.
    func isBatteryLevelSufficient() -> Bool {
        // Battery level.
        let updater = remoteControl?.getPeripheral(Peripherals.updater)
        let isBatterySufficient = updater?.updateUnavailabilityReasons.contains(.notEnoughBattery) == false
        return isBatterySufficient
    }

    /// Check if the drone is currently flying.
    func isDroneFlying() -> Bool {
        return drone?.isStateFlying == true
    }
}

// MARK: - Private Funcs
private extension RemoteDetailsViewModel {
    /// Starts watcher for remote battery.
    func listenBatteryLevel(_ remoteControl: RemoteControl) {
        batteryRef = remoteControl.getInstrument(Instruments.batteryInfo) { [weak self] battery in
            let copy = self?.state.value.copy()
            copy?.batteryLevel = BatteryValueModel(currentValue: battery?.batteryLevel, alertLevel: battery?.alertLevel ?? AlertLevel.none)
            self?.state.set(copy)
        }
    }

    /// Starts watcher for remote name.
    func listenRemoteName(_ remoteControl: RemoteControl) {
        remoteNameRef = remoteControl.getName(observer: { [weak self] name in
            let copy = self?.state.value.copy()
            copy?.remoteName = name ?? L10n.remoteDetailsControllerInfos
            self?.state.set(copy)
        })
    }

    /// Starts watcher for remote Magnetometer.
    func listenMagnetometer(_ remoteControl: RemoteControl) {
        magnetometerRef = remoteControl.getPeripheral(Peripherals.magnetometer) { [weak self] magnetometer in
            let copy = self?.state.value.copy()
            copy?.needCalibration = magnetometer?.calibrationState == .required
            self?.state.set(copy)
        }
    }

    /// Starts watcher for drone name.
    func listenDroneName(_ drone: Drone) {
        droneNameRef = drone.getName(observer: { [weak self] name in
            let copy = self?.state.value.copy()
            copy?.droneName = name
            self?.state.set(copy)
        })
    }

    /// Starts watcher for radio.
    func listenRadio(_ drone: Drone) {
        radioRef = drone.getInstrument(Instruments.radio) { [weak self] radio in
            let copy = self?.state.value.copy()
            copy?.wifiStrength = radio?.wifiStrength ?? WifiStrength.none
            self?.state.set(copy)
        }
    }

    /// Query remote update.
    func queryRemoteUpdate() {
        groundSdk.getFacility(Facilities.firmwareManager)?.queryRemoteUpdates()
    }
}
