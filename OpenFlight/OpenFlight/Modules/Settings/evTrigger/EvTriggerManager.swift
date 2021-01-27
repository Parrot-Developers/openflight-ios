// Copyright (C) 2020 Parrot Drones SAS
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

import SwiftyUserDefaults
import GroundSdk

/// EV trigger manager handle the right trigger actions.

public final class EVTriggerManager: DroneWatcherViewModel<DeviceConnectionState> {
    // MARK: - Shared instance
    /// This is a singleton because this manager lives all the app cyclelife long.
    public static let shared = EVTriggerManager()

    // MARK: - Private Properties
    private var remoteControlUpGrabber: RemoteControlAxisButtonGrabber?
    private var remoteControlDownGrabber: RemoteControlAxisButtonGrabber?
    private var actionKey: String {
        return NSStringFromClass(type(of: self)) + SkyCtrl3AxisEvent.rightSlider.description
    }
    // MARK: - Public Properties
    var isEvTriggerSettingEnabled: Bool {
        return Defaults.evTriggerSetting ?? false
    }

    // MARK: - Override Funcs
    override init(stateDidUpdate: ((DeviceConnectionState) -> Void)? = nil) {
        super.init(stateDidUpdate: stateDidUpdate)

        // Grab remote's rightSlider up event.
        remoteControlUpGrabber = RemoteControlAxisButtonGrabber(axis: .rightSlider,
                                                                event: .rightSliderUp,
                                                                key: actionKey,
                                                                action: increaseValue)
        // Grab remote's rightSlider down event.
        remoteControlDownGrabber = RemoteControlAxisButtonGrabber(axis: .rightSlider,
                                                                  event: .rightSliderDown,
                                                                  key: actionKey,
                                                                  action: decreaseValue)

        updateGrabRemoteControl()
    }

    override public func listenDrone(drone: Drone) {
        // Nothing to do here:
        // currentDroneWatcher is needed here, but the state not
    }

    // MARK: - Public functions
    /// Start mode with the default setting.
    /// Should be call to the AppDelegate's didFinishLaunchingWithOptions.
    public func setup() {
        enableEvTriggerMode(isEvTriggerSettingEnabled)
    }

    /// Enables EV trigger mode.
    ///
    /// - Parameters:
    ///     - isEnabled: enabled trigger mode or not
    func enableEvTriggerMode(_ isEnabled: Bool) {
        Defaults.evTriggerSetting = isEnabled
        updateGrabRemoteControl()
    }
}

// MARK: - Private Funcs
private extension EVTriggerManager {
    /// Update grab mode regarding setting.
    func updateGrabRemoteControl() {
        if isEvTriggerSettingEnabled {
            remoteControlUpGrabber?.grab()
            remoteControlDownGrabber?.grab()
        } else {
            remoteControlUpGrabber?.ungrab()
            remoteControlDownGrabber?.ungrab()
        }
    }

    /// Increase mapped value.
    func increaseValue(_ state: SkyCtrl3ButtonEventState) {
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
            currentEditor.saveSettings()
        } else {
            // Change EV.
            guard let currentIndex = evSetting.currentSupportedValues.sorted().firstIndex(of: evSetting.value),
                currentIndex < evSetting.currentSupportedValues.count - 1 else {
                    return
            }

            let currentEditor = camera.currentEditor
            currentEditor[Camera2Params.exposureCompensation]?.value = evSetting.currentSupportedValues.sorted()[currentIndex + 1]
            currentEditor.saveSettings()
        }
    }

    /// Decrease mapped value.
    func decreaseValue(_ state: SkyCtrl3ButtonEventState) {
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
            currentEditor.saveSettings()
        } else {
            // Change EV.
            guard let currentIndex = evSetting.currentSupportedValues.sorted().firstIndex(of: evSetting.value),
                currentIndex > 0 else {
                    return
            }

            let currentEditor = camera.currentEditor
            currentEditor[Camera2Params.exposureCompensation]?.value = evSetting.currentSupportedValues.sorted()[currentIndex - 1]
            currentEditor.saveSettings()
        }
    }
}
