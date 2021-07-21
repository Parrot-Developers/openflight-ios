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
import Combine

/// View model for split screen.

class SplitControlsViewModel {
    // MARK: - Private Properties
    private var bottomBarModeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private var modeSubject = CurrentValueSubject<SplitScreenMode, Never>(.splited)
    private var bottomBarModeSubject = CurrentValueSubject<BottomBarMode, Never>(.preset)
    private var isJoysticksVisibleSubject = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Internal Properties
    /// Current split screen mode.
    var mode: SplitScreenMode { modeSubject.value }
    /// Current bottom bar mode.
    var bottomBarMode: BottomBarMode { bottomBarModeSubject.value }
    /// Tells if joysticks are visible.
    var isJoysticksVisible: Bool { isJoysticksVisibleSubject.value }
    /// Helper for secondary miniature visibility.
    var shouldHideSecondary: AnyPublisher<Bool, Never> {
        modeSubject
            .combineLatest(bottomBarModeSubject)
            .map { (couple: (SplitScreenMode, BottomBarMode)) -> Bool in
                let (mode, bottomBarMode) = couple
                return mode == .stream && bottomBarMode != .closed
            }
            .eraseToAnyPublisher()
    }
    /// Current split screen mode.
    var modePublisher: AnyPublisher<SplitScreenMode, Never> { modeSubject.eraseToAnyPublisher() }
    /// Tells if joysticks are visible.
    var isJoysticksVisiblePublisher: AnyPublisher<Bool, Never> { isJoysticksVisibleSubject.eraseToAnyPublisher() }
    /// Current bottom bar mode.
    var bottomBarModePublisher: AnyPublisher<BottomBarMode, Never> { bottomBarModeSubject.eraseToAnyPublisher() }

    // MARK: - Init
    init() {
        listenBottomBarModeChanges()
        // TODO: Wrong injection
        listenJoysticksAvailabilityChanges(joysticksAvailabilityService: Services.hub.ui.joysticksAvailabilityService)
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.remove(observer: bottomBarModeObserver)
        bottomBarModeObserver = nil
    }

    // MARK: - Internal Funcs
    /// Sets current split screen mode.
    ///
    /// - Parameters:
    ///    - mode: split screen mode to apply
    func setMode(_ mode: SplitScreenMode) {
        self.modeSubject.value = mode
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
            self?.bottomBarModeSubject.value = bottomBarMode
        }
    }

    /// Starts watching for joysticks visibility changes.
    func listenJoysticksAvailabilityChanges(joysticksAvailabilityService: JoysticksAvailabilityService) {
        joysticksAvailabilityService.showJoysticksPublisher.sink { [unowned self] in
            isJoysticksVisibleSubject.value = $0
        }
        .store(in: &cancellables)
    }
}
