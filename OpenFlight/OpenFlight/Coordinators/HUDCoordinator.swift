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

import SwiftyUserDefaults
import Combine

/// Coordinator for HUD part.
open class HUDCoordinator: Coordinator {
    // MARK: - Public Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public weak var parentCoordinator: Coordinator?
    public var showMissionLauncherPublisher: AnyPublisher<Bool, Never> { showMissionsLauncherSubject.eraseToAnyPublisher() }
    public var isMissionLauncherShown: Bool { showMissionsLauncherSubject.value }

    // MARK: - Private Properties
    public private(set) unowned var services: ServiceHub
    private weak var viewController: HUDViewController!
    private var cameraSlidersCoordinator: CameraSlidersCoordinator?
    private var rightPanelCoordinator: Coordinator?
    private var cancellables = Set<AnyCancellable>()
    private var showMissionsLauncherSubject = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Init
    public init(services: ServiceHub) {
        self.services = services
    }

    // MARK: - Public Funcs
    open func start() {
        let viewController = HUDViewController.instantiate(coordinator: self)
        self.viewController = viewController
        viewController.loadViewIfNeeded()
        navigationController?.viewControllers = [viewController]
        if AppUtils.isLayoutGridAuthorized {
            // HUD VC is directly affected to navigationController stack.
            // LayoutGridVC won't be added through any Coordinator's presenting operation.
            // => Need to directly overlay grid on VC.
            if let navigationController = navigationController {
                DispatchQueue.main.async {
                    LayoutGridView().overlay(on: navigationController)
                }
            }
        }
        setupIndicator()
        services.currentMissionManager.modePublisher
            .sink { [unowned self] in
                cleanRightPanel()
                insertRightPanelIfNeeded(mode: $0)
                Services.hub.ui.hudTopBarService.allowTopBarDisplay()
            }
            .store(in: &cancellables)

        services.ui.criticalAlert.alertPublisher
            .removeDuplicates()
            .sink { [unowned self] in
                displayCriticalAlert(alert: $0)
            }
            .store(in: &cancellables)

        listenCameraRecordingState()
        listenCameraPhotoCaptureState()
    }

    open func setupIndicator() {
        setupCustomIndicator(customIndicatorProvider: nil)
    }

    open func setupCustomIndicator(customIndicatorProvider: CustomIndicatorProvider?) {
        viewController.setupCustomMessageProvider(customMessageProvider: customIndicatorProvider)
    }

    func cleanRightPanel() {
        guard let rightPanelCoordinator = rightPanelCoordinator,
              let previousContentNavigationController = rightPanelCoordinator.navigationController else { return }
        previousContentNavigationController.willMove(toParent: nil)
        previousContentNavigationController.view.removeFromSuperview()
        previousContentNavigationController.removeFromParent()
        self.rightPanelCoordinator = nil
    }

    func insertRightPanelIfNeeded(mode: MissionMode) {
        let rightPanelContainerControls: RightPanelContainerControls = viewController.rightPanelContainerControls
        let splitControls: SplitControls = viewController.splitControls
        guard mode.isRightPanelRequired,
              let coordinator = mode.hudRightPanelContentProvider(services, splitControls, rightPanelContainerControls),
              let parentViewController = viewController,
              let childNavigationController = coordinator.navigationController else { return }
        rightPanelCoordinator = coordinator
        coordinator.parentCoordinator = self

        childNavigationController.view.frame = rightPanelContainerControls.rightPanelContainerView.bounds

        parentViewController.addChild(childNavigationController)
        rightPanelContainerControls.rightPanelContainerView.addSubview(childNavigationController.view)
        childNavigationController.didMove(toParent: parentViewController)
    }

    /// Starts dashboard coordinator.
    open func startDashboard() {
        let dashboardCoordinator = DashboardCoordinator(services: services)
        presentCoordinatorWithAnimator(childCoordinator: dashboardCoordinator, transitionSubtype: .fromLeft)
        services.ui.navigationStack.add(.dashboard)
    }

    /// Returns dashboard coordinator.
    open func dashboardCoordinator() -> Coordinator { DashboardCoordinator(services: services) }

    /// Returns to the previous displayed view according navigation stack service.
    ///
    /// - Parameters:
    ///   - completion: The completion block
    open func returnToPreviousView(completion: (() -> Void)? = nil) {
        let coordinators = services.ui.navigationStack.coordinators(services: services, hudCoordinator: self)
        guard !coordinators.isEmpty else {
            startDashboard()
            return
        }
        presentCoordinatorsStack(coordinators: coordinators, transitionSubtype: .fromLeft) { [weak self] in
            guard let self = self else { return }
            // Restore HUD with last opened Mission
            self.services.currentMissionManager.restoreLastHudSelection()
            completion?()
        }
    }

    /// Listens camera recording state changes
    func listenCameraRecordingState() {
        services.drone.cameraRecordingService.statePublisher
            .sink { [unowned self] state in
                guard let alertType = state.alertType else { return }
                displayCriticalAlert(alert: alertType)
            }
            .store(in: &cancellables)
    }

    /// Listens camera photo capture state changes.
    func listenCameraPhotoCaptureState() {
        services.drone.cameraPhotoCaptureService.statePublisher
            .sink { [unowned self] state in
                guard let alertType = state.alertType else { return }
                displayCriticalAlert(alert: alertType)
            }
            .store(in: &cancellables)
    }

    /// Displays top critical alert if present in CriticalAlertService.
    /// (Used to flush any potential alert that could not be displayed when triggered.)
    func displayCriticalAlertsIfNeeded() {
        displayCriticalAlert(alert: services.ui.criticalAlert.alert)
    }
}

// MARK: - HUD Navigation
extension HUDCoordinator {
    // MARK: - Internal

    /// Handles camera sliders view controller to manage its coordination.
    ///
    /// - Parameters:
    ///    - cameraSlidersViewController: the sliders view controller
    func handleCameraSlidersViewController(_ cameraSlidersViewController: CameraSlidersViewController) {
        cameraSlidersCoordinator = CameraSlidersCoordinator(services: services, viewController: cameraSlidersViewController)
    }

    /// Starts settings coordinator.
    ///
    /// - Parameters:
    ///    - type: settings type
    func startSettings(_ type: SettingsType?) {
        let settingsCoordinator = SettingsCoordinator()
        settingsCoordinator.startSettingType = type
        presentCoordinatorWithAnimator(childCoordinator: settingsCoordinator)
    }

    /// Starts pairing coordinator.
    func startPairing() {
        let pairingCoordinator = PairingCoordinator(delegate: self)
        pairingCoordinator.parentCoordinator = self
        pairingCoordinator.start()
        present(childCoordinator: pairingCoordinator)
    }

    /// Starts drone details coordinator.
    func startDroneInformation() {
        let droneCoordinator = DroneCoordinator(services: services)
        droneCoordinator.parentCoordinator = self
        droneCoordinator.start()
        present(childCoordinator: droneCoordinator)
    }

    /// Starts remote details coordinator.
    func startRemoteInformation() {
        let remoteCoordinator = RemoteCoordinator()
        remoteCoordinator.parentCoordinator = self
        remoteCoordinator.start()
        present(childCoordinator: remoteCoordinator)
    }

    /// Starts drone calibration.
    func startDroneCalibration() {
        let droneCoordinator = DroneCalibrationCoordinator(services: services)
        droneCoordinator.parentCoordinator = self
        droneCoordinator.startWithMagnetometerCalibration()
        present(childCoordinator: droneCoordinator)
    }

    /// Displays remote shutdown alert screen.
    func displayRemoteAlertShutdown() {
        let remoteShutdown = RemoteShutdownAlertViewController.instantiate()
        UIApplication.topViewController()?.navigationController?.present(remoteShutdown, animated: true)
    }

    /// Displays a critical alert on the screen.
    ///
    /// - Parameters:
    ///    - alert: the alert to display
    func displayCriticalAlert(alert: HUDCriticalAlertType?) {
        // Dismiss currently displayed alert (if any) in order to be able to present new one.
        if let alertVc = navigationController?.presentedViewController as? HUDCriticalAlertViewController,
           alertVc.currentAlert != alert {
            dismiss { self.displayCriticalAlert(alert: alert) }
            return
        }

        if let alert = alert {
            let criticalAlertVC = HUDCriticalAlertViewController.instantiate(with: alert)
            criticalAlertVC.delegate = self
            presentModal(viewController: criticalAlertVC)
        }
    }

    /// Displays entry coordinator for current MissionMode.
    ///
    /// - Parameters:
    ///    - mode: current mission mode
    func presentModeEntryCoordinatorIfNeeded(mode: MissionMode) {
        guard let entryCoordinator = mode.entryCoordinatorProvider?() else { return }

        entryCoordinator.parentCoordinator = self
        entryCoordinator.start()
        present(childCoordinator: entryCoordinator, overFullScreen: true)
    }

    /// Displays cellular pin code modal.
    func displayCellularPinCode() {
        presentModal(viewController: CellularAccessCardPinViewController.instantiate(coordinator: self))
    }

    func showMissionLauncher() {
        viewController?.missionControls.showMissionLauncher()
        showMissionsLauncherSubject.value = true
    }

    func hideMissionLauncher() {
        viewController?.missionControls.hideMissionLauncher()
        showMissionsLauncherSubject.value = false
    }
}

// MARK: - HUDCriticalAlertDelegate
extension HUDCoordinator: HUDCriticalAlertDelegate {
    func dismissAlert() {
        dismiss()
        services.ui.criticalAlert.dismissCurrentAlert()
    }

    func performAlertAction(alert: HUDCriticalAlertType?) {
        switch alert {
        case .droneAndRemoteUpdateRequired,
             .droneUpdateRequired:
            dismiss()
            services.ui.criticalAlert.dismissCurrentAlert()
            startDroneInformation()
        case .remoteUpdateRequired:
            dismiss()
            services.ui.criticalAlert.dismissCurrentAlert()
            startRemoteInformation()
        case .droneCalibrationRequired:
            dismiss()
            services.ui.criticalAlert.dismissCurrentAlert()
            startDroneCalibration()
        default:
            dismissAlert()
        }
    }
}

extension HUDCoordinator: PairingCoordinatorDelegate {
    public func pairingDidFinish() {
        dismissChildCoordinator()
    }
}
