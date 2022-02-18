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

import Combine
import GroundSdk
import SwiftyUserDefaults

/// View model for imaging settings bar shutter speed item.
final class ImagingBarShutterSpeedViewModel: AutomatableBarButtonViewModel<AutomatableRulerImagingBarState> {

    // MARK: - Private Properties

    private var droneStateRef: Ref<DeviceState>?
    private var exposureIndicatorRef: Ref<Camera2ExposureIndicator>?
    private var cameraRef: Ref<MainCamera2>?
    /// Whether HDR is turned on.
    @Published private var isHdrOn = false
    /// Camera exposure lock service.
    private unowned var exposureLockService: ExposureLockService
    /// Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Override Funcs

    /// Constructor.
    ///
    /// - Parameter exposureLockService: camera exposure lock service
    init(exposureLockService: ExposureLockService) {
        self.exposureLockService = exposureLockService
        super.init(barId: "ShutterSpeed")

        exposureLockService.statePublisher
            .combineLatest($isHdrOn)
            .sink { [unowned self] exposureLockState, hdrOn in
                let copy = state.value.copy()
                copy.enabled = !exposureLockState.locked
                    && !exposureLockState.locking
                    && !hdrOn
                state.set(copy)
                if !copy.enabled {
                    // autoclose if necessary
                    state.value.isSelected.set(false)
                }
            }
            .store(in: &cancellables)
    }

    override func listenDrone(drone: Drone) {
        if !drone.isConnected {
            let copy = state.value.copy()
            // If drone is not connected, last used shutter speed value
            // should be displayed (dashed string if none).
            if let shutterSpeedKey = Defaults.lastShutterSpeedValue {
                let shutterSpeed = Camera2ShutterSpeed(rawValue: shutterSpeedKey)
                copy.mode = shutterSpeed
            } else {
                copy.title = L10n.unitSecond.dashPrefixed
            }
            state.set(copy)
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
        currentEditor.saveSettings(currentConfig: camera.config)
    }

    override func toggleAutomaticMode() {
        guard let camera = drone?.currentCamera,
            let exposureMode = camera.config[Camera2Params.exposureMode]?.value else {
            return
        }

        let editor = camera.currentEditor
        if exposureMode.automaticShutterSpeed {
            // switch to manual shutter speed mode
            editor[Camera2Params.exposureMode]?.value = exposureMode.toManualShutterSpeed()
            if let exposureIndicator = camera.getComponent(Camera2Components.exposureIndicator) {
                // apply current shutter speed to manual shutter speed setting
                editor[Camera2Params.shutterSpeed]?.value = exposureIndicator.shutterSpeed
            }
        } else {
            // switch to automatic shutter speed
            editor[Camera2Params.exposureMode]?.value = exposureMode.toAutomaticShutterSpeed()
        }
        editor.saveSettings(currentConfig: camera.config)
    }

    override func copy() -> ImagingBarShutterSpeedViewModel {
        return ImagingBarShutterSpeedViewModel(exposureLockService: exposureLockService)
    }
}

// MARK: - Private Funcs
private extension ImagingBarShutterSpeedViewModel {
    /// Starts watcher for drone state.
    func listenState(drone: Drone) {
        droneStateRef = drone.getState { [unowned self] droneState in
            guard let droneState = droneState else {
                return
            }

            if droneState.connectionState == .disconnected {
                // Autoclose if needed.
                state.value.isSelected.set(false)
            }
        }
    }

    /// Starts watcher for exposure values.
    func listenExposureValues(drone: Drone) {
        exposureIndicatorRef = drone.currentCamera?
            .getComponent(Camera2Components.exposureIndicator,
                          observer: { [unowned self] exposureIndicator in
                let copy = state.value.copy()
                copy.mode = exposureIndicator?.shutterSpeed
                state.set(copy)
            })
    }

    /// Starts watcher for camera.
    func listenCamera(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [unowned self] camera in
            guard let camera = camera,
                let exposureMode = camera.config[Camera2Params.exposureMode],
                let shutterSpeed = camera.config[Camera2Params.shutterSpeed] else {
                return
            }

            let copy = state.value.copy()
            copy.supportedModes = exposureMode.manualShutterSpeedAvailable
                ? shutterSpeed.currentSupportedValues.sorted()
                : [Camera2ShutterSpeed]()
            copy.mode = shutterSpeed.value
            copy.image = exposureMode.value == .manualIsoSensitivity ? Asset.BottomBar.Icons.iconAuto.image : nil
            copy.isAutomatic = exposureMode.value.automaticShutterSpeed
            state.set(copy)
            state.value.exposureSettingsMode.set(exposureMode.value)
            isHdrOn = camera.isHdrOn
        }
    }
}
