//    Copyright (C) 2021 Parrot Drones SAS
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

/// State for `RecordingTimeViewModel`.
final class RecordingTimeState: ViewModelState, EquatableState, Copying {
    /// Current recording function state.
    fileprivate(set) var functionState: Camera2RecordingState = .stopped(latestSavedMediaId: nil)
    /// Current recording time.
    fileprivate(set) var recordingTime: TimeInterval?
    /// Remaining record time.
    fileprivate(set) var remainingRecordTime: TimeInterval?

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - functionState: current recording function state
    ///    - recordingTime: current recording time
    ///    - remainingRecordTime: remaining record time
    init(functionState: Camera2RecordingState,
         recordingTime: TimeInterval?,
         remainingRecordTime: TimeInterval?) {
        self.functionState = functionState
        self.recordingTime = recordingTime
        self.remainingRecordTime = remainingRecordTime
    }

    // MARK: - EquatableState
    func isEqual(to other: RecordingTimeState) -> Bool {
        return self.functionState == other.functionState
            && self.recordingTime == other.recordingTime
            && self.remainingRecordTime == other.remainingRecordTime
    }

    // MARK: - Copying
    func copy() -> RecordingTimeState {
        return RecordingTimeState(functionState: self.functionState,
                                  recordingTime: self.recordingTime,
                                  remainingRecordTime: self.remainingRecordTime)
    }
}

/// View model that notifies on recording time changes.
final class RecordingTimeViewModel: DroneWatcherViewModel<RecordingTimeState> {
    // MARK: - Private Properties
    private var cameraRef: Ref<MainCamera2>?
    private var recordingRef: Ref<Camera2Recording>?
    private var recordingTimeTimer: Timer?

    // MARK: - Deinit
    deinit {
        stopRecordingTimeTimer()
    }
    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        listenCamera(drone: drone)
    }
}

// MARK: - Private Funcs
private extension RecordingTimeViewModel {
    /// Starts watcher for camera.
    func listenCamera(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [weak self] camera in
            guard let camera = camera else { return }

            self?.listenRecording(camera)
        }
    }

    /// Starts watcher for camera recording.
    ///
    /// - Parameters:
    ///     - camera: drone camera
    func listenRecording(_ camera: MainCamera2) {
        recordingRef = camera.getComponent(Camera2Components.recording) { [weak self] recording in
            guard let recordingState = recording?.state else {
                return
            }

            let copy = self?.state.value.copy()
            copy?.functionState = recordingState

            // Start/stop recording timer.
            switch recordingState {
            case .started(let startTime, _, _) where self?.recordingTimeTimer == nil:
                self?.startRecordingTimeTimer()
                copy?.recordingTime = recordingState.getDuration(startTime: startTime)
            case .stopped where self?.recordingTimeTimer != nil,
                 .stopping(reason: .errorInternal, savedMediaId: nil):
                self?.stopRecordingTimeTimer()
                copy?.recordingTime = nil
                copy?.remainingRecordTime = nil
            default:
                break
            }
            self?.state.set(copy)
        }
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
              let camera = drone.currentCamera else {
            return
        }

        let copy = state.value.copy()

        switch camera.recording?.state {
        case .started(let startTime, let bitrate, let mediaStorage):
            copy.recordingTime = camera.recording?.state.getDuration(startTime: startTime)
            if let mediaStorage = mediaStorage {
                let availableStorageSpace = drone.availableStorageSpace(mediaStorage: mediaStorage)
                copy.remainingRecordTime = StorageUtils.remainingTime(availableSpace: availableStorageSpace,
                                                                      bitrate: Int64(bitrate))
            } else {
                copy.remainingRecordTime = nil
            }
        default:
            break
        }

        state.set(copy)
    }
}
