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
    private var viewModel: DroneCalibrationViewModel!
    private var cancellables = Set<AnyCancellable>()
    private var isLoading: Bool = false

    // MARK: - Setup
    static func instantiate(coordinator: DroneGimbalCalibrationCoordinator, viewModel: DroneCalibrationViewModel ) -> DroneGimbalCalibrationViewController {
        let viewController = StoryboardScene.DroneCalibration.droneGimbalCalibrationViewController.instantiate()
        viewController.coordinator = coordinator
        viewController.viewModel = viewModel
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.gimbalCalibration,
                             logType: .screen)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.cancelCalibrations()
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
private extension DroneGimbalCalibrationViewController {
    @IBAction func backButtonTouchedUpInside(_ sender: Any) {
        dismissView()
        self.cancelCalibrations()
    }

    @IBAction func backgroundButtonTouchedUpInside(_ sender: Any) {
        dismissView()
        self.cancelCalibrations()
    }

    @IBAction func startButtonTouchedUpInside(_ sender: Any) {
        self.descriptionLabel.makeUp(with: .large, and: .highlightColor)
        self.descriptionLabel.text = L10n.gimbalCalibration8kCameraMessage
        self.gimbalImageView.image = Asset.Drone.icGimbalCamera.image
        self.synchronisationImageView.isHidden = isLoading
        self.synchronisationImageView.startRotate()
        self.startButton.customCornered(corners: [.allCorners],
                                        radius: Style.largeCornerRadius,
                                        backgroundColor: ColorName.white.color,
                                        borderColor: ColorName.defaultTextColor.color,
                                        borderWidth: Style.smallBorderWidth)
        self.startButton.isEnabled = isLoading

        if viewModel.isCalibrationRequested {
            viewModel.startGimbalCalibration()
        } else {
            dismissView()
        }

        LogEvent.logAppEvent(itemName: LogEvent.LogKeyDroneDetailsCalibrationButton.gimbalCalibrationStart,
                             newValue: viewModel.gimbalCalibrationDescription,
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
        gimbalImageView.image = Asset.Drone.icGimbal.image
        titleLabel.text = L10n.gimbalCalibrationTitle
        mainView.customCornered(corners: [.topLeft, .topRight], radius: Style.largeCornerRadius)
        descriptionLabel.makeUp(with: .large, and: .warningColor)
        descriptionLabel.text = L10n.gimbalCalibrationDescription
        startButton.customCornered(corners: [.allCorners],
                                        radius: Style.largeCornerRadius,
                                        backgroundColor: ColorName.highlightColor.color,
                                        borderColor: .clear,
                                        borderWidth: Style.smallBorderWidth)
        startButton.setTitleColor(ColorName.white.color, for: .normal)
        startButton.setTitle(L10n.commonStart, for: .normal)
        startButton.setTitleColor(ColorName.defaultTextColor.color, for: .disabled)
        startButton.setTitle(L10n.gimbalCalibrationCalibrating, for: .disabled)
        synchronisationImageView.isHidden = !isLoading
    }

    func bindViewModel() {
        viewModel.$gimbalCalibrationState
            .removeDuplicates()
            .sink { [unowned self] gimbalCalibrationState in
                switch gimbalCalibrationState {
                case.calibrated:
                    descriptionLabel.makeUp(with: .large, and: .highlightColor)
                    descriptionLabel.text = L10n.gimbalCalibrationLoveCameraMessage
                    gimbalImageView.image = Asset.Drone.icLoveCamera.image
                    viewModel.startFrontStereoGimbalCalibration()
                    viewModel.updateFrontStereoGimbalCalibrationState(state: .calibrating)

                default :
                    gimbalCalibrateFail()
                }
            }
            .store(in: &cancellables)

        viewModel.$frontStereoGimbalCalibrationState
            .sink { [unowned self] frontStereoGimbalCalibrationState in
                switch frontStereoGimbalCalibrationState {
                case.calibrating:
                    return

                case .calibrated:
                    gimbalCalibrateSuccess()

                default:
                    gimbalCalibrateFail()
                }
            }
            .store(in: &cancellables)
    }

    /// Update gimbal view  after calibration success.
    func gimbalCalibrateSuccess() {
        gimbalImageView.image = Asset.Common.Checks.icFillChecked.image
        synchronisationImageView.isHidden = !isLoading
        descriptionLabel.makeUp(with: .huge, and: .highlightColor)
        descriptionLabel.text = L10n.gimbalCalibrationSucceed
        startButton.isEnabled = !isLoading
        startButton.setTitle(L10n.ok, for: .normal)
        startButton.customCornered(corners: [.allCorners],
                                        radius: Style.largeCornerRadius,
                                        backgroundColor: ColorName.highlightColor.color,
                                        borderColor: .clear,
                                        borderWidth: Style.smallBorderWidth)
        startButton.setTitleColor(ColorName.white.color, for: .normal)
    }

    /// Update gimbal view  after calibration failure.
    func gimbalCalibrateFail() {
        synchronisationImageView.isHidden = !isLoading
        startButton.isEnabled = !isLoading
        startButton.setTitle(L10n.droneCalibrationRedo, for: .normal)
        startButton.setTitleColor(ColorName.white.color, for: .normal)
        descriptionLabel.makeUp(with: .large, and: .errorColor)
        descriptionLabel.text = L10n.gimbalCalibrationFailed
    }

    func cancelCalibrations() {
        viewModel.cancelGimbalCalibration()
        viewModel.cancelFrontStereoGimbalCalibration()
    }
}
