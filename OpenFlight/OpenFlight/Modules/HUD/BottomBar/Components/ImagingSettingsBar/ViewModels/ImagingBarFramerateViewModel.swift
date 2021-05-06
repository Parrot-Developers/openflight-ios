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

/// View model for imaging settings bar framerate item.

final class ImagingBarFramerateViewModel: BarButtonViewModel<ImagingBarState> {
    // MARK: - Private Properties
    private var cameraRef: Ref<MainCamera2>?
    /// List of available framerates.
    private let availableFramerates: [Camera2RecordingFramerate] = Camera2RecordingFramerate.availableFramerates
    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        listenCamera(drone: drone)
    }

    override func update(mode: BarItemMode) {
        guard let camera = drone?.currentCamera,
              !camera.config.updating,
              let framerate = mode as? Camera2RecordingFramerate else {
            return
        }

        let currentEditor = camera.currentEditor
        currentEditor[Camera2Params.videoRecordingFramerate]?.value = framerate
        currentEditor.saveSettings(currentConfig: camera.config)
    }
}

// MARK: - Private Funcs
private extension ImagingBarFramerateViewModel {
    /// Starts watcher for camera.
    func listenCamera(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [weak self] camera in
            guard let camera = camera,
                  let copy = self?.state.value.copy(),
                  let availableFramerates = self?.availableFramerates else {
                return
            }

            copy.mode = camera.config[Camera2Params.videoRecordingFramerate]?.value

            // Setup a camera configuration editor in order to compute which video recording framerates
            // are supported with the current video recording resolution.
            // FIXME: We should use the current configuration instead, but it doesn't work properly with
            // the camera capabilities defined by current Anafi2 firmware.
            let editor = camera.config.edit(fromScratch: true)
            editor[Camera2Params.videoRecordingResolution]?.value = camera.config[Camera2Params.videoRecordingResolution]?.value

            copy.supportedModes = editor[Camera2Params.videoRecordingFramerate]?.currentSupportedValues
                // Several framerate values must be ignored.
                .intersection(availableFramerates)
                .sorted()
            self?.state.set(copy)
        }
    }
}
