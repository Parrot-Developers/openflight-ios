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

import UIKit
import GroundSdk
import SwiftyUserDefaults

/// State for `LiveStreamingWidgetViewModel`.
final class LiveStreamingWidgetState: DeviceConnectionState {
    // MARK: - Internal Properties
    /// Live streaming state.
    fileprivate(set) var liveStreamingState: LiveStreamingWidgetTypes = .none
    /// Tells if we need to hide the widget.
    fileprivate(set) var isLiveStreamingEnabled: Bool = false
    /// Tells if ministream is displayed.
    fileprivate(set) var isMiniStream: Bool = false

    // MARK: Computed Properties
    var shouldShowWidget: Bool {
        return isLiveStreamingEnabled && !isMiniStream
    }

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: connection state
    ///    - liveStreamingState: live streaming state
    ///    - isLiveStreamingEnabled: should hide live streaming widget
    ///    - isMiniStream: tells if ministream is displayed
    init(connectionState: DeviceState.ConnectionState,
         liveStreamingState: LiveStreamingWidgetTypes,
         isLiveStreamingEnabled: Bool,
         isMiniStream: Bool) {
        super.init(connectionState: connectionState)
        self.liveStreamingState = liveStreamingState
        self.isLiveStreamingEnabled = isLiveStreamingEnabled
        self.isMiniStream = isMiniStream
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? LiveStreamingWidgetState else {
            return false
        }
        return super.isEqual(to: other)
            && self.liveStreamingState == other.liveStreamingState
            && self.isLiveStreamingEnabled == other.isLiveStreamingEnabled
            && self.isMiniStream == other.isMiniStream
    }

    override func copy() -> LiveStreamingWidgetState {
        let copy = LiveStreamingWidgetState(connectionState: connectionState,
                                            liveStreamingState: liveStreamingState,
                                            isLiveStreamingEnabled: isLiveStreamingEnabled,
                                            isMiniStream: isMiniStream)
        return copy
    }
}

/// View Model wich manage stream sharing widget.

final class LiveStreamingWidgetViewModel: DroneStateViewModel<LiveStreamingWidgetState> {
    // MARK: - Private Properties
    private var liveStreamingSettingObserver: DefaultsDisposable?
    private var splitModeObserver: Any?

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - stateDidUpdate: called when streaming widget state changed
    override init(stateDidUpdate: ((LiveStreamingWidgetState) -> Void)? = nil) {
        super.init(stateDidUpdate: stateDidUpdate)
        listenDefaults()
        listenSplitModeChanges()
    }

    // MARK: - Deinit
    deinit {
        liveStreamingSettingObserver?.dispose()
        liveStreamingSettingObserver = nil
        if let splitModeObserver = splitModeObserver {
            NotificationCenter.default.removeObserver(splitModeObserver)
        }
        splitModeObserver = nil
    }

    // MARK: - Override Funcs
    override func droneConnectionStateDidChange() {
        let copy = state.value.copy()
        copy.liveStreamingState = state.value.connectionState == .disconnected
            ? .none
            : .stopped

        state.set(copy)
    }

    // MARK: - Internal Funcs
    /// Touch up on streaming button.
    func buttonTouchedUpInside() {
        let copy = state.value.copy()
        switch state.value.liveStreamingState {
        case .stopped:
            copy.liveStreamingState = .started
        case .started:
            copy.liveStreamingState = .stopped
        case .none:
            // TODO: Register a newserver url. Start the new view
            break
        }
        state.set(copy)
    }
}

// MARK: - Private Funcs
private extension LiveStreamingWidgetViewModel {
    /// Starts watcher for user defaults.
    func listenDefaults() {
        liveStreamingSettingObserver = Defaults.observe(\.liveStreaming, options: [.new]) { [weak self] _ in
            DispatchQueue.userDefaults.async {
                self?.updateLiveSharing()
            }
        }
        updateLiveSharing()
    }

    /// Updates live sharing visibility according to default.
    func updateLiveSharing() {
        guard let isLiveSharingEnabled = Defaults.liveStreaming else {
            return
        }
        let copy = state.value.copy()
        copy.isLiveStreamingEnabled = isLiveSharingEnabled
        state.set(copy)
    }

    /// Starts listening split mode changes.
    func listenSplitModeChanges() {
        splitModeObserver = NotificationCenter.default.addObserver(forName: .splitModeDidChange,
                                                                   object: nil,
                                                                   queue: nil) { [weak self] notification in
            guard let splitMode = notification.userInfo?[SplitControlsConstants.splitScreenModeKey]
                as? SplitScreenMode else { return }
            let copy = self?.state.value.copy()
            copy?.isMiniStream = splitMode == .secondary
            self?.state.set(copy)
        }
    }
}
