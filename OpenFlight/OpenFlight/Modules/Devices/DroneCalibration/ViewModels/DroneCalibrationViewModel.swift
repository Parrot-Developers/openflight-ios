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

/// Enum for gimbal calibration state.
enum GimbalCalibrationState {
    case gimbalOk
    case gimbalNotCalibrated
    case gimbalError

    /// String describing gimbal calibration state.
    var description: String {
        switch self {
        case .gimbalOk:
            return "Gimbal Ok"
        case .gimbalNotCalibrated:
            return "Gimbal Not Calibrated"
        case .gimbalError:
            return "Gimbal Error"
        }
    }
}

/// Enum for Front Stereo Gimbal calibration state.
enum FrontStereoGimbalCalibrationState {
    case calibrated
    case notCalibrated
    case error
    case calibrating
}

/// State for CalibrationViewModel.
final class DroneCalibrationState: ViewModelState, EquatableState, Copying {

    // MARK: - Internal Properties
    fileprivate(set) var droneState: DeviceState.ConnectionState?
    fileprivate(set) var gimbalState: GimbalCalibrationState?
    fileprivate(set) var frontStereoGimbalState: FrontStereoGimbalCalibrationState?
    fileprivate(set) var flyingState: FlyingIndicatorsState?
    /// Whether a stereo vision sensor calibration is needed.
    fileprivate(set) var stereoVisionSensorCalibrationNeeded: Bool = false

    // MARK: Helpers
    /// Message to display on calibration button.
    var calibrationText: String {
        // TODO: add message for all calibration cases.
        if stereoVisionSensorCalibrationNeeded {
            return L10n.loveCalibrationRequired
        } else {
            return ""
        }
    }

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - droneState: state of the drone.
    ///    - gimbalState: state of the gimbal.
    ///    - frontStereoGimbalState: state of the stereo vision.
    ///    - stereoVisionSensorCalibrationNeeded: Bool that indicates if stereo vision sensor calibration is needed.
    ///    - flyingState: flying state of the drone.
    init(droneState: DeviceState.ConnectionState?,
         gimbalState: GimbalCalibrationState?,
         frontStereoGimbalState: FrontStereoGimbalCalibrationState?,
         stereoVisionSensorCalibrationNeeded: Bool,
         flyingState: FlyingIndicatorsState?) {
        self.droneState = droneState
        self.gimbalState = gimbalState
        self.frontStereoGimbalState = frontStereoGimbalState
        self.stereoVisionSensorCalibrationNeeded = stereoVisionSensorCalibrationNeeded
        self.flyingState = flyingState
    }

    // MARK: - Internal Funcs
    func isEqual(to other: DroneCalibrationState) -> Bool {
        return self.droneState == other.droneState
            && self.gimbalState == other.gimbalState
            && self.frontStereoGimbalState == other.frontStereoGimbalState
            && self.stereoVisionSensorCalibrationNeeded == other.stereoVisionSensorCalibrationNeeded
            && self.flyingState == other.flyingState
    }

    /// Returns a copy of the object.
    func copy() -> DroneCalibrationState {
        let copy = DroneCalibrationState(droneState: self.droneState,
                                         gimbalState: self.gimbalState,
                                         frontStereoGimbalState: self.frontStereoGimbalState,
                                         stereoVisionSensorCalibrationNeeded: self.stereoVisionSensorCalibrationNeeded,
                                         flyingState: self.flyingState)
        return copy
    }
}

/// ViewModel for calibration.
final class DroneCalibrationViewModel: DroneWatcherViewModel<DroneCalibrationState> {

    // MARK: - Public Properties
    /// gimbalCalibrationState object to represent model.
    /// `gimbalCalibrationState` object is `Observable` and so can be observed.
    public var gimbalCalibrationState =  Observable<GimbalCalibrationState>(GimbalCalibrationState.gimbalNotCalibrated)
    /// frontStereoGimbalCalibrationState object to represent model.
    /// `frontStereoGimbalCalibrationState` object is `Observable` and so can be observed.
    public var frontStereoGimbalCalibrationState =  Observable<FrontStereoGimbalCalibrationState>(FrontStereoGimbalCalibrationState.notCalibrated)

    // MARK: - Private Properties
    private var stateRef: Ref<DeviceState>?
    private var gimbalRef: Ref<Gimbal>?
    private var frontStereoGimbalRef: Ref<FrontStereoGimbal>?
    private var stereoVisionSensorRef: Ref<StereoVisionSensor>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?

    // MARK: - Deinit
    deinit {
        self.stateRef = nil
        self.gimbalRef = nil
        self.frontStereoGimbalRef = nil
        self.stereoVisionSensorRef = nil
        self.flyingIndicatorsRef = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        self.listenFlyingIndicators(drone: drone)
        self.listenState(drone)
        self.listenGimbal(drone)
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
            let copy = self?.state.value.copy()
            switch (gimbal?.calibrated, gimbal?.currentErrors.isEmpty) {
            case (false, true):
                copy?.gimbalState = .gimbalNotCalibrated
            case (_, false):
                copy?.gimbalState = .gimbalError
            default:
                copy?.gimbalState = .gimbalOk
            }
            self?.state.set(copy)
            switch gimbal?.calibrationProcessState {
            case .success:
                self?.gimbalCalibrationState.set(.gimbalOk)
            case .failure:
                self?.gimbalCalibrationState.set(.gimbalNotCalibrated)
            default :
                break
            }
        }
    }

    /// Starts watcher for stereo vision sensor.
    func listenStereoVisionSensor(_ drone: Drone) {
        stereoVisionSensorRef = drone.getPeripheral(Peripherals.stereoVisionSensor) { [weak self] _ in
            self?.updateStereoVisionSensorCalibrationState()
        }
    }

    /// Updates stereo vision sensor calibration state.
    func updateStereoVisionSensorCalibrationState() {
        guard let drone = drone,
              let stereoVisionSensor = drone.getPeripheral(Peripherals.stereoVisionSensor)
        else {
            return
        }

        let copy = self.state.value.copy()
        copy.stereoVisionSensorCalibrationNeeded = !stereoVisionSensor.isCalibrated
        self.state.set(copy)
    }

    /// Listens the front stereo gimbal sensor of the drone.
    func listenFrontStereoGimbal(_ drone: Drone) {
        frontStereoGimbalRef = drone.getPeripheral(Peripherals.frontStereoGimbal) { [weak self] frontStereoGimbal in
            let copy = self?.state.value.copy()
            switch (frontStereoGimbal?.calibrated, frontStereoGimbal?.currentErrors.isEmpty) {
            case (false, true):
                copy?.frontStereoGimbalState = .notCalibrated
            case (_, false):
                copy?.frontStereoGimbalState = .error
            default:
                copy?.frontStereoGimbalState = .calibrated
            }
            self?.state.set(copy)
            switch frontStereoGimbal?.calibrationProcessState {
            case .success:
                self?.frontStereoGimbalCalibrationState.set(.calibrated)
            case .failure:
                self?.frontStereoGimbalCalibrationState.set(.notCalibrated)
            case .calibrating:
                self?.frontStereoGimbalCalibrationState.set(.calibrating)
            default :
                break
            }
        }
    }
}
