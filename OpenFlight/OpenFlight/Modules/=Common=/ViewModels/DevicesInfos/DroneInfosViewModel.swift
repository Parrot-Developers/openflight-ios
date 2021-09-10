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

/// This class links the drone's properties from groundSDK to the published properties of our view model
final class DroneInfosViewModel {

    // MARK: - Internal Published Properties

    /// Drone's battery level.
    @Published private(set) var batteryLevel: BatteryValueModel = BatteryValueModel()
    /// Drone's WiFi strength.
    @Published private(set) var wifiStrength: WifiStrength?
    /// Drone's GPS strength.
    @Published private(set) var gpsStrength: GpsStrength = .none
    /// Drone's GPS satellite count.
    @Published private(set) var satelliteCount: Int?
    /// Drone's name.
    @Published private(set) var droneName: String = Style.dash
    /// Drone's model.
    @Published private(set) var droneModelName: String?
    /// Drone's gimbal status.
    @Published private(set) var gimbalStatus: CalibratableGimbalState?
    /// Drone's front stereo gimbal status.
    @Published private(set) var frontStereoGimbalStatus: FrontStereoGimbalState?
    /// Drone's magnetometer status.
    @Published private(set) var magnetometerStatus: MagnetometerCalibrationState?
    /// Drone's stereo vision sensor status.
    @Published private(set) var stereoVisionStatus: StereoVisionSensorsCalibrationState?
    /// Drone's cellular strength.
    @Published private(set) var cellularStrength: CellularStrength = .offline
    /// Drone's current network link. It can be cellular or wlan one.
    @Published private(set) var currentLink: NetworkControlLinkType = .wlan
    /// Drone's current copter motor errors.
    @Published private(set) var copterMotorsErrors: Set<CopterMotor>?
    /// Current connection state
    @Published private(set) var connectionState: DeviceState.ConnectionState = .disconnected

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private var batteryInfoRef: Ref<BatteryInfo>?
    private var gpsRef: Ref<Gps>?
    private var modelRef: Ref<String>?
    private var nameRef: Ref<String>?
    private var connectionStateRef: Ref<DeviceState>?
    private var gimbalRef: Ref<Gimbal>?
    private var frontStereoGimbalRef: Ref<FrontStereoGimbal>?
    private var magnetometerRef: Ref<Magnetometer>?
    private var stereoVisionSensorRef: Ref<StereoVisionSensor>?
    private var cellularRef: Ref<Cellular>?
    private var networkControlRef: Ref<NetworkControl>?
    private var motorsRef: Ref<CopterMotors>?

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

    init() {
        // TODO inject
        Services.hub.currentDroneHolder.dronePublisher
            .sink { [unowned self] drone in
                listenBatteryInfo(drone: drone)
                listenModel(drone: drone)
                listenName(drone: drone)
                listenGimbalAndFrontStereo(drone: drone)
                listenMagnetometer(drone: drone)
                listenStereoVisionSensor(drone: drone)
                listenCellular(drone: drone)
                listenNetworkControl(drone: drone)
                listenMotors(drone: drone)
                listenConnectionState(drone: drone)
            }
            .store(in: &cancellables)

        Services.hub.connectedDroneHolder.dronePublisher
            .sink { [unowned self] drone in
                listenGps(drone: drone)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Private Funcs
/// Ref Listeners.
private extension DroneInfosViewModel {

    /// Starts watcher for battery.
    ///
    /// - Parameter drone: the current drone
    func listenBatteryInfo(drone: Drone) {
        batteryInfoRef = drone.getInstrument(Instruments.batteryInfo) { [weak self] batteryInfo in
            let batteryLevel = BatteryValueModel(currentValue: batteryInfo?.batteryLevel)
            self?.batteryLevel = batteryLevel
        }
    }

    // MARK: - GPS

    /// Starts observing changes for gps strength and updates the gps Strength published property.
    ///
    /// - Parameter drone: the current drone
    func listenGps(drone: Drone?) {
        guard let drone = drone else {
            gpsStrength = .none
            satelliteCount = nil
            return
        }
        gpsRef = drone.getInstrument(Instruments.gps) { [weak self] gps in
            self?.gpsStrength = gps?.gpsStrength ?? .none
            self?.satelliteCount = gps?.satelliteCount
        }
    }

    // MARK: - Name

    /// Starts observing changes for the drone's name and updates the drone name published property.
    ///
    /// - Parameter drone: the current drone
    func listenName(drone: Drone) {
        nameRef = drone.getName(observer: { [weak self] name in
            self?.droneName = name ?? Style.dash
        })
    }

    /// Starts observing changes for the drone's model and updates the drone model name published property.
    ///
    /// - Parameter drone: the current drone
    func listenModel(drone: Drone) {
        self.droneModelName = drone.model.publicName
    }

    /// Updates gimbal and front stereo calibration state.
    ///
    /// - Parameter drone: the current drone
    func listenGimbalAndFrontStereo(drone: Drone) {
        guard let gimbal = drone.getPeripheral(Peripherals.gimbal),
              let frontStereoGimbal = drone.getPeripheral(Peripherals.frontStereoGimbal) else {
            self.gimbalStatus = .unavailable
            self.frontStereoGimbalStatus = .unavailable
            return
        }

        gimbalStatus = gimbal.state
        frontStereoGimbalStatus = frontStereoGimbal.state
    }

    // MARK: - Magnetometer

    /// Starts observing changes for magnetometer and updates the magnetometer status published property.
    ///
    /// - Parameter drone: the current drone
    func listenMagnetometer(drone: Drone) {
        magnetometerRef = drone.getPeripheral(Peripherals.magnetometer) { [weak self] magnetometer in
            self?.magnetometerStatus = magnetometer?.calibrationState
        }
    }

    // MARK: - Stereo Vision Sensor

    /// Starts observing changes for the drone stereo vision sensor state and updates the stereo vision sensor published property.
    ///
    /// - Parameter drone: the current drone
    func listenStereoVisionSensor(drone: Drone) {
        stereoVisionSensorRef = drone.getPeripheral(Peripherals.stereoVisionSensor) { [weak self] stereoVisionSensor in
            self?.stereoVisionStatus = stereoVisionSensor?.isCalibrated == true ? .calibrated : .needed
        }
    }

    // MARK: - Cellular

    /// Starts watcher for drone cellular.
    ///
    /// - Parameter drone: the current drone
    func listenCellular(drone: Drone) {
        cellularRef = drone.getPeripheral(Peripherals.cellular) { [weak self] _ in
            self?.updateCellularStrength(drone: drone)
        }
    }

    // MARK: - Network Control

    /// Starts watcher for drone network control.
    ///
    /// - Parameter drone: the current drone
    func listenNetworkControl(drone: Drone) {
        networkControlRef = drone.getPeripheral(Peripherals.networkControl) { [weak self] networkControl in
            self?.currentLink = networkControl?.currentLink ?? .wlan
            self?.wifiStrength = networkControl?.wifiStrength
            self?.updateCellularStrength(drone: drone)
        }
    }

    /// Updates the cellular strength in our view model.
    ///
    /// - Parameter drone: the current drone
    func updateCellularStrength(drone: Drone) {
        let cellular = drone.getPeripheral(Peripherals.cellular)

        if cellular?.isActivated != true {
            if drone.isConnected == false {
                cellularStrength = .offline
                return
            }
            cellularStrength = .deactivated
            return
        }

        if cellular?.simStatus != .ready
            || cellular?.modemStatus != .online
            || cellular?.mode.value != .data
            || cellular?.networkStatus != .activated
            || cellular?.registrationStatus == .denied
            || cellular?.registrationStatus == .notRegistered {
            cellularStrength = .offline
        } else if let strength = drone.getPeripheral(Peripherals.networkControl)?.cellularStrength {
            cellularStrength = strength
        } else {
            cellularStrength = .ko0On4
        }
    }

    // MARK: - Motors

    /// Starts watcher for drone's motors.
    ///
    /// - Parameter drone: the current drone
    func listenMotors(drone: Drone) {
        motorsRef = drone.getPeripheral(Peripherals.copterMotors) { [weak self] copterMotors in
            self?.copterMotorsErrors = copterMotors?.motorsCurrentlyInError
        }
    }

    /// Starts watcher for drone's connection state.
    ///
    /// - Parameter drone: the current drone
    func listenConnectionState(drone: Drone) {
        connectionStateRef = drone.getState { [weak self] state in
            self?.connectionState = state?.connectionState ?? .disconnected
            self?.updateCellularStrength(drone: drone)
        }
    }
}
