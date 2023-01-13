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

import Combine
import SwiftyUserDefaults
import GroundSdk

/// State for HUDCameraStreamingViewModel.
final class HUDCameraStreamingState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    /// Current stream server enabled state.
    fileprivate(set) var streamEnabled: Bool = false
    /// Current secondary screen setting.
    fileprivate(set) var secondaryScreenSetting: SecondaryScreenType = .map
    /// Current overexposure setting.
    fileprivate(set) var overexposureSetting: SettingsOverexposure = .current

    // MARK: - Init
    required init() { }

    /// Constructor.
    ///
    /// - Parameters:
    ///    - streamEnabled: stream server enable state
    ///    - secondaryScreenSetting: setting for secondary screen
    ///    - overexposureSetting: setting for overexposure
    init(streamEnabled: Bool,
         secondaryScreenSetting: SecondaryScreenType,
         overexposureSetting: SettingsOverexposure) {
        self.streamEnabled = streamEnabled
        self.secondaryScreenSetting = secondaryScreenSetting
        self.overexposureSetting = overexposureSetting
    }

    // MARK: - Internal Funcs
    func isEqual(to other: HUDCameraStreamingState) -> Bool {
        // State should always get updated to avoid issues
        // with updates while stream view is not visible.
        return false
    }

    /// Returns a copy of the object.
    func copy() -> HUDCameraStreamingState {
        let copy = HUDCameraStreamingState(streamEnabled: streamEnabled,
                                           secondaryScreenSetting: secondaryScreenSetting,
                                           overexposureSetting: overexposureSetting)
        return copy
    }
}

/// ViewModel for HUDCameraStreaming, notifies on stream server, camera live and secondary screen setting changes.
final class HUDCameraStreamingViewModel: DroneWatcherViewModel<HUDCameraStreamingState> {
    // MARK: - Internal Properties
    /// Front camera stream.
    @Published var cameraLive: CameraLive?
    /// Whether snow view is visible.
    @Published var snowVisible = true
    /// Whether grid view is visible
    @Published var gridDisplayType: SettingsGridDisplayType = .none

    // MARK: - Private Properties
    private var overexposureSettingObserver: DefaultsDisposable?
    private var gridSettingsObserver: DefaultsDisposable?
    private var streamServerRef: Ref<StreamServer>?
    private var cameraLiveRef: Ref<CameraLive>?
    private var playStreamRetryTimer: Timer?
    private var isMonitoring: Bool = false

    // MARK: - Private Enums
    private enum Constants {
        static let playStreamRetryDelay = 1.0
    }

    // MARK: - Init
    override init() {
        super.init()

        listenDefaults()
    }

    // MARK: - Deinit
    deinit {
        cameraLiveRef = nil
        streamServerRef = nil
        playStreamRetryTimer?.invalidate()
        playStreamRetryTimer = nil
        overexposureSettingObserver?.dispose()
        overexposureSettingObserver = nil
        gridSettingsObserver?.dispose()
        gridSettingsObserver = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        // if monitoring is already enabled, reset it for drone change
        if isMonitoring {
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
        if enabled {
            if let drone = drone {
                listenStreamServer(drone: drone)
            }
        } else {
            _ = cameraLiveRef?.value?.pause()
            streamServerRef = nil
            cameraLiveRef = nil
            cameraLive = nil
        }
    }
}

// MARK: - Private Funcs
private extension HUDCameraStreamingViewModel {
    /// Starts watcher for stream server state.
    func listenStreamServer(drone: Drone) {
        streamServerRef = drone.getPeripheral(Peripherals.streamServer) { [unowned self] streamServer in
            guard let streamServer = streamServer else {
                cameraLiveRef = nil
                snowVisible = true
                return
            }

            snowVisible = false
            updateStreamEnabled(streamServer.enabled)

            // Start watcher for camera live.
            if cameraLiveRef == nil {
                cameraLiveRef = streamServer.live { [unowned self] live in
                    guard let live = live else {
                        return
                    }
                    cameraLive = live
                    playStreamIfNeeded(cameraLive: live)
                }
            }
        }
    }

    /// Updates stream enabled state.
    func updateStreamEnabled(_ enabled: Bool) {
        let copy = state.value.copy()
        copy.streamEnabled = enabled
        state.set(copy)
    }

    /// Starts watchers for defaults.
    func listenDefaults() {
        // start overexposure setting observer
        overexposureSettingObserver = Defaults.observe(\.overexposureSetting, options: [.new]) { [weak self] _ in
            DispatchQueue.userDefaults.async {
                let copy = self?.state.value.copy()
                copy?.overexposureSetting = SettingsOverexposure.current
                self?.state.set(copy)
            }
        }

        // start grid grid display type setting observer
        gridSettingsObserver = Defaults.observe(\.userGridDisplayTypeSetting, options: [.new, .initial]) { [weak self] _ in
            self?.gridDisplayType = SettingsGridDisplayType.current
        }
    }

    /// Plays the stream if all conditions are met.
    func playStreamIfNeeded(cameraLive: CameraLive) {
        guard state.value.streamEnabled,
              cameraLive.playState != .playing else {
            return
        }
        // play live stream
        _ = cameraLive.play()

        // retry later to recover from potential playing error (for instance when connection quality is low)
        playStreamRetryTimer?.invalidate()
        playStreamRetryTimer = Timer.scheduledTimer(withTimeInterval: Constants.playStreamRetryDelay, repeats: false) { [weak self] _ in
            if let cameraLive = self?.cameraLiveRef?.value {
                self?.playStreamIfNeeded(cameraLive: cameraLive)
            }
        }
    }
}
