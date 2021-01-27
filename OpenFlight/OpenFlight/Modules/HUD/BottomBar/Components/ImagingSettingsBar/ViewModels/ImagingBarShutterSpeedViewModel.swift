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
import SwiftyUserDefaults

/// View model for imaging settings bar shutter speed item.

final class ImagingBarShutterSpeedViewModel: AutomatableBarButtonViewModel<AutomatableRulerImagingBarState> {
    // MARK: - Private Properties
    private var droneStateRef: Ref<DeviceState>?
    private var exposureIndicatorRef: Ref<Camera2ExposureIndicator>?
    private var cameraRef: Ref<MainCamera2>?

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        if !drone.isConnected {
            let copy = self.state.value.copy()
            // If drone is not connected, last used shutter speed value
            // should be displayed (dashed string if none).
            if let shutterSpeedKey = Defaults.lastShutterSpeedValue {
                let shutterSpeed = Camera2ShutterSpeed(rawValue: shutterSpeedKey)
                copy.mode = shutterSpeed
            } else {
                copy.title = L10n.unitSecond.dashPrefixed
            }
            self.state.set(copy)
        }
        listenState(drone: drone)
        listenExposureValues(drone: drone)
        listenCamera(drone: drone)
    }

    override func update(mode: BarItemMode) {
        guard let shutterSpeed = mode as? Camera2ShutterSpeed,
            let camera = drone?.currentCamera,
            !camera.config.updating else {
                return
        }

        let currentEditor = camera.currentEditor
        currentEditor[Camera2Params.shutterSpeed]?.value = shutterSpeed
        currentEditor[Camera2Params.exposureMode]?.value = camera.config[Camera2Params.exposureMode]?.value.toManualShutterSpeed()
        currentEditor.saveSettings()
    }

    override func toggleAutomaticMode() {
        guard let camera = drone?.currentCamera,
            let exposureMode = camera.config[Camera2Params.exposureMode]?.value else {
            return
        }

        let currentEditor = camera.currentEditor
        currentEditor[Camera2Params.exposureMode]?.value = exposureMode.automaticShutterSpeed ?
            exposureMode.toManualShutterSpeed() :
            exposureMode.toAutomaticShutterSpeed()
        currentEditor.saveSettings()
    }

    override func copy() -> ImagingBarShutterSpeedViewModel {
        return ImagingBarShutterSpeedViewModel()
    }
}

// MARK: - Private Funcs
private extension ImagingBarShutterSpeedViewModel {
    /// Starts watcher for drone state.
    func listenState(drone: Drone) {
        droneStateRef = drone.getState { [weak self] state in
            guard let state = state, let copy = self?.state.value.copy() else {
                return
            }
            copy.enabled = state.connectionState == .connected
            self?.state.set(copy)

            if state.connectionState == .disconnected {
                // Autoclose if needed.
                self?.state.value.isSelected.set(false)
            }
        }
    }

    /// Starts watcher for exposure values.
    func listenExposureValues(drone: Drone) {
        exposureIndicatorRef = drone.currentCamera?
            .getComponent(Camera2Components.exposureIndicator,
                          observer: { [weak self] exposureIndicator in
                            guard let copy = self?.state.value.copy() else { return }
                            copy.mode = exposureIndicator?.shutterSpeed
                            self?.state.set(copy)
        })
    }

    /// Starts watcher for camera.
    func listenCamera(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [weak self] camera in
            guard let camera = camera,
                let exposureMode = camera.config[Camera2Params.exposureMode],
                let shutterSpeed = camera.config[Camera2Params.shutterSpeed],
                let copy = self?.state.value.copy()
                else {
                    return
            }

            copy.supportedModes = exposureMode.manualShutterSpeedAvailable
                ? shutterSpeed.currentSupportedValues.sorted()
                : [Camera2ShutterSpeed]()
            copy.mode = shutterSpeed.value
            copy.image = exposureMode.value.automaticShutterSpeed ? Asset.BottomBar.Icons.iconAuto.image : nil
            copy.isAutomatic = exposureMode.value.automaticShutterSpeed
            self?.state.set(copy)
            self?.state.value.exposureSettingsMode.set(exposureMode.value)
        }
    }
}
