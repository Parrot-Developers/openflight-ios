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

    // MARK: - Setup
    static func instantiate(coordinator: DroneCalibrationCoordinator) -> DroneCalibrationViewController {
        let viewController = StoryboardScene.DroneCalibration.initialScene.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initUI()
        self.setupViewModels()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.droneCalibration,
                             logType: .screen)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIView.animate(withDuration: Style.mediumAnimationDuration) {
            self.view.backgroundColor = ColorName.greyDark60.color
        }
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
        return .all
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
            self.coordinator?.startStereoVisionCalibration()
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
        self.titleLabel.text = L10n.remoteDetailsCalibration
        self.mainView.applyCornerRadius(Style.largeCornerRadius,
                                        maskedCorners: [.layerMinXMinYCorner,
                                                        .layerMaxXMinYCorner])
    }

    /// Updates the gimbal UI for the specified state.
    ///
    /// - Parameters:
    ///    - gimbalState: state of the gimbal.
    func updateGimbalUI(gimbalState: GimbalCalibrationState) {
        switch gimbalState {
        case .gimbalNotCalibrated:
            // TODO: Update text for none calibrated gimbal.
            self.gimbalCalibrationChoiceView.viewModel?.subText = ""
            self.gimbalCalibrationChoiceView.isUserInteractionEnabled = true
        case .gimbalError:
            // TODO: Update text for gimbal errors.
            self.gimbalCalibrationChoiceView.viewModel?.subText = ""
            self.gimbalCalibrationChoiceView.isUserInteractionEnabled = false
        case .gimbalOk:
            self.gimbalCalibrationChoiceView.viewModel?.subText = nil
            self.gimbalCalibrationChoiceView.isUserInteractionEnabled = true
        }
    }

    /// Sets up view models associated with the view.
    func setupViewModels() {
        self.gimbalCalibrationChoiceView.viewModel = CalibrationChoiceModel(image: Asset.Drone.icGimbal.image,
                                                                            text: L10n.droneGimbalTitle)
        self.correctHorizonChoiceView.viewModel = CalibrationChoiceModel(image: Asset.Drone.icCorrectHorizon.image,
                                                                         text: L10n.droneHorizonCalibration)
        self.magnetometerChoiceView.viewModel = CalibrationChoiceModel(image: Asset.Drone.icDroneDetails.image,
                                                                       text: L10n.droneMagnetometerTitle)
        self.obstacleDetectionChoiceView.viewModel = CalibrationChoiceModel(image: Asset.Drone.icCalibrateStereoVision.image,
                                                                            text: L10n.droneObstacleDetectionTitle)

        self.viewModel.state.valueChanged = { [weak self] state in
            self?.updateView(state: state)
            if let droneState = state.droneState,
               droneState == .disconnected || droneState == .disconnecting {
                self?.coordinator?.dismissDroneCalibration()
            }

            if let gimbalState = state.gimbalState {
                self?.updateGimbalUI(gimbalState: gimbalState)
            }

            if let flyingState = state.flyingState, flyingState == .flying {
                self?.coordinator?.dismissDroneCalibration()
            }
        }
        updateView(state: viewModel.state.value)
    }

    /// Updates the buttons with state.
    ///
    /// - Parameters:
    ///    - state: current state
    func updateView(state: DroneCalibrationState) {
        // Calibration button.
        obstacleDetectionChoiceView.viewModel?.subText = state.calibrationText
        obstacleDetectionChoiceView.viewModel?.subTextColor = state.stereoVisionSensorCalibrationNeeded ? .redTorch : .white50
        obstacleDetectionChoiceView.viewModel?.backgroundColor = state.stereoVisionSensorCalibrationNeeded ? .redTorch25 : .white10

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
}
