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
    /// Time before restart record.
    fileprivate(set) var timeBeforeRestartRecord: Int?

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
    ///    - timeBeforeRestartRecord: time before restart record
    init(connectionState: DeviceState.ConnectionState,
         cameraMode: Camera2Mode,
         cameraCaptureMode: CameraCaptureMode,
         cameraCaptureSubMode: BarItemSubMode?,
         photoFunctionState: Camera2PhotoCaptureState,
         userStorageState: GlobalUserStorageState,
         recordingTimeState: RecordingTimeState,
         panoramaModeState: PanoramaModeState?,
         lapseModeState: PhotoLapseState?,
         timeBeforeRestartRecord: Int?) {
        super.init(connectionState: connectionState)

        self.cameraMode = cameraMode
        self.cameraCaptureMode = cameraCaptureMode
        self.cameraCaptureSubMode = cameraCaptureSubMode
        self.photoFunctionState = photoFunctionState
        self.userStorageState = userStorageState
        self.recordingTimeState = recordingTimeState
        self.panoramaModeState = panoramaModeState
        self.lapseModeState = lapseModeState
        self.timeBeforeRestartRecord = timeBeforeRestartRecord
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? CameraShutterButtonState else { return false }

        return super.isEqual(to: other)
            && self.cameraMode == other.cameraMode
            && self.cameraCaptureMode == other.cameraCaptureMode
            && self.cameraCaptureSubMode?.key == other.cameraCaptureSubMode?.key
            && self.photoFunctionState == other.photoFunctionState
            && self.userStorageState == other.userStorageState
            && self.recordingTimeState == other.recordingTimeState
            && self.panoramaModeState == other.panoramaModeState
            && self.lapseModeState == other.lapseModeState
            && self.timeBeforeRestartRecord == other.timeBeforeRestartRecord
    }

    override func copy() -> CameraShutterButtonState {
        let copy = CameraShutterButtonState(connectionState: self.connectionState,
                                            cameraMode: self.cameraMode,
                                            cameraCaptureMode: self.cameraCaptureMode,
                                            cameraCaptureSubMode: self.cameraCaptureSubMode,
                                            photoFunctionState: self.photoFunctionState,
                                            userStorageState: self.userStorageState,
                                            recordingTimeState: self.recordingTimeState,
                                            panoramaModeState: self.panoramaModeState,
                                            lapseModeState: self.lapseModeState,
                                            timeBeforeRestartRecord: self.timeBeforeRestartRecord)
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
    private var recordingRef: Ref<Camera2Recording>?
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
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [weak self] camera in
            guard let camera = camera,
                  let cameraMode = camera.mode else {
                return
            }

            self?.listenPhotoCapture(camera)
            self?.listenCameraConfiguration(camera)
            let copy = self?.state.value.copy()
            copy?.cameraMode = cameraMode
            self?.state.set(copy)
        }
    }

    /// Starts watcher for camera configuration.
    func listenCameraConfiguration(_ camera: MainCamera2) {
        recordingRef = camera.getComponent(Camera2Components.recording) { [weak self] recording in
            guard let recordingState = recording?.state else { return }

            let copy = self?.state.value.copy()
            // Reset timer before restart record
            if case .stopping(reason: .configurationChange, _) = recordingState {
                copy?.timeBeforeRestartRecord = Constants.timerBeforeRestartRecord
            }

            self?.state.set(copy)
            // Prevents for multiple copy call
            if self?.state.value.timeBeforeRestartRecord != nil,
               case .stopping(reason: .configurationChange, _) = recordingState {
                self?.restartRecording()
            }
        }
    }

    /// Restart recording when camera configuration changes.
    func restartRecording() {
        countDownTimer = Timer.scheduledTimer(withTimeInterval: Constants.countDownInterval, repeats: true) { [weak self] _ in
            if let countDown = self?.state.value.timeBeforeRestartRecord {
                let interval = Int(Constants.countDownInterval)
                if countDown > interval {
                    let copy = self?.state.value.copy()
                    copy?.timeBeforeRestartRecord = countDown - interval
                    self?.state.set(copy)
                } else {
                    self?.cancelRestartRecording()
                    self?.recordingRef?.value?.start()
                }
            }
        }
    }

    /// Cancels previously restart recording.
    func cancelRestartRecording() {
        countDownTimer?.invalidate()
        countDownTimer = nil
        let copy = self.state.value.copy()
        copy.timeBeforeRestartRecord = nil
        self.state.set(copy)
    }

    /// Starts watcher for photo capture.
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
    ///    - state: current recording time state
    func updateRecordingTimeState(_ state: RecordingTimeState) {
        let copy = self.state.value.copy()
        copy.recordingTimeState = state
        self.state.set(copy)
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

    /// Update current panorama mode state.
    ///
    /// - Parameters:
    ///     - state: current panorama mode state
    func updatePanoramaModeState(_ state: PanoramaModeState) {
        let copy = self.state.value.copy()
        copy.panoramaModeState = state
        self.state.set(copy)
    }

    /// Update current user storage state.
    ///
    /// - Parameters:
    ///     - state: current global user storage state
    func updateUserStorageState(_ state: GlobalUserStorageState) {
        let copy = self.state.value.copy()
        copy.userStorageState = state
        self.state.set(copy)
    }

    /// Update current camera capture mode.
    ///
    /// - Parameters:
    ///     - state: current bar button state
    func updateCameraCaptureModeState(_ state: CameraBarButtonState) {
        if let mode = state.mode as? CameraCaptureMode {
            let copy = self.state.value.copy()
            copy.cameraCaptureMode = mode
            copy.cameraCaptureSubMode = state.subMode
            self.state.set(copy)
        }
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
