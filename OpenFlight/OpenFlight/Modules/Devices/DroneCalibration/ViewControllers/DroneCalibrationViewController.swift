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

/// View Controller used to display drone calibrations.
open class DroneCalibrationViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var gimbalCalibrationChoiceView: CalibrationChoiceView!
    @IBOutlet private weak var correctHorizonChoiceView: CalibrationChoiceView!
    @IBOutlet private weak var magnetometerChoiceView: CalibrationChoiceView!
    @IBOutlet private weak var obstacleDetectionChoiceView: CalibrationChoiceView!
    @IBOutlet private weak var missionsStackView: UIStackView!
    @IBOutlet private weak var mainView: UIView!

    // MARK: - Private Properties
    weak public var coordinator: DroneCalibrationCoordinator?
    private var viewModel = DroneCalibrationViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var firmwareAndMissionsUpdateListener: FirmwareAndMissionsListener?
    private var firmwareAndMissionToUpdateModel: FirmwareAndMissionToUpdateModel?
    private var moreMissionsProvider: DroneCalibrationMoreMissionsProvider?

    // MARK: - Private Enums
    private enum Constants {
        static let defaultTextColor: ColorName = .defaultTextColor
        static let defaultBackgroundColor: ColorName = .white
    }

    // MARK: - Setup
    static public func instantiate(coordinator: DroneCalibrationCoordinator,
                                   moreMissionProvider: DroneCalibrationMoreMissionsProvider? = nil) -> DroneCalibrationViewController {
        let viewController = StoryboardScene.DroneCalibration.initialScene.instantiate()
        viewController.coordinator = coordinator
        viewController.moreMissionsProvider = moreMissionProvider
        return viewController
    }

    // MARK: - Override Funcs
    open override func viewDidLoad() {
        super.viewDidLoad()

        setupAdditionalMissions()
        listenFirmwareUpdate()
        initUI()
        setupViewModels()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bindViewModel()
        LogEvent.log(.screen(LogEvent.Screen.droneCalibration))
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancellables = []
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIView.animate(withDuration: Style.shortAnimationDuration,
                       delay: Style.shortAnimationDuration,
                       options: .allowUserInteraction,
                       animations: {
            self.view.backgroundColor = ColorName.nightRider80.color
        })
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Landscape: display gimbal calibration first.
        // Portrait: display horizon correction first.
        let lastView: CalibrationChoiceView = UIApplication.isLandscape ? correctHorizonChoiceView : gimbalCalibrationChoiceView
        missionsStackView.addArrangedSubview(lastView)
    }

    open override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    open override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension DroneCalibrationViewController {
    /// Function called when a choice view is clicked.
    @IBAction func choiceViewTouchedUpInside(_ view: CalibrationChoiceView) {
        if view == gimbalCalibrationChoiceView {
            logEvent(with: LogEvent.LogKeyDroneDetailsCalibrationButton.gimbalCalibration)
            coordinator?.startGimbal()
        } else if view == correctHorizonChoiceView {
            coordinator?.startHorizonCorrection()
        } else if view == magnetometerChoiceView {
            logEvent(with: LogEvent.LogKeyDroneDetailsCalibrationButton.magnetometerCalibration)
            coordinator?.startMagnetometerCalibration()
        } else if view == obstacleDetectionChoiceView {
            logEvent(with: LogEvent.LogKeyDroneDetailsCalibrationButton.sensorCalibrationTutorial)
            if let firmwareAndMissionToUpdateModel = firmwareAndMissionToUpdateModel {
                if firmwareAndMissionToUpdateModel.updateRequired {
                    coordinator?.displayCriticalAlert()
                } else {
                    coordinator?.startStereoVisionCalibration()
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
        titleLabel.font = FontStyle.title.font(isRegularSizeClass)
        mainView.customCornered(corners: [.topLeft, .topRight], radius: Style.largeCornerRadius)
    }

    /// Sets up view models associated with the view.
    func setupViewModels() {
        gimbalCalibrationChoiceView.viewModel = CalibrationChoiceModel(image: Asset.Drone.icGimbal.image,
                                                                       title: L10n.droneGimbalTitle)
        correctHorizonChoiceView.viewModel = CalibrationChoiceModel(image: Asset.Drone.icCorrectHorizon.image,
                                                                    title: L10n.droneHorizonCalibration)
        magnetometerChoiceView.viewModel = CalibrationChoiceModel(image: Asset.Drone.icDroneDetailsAvailable.image,
                                                                  title: L10n.droneMagnetometerTitle)
        obstacleDetectionChoiceView.viewModel = CalibrationChoiceModel(image: Asset.Drone.icCalibrateStereoVision.image,
                                                                       title: L10n.droneObstacleDetectionTitle)
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
            .sink { [unowned self] flyingState in
                guard let flyingState = flyingState else {
                    // Drone is disconnected -> dismiss view
                    coordinator?.dismissDroneCalibration()
                    return
                }

                // Drone is flying -> dismiss view
                if flyingState == .flying {
                    coordinator?.dismissDroneCalibration()
                }
            }
            .store(in: &cancellables)
    }

    /// Updates the gimbal choice view
    func bindGimbal() {
        viewModel.$frontStereoGimbalState
            .combineLatest(viewModel.$gimbalCalibrationDescription)
            .sink { [unowned self]  (gimbalState, calibrationDescription) in
                if gimbalState == .needed {
                    gimbalCalibrationChoiceView.viewModel?.subtitle = gimbalState?.description ?? ""
                    gimbalCalibrationChoiceView.viewModel?.titleColor = ColorName.white.color
                    gimbalCalibrationChoiceView.viewModel?.subtitleColor = .white
                    gimbalCalibrationChoiceView.viewModel?.backgroundColor = .errorColor
                } else {
                    gimbalCalibrationChoiceView.viewModel?.subtitle = calibrationDescription
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

        viewModel.$gimbalCalibrationTitleColor
            .combineLatest(viewModel.$frontStereoGimbalState)
            .sink { [unowned self] (textColor, gimbalState) in
                if gimbalState != .needed {
                    let color = textColor ?? Constants.defaultTextColor
                    gimbalCalibrationChoiceView.viewModel?.titleColor = color.color
                    gimbalCalibrationChoiceView.viewModel?.subtitleColor = color
                }
            }
            .store(in: &cancellables)
    }

    /// Updates the magnetometer choice view
    func bindMagnetometer() {
        viewModel.$magnetometerState
            .sink { [unowned self] magnetometerState in
                let textColor = magnetometerState?.subtextColor ?? Constants.defaultTextColor
                magnetometerChoiceView.viewModel?.subtitle = magnetometerState?.description
                magnetometerChoiceView.viewModel?.titleColor = textColor.color
                magnetometerChoiceView.viewModel?.subtitleColor = textColor
                magnetometerChoiceView.viewModel?.backgroundColor = magnetometerState?.backgroundColor ?? Constants.defaultBackgroundColor
            }
            .store(in: &cancellables)
    }

    /// Updates the love calibration choice view
    func bindLoveCalibration() {
        viewModel.$stereoVisionSensorsState
            .sink { [unowned self] stereoVisionSensorsState in
                let textColor = stereoVisionSensorsState?.subtextColor ?? Constants.defaultTextColor
                obstacleDetectionChoiceView.viewModel?.subtitle = stereoVisionSensorsState?.description
                obstacleDetectionChoiceView.viewModel?.titleColor = textColor.color
                obstacleDetectionChoiceView.viewModel?.subtitleColor = textColor
                obstacleDetectionChoiceView.viewModel?.backgroundColor = stereoVisionSensorsState?.backgroundColor ?? Constants.defaultBackgroundColor
            }
            .store(in: &cancellables)
    }

    /// Dismiss the view.
    func dismissView() {
        self.view.backgroundColor = .clear
        coordinator?.dismissDroneCalibration()
    }

    /// Calls log event.
    ///
    /// - Parameters:
    ///     - itemName: Button name
    func logEvent(with itemName: String) {
        LogEvent.log(.simpleButton(itemName))
    }

    func listenFirmwareUpdate() {
        firmwareAndMissionsUpdateListener = FirmwareAndMissionsInteractor.shared
            .register { [weak self] (_, firmwareAndMissionToUpdateModel) in
                self?.firmwareAndMissionToUpdateModel = firmwareAndMissionToUpdateModel
            }
    }

    /// Adds additional missions to the missionsStackView.
    func setupAdditionalMissions() {
        guard let moreMissions = moreMissionsProvider?.moreMissions else { return }

        for mission in moreMissions {
            missionsStackView.insertArrangedSubview(mission.calibrationChoiceView, at: mission.positionInStack)
        }
    }
}
