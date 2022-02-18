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

/// Coordinator for Remote details screens.
public final class RemoteCoordinator: Coordinator {
    // MARK: - Public Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public weak var parentCoordinator: Coordinator?

    // MARK: - Public Funcs
    public func start() {
        let viewController = RemoteDetailsViewController.instantiate(coordinator: self)
        // Prevents not fullscreen presentation style since iOS 13.
        navigationController = NavigationController(rootViewController: viewController)
        navigationController?.isNavigationBarHidden = true
        navigationController?.modalPresentationStyle = .fullScreen
    }
}

// MARK: - Remote Navigation
extension RemoteCoordinator {
    /// Starts drone list coordinator.
    func startDronesList() {
        let pairingCoordinator = PairingCoordinator(delegate: self)
        pairingCoordinator.parentCoordinator = self
        pairingCoordinator.navigationController = navigationController
        childCoordinators.append(pairingCoordinator)
        pairingCoordinator.startRemoteConnectDrone()
    }

    /// Starts calibration screen.
    func startCalibration() {
        let viewController = RemoteCalibrationViewController.instantiate(coordinator: self)
        push(viewController)
    }

    /// Starts update coordinator.
    func startUpdate() {
        let viewController = RemoteUpdateViewController.instantiate(coordinator: self)
        push(viewController)
    }
}

extension RemoteCoordinator: PairingCoordinatorDelegate {
    public func pairingDidFinish() {
        dismissChildCoordinator()
    }
}
