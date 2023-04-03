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

import UIKit
import Combine
import CoreLocation
import ArcGIS

///  Displays buttons with drone informations (calibration state, firmware version, etc).
final class DroneDetailsButtonsViewController: AGSMapViewController, DroneDetailsMapViewProtocol {
    // MARK: - Outlets
    @IBOutlet private weak var mapButtonView: DeviceDetailsButtonView!
    @IBOutlet private weak var calibrationButtonView: DeviceDetailsButtonView!
    @IBOutlet private weak var firmwareUpdateButtonView: DeviceDetailsButtonView!
    @IBOutlet private weak var cellularAccessButtonView: DeviceDetailsButtonView!
    @IBOutlet private weak var batteryButtonView: DeviceDetailsButtonView!

    // MARK: - Private Properties
    private var viewModel: DroneDetailsButtonsViewModel!
    private var firmwareUpdateButtonViewModel: FirmwareUpdateButtonViewModel!
    private weak var coordinator: DroneCoordinator?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Setup
    static func instantiate(coordinator: DroneCoordinator,
                            viewModel: DroneDetailsButtonsViewModel,
                            firmwareUpdateButtonViewModel: FirmwareUpdateButtonViewModel) -> DroneDetailsButtonsViewController {
        let viewController = StoryboardScene.DroneDetailsButtons.initialScene.instantiate()
        viewController.coordinator = coordinator
        viewController.viewModel = viewModel
        viewController.firmwareUpdateButtonViewModel = firmwareUpdateButtonViewModel
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        bindToViewModel()
    }

    // MARK: - Delegate
    func dismissScreen() {
    }

    override func getCenter(completion: @escaping(AGSViewpoint?) -> Void) {
        if let coordinate = viewModel.lastKnownPosition?.coordinate {
            completion(AGSViewpoint(center: AGSPoint(clLocationCoordinate2D: coordinate),
                                    scale: CommonMapConstants.cameraDistanceToCenterLocation))
        } else {
            completion(nil)
        }
    }

    override func defaultCenteringDone() {
        initDisplayMap()
    }
}

// MARK: - Actions
private extension DroneDetailsButtonsViewController {
    @IBAction func mapButtonTouchedUpInside(_ sender: Any) {
        logEvent(with: LogEvent.LogKeyDroneDetailsButtons.map)
        self.coordinator?.startMap(delegate: self)
    }

    @IBAction func calibrationButtonTouchedUpInside(_ sender: Any) {
        logEvent(with: LogEvent.LogKeyDroneDetailsButtons.calibration)
        self.coordinator?.startCalibration()
    }

    @IBAction func firmwareUpdateButtonTouchedUpInside(_ sender: Any) {
        logEvent(with: LogEvent.LogKeyDroneDetailsButtons.firmwareUpdate)
        self.coordinator?.startFirmwareAndAirSdkMissionsUpdate()
    }

    @IBAction func cellularAccessButtonTouchedUpInside(_ sender: Any) {
        logEvent(with: LogEvent.LogKeyDroneDetailsButtons.cellularAccess)
        viewModel.resetPairingDroneListIfNeeded()
        coordinator?.displayDroneDetailsCellular()
    }

    @IBAction func batteryButtonTouchedUpInside(_ sender: Any) {
        coordinator?.displayBatteryInfos()
    }
}

// MARK: - Private Funcs
private extension DroneDetailsButtonsViewController {

    /// Init display of map
    func initDisplayMap() {
        viewModel.$lastKnownPosition
            .combineLatest(viewModel.$mapThumbnail)
            .sink { [weak self] (lastKnownPosition, mapThumbnail) in
                guard let self = self else { return }
                let displayMap = lastKnownPosition != nil
                self.mapView.isHidden = !displayMap
                self.mapButtonView.model?.mainImage = displayMap ? nil : mapThumbnail
            }
            .store(in: &cancellables)
    }

    /// Sets up initial view display.
    func initUI() {
        mapButtonView.model = DeviceDetailsButtonModel(mainImage: Asset.Drone.icPoi.image,
                                                       title: L10n.droneDetailsLastKnownPosition)
        calibrationButtonView.model = DeviceDetailsButtonModel(mainImage: Asset.Drone.iconDrone.image,
                                                               title: L10n.remoteDetailsCalibration)
        firmwareUpdateButtonView.model = DeviceDetailsButtonModel(mainImage: Asset.Drone.icDroneFirmware.image,
                                                                  title: L10n.remoteDetailsSoftware)
        cellularAccessButtonView.model = DeviceDetailsButtonModel(mainImage: Asset.Drone.iconCellularDatas.image,
                                                                  title: L10n.droneDetailsCellularAccess,
                                                                  subtitle: "")
        batteryButtonView.model = DeviceDetailsButtonModel(mainImage: Asset.MyFlights.battery.image,
                                                           title: L10n.battery,
                                                           subtitle: "")
    }

    /// Binds the views to the view model
    func bindToViewModel() {
        viewModel.operatorName
            .combineLatest(viewModel.connectionStatusColor, viewModel.cellularLinkState)
            .sink { [unowned self] (operatorName, connectionStatusColor, cellularLinkState) in

                cellularAccessButtonView.model?.subtitle = operatorName ?? cellularLinkState ?? L10n.commonNotConnected
                cellularAccessButtonView.model?.subtitleColor = connectionStatusColor
            }
            .store(in: &cancellables)

        viewModel.$lastKnownPosition
            .sink { [unowned self] lastKnownPosition in
                // Map button.
                let coordinateString = lastKnownPosition?.coordinate.convertToDmsCoordinate()
                mapButtonView.model?.subtitle = coordinateString ?? Style.dash
            }
            .store(in: &cancellables)

        viewModel.$batteryHealth
            .removeDuplicates()
            .sink { [weak self] batteryHealth in
                guard let self = self else { return }
                self.batteryButtonView.model?.subtitle = batteryHealth
            }
            .store(in: &cancellables)

        viewModel.$batteryButtonAvailable
            .removeDuplicates()
            .sink { [weak self] isAvailable in
                guard let self = self else { return }
                self.batteryButtonView.isEnabled = isAvailable
                self.batteryButtonView.alphaWithEnabledState(isAvailable)
            }
            .store(in: &cancellables)

        viewModel.$batterySubtitleColor
            .sink { [weak self] color in
                guard let self = self else { return }
                self.batteryButtonView.model?.subtitleColor = color
            }
            .store(in: &cancellables)

        viewModel.calibrationSubtitle
            .sink { [weak self] calibrationSubtitle in
                self?.calibrationButtonView.model?.subtitle = calibrationSubtitle
            }
            .store(in: &cancellables)

        viewModel.calibrationTitleColor
            .sink { [weak self] calibrationTitleColor in
                self?.calibrationButtonView.model?.titleColor = calibrationTitleColor
                self?.calibrationButtonView.model?.mainImageTintColor = calibrationTitleColor
            }
            .store(in: &cancellables)

        viewModel.calibrationSubtitleColor
            .sink { [weak self] calibrationSubtitleColor in
                self?.calibrationButtonView.model?.subtitleColor = calibrationSubtitleColor
            }
            .store(in: &cancellables)

        viewModel.calibrationBackgroundColor
            .sink { [weak self] calibrationBackgroundColor in
                self?.calibrationButtonView.model?.backgroundColor = calibrationBackgroundColor
            }
            .store(in: &cancellables)

        viewModel.calibrationTitleColor
            .sink { [weak self] calibrationTitleColor in
                self?.calibrationButtonView.model?.titleColor = calibrationTitleColor
                self?.calibrationButtonView.model?.mainImageTintColor = calibrationTitleColor
            }
            .store(in: &cancellables)

        viewModel.isCalibrationButtonAvailable
            .sink { [weak self] isCalibrationButtonAvailable in
                self?.calibrationButtonView.isEnabled = isCalibrationButtonAvailable
                self?.calibrationButtonView.alphaWithEnabledState(isCalibrationButtonAvailable)
            }
            .store(in: &cancellables)

        firmwareUpdateButtonViewModel.$buttonProperties
                .receive(on: RunLoop.main)
                .sink { [weak self] buttonProperties in
                    self?.updateFirmwareUpdateButtonView(properties: buttonProperties)
                }
                .store(in: &cancellables)
    }

    func updateFirmwareUpdateButtonView(properties: FirmwareUpdateButtonProperties) {
        firmwareUpdateButtonView.model?.subtitle = properties.subtitle
        firmwareUpdateButtonView.model?.subImage = properties.subImage
        firmwareUpdateButtonView.model?.backgroundColor = properties.backgroundColor
        firmwareUpdateButtonView.model?.titleColor = properties.titleColor
        firmwareUpdateButtonView.model?.mainImageTintColor = properties.titleColor
        firmwareUpdateButtonView.model?.subtitleColor = properties.titleColor
        firmwareUpdateButtonView.model?.subimageTintColor = properties.subImageTintColor
        firmwareUpdateButtonView.isEnabled = properties.isEnabled

    }

    /// Calls log event.
    ///
    /// - Parameters:
    ///     - itemName: Button name
    func logEvent(with itemName: String) {
        LogEvent.log(.simpleButton(itemName))
    }
}
