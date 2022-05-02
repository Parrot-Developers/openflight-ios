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

/// Coordinator for execution details.
public final class FlightPlanExecutionDetailsCoordinator: Coordinator {
    // MARK: - Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public weak var parentCoordinator: Coordinator?

    private let flightServices: FlightServices
    private let flightPlanServices: FlightPlanServices
    private let uiServices: UIServices
    private let repos: Repositories
    private let drone: CurrentDroneHolder
    private let flightPlan: FlightPlanModel

    public init(flightPlan: FlightPlanModel,
                flightServices: FlightServices,
                flightPlanServices: FlightPlanServices,
                uiServices: UIServices,
                repos: Repositories,
                drone: CurrentDroneHolder) {
        self.flightPlan = flightPlan
        self.flightServices = flightServices
        self.flightPlanServices = flightPlanServices
        self.uiServices = uiServices
        self.repos = repos
        self.drone = drone
    }

    // MARK: - Public Funcs
    public func start() {
        let viewModel = FlightPlanExecutionViewModel(flightPlan: flightPlan,
                                                     flightRepository: repos.flight,
                                                     flightPlanRepository: repos.flightPlan,
                                                     coordinator: self,
                                                     flightPlanExecutionDetailsSettingsProvider: uiServices.flightPlanExecutionDetailsSettingsProvider,
                                                     flightPlanUiStateProvider: uiServices.flightPlanUiStateProvider,
                                                     flightService: flightServices.service,
                                                     navigationStack: uiServices.navigationStack)
        let viewController = FlightDetailsViewController.instantiate(viewModel: .execution(viewModel))
        viewController.modalPresentationStyle = .fullScreen
        navigationController = NavigationController(rootViewController: viewController)
        navigationController?.isNavigationBarHidden = true
    }

    /// Dismisses details.
    ///
    /// - Parameters:
    ///    - completion: Completion block.
    func dismissDetails(completion: (() -> Void)? = nil) {
        dismissModallyCoordinatorWithAnimator(completion: completion)
    }

    /// Shows delete flight confirmation popup.
    ///
    /// - Parameters:
    ///    - didTapDelete: completion block called when user taps on delete button.
    func showDeleteFlightPopupConfirmation(didTapDelete: @escaping () -> Void) {
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
        presentModal(viewController: alert)
    }

    /// Opens Flight Plan in HUD.
    ///
    /// - Parameters:
    ///    - flightPlan: Flight Plan
    public func open(flightPlan: FlightPlanModel) {
        flightPlanServices.projectManager
            .loadEverythingAndOpen(flightPlan: flightPlan,
                                   autoStart: true,
                                   isBrandNew: false)
        popToRootCoordinatorWithAnimator(coordinator: self,
                                         transitionType: .reveal,
                                         transitionSubtype: .fromTop)
    }
}
