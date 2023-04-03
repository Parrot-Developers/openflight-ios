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

import Foundation
import GroundSdk
import Combine

private extension ULogTag {
    static let tag = ULogTag(name: "ExposureLock")
}

/// Output of `ExposureLockService`: exposes exposure lock state.
public enum ExposureLockState: Equatable {
    /// Exposure lock is not available.
    case unavailable
    /// Exposure is unlocked.
    case unlocked
    /// Exposure lock on current values request has been sent to drone.
    /// We are waiting for confirmation from drone.
    case lockingOnCurrentValues
    /// Exposure lock on region request has been sent to drone.
    /// We are waiting for confirmation from drone.
    case lockingOnRegion(centerX: Double, centerY: Double)
    /// Exposure is locked on current exposure values.
    case lockedOnCurrentValues
    /// Exposure is locked on a region.
    case lockOnRegion

    /// Whether an exposure lock request has been sent to drone and we are waiting for confirmation.
    var locking: Bool {
        switch self {
        case .lockingOnCurrentValues,
             .lockingOnRegion:
            return true
        default:
            return false
        }
    }

    /// Whether exposure is locked.
    var locked: Bool {
        switch self {
        case .lockedOnCurrentValues,
             .lockOnRegion:
            return true
        default:
            return false
        }
    }
}

/// Output of `ExposureLockService`: exposes exposure lock region.
public struct ExposureLockRegion: Equatable {
    /// Region horizontal center in frame, in linear range [0, 1], where 0 is the left of the frame.
    let centerX: Double
    /// Region vertical center in frame, in linear range [0, 1], where 0 is the bottom of the frame.
    let centerY: Double
    /// Region width, in linear range [0, 1], where 1 represents the full frame width.
    let width: Double
    /// Region height, in linear range [0, 1], where 1 represents the full frame height.
    let height: Double
}

/// Exposure lock service.
public protocol ExposureLockService: AnyObject {
    /// Publisher for exposure lock state.
    var statePublisher: AnyPublisher<ExposureLockState, Never> { get }

    /// Exposure lock state.
    var stateValue: ExposureLockState { get }

    /// Publisher for exposure lock region.
    var lockRegionPublisher: AnyPublisher<ExposureLockRegion?, Never> { get }

    /// Exposure lock region.
    var lockRegionValue: ExposureLockRegion? { get }

    /// Unlocks exposure.
    func unlock()

    /// Locks exposure on current exposure values.
    func lock()

    /// Locks or unlocks exposure, depending on current state.
    func toggleExposureLock()

    /// Locks exposure on a region.
    ///
    /// - Parameters:
    ///   - centerX: horizontal position in the video (relative position, from left (0.0) to right (1.0))
    ///   - centerY: vertical position in the video (relative position, from bottom (0.0) to top (1.0))
    func lockOnRegion(centerX: Double, centerY: Double)
}

/// Implementation of `ExposureLockService`.
public class ExposureLockServiceImpl {

    // MARK: - Private Enums
    private enum Constants {
        /// Locking state timeout in seconds
        static let lockingTimeout = 5
    }

    // MARK: Private properties

    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// Locking state timeout, see `setupLockingTimeout().`
    private var lockingTimeout: AnyCancellable?
    /// Reference to camera peripheral.
    private var cameraRef: Ref<MainCamera2>?
    /// Reference to exposure lock component.
    private var exposureLockRef: Ref<Camera2ExposureLock>?
    /// Reference to exposure indicator component.
    private var exposureIndicatorRef: Ref<Camera2ExposureIndicator>?
    /// Exposure lock state.
    private var stateSubject = CurrentValueSubject<ExposureLockState, Never>(.unavailable)
    /// Exposure lock region.
    private var lockRegionSubject = CurrentValueSubject<ExposureLockRegion?, Never>(nil)

    // MARK: init

    /// Constructor.
    ///
    /// - Parameters:
    ///   - currentDroneHolder: drone holder
    public init(currentDroneHolder: CurrentDroneHolder) {
        // setup locking state timeout
        setupLockingTimeout()
        // listen to drone changes
        listen(dronePublisher: currentDroneHolder.dronePublisher)
    }
}

// MARK: Private functions
private extension ExposureLockServiceImpl {

    /// Listens for the current drone.
    ///
    /// - Parameter dronePublisher: the drone publisher
    func listen(dronePublisher: AnyPublisher<Drone, Never>) {
        dronePublisher.sink { [unowned self] drone in
            listenCamera(drone: drone)
        }
        .store(in: &cancellables)
    }

    /// Listens the drone's camera peripheral.
    ///
    /// - Parameter drone: drone to monitor
    func listenCamera(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [unowned self] camera in
            if let camera = camera {
                // register exposure lock listener when current component is nil,
                // in order to react to a drone or camera change
                if exposureLockRef?.value == nil {
                    listenExposureLock(camera: camera)
                }
                // register exposure indicator listener when current component is nil,
                // in order to react to a drone or camera change
                if exposureIndicatorRef?.value == nil {
                    listenExposureIndicator(camera: camera)
                }
            }
        }
    }

    /// Listens the camera peripheral's exposure lock component.
    ///
    /// - Parameter camera: camera to monitor
    func listenExposureLock(camera: MainCamera2) {
        exposureLockRef = camera.getComponent(Camera2Components.exposureLock) { [unowned self] exposureLock in
            if let exposureLock = exposureLock {
                if exposureLock.supportedModes == [.none] {
                    stateSubject.value = .unavailable
                } else if !exposureLock.updating {
                    switch (stateSubject.value, exposureLock.mode) {
                    case (.lockingOnCurrentValues, .none),
                         (.lockingOnRegion, .none):
                        /// when drone receives a locking request, it first sends '.none' state,
                        /// we ignore this transitional state
                        break
                    case (_, .none):
                        stateSubject.value = .unlocked
                    case (_, .currentValues):
                        stateSubject.value = .lockedOnCurrentValues
                    case (_, .region):
                        stateSubject.value = .lockOnRegion
                    }
                }
            } else {
                stateSubject.value = .unavailable
            }
        }
    }

    /// Listens the camera peripheral's exposure indicator component.
    ///
    /// - Parameter camera: camera to monitor
    func listenExposureIndicator(camera: MainCamera2) {
        exposureIndicatorRef = camera.getComponent(Camera2Components.exposureIndicator) { [unowned self] indicator in
            if let lockRegion = indicator?.lockRegion {
                lockRegionSubject.value = ExposureLockRegion(centerX: lockRegion.centerX,
                                                             centerY: lockRegion.centerY,
                                                             width: lockRegion.width,
                                                             height: lockRegion.height)
            } else {
                lockRegionSubject.value = nil
            }
        }
    }

    /// Setups locking state timeout.
    ///
    /// When the drone receives a locking request, it first sends a state indicating that the exposure is unlocked.
    /// Once the exposure is locked, the drone sends a state indicating that the exposure is locked.
    /// We ignore this "unlocked" transitional state, and we remain in "locking" state.
    /// This timeout ensures that state is not stalled in `.lockingOnCurrentValues` or `lockingOnRegion`,
    /// if the exposure lock request fails.
    func setupLockingTimeout() {
        stateSubject.sink { [unowned self] state in
            if state.locking {
                startLockingTimeout()
            } else {
                cancelLockingTimeout()
            }
        }
        .store(in: &cancellables)
    }

    /// Starts locking timeout.
    ///
    /// At timeout, the state is updated with the current state of exposure lock camera component.
    func startLockingTimeout() {
        lockingTimeout = Just(true)
            .delay(for: .seconds(Constants.lockingTimeout), scheduler: DispatchQueue.main)
            .sink { [unowned self] _ in
                if stateSubject.value.locking {
                    switch exposureLockRef?.value?.mode {
                    case .currentValues:
                        stateSubject.value = .lockedOnCurrentValues
                    case .region:
                        stateSubject.value = .lockOnRegion
                    case .some(.none):
                        stateSubject.value = .unlocked
                    case nil:
                        stateSubject.value = .unavailable
                    }
                }
            }
    }

    /// Cancels locking timeout.
    func cancelLockingTimeout() {
        lockingTimeout?.cancel()
        lockingTimeout = nil
    }
}

// MARK: ExposureLockService protocol conformance
extension ExposureLockServiceImpl: ExposureLockService {

    public var statePublisher: AnyPublisher<ExposureLockState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    public var stateValue: ExposureLockState {
        stateSubject.value
    }

    public var lockRegionPublisher: AnyPublisher<ExposureLockRegion?, Never> {
        lockRegionSubject.removeDuplicates()
            .eraseToAnyPublisher()
    }

    public var lockRegionValue: ExposureLockRegion? {
        lockRegionSubject.value
    }

    public func unlock() {
        exposureLockRef?.value?.unlock()
    }

    public func lock() {
        if let exposureLock = exposureLockRef?.value {
            stateSubject.value = .lockingOnCurrentValues
            exposureLock.lockOnCurrentValues()
        }
    }

    public func toggleExposureLock() {
        switch stateSubject.value {
        case .unlocked:
            lock()
        case .lockedOnCurrentValues, .lockOnRegion:
            unlock()
        default:
            // do nothing
            break
        }
    }

    public func lockOnRegion(centerX: Double, centerY: Double) {
        if let exposureLock = exposureLockRef?.value {
            stateSubject.value = .lockingOnRegion(centerX: centerX, centerY: centerY)
            exposureLock.lockOnRegion(centerX: centerX, centerY: centerY)
        }
    }
}
