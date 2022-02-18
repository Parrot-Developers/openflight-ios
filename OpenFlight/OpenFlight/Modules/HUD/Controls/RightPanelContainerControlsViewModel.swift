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

import Foundation
import Combine

/// State for `RightPanelContainerControlsViewModel`.

final class RightPanelContainerControlsState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    /// Current mission launcher mode.
    fileprivate(set) var isMissionMenuDisplayed: Bool = false
    /// Current alert panel mode.
    fileprivate(set) var alertPanelMode: AlertPanelMode = .preset
    /// Boolean describing if Flight Plan mode is active.
    fileprivate(set) var isRightPanelRequired: Bool = false
    /// Boolean to force hide Flight Plan panel.
    fileprivate(set) var forceHidePanel: Bool = false
    /// Boolean describing if hand launch need to be hidden when a modal is presented.
    fileprivate(set) var isOverContextModalPresented: Bool = false

    /// Boolean describing if flight plan panel should be opened.
    var shouldDisplayRightPanel: Bool {
        return isRightPanelRequired
            && !isMissionMenuDisplayed
            && alertPanelMode == .closed
            && !forceHidePanel
    }

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - isMissionMenuDisplayed: is mission menu displayed
    ///    - alertPanelMode: current alert panel mode
    ///    - isFlightPlanActive: whether flight plan is currently active
    ///    - forceHidePanel: whether panel should be force hidden
    ///    - isOverContextModalPresented: whether panel should be hidden if a modal is presented
    init(isMissionMenuDisplayed: Bool,
         alertPanelMode: AlertPanelMode,
         isRightPanelRequired: Bool,
         forceHidePanel: Bool,
         isOverContextModalPresented: Bool) {
        self.isMissionMenuDisplayed = isMissionMenuDisplayed
        self.alertPanelMode = alertPanelMode
        self.isRightPanelRequired = isRightPanelRequired
        self.forceHidePanel = forceHidePanel
        self.isOverContextModalPresented = isOverContextModalPresented
    }

    // MARK: - Equatable
    func isEqual(to other: RightPanelContainerControlsState) -> Bool {
        return self.isMissionMenuDisplayed == other.isMissionMenuDisplayed
            && self.alertPanelMode == other.alertPanelMode
            && self.isRightPanelRequired == other.isRightPanelRequired
            && self.forceHidePanel == other.forceHidePanel
            && self.isOverContextModalPresented == other.isOverContextModalPresented
    }

    // MARK: - Copying
    func copy() -> RightPanelContainerControlsState {
        return RightPanelContainerControlsState(isMissionMenuDisplayed: self.isMissionMenuDisplayed,
                                       alertPanelMode: self.alertPanelMode,
                                       isRightPanelRequired: self.isRightPanelRequired,
                                       forceHidePanel: self.forceHidePanel,
                                       isOverContextModalPresented: self.isOverContextModalPresented)
    }
}

/// View model for `FlightPlanControls`.

final class RightPanelContainerControlsViewModel: BaseViewModel<RightPanelContainerControlsState> {
    // MARK: - Private Properties
    private var alertPanelModeObserver: Any?
    // TODO : wrong injection
    private unowned var currentMissionManager = Services.hub.currentMissionManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    override init() {
        super.init()
        listenMissionMenuDisplayedChanges()
        listenAlertPanelMode()
        listenCurrentMission()
        listenModalPresentation()
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.remove(observer: alertPanelModeObserver)
        alertPanelModeObserver = nil
    }

    // MARK: - Internal Funcs
    /// Force hide the Flight Plan panel.
    ///
    /// - Parameters:
    ///    - shouldHide: whether panel should be hidden
    func forceHidePanel(_ shouldHide: Bool) {
        let copy = state.value.copy()
        copy.forceHidePanel = shouldHide
        state.set(copy)
    }
}

// MARK: - Private Funcs
private extension RightPanelContainerControlsViewModel {
    /// Starts watcher for mission menu display changes.
    func listenMissionMenuDisplayedChanges() {
        Services.hub.ui.uiComponentsDisplayReporter.isMissionMenuDisplayedPublisher
            .sink { [weak self] in
                let copy = self?.state.value.copy()
                copy?.isMissionMenuDisplayed = $0
                self?.state.set(copy)
            }
            .store(in: &cancellables)
    }

    /// Starts watcher for alert panel open/close mode.
    func listenAlertPanelMode() {
        alertPanelModeObserver = NotificationCenter.default.addObserver(
            forName: .alertPanelModeDidChange,
            object: nil,
            queue: nil) { [weak self] notification in
                guard let alertPanelMode = notification.userInfo?[AlertPanelMode.notificationKey] as? AlertPanelMode else {
                    return
                }
                let copy = self?.state.value.copy()
                copy?.alertPanelMode = alertPanelMode
                self?.state.set(copy)
        }
    }

    /// Listen for mission
    func listenCurrentMission() {
        currentMissionManager.modePublisher.sink { [unowned self] mode in
            let copy = state.value.copy()
            copy.isRightPanelRequired = mode.isRightPanelRequired
            state.set(copy)
        }
        .store(in: &cancellables)
    }

    /// Listen to modal presentation
    func listenModalPresentation() {
        Services.hub.ui.uiComponentsDisplayReporter.isModalPresentedPublisher
            .sink { [weak self] in
                let copy = self?.state.value.copy()
                copy?.isOverContextModalPresented = $0
                self?.state.set(copy)
            }
            .store(in: &cancellables)
    }
}
