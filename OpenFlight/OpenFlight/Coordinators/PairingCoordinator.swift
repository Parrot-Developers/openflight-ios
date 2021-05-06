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

/// Coordinator for Pairing part.
public final class PairingCoordinator: Coordinator {
    // MARK: - Public Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public var parentCoordinator: Coordinator?

    // MARK: - Private Properties
    private var duringOnboarding: Bool = false

    // MARK: - Init
    public init(navigationController: NavigationController? = nil) {
        self.navigationController = navigationController
    }

    // MARK: - Public Funcs
    public func start() {
        let viewController = PairingViewController.instantiate(coordinator: self)
        viewController.modalPresentationStyle = .fullScreen
        self.navigationController = NavigationController(rootViewController: viewController)
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.modalPresentationStyle = .fullScreen
    }

    /// Alternative way to start the coordinator from onboarding.
    public func startFromOnboarding() {
        self.duringOnboarding = true
        let viewController = PairingViewController.instantiate(coordinator: self)
        self.push(viewController)
    }
}

// MARK: - Navigation
extension PairingCoordinator {
    /// Dismisses the pairing menu.
    func dismissPairing() {
        duringOnboarding == true ? showHUDScreen() : parentCoordinator?.dismissChildCoordinator()
    }

    /// Dismisses connect drone with remote screen.
    func dismissRemoteConnectDrone() {
        // Come back to the pairing menu if we are comming from this screen.
        if let remoteVC = navigationController?.viewControllers.first(where: { $0 is PairingViewController }) {
            navigationController?.popToViewController(remoteVC, animated: true)
        } else {
            back()
        }
    }

    /// Starts drones list.
    func startRemoteConnectDrone() {
        let viewController = PairingConnectDroneViewController.instantiate(coordinator: self)
        self.push(viewController)
    }

    /// Starts remote not recognized screen.
    func startControllerNotRecognizedInfo() {
        let viewController = PairingRemoteNotRecognizedViewController.instantiate(coordinator: self)
        self.push(viewController)
    }

    /// Starts how to find wifi password screen.
    func startControllerWhereIsWifi() {
        let viewController = PairingWhereIsWifiViewController.instantiate(coordinator: self)
        self.push(viewController)
    }

    /// Starts drone not detected info screen.
    func startControllerDroneNotDetected() {
        let viewController = PairingDroneNotDetectedViewController.instantiate(coordinator: self)
        self.push(viewController)
    }

    /// Starts connection drone detail with the selected drone from the list.
    ///
    /// - Parameters:
    ///    - droneModel: selected drone model
    func startRemoteConnectDroneDetail(droneModel: RemoteConnectDroneModel) {
        let viewController = PairingConnectDroneDetailViewController.instantiate(coordinator: self, droneModel: droneModel)
        self.push(viewController)
    }

    /// Used to show HUD from pairing process.
    func showHUDScreen() {
        // Remove Pairing coordinator.
        if let pairingCoordinatorIndex = childCoordinators.firstIndex(where: ({ $0 is PairingCoordinator })) {
            childCoordinators.remove(at: pairingCoordinatorIndex)
        }

        let hudCoordinator = HUDCoordinator()
        hudCoordinator.parentCoordinator = self
        self.start(childCoordinator: hudCoordinator)
    }
}
