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

/// Coordinator for Flight Details.
public final class FlightDetailsCoordinator: Coordinator {
    // MARK: - Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public weak var parentCoordinator: Coordinator?

    private let flightServices: FlightServices
    private let flightPlanServices: FlightPlanServices
    private let uiServices: UIServices
    private let drone: CurrentDroneHolder
    private let flight: FlightModel

    init(flight: FlightModel,
         flightServices: FlightServices,
         flightPlanServices: FlightPlanServices,
         uiServices: UIServices,
         drone: CurrentDroneHolder) {
        self.flight = flight
        self.flightServices = flightServices
        self.flightPlanServices = flightPlanServices
        self.uiServices = uiServices
        self.drone = drone
    }

    // MARK: - Public Funcs
    public func start() {
        let viewModel = FlightDetailsViewModel(service: flightServices.service,
                                               flight: flight,
                                               drone: drone,
                                               coordinator: self)
        let viewController = FlightDetailsViewController.instantiate(viewModel: .details(viewModel))
        viewController.modalPresentationStyle = .fullScreen
        navigationController = NavigationController(rootViewController: viewController)
        navigationController?.isNavigationBarHidden = true
    }

    /// Dismisses details.
    ///
    /// - Parameters:
    ///    - completion: Completion block.
    func dismissDetails(completion: (() -> Void)? = nil) {
        // Update the navigation stack
        uiServices.navigationStack.removeLast()
        dismissModallyCoordinatorWithAnimator(completion: completion)
    }

    /// Shows delete flight confirmation popup.
    ///
    /// - Parameters:
    ///    - didTapDelete: completion block called when user taps on delete button.
    func showDeleteFlightPopupConfirmation(didTapDelete: @escaping () -> Void) {
        var parentCoordinator: Coordinator? = self
        while !(parentCoordinator is MyFlightsCoordinator),
              parentCoordinator != nil {
            parentCoordinator = parentCoordinator?.parentCoordinator
        }

        if let myFlightCoordinator =  parentCoordinator as? MyFlightsCoordinator {
            myFlightCoordinator.showDeleteFlightPopupConfirmation(onCoordinator: self,
                                                                  didTapDelete: didTapDelete)
        }
    }
}
