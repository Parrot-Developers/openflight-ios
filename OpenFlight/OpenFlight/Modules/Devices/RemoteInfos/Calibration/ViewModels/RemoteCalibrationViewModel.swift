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

import UIKit
import GroundSdk

// MARK: - Internal Enums
// Describe the current state of the calibration.
enum CalibrationState {
    case started
    case cancelled
    case finished

    /// String describing calibration state.
    var description: String {
        switch self {
        case .started:
            return "Started"
        case .cancelled:
            return "Cancelled"
        case .finished:
            return "Finished"
        }
    }
}

/// State for `RemoteCalibrationViewModel`.

final class RemoteCalibrationState: DevicesConnectionState {
    // MARK: - Internal Properties
    fileprivate(set) var yawValue: Float?
    fileprivate(set) var rollValue: Float?
    fileprivate(set) var pitchValue: Float?
    fileprivate(set) var calibrationState: CalibrationState?

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - droneConnectionState: drone connection state
    ///    - remoteControlConnectionState: remote control connection state
    ///    - yawValue: calibration on yaw axe
    ///    - rollValue: calibration on roll axe
    ///    - pitchValue: calibration on pitch axe
    ///    - calibrationState: current state of the calibration process
    init(droneConnectionState: DeviceConnectionState?,
         remoteControlConnectionState: DeviceConnectionState?,
         yawValue: Float?,
         rollValue: Float?,
         pitchValue: Float?,
         calibrationState: CalibrationState?) {
        super.init(droneConnectionState: droneConnectionState, remoteControlConnectionState: remoteControlConnectionState)
        self.yawValue = yawValue
        self.rollValue = rollValue
        self.pitchValue = pitchValue
        self.calibrationState = calibrationState
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DevicesConnectionState) -> Bool {
        guard let other = other as? RemoteCalibrationState else {
            return false
        }
        return super.isEqual(to: other)
            && self.yawValue == other.yawValue
            && self.rollValue == other.rollValue
            && self.pitchValue == other.pitchValue
            && self.calibrationState == calibrationState
    }

    override func copy() -> RemoteCalibrationState {
        let copy = RemoteCalibrationState(droneConnectionState: self.droneConnectionState,
                                          remoteControlConnectionState: self.remoteControlConnectionState,
                                          yawValue: self.yawValue,
                                          rollValue: self.rollValue,
                                          pitchValue: self.pitchValue,
                                          calibrationState: self.calibrationState)
        return copy
    }
}

/// ViewModel for remote Calibration.

final class RemoteCalibrationViewModel: DevicesStateViewModel<RemoteCalibrationState> {
    // MARK: - Private Properties
    private var magnetometerRef: Ref<MagnetometerWith1StepCalibration>?

    // MARK: - Override Funcs
    override func listenRemoteControl(remoteControl: RemoteControl) {
        listenMagnetometer(remoteControl)
    }

    // MARK: - Internal Funcs
    /// Starts remote calibration.
    func startCalibration() {
        if let magnetometer = remoteControl?.getPeripheral(Peripherals.magnetometerWith1StepCalibration) {
            magnetometer.startCalibrationProcess()
        }
    }

    /// Cancels remote calibration.
    func cancelCalibration() {
        if let magnetometer =
            remoteControl?.getPeripheral(Peripherals.magnetometerWith1StepCalibration) {
            magnetometer.cancelCalibrationProcess()
        }
    }
}

// MARK: - Private Funcs
private extension RemoteCalibrationViewModel {
    /// Starts watcher for magnetometer.
    func listenMagnetometer(_ remoteControl: RemoteControl) {
        magnetometerRef = remoteControl.getPeripheral(Peripherals.magnetometerWith1StepCalibration) { [weak self] magnetometer in
            let copy = self?.state.value.copy()
            if let processState = magnetometer?.calibrationProcessState {
                copy?.calibrationState = magnetometer?.calibrationState == .calibrated ? .finished : .started
                copy?.yawValue = Float(processState.yawProgress)/100.0
                copy?.rollValue = Float(processState.rollProgress)/100.0
                copy?.pitchValue = Float(processState.pitchProgress)/100.0
            } else {
                copy?.calibrationState = .cancelled
            }
            self?.state.set(copy)
        }
    }
}
