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
open class DroneCoordinator: Coordinator {
    // MARK: - Public Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public weak var parentCoordinator: Coordinator?

    public let services: ServiceHub

    public init(services: ServiceHub) {
        self.services = services
    }

    // MARK: - Public Funcs
    /// Starts drone coordinator.
    public func start() {
        let buttonsViewModel = DroneDetailsButtonsViewModel(coordinator: self,
                                                            currentDroneHolder: services.currentDroneHolder,
                                                            cellularPairingService: services.drone.cellularPairingService,
                                                            connectedRemoteControlHolder: services.connectedRemoteControlHolder,
                                                            connectedDroneHolder: services.connectedDroneHolder,
                                                            networkService: services.systemServices.networkService,
                                                            cellularService: services.drone.cellularService,
                                                            cellularSessionService: services.drone.cellularSessionService,
                                                            locationsTracker: services.locationsTracker)
        let buttonsViewController = DroneDetailsButtonsViewController.instantiate(coordinator: self,
                                                                                  viewModel: buttonsViewModel)
        let deviceViewController = DroneDetailsDeviceViewController.instantiate(coordinator: self)
        let informationViewModel = DroneDetailsInformationsViewModel(currentDroneHolder: services.currentDroneHolder,
                                                                     connectedDroneHolder: services.connectedDroneHolder)
        let informationViewController = DroneDetailsInformationsViewController.instantiate(viewModel: informationViewModel)
        let viewController = DroneDetailsViewController.instantiate(coordinator: self,
                                                                    deviceViewController: deviceViewController,
                                                                    informationViewController: informationViewController,
                                                                    buttonsViewController: buttonsViewController)

        viewController.modalPresentationStyle = .fullScreen
        navigationController = NavigationController(rootViewController: viewController)
        navigationController?.isNavigationBarHidden = true
        navigationController?.modalPresentationStyle = .fullScreen
    }

    /// Starts calibration.
    open func startCalibration() {
        let droneCalibrationCoordinator = DroneCalibrationCoordinator(services: services)
        droneCalibrationCoordinator.parentCoordinator = self
        droneCalibrationCoordinator.delegate = self
        droneCalibrationCoordinator.start()
        present(childCoordinator: droneCalibrationCoordinator,
                overFullScreen: true)
    }

    /// Displays cellular information screen.
    open func displayDroneDetailsCellular() {
        let viewModel = DroneDetailCellularViewModel(coordinator: self,
                                                     currentDroneHolder: services.currentDroneHolder,
                                                     cellularPairingService: services.drone.cellularPairingService,
                                                     connectedRemoteControlHolder: services.connectedRemoteControlHolder,
                                                     connectedDroneHolder: services.connectedDroneHolder,
                                                     networkService: services.systemServices.networkService,
                                                     cellularService: services.drone.cellularService,
                                                     cellularSessionService: services.drone.cellularSessionService)
        let viewController = DroneDetailsCellularViewController.instantiate(viewModel: viewModel)
        presentModal(viewController: viewController)
    }

    /// Starts cellular support screen.
    open func startCellularSupport() {}
}

// MARK: - Drone Details Navigation
extension DroneCoordinator {
    /// Starts map (last known position).
    func startMap(delegate: DroneDetailsMapViewProtocol) {
        let droneDetailsMapViewController = DroneDetailsMapViewController.instantiate(coordinator: self, delegate: delegate)
        presentModal(viewController: droneDetailsMapViewController)
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
        let viewModel = CellularAccessCardPinViewModel(coordinator: self, detailsCellularIsSource: true)
        presentModal(viewController: CellularAccessCardPinViewController.instantiate(viewModel: viewModel))
    }

    /// Dismisses current coordinator.
    func dismissDroneInfos() {
        parentCoordinator?.dismissChildCoordinator()
    }

    /// Pops to root coordinator in order to display pairing process.
    func pairUser() {
        popToRootCoordinator(coordinator: parentCoordinator)
    }

    /// Displays the battery info view
    func displayBatteryInfos() {
        let viewModel = DroneDetailsBatteryViewModel(coordinator: self, connectedDroneHolder: services.connectedDroneHolder)
        let viewController = DroneDetailsBatteryViewController.instantiate(viewModel: viewModel)
        presentModal(viewController: viewController)
    }

    /// Starts the Firmware and AirSdk Missions updates process.
    func startFirmwareAndAirSdkMissionsUpdate() {
        let coordinator = DroneFirmwaresCoordinator()
        coordinator.parentCoordinator = self
        coordinator.start()
        present(childCoordinator: coordinator,
                overFullScreen: true)
    }
}

// MARK: - Delegate
extension DroneCoordinator: DroneCalibrationCoordinatorDelegate {
    public func firmwareUpdateRequired() {
        dismissChildCoordinator()
        startFirmwareAndAirSdkMissionsUpdate()
    }
}
