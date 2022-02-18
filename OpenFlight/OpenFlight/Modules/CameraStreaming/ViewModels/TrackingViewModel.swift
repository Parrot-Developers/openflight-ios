//    Copyright (C) 2020 Parrot Drones SAS
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
    fileprivate(set) var droneNotConnected: Bool?

    // MARK: - Init
    required init() { }

    /// Constructor.
    ///
    /// - Parameters:
    ///    - trackingInfo: meta data returned by the drone
    ///    - tilt: tilt
    ///    - droneNotConnected: state of the drone
    init(trackingInfo: TrackingData?, tilt: Double?, droneNotConnected: Bool?) {
        self.trackingInfo = trackingInfo
    }

    // MARK: - Internal Funcs
    func isEqual(to other: TrackingState) -> Bool {
        return trackingInfo == other.trackingInfo
        && tilt == other.tilt
        && droneNotConnected == other.droneNotConnected
    }

    /// Returns a copy of the object.
    func copy() -> TrackingState {
        let copy = TrackingState(trackingInfo: trackingInfo, tilt: tilt, droneNotConnected: droneNotConnected)
        return copy
    }
}

/// ViewModel for tracking.
final class TrackingViewModel: DroneWatcherViewModel<TrackingState> {

    // MARK: - Private Properties
    private var streamServerRef: Ref<StreamServer>?
    private var cameraLiveRef: Ref<CameraLive>?
    private var gimbalRef: Ref<Gimbal>?
    private var stateRef: Ref<DeviceState>?
    private var sink: StreamSink?
    private var onboardTrackerRef: Ref<OnboardTracker>?
    private var onboardTracker: OnboardTracker?
    private var frameTimeStamp: UInt64?
    private var cookie: UInt = 1
    private var isMonitoring: Bool = false

    // MARK: - Deinit
    deinit {
        stopImageProcessing()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        // if monitoring is already enabled, reset it for drone change
        if isMonitoring {
            enableMonitoring(false)
            enableMonitoring(true)
        }

        stateRef = drone.getState { [unowned self] droneState in
            let copy = state.value.copy()

            copy.droneNotConnected = !(droneState?.connectionState == .connected)
            state.set(copy)
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

    /// Sends the frame that the user has drawn.
    ///
    /// - Parameters:
    ///    - frame: frame drawn by the user
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

    /// Sends the proposal selected by the user.
    ///
    /// - Parameters:
    ///    - proposalId: proposal selected by the user
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

    /// Removes all current targets.
    func removeAllTargets() {
        onboardTracker?.removeAllTargets()
    }
}

// MARK: - Private Funcs
private extension TrackingViewModel {

    /// Starts watcher for stream server state.
    func listenStreamServer(drone: Drone) {
        streamServerRef = drone.getPeripheral(Peripherals.streamServer) { [unowned self] streamServer in

            guard let streamServer = streamServer,
                  streamServer.enabled else {
                      // avoid issues when dismissing App and returning on it
                      cameraLiveRef = nil
                      sink = nil
                      return
                  }

            cameraLiveRef = streamServer.live { [unowned self] liveStream in
                guard let liveStream = liveStream,
                      sink == nil else {
                          return
                      }

                sink = liveStream.openYuvSink(queue: DispatchQueue.main, listener: self)
            }
        }
    }

    /// Starts watcher for onBoard tracker state.
    func listenOnboardTracker(drone: Drone) {
        onboardTrackerRef = drone.getPeripheral(Peripherals.onboardTracker) { [unowned self] onboardTracker in
            self.onboardTracker = onboardTracker
        }
    }

    /// Starts watcher for gimbal.
    func listenGimbal(drone: Drone) {
        gimbalRef = drone.getPeripheral(Peripherals.gimbal) { [unowned self] gimbal in
            guard let gimbal = gimbal,
                  gimbal.calibrated,
                  let currentPitch = gimbal.currentAttitude[.pitch] else {
                      return
                  }

            let copy = state.value.copy()
            copy.tilt = currentPitch
            state.set(copy)
        }
    }

    /// Updates tracking info from drone.
    ///
    /// - Parameters:
    ///    - info: metadata from the drone
    func trackingStatusDidUpdate(_ info: TrackingData?) {
        frameTimeStamp = info?.camera.timestamp
        let copy = state.value.copy()
        copy.trackingInfo = info
        state.set(copy)
    }

    /// Clears all variables of the view model.
    func stopImageProcessing() {
        removeAllReferences()
    }

    /// Releases all references.
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
