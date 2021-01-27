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

import SwiftyUserDefaults

/// State for `SplitControlsViewModel`.

final class SplitControlsState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    /// Current split screen mode.
    fileprivate(set) var mode: SplitScreenMode = .splited
    /// Current bottom bar mode.
    fileprivate(set) var bottomBarMode: BottomBarMode = .preset
    /// Tells if joysticks are visible.
    fileprivate(set) var isJoysticksVisible = false
    /// Helper for secondary miniature visibility.
    var shouldHideSecondary: Bool {
        return mode == .stream && bottomBarMode != .closed
    }

    // MARK: - Init
    required init() {}

    /// Init.
    ///
    /// - Parameters:
    ///    - mode: current split screen mode
    ///    - bottomBarMode: current bottom bar mode
    ///    - isJoysticksVisible: tells if joysticks are visible
    init(mode: SplitScreenMode,
         bottomBarMode: BottomBarMode,
         isJoysticksVisible: Bool) {
        self.mode = mode
        self.bottomBarMode = bottomBarMode
        self.isJoysticksVisible = isJoysticksVisible
    }

    // MARK: - Equatable Implementation
    func isEqual(to other: SplitControlsState) -> Bool {
        return self.mode == other.mode
            && self.bottomBarMode == other.bottomBarMode
            && self.isJoysticksVisible == other.isJoysticksVisible
    }

    // MARK: - Copying Implementation
    func copy() -> SplitControlsState {
        return SplitControlsState(mode: self.mode,
                                  bottomBarMode: self.bottomBarMode,
                                  isJoysticksVisible: self.isJoysticksVisible)
    }
}

/// View model for split screen.

final class SplitControlsViewModel: BaseViewModel<SplitControlsState> {
    // MARK: - Private Properties
    private var bottomBarModeObserver: Any?
    private var joysticksAvailabilityObserver: Any?

    // MARK: - Init
    override init(stateDidUpdate: ((SplitControlsState) -> Void)? = nil) {
        super.init(stateDidUpdate: stateDidUpdate)
        listenBottomBarModeChanges()
        listenJoysticksAvailabilityChanges()
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.remove(observer: bottomBarModeObserver)
        bottomBarModeObserver = nil
        NotificationCenter.default.remove(observer: joysticksAvailabilityObserver)
        joysticksAvailabilityObserver = nil
    }

    // MARK: - Internal Funcs
    /// Sets current split screen mode.
    ///
    /// - Parameters:
    ///    - mode: split screen mode to apply
    func setMode(_ mode: SplitScreenMode) {
        let copy = self.state.value.copy()
        copy.mode = mode
        self.state.set(copy)
        NotificationCenter.default.post(name: .splitModeDidChange,
                                        object: self,
                                        userInfo: [SplitControlsConstants.splitScreenModeKey: mode])
    }
}

// MARK: - Private Funcs
private extension SplitControlsViewModel {
    /// Starts watcher for bottom bar mode changes.
    func listenBottomBarModeChanges() {
        bottomBarModeObserver = NotificationCenter.default.addObserver(forName: .bottomBarModeDidChange,
                                                                       object: nil,
                                                                       queue: nil) { [weak self] notification in
            guard let bottomBarMode = notification.userInfo?[BottomBarMode.notificationKey] as? BottomBarMode else {
                return
            }
            let copy = self?.state.value.copy()
            copy?.bottomBarMode = bottomBarMode
            self?.state.set(copy)
        }
    }

    /// Starts watcher for joysticks availability changes.
    func listenJoysticksAvailabilityChanges() {
        joysticksAvailabilityObserver = NotificationCenter.default.addObserver(forName: .joysticksAvailabilityDidChange,
                                                                             object: nil,
                                                                             queue: nil) { [weak self] notification in
            guard let joysticksAvailable = notification.userInfo?[JoysticksStateNotifications.joysticksAvailabilityNotificationKey] as? Bool else {
                return
            }
            let copy = self?.state.value.copy()
            copy?.isJoysticksVisible = joysticksAvailable
            self?.state.set(copy)
        }
    }
}
