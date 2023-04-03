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

/// This class links the drone's properties from groundSDK to the published properties of our view model
final class DroneInfosViewModel {

    // MARK: - Internal Published Properties
    /// Drone's battery level.
    @Published private(set) var batteryLevel: BatteryValueModel = BatteryValueModel()
    /// Drone's WiFi strength.
    @Published private(set) var wifiStrength: WifiStrength = .offline
    /// DRI status.
    @Published private(set) var driState: DriState = .off
    /// Drone's GPS strength.
    @Published private(set) var gpsStrength: GpsStrength = .none
    /// Drone's GPS satellite count.
    @Published private(set) var satelliteCount: Int?
    /// Drone's name.
    @Published private(set) var droneName: String = Style.dash
    /// Drone's model.
    @Published private(set) var droneModelName: String?
    /// Drone's gimbal error image.
    @Published private(set) var gimbalErrorImage: UIImage?
    /// Drone's gimbal status.
    @Published private(set) var gimbalStatus: CalibratableGimbalState?
    /// Drone's front stereo gimbal error image.
    @Published private(set) var frontStereoGimbalErrorImage: UIImage?
    /// Drone's front stereo gimbal status.
    @Published private(set) var frontStereoGimbalStatus: CalibratableGimbalState?
    /// Drone's magnetometer status.
    @Published private(set) var magnetometerStatus: MagnetometerCalibrationState?
    /// Drone's stereo vision sensor status.
    @Published private(set) var stereoVisionStatus: StereoVisionSensorCalibrationState?
    /// Drone's cellular strength.
    @Published private(set) var cellularStrength: CellularStrength = .deactivated
    /// Drone's current network link. It can be cellular or wlan one.
    @Published private(set) var currentLink: NetworkControlLinkType = .wlan
    /// Drone's current copter motor errors.
    @Published private(set) var copterMotorsErrors: Set<CopterMotor>?
    /// Current connection state
    @Published private(set) var connectionState: DeviceState.ConnectionState = .disconnected
    /// `true` if calibration is required.
    var isCalibrationRequired: Bool?
    /// `true` if calibration is recommended.
    var isCalibrationRecommended: Bool?

    /// Tells if a sim is inserted or not
    private(set) var simInserted: Bool = false

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var alarmsRef: Ref<Alarms>?
    private var driStatusRef: Ref<Dri>?
    private var batteryInfoRef: Ref<BatteryInfo>?
    private var gpsRef: Ref<Gps>?
    private var nameRef: Ref<String>?
    private var connectionStateRef: Ref<DeviceState>?
    private var magnetometerRef: Ref<Magnetometer>?
    private var stereoVisionSensorRef: Ref<StereoVisionSensor>?
    private var cellularRef: Ref<Cellular>?
    private var networkControlRef: Ref<NetworkControl>?
    private var motorsRef: Ref<CopterMotors>?
    private var gimbalRef: Ref<Gimbal>?
    private var frontStereoGimbalRef: Ref<FrontStereoGimbal>?

    init() {
        // TODO inject
        Services.hub.currentDroneHolder.dronePublisher
            .sink { [weak self] drone in
                guard let self = self else { return }
                self.listenModel(drone: drone)
                self.listenName(drone: drone)
                self.listenGimbal(drone: drone)
                self.listenFrontStereoGimbal(drone: drone)
                self.listenMagnetometer(drone: drone)
                self.listenStereoVisionSensor(drone: drone)
                self.listenMotors(drone: drone)
                self.listenConnectionState(drone: drone)
            }
            .store(in: &cancellables)

        Services.hub.connectedDroneHolder.dronePublisher
            .sink { [weak self] drone in
                guard let self = self else { return }
                self.listenBatteryInfo(drone: drone)
                self.listenGps(drone: drone)
                self.listenNetworkControl(drone: drone)
                self.listenAlarms(drone: drone)
                self.listenDriStatus(drone: drone)
                self.listenCellular(drone: drone)
            }
            .store(in: &cancellables)

        $gimbalStatus
            .combineLatest($magnetometerStatus, $stereoVisionStatus)
            .sink { [weak self] gimbal, magnetometer, stereoVision in
                guard let self = self else { return }
                self.isCalibrationRequired = gimbal == .needed
                || magnetometer == MagnetometerCalibrationState.required
                || stereoVision == .needed

                self.isCalibrationRecommended = magnetometer == MagnetometerCalibrationState.recommended
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
    func listenBatteryInfo(drone: Drone?) {
        // Starts watcher
        batteryInfoRef = drone?.getInstrument(Instruments.batteryInfo) { [weak self] batteryInfo in
            self?.updateBatteryLevel(drone: drone)
        }

        // Updates status
        updateBatteryLevel(drone: drone)
    }

    // MARK: - GPS
    /// Starts observing changes for gps strength and updates the gps Strength published property.
    ///
    /// - Parameter drone: the current drone
    func listenGps(drone: Drone?) {
        // Starts watcher
        gpsRef = drone?.getInstrument(Instruments.gps) { [weak self] _ in
            self?.updateGpsStatus(drone: drone)
        }

        // Update status
        updateGpsStatus(drone: drone)
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

    // MARK: - Gimbal and Front Stereo Gimbal
    /// Updates gimbal calibration state.
    ///
    /// - Parameter drone: the current drone
    func listenGimbal(drone: Drone) {
        gimbalRef = drone.getPeripheral(Peripherals.gimbal) { [weak self] gimbal in
            guard let self = self else { return }
            self.gimbalStatus = gimbal?.state ?? .calibrated
            self.gimbalErrorImage = gimbal?.errorImage
        }
    }

    /// Updates front stereo gimbal calibration state.
    ///
    /// - Parameter drone: the current drone
    func listenFrontStereoGimbal(drone: Drone) {
        frontStereoGimbalRef = drone.getPeripheral(Peripherals.frontStereoGimbal) { [weak self] frontStereoGimbal in
            guard let self = self else { return }
            self.frontStereoGimbalStatus = frontStereoGimbal?.state ?? .calibrated
            self.frontStereoGimbalErrorImage = frontStereoGimbal?.errorImage
        }
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
    func listenCellular(drone: Drone?) {
        // Starts watcher
        cellularRef = drone?.getPeripheral(Peripherals.cellular) { [weak self] cellularState in
            guard let self = self else { return }
            if let simInserted = cellularState?.isSimCardInserted {
                self.simInserted = simInserted
            }
            self.updateCellularStrength(drone: drone)
        }

        // Updates status
        updateCellularStrength(drone: drone)
    }

    /// Listens to dri status.
    ///
    /// - Parameter drone: drone to monitor
    func listenDriStatus(drone: Drone?) {
        driStatusRef = drone?.getPeripheral(Peripherals.dri) { [weak self] _ in
            self?.updateDriStatus(drone: drone)
        }
        updateDriStatus(drone: drone)
    }

    /// Listens to alarms instrument.
    ///
    /// - Parameter drone: drone to monitor
    func listenAlarms(drone: Drone?) {
        alarmsRef = drone?.getInstrument(Instruments.alarms) { [weak self] alarms in
            guard let self = self, let alarms = alarms else { return }

            if alarms.getAlarm(kind: .driFailing).level != .off {
                self.driState = .error
            } else if self.driState == .error && alarms.getAlarm(kind: .driFailing).level == .off {
                self.updateDriStatus(drone: drone)
            }
        }
    }

    // MARK: - Network Control
    /// Starts watcher for drone network control.
    ///
    /// - Parameter drone: the current drone
    func listenNetworkControl(drone: Drone?) {
        // Starts watcher
        networkControlRef = drone?.getPeripheral(Peripherals.networkControl) { [weak self] _ in
            self?.updateNetworkLink(drone: drone)
        }
        // Updates status
        updateNetworkLink(drone: drone)
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
        }
    }

    /// Updates the network link informations in our view model.
    ///
    /// - Parameter drone: the current drone
    func updateNetworkLink(drone: Drone?) {
        let networkControl = drone?.getPeripheral(Peripherals.networkControl)
        currentLink = networkControl?.currentLink ?? .wlan
        updateWifiStrength(drone: drone)
        updateCellularStrength(drone: drone)
    }

    /// Updates the gps status in our view model.
    ///
    /// - Parameter drone: the current drone
    func updateGpsStatus(drone: Drone?) {
        let gps = drone?.getInstrument(Instruments.gps)
        gpsStrength = gps?.gpsStrength ?? .none
        satelliteCount = gps?.satelliteCount
    }

    /// Updates the battery level in our view model.
    ///
    /// - Parameter drone: the current drone
    func updateBatteryLevel(drone: Drone?) {
        let batteryInfo = drone?.getInstrument(Instruments.batteryInfo)
        batteryLevel = BatteryValueModel(currentValue: batteryInfo?.batteryLevel)
    }

    /// Updates the dri status in our view model.
    ///
    /// - Parameters:
    ///   - drone: the current drone
    ///   - driErrorAlarm: a dri error alarm returned from the drone
    func updateDriStatus(drone: Drone?) {
        guard let drone = drone else {
            driState = .disconnected
            return
        }
        guard driState != .error else {
            return
        }

        let dri = drone.getPeripheral(Peripherals.dri)
        driState = dri?.mode?.value == true ? .active : .off
    }

    /// Updates the cellular strength in our view model.
    ///
    /// - Parameter drone: the current drone
    func updateCellularStrength(drone: Drone?) {
        guard let cellular = drone?.getPeripheral(Peripherals.cellular),
              cellular.isActivated else {
            cellularStrength = .deactivated
            return
        }

        guard let isConnected = drone?.isConnected, isConnected else {
            cellularStrength = .offline
            return
        }

        guard cellular.isSimCardInserted else {
            cellularStrength = .deactivated
            return
        }

        if cellular.simStatus != .ready
            || cellular.modemStatus != .online
            || cellular.mode.value != .data
            || cellular.networkStatus != .activated
            || cellular.registrationStatus == .denied
            || cellular.registrationStatus == .notRegistered {
            cellularStrength = .offline
        } else if let strength = drone?.getPeripheral(Peripherals.networkControl)?.cellularStrength {
            cellularStrength = strength
        } else {
            cellularStrength = .ko0On4
        }
    }

    func updateWifiStrength(drone: Drone?) {
        guard let isConnected = drone?.isConnected, isConnected else {
            wifiStrength = .offline
            return
        }

        let networkControl = drone?.getPeripheral(Peripherals.networkControl)
        wifiStrength = networkControl?.wifiStrength ?? .offline
    }
}
