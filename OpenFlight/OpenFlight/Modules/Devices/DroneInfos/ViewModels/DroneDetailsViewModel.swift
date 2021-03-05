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

/// State for `DroneDetailsViewModel`.
final class DroneDetailsState: DroneInfosState {
    // MARK: - Internal Properties
    /// Drone copter motors state.
    fileprivate(set) var copterMotorsError: Set<CopterMotor>?
    /// Current gimbal state.
    fileprivate(set) var gimbalState: DroneGimbalStatus?
    /// Current Stereo Vision state.
    fileprivate(set) var stereoVisionState: DroneStereoVisionStatus?
    /// Number of reachable satellite.
    fileprivate(set) var satelliteCount: Int?

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: connection state
    ///    - copterMotors: drone copter motors state
    ///    - gimbalState: gimbal state
    ///    - stereoVisionState: stereo vision state
    ///    - satelliteCount: number of reachable satellite
    ///    - batteryLevel: battery level
    ///    - wifiStrength: wifi signal
    ///    - gpsStrength: gps signal
    ///    - droneName: drone name
    ///    - droneConnectionState: drone connection state
    ///    - droneNeedGimbalCalibration: tells if the drone need a gimbal calibration
    ///    - droneNeedMagnetometerCalibration: tells if the drone need a magnetometer calibration
    ///    - droneNeedStereoVisionSensorCalibration: tells if the drone need a stereo vision sensor calibration
    ///    - cellularStrength: cellular signal strength
    ///    - currentLink: provides current link
    init(connectionState: DeviceState.ConnectionState,
         copterMotors: Set<CopterMotor>?,
         gimbalState: DroneGimbalStatus?,
         stereoVisionState: DroneStereoVisionStatus?,
         satelliteCount: Int?,
         batteryLevel: Observable<BatteryValueModel>,
         wifiStrength: Observable<WifiStrength>,
         gpsStrength: Observable<GpsStrength>,
         droneName: Observable<String>,
         droneConnectionState: Observable<DeviceState.ConnectionState>,
         droneNeedGimbalCalibration: Observable<Bool>,
         droneNeedMagnetometerCalibration: Observable<Bool>,
         droneNeedStereoVisionSensorCalibration: Observable<Bool>,
         cellularStrength: Observable<CellularStrength>,
         currentLink: Observable<NetworkControlLinkType>) {
        super.init(connectionState: connectionState,
                   batteryLevel: batteryLevel,
                   wifiStrength: wifiStrength,
                   gpsStrength: gpsStrength,
                   droneName: droneName,
                   droneConnectionState: droneConnectionState,
                   droneNeedGimbalCalibration: droneNeedGimbalCalibration,
                   droneNeedMagnetometerCalibration: droneNeedMagnetometerCalibration,
                   droneNeedStereoVisionSensorCalibration: droneNeedStereoVisionSensorCalibration,
                   cellularStrength: cellularStrength,
                   currentLink: currentLink)

        self.copterMotorsError = copterMotors
        self.gimbalState = gimbalState
        self.stereoVisionState = stereoVisionState
        self.satelliteCount = satelliteCount
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? DroneDetailsState else {
            return false
        }
        return super.isEqual(to: other)
            && self.copterMotorsError == other.copterMotorsError
            && self.gimbalState == other.gimbalState
            && self.stereoVisionState == other.stereoVisionState
            && self.satelliteCount == satelliteCount
    }

    override func copy() -> DroneDetailsState {
        let copy = DroneDetailsState(connectionState: connectionState,
                                     copterMotors: copterMotorsError,
                                     gimbalState: gimbalState,
                                     stereoVisionState: stereoVisionState,
                                     satelliteCount: satelliteCount,
                                     batteryLevel: batteryLevel,
                                     wifiStrength: wifiStrength,
                                     gpsStrength: gpsStrength,
                                     droneName: droneName,
                                     droneConnectionState: droneConnectionState,
                                     droneNeedGimbalCalibration: droneNeedGimbalCalibration,
                                     droneNeedMagnetometerCalibration: droneNeedMagnetometerCalibration,
                                     droneNeedStereoVisionSensorCalibration: droneNeedStereoVisionSensorCalibration,
                                     cellularStrength: cellularStrength,
                                     currentLink: currentLink)
        return copy

    }
}

/// View Model for Drone details screen.
final class DroneDetailsViewModel: DroneInfosViewModel<DroneDetailsState> {
    // MARK: - Private Properties
    private var motorsRef: Ref<CopterMotors>?
    private var gimbalRef: Ref<Gimbal>?
    private var stereoVisionSensorRef: Ref<StereoVisionSensor>?
    private var gpsRef: Ref<Gps>?

    // MARK: - Internal Properties
    /// Returns drone model.
    var droneModel: String {
        return drone?.model.publicName ?? state.value.droneName.value
    }

    // MARK: - Init
    override init(stateDidUpdate: ((DroneDetailsState) -> Void)? = nil,
                  batteryLevelDidChange: ((BatteryValueModel) -> Void)? = nil,
                  wifiStrengthDidChange: ((WifiStrength) -> Void)? = nil,
                  gpsStrengthDidChange: ((GpsStrength) -> Void)? = nil,
                  nameDidChange: ((String) -> Void)? = nil,
                  connectionStateDidChange: ((DeviceState.ConnectionState) -> Void)? = nil,
                  cellularStrengthDidChange: ((CellularStrength) -> Void)? = nil,
                  currentLinkDidChange: ((NetworkControlLinkType) -> Void)? = nil) {
        super.init(batteryLevelDidChange: batteryLevelDidChange,
                   wifiStrengthDidChange: wifiStrengthDidChange,
                   gpsStrengthDidChange: gpsStrengthDidChange,
                   nameDidChange: nameDidChange,
                   connectionStateDidChange: connectionStateDidChange,
                   cellularStrengthDidChange: cellularStrengthDidChange,
                   currentLinkDidChange: currentLinkDidChange)

        self.state.valueChanged = stateDidUpdate
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenGimbal(drone)
        listenGps(drone)
        listenStereoVisionSensor(drone)
        listenMotorsError(drone)
    }
}

// MARK: - Private Funcs
private extension DroneDetailsViewModel {
    /// Starts watcher for gimbal.
    func listenGimbal(_ drone: Drone) {
        gimbalRef = drone.getPeripheral(Peripherals.gimbal) { [weak self] gimbal in
            let copy = self?.state.value.copy()

            if gimbal?.currentErrors.isEmpty == true && gimbal?.calibrated == true {
                copy?.gimbalState = .ready
            } else if gimbal?.currentErrors.contains(.critical) == true {
                copy?.gimbalState = .critical
            } else {
                copy?.gimbalState = .warning
            }

            self?.state.set(copy)
        }
    }

    /// Starts watcher for Stereo Vision Sensor.
    func listenStereoVisionSensor(_ drone: Drone) {
        stereoVisionSensorRef = drone.getPeripheral(Peripherals.stereoVisionSensor) { [weak self] stereoVisionSensor in
            let copy = self?.state.value.copy()
            copy?.stereoVisionState = stereoVisionSensor?.isCalibrated ==  true ? .ready : .warning
            self?.state.set(copy)
        }
    }

    /// Starts watcher for drone gps.
    func listenGps(_ drone: Drone) {
        gpsRef = drone.getInstrument(Instruments.gps) { [weak self] gps in
            let copy = self?.state.value.copy()
            copy?.satelliteCount = gps?.satelliteCount
            self?.state.set(copy)
        }
    }

    /// Starts watcher for motors error.
    func listenMotorsError(_ drone: Drone) {
        motorsRef = drone.getPeripheral(Peripherals.copterMotors) { [weak self] copterMotors in
            let copy = self?.state.value.copy()
            copy?.copterMotorsError = copterMotors?.motorsCurrentlyInError
            self?.state.set(copy)
        }
    }
}
