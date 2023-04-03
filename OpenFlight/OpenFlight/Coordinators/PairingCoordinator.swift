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

public protocol PairingCoordinatorDelegate: AnyObject {
    /// Calls when the pairing finished.
    func pairingDidFinish()
}

/// Coordinator for Pairing part.
public final class PairingCoordinator: Coordinator {
    // MARK: - Public Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public weak var parentCoordinator: Coordinator?

    // MARK: - Private Properties
    private unowned var services: ServiceHub
    private weak var delegate: PairingCoordinatorDelegate?

    // MARK: - Init
    public init(services: ServiceHub,
                navigationController: NavigationController? = nil,
                delegate: PairingCoordinatorDelegate) {
        self.services = services
        self.navigationController = navigationController
        self.delegate = delegate
    }

    // MARK: - Public Funcs
    public func start() {
        let viewController = PairingViewController.instantiate(coordinator: self)
        viewController.modalPresentationStyle = .fullScreen
        navigationController = NavigationController(rootViewController: viewController)
        navigationController?.isNavigationBarHidden = true
        navigationController?.modalPresentationStyle = .fullScreen
    }
}

// MARK: - Navigation
extension PairingCoordinator {
    /// Dismisses the pairing menu.
    func dismissPairing() {
        delegate?.pairingDidFinish()
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
        let viewModel = PairingConnectDroneViewModel(currentDroneHolder: services.currentDroneHolder,
                                                     currentRemoteControlHolder: services.currentRemoteControlHolder,
                                                     networkService: services.systemServices.networkService,
                                                     pairingService: services.drone.cellularPairingService,
                                                     academyApiDroneService: services.academyApiDroneService)
        let viewController = PairingConnectDroneViewController.instantiate(coordinator: self,
                                                                           viewModel: viewModel)
        push(viewController)
    }

    /// Starts remote not recognized screen.
    func startControllerNotRecognizedInfo() {
        let viewController = PairingRemoteNotRecognizedViewController.instantiate(coordinator: self)
        viewController.modalPresentationStyle = .overFullScreen
        presentPopup(viewController)
    }

    /// Starts how to find wifi password screen.
    func startControllerWhereIsWifi() {
        let viewController = PairingWhereIsWifiViewController.instantiate(coordinator: self)
        viewController.modalPresentationStyle = .overFullScreen
        presentPopup(viewController)
    }

    /// Starts drone not detected info screen.
    func startControllerDroneNotDetected() {
        let viewController = PairingDroneNotDetectedViewController.instantiate(coordinator: self)
        viewController.modalPresentationStyle = .overFullScreen
        presentPopup(viewController)
    }

    /// Starts connection drone detail with the selected drone from the list.
    ///
    /// - Parameters:
    ///    - droneModel: selected drone model
    func startRemoteConnectDroneDetail(droneModel: RemoteConnectDroneModel) {
        let viewModel = PairingConnectDroneDetailViewModel(droneModel: droneModel)
        let viewController = PairingConnectDroneDetailViewController.instantiate(coordinator: self,
                                                                                 viewModel: viewModel)
        push(viewController)
    }
}
