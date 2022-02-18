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

private extension ULogTag {
    static let tag = ULogTag(name: "GpslapseRestartService")
}

/// Gpslapse restart state.
enum GpslapseRestartState {
    /// No restart ongoing.
    case none
    /// The command to stop gpslapse has been sent.
    /// Now we are waiting the command to change camera configuration to be sent.
    case waitConfigApplied
    /// The command to change camera configuration has been sent.
    /// Now we are waiting the gpslapse to be ready to be started.
    /// It can be started when the gpslapse is in stopped state and when drone has acknowledged configuration changes.
    case waitReadyToStart
}

/// Service in charge of restarting gpslapse photo capture when application changes camera configuration.
///
/// When changing some camera configuration parameters related to gpslapse photo capture,
/// if a gpslapse capture is ongoing, it has to be stopped and restarted.
/// Changing the camera configuration and restarting the gpslapse is done with the following steps:
///   1. Send command to stop the gpslapse.
///   2. Send command to change the camera configuration.
///   3. Wait for the drone to indicate that the gpslapse is stopped.
///   4. Wait for the drone to acknowledge camera configuration change.
///   5. Send command to start gpslapse.
public protocol GpslapseRestartService: AnyObject {
}

/// Implementation of `GpslapseRestartService`.
public class GpslapseRestartServiceImpl {

    // MARK: Private properties

    /// Gpslapse restart state.
    private var restartState = GpslapseRestartState.none
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()

    // MARK: init

    /// Constructor.
    ///
    /// - Parameters:
    ///   - connectedDroneHolder: connected drone holder
    ///   - cameraPhotoCaptureService: photo capture service
    ///   - cameraConfigWatcher: camera configuration watcher
    ///   - activeFlightPlanWatcher: active flight plan execution watcher
    public init(connectedDroneHolder: ConnectedDroneHolder,
                cameraPhotoCaptureService: CameraPhotoCaptureService,
                cameraConfigWatcher: CameraConfigWatcher,
                activeFlightPlanWatcher: ActiveFlightPlanExecutionWatcher) {

        // monitor connected drone
        // to reset gpslapse restart process when connected drone changes
        connectedDroneHolder.dronePublisher
            .sink { [unowned self ] _ in
                restartState = .none
            }
            .store(in: &cancellables)

        // monitor camera configuration `willApply` notification
        // to trigger gpslapse restart process if required
        cameraConfigWatcher.willApplyConfigPublisher
            .sink { [unowned self ] editor in
                // check if gpslapse is ongoing
                // and if configuration changes require restarting gpslapse
                guard let camera = connectedDroneHolder.drone?.currentCamera,
                      cameraPhotoCaptureService.state.canStop,
                      camera.config[Camera2Params.mode]?.value == .photo,
                      camera.config[Camera2Params.photoMode]?.value == .gpsLapse,
                      editor[Camera2Params.mode]?.value == .photo,
                      editor[Camera2Params.photoMode]?.value == .gpsLapse,
                      requireRestart(config: camera.config, editor: editor),
                      activeFlightPlanWatcher.activeFlightPlan == nil,
                      restartState == .none
                else { return }

                ULog.i(.tag, "Stop gpslapse capture")

                // stop gpslapse
                camera.photoCapture?.stop()
                // change state to wait for camera configuration to be applied
                restartState = .waitConfigApplied
            }
            .store(in: &cancellables)

        // monitor camera configuration `didApply` notification
        cameraConfigWatcher.didApplyConfigPublisher
            .sink { [unowned self ] success in
                guard restartState == .waitConfigApplied else { return }

                ULog.i(.tag, "Config applied success: \(success)")

                // change state to wait for gpslapse to be ready to be started,
                // or end of gpslapse restart process if failed to apply configuration
                restartState = success ? .waitReadyToStart : .none
            }
            .store(in: &cancellables)

        // monitor photo capture state and camera configuration updating flag
        // to start gpslapse when ready
        cameraPhotoCaptureService.statePublisher
            .combineLatest(cameraConfigWatcher.updatingPublisher)
            .filter { $0.canStart && !$1 }
            .sink { [unowned self ] _ in
                guard let camera = connectedDroneHolder.drone?.currentCamera,
                      restartState == .waitReadyToStart
                else { return }

                // ensure that current capture mode is still gpslapse
                // and no flight plan is being executed
                if camera.config[Camera2Params.mode]?.value == .photo,
                   camera.config[Camera2Params.photoMode]?.value == .gpsLapse,
                   activeFlightPlanWatcher.activeFlightPlan == nil {
                    ULog.i(.tag, "Restart gpslapse capture")
                    // start gpslapse
                    camera.photoCapture?.start()
                } else {
                    ULog.i(.tag, "Do not restart gpslapse capture: not in gpslapse anymore")
                }
                // end of gpslapse restart process
                restartState = .none
            }
            .store(in: &cancellables)
    }
}

// MARK: Private functions
private extension GpslapseRestartServiceImpl {
    /// Tells whether camera configuration changes require restarting the gpslapse.
    ///
    /// - Parameters:
    ///    - config: current camera configuration
    ///    - editor: camera configuration that will be applied
    /// - Returns: `true` if gpslapse should be restarted, `false` otherwise
    func requireRestart(config: Camera2Config, editor: Camera2Editor) -> Bool {
        config[Camera2Params.photoGpslapseInterval]?.value != editor[Camera2Params.photoGpslapseInterval]?.value
        || config[Camera2Params.photoDigitalSignature]?.value != editor[Camera2Params.photoDigitalSignature]?.value
        || config[Camera2Params.photoResolution]?.value != editor[Camera2Params.photoResolution]?.value
        || config[Camera2Params.photoFormat]?.value != editor[Camera2Params.photoFormat]?.value
        || config[Camera2Params.photoFileFormat]?.value != editor[Camera2Params.photoFileFormat]?.value
    }
}

// MARK: GpslapseRestartService protocol conformance
extension GpslapseRestartServiceImpl: GpslapseRestartService {
}
