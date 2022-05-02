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
import Combine

/// State for `CameraShutterButtonViewModel`.
final class CameraShutterButtonState: DeviceConnectionState {
    // MARK: - Internal Properties
    /// Current camera mode (photo/recording).
    fileprivate(set) var cameraMode: Camera2Mode = .recording
    /// Current camera capture mode.
    fileprivate(set) var cameraCaptureMode: CameraCaptureMode = .video
    /// Current camera capture sub mode.
    fileprivate(set) var cameraCaptureSubMode: BarItemSubMode?
    /// Current photo function state.
    fileprivate(set) var photoFunctionState: Camera2PhotoCaptureState = .stopped(latestSavedMediaId: nil)
    /// Current user storage state.
    fileprivate(set) var userStorageState = GlobalUserStorageState()
    /// Current recording time state.
    fileprivate(set) var recordingTimeState = RecordingTimeState()
    /// Current state for panorama mode.
    fileprivate(set) weak var panoramaModeState: PanoramaModeState?
    /// Current state for timelapse and gpslapse mode.
    fileprivate(set) weak var lapseModeState: PhotoLapseState?
    /// Whether shutter button is enabled.
    fileprivate(set) var enabled = true

    // MARK: - Public Properties
    /// Returns if storage is ready.
    var isStorageReady: Bool {
        return userStorageState.removableUserStorageFileSystemState == .ready ||
            userStorageState.internalUserStorageFileSystemState == .ready
    }

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: drone connection state
    ///    - cameraMode: current camera mode
    ///    - cameraCaptureMode: current camera capture mode
    ///    - cameraCaptureSubMode: current camera capture sub mode
    ///    - photoFunctionState: current photo function state
    ///    - userStorageState: current user storage state
    ///    - recordingTimeState: current recording time state
    ///    - panoramaModeState: current state for panorama mode
    ///    - lapseModeState: current state for lapse capture mode
    init(connectionState: DeviceState.ConnectionState,
         cameraMode: Camera2Mode,
         cameraCaptureMode: CameraCaptureMode,
         cameraCaptureSubMode: BarItemSubMode?,
         photoFunctionState: Camera2PhotoCaptureState,
         userStorageState: GlobalUserStorageState,
         recordingTimeState: RecordingTimeState,
         panoramaModeState: PanoramaModeState?,
         lapseModeState: PhotoLapseState?,
         enabled: Bool) {
        super.init(connectionState: connectionState)

        self.cameraMode = cameraMode
        self.cameraCaptureMode = cameraCaptureMode
        self.cameraCaptureSubMode = cameraCaptureSubMode
        self.photoFunctionState = photoFunctionState
        self.userStorageState = userStorageState
        self.recordingTimeState = recordingTimeState
        self.panoramaModeState = panoramaModeState
        self.lapseModeState = lapseModeState
        self.enabled = enabled
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? CameraShutterButtonState else { return false }

        return super.isEqual(to: other)
            && cameraMode == other.cameraMode
            && cameraCaptureMode == other.cameraCaptureMode
            && cameraCaptureSubMode?.key == other.cameraCaptureSubMode?.key
            && photoFunctionState == other.photoFunctionState
            && userStorageState == other.userStorageState
            && recordingTimeState == other.recordingTimeState
            && panoramaModeState == other.panoramaModeState
            && lapseModeState == other.lapseModeState
            && enabled == other.enabled
    }

    override func copy() -> CameraShutterButtonState {
        let copy = CameraShutterButtonState(connectionState: connectionState,
                                            cameraMode: cameraMode,
                                            cameraCaptureMode: cameraCaptureMode,
                                            cameraCaptureSubMode: cameraCaptureSubMode,
                                            photoFunctionState: photoFunctionState,
                                            userStorageState: userStorageState,
                                            recordingTimeState: recordingTimeState,
                                            panoramaModeState: panoramaModeState,
                                            lapseModeState: lapseModeState,
                                            enabled: enabled)
        return copy
    }
}

/// View model for `CameraShutterButton`, notifies on recording/photo capture changes and handles user action.
final class CameraShutterButtonViewModel: DroneStateViewModel<CameraShutterButtonState> {
    // MARK: - Public Properties
    public var hideBottomBarEventPublisher: AnyPublisher<Bool, Never> {
        hideBottomBarEventSubject.eraseToAnyPublisher()
    }

    // MARK: - Private Properties
    private var hideBottomBarEventSubject = CurrentValueSubject<Bool, Never>(false)
    private var cameraRef: Ref<MainCamera2>?
    private var photoCaptureRef: Ref<Camera2PhotoCapture>?
    private let cameraCaptureModeViewModel = CameraCaptureModeViewModel(
        panoramaService: Services.hub.panoramaService, currentMissionManager: Services.hub.currentMissionManager)
    private let panoramaModeViewModel = PanoramaModeViewModel()
    private var userStorageViewModel = GlobalUserStorageViewModel()
    private var photoLapseModeViewModel = PhotoLapseModeViewModel()
    private var recordingTimeViewModel = RecordingTimeViewModel()
    private var remoteControlRecordObserver: Any?
    private var countDownTimer: Timer?

    // MARK: - Private Enums
    private enum Constants {
        static let countDownInterval: TimeInterval = 1.0
        static let timerBeforeRestartRecord: Int = 5
    }

    // MARK: - Init
    override init() {
        super.init()

        listenCameraCaptureMode()
        listenPanoramaMode()
        listenUserStorage()
        listenLapseMode()
        listenRecordingTime()
        listenRemoteControlRecordChanges()
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.remove(observer: remoteControlRecordObserver)
        remoteControlRecordObserver = nil
        countDownTimer?.invalidate()
        countDownTimer = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenCamera(drone: drone)
    }

    // MARK: - Internal Funcs
    /// Starts or stops recording or photo capture.
    func toggleCapture() {
        guard let camera = drone?.currentCamera,
              let cameraMode = camera.mode else {
            return
        }

        switch cameraMode {
        case .recording:
            toggleRecording(camera: camera)
        case .photo:
            togglePhoto(camera: camera)
        }
    }
}

// MARK: - Private Funcs
/// Private methods related to watcher on Peripherals or ViewModels.
private extension CameraShutterButtonViewModel {
    /// Starts watcher for camera.
    func listenCamera(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [unowned self] camera in
            guard let camera = camera,
                  let cameraMode = camera.mode else {
                return
            }

            listenPhotoCapture(camera)
            let copy = state.value.copy()
            copy.cameraMode = cameraMode
            state.set(copy)
            udpateEnabledState()
        }
    }

    /// Starts watcher for photo capture.
    func listenPhotoCapture(_ camera: MainCamera2) {
        photoCaptureRef = camera.getComponent(Camera2Components.photoCapture) { [unowned self] photo in
            guard let photoState = photo?.state else {
                return
            }

            let copy = state.value.copy()
            copy.photoFunctionState = photoState
            state.set(copy)
        }
    }

    /// Starts watcher for user storage state.
    func listenUserStorage() {
        userStorageViewModel.state.valueChanged = { [weak self] state in
            self?.updateUserStorageState(state)
        }
        updateUserStorageState(userStorageViewModel.state.value)
    }

    /// Starts watcher for camera capture mode.
    func listenCameraCaptureMode() {
        cameraCaptureModeViewModel.state.valueChanged = { [weak self] state in
            self?.updateCameraCaptureModeState(state)
        }
        updateCameraCaptureModeState(cameraCaptureModeViewModel.state.value)
    }

    /// Listen notifications about remote control rear right button changes.
    /// It corresponds to photo capture or recording start.
    func listenRemoteControlRecordChanges() {
        remoteControlRecordObserver = NotificationCenter.default.addObserver(
            forName: .remoteControlShutterButtonPressed,
            object: nil,
            queue: nil,
            using: { [weak self] _ in
                self?.toggleCapture()
            })
    }

    /// Starts watcher for panorama mode.
    func listenPanoramaMode() {
        panoramaModeViewModel.state.valueChanged = { [weak self] state in
            self?.updatePanoramaModeState(state)
        }
        updatePanoramaModeState(panoramaModeViewModel.state.value)
    }

    /// Starts watcher for timelapse and gpslapse mode.
    func listenLapseMode() {
        photoLapseModeViewModel.state.valueChanged = { [weak self] state in
            self?.updateLapseModeState(state)
        }
        updateLapseModeState(photoLapseModeViewModel.state.value)
    }

    /// Starts watcher for current recording time.
    func listenRecordingTime() {
        recordingTimeViewModel.state.valueChanged = { [weak self] state in
            self?.updateRecordingTimeState(state)
        }
        updateRecordingTimeState(recordingTimeViewModel.state.value)
    }
}

/// Private methods related to state update.
private extension CameraShutterButtonViewModel {
    /// Updates current recording time state.
    ///
    /// - Parameters:
    ///    - recordingState: current recording time state
    func updateRecordingTimeState(_ recordingState: RecordingTimeState) {
        let copy = state.value.copy()
        copy.recordingTimeState = recordingState
        state.set(copy)
    }

    /// Update current lapse capture mode state.
    ///
    /// - Parameters:
    ///     - photosState: current photo lapse state
    func updateLapseModeState(_ photosState: PhotoLapseState) {
        let copy = state.value.copy()
        copy.lapseModeState = photosState
        state.set(copy)
    }

    /// Update current panorama mode state.
    ///
    /// - Parameters:
    ///     - panoramaState: current panorama mode state
    func updatePanoramaModeState(_ panoramaState: PanoramaModeState) {
        let copy = state.value.copy()
        copy.panoramaModeState = panoramaState
        state.set(copy)
    }

    /// Update current user storage state.
    ///
    /// - Parameters:
    ///     - userStorageState: current global user storage state
    func updateUserStorageState(_ userStorageState: GlobalUserStorageState) {
        let copy = state.value.copy()
        copy.userStorageState = userStorageState
        state.set(copy)
    }

    /// Update current camera capture mode.
    ///
    /// - Parameters:
    ///     - captureState: current bar button state
    func updateCameraCaptureModeState(_ captureState: CameraBarButtonState) {
        if let mode = captureState.mode as? CameraCaptureMode {
            let copy = state.value.copy()
            copy.cameraCaptureMode = mode
            copy.cameraCaptureSubMode = captureState.subMode
            state.set(copy)
        }
        udpateEnabledState()
    }

    /// Updates enabled state.
    ///
    /// Shutter button is disabled if current capture mode is not a supported capture mode,
    /// or if there is no current supported photo mode (recording or photo).
    func udpateEnabledState() {
        let captureState = cameraCaptureModeViewModel.state.value
        let copy = state.value.copy()
        if let mode = captureState.mode as? CameraCaptureMode,
           // when `supportedModes` is nil, all capture modes are supported
           !(captureState.supportedModes?.customContains(mode) ?? true) {
            copy.enabled = false
        } else if let camera = drone?.currentCamera,
             let modeParam = camera.config[Camera2Params.mode] {
            copy.enabled = !modeParam.currentSupportedValues.isEmpty
        } else {
            copy.enabled = false
        }
        state.set(copy)
    }
}

/// Private methods related to photo or record action.
private extension CameraShutterButtonViewModel {
    /// Starts or stops photo capture.
    ///
    /// - Parameters:
    ///     - camera: current camera
    func togglePhoto(camera: Camera2) {
        switch state.value.cameraCaptureMode {
        case .panorama where state.value.panoramaModeState?.inProgress == true:
            panoramaModeViewModel.cancelPanoramaPhotoCapture()
        case .panorama:
            panoramaModeViewModel.startPanoramaPhotoCapture()
            hideBottomBarEventSubject.send(true)
        default:
            guard let photoCapture = camera.photoCapture else { return }

            switch photoCapture.state {
            case .stopped:
                photoCapture.start()
            case .started:
                photoCapture.stop()
            default:
                break
            }
        }
    }

    /// Starts or stops video recording.
    ///
    /// - Parameters:
    ///     - camera: current camera
    func toggleRecording(camera: Camera2) {
        guard let recording = camera.recording else { return }

        switch recording.state {
        case .stopped:
            recording.start()
        case .started:
            recording.stop()
        default:
            break
        }
    }
}
