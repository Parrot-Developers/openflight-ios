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

import Combine
import GroundSdk

/// View model for imaging bar auto mode setting. In this mode exposure settings
/// and white balance settings are all monitored automatically.
final class ImagingBarAutoModeViewModel {

    // MARK: - Published Properties

    /// Whether ISO and shutter speed are both in automatic mode.
    @Published fileprivate(set) var autoExposure = false
    /// Whether auto/manual exposure button is enabled.
    @Published fileprivate(set) var autoExposureButtonEnabled = false

    /// Image for current state.
    var image: AnyPublisher<UIImage, Never> {
        $autoExposure
            .map { autoExposure in
                return autoExposure
                    ? Asset.BottomBar.Icons.iconManualAutoAuto.image
                    : Asset.BottomBar.Icons.iconManualAutoManual.image
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private Properties
    private var cameraRef: Ref<MainCamera2>?
    private var currentDrone = Services.hub.currentDroneHolder
    /// Whether HDR is turned on.
    @Published private var isHdrOn = false
    /// Camera exposure lock service.
    private unowned var exposureLockService: ExposureLockService
    /// Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    /// Constructor.
    ///
    /// - Parameter exposureLockService: camera exposure lock service
    init(exposureLockService: ExposureLockService) {
        self.exposureLockService = exposureLockService
        currentDrone.dronePublisher
            .sink { [unowned self] drone in
                listenCamera(drone: drone)
            }
            .store(in: &cancellables)

        exposureLockService.statePublisher
            .combineLatest($isHdrOn)
            .sink { [unowned self] exposureLockState, hdrOn in
                autoExposureButtonEnabled = !exposureLockState.locked
                    && !exposureLockState.locking
                    && !hdrOn
            }
            .store(in: &cancellables)
    }

    // MARK: - Internal Funcs
    /// Toggle auto mode.
    func toggleAutoMode() {
        if let camera = currentDrone.drone.currentCamera,
           let exposureMode = camera.config[Camera2Params.exposureMode]?.value {
            let editor = camera.currentEditor
            editor[Camera2Params.exposureMode]?.value = exposureMode.automaticIsoAndShutterSpeed ?
                .manual : exposureMode.toAutomaticMode()
            editor.saveSettings(currentConfig: camera.config)
        }
    }
}

// MARK: - Private Funcs
private extension ImagingBarAutoModeViewModel {
    /// Starts watcher for camera.
    ///
    /// - Parameter drone: drone to observe
    func listenCamera(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [unowned self] camera in
            guard let camera = camera,
                  let exposureMode = camera.config[Camera2Params.exposureMode] else {
                return
            }

            autoExposure = exposureMode.value.automaticIsoAndShutterSpeed
            isHdrOn = camera.isHdrOn
        }
    }
}
