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

/// View model for imaging settings bar photo format item.
final class ImagingBarPhotoFormatViewModel: BarButtonViewModel<ImagingBarState> {

    // MARK: - Private Properties
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// Reference to camera peripheral.
    private var cameraRef: Ref<MainCamera2>?
    /// Panorama service.
    private unowned var panoramaService: PanoramaService

    // MARK: - Init
    /// Constructor.
    ///
    /// - Parameter panoramaService: panorama mode service
    init(panoramaService: PanoramaService) {
        self.panoramaService = panoramaService
        super.init(barId: "PhotoFormat")

        panoramaService.panoramaModeActivePublisher
            .sink { [unowned self] _ in
                updateState(camera: cameraRef?.value)
            }
            .store(in: &cancellables)
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        listenCamera(drone: drone)
    }

    override func update(mode: BarItemMode) {
        guard let camera = drone?.currentCamera,
            !camera.config.updating,
            let photoFormat = mode as? PhotoFormatMode else {
                return
        }

        let currentEditor = camera.currentEditor
        currentEditor[Camera2Params.photoFormat]?.value = photoFormat.format
        currentEditor[Camera2Params.photoFileFormat]?.value = photoFormat.fileFormat
        currentEditor.saveSettings(currentConfig: camera.config)
    }
}

// MARK: - Private Funcs
private extension ImagingBarPhotoFormatViewModel {
    /// Starts watcher for camera.
    ///
    /// - Parameters:
    ///    - drone: drone to monitor
    func listenCamera(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [unowned self] camera in
            updateState(camera: camera)
        }
    }

    /// Updates imaging settings bar state.
    ///
    /// - Parameters:
    ///    - camera: camera peripheral, `nil` if unavailable
    func updateState(camera: Camera2?) {
        guard let camera = camera,
              let cameraMode = CameraUtils.computeCameraMode(camera: camera) else {
                  return
              }

        let photoFormats = cameraMode == .panorama ? [.rectilinearJpeg] : camera.photoFormatModeSupportedValues

        let copy = state.value.copy()
        copy.mode = camera.photoFormatMode
        copy.supportedModes = photoFormats
        copy.unavailableReason = [:]
        copy.showUnsupportedModes = true
        state.set(copy)
    }
}
