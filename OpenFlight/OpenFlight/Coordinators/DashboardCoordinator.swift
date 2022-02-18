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

import SafariServices
import SwiftyUserDefaults

/// Coordinator for Dashboard part.
open class DashboardCoordinator: Coordinator {
    // MARK: - Public Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public weak var parentCoordinator: Coordinator?
    /// The services. Warning: only here for availability in extensions, don't use from the outside.
    public unowned var services: ServiceHub

    // MARK: - Init
    public init(services: ServiceHub) {
        self.services = services
    }

    // MARK: - Public Funcs
    public func start() {
        let dashboardViewModel = DashboardViewModel(service: services.ui.variableAssetsService,
                                                    projectManager: services.flightPlan.projectManager,
                                                    cloudSynchroWatcher: services.cloudSynchroWatcher,
                                                    projectManagerUiProvider: services.ui.projectManagerUiProvider,
                                                    flightService: services.flight.service)
        let viewController = DashboardViewController.instantiate(coordinator: self, viewModel: dashboardViewModel)
        // Prevents not fullscreen presentation style since iOS 13.
        viewController.modalPresentationStyle = .fullScreen
        navigationController = NavigationController(rootViewController: viewController)
        navigationController?.isNavigationBarHidden = true
        navigationController?.modalPresentationStyle = .fullScreen
    }

    open func startPhotogrammetryDebug() {
    }
}

// MARK: - Dashboard Navigation
extension DashboardCoordinator: DashboardCoordinatorNavigation {
    /// Starts Parrot Debug screen.
    func startParrotDebug() {
        let debugCoordinator = ParrotDebugCoordinator()
        debugCoordinator.parentCoordinator = self
        debugCoordinator.start()
        present(childCoordinator: debugCoordinator)
    }

    /// Starts layout grid manager screen.
    func startLayoutGridManagerScreen() {
        let layoutGridManagerCoordinator = LayoutGridManagerCoordinator()
        layoutGridManagerCoordinator.parentCoordinator = self
        layoutGridManagerCoordinator.start()
        present(childCoordinator: layoutGridManagerCoordinator)
    }

    /// Starts drone details screen.
    func startDroneInformation() {
        let droneCoordinator = DroneCoordinator(services: services)
        droneCoordinator.parentCoordinator = self
        droneCoordinator.start()
        present(childCoordinator: droneCoordinator)
    }

    /// Starts remote details screen.
    func startRemoteInformation() {
        let remoteCoordinator = RemoteCoordinator()
        remoteCoordinator.parentCoordinator = self
        remoteCoordinator.start()
        present(childCoordinator: remoteCoordinator)
    }

    /// Starts device update screens.
    ///
    /// - Parameters:
    ///     - model: device model
    func startUpdate(model: DeviceUpdateModel) {
        switch model {
        case .drone:
            let updateCoordinator = DroneFirmwaresCoordinator()
            updateCoordinator.parentCoordinator = self
            updateCoordinator.start()
            present(childCoordinator: updateCoordinator, overFullScreen: true)
        case .remote:
            let viewController = RemoteUpdateViewController.instantiate(coordinator: self)
            push(viewController)
        }
    }

    /// Starts medias gallery.
    func startMedias() {
        let galleryCoordinator = GalleryCoordinator()
        galleryCoordinator.parentCoordinator = self
        galleryCoordinator.start()
        present(childCoordinator: galleryCoordinator)
    }

    /// Starts settings screen.
    func startSettings() {
        let settingsCoordinator = SettingsCoordinator()
        settingsCoordinator.parentCoordinator = self
        settingsCoordinator.start()
        present(childCoordinator: settingsCoordinator)
    }

    /// Starts my flights screen.
    ///
    /// - Parameters:
    ///    - selectedProject: default selected project
    ///    - selectedFlight: default selected flight
    ///    - completion: completion block
    func startMyFlights(selectedProject: ProjectModel? = nil,
                        selectedFlight: FlightModel? = nil,
                        completion: (() -> Void)? = nil) {
        let coordinator = MyFlightsCoordinator(flightServices: services.flight,
                                               flightPlanServices: services.flightPlan,
                                               uiServices: services.ui,
                                               repos: services.repos,
                                               drone: services.currentDroneHolder,
                                               defaultSelectedProject: selectedProject)
        coordinator.parentCoordinator = self
        coordinator.start()
        present(childCoordinator: coordinator, completion: completion)
        if let selectedProject = selectedProject {
            addToNavigationStack(.myFlightsExecutedProjects(selectedProject: selectedProject))
        } else {
            addToNavigationStack(.myFlights(selectedFlight: selectedFlight))
        }
    }

    /// Starts project manager.
    ///
    /// - Parameters:
    ///    - selectedProject: default selected project
    ///    - completion (optional): completion block
    func startProjectManager(selectedProject: ProjectModel? = nil,
                             completion: (() -> Void)? = nil) {
        let projectManagerCoordinator = ProjectManagerCoordinator(flightPlanServices: services.flightPlan,
                                                                  uiServices: services.ui,
                                                                  cloudSynchroWatcher: services.cloudSynchroWatcher,
                                                                  defaultSelectedProject: selectedProject)
        projectManagerCoordinator.parentCoordinator = self
        projectManagerCoordinator.start()
        present(childCoordinator: projectManagerCoordinator, completion: completion)
        addToNavigationStack(.projectManager(selectedProject: selectedProject))
    }

    /// Displays my acount screen.
    func startMyAccount() {
        let viewController = DashboardMyAccountViewController.instantiate(coordinator: self)
        push(viewController)
    }

    /// Starts map preloading.
    func startMapPreloading() {
    }

    /// Dismisses the dashboard.
    ///
    /// - Parameters:
    ///     - completion: completion when dismiss is completed
    func dismissDashboard(completion: (() -> Void)? = nil) {
        clearNavigationStack()
        dismissCoordinatorWithAnimator(transitionSubtype: .fromRight, completion: completion)
    }
}

// MARK: - Navigation Stack
private extension DashboardCoordinator {

    func addToNavigationStack(_ screen: NavigationStackScreen) {
        services.ui.navigationStack.add(screen)
    }

    func popNavigationStack() {
        services.ui.navigationStack.removeLast()
    }

    func clearNavigationStack() {
        services.ui.navigationStack.clearStack()
    }
}
