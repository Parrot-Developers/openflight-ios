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

// MARK: - Protocols
public protocol FlightPlanEditionViewControllerDelegate: AnyObject {
    /// Starts flight plan edition mode.
    ///
    /// - Parameters:
    ///    - shouldCenter: should center position on map
    func startFlightPlanEdition(shouldCenter: Bool)

    /// Starts a new flight plan.
    ///
    /// - Parameters:
    ///    - flightPlanProvider: flight plan provider
    ///    - creationCompletion: call back that returns if a flight plan have been created
    func startNewFlightPlan(flightPlanProvider: FlightPlanProvider,
                            creationCompletion: @escaping (_ createNewFp: Bool) -> Void)
}

/// Protocol for `ManagePlansViewController` navigation.
public protocol FlightPlanManagerCoordinator: AnyObject {
    /// Starts manage plans modal.
    func startManagePlans()

    /// Starts Flight Plan history modal.
    ///
    /// - Parameters:
    ///     - flightPlanViewModel: Flight Plan ViewModel
    func startFlightPlanHistory(flightPlanViewModel: FlightPlanViewModel)

}

/// Coordinator for flight plan planel.
public final class FlightPlanPanelCoordinator: Coordinator,
                                               FlightPlanEditionViewControllerDelegate {
    // MARK: - Public Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public var parentCoordinator: Coordinator?
    public weak var flightPlanEditionViewController: FlightPlanEditionViewController?

    // MARK: - Private Properties
    private var splitControls: SplitControls?
    private var flightPlanControls: FlightPlanControls?
    private var managePlansViewModel: ManagePlansViewModel?

    // MARK: - Public Funcs
    public func start() {
        assert(false) // Forbidden start
    }

    /// Starts the coordinator with the flight plan panel view controller.
    ///
    /// - Parameters:
    ///     - flightPlanPanelVC: flight plan panel view controller
    ///     - splitControls: split controls
    ///     - flightPlanControls: flight plan controls
    func start(flightPlanPanelVC: FlightPlanPanelViewController,
               splitControls: SplitControls,
               flightPlanControls: FlightPlanControls) {
        flightPlanPanelVC.coordinator = self
        self.splitControls = splitControls
        self.flightPlanControls = flightPlanControls
        self.navigationController = NavigationController(rootViewController: flightPlanPanelVC)
        self.navigationController?.isNavigationBarHidden = true
    }

    /// Displays the execution summary screen if there is one in the Flight Plan Provider.
    ///
    /// - Parameters:
    ///     - executionId: id of flight plan execution
    ///     - flightPlanProvider: Flight Plan Provider
    public func startExecutionSummary(executionId: String, flightPlanProvider: FlightPlanProvider) {
        guard let execution = CoreDataManager.shared.execution(forExecutionId: executionId),
              let executionSummaryVC = flightPlanProvider.executionSummaryVC(execution: execution, coordinator: self),
              navigationController?.viewControllers.count == 1 else {
            return
        }

        push(executionSummaryVC, animated: true)
    }
}

// MARK: - FlightPlanEditionViewControllerDelegate
public extension FlightPlanPanelCoordinator {
    func startFlightPlanEdition(shouldCenter: Bool = false) {
        guard let splitControls = splitControls,
              let mapViewController = splitControls.mapViewController else { return }
        if shouldCenter {
            mapViewController.centerMapOnDroneOrUser()
        }
        flightPlanControls?.viewModel.forceHidePanel(true)
        self.startFlightPlanEdition(mapViewController: mapViewController,
                                    mapViewRestorer: splitControls)
    }

    func centerMapViewController() {
        guard let splitControls = splitControls,
            let mapViewController = splitControls.mapViewController else { return }
        mapViewController.centerMapOnDroneOrUser()
    }

    func startNewFlightPlan(flightPlanProvider: FlightPlanProvider,
                            creationCompletion: @escaping (_ createNewFp: Bool) -> Void) {
        guard let flightPlanCoordinator = flightPlanProvider.flightPlanCoordinator else { return }

        // center map on user
        if let splitControls = splitControls, let mapViewController = splitControls.mapViewController {
            mapViewController.centerMapOnDroneOrUser()
        }
        flightPlanCoordinator.parentCoordinator = self
        flightPlanCoordinator.startNewFlightPlan(flightPlanProvider: flightPlanProvider, creationCompletion: creationCompletion)
        self.present(childCoordinator: flightPlanCoordinator, overFullScreen: true)
    }
}

// MARK: - FlightPlanManagerCoordinator
extension FlightPlanPanelCoordinator: FlightPlanManagerCoordinator {
    public func startManagePlans() {
        guard let fpProvider = Services.hub.currentMissionManager.mode.flightPlanProvider else { return }
        let viewModel = ManagePlansViewModel(
            delegate: self,
            flightPlanProvider: fpProvider,
            persistence: CoreDataManager.shared,
            manager: FlightPlanManager.shared
        )

        let flightPlanListviewModel = FlightPlansListViewModel(persistence: CoreDataManager.shared)
        viewModel.setupFlightPlanListviewModel(viewModel: flightPlanListviewModel)

        let viewController = ManagePlansViewController.instantiate(viewModel: viewModel)
        let coordinator: Coordinator
        if let child = self.childCoordinators.first(where: { $0 is FlightPlanEditionCoordinator }) {
            coordinator = child
        } else {
            coordinator = self
        }

        // Add right presentation animation.
        // This could be improved by writing a custom modal presentation.
        let transition = CATransition()
        transition.duration = Style.shortAnimationDuration
        transition.type = CATransitionType.moveIn
        transition.subtype = .fromRight
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        coordinator.navigationController?.view.window?.layer.add(transition, forKey: kCATransition)

        coordinator.presentModal(viewController: viewController, animated: false)
        NotificationCenter.default.post(name: .modalPresentDidChange,
                                        object: self,
                                        userInfo: [BottomBarViewControllerNotifications.notificationKey: true])
        // The view model will immediately configure the VC on start, start only when everything is installed
        viewModel.start()

        self.managePlansViewModel = viewModel // Just retaining
    }

    public func startFlightPlanHistory(flightPlanViewModel: FlightPlanViewModel) {
        let viewController = FlightPlanFullHistoryViewController.instantiate(coordinator: self,
                                                                             viewModel: flightPlanViewModel)
        presentModal(viewController: viewController)
    }

}

// MARK: - Privates Funcs
private extension FlightPlanPanelCoordinator {
    /// Starts flight plan edition coordinator.
    ///
    /// - Parameters:
    ///    - mapViewController: controller for the map
    ///    - mapViewRestorer: restorer for the map
    ///
    /// Note: these parameters are needed because, when entering
    /// Flight Plan edition, map view is transferred to the new
    /// view controller. Map is restored back to its original
    /// container afterwards with `MapViewRestorer` protocol.
    func startFlightPlanEdition(mapViewController: MapViewController,
                                mapViewRestorer: MapViewRestorer) {
        let flightPlanEditionCoordinator = FlightPlanEditionCoordinator()
        flightPlanEditionCoordinator.parentCoordinator = self
        flightPlanEditionCoordinator.start(panelCoordinator: self,
                                           mapViewController: mapViewController,
                                           mapViewRestorer: mapViewRestorer)
        self.present(childCoordinator: flightPlanEditionCoordinator, animated: false)
    }
}

extension FlightPlanPanelCoordinator: ManagePlansViewModelDelegate {
    /// Closes manage plans view.
    ///
    /// - Parameters:
    ///     - shouldStartEdition: should start flight plan edition
    ///     - shouldCenter: should center position on map
    func endManagePlans(shouldStartEdition: Bool, shouldCenter: Bool) {
        let coordinator: Coordinator
        if let child = self.childCoordinators.first(where: { $0 is FlightPlanEditionCoordinator }) {
            coordinator = child
        } else {
            coordinator = self
        }
        coordinator.dismiss(animated: false) { [weak self] in
            if shouldStartEdition, !(coordinator is FlightPlanEditionCoordinator) {
                self?.startFlightPlanEdition()
            }
            if shouldCenter {
                self?.centerMapViewController()
            }

            self?.flightPlanEditionViewController?.checkIfEditionNecesary()
        }

        // Release the VM
        self.managePlansViewModel = nil
        // Notify observers about flight plan modal's visibility status.
        NotificationCenter.default.post(name: .modalPresentDidChange,
                                        object: self,
                                        userInfo: [BottomBarViewControllerNotifications.notificationKey: false])
    }
}
