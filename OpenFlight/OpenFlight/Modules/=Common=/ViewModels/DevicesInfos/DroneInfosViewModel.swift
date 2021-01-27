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

import GroundSdk
import UIKit

// MARK: - DroneInfosState
/// State for DroneInfosViewModel.

class DroneInfosState: DeviceConnectionState {
    // MARK: - Internal Properties
    /// Observable for current battery level.
    fileprivate(set) var batteryLevel: Observable<BatteryValueModel> = Observable(BatteryValueModel())
    /// Observable for wifi strength.
    fileprivate(set) var wifiStrength: Observable<WifiStrength> = Observable(WifiStrength.none)
    /// Observable for gps strength.
    fileprivate(set) var gpsStrength: Observable<GpsStrength> = Observable(GpsStrength.none)
    /// Observable for name.
    fileprivate(set) var droneName: Observable<String> = Observable(String())
    /// Observable for connection state.
    fileprivate(set) var droneConnectionState: Observable<DeviceState.ConnectionState> = Observable(DeviceState.ConnectionState.disconnected)
    /// Observable for drone update.
    fileprivate(set) var droneNeedUpdate: Observable<Bool> = Observable(false)
    /// Observable for drone gimbal calibration.
    fileprivate(set) var droneNeedGimbalCalibration: Observable<Bool> = Observable(false)
    /// Observable for drone magnetometer calibration.
    fileprivate(set) var droneNeedMagnetometerCalibration: Observable<Bool> = Observable(false)
    /// Observable for drone stereo vision sensor calibration.
    fileprivate(set) var droneNeedStereoVisionSensorCalibration: Observable<Bool> = Observable(false)
    /// Observable for drone cellular access. Provides the icon according to network state.
    fileprivate(set) var cellularNetworkIcon: Observable<UIImage> = Observable(Asset.Cellular.ic4GNoSignal.image)
    /// Observable for drone cellular access availability.
    fileprivate(set) var isCellularAvailable: Observable<Bool> = Observable(false)

    // MARK: - Override Funcs
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: connection state
    ///    - batteryLevel: current battery
    ///    - wifiStrength: wifi signal
    ///    - gpsStrength: current recording function state
    ///    - droneName: drone name
    ///    - droneConnectionState: drone connection state
    ///    - droneNeedUpdate: boolean for drone update state
    ///    - droneNeedGimbalCalibration: boolean for gimbal calibration
    ///    - droneNeedMagnetometerCalibration: boolean for magnetometer calibration
    ///    - droneNeedStereoVisionSensorCalibration: boolean for stereo vision sensor calibration
    ///    - cellularNetworkIcon: current cellular access icon according to network state
    ///    - isCellularAvailable: drone cellular access availability
    init(connectionState: DeviceState.ConnectionState,
         batteryLevel: Observable<BatteryValueModel>,
         wifiStrength: Observable<WifiStrength>,
         gpsStrength: Observable<GpsStrength>,
         droneName: Observable<String>,
         droneConnectionState: Observable<DeviceState.ConnectionState>,
         droneNeedUpdate: Observable<Bool>,
         droneNeedGimbalCalibration: Observable<Bool>,
         droneNeedMagnetometerCalibration: Observable<Bool>,
         droneNeedStereoVisionSensorCalibration: Observable<Bool>,
         cellularNetworkIcon: Observable<UIImage>,
         isCellularAvailable: Observable<Bool>) {
        super.init(connectionState: connectionState)
        self.batteryLevel = batteryLevel
        self.wifiStrength = wifiStrength
        self.gpsStrength = gpsStrength
        self.droneName = droneName
        self.droneConnectionState = droneConnectionState
        self.droneNeedUpdate = droneNeedUpdate
        self.droneNeedGimbalCalibration = droneNeedGimbalCalibration
        self.droneNeedMagnetometerCalibration = droneNeedMagnetometerCalibration
        self.droneNeedStereoVisionSensorCalibration = droneNeedStereoVisionSensorCalibration
        self.cellularNetworkIcon = cellularNetworkIcon
        self.isCellularAvailable = isCellularAvailable
    }

    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? DroneDetailsState else {
            return false
        }
        return super.isEqual(to: other)
            && self.batteryLevel.value == other.batteryLevel.value
            && self.wifiStrength.value == other.wifiStrength.value
            && self.gpsStrength.value == other.gpsStrength.value
            && self.droneName.value == other.droneName.value
            && self.droneConnectionState.value == other.droneConnectionState.value
            && self.droneNeedUpdate.value == other.droneNeedUpdate.value
            && self.droneNeedGimbalCalibration.value == other.droneNeedGimbalCalibration.value
            && self.droneNeedMagnetometerCalibration.value == other.droneNeedMagnetometerCalibration.value
            && self.droneNeedStereoVisionSensorCalibration.value == other.droneNeedStereoVisionSensorCalibration.value
            && self.cellularNetworkIcon.value == other.cellularNetworkIcon.value
            && self.isCellularAvailable.value == other.isCellularAvailable.value
    }
}

// MARK: - DroneInfosViewModel
/// ViewModel for DroneInfos, notifies on battery level, wifi strength and gps strength changes.

class DroneInfosViewModel<T: DroneInfosState>: DroneWatcherViewModel<T> {
    // MARK: - Private Properties
    private var batteryInfoRef: Ref<BatteryInfo>?
    private var radioRef: Ref<Radio>?
    private var gpsRef: Ref<Gps>?
    private var nameRef: Ref<String>?
    private var connectionStateRef: Ref<DeviceState>?
    private var updaterRef: Ref<Updater>?
    private var gimbalRef: Ref<Gimbal>?
    private var magnetometerRef: Ref<Magnetometer>?
    private var stereoVisionSensorRef: Ref<StereoVisionSensor>?
    private var cellularRef: Ref<Cellular>?

    // MARK: - Init
    private init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - stateDidUpdate: state update
    ///    - batteryLevelDidChange: called when battery level changes
    ///    - wifiStrengthDidChange: called when wifi strength changes
    ///    - gpsStrengthDidChange: called when gps strength changes
    ///    - nameDidChange: called when name changes
    ///    - connectionStateDidChange: called when connection state changes
    ///    - needUpdateDidChange: called when drone update availability changes
    ///    - cellularStateDidChange: called when drone cellular changes
    ///    - isCellularAvailabilityChange: called when drone cellular availability changes
    init(stateDidUpdate: ((DroneInfosState) -> Void)? = nil,
         batteryLevelDidChange: ((BatteryValueModel) -> Void)? = nil,
         wifiStrengthDidChange: ((WifiStrength) -> Void)? = nil,
         gpsStrengthDidChange: ((GpsStrength) -> Void)? = nil,
         nameDidChange: ((String) -> Void)? = nil,
         connectionStateDidChange: ((DeviceState.ConnectionState) -> Void)? = nil,
         needUpdateDidChange: ((Bool) -> Void)? = nil,
         cellularStateDidChange: ((UIImage) -> Void)? = nil,
         isCellularAvailabilityChange: ((Bool) -> Void)? = nil) {
        super.init(stateDidUpdate: stateDidUpdate)
        state.value.batteryLevel.valueChanged = batteryLevelDidChange
        state.value.wifiStrength.valueChanged = wifiStrengthDidChange
        state.value.gpsStrength.valueChanged = gpsStrengthDidChange
        state.value.droneName.valueChanged = nameDidChange
        state.value.droneConnectionState.valueChanged = connectionStateDidChange
        state.value.droneNeedUpdate.valueChanged = needUpdateDidChange
        state.value.cellularNetworkIcon.valueChanged = cellularStateDidChange
        state.value.isCellularAvailable.valueChanged = isCellularAvailabilityChange
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        listenBatteryInfo(drone: drone)
        listenRadio(drone: drone)
        listenGps(drone: drone)
        listenName(drone: drone)
        listenConnectionState(drone: drone)
        listenDroneUpdate(drone: drone)
        listenDroneMagnetometer(drone)
        listenDroneStereoVisionSensor(drone)
        listenDroneGimbal(drone)
        listenDroneCellularAccess(drone)
    }
}

// MARK: - Private Funcs
private extension DroneInfosViewModel {
    /// Starts watcher for battery info.
    func listenBatteryInfo(drone: Drone) {
        batteryInfoRef = drone.getInstrument(Instruments.batteryInfo) { [weak self] batteryInfo in
            guard let batteryInfo = batteryInfo else {
                self?.state.value.batteryLevel.set(BatteryValueModel(currentValue: nil,
                                                                     alertLevel: .none))
                return
            }
            self?.state.value.batteryLevel.set(batteryInfo.batteryValueModel)
        }
    }

    /// Starts watcher for radio.
    func listenRadio(drone: Drone) {
        radioRef = drone.getInstrument(Instruments.radio) { [weak self] radio in
            guard let radio = radio else {
                self?.state.value.wifiStrength.set(WifiStrength.none)
                return
            }
            self?.state.value.wifiStrength.set(radio.wifiStrength)
        }
    }

    /// Starts watcher for gps.
    func listenGps(drone: Drone) {
        gpsRef = drone.getInstrument(Instruments.gps) { [weak self] gps in
            guard let gps = gps else {
                self?.state.value.gpsStrength.set(GpsStrength.none)
                return
            }
            self?.state.value.gpsStrength.set(gps.gpsStrength)
        }
    }

    /// Starts watcher for name.
    func listenName(drone: Drone) {
        nameRef = drone.getName(observer: { [weak self] name in
            guard let name = name else {
                self?.state.value.droneName.set(String())
                return
            }
            self?.state.value.droneName.set(name)
        })
    }

    /// Starts watcher for connection state.
    func listenConnectionState(drone: Drone) {
        connectionStateRef = drone.getState { [weak self] deviceState in
            self?.state.value.droneConnectionState.set(deviceState?.connectionState)
            self?.updateCellular()
        }
    }

    /// Starts watcher for drone update.
    func listenDroneUpdate(drone: Drone) {
        updaterRef = drone.getPeripheral(Peripherals.updater) { [weak self] updater in
            if let updater = updater {
                self?.state.value.droneNeedUpdate.set(!updater.isUpToDate)
            }
        }
    }

    /// Starts watcher for drone gimbal state.
    func listenDroneGimbal(_ drone: Drone) {
        gimbalRef = drone.getPeripheral(Peripherals.gimbal) { [weak self] gimbal in
            self?.state.value.droneNeedGimbalCalibration.set(gimbal?.calibrated)
        }
    }

    /// Starts watcher for drone magnetometer state.
    func listenDroneMagnetometer(_ drone: Drone) {
        magnetometerRef = drone.getPeripheral(Peripherals.magnetometer) { [weak self] magnetometer in
            self?.state.value.droneNeedMagnetometerCalibration.set(magnetometer?.calibrationState == .required)
        }
    }

    /// Starts watcher for drone stereo vision sensor state.
    func listenDroneStereoVisionSensor(_ drone: Drone) {
        stereoVisionSensorRef = drone.getPeripheral(Peripherals.stereoVisionSensor) { [weak self] stereoVisionSensor in
            self?.state.value.droneNeedStereoVisionSensorCalibration.set(stereoVisionSensor?.isCalibrated == false)
        }
    }

    /// Starts watcher for drone cellular access state.
    func listenDroneCellularAccess(_ drone: Drone) {
        cellularRef = drone.getPeripheral(Peripherals.cellular) { [weak self] _ in
            self?.updateCellular()
        }
        updateCellular()
    }

    /// Updates 4G state according to Cellular peripheral.
    func updateCellular() {
        guard drone?.isCellularAvailable == true else {
            // Set a default icon when not available.
            state.value.cellularNetworkIcon.set(Asset.Cellular.ic4GNoSignal.image)
            state.value.isCellularAvailable.set(false)
            return
        }

        state.value.cellularNetworkIcon.set(drone?.cellularIcon)
        state.value.isCellularAvailable.set(true)
    }
}
