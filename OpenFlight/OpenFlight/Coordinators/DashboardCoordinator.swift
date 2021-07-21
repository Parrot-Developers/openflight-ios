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

import SafariServices
import SwiftyUserDefaults

/// Coordinator for Dashboard part.
public final class DashboardCoordinator: Coordinator {
    // MARK: - Public Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public var parentCoordinator: Coordinator?
    /// The services. Warning: only here for availability in extensions, don't use from the outside
    public unowned var services: ServiceHub

    // MARK: - Init
    init(services: ServiceHub) {
        self.services = services
    }

    // MARK: - Public Funcs
    public func start() {
        let dashboardViewModel = DashboardViewModel(services: self.services)
        let viewController = DashboardViewController.instantiate(coordinator: self, viewModel: dashboardViewModel)
        // Prevents not fullscreen presentation style since iOS 13.
        viewController.modalPresentationStyle = .fullScreen
        self.navigationController = NavigationController(rootViewController: viewController)
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.modalPresentationStyle = .fullScreen
    }
}

// MARK: - Dashboard Navigation
extension DashboardCoordinator: DashboardCoordinatorNavigation {
    /// Starts Parrot Debug screen.
    func startParrotDebug() {
        let debugCoordinator = ParrotDebugCoordinator()
        debugCoordinator.parentCoordinator = self
        debugCoordinator.start()
        self.present(childCoordinator: debugCoordinator)
    }

    /// Starts Drone infos.
    func startDroneInfos() {
        let droneCoordinator = DroneCoordinator()
        droneCoordinator.parentCoordinator = self
        droneCoordinator.start()
        self.present(childCoordinator: droneCoordinator)
    }

    /// Starts Remote details screen.
    func startRemoteInfos() {
        let remoteCoordinator = RemoteCoordinator()
        remoteCoordinator.parentCoordinator = self
        remoteCoordinator.start()
        self.present(childCoordinator: remoteCoordinator)
    }

    /// Starts device update screens.
    ///
    /// - Parameters:
    ///     - model: device model
    func startUpdate(model: DeviceUpdateModel) {
        let updateCoordinator = UpdateCoordinator(model: model)
        updateCoordinator.parentCoordinator = self
        updateCoordinator.start()
        self.present(childCoordinator: updateCoordinator)
    }

    /// Starts Medias gallery.
    func startMedias() {
        let galleryCoordinator = GalleryCoordinator()
        galleryCoordinator.parentCoordinator = self
        galleryCoordinator.start()
        self.present(childCoordinator: galleryCoordinator)
    }

    /// Starts my flights.
    ///
    /// - Parameters:
    ///     - viewModel: MyFlights view model
    func startMyFlights(_ viewModel: MyFlightsViewModel) {
        let viewController = MyFlightsViewController.instantiate(coordinator: self, viewModel: viewModel)
        self.push(viewController)
    }

    /// Starts flights details.
    func startFlightDetails(viewModel: FlightDataViewModel) {
        let viewController = FlightDetailsViewController.instantiate(coordinator: self, viewModel: viewModel)
        self.push(viewController)
    }

    /// Displays my acount screen.
    func startMyAccount() {
        let viewController = DashboardMyAccountViewController.instantiate(coordinator: self)
        push(viewController)
    }

    /// Starts Confidentiality screen.
    func startConfidentiality() {
        guard let currentAccount = AccountManager.shared.currentAccount,
              let loginCoordinator = currentAccount.destinationCoordinator else {
            return
        }

        // If you need to show a data confidentiality view (ie: GPDR), start data confidentiality from login coordinator here.
        loginCoordinator.parentCoordinator = self
        currentAccount.startDataConfidentiality()
        self.present(childCoordinator: loginCoordinator, animated: true, completion: nil)
    }

    /// Starts map preloading.
    func startMapPreloading() {
    }

    /// Dismisses the dashboard.
    ///
    /// - Parameters:
    ///     - completion: completion when dismiss is completed
    func dismissDashboard(completion: (() -> Void)? = nil) {
        self.dismissCoordinatorWithAnimation(animationDirection: .fromRight, completion: completion)
    }

    /// Function used to handle navigation after clicking on MyFlightsAccountView.
    func startMyFlightsAccountView() {
        guard let currentAccount = AccountManager.shared.currentAccount,
              let loginCoordinator = currentAccount.destinationCoordinator else {
            return
        }

        loginCoordinator.parentCoordinator = self
        currentAccount.startMyFlightsAccountView()
        self.present(childCoordinator: loginCoordinator)
    }

    /// Starts Flight Plan Dashboard.
    ///
    /// - Parameters:
    ///     - viewModel: flightPlan view model
    func startFlightPlanDashboard(viewModel: FlightPlanViewModel) {
        let viewController = FlightPlanDashboardViewController.instantiate(coordinator: self,
                                                                           viewModel: viewModel)
        self.presentModal(viewController: viewController)
    }

    /// Starts Flight Plan.
    ///
    /// - Parameters:
    ///     - viewModel: Flight Plan view model
    func showFlightPlan(viewModel: FlightPlanViewModel?) {
        guard let type = viewModel?.state.value.type else { return }

        // Set Flight Plan as last used to be automatically open
        // if the current mission is not related to a Flight Plan.
        viewModel?.setAsLastUsed()
        // Set Flight Plan as current.
        FlightPlanManager.shared.currentFlightPlanViewModel = viewModel

        dismissDashboard {
            // Setup Mission as a Flight Plan mission (may be custom).
            Services.hub.currentMissionManager.set(provider: type.missionProvider)
            Services.hub.currentMissionManager.set(mode: type.missionMode)
        }
    }
}
