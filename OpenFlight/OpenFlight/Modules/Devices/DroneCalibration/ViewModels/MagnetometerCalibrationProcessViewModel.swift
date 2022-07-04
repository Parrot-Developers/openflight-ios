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
import Combine

/// ViewModel for calibration.
final class MagnetometerCalibrationProcessViewModel {

    // MARK: - Private Properties
    private var stateRef: Ref<DeviceState>?
    private var magnetometerRef: Ref<MagnetometerWith3StepCalibration>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var currentDroneHolder: CurrentDroneHolder

    @Published private(set) var droneConnectionState: DeviceState.ConnectionState?
    @Published private(set) var flyingState: FlyingIndicatorsState?
    @Published private(set) var calibrationProcessState: Magnetometer3StepCalibrationProcessState?

    init(currentDroneHolder: CurrentDroneHolder) {
        self.currentDroneHolder = currentDroneHolder
        listenDrone(drone: currentDroneHolder.drone)
    }

    // MARK: - Deinit
    deinit {
        stateRef = nil
        magnetometerRef = nil
        flyingIndicatorsRef = nil
    }

    // MARK: - Override Funcs
    func listenDrone(drone: Drone) {
        listenState(drone)
        listenMagnetometer(for: drone)
        listenFlyingIndicators(for: drone)
    }
}

// MARK: - Internal Funcs
extension MagnetometerCalibrationProcessViewModel {

    /// Start the drone magnetometer calibration.
    func startCalibration() {
        currentDroneHolder.drone.getPeripheral(Peripherals.magnetometerWith3StepCalibration)?.startCalibrationProcess()
    }

    /// Stop the drone magnetometer calibration.
    func cancelCalibration() {
        currentDroneHolder.drone.getPeripheral(Peripherals.magnetometerWith3StepCalibration)?.cancelCalibrationProcess()
    }
}

// MARK: - Private Funcs
private extension MagnetometerCalibrationProcessViewModel {

    /// Listen the state of the drone.
    func listenState(_ drone: Drone) {
        stateRef = drone.getState { [weak self] droneState in
            guard let self = self else { return }
            self.droneConnectionState = droneState?.connectionState
        }
    }

    /// Listen the drone magnetometer.
    func listenMagnetometer(for drone: Drone) {
        magnetometerRef = drone.getPeripheral(Peripherals.magnetometerWith3StepCalibration) { [weak self] magnetometer in
            guard let self = self else { return }
            self.calibrationProcessState = magnetometer?.calibrationProcessState
        }
    }

    /// Listen the drone flying indicators.
    func listenFlyingIndicators(for drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] flyingIndicators in
            guard let self = self else { return }
            self.flyingState = flyingIndicators?.state
        }
    }
}
