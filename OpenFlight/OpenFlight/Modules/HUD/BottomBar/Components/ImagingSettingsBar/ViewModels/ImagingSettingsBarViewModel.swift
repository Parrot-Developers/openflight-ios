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

/// State for `ImagingSettingsBarViewModel`.
final class ImagingSettingsBarState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    fileprivate(set) var resolution: Camera2RecordingResolution?
    fileprivate(set) var isShutterAndISOManual: Bool = false

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - resolution: Camera video resolution.
    ///    - isShutterAndISOManual: Boolean to indicate wether shutter speed and ISO are manual.
    init(resolution: Camera2RecordingResolution?,
         isShutterAndISOManual: Bool) {
        self.resolution = resolution
        self.isShutterAndISOManual = isShutterAndISOManual
    }

    // MARK: - Internal Funcs
    func isEqual(to other: ImagingSettingsBarState) -> Bool {
        return self.resolution == other.resolution
            && self.isShutterAndISOManual == other.isShutterAndISOManual
    }

    /// Returns a copy of the object.
    func copy() -> ImagingSettingsBarState {
        let copy = ImagingSettingsBarState(resolution: self.resolution,
                                           isShutterAndISOManual: self.isShutterAndISOManual)
        return copy
    }
}

/// ViewModel for Imaging Settings bar.
final class ImagingSettingsBarViewModel: DroneWatcherViewModel<ImagingSettingsBarState> {
    // MARK: - Private Properties
    private var cameraRef: Ref<MainCamera2>?

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        listenCamera(drone: drone)
    }
}

// MARK: - Private Funcs
private extension ImagingSettingsBarViewModel {
    /// Starts watcher for camera.
    func listenCamera(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [weak self] camera in
            self?.updateCurrentAutoExposureValues(with: camera)
        }

        updateCurrentAutoExposureValues(with: drone.getPeripheral(Peripherals.mainCamera2))
    }

    /// Updates current auto exposure and resolution values.
    ///
    /// - Parameters:
    ///     - camera: current camera
    func updateCurrentAutoExposureValues(with camera: MainCamera2?) {
        guard let exposureSettings = camera?.currentEditor[Camera2Params.exposureMode]?.value,
              let resolution = camera?.config[Camera2Params.videoRecordingResolution]?.value else {
            return
        }

        let copy = state.value.copy()
        copy.resolution = resolution
        copy.isShutterAndISOManual = exposureSettings.automaticIsoSensitivity == false
            && exposureSettings.automaticShutterSpeed == false
        state.set(copy)
    }
}
