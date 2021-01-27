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

/// View Controller used to display the drone gimbal calibration.
final class DroneGimbalCalibrationViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var mainView: UIView!
    @IBOutlet private weak var gimbalImageView: UIImageView!
    @IBOutlet private weak var synchronisationImageView: UIImageView!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var startButton: UIButton!

    // MARK: - Private Properties
    private weak var coordinator: DroneGimbalCalibrationCoordinator?
    private var viewModel = DroneCalibrationViewModel()
    private var isLoading: Bool = false

    // MARK: - Private Enums
    /// Enum which stores messages to log.
    private enum EventLoggerConstants {
        static let screenMessage: String = "GimbalCalibration"
    }

    // MARK: - Setup
    static func instantiate(coordinator: DroneGimbalCalibrationCoordinator) -> DroneGimbalCalibrationViewController {
        let viewController = StoryboardScene.DroneCalibration.droneGimbalCalibrationViewController.instantiate()
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

        logScreen(logMessage: EventLoggerConstants.screenMessage)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.viewModel.cancelFrontStereoGimbalCalibration()
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
private extension DroneGimbalCalibrationViewController {
    @IBAction func backButtonTouchedUpInside(_ sender: Any) {
        dismissView()
        self.viewModel.cancelGimbalCalibration()
        self.viewModel.cancelFrontStereoGimbalCalibration()
    }

    @IBAction func backgroundButtonTouchedUpInside(_ sender: Any) {
        dismissView()
        self.viewModel.cancelGimbalCalibration()
        self.viewModel.cancelFrontStereoGimbalCalibration()
    }

    @IBAction func startButtonTouchedUpInside(_ sender: Any) {
        switch self.viewModel.gimbalCalibrationState.value {
        case .gimbalOk:
            if self.viewModel.frontStereoGimbalCalibrationState.value == .calibrated {
                dismissView()
            }
        default:
            self.descriptionLabel.text = L10n.gimbalCalibrationMainCamMessage
            self.gimbalImageView.image = Asset.Drone.icGimbalCamera.image
            self.synchronisationImageView.isHidden = isLoading
            self.synchronisationImageView.startRotate()
            self.startButton.isEnabled = isLoading
            self.viewModel.startGimbalCalibration()
        }

        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.gimbal.name,
                             itemName: LogEvent.LogKeyDroneDetailsCalibrationButton.gimbalCalibrationStart,
                             newValue: self.viewModel.gimbalCalibrationState.value.description,
                             logType: .button)
    }
}

// MARK: - Private Funcs
private extension DroneGimbalCalibrationViewController {
    /// Called when the view needs to be dismissed.
    func dismissView() {
        self.view.backgroundColor = .clear
        self.coordinator?.dismissDroneCalibration()
    }

    /// Initializes all the UI for the view controller.
    func initUI() {
        self.gimbalImageView.image = Asset.Drone.icGimbal.image
        self.titleLabel.text = L10n.gimbalCalibrationTitle
        self.mainView.applyCornerRadius(Style.largeCornerRadius,
                                        maskedCorners: [.layerMinXMinYCorner,
                                                        .layerMaxXMinYCorner])
        self.descriptionLabel.textColor = ColorName.yellowSea.color
        self.descriptionLabel.text = L10n.gimbalCalibrationDescription
        self.startButton.cornerRadiusedWith(backgroundColor: ColorName.greenSpring20.color, radius: Style.largeCornerRadius)
        self.startButton.setTitleColor(ColorName.white.color, for: .normal)
        self.startButton.setTitle(L10n.commonStart, for: .normal)
        self.startButton.setTitleColor(ColorName.white50.color, for: .disabled)
        self.startButton.setTitle(L10n.gimbalCalibrationCalibrating, for: .disabled)
        self.synchronisationImageView.isHidden = !isLoading
    }

    /// Sets up view models associated with the view.
    func setupViewModels() {
        self.viewModel.gimbalCalibrationState.valueChanged = { [weak self] state in
            switch state {
            case .gimbalOk:
                self?.viewModel.frontStereoGimbalCalibrationState.set(.calibrating)
                self?.descriptionLabel.text = L10n.gimbalCalibrationSensorMessage
                self?.gimbalImageView.image = Asset.Drone.icLoveCamera.image
                self?.viewModel.startFrontStereoGimbalCalibration()
                self?.viewModel.frontStereoGimbalCalibrationState.valueChanged = { [weak self] frontStereoState in
                    switch frontStereoState {
                    case .calibrated:
                        self?.gimbalCalibrateSuccess()
                    case .calibrating:
                        break
                    default:
                        self?.gimbalCalibrateFail()
                    }
                }
            default :
                self?.gimbalCalibrateFail()
            }
        }
    }

    /// Update gimbal view  after calibration success.
    func gimbalCalibrateSuccess() {
        self.synchronisationImageView.isHidden = !isLoading
        self.startButton.isEnabled = !isLoading
        self.startButton.setTitle(L10n.ok, for: .normal)
        self.descriptionLabel.textColor = ColorName.greenSpring.color
        self.descriptionLabel.text = L10n.gimbalCalibrationSucceed
        self.startButton.setTitleColor(ColorName.greenSpring.color, for: .normal)
    }

    /// Update gimbal view  after calibration failure.
    func gimbalCalibrateFail() {
        self.synchronisationImageView.isHidden = !isLoading
        self.startButton.isEnabled = !isLoading
        self.startButton.setTitle(L10n.droneCalibrationRedo, for: .normal)
        self.descriptionLabel.textColor = ColorName.redTorch.color
        self.startButton.setTitleColor(ColorName.white.color, for: .normal)
        self.descriptionLabel.text = L10n.gimbalCalibrationFailed
    }
}
