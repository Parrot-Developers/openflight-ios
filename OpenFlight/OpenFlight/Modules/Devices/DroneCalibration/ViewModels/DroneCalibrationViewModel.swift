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

/// State for CalibrationViewModel.
final class DroneCalibrationState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    /// Drone's connection state.
    fileprivate(set) var droneState: DeviceState.ConnectionState?
    /// Drone's gimbal state.
    fileprivate(set) var gimbalState: CalibratableGimbalState?
    /// Drone's front stereo gimbal state.
    fileprivate(set) var frontStereoGimbalState: FrontStereoGimbalCalibrationState?
    /// Drone's stereo vision sensors state.
    fileprivate(set) var stereoVisionSensorsState: StereoVisionSensorsCalibrationState?
    /// Drone's magnetometer state.
    fileprivate(set) var magnetometerState: DroneMagnetometerCalibrationState?
    /// Drone's flying state.
    fileprivate(set) var flyingState: FlyingIndicatorsState?
    /// Gimbal calibration state description.
    fileprivate(set) var gimbalCalibrationDescription: String?
    /// Gimbal calibration description color.
    fileprivate(set) var gimbalCalibrationTextColor: ColorName?
    /// Gimbal calibration description background.
    fileprivate(set) var gimbalCalibrationBackgroundColor: ColorName?

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - droneState: state of the drone.
    ///    - calibratableGimbalState: gimbal calibration state.
    ///    - frontStereoGimbalState: state of the gimbal front stereo.
    ///    - stereoVisionSensorsState: state of the stereo vision sensor.
    ///    - magnetometerState: state of magnetometer.
    ///    - flyingState: flying state of the drone.
    ///    - gimbalCalibrationDescription: gimbal calibration text.
    ///    - gimbalCalibrationTextColor: gimbal calibraton text color.
    ///    - gimbalCalibrationBackgroundColor: gimbal calibration background cell color.
    init(droneState: DeviceState.ConnectionState?,
         calibratableGimbalState: CalibratableGimbalState?,
         frontStereoGimbalState: FrontStereoGimbalCalibrationState?,
         stereoVisionSensorsState: StereoVisionSensorsCalibrationState?,
         magnetometerState: DroneMagnetometerCalibrationState?,
         flyingState: FlyingIndicatorsState?,
         gimbalCalibrationDescription: String?,
         gimbalCalibrationTextColor: ColorName?,
         gimbalCalibrationBackgroundColor: ColorName?) {
        self.droneState = droneState
        self.gimbalState = calibratableGimbalState
        self.frontStereoGimbalState = frontStereoGimbalState
        self.stereoVisionSensorsState = stereoVisionSensorsState
        self.magnetometerState = magnetometerState
        self.flyingState = flyingState
        self.gimbalCalibrationDescription = gimbalCalibrationDescription
        self.gimbalCalibrationTextColor = gimbalCalibrationTextColor
        self.gimbalCalibrationBackgroundColor = gimbalCalibrationBackgroundColor
    }

    // MARK: - Internal Funcs
    func isEqual(to other: DroneCalibrationState) -> Bool {
        return self.droneState == other.droneState
            && self.gimbalState == other.gimbalState
            && self.frontStereoGimbalState == other.frontStereoGimbalState
            && self.stereoVisionSensorsState == other.stereoVisionSensorsState
            && self.magnetometerState == other.magnetometerState
            && self.flyingState == other.flyingState
            && self.gimbalCalibrationDescription == other.gimbalCalibrationDescription
    }

    /// Returns a copy of the object.
    func copy() -> DroneCalibrationState {
        let copy = DroneCalibrationState(droneState: self.droneState,
                                         calibratableGimbalState: self.gimbalState,
                                         frontStereoGimbalState: self.frontStereoGimbalState,
                                         stereoVisionSensorsState: self.stereoVisionSensorsState ,
                                         magnetometerState: self.magnetometerState,
                                         flyingState: self.flyingState,
                                         gimbalCalibrationDescription: self.gimbalCalibrationDescription,
                                         gimbalCalibrationTextColor: self.gimbalCalibrationTextColor,
                                         gimbalCalibrationBackgroundColor: self.gimbalCalibrationBackgroundColor)
        return copy
    }
}

/// ViewModel for calibration.
final class DroneCalibrationViewModel: DroneWatcherViewModel<DroneCalibrationState> {
    // MARK: - Public Properties
    // TODO: To refact by deleting those observable (gimbalCalibrationState and frontStereoGimbalCalibrationState)
    /// gimbalCalibrationState object to represent model.
    /// `gimbalCalibrationState` object is `Observable` and so can be observed.
    public var gimbalCalibrationState =  Observable<CalibratableGimbalState>(CalibratableGimbalState.needed)
    /// frontStereoGimbalCalibrationState object to represent model.
    /// `frontStereoGimbalCalibrationState` object is `Observable` and so can be observed.
    public var frontStereoGimbalCalibrationState =  Observable<FrontStereoGimbalCalibrationState>(FrontStereoGimbalCalibrationState.needed)

    // MARK: - Private Properties
    private var stateRef: Ref<DeviceState>?
    private var gimbalRef: Ref<Gimbal>?
    private var magnetometerRef: Ref<MagnetometerWith3StepCalibration>?
    private var frontStereoGimbalRef: Ref<FrontStereoGimbal>?
    private var stereoVisionSensorRef: Ref<StereoVisionSensor>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?

    // MARK: - Deinit
    deinit {
        self.stateRef = nil
        self.gimbalRef = nil
        self.frontStereoGimbalRef = nil
        self.stereoVisionSensorRef = nil
        self.magnetometerRef = nil
        self.flyingIndicatorsRef = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        self.listenFlyingIndicators(drone: drone)
        self.listenState(drone)
        self.listenGimbal(drone)
        self.listenMagnetometer(drone)
        self.listenStereoVisionSensor(drone)
        self.listenFrontStereoGimbal(drone)
    }
}

// MARK: - Private Funcs
extension DroneCalibrationViewModel {

    /// Listens the state of the drone.
    func listenState(_ drone: Drone) {
        stateRef = drone.getState { [weak self] droneState in
            let copy = self?.state.value.copy()
            copy?.droneState = droneState?.connectionState
            self?.state.set(copy)
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

    /// Starts Gimbal calibration.
    func startGimbalCalibration() {
        self.drone?.getPeripheral(Peripherals.gimbal)?.startCalibration()
    }

    /// Stops Gimbal calibration.
    func cancelGimbalCalibration() {
        self.drone?.getPeripheral(Peripherals.gimbal)?.cancelCalibration()
    }

    /// Starts Front Stereo Gimbal calibration.
    func startFrontStereoGimbalCalibration() {
        self.drone?.getPeripheral(Peripherals.frontStereoGimbal)?.startCalibration()
    }

    /// Cancels Front Stereo Gimbal calibration.
    func cancelFrontStereoGimbalCalibration() {
        self.drone?.getPeripheral(Peripherals.frontStereoGimbal)?.cancelCalibration()
    }

    /// Listens the gimbal of the drone.
    func listenGimbal(_ drone: Drone) {
        gimbalRef = drone.getPeripheral(Peripherals.gimbal) { [weak self] gimbal in
            self?.updateGimbalState(gimbal: gimbal)
        }
    }

    /// Starts watcher for gimbal front stereo sensors.
    func listenFrontStereoGimbal(_ drone: Drone) {
        frontStereoGimbalRef = drone.getPeripheral(Peripherals.frontStereoGimbal) { [weak self] frontStereoGimbal in
            self?.updateFrontStereoGimbal(frontStereoGimbal: frontStereoGimbal)
        }
    }

    /// Starts watcher for stereo vision sensor.
    func listenStereoVisionSensor(_ drone: Drone) {
        stereoVisionSensorRef = drone.getPeripheral(Peripherals.stereoVisionSensor) { [weak self] stereoVisionSensor in
            self?.updateStereoVisionSensorCalibrationState(stereoVisionSensor: stereoVisionSensor)
        }
    }

    /// Starts watcher for magnetometer.
    func listenMagnetometer(_ drone: Drone) {
        magnetometerRef = drone.getPeripheral(Peripherals.magnetometerWith3StepCalibration) { [weak self] magnetometer in
            self?.updateMagnetometerCalibrationState(magnetometer: magnetometer)
        }
    }

    /// Updates gimbal states and attributes.
    func updateGimbalState(gimbal: Gimbal?) {
        let copy = self.state.value.copy()

        guard let gimbal = gimbal else {
            copy.gimbalState = .calibrated
            copy.gimbalCalibrationDescription = ""
            copy.gimbalCalibrationTextColor = .white50
            copy.gimbalCalibrationBackgroundColor = .white10
            return
        }

        copy.gimbalState = gimbal.state
        copy.gimbalCalibrationDescription = gimbal.calibrationStateDescription
        copy.gimbalCalibrationTextColor = gimbal.subtextColor
        copy.gimbalCalibrationBackgroundColor = gimbal.backgroundColor
        self.state.set(copy)

        switch gimbal.calibrationProcessState {
        case .success:
            self.gimbalCalibrationState.set(.calibrated)
        case .failure:
            self.gimbalCalibrationState.set(.needed)
        default :
            break
        }
    }

    /// Updates stereo vision sensor calibration state.
    func updateStereoVisionSensorCalibrationState(stereoVisionSensor: StereoVisionSensor?) {
        let copy = state.value.copy()

        guard let stereoVisionSensor = stereoVisionSensor else {
            copy.stereoVisionSensorsState = .calibrated
            state.set(copy)
            return
        }

        copy.stereoVisionSensorsState = stereoVisionSensor.isCalibrated ? .calibrated : .needed
        state.set(copy)
    }

    /// Updates magnetometer calibration state.
    func updateMagnetometerCalibrationState(magnetometer: MagnetometerWith3StepCalibration?) {
        let copy = self.state.value.copy()

        guard let magnetometer = magnetometer else {
            copy.magnetometerState = .calibrated
            state.set(copy)
            return
        }

        switch magnetometer.calibrationState {
        case .calibrated:
            copy.magnetometerState = .calibrated
        case .required,
             .recommended:
            copy.magnetometerState = .needed
        }

        state.set(copy)
    }

    /// Updates the front stereo gimbal sensor of the drone.
    func updateFrontStereoGimbal(frontStereoGimbal: FrontStereoGimbal?) {
        let copy = state.value.copy()

        guard let frontStereoGimbal = frontStereoGimbal else {
            copy.frontStereoGimbalState = .calibrated
            self.frontStereoGimbalCalibrationState.set(.calibrated)
            return
        }

        switch (frontStereoGimbal.calibrated, frontStereoGimbal.currentErrors.isEmpty) {
        case (false, true),
             (_, false):
            copy.frontStereoGimbalState = .needed
        default:
            copy.frontStereoGimbalState = .calibrated
        }

        state.set(copy)

        switch frontStereoGimbal.calibrationProcessState {
        case .success:
            self.frontStereoGimbalCalibrationState.set(.calibrated)
        case .failure:
            self.frontStereoGimbalCalibrationState.set(.needed)
        case .calibrating:
            self.frontStereoGimbalCalibrationState.set(.calibrating)
        default :
            break
        }
    }
}
