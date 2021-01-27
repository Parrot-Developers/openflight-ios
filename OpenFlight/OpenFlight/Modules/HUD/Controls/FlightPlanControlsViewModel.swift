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

import Foundation

/// State for `FlightPlanControlsViewModel`.

final class FlightPlanControlsState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    /// Current mission launcher mode.
    fileprivate(set) var missionLauncherMode: MissionLauncherMode = .preset
    /// Current alert panel mode.
    fileprivate(set) var alertPanelMode: AlertPanelMode = .preset
    /// Boolean describing if Flight Plan mode is active.
    fileprivate(set) var isFlightPlanPanelRequired: Bool = false
    /// Boolean to force hide Flight Plan panel.
    fileprivate(set) var forceHidePanel: Bool = false
    /// Boolean describing if hand launch need to be hidden when a modal is presented.
    fileprivate(set) var isOverContextModalPresented: Bool = false

    /// Boolean describing if flight plan panel should be opened.
    var shouldDisplayFlightPlanPanel: Bool {
        return isFlightPlanPanelRequired
            && missionLauncherMode == .closed
            && alertPanelMode == .closed
            && !forceHidePanel
            && !isOverContextModalPresented
    }

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - missionLauncherMode: current mission launcher mode
    ///    - alertPanelMode: current alert panel mode
    ///    - isFlightPlanActive: whether flight plan is currently active
    ///    - forceHidePanel: whether panel should be force hidden
    ///    - isOverContextModalPresented: whether panel should be hidden if a modal is presented
    init(missionLauncherMode: MissionLauncherMode,
         alertPanelMode: AlertPanelMode,
         isFlightPlanPanelRequired: Bool,
         forceHidePanel: Bool,
         isOverContextModalPresented: Bool) {
        self.missionLauncherMode = missionLauncherMode
        self.alertPanelMode = alertPanelMode
        self.isFlightPlanPanelRequired = isFlightPlanPanelRequired
        self.forceHidePanel = forceHidePanel
        self.isOverContextModalPresented = isOverContextModalPresented
    }

    // MARK: - Equatable
    func isEqual(to other: FlightPlanControlsState) -> Bool {
        return self.missionLauncherMode == other.missionLauncherMode
            && self.alertPanelMode == other.alertPanelMode
            && self.isFlightPlanPanelRequired == other.isFlightPlanPanelRequired
            && self.forceHidePanel == other.forceHidePanel
            && self.isOverContextModalPresented == other.isOverContextModalPresented
    }

    // MARK: - Copying
    func copy() -> FlightPlanControlsState {
        return FlightPlanControlsState(missionLauncherMode: self.missionLauncherMode,
                                       alertPanelMode: self.alertPanelMode,
                                       isFlightPlanPanelRequired: self.isFlightPlanPanelRequired,
                                       forceHidePanel: self.forceHidePanel,
                                       isOverContextModalPresented: self.isOverContextModalPresented)
    }
}

/// View model for `FlightPlanControls`.

final class FlightPlanControlsViewModel: BaseViewModel<FlightPlanControlsState> {
    // MARK: - Private Properties
    private var missionLauncherModeObserver: Any?
    private var alertPanelModeObserver: Any?
    private var panelVisibilityObserver: Any?
    private var missionLauncherViewModel = MissionLauncherViewModel()

    // MARK: - Init
    override init(stateDidUpdate: ((FlightPlanControlsState) -> Void)? = nil) {
        super.init(stateDidUpdate: stateDidUpdate)
        listenMissionLauncherMode()
        listenAlertPanelMode()
        listenMissionLauncherViewModel()
        listenPanelVisibilityChanges()
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.remove(observer: missionLauncherModeObserver)
        missionLauncherModeObserver = nil
        NotificationCenter.default.remove(observer: alertPanelModeObserver)
        alertPanelModeObserver = nil
        NotificationCenter.default.remove(observer: panelVisibilityObserver)
        panelVisibilityObserver = nil
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
private extension FlightPlanControlsViewModel {
    /// Starts watcher for mission launcher open/close mode.
    func listenMissionLauncherMode() {
        missionLauncherModeObserver = NotificationCenter.default.addObserver(
            forName: .missionLauncherModeDidChange,
            object: nil,
            queue: nil) { [weak self] notification in
                guard let missionLauncherMode = notification.userInfo?[MissionLauncherMode.notificationKey] as? MissionLauncherMode else {
                    return
                }
                let copy = self?.state.value.copy()
                copy?.missionLauncherMode = missionLauncherMode
                self?.state.set(copy)
        }
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

    /// Starts watcher for mission mode/submode.
    func listenMissionLauncherViewModel() {
        missionLauncherViewModel.state.valueChanged = { [weak self] state in
            guard let mode = state.mode else {
                return
            }
            let copy = self?.state.value.copy()
            copy?.isFlightPlanPanelRequired = mode.isFlightPlanPanelRequired
            self?.state.set(copy)
        }
    }

    /// Starts watcher for flight plan panel visibility changes.
    func listenPanelVisibilityChanges() {
        panelVisibilityObserver = NotificationCenter.default.addObserver(
            forName: .modalPresentDidChange,
            object: nil,
            queue: nil) { [weak self] notification in
                guard let isModalPresented = notification.userInfo?[BottomBarViewControllerNotifications.notificationKey] as? Bool else {
                    return
                }
                let copy = self?.state.value.copy()
                copy?.isOverContextModalPresented = isModalPresented
                self?.state.set(copy)
        }
    }
}
