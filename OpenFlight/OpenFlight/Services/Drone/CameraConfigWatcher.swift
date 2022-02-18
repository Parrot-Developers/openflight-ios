//    Copyright (C) 2022 Parrot Drones SAS
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

/// Drone camera configuration changes watcher.
public protocol CameraConfigWatcher: AnyObject {
    /// Publisher notifying that a camera configuration will be applied.
    var willApplyConfigPublisher: AnyPublisher<Camera2Editor, Never> { get }

    /// Publisher notifying that a camera configuration has been applied.
    var didApplyConfigPublisher: AnyPublisher<Bool, Never> { get }

    /// Publisher telling whether camera configuration is updating.
    var updatingPublisher: AnyPublisher<Bool, Never> { get }

    /// Notifies `CameraConfigWatcher` when a camera configuration will be applied.
    ///
    /// - Parameters:
    ///    - config: configuration editor holding parameters that will be applied
    func willApplyConfig(config: Camera2Editor)

    /// Notifies `CameraConfigWatcher` when a camera configuration has been applied.
    ///
    /// - Parameters:
    ///    - success: `true` if configuration was applied, `false` otherwise
    func didApplyConfig(success: Bool)
}

/// Implementation of `CameraConfigWatcher`.
public class CameraConfigWatcherImpl {

    // MARK: Private properties

    /// Reference to camera peripheral.
    private var cameraRef: Ref<MainCamera2>?
    /// Subject notifying that a camera configuration will be applied.
    private var willApplyConfigSubject = PassthroughSubject<Camera2Editor, Never>()
    /// Subject notifying that a camera configuration has been applied.
    private var didApplyConfigSubject = PassthroughSubject<Bool, Never>()
    /// Subject telling whether camera configuration is updating.
    private var updatingSubject = CurrentValueSubject<Bool, Never>(false)
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()

    // MARK: init

    /// Constructor.
    ///
    /// - Parameters:
    ///   - currentDroneHolder: drone holder
    public init(currentDroneHolder: CurrentDroneHolder) {
        // listen to drone changes
        listen(dronePublisher: currentDroneHolder.dronePublisher)
    }
}

// MARK: Private functions
private extension CameraConfigWatcherImpl {

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
            updatingSubject.value = camera?.config.updating == true
        }
    }
}

// MARK: CameraConfigWatcher protocol conformance
extension CameraConfigWatcherImpl: CameraConfigWatcher {
    public var willApplyConfigPublisher: AnyPublisher<Camera2Editor, Never> {
        willApplyConfigSubject.eraseToAnyPublisher()
    }

    public var didApplyConfigPublisher: AnyPublisher<Bool, Never> {
        didApplyConfigSubject.eraseToAnyPublisher()
    }

    public var updatingPublisher: AnyPublisher<Bool, Never> {
        updatingSubject.eraseToAnyPublisher()
    }

    public func willApplyConfig(config: Camera2Editor) {
        willApplyConfigSubject.send(config)
    }

    public func didApplyConfig(success: Bool) {
        didApplyConfigSubject.send(success)
    }
}
