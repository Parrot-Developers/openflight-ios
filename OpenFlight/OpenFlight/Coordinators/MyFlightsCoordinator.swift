//    Copyright (C) 2021 Parrot Drones SAS
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

/// Coordinator for My Flights.
public final class MyFlightsCoordinator: Coordinator {
    // MARK: - Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public weak var parentCoordinator: Coordinator?

    private let flightServices: FlightServices
    private let flightPlanServices: FlightPlanServices
    private let uiServices: UIServices
    private let repos: Repositories
    private let drone: CurrentDroneHolder
    private var defaultSelectedProject: ProjectModel?
    private var defaultSelectedFlight: FlightModel?
    private var defaultSelectedHeaderUuid: String?

    public init(flightServices: FlightServices,
                flightPlanServices: FlightPlanServices,
                uiServices: UIServices,
                repos: Repositories,
                drone: CurrentDroneHolder,
                defaultSelectedProject: ProjectModel? = nil,
                defaultSelectedFlight: FlightModel? = nil,
                defaultSelectedHeaderUuid: String? = nil) {
        self.flightServices = flightServices
        self.flightPlanServices = flightPlanServices
        self.defaultSelectedProject = defaultSelectedProject
        self.defaultSelectedFlight = defaultSelectedFlight
        self.defaultSelectedHeaderUuid = defaultSelectedHeaderUuid
        self.uiServices = uiServices
        self.repos = repos
        self.drone = drone
    }

    // MARK: - Public Funcs
    public func start() {
        let viewController = MyFlightsViewController.instantiate(coordinator: self,
                                                                 defaultSelectedProject: defaultSelectedProject,
                                                                 defaultSelectedFlight: defaultSelectedFlight,
                                                                 defaultSelectedHeaderUuid: defaultSelectedHeaderUuid)
        viewController.modalPresentationStyle = .fullScreen
        navigationController = NavigationController(rootViewController: viewController)
        navigationController?.isNavigationBarHidden = true
    }

    /// Dismisses My Flights.
    ///
    /// - Parameters:
    ///    - animated: Animate the dismiss coordinator action.
    ///    - completion: Completion block.
    func dismissMyFlights(animated: Bool = true,
                          completion: (() -> Void)? = nil) {
        // Update the navigation stack
        uiServices.navigationStack.removeLast()
        parentCoordinator?.dismissChildCoordinator(animated: animated, completion: completion)
    }

    /// Function used to handle navigation after clicking on MyFlightsAccountView.
    func startMyFlightsAccountView() {
        guard let currentAccount = AccountManager.shared.currentAccount,
              let loginCoordinator = currentAccount.destinationCoordinator else { return }
        loginCoordinator.parentCoordinator = self
        currentAccount.startMyFlightsAccountView()
        present(childCoordinator: loginCoordinator)
    }

    /// Opens a Project/Flight Plan vue.
    ///
    /// - Parameters:
    ///    - project: a project
    func open(project: ProjectModel) {
        flightPlanServices.projectManager.loadEverythingAndOpen(project: project)
        popToRootCoordinatorWithAnimator(coordinator: self,
                                         transitionSubtype: .fromRight)
    }

    /// Starts execution details.
    ///
    /// - Parameters:
    ///    - execution: a flightPlan execution
    ///    - completion: Completion block.
    public func startFlightExecutionDetails(_ execution: FlightPlanModel,
                                            completion: (() -> Void)? = nil) {
        let coordinator =  FlightPlanExecutionDetailsCoordinator(flightPlan: execution,
                                                                 flightServices: flightServices,
                                                                 flightPlanServices: flightPlanServices,
                                                                 uiServices: uiServices,
                                                                 repos: repos,
                                                                 drone: drone)
        presentModallyCoordinatorWithAnimator(childCoordinator: coordinator, completion: completion)
    }

    /// Starts a flight details.
    ///
    /// - Parameters:
    ///    - flight: a flight
    ///    - completion: Completion block.
    func startFlightDetails(flight: FlightModel,
                            completion: (() -> Void)? = nil) {
        let coordinator =  FlightDetailsCoordinator(flight: flight,
                                                    flightServices: flightServices,
                                                    flightPlanServices: flightPlanServices,
                                                    uiServices: uiServices,
                                                    drone: drone)
        presentModallyCoordinatorWithAnimator(childCoordinator: coordinator, completion: completion)
        uiServices.navigationStack.add(.flightDetails(flight: flight))
    }

    /// Shows delete flight confirmation popup.
    ///
    /// - Parameters:
    ///    - onCoordinator: Presenting parent coordinator.
    ///    - didTapDelete: Completion block called when user taps on delete button.
    func showDeleteFlightPopupConfirmation(onCoordinator: Coordinator? = nil,
                                           didTapDelete: @escaping () -> Void) {
        let deleteAction = AlertAction(title: L10n.commonDelete,
                                       style: .destructive,
                                       actionHandler: { didTapDelete() })
        let cancelAction = AlertAction(title: L10n.cancel,
                                       style: .default2,
                                       actionHandler: {})
        let alert = AlertViewController.instantiate(title: L10n.alertDeleteFlightLogTitle,
                                                    message: L10n.alertDeleteFlightLogMessage,
                                                    cancelAction: cancelAction,
                                                    validateAction: deleteAction)
        (onCoordinator ?? self).presentModal(viewController: alert)
    }
}

// MARK: - Navigation Stack
extension MyFlightsCoordinator {
    func resetNavigationStack(selectedPanel: MyFlightsPanelType) {
        uiServices.navigationStack.updateLast(with: selectedPanel == .plans ?
                                                .myFlightsExecutedProjects(selectedProject: nil, selectedHeaderUuid: defaultSelectedHeaderUuid) :
                                                    .myFlights(selectedFlight: nil))
    }
}
