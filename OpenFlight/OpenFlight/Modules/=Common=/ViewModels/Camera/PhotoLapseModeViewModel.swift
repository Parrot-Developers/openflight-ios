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

import GroundSdk

/// State for `PhotoLapseModeViewModel`.
final class PhotoLapseState: DeviceConnectionState {
    // MARK: - Internal Properties
    /// Boolean describing current timelapse state.
    var isTimelapseInProgress: Bool = false
    /// Boolean describing current gpslapse state.
    var isGpslapseInProgress: Bool = false
    /// Number of photos which has been take.
    var photosNumber: Int = 0
    /// Current progress of the gpslapse or timelapse. It represents the interval between each photo capture.
    var currentProgress: Double = 0.0
    /// Selected gpslapse or timelapse value.
    var selectedValue: Double = 1.0

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: connection state
    ///    - isTimelapseInProgress: boolean describing current timelapse state
    ///    - isGpslapseInProgress: boolean describing current gpslapse state
    ///    - photosNumber: number of photos which has been take
    ///    - currentProgress: current progress of the gpslapse or timelapse
    ///    - selectedValue: selected value
    init(connectionState: DeviceState.ConnectionState,
         isTimelapseInProgress: Bool,
         isGpslapseInProgress: Bool,
         photosNumber: Int,
         currentProgress: Double,
         selectedValue: Double) {
        super.init(connectionState: connectionState)
        self.isTimelapseInProgress = isTimelapseInProgress
        self.isGpslapseInProgress = isGpslapseInProgress
        self.photosNumber = photosNumber
        self.currentProgress = currentProgress
        self.selectedValue = selectedValue
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? PhotoLapseState else {
            return false
        }
        return super.isEqual(to: other)
            && self.isTimelapseInProgress == other.isTimelapseInProgress
            && self.isGpslapseInProgress == other.isGpslapseInProgress
            && self.photosNumber == other.photosNumber
            && self.currentProgress == other.currentProgress
            && self.selectedValue == other.selectedValue
    }

    override func copy() -> PhotoLapseState {
        return PhotoLapseState(connectionState: connectionState,
                               isTimelapseInProgress: isTimelapseInProgress,
                               isGpslapseInProgress: isGpslapseInProgress,
                               photosNumber: photosNumber,
                               currentProgress: currentProgress,
                               selectedValue: selectedValue)
    }
}

/// View model that manages timelapse and gpslapse photo capture mode.
final class PhotoLapseModeViewModel: DroneStateViewModel<PhotoLapseState> {
    // MARK: - Private Properties
    private var photoCaptureRef: Ref<Camera2PhotoCapture>?
    private var photoProgressIndicatorRef: Ref<Camera2PhotoProgressIndicator>?
    private var cameraRef: Ref<MainCamera2>?
    private var camera: Camera2? {
        return drone?.currentCamera
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)
        listenCamera(drone: drone)
    }
}

// MARK: - Private Funcs
private extension PhotoLapseModeViewModel {
    /// Starts watcher for camera.
    ///
    /// - Parameters:
    ///   - drone: the current drone
    func listenCamera(drone: Drone) {
        // reset capture and progress references on drone change
        photoCaptureRef = nil
        photoProgressIndicatorRef = nil

        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [unowned self] camera in
            guard let camera = camera else { return }
            // update camera mode
            updateMode(withCamera: camera)
            updateSelectedValue(withCamera: camera)

            // listen to capture and progress components
            listenPhotoCapture(camera: camera)
            listenProgressIndicator(camera: camera)
        }
    }

    /// Listens to photo capture component.
    ///
    /// - Parameters:
    ///    - camera: the camera
    func listenPhotoCapture(camera: Camera2) {
        // do not register photo capture observer if not needed
        guard photoCaptureRef?.value == nil else { return }

        photoCaptureRef = camera.getComponent(Camera2Components.photoCapture) { [unowned self] photoCapture in
            updateMode(withCamera: camera)
            guard let photoCaptureState = photoCapture?.state,
                  case .started(_, let photoCount, _) = photoCaptureState else { return }
            updatePhotoCount(photoCount: photoCount)
        }
    }

    /// Listens to photo progress indicator component.
    ///
    /// - Parameters:
    ///    - camera: the camera
    func listenProgressIndicator(camera: Camera2) {
        // do not register progress indicator observer if not needed
        guard photoProgressIndicatorRef?.value == nil else { return }

        photoProgressIndicatorRef = camera.getComponent(Camera2Components.photoProgressIndicator) { [unowned self] photoProgressIndicator in
            guard let photoProgressIndicator = photoProgressIndicator else { return }
            updateProgress(photoProgressIndicator: photoProgressIndicator)
        }
    }

    /// Update state from camera mode.
    ///
    /// - Parameters:
    ///      - camera: current camera
    func updateMode(withCamera camera: Camera2) {
        guard camera.photoCapture?.state.isStarted == true else { return }

        let copy = state.value.copy()
        let currentCameraMode = CameraUtils.computeCameraMode(camera: camera)
        copy.isGpslapseInProgress = currentCameraMode == .gpslapse
        copy.isTimelapseInProgress = currentCameraMode == .timelapse
        state.set(copy)
    }

    /// Updates photo number during a timelapse and a gpslapse.
    ///
    /// - Parameters:
    ///     - photoCount: current photo count
    func updatePhotoCount(photoCount: Int) {
        guard state.value.isGpslapseInProgress || state.value.isTimelapseInProgress else { return }
        let copy = state.value.copy()
        copy.photosNumber = photoCount
        state.set(copy)
    }

    /// Updates selected value.
    ///
    /// - Parameters:
    ///     - camera: current camera
    func updateSelectedValue(withCamera camera: Camera2) {
        let copy = state.value.copy()
        switch CameraUtils.computeCameraMode(camera: camera) {
        case .timelapse:
            if let photoTimelapseInterval = camera.config[Camera2Params.photoTimelapseInterval]?.value {
                copy.selectedValue = photoTimelapseInterval
            }
        case .gpslapse:
            if let photoGpslapseInterval = camera.config[Camera2Params.photoGpslapseInterval]?.value {
                copy.selectedValue = photoGpslapseInterval
            }
        default:
            break
        }
        state.set(copy)
    }

    /// Updates timelapse or gpslapse progress.
    ///
    /// - Parameters:
    ///     - photoProgressIndicator: current photo progress indicator
    func updateProgress(photoProgressIndicator: Camera2PhotoProgressIndicator) {
        let copy = state.value.copy()

        if copy.isGpslapseInProgress {
            copy.currentProgress = photoProgressIndicator.remainingDistance ?? 0.0
        } else if copy.isTimelapseInProgress {
            copy.currentProgress = photoProgressIndicator.remainingTime ?? 0.0
        }

        state.set(copy)
    }
}
