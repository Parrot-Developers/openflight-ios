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

/// State for `CameraShutterButtonViewModel`.
final class CameraShutterButtonState: DeviceConnectionState {
    // MARK: - Internal Properties
    /// Current camera mode (photo/recording).
    fileprivate(set) var cameraMode: Camera2Mode = .recording
    /// Current camera capture mode.
    fileprivate(set) var cameraCaptureMode: CameraCaptureMode = .video
    /// Current camera capture sub mode.
    fileprivate(set) var cameraCaptureSubMode: BarItemSubMode?
    /// Current recording function state.
    fileprivate(set) var recordingFunctionState: Camera2RecordingState = .stopped(latestSavedMediaId: nil)
    /// Current photo function state.
    fileprivate(set) var photoFunctionState: Camera2PhotoCaptureState = .stopped(latestSavedMediaId: nil)
    /// Current user storage state.
    fileprivate(set) var userStorageState = GlobalUserStorageState()
    /// Current recording time.
    fileprivate(set) var recordingTime: TimeInterval?
    /// Remaining record time.
    fileprivate(set) var remainingRecordTime: TimeInterval?
    /// Current state for timer mode.
    fileprivate(set) weak var timerModeState: TimerModeState?
    /// Current state for panorama mode.
    fileprivate(set) weak var panoramaModeState: PanoramaModeState?
    /// Current state for timelapse and gpslapse mode.
    fileprivate(set) weak var lapseModeState: PhotoLapseState?

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
    ///    - recordingFunctionState: current recording function state
    ///    - photoFunctionState: current photo function state
    ///    - userStorageState: current user storage state
    ///    - recordingTime: current recording time
    ///    - remainingRecordTime: remaining record time
    ///    - timerModeState: current state for timer mode
    ///    - panoramaModeState: current state for panorama mode
    ///    - lapseModeState: current state for lapse capture mode
    init(connectionState: DeviceState.ConnectionState,
         cameraMode: Camera2Mode,
         cameraCaptureMode: CameraCaptureMode,
         cameraCaptureSubMode: BarItemSubMode?,
         recordingFunctionState: Camera2RecordingState,
         photoFunctionState: Camera2PhotoCaptureState,
         userStorageState: GlobalUserStorageState,
         recordingTime: TimeInterval?,
         remainingRecordTime: TimeInterval?,
         timerModeState: TimerModeState?,
         panoramaModeState: PanoramaModeState?,
         lapseModeState: PhotoLapseState?) {
        super.init(connectionState: connectionState)
        self.cameraMode = cameraMode
        self.cameraCaptureMode = cameraCaptureMode
        self.cameraCaptureSubMode = cameraCaptureSubMode
        self.recordingFunctionState = recordingFunctionState
        self.photoFunctionState = photoFunctionState
        self.userStorageState = userStorageState
        self.recordingTime = recordingTime
        self.remainingRecordTime = remainingRecordTime
        self.timerModeState = timerModeState
        self.panoramaModeState = panoramaModeState
        self.lapseModeState = lapseModeState
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? CameraShutterButtonState else {
            return false
        }
        return super.isEqual(to: other)
            && self.cameraMode == other.cameraMode
            && self.cameraCaptureMode == other.cameraCaptureMode
            && self.cameraCaptureSubMode?.key == other.cameraCaptureSubMode?.key
            && self.recordingFunctionState == other.recordingFunctionState
            && self.photoFunctionState == other.photoFunctionState
            && self.userStorageState == other.userStorageState
            && self.recordingTime == other.recordingTime
            && self.remainingRecordTime == other.remainingRecordTime
            && self.timerModeState == other.timerModeState
            && self.panoramaModeState == other.panoramaModeState
            && self.lapseModeState == other.lapseModeState
    }

    override func copy() -> CameraShutterButtonState {
        let copy = CameraShutterButtonState(connectionState: self.connectionState,
                                            cameraMode: self.cameraMode,
                                            cameraCaptureMode: self.cameraCaptureMode,
                                            cameraCaptureSubMode: self.cameraCaptureSubMode,
                                            recordingFunctionState: self.recordingFunctionState,
                                            photoFunctionState: self.photoFunctionState,
                                            userStorageState: self.userStorageState,
                                            recordingTime: self.recordingTime,
                                            remainingRecordTime: self.remainingRecordTime,
                                            timerModeState: self.timerModeState,
                                            panoramaModeState: self.panoramaModeState,
                                            lapseModeState: self.lapseModeState)
        return copy
    }
}

/// View model for `CameraShutterButton`, notifies on recording/photo capture changes and handles user action.

final class CameraShutterButtonViewModel: DroneStateViewModel<CameraShutterButtonState> {
    // MARK: - Private Properties
    private var cameraRef: Ref<MainCamera2>?
    private var photoCaptureRef: Ref<Camera2PhotoCapture>?
    private var recordingRef: Ref<Camera2Recording>?
    private var cameraCaptureModeViewModel = CameraCaptureModeViewModel()
    private var timerModeViewModel = TimerModeViewModel()
    private var panoramaModeViewModel = PanoramaModeViewModel()
    private var userStorageViewModel = GlobalUserStorageViewModel()
    private var photoLapseModeViewModel = PhotoLapseModeViewModel()
    private var recordingTimeTimer: Timer?
    private var remoteControlButtonGrabber: RemoteControlButtonGrabber?
    private var actionKey: String {
        return NSStringFromClass(type(of: self)) + SkyCtrl3ButtonEvent.rearRightButton.description
    }

    // MARK: - Init
    override init(stateDidUpdate: ((CameraShutterButtonState) -> Void)? = nil) {
        super.init(stateDidUpdate: stateDidUpdate)
        listenCameraCaptureMode()
        listenTimerMode()
        listenPanoramaMode()
        listenUserStorage()
        listenLapseMode()
        remoteControlButtonGrabber = RemoteControlButtonGrabber(button: .rearRightButton,
                                                                event: .rearRightButton,
                                                                key: actionKey,
                                                                action: onRemoteControlGrabUpdate)
    }

    // MARK: - Deinit
    deinit {
        stopRecordingTimeTimer()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)
        listenCamera(drone: drone)
    }

    // MARK: - Internal Funcs
    /// Starts/stops recording or photo capture.
    func startStopCapture() {
        guard let camera = drone?.currentCamera,
            let cameraMode = camera.mode else {
                return
        }

        switch cameraMode {
        case .recording:
            startStopRecording(camera: camera)
        case .photo:
            startStopPhoto(camera: camera)
        }
    }
}

// MARK: - Private Funcs
private extension CameraShutterButtonViewModel {
    /// Starts watcher for camera.
    func listenCamera(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [weak self] camera in
            guard let camera = camera else { return }

            self?.listenPhotoCapture(camera)
            self?.listenRecording(camera)
        }
    }

    /// Starts watcher for photo capture.
    ///
    /// - Parameters:
    ///     - camera: drone camera
    func listenPhotoCapture(_ camera: MainCamera2) {
        photoCaptureRef = camera.getComponent(Camera2Components.photoCapture) { [weak self] photo in
            guard let cameraMode = camera.mode,
                  let photoState = photo?.state else {
                return
            }

            let copy = self?.state.value.copy()
            copy?.cameraMode = cameraMode
            copy?.photoFunctionState = photoState
            self?.state.set(copy)
        }
    }

    /// Starts watcher for camera recording.
    ///
    /// - Parameters:
    ///     - camera: drone camera
    func listenRecording(_ camera: MainCamera2) {
        recordingRef = camera.getComponent(Camera2Components.recording) { [weak self] recording in
            guard let cameraMode = camera.mode,
                  let recordingState = recording?.state else {
                return
            }

            let copy = self?.state.value.copy()
            copy?.cameraMode = cameraMode
            copy?.recordingFunctionState = recordingState

            // Start/stop recording timer.
            switch recordingState {
            case .started(let startTime, _, _) where self?.recordingTimeTimer == nil:
                self?.startRecordingTimeTimer()
                copy?.recordingTime = recordingState.getDuration(startTime: startTime)
            case .stopped where self?.recordingTimeTimer != nil,
                 .stopping(reason: .errorInternal, savedMediaId: nil):
                self?.stopRecordingTimeTimer()
                copy?.recordingTime = nil
            default:
                break
            }
            self?.state.set(copy)
        }
    }

    /// Starts watcher for user storage state.
    func listenUserStorage() {
        userStorageViewModel.state.valueChanged = { [weak self] state in
            self?.updateUserStorageState(state)
        }
        updateUserStorageState(userStorageViewModel.state.value)
    }

    /// Update current user storage state.
    func updateUserStorageState(_ state: GlobalUserStorageState) {
        let copy = self.state.value.copy()
        copy.userStorageState = state
        self.state.set(copy)
    }

    /// Starts watcher for camera capture mode.
    func listenCameraCaptureMode() {
        cameraCaptureModeViewModel.state.valueChanged = { [weak self] state in
            self?.updateCameraCaptureModeState(state)
        }
        updateCameraCaptureModeState(cameraCaptureModeViewModel.state.value)
    }

    /// Update current camera capture mode.
    func updateCameraCaptureModeState(_ state: CameraBarButtonState) {
        if let mode = state.mode as? CameraCaptureMode {
            let copy = self.state.value.copy()
            copy.cameraCaptureMode = mode
            copy.cameraCaptureSubMode = state.subMode
            // Cancel timer if needed.
            if mode != .timer && timerModeViewModel.state.value.inProgress {
                timerModeViewModel.cancelPhotoTimer()
            }
            // Update remote control grab.
            switch mode {
            case .timer, .panorama:
                remoteControlButtonGrabber?.grab()
            default:
                remoteControlButtonGrabber?.ungrab()
            }
            self.state.set(copy)
        }
    }

    /// Starts watcher for timer mode.
    func listenTimerMode() {
        timerModeViewModel.state.valueChanged = { [weak self] state in
            self?.updateTimerModeState(state)
        }
        updateTimerModeState(timerModeViewModel.state.value)
    }

    /// Update current timer mode state.
    ///
    /// - Parameters:
    ///     - state: current timer mode state
    func updateTimerModeState(_ state: TimerModeState) {
        let copy = self.state.value.copy()
        copy.timerModeState = state
        self.state.set(copy)
    }

    /// Starts watcher for panorama mode.
    func listenPanoramaMode() {
        panoramaModeViewModel.state.valueChanged = { [weak self] state in
            self?.updatePanoramaModeState(state)
        }
        updatePanoramaModeState(panoramaModeViewModel.state.value)
    }

    /// Update current panorama mode state.
    ///
    /// - Parameters:
    ///     - state: current panorama mode state
    func updatePanoramaModeState(_ state: PanoramaModeState) {
        let copy = self.state.value.copy()
        copy.panoramaModeState = state
        self.state.set(copy)
    }

    /// Starts watcher for timelapse and gpslapse mode.
    func listenLapseMode() {
        photoLapseModeViewModel.state.valueChanged = { [weak self] state in
            self?.updateLapseModeState(state)
        }
        updateLapseModeState(photoLapseModeViewModel.state.value)
    }

    /// Update current lapse capture mode state.
    ///
    /// - Parameters:
    ///     - state: current photo lapse state
    func updateLapseModeState(_ state: PhotoLapseState) {
        let copy = self.state.value.copy()
        copy.lapseModeState = state
        self.state.set(copy)
    }

    /// Starts timer for recording time.
    func startRecordingTimeTimer() {
        recordingTimeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _ in
            self?.updateRecordingTime()
        })
        recordingTimeTimer?.fire()
    }

    /// Stops timer for recording time.
    func stopRecordingTimeTimer() {
        recordingTimeTimer?.invalidate()
        recordingTimeTimer = nil
    }

    /// Updates `recordingTime` and `remainingRecordTime` values.
    func updateRecordingTime() {
        guard let drone = drone,
              let camera = drone.currentCamera,
              drone.getPeripheral(Peripherals.removableUserStorage) != nil else {
            return
        }
        let copy = self.state.value.copy()

        switch camera.recording?.state {
        case .started(let startTime, _, _):
            copy.recordingTime = camera.recording?.state.getDuration(startTime: startTime)
        default:
            break
        }

        // FIXME: Bitrate is not returned by camera2 for now.
        // copy.remainingRecordTime = StorageUtils.remainingTime(availableSpace: removableUserStorage.availableSpace,
        //                                                       bitrate: Int64(camera.recordingSettings.bitrate))
        self.state.set(copy)
    }

    /// Starts or stops video recording.
    ///
    /// - Parameters:
    ///     - camera: current camera
    func startStopRecording(camera: Camera2) {
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

    /// Starts or stops photo capture.
    ///
    /// - Parameters:
    ///     - camera: current camera
    func startStopPhoto(camera: Camera2) {
        switch state.value.cameraCaptureMode {
        case .timer where state.value.timerModeState?.inProgress == true:
            timerModeViewModel.cancelPhotoTimer()
        case .timer:
            timerModeViewModel.startPhotoTimer()
        case .panorama where state.value.panoramaModeState?.inProgress == true:
            panoramaModeViewModel.cancelPanoramaPhotoCapture()
        case .panorama:
            panoramaModeViewModel.startPanoramaPhotoCapture()
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

    /// Called on remote control grab update.
    ///
    /// - Parameters:
    ///     - newState: new skycontroller event state
    func onRemoteControlGrabUpdate(_ newState: SkyCtrl3ButtonEventState) {
        if newState == .pressed {
            startStopCapture()
        }
    }
}
