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

/// Coordinator for drone details screens.
public final class DroneCoordinator: Coordinator {
    // MARK: - Public Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public weak var parentCoordinator: Coordinator?

    private let services: ServiceHub

    init(services: ServiceHub) {
        self.services = services
    }

    // MARK: - Public Funcs
    /// Starts drone coordinator.
    public func start() {
        let viewController = DroneDetailsViewController.instantiate(coordinator: self)
        viewController.modalPresentationStyle = .fullScreen
        navigationController = NavigationController(rootViewController: viewController)
        navigationController?.isNavigationBarHidden = true
        navigationController?.modalPresentationStyle = .fullScreen
    }
}

// MARK: - Drone Details Navigation
extension DroneCoordinator {
    /// Starts map (last known position).
    func startMap() {
        presentModal(viewController: DroneDetailsMapViewController.instantiate(coordinator: self))
    }

    /// Starts calibration.
    func startCalibration() {
        let droneCalibrationCoordinator = DroneCalibrationCoordinator(services: services)
        droneCalibrationCoordinator.parentCoordinator = self
        droneCalibrationCoordinator.delegate = self
        droneCalibrationCoordinator.start()
        present(childCoordinator: droneCalibrationCoordinator,
                overFullScreen: true)
    }

    /// Displays cellular information screen.
    func displayDroneDetailsCellular() {
        let viewModel = DroneDetailCellularViewModel(coordinator: self,
                                                     currentDroneHolder: services.currentDroneHolder,
                                                     cellularPairingService: services.drone.cellularPairingService,
                                                     connectedRemoteControlHolder: services.connectedRemoteControlHolder,
                                                     connectedDroneHolder: services.connectedDroneHolder,
                                                     networkService: services.systemServices.networkService
        )
        let viewController = DroneDetailsCellularViewController.instantiate(viewModel: viewModel)
        presentModal(viewController: viewController)
    }

    /// Displays reboot alert.
    func displayAlertReboot(action: @escaping () -> Void) {
        let cancelAction = AlertAction(title: L10n.cancel,
                                       style: .destructive)

        let validateAction = AlertAction(title: L10n.firmwareMissionUpdateReboot, style: .validate) {
            action()
        }

        let alertViewController = AlertViewController.instantiate(title: L10n.rebootMessageDrone,
                                                                  message: L10n.rebootMessageContinue,
                                                                  messageColor: ColorName.defaultTextColor,
                                                                  closeButtonStyle: .cross,
                                                                  cancelAction: cancelAction,
                                                                  validateAction: validateAction)

        presentPopup(alertViewController)
    }

    /// Displays cellular pin code modal.
    func displayCellularPinCode() {
        presentModal(viewController: CellularAccessCardPinViewController.instantiate(coordinator: self))
    }

    /// Displays cellular debug logs.
    func displayCellularDebug() {
        let viewModel = CellularDebugLogsViewModel(coordinator: self)
        let viewController = CellularDebugLogsViewController.instantiate(viewModel: viewModel)
        navigationController?.present(viewController, animated: true, completion: nil)
    }

    /// Dismisses current coordinator.
    func dismissDroneInfos() {
        parentCoordinator?.dismissChildCoordinator()
    }

    /// Pops to root coordinator in order to display pairing process.
    func pairUser() {
        popToRootCoordinator(coordinator: parentCoordinator)
    }

    /// Displays drone password edition setting.
    func displayDronePasswordEdition() {
        let viewModel = SettingsNetworkViewModel()
        let viewController = SettingsPasswordEditionViewController.instantiate(
            coordinator: self,
            viewModel: viewModel,
            orientation: .all)
        presentModal(viewController: viewController)
    }

    /// Starts the Firmware and AirSdk Missions updates process.
    func startFimwareAndAirSdkMissionsUpdate() {
        let coordinator = DroneFirmwaresCoordinator()
        coordinator.parentCoordinator = self
        coordinator.start()
        present(childCoordinator: coordinator,
                overFullScreen: true)
    }
}

// MARK: - Delegate
extension DroneCoordinator: DroneCalibrationCoordinatorDelegate {
    func firmwareUpdateRequired() {
        dismissChildCoordinator()
        startFimwareAndAirSdkMissionsUpdate()
    }
}
