//    Copyright (C) 2020 Parrot Drones SAS
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
import GroundSdk
import Combine

final class DroneCalibrationViewModel {

    // MARK: - Published Properties

    /// Drone's gimbal state.
    @Published private(set) var gimbalState: CalibratableGimbalState?
    /// Drone's front stereo gimbal state.
    @Published private(set) var frontStereoGimbalState: CalibratableGimbalState?
    /// Drone's stereo vision sensors state.
    @Published private(set) var stereoVisionSensorsState: StereoVisionSensorCalibrationState?
    /// Drone's magnetometer state.
    @Published private(set) var magnetometerState: DroneMagnetometerCalibrationState?
    /// Drone's flying state.
    @Published private(set) var flyingState: FlyingIndicatorsState?
    /// Gimbal calibration state description.
    @Published private(set) var gimbalCalibrationDescription: String?
    /// Gimbal calibration title color.
    @Published private(set) var gimbalCalibrationTitleColor: ColorName?
    /// Gimbal calibration subtitle color.
    @Published private(set) var gimbalCalibrationSubtitleColor: ColorName?
    /// Gimbal calibration description background.
    @Published private(set) var gimbalCalibrationBackgroundColor: ColorName?
    /// Tells if a gimbal calibration has been requested.
    @Published private(set) var isCalibrationRequested: Bool = true
    /// gimbalCalibrationState to represent model
    @Published private(set) var gimbalCalibrationProcessState: GimbalCalibrationProcessState = .none
    /// frontStereoGimbalCalibrationState object to represent model.
    @Published private(set) var frontStereoGimbalCalibrationProcessState: GimbalCalibrationProcessState = .none
    /// Firmware update state
    @Published var updateState: UpdateState?

    private var cancellables = Set<AnyCancellable>()
    private var connectedDroneHolder = Services.hub.connectedDroneHolder
    private let updateService = Services.hub.update

    // MARK: - Private Properties

    private var gimbalRef: Ref<Gimbal>?
    private var magnetometerRef: Ref<MagnetometerWith3StepCalibration>?
    private var frontStereoGimbalRef: Ref<FrontStereoGimbal>?
    private var stereoVisionSensorRef: Ref<StereoVisionSensor>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?

    init() {
        connectedDroneHolder.dronePublisher
            .compactMap { $0 }
            .sink { [weak self] drone in
                guard let self = self else { return }
                self.listenFlyingIndicators(drone: drone)
                self.listenGimbal(drone)
                self.listenFrontStereoGimbal(drone)
                self.listenStereoVisionSensor(drone)
                self.listenMagnetometer(drone)
            }
            .store(in: &cancellables)
        updateService.droneUpdatePublisher
            .sink { [weak self] updateState in
                self?.updateState = updateState
            }
            .store(in: &cancellables)
    }

    /// Starts Gimbal calibration.
    func startGimbalCalibration() {
        gimbalCalibrationProcessState = GimbalCalibrationProcessState.none
        connectedDroneHolder.drone?.getPeripheral(Peripherals.gimbal)?.startCalibration()
    }

    /// Stops Gimbal calibration.
    func cancelGimbalCalibration() {
        connectedDroneHolder.drone?.getPeripheral(Peripherals.gimbal)?.cancelCalibration()
    }

    /// Starts Front Stereo Gimbal calibration.
    func startFrontStereoGimbalCalibration() {
        frontStereoGimbalCalibrationProcessState = GimbalCalibrationProcessState.none
        connectedDroneHolder.drone?.getPeripheral(Peripherals.frontStereoGimbal)?.startCalibration()
    }

    /// Cancels Front Stereo Gimbal calibration.
    func cancelFrontStereoGimbalCalibration() {
        connectedDroneHolder.drone?.getPeripheral(Peripherals.frontStereoGimbal)?.cancelCalibration()
    }
}

private extension DroneCalibrationViewModel {

    /// Listens the gimbal of the drone.
    func listenGimbal(_ drone: Drone) {
        gimbalRef = drone.getPeripheral(Peripherals.gimbal) { [weak self] gimbal in
            self?.updateGimbalState(gimbal: gimbal)
        }
    }

    /// Starts watcher for flying indicators.
    func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] flyingIndicators in
            self?.flyingState = flyingIndicators?.state
        }
    }

    /// Updates gimbal states and attributes.
    func updateGimbalState(gimbal: Gimbal?) {
        gimbalState = gimbal?.state ?? .calibrated
        gimbalCalibrationProcessState = gimbal?.calibrationProcessState ?? GimbalCalibrationProcessState.none
        gimbalCalibrationDescription = gimbal?.state.description ?? ""
        gimbalCalibrationTitleColor = gimbal?.titleColor ?? .defaultTextColor
        gimbalCalibrationSubtitleColor = gimbal?.subtitleColor ?? .defaultTextColor
        gimbalCalibrationBackgroundColor = gimbal?.backgroundColor ?? .white
        updateCalibrationRequested(gimbalCalibrationProcessState)
    }

    /// Starts watcher for gimbal front stereo sensors.
    func listenFrontStereoGimbal(_ drone: Drone) {
        frontStereoGimbalRef = drone.getPeripheral(Peripherals.frontStereoGimbal) { [weak self] frontStereoGimbal in
            self?.updateFrontStereoGimbal(frontStereoGimbal: frontStereoGimbal)
        }
    }

    /// Updates the front stereo gimbal sensor of the drone.
    func updateFrontStereoGimbal(frontStereoGimbal: FrontStereoGimbal?) {
        frontStereoGimbalState = frontStereoGimbal?.state ?? .calibrated
        frontStereoGimbalCalibrationProcessState = frontStereoGimbal?.calibrationProcessState ?? GimbalCalibrationProcessState.none
        updateCalibrationRequested(frontStereoGimbalCalibrationProcessState)
    }

    /// Starts watcher for stereo vision sensor.
    func listenStereoVisionSensor(_ drone: Drone) {
        stereoVisionSensorRef = drone.getPeripheral(Peripherals.stereoVisionSensor) { [weak self] stereoVisionSensor in
            self?.updateStereoVisionSensorCalibrationState(stereoVisionSensor: stereoVisionSensor)
        }
    }

    /// Updates the calibration requested flag.
    func updateCalibrationRequested(_ processState: GimbalCalibrationProcessState) {
        switch processState {
        case .success:
            isCalibrationRequested = false
        case .failure:
            isCalibrationRequested = true
        default :
            break
        }
    }

    /// Starts watcher for magnetometer.
    func listenMagnetometer(_ drone: Drone) {
        magnetometerRef = drone.getPeripheral(Peripherals.magnetometerWith3StepCalibration) { [weak self] magnetometer in
            self?.updateMagnetometerCalibrationState(magnetometer: magnetometer)
        }
    }

    /// Updates stereo vision sensor calibration state.
    func updateStereoVisionSensorCalibrationState(stereoVisionSensor: StereoVisionSensor?) {
        stereoVisionSensorsState = stereoVisionSensor?.state ?? .calibrated
    }

    /// Updates magnetometer calibration state.
    func updateMagnetometerCalibrationState(magnetometer: MagnetometerWith3StepCalibration?) {
       guard let magnetometer = magnetometer else {
            magnetometerState = .calibrated
            return
        }

        switch magnetometer.calibrationState {
        case .calibrated:
            magnetometerState = .calibrated
        case .required:
            magnetometerState = .needed
        case .recommended:
            magnetometerState = .recommended
        }
    }
}
