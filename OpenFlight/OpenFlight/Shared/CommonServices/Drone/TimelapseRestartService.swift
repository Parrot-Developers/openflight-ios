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
    static let tag = ULogTag(name: "TimelapseRestartService")
}

/// Timelapse restart state.
enum TimelapseRestartState {
    /// No restart ongoing.
    case none
    /// The command to stop timelapse has been sent.
    /// Now we are waiting the command to change camera configuration to be sent.
    case waitConfigApplied
    /// The command to change camera configuration has been sent.
    /// Now we are waiting the timelapse to be ready to be started.
    /// It can be started when the timelapse is in stopped state and when drone has acknowledged configuration changes.
    case waitReadyToStart
}

/// Service in charge of restarting timelapse photo capture when application changes camera configuration.
///
/// When changing some camera configuration parameters related to timelapse photo capture,
/// if a timelapse capture is ongoing, it has to be stopped and restarted.
/// Changing the camera configuration and restarting the timelapse is done with the following steps:
///   1. Send command to stop the timelapse.
///   2. Send command to change the camera configuration.
///   3. Wait for the drone to indicate that the timelapse is stopped.
///   4. Wait for the drone to acknowledge camera configuration change.
///   5. Send command to start timelapse.
public protocol TimelapseRestartService: AnyObject {
}

/// Implementation of `TimelapseRestartService`.
public class TimelapseRestartServiceImpl {

    // MARK: Private properties

    /// Timelapse restart state.
    private var restartState = TimelapseRestartState.none
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
        // to reset timelapse restart process when connected drone changes
        connectedDroneHolder.dronePublisher
            .sink { [unowned self ] _ in
                restartState = .none
            }
            .store(in: &cancellables)

        // monitor camera configuration `willApply` notification
        // to trigger timelapse restart process if required
        cameraConfigWatcher.willApplyConfigPublisher
            .sink { [unowned self ] editor in
                // Check if the following conditions are met to restart a timelapse:
                //    • Drone's camera is accessible
                //    • A timelapse is ongoing
                //    • There is NO Flight Plan execution running
                //    • A timelapse restart is not already asked
                //    • The camera config to apply doesn't come from a restore after an FP stop
                guard let camera = connectedDroneHolder.drone?.currentCamera,
                      cameraPhotoCaptureService.state.canStop,
                      camera.config[Camera2Params.mode]?.value == .photo,
                      camera.config[Camera2Params.photoMode]?.value == .timeLapse,
                      editor[Camera2Params.mode]?.value == .photo,
                      editor[Camera2Params.photoMode]?.value == .timeLapse,
                      requireRestart(config: camera.config, editor: editor),
                      case .none = activeFlightPlanWatcher.activeFlightPlanState,
                      !cameraConfigWatcher.isRestoringSavedCameraSettings,
                      restartState == .none
                else { return }

                ULog.i(.tag, "Stop timelapse capture")

                // stop timelapse
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

                // change state to wait for timelapse to be ready to be started,
                // or end of timelapse restart process if failed to apply configuration
                restartState = success ? .waitReadyToStart : .none
            }
            .store(in: &cancellables)

        // monitor photo capture state and camera configuration updating flag
        // to start timelapse when ready
        cameraPhotoCaptureService.statePublisher
            .combineLatest(cameraConfigWatcher.updatingPublisher)
            .filter { $0.canStart && !$1 }
            .sink { [unowned self ] _ in
                guard let camera = connectedDroneHolder.drone?.currentCamera,
                      restartState == .waitReadyToStart
                else { return }

                // ensure that current capture mode is still timelapse
                // and no flight plan is being executed
                if camera.config[Camera2Params.mode]?.value == .photo,
                   camera.config[Camera2Params.photoMode]?.value == .timeLapse,
                   activeFlightPlanWatcher.activeFlightPlan == nil {
                    ULog.i(.tag, "Restart timelapse capture")
                    // start timelapse
                    camera.photoCapture?.start()
                } else {
                    ULog.i(.tag, "Do not restart timelapse capture: not in timelapse anymore")
                }
                // end of timelapse restart process
                restartState = .none
            }
            .store(in: &cancellables)
    }
}

// MARK: Private functions
private extension TimelapseRestartServiceImpl {
    /// Tells whether camera configuration changes require restarting the timelapse.
    ///
    /// - Parameters:
    ///    - config: current camera configuration
    ///    - editor: camera configuration that will be applied
    /// - Returns: `true` if timelapse should be restarted, `false` otherwise
    func requireRestart(config: Camera2Config, editor: Camera2Editor) -> Bool {
        config[Camera2Params.photoTimelapseInterval]?.value != editor[Camera2Params.photoTimelapseInterval]?.value
        || config[Camera2Params.photoDigitalSignature]?.value != editor[Camera2Params.photoDigitalSignature]?.value
        || config[Camera2Params.photoResolution]?.value != editor[Camera2Params.photoResolution]?.value
        || config[Camera2Params.photoFormat]?.value != editor[Camera2Params.photoFormat]?.value
        || config[Camera2Params.photoFileFormat]?.value != editor[Camera2Params.photoFileFormat]?.value
    }
}

// MARK: TimelapseRestartService protocol conformance
extension TimelapseRestartServiceImpl: TimelapseRestartService {
}
