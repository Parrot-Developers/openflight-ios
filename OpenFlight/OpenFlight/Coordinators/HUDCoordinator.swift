// Copyright (C) 2020 Parrot Drones SAS
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
open class HUDCoordinator: Coordinator, HistoryMediasAction {
    // MARK: - Public Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public var parentCoordinator: Coordinator?
    public var showMissionLauncherPublisher: AnyPublisher<Bool, Never> { showMissionsLauncherSubject.eraseToAnyPublisher() }
    public var isMissionLauncherShown: Bool { showMissionsLauncherSubject.value }
    public var canShowCellularPairingViews: Bool { criticalAlertViewModel.state.value.alertStack.isEmpty }

    // MARK: - Internal Properties
    private let criticalAlertViewModel = HUDCriticalAlertViewModel()

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
        self.navigationController?.viewControllers = [viewController]
        services.currentMissionManager.modePublisher
            .sink { [unowned self] in
                cleanRightPanel()
                insertRightPanelIfNeeded(mode: $0)
            }
            .store(in: &cancellables)
        services.flight.gutmaWatcher.flightEnded
            .sink { [unowned self] in
                displayFlightReport(flight: $0)
            }
            .store(in: &cancellables)

        criticalAlertViewModel.state.valueChanged = { [weak self] state in
            self?.updateCriticalAlertVisibility(with: state)
        }
    }

    /// Changes critical alert modal visibility regarding view model state.
    ///
    /// - Parameters:
    ///     - state: The alert state
    func updateCriticalAlertVisibility(with state: HUDCriticalAlertState?) {
        guard state?.canShowAlert == true else {
            viewController?.showCellularPinCodeIfNeeded()
            return
        }

        displayCriticalAlert(alert: state?.currentAlert)
    }

    open func canShowCellularPairing() -> Bool {
        return criticalAlertViewModel.state.value.alertStack.isEmpty
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
        self.rightPanelCoordinator = coordinator
        coordinator.parentCoordinator = self

        childNavigationController.view.frame = rightPanelContainerControls.rightPanelContainerView.bounds

        parentViewController.addChild(childNavigationController)
        rightPanelContainerControls.rightPanelContainerView.addSubview(childNavigationController.view)
        childNavigationController.didMove(toParent: parentViewController)
    }

    open func displayAuthentification() {
        // To override.
    }

    open func handleHistoryCellAction(with flightModel: FlightPlanModel, actionType: HistoryMediasActionType) {
        // To override.
    }

    /// Starts dashboard coordinator.
    open func startDashboard() {
        let dashboardCoordinator = DashboardCoordinator(services: services)
        self.presentCoordinatorWithAnimation(childCoordinator: dashboardCoordinator, animationDirection: .fromLeft)
    }

    open func startFlightExecutionDetails(_ execution: FlightPlanModel) {
        let dashboardCoordinator = DashboardCoordinator(services: services)
        self.presentCoordinatorWithAnimation(childCoordinator: dashboardCoordinator, animationDirection: .fromLeft) {
            dashboardCoordinator.startFlightExecutionDetails(execution)
        }
    }
}

// MARK: - HUDNavigation
extension HUDCoordinator {
    // MARK: - Internal

    /// Handle camera sliders view controller to manage its coordination
    /// - Parameter cameraSlidersViewController: the sliders view controller
    func handleCameraSlidersViewController(_ cameraSlidersViewController: CameraSlidersViewController) {
        cameraSlidersCoordinator = CameraSlidersCoordinator(services: services, viewController: cameraSlidersViewController)
    }

    /// Starts settings coordinator.
    ///
    /// - Parameters:
    ///     - type: settings type
    func startSettings(_ type: SettingsType?) {
        let settingsCoordinator = SettingsCoordinator()
        settingsCoordinator.startSettingType = type
        self.presentCoordinatorWithAnimation(childCoordinator: settingsCoordinator, animationDirection: .fromRight)
    }

    /// Starts pairing coordinator.
    func startPairing() {
        let pairingCoordinator = PairingCoordinator(delegate: self)
        pairingCoordinator.parentCoordinator = self
        pairingCoordinator.start()
        self.present(childCoordinator: pairingCoordinator)
    }

    /// Starts drone infos coordinator.
    func startDroneInfos() {
        let droneCoordinator = DroneCoordinator(services: services)
        droneCoordinator.parentCoordinator = self
        droneCoordinator.start()
        self.present(childCoordinator: droneCoordinator)
    }

    /// Starts remote infos coordinator.
    func startRemoteInfos() {
        let remoteCoordinator = RemoteCoordinator()
        remoteCoordinator.parentCoordinator = self
        remoteCoordinator.start()
        self.present(childCoordinator: remoteCoordinator)
    }

    /// Starts drone calibration.
    func startDroneCalibration() {
        let droneCoordinator = DroneCalibrationCoordinator(services: services)
        droneCoordinator.parentCoordinator = self
        droneCoordinator.startWithMagnetometerCalibration()
        self.present(childCoordinator: droneCoordinator)
    }

    /// Displays remote shutdown alert screen.
    func displayRemoteAlertShutdown() {
        presentModal(viewController: RemoteShutdownAlertViewController.instantiate(coordinator: self))
    }

    /// Displays a critical alert on the screen.
    ///
    /// - Parameters:
    ///     - alert: the alert to display
    func displayCriticalAlert(alert: HUDCriticalAlertType?) {
        let criticalAlertVC = HUDCriticalAlertViewController.instantiate(with: alert)
        criticalAlertVC.delegate = self
        presentModal(viewController: criticalAlertVC)
    }

    /// Displays a flight report on the HUD.
    ///
    /// - Parameters:
    ///     - flight: flight
    func displayFlightReport(flight: FlightModel) {
        let viewModel = FlightDetailsViewModel(service: services.flight.service,
                                               flight: flight,
                                               flightPlanTypeStore: services.flightPlan.typeStore)
        presentModal(viewController: FlightReportViewController.instantiate(viewModel: viewModel))
    }

    /// Displays entry coordinator for current MissionMode.
    ///
    /// - Parameters:
    ///    - mode: current mission mode
    func presentModeEntryCoordinatorIfNeeded(mode: MissionMode) {
        guard let entryCoordinator = mode.entryCoordinatorProvider?() else { return }

        entryCoordinator.parentCoordinator = self
        entryCoordinator.start()
        self.present(childCoordinator: entryCoordinator, overFullScreen: true)
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
        criticalAlertViewModel.onAlertDismissed()
        viewController?.showCellularPinCodeIfNeeded()
    }

    func performAlertAction(alert: HUDCriticalAlertType?) {
        switch alert {
        case .droneAndRemoteUpdateRequired,
             .droneUpdateRequired:
            dismiss()
            criticalAlertViewModel.onAlertDismissed()
            startDroneInfos()
        case .droneCalibrationRequired:
            dismiss()
            criticalAlertViewModel.onAlertDismissed()
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
