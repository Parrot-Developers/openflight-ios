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
import CoreLocation
import SwiftyUserDefaults

/// State for `DroneDetailsButtonsViewModel`.
final class DroneDetailsButtonsState: DeviceConnectionState {
    // MARK: - Internal Properties
    /// Drone's last known position.
    fileprivate(set) var lastKnownPosition: CLLocation?
    /// Whether a stereo vision sensor calibration is needed.
    fileprivate(set) var isStereoVisionSensorCalibrationNeeded: Bool = false
    /// Whether magnetometer calibration is needed.
    fileprivate(set) var isMagnetometerCalibrationNeeded: Bool = false
    /// Gimbal state.
    fileprivate(set) var gimbalState: CalibratableGimbalState?
    /// Whether a gimbal front stereo vision calibration is needed.
    fileprivate(set) var isGimbalFrontStereoCalibrationNeeded: Bool = false
    /// Drone's cellular network state.
    fileprivate(set) var cellularStateDescription: String?
    /// Drone's cellular connection status.
    fileprivate(set) var cellularStatus: DetailsCellularStatus = .noState
    /// Drone's flying state.
    fileprivate(set) var flyingState: FlyingIndicatorsState?

    // MARK: Helpers
    /// Tells if a calibration is needed.
    var isCalibrationNeeded: Bool {
        return isMagnetometerCalibrationNeeded
            || isStereoVisionSensorCalibrationNeeded
            || isGimbalFrontStereoCalibrationNeeded
    }

    /// Message to display on calibration button.
    var calibrationText: String? {
        if !isConnected() || flyingState == .flying {
            return Style.dash
        } else if isMagnetometerCalibrationNeeded {
            return L10n.droneDetailsCalibrationRequired
        } else if isStereoVisionSensorCalibrationNeeded {
            return L10n.droneDetailsCalibrationLoveRequired
        } else if isGimbalFrontStereoCalibrationNeeded {
            return L10n.droneDetailsCalibrationGimbalRequired
        } else {
            return nil
        }
    }

    /// Color for calibration text cell.
    var calibrationTextColor: ColorName? {
        if !isConnected() || flyingState == .flying {
            return .white50
        } else if isCalibrationNeeded {
            return .redTorch
        } else {
            return nil
        }
    }

    /// Background for calibration text cell.
    var calibrationBackgroundCellColor: ColorName? {
        if !isConnected() || flyingState == .flying {
            return .white10
        } else if isCalibrationNeeded {
            return .redTorch25
        } else {
            return nil
        }
    }

    /// Tells if we can display the cellular modal.
    var canShowCellular: Bool {
        return cellularStatus != .noState && isConnected()
    }

    /// Tells if calibration button is available.
    var isCalibrationButtonAvailable: Bool {
        return isConnected() && flyingState == .landed
    }

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: drone's connection state
    ///    - lastKnownPosition: drone's last known position
    ///    - gimbalState: gimbal state
    ///    - isStereoVisionSensorCalibrationNeeded: wheter a stereo vision sensor calibration is needed
    ///    - isMagnetometerCalibrationNeeded: wheter a magnetometer calibration is needed
    ///    - isGimbalFrontStereoCalibrationNeeded: wheter a gimbal front stereo calibration calibration is needed
    ///    - cellularStateDescription: cellular description state
    ///    - cellularStatus: current cellular status
    ///    - flyingState: flying state of the drone.
    init(connectionState: DeviceState.ConnectionState,
         lastKnownPosition: CLLocation?,
         gimbalState: CalibratableGimbalState?,
         isStereoVisionSensorCalibrationNeeded: Bool,
         isMagnetometerCalibrationNeeded: Bool,
         isGimbalFrontStereoCalibrationNeeded: Bool,
         cellularStateDescription: String?,
         cellularStatus: DetailsCellularStatus,
         flyingState: FlyingIndicatorsState?) {
        super.init(connectionState: connectionState)

        self.lastKnownPosition = lastKnownPosition
        self.gimbalState = gimbalState
        self.isStereoVisionSensorCalibrationNeeded = isStereoVisionSensorCalibrationNeeded
        self.isMagnetometerCalibrationNeeded = isMagnetometerCalibrationNeeded
        self.isGimbalFrontStereoCalibrationNeeded = isGimbalFrontStereoCalibrationNeeded
        self.cellularStateDescription = cellularStateDescription
        self.cellularStatus = cellularStatus
        self.flyingState = flyingState
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? DroneDetailsButtonsState else { return false }

        return super.isEqual(to: other)
            && self.lastKnownPosition == other.lastKnownPosition
            && self.gimbalState == other.gimbalState
            && self.isStereoVisionSensorCalibrationNeeded == other.isStereoVisionSensorCalibrationNeeded
            && self.isMagnetometerCalibrationNeeded == other.isMagnetometerCalibrationNeeded
            && self.isGimbalFrontStereoCalibrationNeeded == other.isGimbalFrontStereoCalibrationNeeded
            && self.cellularStateDescription == other.cellularStateDescription
            && self.cellularStatus == other.cellularStatus
            && self.flyingState == other.flyingState
    }

    override func copy() -> DroneDetailsButtonsState {
        return DroneDetailsButtonsState(connectionState: self.connectionState,
                                        lastKnownPosition: self.lastKnownPosition,
                                        gimbalState: self.gimbalState,
                                        isStereoVisionSensorCalibrationNeeded: self.isStereoVisionSensorCalibrationNeeded,
                                        isMagnetometerCalibrationNeeded: self.isMagnetometerCalibrationNeeded,
                                        isGimbalFrontStereoCalibrationNeeded: self.isGimbalFrontStereoCalibrationNeeded,
                                        cellularStateDescription: self.cellularStateDescription,
                                        cellularStatus: self.cellularStatus,
                                        flyingState: self.flyingState)
    }
}

/// View model for drone details buttons.
final class DroneDetailsButtonsViewModel: DroneStateViewModel<DroneDetailsButtonsState> {
    // MARK: - Internal Properties
    /// Returns true if the drone is already paired to MyParrot.
    var isDronePaired: Bool? {
        guard let uid = drone?.uid else { return false }

        return Defaults.cellularPairedDronesList.contains(uid)
    }

    // MARK: - Helper
    /// Message to display on calibration button.
    var calibrationText: String? {
        if state.value.calibrationText != nil {
            return state.value.calibrationText
        } else {
            guard let gimbal = drone?.getPeripheral(Peripherals.gimbal) else {
                return L10n.droneDetailsCalibrationOk
            }

            switch gimbal.state {
            case .calibrated:
                return L10n.droneDetailsCalibrationOk
            case .needed,
                 .error:
                return L10n.droneDetailsCalibrationGimbalRequired
            case .recommended:
                return L10n.droneDetailsCalibrationGimbalRecommended
            }
        }
    }

    /// Calibration description color.
    var calibrationTextColor: ColorName? {
        if state.value.calibrationText != nil {
            return state.value.calibrationTextColor
        } else {
            return drone?.getPeripheral(Peripherals.gimbal)?.subtextColor ?? .white10
        }
    }

    /// Background color for calibration cell.
    var calibrationTextBackgroundColor: ColorName? {
        if state.value.calibrationBackgroundCellColor != nil {
            return state.value.calibrationBackgroundCellColor
        } else {
            guard let gimbal = drone?.getPeripheral(Peripherals.gimbal) else {
                return .white10
            }

            return gimbal.backgroundColor
        }
    }

    // MARK: - Private Properties
    private var gpsRef: Ref<Gps>?
    private var gimbalRef: Ref<Gimbal>?
    private var stereoVisionSensorRef: Ref<StereoVisionSensor>?
    private var magnetometerRef: Ref<MagnetometerWith3StepCalibration>?
    private var frontStereoGimbalRef: Ref<FrontStereoGimbal>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private let cellularViewModel = DroneDetailsCellularViewModel()

    // MARK: - Init
    override init() {
        super.init()

        cellularViewModel.state.valueChanged = { [weak self] _ in
            self?.updateCellularState()
        }
        updateCellularState()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenGps(drone)
        listenGimbal(drone)
        listenStereoVisionSensor(drone)
        listenMagnetometer(drone)
        listenFrontStereoGimbal(drone)
        listenFlyingIndicators(drone: drone)
    }

    // MARK: - Internal Funcs
    /// Removes current drone uid in the dismissed pairing list.
    /// The pairing process for the current drone could be displayed again in the HUD.
    func resetPairingDroneListIfNeeded() {
        guard let uid = self.drone?.uid,
              Defaults.dronesListPairingProcessHidden.contains(uid),
              !Defaults.cellularPairedDronesList.contains(uid) else {
            return
        }

        Defaults.dronesListPairingProcessHidden.removeAll(where: { $0 == uid })
    }
}

// MARK: - Private Funcs
private extension DroneDetailsButtonsViewModel {
    /// Starts watcher for gps.
    func listenGps(_ drone: Drone) {
        gpsRef = drone.getInstrument(Instruments.gps) { [weak self] gps in
            let copy = self?.state.value.copy()
            copy?.lastKnownPosition = gps?.lastKnownLocation
            self?.state.set(copy)
        }
    }

    /// Starts watcher for gimbal.
    func listenGimbal(_ drone: Drone) {
        gimbalRef = drone.getPeripheral(Peripherals.gimbal) { [weak self] gimbal in
            let copy = self?.state.value.copy()
            copy?.gimbalState = gimbal?.state
            self?.state.set(copy)
        }
    }

    /// Starts watcher for stereo vision sensor.
    func listenStereoVisionSensor(_ drone: Drone) {
        stereoVisionSensorRef = drone.getPeripheral(Peripherals.stereoVisionSensor) { [weak self] stereoVisionSensor in
            self?.updateStereoVisionSensorCalibrationState(stereoVisionSensors: stereoVisionSensor)
        }
    }

    /// Starts watcher for flying indicators.
    func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] flyingIndicators in
            guard let flyingState = flyingIndicators?.state else { return }

            let copy = self?.state.value.copy()
            copy?.flyingState = flyingState
            self?.state.set(copy)
        }
    }

    /// Starts watcher for magnetometer.
    func listenMagnetometer(_ drone: Drone) {
        magnetometerRef = drone.getPeripheral(Peripherals.magnetometerWith3StepCalibration) { [weak self] magnetometer in
            self?.updateMagnetometerCalibrationState(magnetometer: magnetometer)
        }
    }

    /// Starts watcher for front stereo gimbal.
    func listenFrontStereoGimbal(_ drone: Drone) {
        frontStereoGimbalRef = drone.getPeripheral(Peripherals.frontStereoGimbal) { [weak self] frontStereoGimbal in
            self?.updateFrontStereoGimbal(frontStereoGimbal: frontStereoGimbal)
        }
    }

    /// Updates front stereo gimbal calibration state.
    func updateFrontStereoGimbal(frontStereoGimbal: FrontStereoGimbal?) {
        let copy = self.state.value.copy()

        guard let frontStereoGimbal = frontStereoGimbal else {
            copy.isGimbalFrontStereoCalibrationNeeded = false
            self.state.set(copy)
            return
        }

        switch (frontStereoGimbal.calibrated, frontStereoGimbal.currentErrors.isEmpty) {
        case (false, true),
             (true, false):
            copy.isGimbalFrontStereoCalibrationNeeded = true
        default:
            copy.isGimbalFrontStereoCalibrationNeeded = false
        }

        self.state.set(copy)
    }

    /// Updates stereo vision sensor calibration state.
    func updateStereoVisionSensorCalibrationState(stereoVisionSensors: StereoVisionSensor?) {
        let copy = self.state.value.copy()

        guard let stereoVisionSensor = stereoVisionSensors else {
            copy.isStereoVisionSensorCalibrationNeeded = false
            self.state.set(copy)
            return
        }

        copy.isStereoVisionSensorCalibrationNeeded = !stereoVisionSensor.isCalibrated
        self.state.set(copy)
    }

    /// Updates magnetometer calibration state.
    func updateMagnetometerCalibrationState(magnetometer: MagnetometerWith3StepCalibration?) {
        let copy = self.state.value.copy()

        guard let magnetometer = magnetometer else {
            copy.isMagnetometerCalibrationNeeded = false
            self.state.set(copy)
            return
        }

        switch magnetometer.calibrationState {
        case .calibrated:
            copy.isMagnetometerCalibrationNeeded = false
        case .required,
             .recommended:
            copy.isMagnetometerCalibrationNeeded = true
        }

        state.set(copy)
    }

    /// Updates cellular state.
    func updateCellularState() {
        let copy = state.value.copy()
        copy.cellularStatus = cellularViewModel.state.value.cellularStatus
        state.set(copy)
    }
}
