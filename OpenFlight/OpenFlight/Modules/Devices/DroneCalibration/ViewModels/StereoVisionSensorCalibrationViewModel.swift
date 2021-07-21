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

/// State for `StereoVisionSensorCalibrationViewModel`.
final class StereoVisionSensorCalibrationState: ViewModelState, EquatableState, Copying {

    // MARK: - Internal Properties
    fileprivate(set) var missionState: MissionState?
    fileprivate(set) var calibrationProcessState: StereoVisionCalibrationProcessState?
    fileprivate(set) var calibrationStepsCount: Int?

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - calibrationProcessState: calibration process state of the drone.
    ///    - calibrationStepsCount: Number of steps to calibrate stereo vision sensor.
    init(calibrationProcessState: StereoVisionCalibrationProcessState?, calibrationStepsCount: Int?) {
        self.calibrationProcessState = calibrationProcessState
    }

    // MARK: - Internal Funcs
    func isEqual(to other: StereoVisionSensorCalibrationState) -> Bool {
        return false
    }

    /// Returns a copy of the object.
    func copy() -> StereoVisionSensorCalibrationState {
        let copy = StereoVisionSensorCalibrationState(calibrationProcessState: self.calibrationProcessState,
                                                      calibrationStepsCount: self.calibrationStepsCount)
        return copy
    }
}

/// ViewModel for Stereo vision Sensor calibration.
final class StereoVisionSensorCalibrationViewModel: DroneWatcherViewModel<StereoVisionSensorCalibrationState> {

    // MARK: - Private Properties
    private let manager = ProtobufMissionsManager.shared
    private var listener: ProtobufMissionListener?
    private let signature = OFMissionSignatures.ophtalmo
    private var stereoVisionSensorRef: Ref<StereoVisionSensor>?

    // MARK: - Deinit
    deinit {
        manager.unregister(listener)
        self.stereoVisionSensorRef = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        self.listenMission()
        self.listenStereoVisionSensor(for: drone)
    }
}

// MARK: - Internal Funcs
extension StereoVisionSensorCalibrationViewModel {

    /// Start the drone stereoVisionSensor calibration.
    func startCalibration() {
        manager.activate(mission: signature)
    }

    /// Stop the drone stereoVisionSensor calibration.
    func cancelCalibration() {
        manager.deactivate(mission: signature)
    }
}

// MARK: - Private Funcs
private extension StereoVisionSensorCalibrationViewModel {

    /// Listens to the ophtalmo mission.
    func listenMission() {
        listener = manager.register(
            for: signature,
            missionCallback: { [weak self] (state, _, _) in
                let copy = self?.state.value.copy()
                copy?.missionState = state
                self?.state.set(copy)
            })
    }

    /// Listen the drone stereoVisionSensor.
    func listenStereoVisionSensor(for drone: Drone) {
        stereoVisionSensorRef = drone.getPeripheral(Peripherals.stereoVisionSensor) { [weak self] stereoVisionSensor in
            guard let calibrationProcessState = stereoVisionSensor?.calibrationProcessState,
                let calibrationStepsCount = stereoVisionSensor?.calibrationStepCount else {
                    return
            }
            let copy = self?.state.value.copy()
            copy?.calibrationProcessState = calibrationProcessState
            copy?.calibrationStepsCount = calibrationStepsCount
            self?.state.set(copy)
        }
    }
}
