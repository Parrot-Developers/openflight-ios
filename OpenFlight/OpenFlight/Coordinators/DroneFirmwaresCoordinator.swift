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

/// Coordinator for the Firmware and missions update processes.
final class DroneFirmwaresCoordinator: Coordinator {
    // MARK: - Internal Properties
    var navigationController: NavigationController?
    var childCoordinators = [Coordinator]()
    weak var parentCoordinator: Coordinator?
    public let services: ServiceHub

    public init(services: ServiceHub) {
        self.services = services
    }

    // MARK: - Internal Funcs
    func start() {
        let viewModel = DroneFirmwaresViewModel(
            currentDroneHolder: services.currentDroneHolder,
            networkService: services.systemServices.networkService,
            updateService: services.update,
            firmwareUpdateService: services.drone.firmwareUpdateService,
            airSdkMissionsUpdaterService: services.drone.airsdkMissionsUpdaterService,
            airSdkMissionManager: services.drone.airsdkMissionsManager,
            batteryGaugeUpdaterService: services.drone.batteryGaugeUpdaterService
        )
        let viewController = DroneFirmwaresViewController.instantiate(coordinator: self, viewModel: viewModel)
        viewController.modalPresentationStyle = .overFullScreen
        navigationController = NavigationController(rootViewController: viewController)
        navigationController?.isNavigationBarHidden = true
        navigationController?.modalPresentationStyle = .overFullScreen
    }

    /// Quits the update processes.
    func quitUpdateProcesses() {
        services.drone.airsdkMissionsUpdaterService.manuallyBrowse()
        self.parentCoordinator?.dismissChildCoordinator()
    }

    /// Goes to the updating view controller.
    ///
    /// - Parameters:
    ///    - functionalUpdateChoice:The current functional update choice
    func goToUpdatingViewController(functionalUpdateChoice: FirmwareAndMissionUpdateFunctionalChoice) {
        switch functionalUpdateChoice {
        case .firmware:
            let viewModel = FirmwareUpdatingViewModel(
                firmwareUpdateService: services.drone.firmwareUpdateService,
                currentDroneHolder: services.currentDroneHolder)
            let viewController = FirmwareUpdatingViewController.instantiate(coordinator: self, viewModel: viewModel)
            push(viewController)
        case .airSdkMissions:
            let viewModel = AirSdkMissionsUpdatingViewModel(
                airSdkMissionsUpdaterService: services.drone.airsdkMissionsUpdaterService,
                currentDroneHolder: services.currentDroneHolder)
            let viewController = AirSdkMissionsUpdatingViewController.instantiate(
                coordinator: self,
            viewModel: viewModel)
            push(viewController)
        case .firmwareAndAirSdkMissions:
            let viewModel = FirmwareAndMissionsUpdateViewModel(
                airSdkMissionsUpdaterService: services.drone.airsdkMissionsUpdaterService,
                firmwareUpdateService: services.drone.firmwareUpdateService,
                currentDroneHolder: services.currentDroneHolder)
            let viewController = FirmwareAndMissionsUpdateViewController.instantiate(
                coordinator: self,
            viewModel: viewModel)
            push(viewController)
        case .batteryGauge:
            // Push the battery checklist view.
            let viewModel = BatteryUpdateChecklistViewModel(batteryGaugeUpdaterService: services.drone.batteryGaugeUpdaterService)
            let viewController = BatteryUpdateChecklistViewController.instantiate(coordinator: self, viewModel: viewModel)
            push(viewController)
        }
    }

    /// Pushes the battery updating interface.
    ///
    /// Called after the battery check list has been validated.
    func goToBatteryUpdate() {
        let viewModel = BatteryUpdatingViewModel(
            batteryGaugeUpdaterService: services.drone.batteryGaugeUpdaterService,
            connectedDroneHolder: services.connectedDroneHolder)
        let viewController = BatteryUpdatingViewController.instantiate(coordinator: self, viewModel: viewModel)
        push(viewController)
    }
}
