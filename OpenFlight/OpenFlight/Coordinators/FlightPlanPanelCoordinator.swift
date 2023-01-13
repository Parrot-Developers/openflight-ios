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

/// Protocol for `ManagePlansViewController` navigation.
public protocol FlightPlanManagerCoordinator: AnyObject {
    /// Starts manage plans modal.
    func startManagePlans()

    /// Starts Flight Plan history modal.
    ///
    /// - Parameters:
    ///    - projectModel: Flight Plan project
    func startFlightPlanHistory(projectModel: ProjectModel)
}

/// Coordinator for flight plan planel.
public final class FlightPlanPanelCoordinator: Coordinator {
    // MARK: - Public Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public weak var parentCoordinator: Coordinator?
    public weak var flightPlanEditionViewController: FlightPlanEditionViewController?
    // MARK: - Private Properties
    private let services: ServiceHub
    private var splitControls: SplitControls?
    private var rightPanelContainerControls: RightPanelContainerControls?

    // MARK: - Public Funcs
    public func start() {
        assert(false) // Forbidden start
    }

    public init(services: ServiceHub) {
        self.services = services
    }

    /// Starts the coordinator with the flight plan panel view controller.
    ///
    /// - Parameters:
    ///    - splitControls: split controls
    ///    - rightPanelContainerControls: flight plan controls
    public func start(splitControls: SplitControls,
                      rightPanelContainerControls: RightPanelContainerControls) {

        // FlightPlanPanel : ViewModel
        let viewModel = FlightPlanPanelViewModel(projectManager: services.flightPlan.projectManager,
                                                 runStateProgress: services.flightPlan.run,
                                                 currentMissionManager: services.currentMissionManager,
                                                 flightService: services.flight.service,
                                                 coordinator: self,
                                                 rthSettingsMonitor: services.rthSettingsMonitor,
                                                 splitControls: splitControls)
        // FlightPlanPanel : ViewController + viewModel
        let flightPlanPanelVC = FlightPlanPanelViewController.instantiate(flightPlanPanelViewModel: viewModel)

        self.splitControls = splitControls
        rightPanelContainerControls.splitControls = splitControls
        self.rightPanelContainerControls = rightPanelContainerControls
        navigationController = NavigationController(rootViewController: flightPlanPanelVC)
        navigationController?.isNavigationBarHidden = true
    }
}

// MARK: - FlightPlanPanelCoordinator
public extension FlightPlanPanelCoordinator {
    func startFlightPlanEdition(centerMapOnDroneOrUser: Bool = false) {
        guard let splitControls = splitControls else { return }

        if let mapViewController = splitControls.commonMapViewController as? FlightPlanMapViewController {
            showHudControls(show: false) // Hide HUD controls in edition mode.
            startFlightPlanEdition(mapViewController: mapViewController)
        } else if let sceneViewController = splitControls.commonMapViewController as? FlightPlanSceneViewController {
            showHudControls(show: false) // Hide HUD controls in edition mode.
            startFlightPlanEdition(mapViewController: sceneViewController)
        }
    }

    func back(animated: Bool = true) {
        navigationController?.popViewController(animated: animated)
    }

    /// Show HUD controls or map VC navigation bar according to `show` parameter.
    ///
    /// - Parameter show: whether HUD controls should be shown
    func showHudControls(show: Bool) {
        guard let splitControls = splitControls else { return }

        if show {
            services.ui.hudTopBarService.allowTopBarDisplay()
        } else {
            services.ui.hudTopBarService.forbidTopBarDisplay()
        }
        splitControls.commonMapViewController?.navBarView.isHidden = show
        splitControls.hideCameraSliders(hide: !show)
        splitControls.hideBottomBar(hide: !show)
    }
}

// MARK: - FlightPlanManagerCoordinator
extension FlightPlanPanelCoordinator: FlightPlanManagerCoordinator {
    public func startManagePlans() {
        let selectedProject = services.flightPlan.projectManager.currentProject
        let projectManagerCoordinator = ProjectManagerCoordinator(flightPlanServices: services.flightPlan,
                                                                  uiServices: services.ui,
                                                                  cloudSynchroWatcher: services.cloudSynchroWatcher,
                                                                  defaultSelectedProject: selectedProject)
        projectManagerCoordinator.parentCoordinator = self
        projectManagerCoordinator.start()
        present(childCoordinator: projectManagerCoordinator, completion: {})
    }

    public func startFlightPlanHistory(projectModel: ProjectModel) {
        guard let splitControls = splitControls,
              let mapViewController = splitControls.commonMapViewController else { return }

        // FP history panel uses map VC navigation bar instead of HUD top bar.
        services.ui.hudTopBarService.forbidTopBarDisplay()
        showNavBar(show: true)

        if let viewController = (mapViewController as? FlightPlanMapViewController)?.executionsListProvider(
            delegate: self,
            flightPlanHandler: services.flightPlan.manager,
            projectManager: services.flightPlan.projectManager,
            projectModel: projectModel,
            flightService: services.flight.service,
            flightPlanRepo: services.repos.flightPlan,
            topBarService: services.ui.hudTopBarService) {
            navigationController?.pushViewController(viewController, animated: true)
        } else if let viewController = (mapViewController as? FlightPlanSceneViewController)?.executionsListProvider(
            delegate: self,
            flightPlanHandler: services.flightPlan.manager,
            projectManager: services.flightPlan.projectManager,
            projectModel: projectModel,
            flightService: services.flight.service,
            flightPlanRepo: services.repos.flightPlan,
            topBarService: services.ui.hudTopBarService) {
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

// MARK: - Privates Funcs
private extension FlightPlanPanelCoordinator {
    /// Starts flight plan edition coordinator.
    ///
    /// - Parameters:
    ///    - mapViewController: controller for the map
    func startFlightPlanEdition(mapViewController: FlightPlanMapViewController) {
        let viewController = mapViewController
            .editionProvider(panelCoordinator: self,
                             flightPlanServices: services.flightPlan,
                             navigationStack: services.ui.navigationStack)

        // Ensure that last VC of navigation stack is not of same type as `editionProvider`
        // in order to avoid incorrectly pushing same VC twice (may occur on potential
        // double taps on Edition button).
        if let lastVC = navigationController?.viewControllers.last,
           type(of: viewController) == type(of: lastVC) {
            // `viewController` is already last VC of navigation stack => exit.
            return
        }

        navigationController?.pushViewController(viewController, animated: true)
    }

    /// Starts flight plan edition coordinator.
    ///
    /// - Parameters:
    ///    - mapViewController: controller for the map
    func startFlightPlanEdition(mapViewController: FlightPlanSceneViewController) {
        let viewController = mapViewController
            .editionProvider(panelCoordinator: self,
                             flightPlanServices: services.flightPlan,
                             navigationStack: services.ui.navigationStack)

        // Ensure that last VC of navigation stack is not of same type as `editionProvider`
        // in order to avoid incorrectly pushing same VC twice (may occur on potential
        // double taps on Edition button).
        if let lastVC = navigationController?.viewControllers.last,
           type(of: viewController) == type(of: lastVC) {
            // `viewController` is already last VC of navigation stack => exit.
            return
        }

        navigationController?.pushViewController(viewController, animated: true)
    }

    /// Shows map view controller navigation bar if needed.
    ///
    /// - Parameter show: whether the navigation bar needs to be shown
    private func showNavBar(show: Bool) {
        splitControls?.commonMapViewController?.navBarView.isHidden = !show
    }
}

extension FlightPlanPanelCoordinator: ExecutionsListDelegate {
    public func open(flightPlan: FlightPlanModel) {
        back()
        services.flightPlan.projectManager.loadEverythingAndOpen(flightPlan: flightPlan)
    }

    public func startFlightExecutionDetails(_ flightPlan: FlightPlanModel, animated: Bool) {
        let flightPlanExecutionCoordinator =  FlightPlanExecutionDetailsCoordinator(flightPlan: flightPlan,
                                                                                    flightServices: services.flight,
                                                                                    flightPlanServices: services.flightPlan,
                                                                                    uiServices: services.ui,
                                                                                    repos: services.repos,
                                                                                    drone: services.currentDroneHolder)
        presentModallyCoordinatorWithAnimator(childCoordinator: flightPlanExecutionCoordinator)
    }

    public func backDisplay() {
        showNavBar(show: false)
        back()
    }
}
