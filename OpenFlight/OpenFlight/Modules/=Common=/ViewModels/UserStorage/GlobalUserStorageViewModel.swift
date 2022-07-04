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

/// State for `UserStorageViewModel`.
final class GlobalUserStorageState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    /// Current removable user storage physical state.
    fileprivate var removableUserStoragePhysicalState: UserStoragePhysicalState = .available
    /// Current removable user storage file system state.
    fileprivate(set) var removableUserStorageFileSystemState: UserStorageFileSystemState = .ready
    /// Current internal user storage physical state.
    fileprivate var internalUserStoragePhysicalState: UserStoragePhysicalState = .available
    /// Current internal user storage file system state.
    fileprivate(set) var internalUserStorageFileSystemState: UserStorageFileSystemState = .ready
    /// Boolean for insufficient storage space error.
    fileprivate var hasInsufficientStorageSpaceError: Bool = false
    /// Boolean for sd card to slow.
    fileprivate(set) var isUserRemovableStorageTooSlow: Bool = false
    /// Boolean for storage error.
    var hasStorageError: Bool {
        hasInsufficientStorageSpaceError
    }
    /// Icon for shutter button.
    var shutterIcon: UIImage? {
        internalUserStoragePhysicalState.shutterIcon
        ?? internalUserStorageFileSystemState.shutterIcon
    }
    /// Boolean for error state.
    var isErrorState: Bool {
        internalUserStoragePhysicalState.isErrorState
        || internalUserStorageFileSystemState.isErrorState
    }

    // MARK: - Init
    required init() { }

    /// Constructor.
    ///
    /// - Parameters:
    ///    - removableUserStoragePhysicalState: current removable user storage physical state
    ///    - removableUserStorageFileSystemState: current removable user file system storage state
    ///    - internalUserStoragePhysicalState: current internal user storage physical state
    ///    - internalUserStorageFileSystemState: current internal user file system storage state
    ///    - hasInsufficientStorageSpaceError: boolean for insufficient storage space error
    ///    - isUserRemovableStorageTooSlow: boolean for sd card too slow
    init(removableUserStoragePhysicalState: UserStoragePhysicalState,
         removableUserStorageFileSystemState: UserStorageFileSystemState,
         internalUserStoragePhysicalState: UserStoragePhysicalState,
         internalUserStorageFileSystemState: UserStorageFileSystemState,
         hasInsufficientStorageSpaceError: Bool,
         isUserRemovableStorageTooSlow: Bool) {
        self.removableUserStoragePhysicalState = removableUserStoragePhysicalState
        self.removableUserStorageFileSystemState = removableUserStorageFileSystemState
        self.internalUserStoragePhysicalState = internalUserStoragePhysicalState
        self.internalUserStorageFileSystemState = internalUserStorageFileSystemState
        self.hasInsufficientStorageSpaceError = hasInsufficientStorageSpaceError
        self.isUserRemovableStorageTooSlow = isUserRemovableStorageTooSlow
    }

    // MARK: - Equatable
    func isEqual(to other: GlobalUserStorageState) -> Bool {
        removableUserStoragePhysicalState == other.removableUserStoragePhysicalState
        && removableUserStorageFileSystemState == other.removableUserStorageFileSystemState
        && internalUserStoragePhysicalState == other.internalUserStoragePhysicalState
        && internalUserStorageFileSystemState == other.internalUserStorageFileSystemState
        && hasInsufficientStorageSpaceError == other.hasInsufficientStorageSpaceError
        && isUserRemovableStorageTooSlow == other.isUserRemovableStorageTooSlow
    }

    // MARK: - Copying
    func copy() -> GlobalUserStorageState {
        GlobalUserStorageState(removableUserStoragePhysicalState: removableUserStoragePhysicalState,
                               removableUserStorageFileSystemState: removableUserStorageFileSystemState,
                               internalUserStoragePhysicalState: internalUserStoragePhysicalState,
                               internalUserStorageFileSystemState: internalUserStorageFileSystemState,
                               hasInsufficientStorageSpaceError: hasInsufficientStorageSpaceError,
                               isUserRemovableStorageTooSlow: isUserRemovableStorageTooSlow)
    }
}

/// View model for drone's user storage (internal + removable).
final class GlobalUserStorageViewModel: DroneWatcherViewModel<GlobalUserStorageState> {
    // MARK: - Private Properties
    private var cameraRef: Ref<MainCamera2>?
    private var recordingRef: Ref<Camera2Recording>?
    private var captureRef: Ref<Camera2PhotoCapture>?
    private var removableUserStorageRef: Ref<RemovableUserStorage>?
    private var internalUserStorageRef: Ref<InternalUserStorage>?
    private var oldInternalStorageAvailableSpace: Int64?
    private var oldRemovableStorageAvailableSpace: Int64?

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        /// Remove storage errors if a new drone connects.
        removeInsufficientStorageSpaceError()
        listenCamera(drone: drone)
        listenRemovableUserStorage(drone: drone)
        listenInternalUserStorage(drone: drone)
    }
}

// MARK: - Private Funcs
private extension GlobalUserStorageViewModel {
    /// Starts watcher for camera.
    ///
    /// - Parameters:
    ///    - drone: the drone
    func listenCamera(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [unowned self] in
            guard let camera = $0 else { return }

            listenRecording(camera)
            listenCapture(camera)
        }
    }

    /// Starts watcher for camera recording.
    ///
    /// - Parameters:
    ///    - camera: drone camera
    func listenRecording(_ camera: MainCamera2) {
        guard recordingRef?.value == nil else { return }

        recordingRef = camera.getComponent(Camera2Components.recording) { [unowned self] recording in
            guard let recordingState = recording?.state else { return }
            updateRecordingState(recordingState: recordingState)
        }
    }

    /// Starts watcher for camera photo capture.
    ///
    /// - Parameters:
    ///    - camera: drone camera
    func listenCapture(_ camera: MainCamera2) {
        guard captureRef?.value == nil else { return }

        captureRef = camera.getComponent(Camera2Components.photoCapture) { [unowned self] photoCapture in
            guard let photoCaptureState = photoCapture?.state else { return }
            updatePhotoCaptureState(photoCaptureState: photoCaptureState)
        }
    }

    /// Updates storage errors according to recording state.
    ///
    /// - Parameters:
    ///    - recordingState: the camera recording state
    func updateRecordingState(recordingState: Camera2RecordingState) {
        guard case .stopping(let reason, _) = recordingState else { return }

        let copy = state.value.copy()
        switch reason {
        case .errorInsufficientStorageSpace:
            copy.hasInsufficientStorageSpaceError = true
        default:
            return
        }
        state.set(copy)
    }

    /// Updates storage error according to photo capture state.
    ///
    /// - Parameters:
    ///    - recordingState: the photo capture state
    func updatePhotoCaptureState(photoCaptureState: Camera2PhotoCaptureState) {
        guard case .stopping(let reason, _) = photoCaptureState, reason == .errorInsufficientStorageSpace else { return }

        let copy = state.value.copy()
        copy.hasInsufficientStorageSpaceError = true
        state.set(copy)
    }

    /// Starts watcher for removable user storage.
    func listenRemovableUserStorage(drone: Drone) {
        removableUserStorageRef = drone.getPeripheral(Peripherals.removableUserStorage) { [weak self] removableUserStorage in
            guard let removableUserStorage = removableUserStorage,
                  let self = self else {
                return
            }

            let copy = self.state.value.copy()
            copy.removableUserStoragePhysicalState = removableUserStorage.physicalState
            copy.removableUserStorageFileSystemState = removableUserStorage.fileSystemState
            copy.isUserRemovableStorageTooSlow = removableUserStorage.physicalState == .mediaTooSlow
            self.state.set(copy)

            // remove storage space error if space has increased
            if let oldAvailableSpace = self.oldRemovableStorageAvailableSpace,
                removableUserStorage.availableSpace > oldAvailableSpace {
                self.removeInsufficientStorageSpaceError()
            } else if removableUserStorage.physicalState == .noMedia {
                // also remove storage space error if storage was removed
                self.removeInsufficientStorageSpaceError()
            }

            self.oldRemovableStorageAvailableSpace = removableUserStorage.availableSpace
        }
    }

    /// Starts watcher for internal user storage.
    func listenInternalUserStorage(drone: Drone) {
        internalUserStorageRef = drone.getPeripheral(Peripherals.internalUserStorage) { [weak self] internalUserStorage in
            guard let internalUserStorage = internalUserStorage,
                  let self = self else {
                return
            }

            let copy = self.state.value.copy()
            copy.internalUserStoragePhysicalState = internalUserStorage.physicalState
            copy.internalUserStorageFileSystemState = internalUserStorage.fileSystemState
            self.state.set(copy)

            // remove storage space error if space has increased
            if let oldAvailableSpace = self.oldInternalStorageAvailableSpace,
                internalUserStorage.availableSpace > oldAvailableSpace {
                self.removeInsufficientStorageSpaceError()
            }
            self.oldInternalStorageAvailableSpace = internalUserStorage.availableSpace
        }
    }

    /// Removes error for insufficient storage space.
    func removeInsufficientStorageSpaceError() {
        let copy = state.value.copy()
        copy.hasInsufficientStorageSpaceError = false
        state.set(copy)
    }
}
