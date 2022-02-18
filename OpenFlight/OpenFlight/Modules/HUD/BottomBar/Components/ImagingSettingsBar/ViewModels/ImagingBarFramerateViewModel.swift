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

/// View model for imaging settings bar framerate item.

final class ImagingBarFramerateViewModel: BarButtonViewModel<ImagingBarState> {
    // MARK: - Constants
    private enum Constants {
        /// Maximum number of items displayed at the same time on segmented bar.
        static let maxItemsDisplayed = 9
    }

    // MARK: - Private Properties
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// Reference to main camera peripheral.
    private var cameraRef: Ref<MainCamera2>?
    /// List of available framerates.
    private let availableFramerates: [Camera2RecordingFramerate] = Camera2RecordingFramerate.availableFramerates
    /// Current mission manager.
    private unowned let currentMissionManager: CurrentMissionManager

    // MARK: - init
    /// Constructor.
    ///
    /// - Parameters:
    ///   - currentMissionManager: current mission mode manager
    init(currentMissionManager: CurrentMissionManager) {
        self.currentMissionManager = currentMissionManager
        super.init(barId: "Framerate")

        let copy = state.value.copy()
        copy.showUnsupportedModes = true
        copy.maxItems = Constants.maxItemsDisplayed
        state.set(copy)

        currentMissionManager.modePublisher
            .sink { [unowned self] _ in
                if let camera = cameraRef?.value {
                    updateState(camera: camera)
                }
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
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [unowned self] camera in
            guard let camera = camera else { return }
            updateState(camera: camera)
        }
    }

    /// Updates current state.
    ///
    /// - Parameter camera: camera peripheral
    func updateState(camera: Camera2) {
        let copy = state.value.copy()
        copy.mode = camera.config[Camera2Params.videoRecordingFramerate]?.value

        // Setup a camera configuration editor in order to compute which video recording framerates
        // are supported regarding the current video recording resolution and HDR mode.
        let editor = camera.config.edit(fromScratch: true)
        editor[Camera2Params.videoRecordingResolution]?.value = camera.config[Camera2Params.videoRecordingResolution]?.value
        editor[Camera2Params.videoRecordingDynamicRange]?.value = camera.config[Camera2Params.videoRecordingDynamicRange]?.value

        // currently supported framerates
        var supportedValues = editor[Camera2Params.videoRecordingFramerate]?.currentSupportedValues
            .intersection(availableFramerates)

        // apply restrictions for current mission, if any
        if let restrictions = currentMissionManager.mode.cameraRestrictions,
           let resolution = camera.config[Camera2Params.videoRecordingResolution]?.value,
           let suppportedFrameratesForMission = restrictions.supportedFrameratesByResolution?[resolution] {
            supportedValues = supportedValues?.intersection(suppportedFrameratesForMission)
        }

        copy.supportedModes = supportedValues?.sorted() ?? []
        state.set(copy)
    }
}
