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
import Combine

/// View Controller used to display drone calibrations.
final class DroneCalibrationViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var gimbalCalibrationChoiceView: CalibrationChoiceView!
    @IBOutlet private weak var correctHorizonChoiceView: CalibrationChoiceView!
    @IBOutlet private weak var magnetometerChoiceView: CalibrationChoiceView!
    @IBOutlet private weak var obstacleDetectionChoiceView: CalibrationChoiceView!
    @IBOutlet private weak var leftStackView: UIStackView!
    @IBOutlet private weak var mainView: UIView!

    // MARK: - Private Properties
    private weak var coordinator: DroneCalibrationCoordinator?
    private var viewModel = DroneCalibrationViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var firmwareAndMissionsUpdateListener: FirmwareAndMissionsListener?
    private var firmwareAndMissionToUpdateModel: FirmwareAndMissionToUpdateModel?

    // MARK: - Private Enums
    private enum Constants {
        static let defaultTextColor: ColorName = .defaultTextColor
        static let defaultBackgroundColor: ColorName = .white
    }

    // MARK: - Setup
    static func instantiate(coordinator: DroneCalibrationCoordinator) -> DroneCalibrationViewController {
        let viewController = StoryboardScene.DroneCalibration.initialScene.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        listenFirmwareUpdate()
        initUI()
        setupViewModels()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.droneCalibration,
                             logType: .screen)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIView.animate(withDuration: Style.shortAnimationDuration,
                       delay: Style.shortAnimationDuration,
                       options: .allowUserInteraction,
                       animations: {
                        self.view.backgroundColor = ColorName.nightRider80.color
                       })
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Landscape: display gimbal calibration first.
        // Portrait: display horizon correction first.
        let lastView: CalibrationChoiceView = UIApplication.isLandscape ? correctHorizonChoiceView : gimbalCalibrationChoiceView
        leftStackView.addArrangedSubview(lastView)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension DroneCalibrationViewController {
    /// Function called when a choice view is clicked.
    @IBAction func choiceViewTouchedUpInside(_ view: CalibrationChoiceView) {
        if view == gimbalCalibrationChoiceView {
            logEvent(with: LogEvent.LogKeyDroneDetailsCalibrationButton.gimbalCalibration)
            self.coordinator?.startGimbal()
        } else if view == correctHorizonChoiceView {
            self.coordinator?.startHorizonCorrection()
        } else if view == magnetometerChoiceView {
            logEvent(with: LogEvent.LogKeyDroneDetailsCalibrationButton.magnetometerCalibration)
            self.coordinator?.startMagnetometerCalibration()
        } else if view == obstacleDetectionChoiceView {
            logEvent(with: LogEvent.LogKeyDroneDetailsCalibrationButton.sensorCalibrationTutorial)
            if let firmwareAndMissionToUpdateModel = firmwareAndMissionToUpdateModel {
                if firmwareAndMissionToUpdateModel.needFirmwareUpdate {
                    self.coordinator?.displayCriticalAlert()
                } else {
                    viewModel.updateIsStereoCalibrationLaunched(isLaunched: true)
                    self.coordinator?.startStereoVisionCalibration()
                }
            }
        }
    }

    /// Function called when the back button is clicked.
    @IBAction func backButtonTouchedUpInside(_ sender: Any) {
        logEvent(with: LogEvent.LogKeyCommonButton.back)
        dismissView()
    }

    /// Function called when the background button is clicked.
    @IBAction func backgroundButtonTouchedUpInside(_ sender: Any) {
        logEvent(with: LogEvent.LogKeyCommonButton.tapToDismiss)
        dismissView()
    }
}

// MARK: - Private Funcs
private extension DroneCalibrationViewController {
    /// Initializes all the UI for the view controller.
    func initUI() {
        titleLabel.text = L10n.remoteDetailsCalibration
        mainView.customCornered(corners: [.topLeft, .topRight], radius: Style.largeCornerRadius)
    }

    /// Sets up view models associated with the view.
    func setupViewModels() {
        gimbalCalibrationChoiceView.viewModel = CalibrationChoiceModel(image: Asset.Drone.icGimbal.image,
                                                                       text: L10n.droneGimbalTitle)
        correctHorizonChoiceView.viewModel = CalibrationChoiceModel(image: Asset.Drone.icCorrectHorizon.image,
                                                                    text: L10n.droneHorizonCalibration)
        magnetometerChoiceView.viewModel = CalibrationChoiceModel(image: Asset.Drone.icDroneDetailsAvailable.image,
                                                                  text: L10n.droneMagnetometerTitle)
        obstacleDetectionChoiceView.viewModel = CalibrationChoiceModel(image: Asset.Drone.icCalibrateStereoVision.image,
                                                                       text: L10n.droneObstacleDetectionTitle)
    }

    /// Binds the view model to the view
    func bindViewModel() {
        bindGimbal()
        bindMagnetometer()
        bindLoveCalibration()
        bindFlyingState()
    }

    /// Hides the view if the drone is flying
    func bindFlyingState() {
        viewModel.$flyingState
            .compactMap { $0 }
            .combineLatest(viewModel.$isStereoCalibrationLaunched)
            .sink { [unowned self] (flyingState, isStereoCalibrationLaunched) in
                if flyingState == .flying && !isStereoCalibrationLaunched {
                    coordinator?.dismissDroneCalibration()
                }
            }
            .store(in: &cancellables)
    }

    /// Hides the view if the drone is not connected
    func bindConnectionState() {
        viewModel.$droneState
            .compactMap { $0 }
            .sink { [unowned self] droneState in
                if droneState == .disconnected || droneState == .disconnecting {
                    coordinator?.dismissDroneCalibration()
                }
            }
            .store(in: &cancellables)
    }

    /// Updates the gimbal choice view
    func bindGimbal() {
        viewModel.$frontStereoGimbalState
            .combineLatest(viewModel.$frontStereoGimbalCalibrationState,
                           viewModel.$gimbalCalibrationDescription)
            .sink { [unowned self]  (gimbalState, calibrationState, calibrationDescription) in
                if gimbalState == .needed {
                    gimbalCalibrationChoiceView.viewModel?.subText = calibrationState?.description ?? ""
                    gimbalCalibrationChoiceView.viewModel?.textColor = ColorName.white.color
                    gimbalCalibrationChoiceView.viewModel?.subTextColor = .white
                    gimbalCalibrationChoiceView.viewModel?.backgroundColor = .errorColor
                } else {
                    gimbalCalibrationChoiceView.viewModel?.subText = calibrationDescription
                }
            }
            .store(in: &cancellables)

        viewModel.$gimbalCalibrationBackgroundColor
            .combineLatest(viewModel.$frontStereoGimbalState)
            .sink { [unowned self] (backgroundColor, gimbalState) in
                if gimbalState != .needed {
                    gimbalCalibrationChoiceView.viewModel?.backgroundColor = backgroundColor ?? Constants.defaultBackgroundColor
                }
            }
            .store(in: &cancellables)

        viewModel.$gimbalCalibrationTextColor
            .combineLatest(viewModel.$frontStereoGimbalState)
            .sink { [unowned self] (textColor, gimbalState) in
                if gimbalState != .needed {
                    let color = textColor ?? Constants.defaultTextColor
                    gimbalCalibrationChoiceView.viewModel?.textColor = color.color
                    gimbalCalibrationChoiceView.viewModel?.subTextColor = color
                }
            }
            .store(in: &cancellables)
    }

    /// Updates the magnetometer choice view
    func bindMagnetometer() {
        viewModel.$magnetometerState
            .sink { [unowned self] magnetometerState in
                let textColor = magnetometerState?.subtextColor ?? Constants.defaultTextColor
                magnetometerChoiceView.viewModel?.subText = magnetometerState?.description
                magnetometerChoiceView.viewModel?.textColor = textColor.color
                magnetometerChoiceView.viewModel?.subTextColor = textColor
                magnetometerChoiceView.viewModel?.backgroundColor = magnetometerState?.backgroundColor ?? Constants.defaultBackgroundColor
            }
            .store(in: &cancellables)
    }

    /// Updates the love calibration choice view
    func bindLoveCalibration() {
        viewModel.$stereoVisionSensorsState
            .sink { [unowned self] stereoVisionSensorsState in
                let textColor = stereoVisionSensorsState?.subtextColor ?? Constants.defaultTextColor
                obstacleDetectionChoiceView.viewModel?.subText = stereoVisionSensorsState?.description
                obstacleDetectionChoiceView.viewModel?.textColor = textColor.color
                obstacleDetectionChoiceView.viewModel?.subTextColor = textColor
                obstacleDetectionChoiceView.viewModel?.backgroundColor = stereoVisionSensorsState?.backgroundColor ?? Constants.defaultBackgroundColor
            }
            .store(in: &cancellables)
    }

    /// Called when the view needs to be dismissed.
    func dismissView() {
        self.view.backgroundColor = .clear
        self.coordinator?.dismissDroneCalibration()
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

    func listenFirmwareUpdate() {
        firmwareAndMissionsUpdateListener = FirmwareAndMissionsInteractor.shared
            .register { [weak self] (_, firmwareAndMissionToUpdateModel) in
                self?.firmwareAndMissionToUpdateModel = firmwareAndMissionToUpdateModel
            }
    }
}
