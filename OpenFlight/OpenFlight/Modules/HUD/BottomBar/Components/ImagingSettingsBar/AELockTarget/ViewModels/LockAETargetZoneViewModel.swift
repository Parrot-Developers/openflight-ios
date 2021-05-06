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
    fileprivate(set) var isAutoExposureLocked: Bool = false

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - lockAEMode: Camera exposure lock mode.
    ///    - camera: Drone main camera.
    ///    - isAutoExposureLocked: Boolean that indicates if lock Auto exposure is locked.
    init(lockAEMode: Camera2ExposureLockMode?,
         camera: MainCamera2?,
         isAutoExposureLocked: Bool) {
        self.lockAEMode = lockAEMode
        self.camera = camera
        self.isAutoExposureLocked = isAutoExposureLocked
    }

    // MARK: - Internal Funcs
    func isEqual(to other: LockAETargeZoneState) -> Bool {
        return self.lockAEMode == other.lockAEMode
            && self.isAutoExposureLocked == other.isAutoExposureLocked
    }

    /// Returns a copy of the object.
    func copy() -> LockAETargeZoneState {
        let copy = LockAETargeZoneState(lockAEMode: self.lockAEMode,
                                        camera: self.camera,
                                        isAutoExposureLocked: self.isAutoExposureLocked)
        return copy
    }
}

/// ViewModel for LockAE Target zone.
final class LockAETargetZoneViewModel: DroneWatcherViewModel<LockAETargeZoneState> {

    // MARK: - Private Properties
    private var cameraRef: Ref<MainCamera2>?

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        listenCamera(drone: drone)
    }

    /// Unlocks exposure.
    func unlock() {
        guard let camera = drone?.getPeripheral(Peripherals.mainCamera2),
              let exposureLock = camera.getComponent(Camera2Components.exposureLock) else {
            return
        }

        exposureLock.unlock()
        updateCurrentAutoExposure(with: camera)
    }

    /// Locks exposure on current exposure values.
    func lockOnCurrentValues() {
        guard let camera = drone?.getPeripheral(Peripherals.mainCamera2),
              let exposureLock = camera.getComponent(Camera2Components.exposureLock) else {
            return
        }

        exposureLock.lockOnCurrentValues()
        updateCurrentAutoExposure(with: camera)
    }

    /// Locks exposure on region according to selection values in stream screen.
    ///
    /// - Parameters:
    ///   - centerX: horizontal position in the video (relative position, from left (0.0) to right (1.0))
    ///   - centerY: vertical position in the video (relative position, from bottom (0.0) to top (1.0))
    func lockOnRegion(centerX: Double, centerY: Double) {
        guard let camera = drone?.getPeripheral(Peripherals.mainCamera2),
              let exposureLock = camera.getComponent(Camera2Components.exposureLock) else {
            return
        }

        exposureLock.lockOnRegion(centerX: centerX, centerY: centerY)
        updateCurrentAutoExposure(with: camera)
    }
}

// MARK: - Private Funcs
private extension LockAETargetZoneViewModel {
    /// Starts watcher for camera.
    func listenCamera(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [weak self] camera in
            guard let camera = camera else { return }

            self?.updateCurrentAutoExposure(with: camera)
        }

        if let camera = drone.getPeripheral(Peripherals.mainCamera2) {
            updateCurrentAutoExposure(with: camera)
        }
    }

    /// Updates current auto exposure value.
    ///
    /// - Parameters:
    ///     - camera: current camera
    func updateCurrentAutoExposure(with camera: MainCamera2) {
        guard let exposureLockMode = camera.getComponent(Camera2Components.exposureLock)?.mode,
              let exposureSettings = camera.currentEditor[Camera2Params.exposureMode]?.value else {
            return
        }

        let copy = state.value.copy()
        copy.camera = camera
        copy.lockAEMode = exposureLockMode
        copy.isAutoExposureLocked = camera.isHdrOn == false
            && exposureSettings != .manual
            && exposureLockMode != .none
        state.set(copy)
    }
}
