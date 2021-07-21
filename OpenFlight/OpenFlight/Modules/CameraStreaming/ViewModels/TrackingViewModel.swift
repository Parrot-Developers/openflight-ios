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

typealias TrackingData = Vmeta_TimedMetadata
typealias ProposalData = Vmeta_TrackingProposalMetadata

/// State for `TrackingViewModel`.
final class TrackingState: ViewModelState, EquatableState, Copying {

    // MARK: - Internal Properties
    fileprivate(set) var trackingInfo: TrackingData?
    fileprivate(set) var tilt: Double?

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - trackingInfo: meta data returned by the drone.
    init(trackingInfo: TrackingData?, tilt: Double?) {
        self.trackingInfo = trackingInfo
    }

    // MARK: - Internal Funcs
    func isEqual(to other: TrackingState) -> Bool {
        return self.trackingInfo == other.trackingInfo
            && self.tilt == other.tilt
    }

    /// Returns a copy of the object.
    func copy() -> TrackingState {
        let copy = TrackingState(trackingInfo: self.trackingInfo, tilt: self.tilt)
        return copy
    }
}

/// ViewModel for tracking.
final class TrackingViewModel: DroneWatcherViewModel<TrackingState> {

    // MARK: - Private Properties
    private var streamServerRef: Ref<StreamServer>?
    private var cameraLiveRef: Ref<CameraLive>?
    private var gimbalRef: Ref<Gimbal>?
    private var sink: StreamSink?
    private var onboardTrackerRef: Ref<OnboardTracker>?
    private var onboardTracker: OnboardTracker?
    private var frameTimeStamp: UInt64?
    private var cookie: UInt = 1
    private var isMonitoring: Bool = false

    // MARK: - Private Enums
    private enum Constants {
        static let defaultTilt: Double = 30.0
    }

    // MARK: - Deinit
    deinit {
        stopImageProcessing()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        switchToVideoRecording(drone: drone)

        /// If monitoring is already enabled, reset it for drone change.
        if self.isMonitoring {
            enableMonitoring(false)
            enableMonitoring(true)
        }
    }

    // MARK: - Internal Funcs
    /// Enables or disables the live monitoring of the stream.
    ///
    /// - Parameters:
    ///    - enabled: whether live should be enabled
    func enableMonitoring(_ enabled: Bool) {
        isMonitoring = enabled
        if enabled, let drone = drone {
            listenStreamServer(drone: drone)
            listenOnboardTracker(drone: drone)
            listenGimbal(drone: drone)
        } else {
            removeAllReferences()
        }
    }

    /// Send the frame that the user has drawed.
    ///
    /// - Parameters:
    ///    - frame: frame drawed by the user.
    func sendSelectionToDrone(frame: CGRect) {
        guard let frameTimeStamp = frameTimeStamp,
            let onboardTracker = onboardTracker else {
                return
        }

        cookie += 1
        var frameRequest = onboardTracker.ofRect(timestamp: frameTimeStamp,
                                                 horizontalPosition: Float(frame.origin.x),
                                                 verticalPosition: Float(frame.origin.y),
                                                 width: Float(frame.width),
                                                 height: Float(frame.height))
        frameRequest.cookie = cookie
        onboardTracker.replaceAllTargetsBy(trackingRequest: frameRequest)
    }

    /// Send the proposal selected by the user.
    ///
    /// - Parameters:
    ///    - proposalId: Proposal selected by the user.
    func sendProposalToDrone(proposalId: UInt) {
        guard let frameTimeStamp = frameTimeStamp,
            let onboardTracker = onboardTracker else {
                return
        }

        cookie += 1
        var proposalRequest = onboardTracker.ofProposal(timestamp: frameTimeStamp, proposalId: proposalId)
        proposalRequest.cookie = cookie
        onboardTracker.replaceAllTargetsBy(trackingRequest: proposalRequest)
    }

    /// Remove all current targets.
    func removeAllTargets() {
        onboardTracker?.removeAllTargets()
    }
}

// MARK: - Private Funcs
private extension TrackingViewModel {
    /// Switch camera mode to recording if necessary.
    func switchToVideoRecording(drone: Drone) {
        guard let currentCamera = drone.currentCamera,
              currentCamera.mode == .photo else {
            return
        }

        let currentEditor = currentCamera.currentEditor
        currentEditor[Camera2Params.mode]?.value = .recording
        currentEditor.saveSettings(currentConfig: currentCamera.config)
    }

    /// Starts watcher for stream server state.
    func listenStreamServer(drone: Drone) {
        streamServerRef = drone.getPeripheral(Peripherals.streamServer) { [weak self] streamServer in

            guard let strongStreamServer = streamServer,
                strongStreamServer.enabled else {
                    // Avoid issues when dismissing App and returning on it.
                    self?.cameraLiveRef = nil
                    self?.sink = nil
                    return
            }

            self?.cameraLiveRef = strongStreamServer.live { [weak self] liveStream in
                guard let strongSelf = self,
                    let strongLiveStream = liveStream,
                    strongSelf.sink == nil else {
                        return
                }

                strongSelf.sink = strongLiveStream.openYuvSink(queue: DispatchQueue.main, listener: strongSelf)
            }
        }
    }

    /// Starts watcher for onBoard tracker state.
    func listenOnboardTracker(drone: Drone) {
        onboardTrackerRef = drone.getPeripheral(Peripherals.onboardTracker) { [weak self] onboardTracker in
            self?.onboardTracker = onboardTracker
        }
        drone.getPeripheral(Peripherals.onboardTracker)?.startTrackingEngine(boxProposals: true)
    }

    /// Starts watcher for gimbal.
    func listenGimbal(drone: Drone) {
        gimbalRef = drone.getPeripheral(Peripherals.gimbal) { [weak self] gimbal in
            guard let strongGimbal = gimbal,
                strongGimbal.calibrated,
                let currentPitch = strongGimbal.currentAttitude[.pitch] else {
                    return
            }

            let copy = self?.state.value.copy()
            copy?.tilt = currentPitch
            self?.state.set(copy)
        }
    }

    /// Update tracking info from drone.
    ///
    /// - Parameters:
    ///    - info: Meta data from the drone.
    func trackingStatusDidUpdate(_ info: TrackingData?) {
        frameTimeStamp = info?.camera.timestamp
        let copy = state.value.copy()
        copy.trackingInfo = info
        state.set(copy)
    }

    /// Clear every variables of the view model.
    func stopImageProcessing() {
        onboardTracker?.removeAllTargets()
        onboardTracker?.stopTrackingEngine()
        removeAllReferences()
    }

    // Nullifies all references
    func removeAllReferences() {
        streamServerRef = nil
        cameraLiveRef = nil
        sink = nil
        onboardTrackerRef = nil
        onboardTracker = nil
        gimbalRef = nil
    }
}

// MARK: - YuvSinkListener
extension TrackingViewModel: YuvSinkListener {
    func didStart(sink: StreamSink) {}
    func didStop(sink: StreamSink) {}

    func frameReady(sink: StreamSink, frame: SdkCoreFrame) {
        guard let metadataProtobuf = frame.metadataProtobuf else { return }

        do {
            let decodedInfo = try TrackingData(serializedData: Data(metadataProtobuf))
            DispatchQueue.main.async {
                self.trackingStatusDidUpdate(decodedInfo)
            }
        } catch {}
    }
}
