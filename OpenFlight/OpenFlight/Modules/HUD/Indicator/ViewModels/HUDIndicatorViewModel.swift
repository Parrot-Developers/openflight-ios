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

import UIKit
import GroundSdk
import Combine

// MARK: - HUDIndicatorState
/// State for `HUDIndicatorViewMode`.

final class HUDIndicatorState: DeviceConnectionState {
    // MARK: - Internal Properties
    /// Current split screen mode.
    fileprivate var currentSplitScreenMode = SplitScreenMode.preset
    /// Current bottom bar mode.
    fileprivate var currentBottomBarMode = BottomBarMode.preset
    /// Current mission launcher mode.
    fileprivate var missionMenuDisplayed = false
    /// Boolean to determine if indicator should be force hidden.
    fileprivate var forceHideIndicator = false
    /// Boolean to determine if indicator should be hidden due to joysticks visibility.
    fileprivate var isJoysticksVisible = false
    /// Current indicator visibility.
    fileprivate(set) var shouldHideIndicator: Observable<Bool> = Observable(false)

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - droneConnectionState: drone connection state
    ///    - currentSplitScreenMode: current split screen mode
    ///    - currentBottomBarMode: current bottom bar mode
    ///    - missionMenuDisplayed: is mission menu displayed
    ///    - forceHideIndicator: boolean to determine if indicator should be force hidden
    ///    - isJoysticksVisible: boolean to determine if indicator should be hidden due to joysticks view
    ///    - shouldHideIndicator: observable for indicator visibility
    init(droneConnectionState: DeviceState.ConnectionState,
         currentSplitScreenMode: SplitScreenMode,
         currentBottomBarMode: BottomBarMode,
         missionMenuDisplayed: Bool,
         forceHideIndicator: Bool,
         isJoysticksVisible: Bool,
         shouldHideIndicator: Observable<Bool>) {
        super.init(connectionState: droneConnectionState)
        self.currentSplitScreenMode = currentSplitScreenMode
        self.currentBottomBarMode = currentBottomBarMode
        self.missionMenuDisplayed = missionMenuDisplayed
        self.forceHideIndicator = forceHideIndicator
        self.isJoysticksVisible = isJoysticksVisible
        self.shouldHideIndicator = shouldHideIndicator
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? HUDIndicatorState else {
            return false
        }
        return super.isEqual(to: other)
            && currentSplitScreenMode == other.currentSplitScreenMode
            && currentBottomBarMode == other.currentBottomBarMode
            && missionMenuDisplayed == other.missionMenuDisplayed
            && forceHideIndicator == other.forceHideIndicator
            && isJoysticksVisible == other.isJoysticksVisible
            && shouldHideIndicator.value == other.shouldHideIndicator.value
    }

    /// Returns a copy of the object.
    override func copy() -> HUDIndicatorState {
        let copy = HUDIndicatorState(droneConnectionState: self.connectionState,
                                     currentSplitScreenMode: self.currentSplitScreenMode,
                                     currentBottomBarMode: self.currentBottomBarMode,
                                     missionMenuDisplayed: self.missionMenuDisplayed,
                                     forceHideIndicator: self.forceHideIndicator,
                                     isJoysticksVisible: self.isJoysticksVisible,
                                     shouldHideIndicator: self.shouldHideIndicator)
        return copy
    }
}

// MARK: - HUDIndicatorViewModel
/// View Model used to manage indicator datas.

final class HUDIndicatorViewModel: DroneStateViewModel<HUDIndicatorState> {
    // MARK: - Private Properties
    private var splitModeObserver: Any?
    private var bottomBarModeObserver: Any?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - indicatorVisibilityDidChange: called when indicator visibility changes
    init(indicatorVisibilityDidChange: ((Bool) -> Void)? = nil) {
        super.init()
        state.valueChanged = { [weak self] _ in
            self?.updateIndicatorVisibility()
        }
        state.value.shouldHideIndicator.valueChanged = indicatorVisibilityDidChange
        listenSplitModeChanges()
        listenBottomBarModeChanges()
        listenMissionMenuDisplayedChanges()
        // TODO: wrong injection
        listenJoysticksAvailabilityChanges(joysticksAvailabilityService: Services.hub.ui.joysticksAvailabilityService)
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.remove(observer: splitModeObserver)
        splitModeObserver = nil
        NotificationCenter.default.remove(observer: bottomBarModeObserver)
        bottomBarModeObserver = nil
    }

    // MARK: - Internal Funcs
    /// Hide indicator view if needed.
    func hideIndicatorView() {
        let copy = state.value.copy()
        copy.forceHideIndicator = true
        state.set(copy)
    }

    /// Show indicator view if needed.
    func showIndicatorView() {
        let copy = state.value.copy()
        copy.forceHideIndicator = false
        state.set(copy)
    }
}

// MARK: - Private Funcs
private extension HUDIndicatorViewModel {
    /// Starts watcher for split mode changes.
    func listenSplitModeChanges() {
        splitModeObserver = NotificationCenter.default.addObserver(forName: .splitModeDidChange,
                                                                   object: nil,
                                                                   queue: nil) { [weak self] notification in
            guard let splitMode = notification.userInfo?[SplitControlsConstants.splitScreenModeKey] as? SplitScreenMode else {
                return
            }
            let copy = self?.state.value.copy()
            copy?.currentSplitScreenMode = splitMode
            copy?.forceHideIndicator = false
            self?.state.set(copy)
            self?.updateIndicatorVisibility()
        }
    }

    /// Starts watcher for bottom bar mode changes.
    func listenBottomBarModeChanges() {
        bottomBarModeObserver = NotificationCenter.default.addObserver(forName: .bottomBarModeDidChange,
                                                                       object: nil,
                                                                       queue: nil) { [weak self] notification in
            guard let bottomBarMode = notification.userInfo?[BottomBarMode.notificationKey] as? BottomBarMode else {
                return
            }
            let copy = self?.state.value.copy()
            copy?.currentBottomBarMode = bottomBarMode
            self?.state.set(copy)
            self?.updateIndicatorVisibility()
        }
    }

    /// Starts watcher for mission menu display changes.
    func listenMissionMenuDisplayedChanges() {
        Services.hub.ui.uiComponentsDisplayReporter.isMissionMenuDisplayedPublisher
            .sink { [weak self] in
                let copy = self?.state.value.copy()
                copy?.missionMenuDisplayed = $0
                self?.state.set(copy)
                self?.updateIndicatorVisibility()
            }
            .store(in: &cancellables)
    }

    /// Starts watching for joysticks visibility changes.
    func listenJoysticksAvailabilityChanges(joysticksAvailabilityService: JoysticksAvailabilityService) {
        joysticksAvailabilityService.showJoysticksPublisher.sink { [unowned self] in
            let copy = state.value.copy()
            copy.isJoysticksVisible = $0
            state.set(copy)
            updateIndicatorVisibility()
        }
        .store(in: &cancellables)
    }

    /// Computes indicator visibility.
    func updateIndicatorVisibility() {
        let shouldHideIndicator = state.value.currentSplitScreenMode == .secondary
            || state.value.currentBottomBarMode != .closed
            || state.value.missionMenuDisplayed
            || state.value.isConnected()
            || state.value.forceHideIndicator
            || state.value.isJoysticksVisible
        state.value.shouldHideIndicator.set(shouldHideIndicator)
    }
}
