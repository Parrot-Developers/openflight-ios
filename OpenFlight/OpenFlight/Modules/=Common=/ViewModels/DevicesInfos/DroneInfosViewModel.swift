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
import SwiftyUserDefaults

// MARK: - DroneInfosState
/// State for DroneInfosViewModel.
final class DroneInfosState: DeviceConnectionState {
    // MARK: - Internal Properties
    /// Drone's battery level.
    fileprivate(set) var batteryLevel: BatteryValueModel = BatteryValueModel()
    /// Drone's WiFi strength.
    fileprivate(set) var wifiStrength: WifiStrength = .offline
    /// Drone's GPS strength.
    fileprivate(set) var gpsStrength: GpsStrength = .none
    /// Drone's GPS satellite count.
    fileprivate(set) var satelliteCount: Int?
    /// Drone's model.
    fileprivate(set) var droneModel: String = Style.dash
    /// Drone's name.
    fileprivate(set) var droneName: String = Style.dash
    /// Drone's gimbal status.
    fileprivate(set) var gimbalStatus: CalibratableGimbalState?
    /// Drone's front stereo gimbal status.
    fileprivate(set) var frontStereoGimbalStatus: FrontStereoGimbalState?
    /// Drone's magnetometer status.
    fileprivate(set) var magnetometerStatus: MagnetometerCalibrationState?
    /// Drone's stereo vision sensor status.
    fileprivate(set) var stereoVisionStatus: StereoVisionSensorsCalibrationState?
    /// Drone's cellular strength.
    fileprivate(set) var cellularStrength: CellularStrength = .offline
    /// Drone's current network link. It can be cellular or wlan one.
    fileprivate(set) var currentLink: NetworkControlLinkType = .wlan
    /// Drone's current copter motor errors.
    fileprivate(set) var copterMotorsErrors: Set<CopterMotor>?

    /// Returns true if drone currently requires a calibration.
    var requiresCalibration: Bool {
        return gimbalStatus == .needed
            || magnetometerStatus == .required
            || stereoVisionStatus == .needed
    }

    // MARK: Helpers
    /// Gives calibration text.
    var calibrationText: String? {
        if requiresCalibration {
            return L10n.droneCalibrationRequired
        } else if gimbalStatus == .recommended {
            return L10n.droneCalibrationRecommended
        }

        return nil
    }

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
    ///    - gpsStrength: current gps strength
    ///    - satelliteCount: drone's gps satellite count
    ///    - droneModel: drone's model
    ///    - droneName: drone's name
    ///    - gimbalStatus: drone's gimbal status
    ///    - frontStereoGimbalStatus: drone's front stereo status
    ///    - magnetometerStatus: drone's magnetometer status
    ///    - stereoVisionStatus: drone's stereo vision sensor status
    ///    - cellularStrength: current cellular signal
    ///    - currentLink: current network link
    ///    - copterMotorsErrors: drone's copter motor errors
    init(connectionState: DeviceState.ConnectionState,
         batteryLevel: BatteryValueModel,
         wifiStrength: WifiStrength,
         gpsStrength: GpsStrength,
         satelliteCount: Int?,
         droneModel: String,
         droneName: String,
         gimbalStatus: CalibratableGimbalState?,
         frontStereoGimbalStatus: FrontStereoGimbalState?,
         magnetometerStatus: MagnetometerCalibrationState?,
         stereoVisionStatus: StereoVisionSensorsCalibrationState?,
         cellularStrength: CellularStrength,
         currentLink: NetworkControlLinkType,
         copterMotorsErrors: Set<CopterMotor>?) {
        super.init(connectionState: connectionState)

        self.batteryLevel = batteryLevel
        self.wifiStrength = wifiStrength
        self.gpsStrength = gpsStrength
        self.satelliteCount = satelliteCount
        self.droneModel = droneModel
        self.droneName = droneName
        self.gimbalStatus = gimbalStatus
        self.frontStereoGimbalStatus = frontStereoGimbalStatus
        self.magnetometerStatus = magnetometerStatus
        self.stereoVisionStatus = stereoVisionStatus
        self.cellularStrength = cellularStrength
        self.currentLink = currentLink
        self.copterMotorsErrors = copterMotorsErrors
    }

    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? DroneInfosState else { return false }

        return super.isEqual(to: other)
            && self.batteryLevel == other.batteryLevel
            && self.wifiStrength == other.wifiStrength
            && self.gpsStrength == other.gpsStrength
            && self.satelliteCount == other.satelliteCount
            && self.droneModel == other.droneModel
            && self.droneName == other.droneName
            && self.gimbalStatus == other.gimbalStatus
            && self.frontStereoGimbalStatus == other.frontStereoGimbalStatus
            && self.magnetometerStatus == other.magnetometerStatus
            && self.stereoVisionStatus == other.stereoVisionStatus
            && self.cellularStrength == other.cellularStrength
            && self.currentLink == other.currentLink
            && self.copterMotorsErrors == other.copterMotorsErrors
    }

    override func copy() -> DroneInfosState {
        return DroneInfosState(connectionState: connectionState,
                               batteryLevel: batteryLevel,
                               wifiStrength: wifiStrength,
                               gpsStrength: gpsStrength,
                               satelliteCount: satelliteCount,
                               droneModel: droneModel,
                               droneName: droneName,
                               gimbalStatus: gimbalStatus,
                               frontStereoGimbalStatus: frontStereoGimbalStatus,
                               magnetometerStatus: magnetometerStatus,
                               stereoVisionStatus: stereoVisionStatus,
                               cellularStrength: cellularStrength,
                               currentLink: currentLink,
                               copterMotorsErrors: copterMotorsErrors)
    }
}

// MARK: - DroneInfosViewModel
/// ViewModel for DroneInfos, notifies on battery level, wifi strength and gps strength changes.
final class DroneInfosViewModel: DroneStateViewModel<DroneInfosState> {
    // MARK: - Private Properties
    private var batteryInfoRef: Ref<BatteryInfo>?
    private var radioRef: Ref<Radio>?
    private var gpsRef: Ref<Gps>?
    private var nameRef: Ref<String>?
    private var connectionStateRef: Ref<DeviceState>?
    private var gimbalRef: Ref<Gimbal>?
    private var frontStereoGimbalRef: Ref<FrontStereoGimbal>?
    private var magnetometerRef: Ref<Magnetometer>?
    private var stereoVisionSensorRef: Ref<StereoVisionSensor>?
    private var cellularRef: Ref<Cellular>?
    private var networkControlRef: Ref<NetworkControl>?
    private var motorsRef: Ref<CopterMotors>?

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        let copy = self.state.value.copy()
        copy.droneModel = drone.model.publicName
        self.state.set(copy)

        listenBatteryInfo(drone: drone)
        listenRadio(drone: drone)
        listenGps(drone: drone)
        listenName(drone: drone)
        listenMagnetometer(drone)
        listenStereoVisionSensor(drone)
        listenGimbal(drone)
        listenFrontStereoGimbal(drone)
        listenCellular(drone)
        listenNetworkControl(drone)
        listenMotors(drone)
    }

    override func droneConnectionStateDidChange() {
        updateCellularStrength()
    }
}

// MARK: - Private Funcs
/// Ref Listeners.
private extension DroneInfosViewModel {
    // MARK: - Battery
    /// Starts watcher for battery info.
    func listenBatteryInfo(drone: Drone) {
        batteryInfoRef = drone.getInstrument(Instruments.batteryInfo) { [weak self] batteryInfo in
            let copy = self?.state.value.copy()
            let batteryLevel = BatteryValueModel(currentValue: batteryInfo?.batteryLevel)
            copy?.batteryLevel = batteryLevel
            self?.state.set(copy)
        }
    }

    /// Updates battery level.
    ///
    /// - Parameters:
    ///    - batteryInfo: battery info instrument
    func updateBatteryLevel(_ batteryInfo: BatteryInfo?) {
        let copy = self.state.value.copy()
        copy.batteryLevel = BatteryValueModel(currentValue: batteryInfo?.batteryLevel)
        self.state.set(copy)
    }

    // MARK: - WiFi
    /// Starts watcher for radio.
    func listenRadio(drone: Drone) {
        radioRef = drone.getInstrument(Instruments.radio) { [weak self] _ in
            self?.updateWifiStrength()
        }
    }

    /// Updates Wi-Fi signal strength.
    func updateWifiStrength() {
        let copy = self.state.value.copy()
        copy.wifiStrength = drone?.wifiStrength ?? .offline
        self.state.set(copy)
    }

    // MARK: - GPS
    /// Starts watcher for gps.
    func listenGps(drone: Drone) {
        gpsRef = drone.getInstrument(Instruments.gps) { [weak self] gps in
            self?.updateGpsStrength(gps)
        }
    }

    /// Updates GPS strength.
    ///
    /// - Parameters:
    ///    - gps: gps instrument
    func updateGpsStrength(_ gps: Gps?) {
        let copy = self.state.value.copy()
        copy.gpsStrength = gps?.gpsStrength ?? .none
        copy.satelliteCount = gps?.satelliteCount
        self.state.set(copy)
    }

    // MARK: - Name
    /// Starts watcher for name.
    func listenName(drone: Drone) {
        nameRef = drone.getName(observer: { [weak self] name in
            self?.updateName(name)
        })
    }

    /// Updates name.
    ///
    /// - Parameters:
    ///    - name: drone's name
    func updateName(_ name: String?) {
        let copy = self.state.value.copy()
        copy.droneName = name ?? Style.dash
        self.state.set(copy)
    }

    // MARK: - Gimbal and Front Stereo
    /// Starts watcher for drone gimbal state.
    func listenGimbal(_ drone: Drone) {
        gimbalRef = drone.getPeripheral(Peripherals.gimbal) { [weak self] _ in
            self?.updateGimbalAndFrontStereo()
        }
    }

    /// Starts watcher for drone front stereo gimbal state.
    func listenFrontStereoGimbal(_ drone: Drone) {
        frontStereoGimbalRef = drone.getPeripheral(Peripherals.frontStereoGimbal) { [weak self] _ in
            self?.updateGimbalAndFrontStereo()
        }
    }

    /// Updates gimbal and front stereo calibration state.
    func updateGimbalAndFrontStereo() {
        let copy = state.value.copy()

        guard let gimbal = drone?.getPeripheral(Peripherals.gimbal),
              let frontStereoGimbal = drone?.getPeripheral(Peripherals.frontStereoGimbal) else {
            copy.gimbalStatus = .unavailable
            copy.frontStereoGimbalStatus = .unavailable
            state.set(copy)
            return
        }

        copy.gimbalStatus = gimbal.state
        copy.frontStereoGimbalStatus = frontStereoGimbal.state
        state.set(copy)
    }

    // MARK: - Magnetometer
    /// Starts watcher for drone magnetometer state.
    func listenMagnetometer(_ drone: Drone) {
        magnetometerRef = drone.getPeripheral(Peripherals.magnetometer) { [weak self] magnetometer in
            self?.updateMagnetometerState(magnetometer)
        }
    }

    /// Updates magnetometer calibration state.
    ///
    /// - Parameters:
    ///    - magnetometer: magnetometer peripheral
    func updateMagnetometerState(_ magnetometer: Magnetometer?) {
        let copy = self.state.value.copy()
        copy.magnetometerStatus = magnetometer?.calibrationState
        self.state.set(copy)
    }

    // MARK: - Stereo Vision Sensor
    /// Starts watcher for drone stereo vision sensor state.
    func listenStereoVisionSensor(_ drone: Drone) {
        stereoVisionSensorRef = drone.getPeripheral(Peripherals.stereoVisionSensor) { [weak self] stereoVisionSensor in
            self?.updateStereoVisionSensorState(stereoVisionSensor)
        }
    }

    /// Updates stereo vision sensor calibration state.
    ///
    /// - Parameters:
    ///    - stereVisionSensor: stereo vision sensor peripheral
    func updateStereoVisionSensorState(_ stereoVisionSensor: StereoVisionSensor?) {
        let copy = self.state.value.copy()
        copy.stereoVisionStatus = stereoVisionSensor?.isCalibrated ==  true ? .calibrated : .needed
        self.state.set(copy)
    }

    // MARK: - Cellular
    /// Starts watcher for drone cellular.
    func listenCellular(_ drone: Drone) {
        cellularRef = drone.getPeripheral(Peripherals.cellular) { [weak self] _ in
            self?.updateCellularStrength()
        }

        updateCellularStrength()
    }

    /// Updates cellular signal strength.
    func updateCellularStrength() {
        let copy = self.state.value.copy()
        if drone?.isAlreadyPaired == false {
            copy.cellularStrength = .offline
        } else {
            copy.cellularStrength = drone?.cellularStrength ?? .offline
        }

        self.state.set(copy)
    }

    // MARK: - Network Control
    /// Starts watcher for drone network control.
    func listenNetworkControl(_ drone: Drone) {
        networkControlRef = drone.getPeripheral(Peripherals.networkControl) { [weak self] networkControl in
            self?.updateCurrentLink(networkControl)
            self?.updateCellularStrength()
        }
    }

    /// Updates current link.
    ///
    /// - Parameters:
    ///    - networkControl: network control peripheral
    func updateCurrentLink(_ networkControl: NetworkControl?) {
        let copy = self.state.value.copy()
        copy.currentLink = networkControl?.currentLink ?? .wlan
        self.state.set(copy)
    }

    // MARK: - Motors
    /// Starts watcher for drone's motors.
    func listenMotors(_ drone: Drone) {
        motorsRef = drone.getPeripheral(Peripherals.copterMotors) { [weak self] copterMotors in
            self?.updateMotorsError(copterMotors)
        }
    }

    /// Updates motor errors.
    ///
    /// - Parameters:
    ///    - copterMotors: copter motors peripheral
    func updateMotorsError(_ copterMotors: CopterMotors?) {
        let copy = self.state.value.copy()
        copy.copterMotorsErrors = copterMotors?.motorsCurrentlyInError
        self.state.set(copy)
    }
}
