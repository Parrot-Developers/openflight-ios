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

import GroundSdk

/// State for `MagnetometerCalibrationProcessViewModel`.
final class MagnetometerCalibrationProcessState: ViewModelState, EquatableState, Copying {

    // MARK: - Internal Properties
    fileprivate(set) var droneState: DeviceState.ConnectionState?
    fileprivate(set) var flyingState: FlyingIndicatorsState?
    fileprivate(set) var calibrationProcessState: Magnetometer3StepCalibrationProcessState?
    fileprivate(set) var axis: Magnetometer3StepCalibrationProcessState.Axis = .none

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - droneState: state of the drone.
    ///    - flyingState: flying state of the drone.
    ///    - calibrationProcessState: calibration process state of the drone.
    ///    - axis: current axis calibration of the drone.
    init(droneState: DeviceState.ConnectionState?,
         flyingState: FlyingIndicatorsState?,
         calibrationProcessState: Magnetometer3StepCalibrationProcessState?,
         axis: Magnetometer3StepCalibrationProcessState.Axis) {
        self.droneState = droneState
        self.flyingState = flyingState
        self.calibrationProcessState = calibrationProcessState
        self.axis = axis
    }

    // MARK: - Internal Funcs
    func isEqual(to other: MagnetometerCalibrationProcessState) -> Bool {
        return self.droneState == other.droneState
            && self.flyingState == other.flyingState
            && self.calibrationProcessState == other.calibrationProcessState
            && self.axis == other.axis
    }

    /// Returns a copy of the object.
    func copy() -> MagnetometerCalibrationProcessState {
        let copy = MagnetometerCalibrationProcessState(droneState: self.droneState,
                                                       flyingState: self.flyingState,
                                                       calibrationProcessState: self.calibrationProcessState,
                                                       axis: self.axis)
        return copy
    }
}

/// ViewModel for calibration.
final class MagnetometerCalibrationProcessViewModel: DroneWatcherViewModel<MagnetometerCalibrationProcessState> {

    // MARK: - Private Properties
    private var stateRef: Ref<DeviceState>?
    private var magnetometerRef: Ref<MagnetometerWith3StepCalibration>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?

    // MARK: - Deinit
    deinit {
        self.stateRef = nil
        self.magnetometerRef = nil
        self.flyingIndicatorsRef = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        self.listenState(drone)
        self.listenMagnetometer(for: drone)
        self.listenFlyingIndicators(for: drone)
    }
}

// MARK: - Internal Funcs
extension MagnetometerCalibrationProcessViewModel {

    /// Start the drone magnetometer calibration.
    func startCalibration() {
        self.drone?.getPeripheral(Peripherals.magnetometerWith3StepCalibration)?.startCalibrationProcess()
    }

    /// Stop the drone magnetometer calibration.
    func cancelCalibration() {
        self.drone?.getPeripheral(Peripherals.magnetometerWith3StepCalibration)?.cancelCalibrationProcess()
    }
}

// MARK: - Private Funcs
private extension MagnetometerCalibrationProcessViewModel {

    /// Listen the state of the drone.
    func listenState(_ drone: Drone) {
        stateRef = drone.getState { [weak self] droneState in
            let copy = self?.state.value.copy()
            copy?.droneState = droneState?.connectionState
            self?.state.set(copy)
        }
    }

    /// Listen the drone magnetometer.
    func listenMagnetometer(for drone: Drone) {
        magnetometerRef = drone.getPeripheral(Peripherals.magnetometerWith3StepCalibration) { [weak self] magnetometer in
            guard let calibrationProcessState = magnetometer?.calibrationProcessState else { return }

            let copy = self?.state.value.copy()
            copy?.calibrationProcessState = calibrationProcessState
            copy?.axis = calibrationProcessState.currentAxis
            self?.state.set(copy)
        }
    }

    /// Listen the drone flying indicators.
    func listenFlyingIndicators(for drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] flyingIndicators in
            guard let flyingState = flyingIndicators?.state else { return }

            let copy = self?.state.value.copy()
            copy?.flyingState = flyingState
            self?.state.set(copy)
        }
    }
}
