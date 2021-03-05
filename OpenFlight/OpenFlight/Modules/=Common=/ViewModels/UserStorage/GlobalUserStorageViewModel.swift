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

/// State for `UserStorageViewModel`.

final class GlobalUserStorageState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    /// Current removable user storage physical state.
    fileprivate(set) var removableUserStoragePhysicalState: UserStoragePhysicalState = .available
    /// Current removable user storage file system state.
    fileprivate(set) var removableUserStorageFileSystemState: UserStorageFileSystemState = .ready
    /// Current internal user storage physical state.
    fileprivate(set) var internalUserStoragePhysicalState: UserStoragePhysicalState = .available
    /// Current internal user storage file system state.
    fileprivate(set) var internalUserStorageFileSystemState: UserStorageFileSystemState = .ready
    /// Boolean for insufficient storage space error.
    fileprivate(set) var hasInsufficientStorageSpaceError: Bool = false
    /// Boolean for insufficient storage speed error.
    fileprivate(set) var hasInsufficientStorageSpeedError: Bool = false
    /// Boolean for storage error.
    var hasStorageError: Bool {
        return hasInsufficientStorageSpaceError || hasInsufficientStorageSpeedError
    }
    /// Icon for shutter button.
    var shutterIcon: UIImage? {
        return internalUserStoragePhysicalState.shutterIcon
            ?? internalUserStorageFileSystemState.shutterIcon
    }
    /// Boolean for error state.
    var isErrorState: Bool {
        return internalUserStoragePhysicalState.isErrorState
            || internalUserStorageFileSystemState.isErrorState
    }

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - removableUserStoragePhysicalState: current removable user storage physical state
    ///    - removableUserStorageFileSystemState: current removable user file system storage state
    ///    - internalUserStoragePhysicalState: current internal user storage physical state
    ///    - internalUserStorageFileSystemState: current internal user file system storage state
    ///    - hasInsufficientStorageSpaceError: boolean for insufficient storage space error
    ///    - hasInsufficientStorageSpeedError: boolean for insufficient storage speed error
    init(removableUserStoragePhysicalState: UserStoragePhysicalState,
         removableUserStorageFileSystemState: UserStorageFileSystemState,
         internalUserStoragePhysicalState: UserStoragePhysicalState,
         internalUserStorageFileSystemState: UserStorageFileSystemState,
         hasInsufficientStorageSpaceError: Bool,
         hasInsufficientStorageSpeedError: Bool) {
        self.removableUserStoragePhysicalState = removableUserStoragePhysicalState
        self.removableUserStorageFileSystemState = removableUserStorageFileSystemState
        self.internalUserStoragePhysicalState = internalUserStoragePhysicalState
        self.internalUserStorageFileSystemState = internalUserStorageFileSystemState
        self.hasInsufficientStorageSpaceError = hasInsufficientStorageSpaceError
        self.hasInsufficientStorageSpeedError = hasInsufficientStorageSpeedError
    }

    // MARK: - Equatable
    func isEqual(to other: GlobalUserStorageState) -> Bool {
        return self.removableUserStoragePhysicalState == other.removableUserStoragePhysicalState
            && self.removableUserStorageFileSystemState == other.removableUserStorageFileSystemState
            && self.internalUserStoragePhysicalState == other.internalUserStoragePhysicalState
            && self.internalUserStorageFileSystemState == other.internalUserStorageFileSystemState
            && self.hasInsufficientStorageSpaceError == other.hasInsufficientStorageSpaceError
            && self.hasInsufficientStorageSpeedError == other.hasInsufficientStorageSpeedError
    }

    // MARK: - Copying
    func copy() -> GlobalUserStorageState {
        return GlobalUserStorageState(removableUserStoragePhysicalState: self.removableUserStoragePhysicalState,
                                      removableUserStorageFileSystemState: self.removableUserStorageFileSystemState,
                                      internalUserStoragePhysicalState: self.internalUserStoragePhysicalState,
                                      internalUserStorageFileSystemState: self.internalUserStorageFileSystemState,
                                      hasInsufficientStorageSpaceError: self.hasInsufficientStorageSpaceError,
                                      hasInsufficientStorageSpeedError: self.hasInsufficientStorageSpeedError)
    }
}

/// View model for drone's user storage (internal + removable).

final class GlobalUserStorageViewModel: DroneWatcherViewModel<GlobalUserStorageState> {
    // MARK: - Private Properties
    private var cameraRef: Ref<MainCamera2>?
    private var removableUserStorageRef: Ref<RemovableUserStorage>?
    private var internalUserStorageRef: Ref<InternalUserStorage>?
    private var oldInternalStorageAvailableSpace: Int64?
    private var oldRemovableStorageAvailableSpace: Int64?

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        /// Remove storage errors if a new drone connects.
        removeInsufficientStorageSpaceError()
        removeInsufficientStorageSpeedError()
        listenCamera(drone: drone)
        listenRemovableUserStorage(drone: drone)
        listenInternalUserStorage(drone: drone)
    }

    // MARK: - Deinit
    deinit {
        cameraRef = nil
        removableUserStorageRef = nil
        internalUserStorageRef = nil
    }
}

// MARK: - Private Funcs
private extension GlobalUserStorageViewModel {
    /// Starts watcher for camera.
    func listenCamera(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [weak self] camera in
            guard let camera = camera,
                let copy = self?.state.value.copy() else {
                    return
            }

            // Handles insufficient storage space/speed error.
            if let recordingState = camera.recording?.state {
                switch recordingState {
                case .stopping(let reason, _):
                    switch reason {
                    case .errorInsufficientStorageSpeed:
                        copy.hasInsufficientStorageSpeedError = true
                    case .errorInsufficientStorageSpace:
                        copy.hasInsufficientStorageSpaceError = true
                    default:
                        break
                    }
                default:
                    break
                }
            }

            if let photoCaptureState = camera.photoCapture?.state {
                switch photoCaptureState {
                case .stopping(let reason, _) where reason == .errorInsufficientStorageSpace:
                    copy.hasInsufficientStorageSpaceError = true
                default:
                    break
                }
            }

            // Updates state.
            self?.state.set(copy)
        }
    }

    /// Starts watcher for removable user storage.
    func listenRemovableUserStorage(drone: Drone) {
        removableUserStorageRef = drone.getPeripheral(Peripherals.removableUserStorage) { [weak self] removableUserStorage in
            guard let removableUserStorage = removableUserStorage,
                  let strongSelf = self else {
                return
            }

            let copy = strongSelf.state.value.copy()
            copy.removableUserStoragePhysicalState = removableUserStorage.physicalState
            copy.removableUserStorageFileSystemState = removableUserStorage.fileSystemState
            strongSelf.state.set(copy)

            // Remove storage space error if space has increased.
            if let oldAvailableSpace = strongSelf.oldRemovableStorageAvailableSpace,
                removableUserStorage.availableSpace > oldAvailableSpace {
                strongSelf.removeInsufficientStorageSpaceError()
            }
            strongSelf.oldRemovableStorageAvailableSpace = removableUserStorage.availableSpace
        }
    }

    /// Starts watcher for internal user storage.
    func listenInternalUserStorage(drone: Drone) {
        internalUserStorageRef = drone.getPeripheral(Peripherals.internalUserStorage) { [weak self] internalUserStorage in
            guard let internalUserStorage = internalUserStorage,
                  let strongSelf = self else {
                return
            }

            let copy = strongSelf.state.value.copy()
            copy.internalUserStoragePhysicalState = internalUserStorage.physicalState
            copy.internalUserStorageFileSystemState = internalUserStorage.fileSystemState
            strongSelf.state.set(copy)

            // Remove storage space error if space has increased.
            if let oldAvailableSpace = strongSelf.oldInternalStorageAvailableSpace,
                internalUserStorage.availableSpace > oldAvailableSpace {
                strongSelf.removeInsufficientStorageSpaceError()
            }
            strongSelf.oldInternalStorageAvailableSpace = internalUserStorage.availableSpace
        }
    }

    /// Removes error for insufficient storage space.
    func removeInsufficientStorageSpaceError() {
        let copy = self.state.value.copy()
        copy.hasInsufficientStorageSpaceError = false
        self.state.set(copy)
    }

    /// Removes error for insufficient sotrage speed.
    func removeInsufficientStorageSpeedError() {
        let copy = self.state.value.copy()
        copy.hasInsufficientStorageSpeedError = false
        self.state.set(copy)
    }
}
