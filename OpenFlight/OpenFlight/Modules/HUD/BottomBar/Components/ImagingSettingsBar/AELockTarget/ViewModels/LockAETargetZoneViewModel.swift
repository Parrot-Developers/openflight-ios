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

/// State for `LockAETargetZoneViewModel`.
final class LockAETargeZoneState: ViewModelState, EquatableState, Copying {

    // MARK: - Internal Properties
    fileprivate(set) var lockAEMode: Camera2ExposureLockMode?
    fileprivate(set) var camera: MainCamera2?
    fileprivate(set) var isLockAeEnabled: Bool = false

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - lockAEMode: Camera exposure lock mode.
    ///    - camera: Drone main camera.
    ///    - isLockAeEnabled: Bool that indicates if lockAE is enabled.
    init(lockAEMode: Camera2ExposureLockMode?,
         camera: MainCamera2?,
         isLockAeEnabled: Bool) {
        self.lockAEMode = lockAEMode
        self.camera = camera
        self.isLockAeEnabled = isLockAeEnabled
    }

    // MARK: - Internal Funcs
    func isEqual(to other: LockAETargeZoneState) -> Bool {
        return self.lockAEMode == other.lockAEMode
            && self.isLockAeEnabled == other.isLockAeEnabled
    }

    /// Returns a copy of the object.
    func copy() -> LockAETargeZoneState {
        let copy = LockAETargeZoneState(lockAEMode: self.lockAEMode,
                                        camera: self.camera,
                                        isLockAeEnabled: self.isLockAeEnabled)
        return copy
    }
}

/// ViewModel for calibration.
final class LockAETargetZoneViewModel: DroneWatcherViewModel<LockAETargeZoneState> {

    // MARK: - Private Properties
    private var cameraRef: Ref<MainCamera2>?

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        listenCamera(drone: drone)
    }

    /// Unlocks exposure.
    func unlock() {
        guard let exposureLock = drone?.getPeripheral(Peripherals.mainCamera2)?.getComponent(Camera2Components.exposureLock) else {
            return
        }

        exposureLock.unlock()
    }

    /// Locks exposure on current exposure values.
    func lockOnCurrentValues() {
        guard let exposureLock = drone?.getPeripheral(Peripherals.mainCamera2)?.getComponent(Camera2Components.exposureLock) else {
            return
        }

        exposureLock.lockOnCurrentValues()
    }
}

// MARK: - Private Funcs
private extension LockAETargetZoneViewModel {
    /// Starts watcher for camera.
    func listenCamera(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [weak self] camera in
            guard let exposureLockMode = camera?.getComponent(Camera2Components.exposureLock)?.mode,
                  let exposureSettings = camera?.currentEditor[Camera2Params.exposureMode]?.value,
                  camera?.getComponent(Camera2Components.exposureLock)?.updating == false,
                  let copy = self?.state.value.copy() else {
                return
            }

            copy.camera = camera
            copy.lockAEMode = exposureLockMode
            copy.isLockAeEnabled = camera?.isHdrOn == false && exposureSettings != .manual
            self?.state.set(copy)
        }
    }
}
