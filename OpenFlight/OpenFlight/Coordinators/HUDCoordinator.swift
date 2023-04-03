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
        let viewController = HUDViewController.instantiate(coordinator: self,
                                                           currentMissionManager: services.currentMissionManager,
                                                           airsdkMissionsManager: services.drone.airsdkMissionsManager,
                                                           topBarService: services.ui.hudTopBarService,
                                                           bottomBarService: services.ui.hudBottomBarService,
                                                           pinCodeService: services.drone.pinCodeService,
                                                           rthService: services.drone.rthService,
                                                           panoramaService: services.panoramaService,
                                                           uiComponentsDisplayReporter: services.ui.uiComponentsDisplayReporter,
                                                           ophtalmoService: services.drone.ophtalmoService,
                                                           touchAndFly: services.ui.touchAndFly,
                                                           missionsStore: services.missionsStore,
                                                           connectedDroneHolder: services.connectedDroneHolder)
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
        // Block dedicated to remove the right panel.
        let removeRightPanel = { [weak self] in
            previousContentNavigationController.willMove(toParent: nil)
            previousContentNavigationController.view.removeFromSuperview()
            previousContentNavigationController.removeFromParent()
            self?.rightPanelCoordinator = nil
        }

        // If Project Manager is displayed, dismiss it before removing the right panel.
        if rightPanelCoordinator.childCoordinators.last is ProjectManagerCoordinator {
            rightPanelCoordinator.dismissChildCoordinator(animated: false) { removeRightPanel() }
        } else {
            removeRightPanel()
        }
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

    /// Starts drone details coordinator.
    open func startDroneInformation() {
        // hide mission launcher if it was opened
        hideMissionLauncher()

        // open drone information screen
        let droneCoordinator = DroneCoordinator(services: services)
        droneCoordinator.parentCoordinator = self
        droneCoordinator.start()
        present(childCoordinator: droneCoordinator)
    }

    /// Starts drone calibration.
    open func startDroneCalibration() {
        let droneCoordinator = DroneCalibrationCoordinator(services: services)
        droneCoordinator.parentCoordinator = self
        droneCoordinator.startWithMagnetometerCalibration()
        present(childCoordinator: droneCoordinator)
    }

    /// Starts ophtalmo coordinator if view is not displayed.
    open func startOphtalmo() {
        // check if viewIsDisplayed
        if (childCoordinators.last as? OphtalmoCoordinator) == nil {
            let ophtalmoCoordinator = OphtalmoCoordinator(services: Services.hub)
            presentCoordinatorWithAnimator(childCoordinator: ophtalmoCoordinator)
        }
    }

    /// Starts settings coordinator.
    ///
    /// - Parameters:
    ///    - type: settings type
    open func startSettings(_ type: SettingsType?) {
        // hide mission launcher if it was opened
        hideMissionLauncher()

        // open settings screen
        let settingsCoordinator = SettingsCoordinator(services: services)
        settingsCoordinator.startSettingType = type
        presentCoordinatorWithAnimator(childCoordinator: settingsCoordinator)
    }

    /// Shows formatting screen.
    func showFormattingScreen() {
        let formattingCoordinator = FormattingCoordinator(userStorageService: services.media.userStorageService)
        formattingCoordinator.parentCoordinator = self
        formattingCoordinator.start()
        present(childCoordinator: formattingCoordinator, overFullScreen: true)
    }

    /// Returns to the previous displayed view according navigation stack service.
    ///
    /// - Parameters:
    ///   - completion: The completion block
    open func returnToPreviousView(completion: (() -> Void)? = nil) {

        // When leaving the "main" HUD, we must store the current mission to restore it, when coming back, if needed.
        if isMainHud { services.currentMissionManager.storeCurrentMissionAsLatestHudSelection() }

        let coordinators = services.ui.navigationStack.coordinators(services: services, hudCoordinator: self)
        guard !coordinators.isEmpty else {
            startDashboard()
            completion?()
            return
        }

        presentCoordinatorsStack(coordinators: coordinators, transitionSubtype: .fromLeft, completion: completion)
    }

    /// Wether the current HUD is the main or the one used to display a project from the dashboard's project manager.
    var isMainHud: Bool {
        // The presence of a project manager instance in the navigation stack
        // means the current HUD is not the "main" but a view to display a project.
        services.ui.navigationStack.coordinators(services: services,
                                                 hudCoordinator: self)
        .first { $0 is ProjectManagerCoordinator } == nil
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

    /// Starts pairing coordinator.
    func startPairing() {
        let pairingCoordinator = PairingCoordinator(services: services,
                                                    delegate: self)
        pairingCoordinator.parentCoordinator = self
        pairingCoordinator.start()
        present(childCoordinator: pairingCoordinator)
    }

    /// Starts remote details coordinator.
    func startRemoteInformation() {
        // hide mission launcher if it was opened
        hideMissionLauncher()

        // open remote information screen
        let remoteCoordinator = RemoteCoordinator(services: services)
        remoteCoordinator.parentCoordinator = self
        remoteCoordinator.start()
        present(childCoordinator: remoteCoordinator)
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
        let viewModel = CellularAccessCardPinViewModel(coordinator: self,
                                                       currentDroneHolder: services.currentDroneHolder,
                                                       pinCodeService: services.drone.pinCodeService,
                                                       cellularService: services.drone.cellularService)
        presentModal(viewController: CellularAccessCardPinViewController.instantiate(viewModel: viewModel))
    }

    /// Shows the mission launcher.
    func showMissionLauncher() {
        viewController?.missionControls.showMissionLauncher()
        showMissionsLauncherSubject.value = true
    }

    /// Hides the mission launcher.
    public func hideMissionLauncher() {
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
        case .sdCardNeedsFormat:
            dismiss()
            services.ui.criticalAlert.dismissCurrentAlert()
            showFormattingScreen()
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
