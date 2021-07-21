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
import Combine

/// State for `BottomBarViewModel`.

final class GlobalBottomBarState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    /// Inform about item's visibility.
    fileprivate(set) var shouldHide: Bool = false
    fileprivate(set) var missionMode: MissionMode = ClassicMission.manualMode

    // MARK: - Init
    required init() {}

    /// Init.
    ///
    /// - Parameters:
    ///    - shouldHide: item visibility
    init(shouldHide: Bool) {
        self.shouldHide = shouldHide
    }

    // MARK: - Equatable Implementation
    func isEqual(to other: GlobalBottomBarState) -> Bool {
        return self.shouldHide == other.shouldHide
            && self.missionMode.key == other.missionMode.key
    }

    // MARK: - Copying Implementation
    func copy() -> GlobalBottomBarState {
        let copy = GlobalBottomBarState(shouldHide: self.shouldHide)
        copy.missionMode = missionMode
        return copy
    }
}

/// View model for `BottomBarViewController`.

final class BottomBarViewModel: BaseViewModel<GlobalBottomBarState> {
    // MARK: - Private Properties
    private var modalPresentationObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private unowned var currentMissionManager = Services.hub.currentMissionManager

    // MARK: - Init
    override init() {
        super.init()

        observeModalPresentation()
        listenMissionMode()
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.remove(observer: modalPresentationObserver)
        modalPresentationObserver = nil
    }
}

// MARK: - Private Funcs
private extension BottomBarViewModel {
    /// Starts watcher for modal presentation.
    func observeModalPresentation() {
        modalPresentationObserver = NotificationCenter.default.addObserver(
            forName: .modalPresentDidChange,
            object: nil,
            queue: nil) { [weak self] notification in
                guard let isModalPresented = notification.userInfo?[BottomBarViewControllerNotifications.notificationKey] as? Bool else {
                    return
                }
                let copy = self?.state.value.copy()
                copy?.shouldHide = isModalPresented
                self?.state.set(copy)
        }
    }

    /// Listen for mission mode
    func listenMissionMode() {
        currentMissionManager.modePublisher.sink { [unowned self] in
            let copy = self.state.value.copy()
            copy.missionMode = $0
            self.state.set(copy)
        }
        .store(in: &cancellables)
    }
}
