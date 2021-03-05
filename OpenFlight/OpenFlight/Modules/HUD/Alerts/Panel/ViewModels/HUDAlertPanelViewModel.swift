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

/// State for `HUDAlertPanelViewModel`.
open class HUDAlertPanelState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    // TODO: rework this when a stack of current alert is defined.
    /// Hand Launch state.
    fileprivate(set) public var handLaunchState = HUDAlertPanelHandLaunchState()
    /// Hand Land state.
    fileprivate(set) public var handLandState = HUDAlertPanelHandLandState()
    /// Return Home state.
    fileprivate(set) public var returnHomeState = HUDAlertPanelReturnHomeState()
    /// Current mission launcher mode.
    fileprivate(set) public var currentMissionLauncherMode = MissionLauncherMode.preset
    /// Boolean describing if an overcontext modal is presented.
    fileprivate(set) public var isOverContextModalPresented: Bool = false

    /// Whether alert should be shown.
    open var canShowAlert: Bool {
        return currentMissionLauncherMode == .closed
            && shouldShowAlertPanel
            && !isOverContextModalPresented
    }

    /// Tells if an alert is available.
    open var shouldShowAlertPanel: Bool {
        return handLaunchState.shouldShowAlertPanel
            || handLandState.shouldShowAlertPanel
            || returnHomeState.shouldShowAlertPanel
    }

    /// Returns alert to display by priority.
    open var currentAlert: AlertPanelState? {
        if returnHomeState.shouldShowAlertPanel {
            return returnHomeState
        } else if handLaunchState.shouldShowAlertPanel {
            return handLaunchState
        } else if handLandState.shouldShowAlertPanel {
            return handLandState
        } else {
            return nil
        }
    }

    // MARK: - Init
    required public init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - handLaunchState: current Hand Launch state
    ///    - handLandState: current Hand Land state
    ///    - returnHomeState: current Return Home state
    ///    - currentMissionLauncherMode: current mission launcher mode
    ///    - isOverContextModalPresented: hand launch visibility state when modal is presented
    public init(handLaunchState: HUDAlertPanelHandLaunchState,
                handLandState: HUDAlertPanelHandLandState,
                returnHomeState: HUDAlertPanelReturnHomeState,
                currentMissionLauncherMode: MissionLauncherMode,
                isOverContextModalPresented: Bool) {
        self.handLaunchState = handLaunchState
        self.handLandState = handLandState
        self.returnHomeState = returnHomeState
        self.currentMissionLauncherMode = currentMissionLauncherMode
        self.isOverContextModalPresented = isOverContextModalPresented
    }

    // MARK: - Equatable
    open func isEqual(to other: HUDAlertPanelState) -> Bool {
        return self.handLaunchState == other.handLaunchState
            && self.handLandState == other.handLandState
            && self.returnHomeState == other.returnHomeState
            && self.currentMissionLauncherMode == other.currentMissionLauncherMode
            && self.isOverContextModalPresented == other.isOverContextModalPresented
    }

    // MARK: - Copying
    open func copy() -> Self {
        if let copy = HUDAlertPanelState(handLaunchState: self.handLaunchState,
                                         handLandState: self.handLandState,
                                         returnHomeState: self.returnHomeState,
                                         currentMissionLauncherMode: self.currentMissionLauncherMode,
                                         isOverContextModalPresented: self.isOverContextModalPresented) as? Self {
            return copy
        } else {
            fatalError("Must override")
        }
    }
}

/// View model for HUD's left alert panel.
open class HUDAlertPanelViewModel<T: HUDAlertPanelState>: BaseViewModel<T> {
    // MARK: - Private Properties
    private var handLaunchViewModel: HUDAlertPanelHandLaunchViewModel = HUDAlertPanelHandLaunchViewModel()
    private var handLandViewModel: HUDAlertPanelHandLandViewModel = HUDAlertPanelHandLandViewModel()
    private var returnHomeViewModel: HUDAlertPanelReturnHomeViewModel = HUDAlertPanelReturnHomeViewModel()
    private var missionLauncherModeObserver: Any?
    private var modalPresentationObserver: Any?

    // MARK: - Init
    public init(stateDidUpdate: ((HUDAlertPanelState) -> Void)? = nil) {
        super.init(stateDidUpdate: stateDidUpdate)

        listenHandLaunch()
        listenHandLand()
        listenReturnHome()
        listenMissionLauncherModeChanges()
        observeModalPresentation()
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.remove(observer: missionLauncherModeObserver)
        missionLauncherModeObserver = nil
        NotificationCenter.default.remove(observer: modalPresentationObserver)
        modalPresentationObserver = nil
    }

    // MARK: - Public Funcs
    /// Starts action.
    open func startAction() {
        if handLaunchViewModel.state.value.state == .available {
            handLaunchViewModel.startAction()
        } else if handLandViewModel.state.value.state == .available {
            handLandViewModel.startAction()
        } else if returnHomeViewModel.state.value.state == .available {
            returnHomeViewModel.startAction()
        }
    }

    /// Cancels action.
    open func cancelAction() {
        handLaunchViewModel.cancelAction()
        returnHomeViewModel.cancelAction()
        handLandViewModel.cancelAction()
    }
}

// MARK: - Private Funcs
private extension HUDAlertPanelViewModel {
    /// Starts watcher for hand launch.
    func listenHandLaunch() {
        handLaunchViewModel.state.valueChanged = { [weak self] state in
            let copy = self?.state.value.copy()
            copy?.handLaunchState = state
            self?.alertPanelDisplayed(isPresented: state.shouldShowAlertPanel == true)
            self?.state.set(copy)
        }
    }

    /// Starts watcher for Hand Land.
    func listenHandLand() {
        handLandViewModel.state.valueChanged = { [weak self] state in
            let copy = self?.state.value.copy()
            copy?.handLandState = state
            self?.alertPanelDisplayed(isPresented: state.shouldShowAlertPanel == true)
            self?.state.set(copy)
        }
    }

    /// Starts watcher for Return home.
    func listenReturnHome() {
        returnHomeViewModel.state.valueChanged = { [weak self] state in
            let copy = self?.state.value.copy()
            copy?.returnHomeState = state
            self?.state.set(copy)
        }
    }

    /// Starts watcher for mission launcher mode changes.
    func listenMissionLauncherModeChanges() {
        missionLauncherModeObserver = NotificationCenter.default.addObserver(
            forName: .missionLauncherModeDidChange,
            object: nil,
            queue: nil) { [weak self] notification in
            guard let missionLauncherMode = notification.userInfo?[MissionLauncherMode.notificationKey] as? MissionLauncherMode else {
                return
            }

            let copy = self?.state.value.copy()
            copy?.currentMissionLauncherMode = missionLauncherMode
            self?.state.set(copy)
        }
    }

    /// Starts watcher for modal presentation.
    func observeModalPresentation() {
        modalPresentationObserver = NotificationCenter.default.addObserver(
            forName: .modalPresentDidChange,
            object: nil,
            queue: nil) { [weak self] notification in
            guard let shouldHide = notification.userInfo?[BottomBarViewControllerNotifications.notificationKey] as? Bool else {
                return
            }

            let copy = self?.state.value.copy()
            copy?.isOverContextModalPresented = shouldHide
            self?.state.set(copy)
        }
    }

    /// Notify if the Hand Land or Hand Launch panel is displayed.
    ///
    /// - Parameters:
    ///     - isPresented: true if the modal is presented
    func alertPanelDisplayed(isPresented: Bool) {
        NotificationCenter.default.post(name: .handDetectedAlertModalPresentDidChange,
                                        object: self,
                                        userInfo: [HUDPanelNotifications.handDetectedNotificationKey: isPresented])
    }
}
