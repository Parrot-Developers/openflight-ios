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

///  Displays buttons with drone informations (calibration state, firmware version, etc).
final class DroneDetailsButtonsViewController: UIViewController, DroneDetailsMapViewProtocol {
    // MARK: - Outlets
    @IBOutlet private weak var mapButtonView: DeviceDetailsButtonView!
    @IBOutlet private weak var mapContainerView: UIView!
    @IBOutlet private weak var calibrationButtonView: DeviceDetailsButtonView!
    @IBOutlet private weak var firmwareUpdateButtonView: DeviceDetailsButtonView!
    @IBOutlet private weak var cellularAccessButtonView: DeviceDetailsButtonView!
    @IBOutlet private weak var batteryButtonView: DeviceDetailsButtonView!

    // MARK: - Private Properties
    private var mapViewController: MapViewController?
    private var viewModel = DroneDetailsButtonsViewModel()
    private var firmwareAndMissionsInteractorListener: FirmwareAndMissionsListener?
    private weak var coordinator: DroneCoordinator?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Setup
    static func instantiate(coordinator: DroneCoordinator) -> DroneDetailsButtonsViewController {
        let viewController = StoryboardScene.DroneDetailsButtons.initialScene.instantiate()
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

        initUI()
        initMap()
        bindToViewModel()
    }

    // MARK: - Delegate
    func dismissScreen() {
        initMap()
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

    /// Init map view controller.
    func initMap() {
        if mapViewController == nil {
            let controller = MapViewController.instantiate(mapMode: .mapOnly)
            addChild(controller)
            mapViewController = controller
        } else {
            // forcing view will appear to refresh sceneView singleton.
            mapViewController?.viewWillAppear(true)
            mapViewController?.viewDidAppear(true)
        }
        guard let mapViewController = mapViewController else { return }

        if let mapView = mapViewController.view {
            mapContainerView.addWithConstraints(subview: mapView)
        }
        mapContainerView.applyCornerRadius(Style.largeCornerRadius)
        mapViewController.didMove(toParent: self)
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
        viewModel.$cellularStatus
            .removeDuplicates()
            .combineLatest(viewModel.cellularButtonSubtitlePublisher)
            .sink { [unowned self] (cellularStatus, cellularButtonSubtitle) in
                // Cellular button.
                cellularAccessButtonView.model?.subtitle = cellularButtonSubtitle
                cellularAccessButtonView.model?.subtitleColor = cellularStatus.detailsTextColor
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

        viewModel.$lastKnownPosition
            .combineLatest(viewModel.$mapThumbnail)
            .sink { [unowned self] (lastKnownPosition, mapThumbnail) in
                let displayMap = lastKnownPosition != nil
                mapContainerView.isHidden = !displayMap
                mapButtonView.model?.mainImage = displayMap ? nil : mapThumbnail
            }
            .store(in: &cancellables)

        viewModel.calibrationSubtitle
            .sink { [unowned self] calibrationSubtitle in
                calibrationButtonView.model?.subtitle = calibrationSubtitle
            }
            .store(in: &cancellables)

        viewModel.calibrationTitleColor
            .sink { [unowned self] calibrationTitleColor in
                calibrationButtonView.model?.titleColor = calibrationTitleColor
                calibrationButtonView.model?.mainImageTintColor = calibrationTitleColor
            }
            .store(in: &cancellables)

        viewModel.calibrationSubtitleColor
            .sink { [unowned self] calibrationSubtitleColor in
                calibrationButtonView.model?.subtitleColor = calibrationSubtitleColor
            }
            .store(in: &cancellables)

        viewModel.calibrationBackgroundColor
            .sink { [unowned self] calibrationBackgroundColor in
                calibrationButtonView.model?.backgroundColor = calibrationBackgroundColor
            }
            .store(in: &cancellables)

        viewModel.calibrationTitleColor
            .sink { [unowned self] calibrationTitleColor in
                calibrationButtonView.model?.titleColor = calibrationTitleColor
                calibrationButtonView.model?.mainImageTintColor = calibrationTitleColor
            }
            .store(in: &cancellables)

        viewModel.isCalibrationButtonAvailable
            .sink { [unowned self] isCalibrationButtonAvailable in
                calibrationButtonView.isEnabled = isCalibrationButtonAvailable
                calibrationButtonView.alphaWithEnabledState(isCalibrationButtonAvailable)
            }
            .store(in: &cancellables)

        firmwareAndMissionsInteractorListener = FirmwareAndMissionsInteractor.shared
            .register { [weak self] (_, firmwareAndMissionToUpdateModel) in
                self?.updateFirmwareUpdateButtonView(for: firmwareAndMissionToUpdateModel)
            }
    }

    /// Updates the firmwareUpdateButtonView UI.
    ///
    /// - Parameters:
    ///    - model: the current `FirmwareAndMissionToUpdateModel`
    func updateFirmwareUpdateButtonView(for model: FirmwareAndMissionToUpdateModel) {
        firmwareUpdateButtonView.model?.subtitle = model.subtitle
        firmwareUpdateButtonView.model?.subImage = model.subImage
        firmwareUpdateButtonView.model?.backgroundColor = model.backgroundColor
        firmwareUpdateButtonView.model?.titleColor = model.titleColor
        firmwareUpdateButtonView.model?.mainImageTintColor = model.titleColor
        firmwareUpdateButtonView.model?.subtitleColor = model.titleColor
        firmwareUpdateButtonView.model?.subimageTintColor = model.subImageTintColor
        firmwareUpdateButtonView.isEnabled = model.isEnabled
    }

    /// Calls log event.
    ///
    /// - Parameters:
    ///     - itemName: Button name
    func logEvent(with itemName: String) {
        LogEvent.log(.simpleButton(itemName))
    }
}
