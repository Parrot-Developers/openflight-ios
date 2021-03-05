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

import UIKit

///  Displays buttons with drone informations (calibration state, firmware version, etc).
final class DroneDetailsButtonsViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var mapButtonView: DroneDetailsButtonView!
    @IBOutlet private weak var calibrationButtonView: DroneDetailsButtonView!
    @IBOutlet private weak var firmwareUpdateButtonView: DroneDetailsButtonView!
    @IBOutlet private weak var cellularAccessButtonView: DroneDetailsButtonView!
    @IBOutlet private weak var passwordButtonView: DroneDetailsButtonView!

    // MARK: - Private Properties
    private var viewModel = DroneDetailsButtonsViewModel()
    private var firmwareAndMissionsInteractorListener: FirmwareAndMissionsListener?
    private weak var coordinator: DroneCoordinator?

    // MARK: - Setup
    static func instantiate(coordinator: DroneCoordinator) -> DroneDetailsButtonsViewController {
        let viewController = StoryboardScene.DroneDetails.droneDetailsButtons.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Deinit
    deinit {
        FirmwareAndMissionsInteractor.shared.unregister(firmwareAndMissionsInteractorListener)
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupViewModel()
    }
}

// MARK: - Actions
private extension DroneDetailsButtonsViewController {
    @IBAction func mapButtonTouchedUpInside(_ sender: Any) {
        logEvent(with: LogEvent.LogKeyDroneDetailsButtons.map)
        self.coordinator?.startMap()
    }

    @IBAction func calibrationButtonTouchedUpInside(_ sender: Any) {
        logEvent(with: LogEvent.LogKeyDroneDetailsButtons.calibration)
        self.coordinator?.startCalibration()
    }

    @IBAction func firmwareUpdateButtonTouchedUpInside(_ sender: Any) {
        logEvent(with: LogEvent.LogKeyDroneDetailsButtons.firmwareUpdate)
        self.coordinator?.startFimwareAndProtobufMissionsUpdate()
    }

    @IBAction func cellularAccessButtonTouchedUpInside(_ sender: Any) {
        logEvent(with: LogEvent.LogKeyDroneDetailsButtons.cellularAccess)

        viewModel.resetPairingDroneListIfNeeded()
        coordinator?.displayCellularDetails()
    }

    @IBAction func passwordEditionButtonTouchedUpInside(_ sender: Any) {
        logEvent(with: LogEvent.LogKeyDroneDetailsButtons.informations)
        coordinator?.displayDronePasswordEdition()
    }
}

// MARK: - Private Funcs
private extension DroneDetailsButtonsViewController {
    /// Sets up initial view display.
    func setupView() {
        mapButtonView.applyCornerRadius(Style.largeCornerRadius)
        calibrationButtonView.applyCornerRadius(Style.largeCornerRadius)
        firmwareUpdateButtonView.applyCornerRadius(Style.largeCornerRadius)
        cellularAccessButtonView.applyCornerRadius(Style.largeCornerRadius)
        passwordButtonView.applyCornerRadius(Style.largeCornerRadius)

        mapButtonView.model = DroneDetailsButtonModel(mainImage: Asset.Drone.iconMap.image,
                                                      title: L10n.droneDetailsLastKnownPosition)
        calibrationButtonView.model = DroneDetailsButtonModel(mainImage: Asset.Drone.iconDrone.image,
                                                              title: L10n.remoteDetailsCalibration)
        firmwareUpdateButtonView.model = DroneDetailsButtonModel(mainImage: Asset.Drone.icUpdateFirmwareAndMission.image,
                                                                 title: L10n.remoteDetailsSoftware)
        cellularAccessButtonView.model = DroneDetailsButtonModel(mainImage: Asset.Drone.iconCellularDatas.image,
                                                                 title: L10n.droneDetailsCellularAccess,
                                                                 subtitle: viewModel.state.value.cellularStatus.droneDetailsTileDescription)
        passwordButtonView.model = DroneDetailsButtonModel(mainImage: Asset.Drone.icDronePassword.image,
                                                           title: L10n.commonPassword,
                                                           subtitle: nil)
    }

    /// Sets up view model.
    func setupViewModel() {
        viewModel.state.valueChanged = { [weak self] state in
            self?.updateView(state: state)
        }
        updateView(state: viewModel.state.value)

        firmwareAndMissionsInteractorListener = FirmwareAndMissionsInteractor.shared
            .register { [weak self] (_, firmwareAndMissionToUpdateModel) in
                self?.updateFirmwareUpdateButtonView(for: firmwareAndMissionToUpdateModel)
            }
    }

    /// Update the buttons with state.
    ///
    /// - Parameters:
    ///    - state: current state
    func updateView(state: DroneDetailsButtonsState) {
        // Map button.
        let coordinateString = state.lastKnownPosition?.coordinate.convertToDmsCoordinate()
        mapButtonView.model?.subtitle = coordinateString ?? Style.dash

        // Calibration button.
        calibrationButtonView.model?.subtitle = state.calibrationText
        calibrationButtonView.model?.subtitleColor = state.stereoVisionSensorCalibrationNeeded ? .redTorch : .white50
        calibrationButtonView.model?.backgroundColor = state.calibrationNeeded || state.stereoVisionSensorCalibrationNeeded ? .redTorch25 : .white10
        calibrationButtonView.isEnabled = state.isCalibrationButtonAvailable

        // Cellular button.
        cellularAccessButtonView.model?.subtitle = state.cellularStatus.droneDetailsTileDescription
        cellularAccessButtonView.model?.subtitleColor = state.cellularStatus.detailsTextColor
        cellularAccessButtonView.isEnabled = viewModel.state.value.canShowCellular

        // Password button.
        passwordButtonView.isEnabled = state.isConnected()
    }

    /// Updates the firmwareUpdateButtonView UI.
    ///
    /// - Parameters:
    ///    - model: the current `FirmwareAndMissionToUpdateModel`
    func updateFirmwareUpdateButtonView(for model: FirmwareAndMissionToUpdateModel) {
        firmwareUpdateButtonView.model?.subtitle = model.subtitle
        firmwareUpdateButtonView.model?.complementarySubtitle = model.complementarySubtitle
        firmwareUpdateButtonView.model?.subImage = model.subImage
        firmwareUpdateButtonView.model?.backgroundColor = model.backgroundColor
    }

    /// Calls log event.
    ///
    /// - Parameters:
    ///     - itemName: Button name
    func logEvent(with itemName: String) {
        LogEvent.logAppEvent(itemName: itemName,
                             newValue: nil,
                             logType: .button)
    }
}
