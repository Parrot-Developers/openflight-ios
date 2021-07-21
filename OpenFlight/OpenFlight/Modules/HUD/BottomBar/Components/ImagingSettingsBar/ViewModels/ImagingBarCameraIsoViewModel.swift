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

/// View model for imaging settings bar camera iso item.

final class ImagingBarCameraIsoViewModel: AutomatableBarButtonViewModel<AutomatableRulerImagingBarState> {
    // MARK: - Private Properties
    private var droneStateRef: Ref<DeviceState>?
    private var exposureValuesRef: Ref<Camera2ExposureIndicator>?
    private var cameraRef: Ref<MainCamera2>?

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        if !drone.isConnected {
            let copy = self.state.value.copy()
            // If drone is not connected, last used camera iso value
            // should be displayed (dashed string if none).
            if let cameraIsoKey = Defaults.lastCameraIsoValue {
                let cameraIso = Camera2Iso(rawValue: cameraIsoKey)
                copy.mode = cameraIso
            } else {
                copy.title = L10n.unitIso.dashPrefixed
            }
            self.state.set(copy)
        }
        listenState(drone: drone)
        listenExposureValues(drone: drone)
        listenCamera(drone: drone)
    }

    override func update(mode: BarItemMode) {
        guard let cameraIso = mode as? Camera2Iso,
            let camera = drone?.currentCamera,
            !camera.config.updating else {
                return
        }

        let currentEditor = camera.currentEditor
        currentEditor[Camera2Params.isoSensitivity]?.value = cameraIso
        currentEditor[Camera2Params.exposureMode]?.value =
            camera.config[Camera2Params.exposureMode]?.value.toManualIsoSensitivity()
        currentEditor.saveSettings(currentConfig: camera.config)
    }

    override func toggleAutomaticMode() {
        guard let camera = drone?.currentCamera,
            let exposureMode = camera.config[Camera2Params.exposureMode]?.value else {
            return
        }

        let currentEditor = camera.currentEditor
        currentEditor[Camera2Params.exposureMode]?.value = exposureMode.automaticIsoSensitivity ?
            exposureMode.toManualIsoSensitivity() :
            exposureMode.toAutomaticIsoSensitivity()
        currentEditor.saveSettings(currentConfig: camera.config)
    }

    override func copy() -> ImagingBarCameraIsoViewModel {
        return ImagingBarCameraIsoViewModel()
    }
}

// MARK: - Private Funcs
private extension ImagingBarCameraIsoViewModel {
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
        exposureValuesRef = drone.currentCamera?
            .getComponent(Camera2Components.exposureIndicator,
                          observer: { [weak self] exposureIndicator in
                            guard let exposureIndicator = exposureIndicator,
                                drone.currentCamera?.config.updating == false,
                                let copy = self?.state.value.copy()
                                else {
                                    return
                            }

                            copy.mode = exposureIndicator.isoSensitivity
                            self?.state.set(copy)
        })
    }

    /// Starts watcher for camera.
    func listenCamera(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [weak self] camera in
            guard let camera = camera,
                let exposureMode = camera.config[Camera2Params.exposureMode],
                let isoSensitivity = camera.config[Camera2Params.isoSensitivity],
                let copy = self?.state.value.copy() else {
                    return
            }

            copy.supportedModes = isoSensitivity.currentSupportedValues.sorted()
            copy.image = exposureMode.value == .manualShutterSpeed ? Asset.BottomBar.Icons.iconAuto.image : nil
            copy.isAutomatic = exposureMode.value.automaticIsoSensitivity
            self?.state.set(copy)
            self?.state.value.exposureSettingsMode.set(exposureMode.value)
        }
    }
}
