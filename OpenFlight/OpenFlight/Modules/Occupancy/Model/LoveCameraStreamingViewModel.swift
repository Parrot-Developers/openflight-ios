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

// FIXME: Occupancy / WIP

import GroundSdk

/// State for `LoveCameraStreamingStateViewModel`.
final class LoveCameraStreamingState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    /// Current stream server enabled state.
    fileprivate(set) var streamEnabled: Bool = false

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - streamEnabled: stream server enable state
    init(streamEnabled: Bool) {
        self.streamEnabled = streamEnabled
    }

    // MARK: - Internal Funcs
    func isEqual(to other: LoveCameraStreamingState) -> Bool {
        // State should always get updated to avoid issues
        // with updates while stream view is not visible.
        return false
    }

    /// Returns a copy of the object.
    func copy() -> LoveCameraStreamingState {
        let copy = LoveCameraStreamingState(
            streamEnabled: self.streamEnabled
        )
        return copy
    }
}

/// ViewModel for LoveCameraStreaming, notifies on stream server, camera live and changes.

final class LoveCameraStreamingViewModel: DroneWatcherViewModel<LoveCameraStreamingState> {

    // MARK: - Private Properties
    private var streamServerRef: Ref<StreamServer>?
    private var cameraLiveRef: Ref<CameraLive>?
    private var playStreamRetryTimer: Timer?
    private var isMonitoring: Bool = false

    // MARK: - Private Enums
    private enum Constants {
        static let playStreamRetryDelay = 1.0
    }

    // MARK: - Deinit
    deinit {
        self.stopImageProcessing()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        /// If monitoring is already enabled, reset it for drone change.
        if self.isMonitoring {
            self.enableMonitoring(false)
            self.enableMonitoring(true)
        }
    }

    // MARK: - Internal Funcs
    /// Enables or disables the live monitoring of the stream.
    ///
    /// - Parameters:
    ///    - enabled: whether live should be enabled
    func enableMonitoring(_ enabled: Bool) {
        self.isMonitoring = enabled
        if enabled, let drone = drone {
            self.listenStreamServer(drone: drone)
        } else {
            self.stopImageProcessing()
        }
    }
}

// MARK: - Private Funcs
private extension LoveCameraStreamingViewModel {
    /// Starts watcher for stream server state.
    func listenStreamServer(drone: Drone) {
        streamServerRef = drone.getPeripheral(Peripherals.streamServer) { [weak self] streamServer in
            guard let strongSelf = self,
                let streamServer = streamServer,
                streamServer.enabled
                else {
                    self?.updateStreamEnabled(false)
                    return
            }
            strongSelf.updateStreamEnabled(streamServer.enabled)
            // Start watcher for camera live.
            strongSelf.cameraLiveRef = drone.getPeripheral(Peripherals.streamServer)?.live { [weak self] cameraLive in
                guard cameraLive != nil else {
                    return
                }
                self?.playStreamIfNeeded(drone: drone)
            }
            strongSelf.playStreamIfNeeded(drone: drone)
        }
    }

    /// Updates stream enabled state.
    func updateStreamEnabled(_ enabled: Bool) {
        let copy = state.value.copy()
        copy.streamEnabled = enabled
        state.set(copy)
    }

    /// Clear every variables of the view model.
    func stopImageProcessing() {
        self.streamServerRef = nil
        self.cameraLiveRef = nil
    }

    /// Plays the stream if all conditions are met.
    func playStreamIfNeeded(drone: Drone) {
        guard state.value.streamEnabled,
            let stream = cameraLiveRef?.value,
            stream.playState != .playing
            else {
                return
        }
        // Play live stream.
        _ = stream.play()
        // Retry later to recover from potential playing error (for instance when connection quality is low).
        playStreamRetryTimer?.invalidate()
        playStreamRetryTimer = Timer.scheduledTimer(withTimeInterval: Constants.playStreamRetryDelay, repeats: false) { [weak self] _ in
            if let drone = self?.drone {
                self?.playStreamIfNeeded(drone: drone)
            }
        }
    }
}
