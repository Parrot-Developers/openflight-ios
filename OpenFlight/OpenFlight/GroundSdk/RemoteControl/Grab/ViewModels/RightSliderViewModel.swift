//
//  Copyright (C) 2021 Parrot Drones SAS.
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
import SwiftyUserDefaults

/// View Model which handles right slider grab events.
final class RightSliderViewModel: DroneStateViewModel<DeviceConnectionState> {
    // MARK: - Private Properties
    private var isEvTriggerSettingEnabled: Bool {
        return Defaults.evTriggerSetting == true
    }
}

// MARK: - Internal Funcs
extension RightSliderViewModel {
    /// Right slider is touched up.
    ///
    /// - Parameters:
    ///     - state: sky controller event state
    func actionUp(_ state: SkyCtrl4ButtonEventState) {
        if isEvTriggerSettingEnabled {
            increaseExposureValue(state)
        }
    }

    /// Right slider is touched down.
    ///
    /// - Parameters:
    ///     - state: sky controller event state
    func actionDown(_ state: SkyCtrl4ButtonEventState) {
        if isEvTriggerSettingEnabled {
            decreaseExposureValue(state)
        }
    }

    /// Called when right slider axis is updated.
    ///
    /// - Parameters:
    ///     - state: new zoom velocity value
    func axisUpdated(_ state: Int) {
        if !isEvTriggerSettingEnabled {
            updateZoomVelocity(newValue: -Double(state) / Values.oneHundred)
        }
    }
}

// MARK: - Private Exposure Funcs
private extension RightSliderViewModel {
    /// Increase Exposure value. It can be EV or shutter speed.
    ///
    /// - Parameters:
    ///     - state: sky controller event state
    func increaseExposureValue(_ state: SkyCtrl4ButtonEventState) {
        guard state == .pressed,
              let camera = drone?.currentCamera,
              let evSetting = camera.config[Camera2Params.exposureCompensation] else {
            return
        }

        if evSetting.currentSupportedValues.isEmpty {
            // Change shutter.
            guard let shutterSpeed = camera.config[Camera2Params.shutterSpeed],
                  let currentIndex = shutterSpeed.currentSupportedValues.sorted().firstIndex(of: shutterSpeed.value),
                  currentIndex < shutterSpeed.currentSupportedValues.count - 1 else {
                return
            }

            let currentEditor = camera.currentEditor
            currentEditor[Camera2Params.shutterSpeed]?.value = shutterSpeed.currentSupportedValues.sorted()[currentIndex + 1]
            currentEditor.saveSettings(currentConfig: camera.config)
        } else {
            // Change EV.
            guard let currentIndex = evSetting.currentSupportedValues.sorted().firstIndex(of: evSetting.value),
                  currentIndex < evSetting.currentSupportedValues.count - 1 else {
                return
            }

            let currentEditor = camera.currentEditor
            currentEditor[Camera2Params.exposureCompensation]?.value = evSetting.currentSupportedValues.sorted()[currentIndex + 1]
            currentEditor.saveSettings(currentConfig: camera.config)
        }
    }

    /// Decrease Exposure value. It can be EV or shutter speed.
    ///
    /// - Parameters:
    ///     - state: sky controller event state
    func decreaseExposureValue(_ state: SkyCtrl4ButtonEventState) {
        guard state == .pressed,
              let camera = drone?.currentCamera,
              let evSetting = camera.config[Camera2Params.exposureCompensation] else {
            return
        }

        if evSetting.currentSupportedValues.isEmpty {
            // Change shutter.
            guard let shutterSpeed = camera.config[Camera2Params.shutterSpeed],
                  let currentIndex = shutterSpeed.currentSupportedValues.sorted().firstIndex(of: shutterSpeed.value),
                  currentIndex > 0 else {
                return
            }

            let currentEditor = camera.currentEditor
            currentEditor[Camera2Params.shutterSpeed]?.value = shutterSpeed.currentSupportedValues.sorted()[currentIndex - 1]
            currentEditor.saveSettings(currentConfig: camera.config)
        } else {
            // Change EV.
            guard let currentIndex = evSetting.currentSupportedValues.sorted().firstIndex(of: evSetting.value),
                  currentIndex > 0 else {
                return
            }

            let currentEditor = camera.currentEditor
            currentEditor[Camera2Params.exposureCompensation]?.value = evSetting.currentSupportedValues.sorted()[currentIndex - 1]
            currentEditor.saveSettings(currentConfig: camera.config)
        }
    }
}

// MARK: - Private Zoom Funcs
private extension RightSliderViewModel {
    /// Increases or decreases zoom velocity.
    ///
    /// - Parameters:
    ///     - state: Sky controller event state
    ///     - newValue: new zoom velocity value
    func updateZoomVelocity(_ state: SkyCtrl4ButtonEventState = .pressed, newValue: Double) {
        guard state == .pressed else {
            return
        }
        Services.hub.drone.zoomService.setZoomVelocity(newValue)
    }
}
