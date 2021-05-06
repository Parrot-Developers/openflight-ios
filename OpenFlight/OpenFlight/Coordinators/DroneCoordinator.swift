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

/// Coordinator for drone details screens.
public final class DroneCoordinator: Coordinator {
    // MARK: - Public Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public var parentCoordinator: Coordinator?

    // MARK: - Public Funcs
    public func start() {
        let viewController = DroneDetailsViewController.instantiate(coordinator: self)
        viewController.modalPresentationStyle = .fullScreen
        self.navigationController = NavigationController(rootViewController: viewController)
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.modalPresentationStyle = .fullScreen
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
        let droneCalibrationCoordinator = DroneCalibrationCoordinator()
        droneCalibrationCoordinator.parentCoordinator = self
        droneCalibrationCoordinator.start()
        self.present(childCoordinator: droneCalibrationCoordinator,
                     overFullScreen: true)
    }

    /// Starts update screen.
    ///
    /// - Parameters:
    ///     - deviceUpdateType: type of the update
    func startUpdate(deviceUpdateType: DeviceUpdateType) {
        let updateCoordinator = UpdateCoordinator(model: .drone)
        updateCoordinator.parentCoordinator = self
        updateCoordinator.deviceUpdateType = deviceUpdateType
        updateCoordinator.start()
        self.present(childCoordinator: updateCoordinator)
    }

    /// Starts cellular information.
    func displayCellularDetails() {
        presentModal(viewController: DroneDetailsCellularViewController.instantiate(coordinator: self))
    }

    /// Displays cellular pin code modal.
    func displayCellularPinCode() {
        presentModal(viewController: CellularAccessCardPinViewController.instantiate(coordinator: self))
    }

    /// Dismisses current coordinator.
    func dismissDroneInfos() {
        parentCoordinator?.dismissChildCoordinator()
    }

    /// Pops to root coordinator in order to display pairing process.
    func pairUser() {
        self.popToRootCoordinator(coordinator: parentCoordinator)
    }

    /// Displays drone password edition setting.
    func displayDronePasswordEdition() {
        let viewController = SettingsPasswordEditionViewController.instantiate(coordinator: self,
                                                                               viewModel: SettingsNetworkViewModel(),
                                                                               orientation: .all)
        self.push(viewController)
    }

    /// Starts update or version information.
    ///
    /// - Parameters:
    ///     - model: tells if the drone is up to date or not
    ///     - versionNumber: current version number
    ///     - versionNeeded: version to update
    func startFirmwareVersionInformation(model: DroneDetailsUpdateType = .upToDate,
                                         versionNumber: String?,
                                         versionNeeded: String?) {
        let firmwareViewController = DroneDetailsFirmwareViewController.instantiate(coordinator: self,
                                                                                    versionNumber: versionNumber,
                                                                                    versionNeeded: versionNeeded,
                                                                                    model: model)
        presentModal(viewController: firmwareViewController)
    }

    /// Starts the Firmware and Protobuf Missions updates process.
    func startFimwareAndProtobufMissionsUpdate() {
        let missionUpdateCoordinator = ProtobufMissionUpdateCoordinator()
        missionUpdateCoordinator.parentCoordinator = self
        missionUpdateCoordinator.start()
        self.present(childCoordinator: missionUpdateCoordinator,
                     overFullScreen: true)
    }
}
