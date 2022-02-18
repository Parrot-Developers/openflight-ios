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
    static let tag = ULogTag(name: "Exposure")
}

/// Exposure service.
public protocol ExposureService: AnyObject {
    /// Publisher for exposure mode.
    var modePublisher: AnyPublisher<Camera2ExposureMode, Never> { get }
}

/// Implementation of `ExposureService`.
public class ExposureServiceImpl {

    // MARK: Private properties

    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// Reference to camera peripheral.
    private var cameraRef: Ref<MainCamera2>?
    /// Exposure mode.
    private var modeSubject = CurrentValueSubject<Camera2ExposureMode, Never>(.automatic)

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
private extension ExposureServiceImpl {

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
            guard let camera = camera else { return }

            modeSubject.value = camera.config[Camera2Params.exposureMode]?.value ?? .automatic
        }
    }
}

// MARK: ExposureService protocol conformance
extension ExposureServiceImpl: ExposureService {

    public var modePublisher: AnyPublisher<Camera2ExposureMode, Never> { modeSubject.eraseToAnyPublisher() }
}
