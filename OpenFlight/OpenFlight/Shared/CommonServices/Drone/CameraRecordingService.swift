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
    static let tag = ULogTag(name: "CameraRecordingService")
}

/// Drone camera recording service.
public protocol CameraRecordingService: AnyObject {
    /// Publisher for recording state.
    var statePublisher: AnyPublisher<Camera2RecordingState, Never> { get }
    /// Current recording state
    var state: Camera2RecordingState { get }
}

/// Implementation of `CameraRecordingService`.
public class CameraRecordingServiceImpl {

    // MARK: Private properties

    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// Reference to camera peripheral.
    private var cameraRef: Ref<MainCamera2>?
    /// Reference to camera recording.
    private var recordingRef: Ref<Camera2Recording>?
    /// RecordingState.
    private var stateSubject = CurrentValueSubject<Camera2RecordingState, Never>(.stopped(latestSavedMediaId: nil))

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
private extension CameraRecordingServiceImpl {

    /// Listens for the current drone.
    ///
    /// - Parameter dronePublisher: the drone publisher
    func listen(dronePublisher: AnyPublisher<Drone, Never>) {
        dronePublisher.sink { [unowned self] in
            listenCamera(drone: $0)
        }
        .store(in: &cancellables)
    }

    /// Starts watcher for camera.
    ///
    /// - Parameters:
    ///     - drone: the drone.
    func listenCamera(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [unowned self] in
            guard let camera = $0 else { return }

            listenRecording(camera)
        }
    }

    /// Starts watcher for camera recording.
    ///
    /// - Parameters:
    ///     - camera: drone camera
    func listenRecording(_ camera: MainCamera2) {
        guard recordingRef?.value == nil else { return }

        recordingRef = camera.getComponent(Camera2Components.recording) { [unowned self] recording in
            guard let recordingState = recording?.state else { return }

            stateSubject.value = recordingState
        }
    }
}

// MARK: CameraRecordingService protocol conformance
extension CameraRecordingServiceImpl: CameraRecordingService {

    public var statePublisher: AnyPublisher<Camera2RecordingState, Never> { stateSubject.eraseToAnyPublisher() }

    public var state: Camera2RecordingState { stateSubject.value }

}
