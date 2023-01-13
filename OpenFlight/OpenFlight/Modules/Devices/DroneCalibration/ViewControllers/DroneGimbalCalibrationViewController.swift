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

/// View Controller used to display the drone gimbal calibration.
final class DroneGimbalCalibrationViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var mainView: UIView!
    @IBOutlet private weak var gimbalImageView: UIImageView!
    @IBOutlet private weak var synchronisationImageView: UIImageView!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var startButton: ActionButton!

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

        LogEvent.log(.screen(LogEvent.Screen.gimbalCalibration))
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelCalibrations()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension DroneGimbalCalibrationViewController {
    @IBAction func backButtonTouchedUpInside(_ sender: Any) {
        dismissView()
        cancelCalibrations()
    }

    @IBAction func backgroundButtonTouchedUpInside(_ sender: Any) {
        dismissView()
        cancelCalibrations()
    }

    @IBAction func startButtonTouchedUpInside(_ sender: Any) {
        descriptionLabel.text = L10n.gimbalCalibrationCameraMessage
        descriptionLabel.textColor = ActionButtonStyle.validate.backgroundColor
        descriptionLabel.font = FontStyle.big.font(isRegularSizeClass)
        gimbalImageView.contentMode = .scaleAspectFit
        gimbalImageView.image = Asset.Drone.icGimbalCamera.image
        synchronisationImageView.isHidden = isLoading
        synchronisationImageView.startRotate()
        startButton.updateStyle(.secondary1)
        startButton.isEnabled = isLoading
        startButton.alpha = 1

        if viewModel.isCalibrationRequested {
            viewModel.startGimbalCalibration()
        } else {
            dismissView()
        }

        LogEvent.log(.button(item: LogEvent.LogKeyDroneDetailsCalibrationButton.gimbalCalibrationStart,
                             value: viewModel.gimbalCalibrationDescription ?? ""))
    }
}

// MARK: - Private Funcs
private extension DroneGimbalCalibrationViewController {
    /// Dismiss the view.
    func dismissView() {
        self.view.backgroundColor = .clear
        coordinator?.dismissDroneCalibration()
    }

    /// Initializes all the UI for the view controller.
    func initUI() {
        mainView.customCornered(corners: [.topLeft, .topRight], radius: Style.largeCornerRadius)
        titleLabel.text = L10n.gimbalCalibrationTitle
        titleLabel.font = FontStyle.title.font(isRegularSizeClass)
        gimbalImageView.contentMode = .scaleAspectFit
        gimbalImageView.image = Asset.Drone.icGimbal.image
        descriptionLabel.text = L10n.gimbalCalibrationDescription
        descriptionLabel.textColor = ActionButtonStyle.action1.backgroundColor
        descriptionLabel.font = FontStyle.big.font(isRegularSizeClass)
        // Button in normal state.
        startButton.setup(title: L10n.commonStart, style: .validate)
        // Button in off state when it is calibrating.
        startButton.setTitle(L10n.gimbalCalibrationCalibrating, for: .disabled)
        startButton.setTitleColor(ColorName.defaultTextColor.color, for: .disabled)
        synchronisationImageView.isHidden = !isLoading
    }

    /// Starts watcher of published properties from view model.
    func bindViewModel() {
        viewModel.$gimbalCalibrationProcessState
            .removeDuplicates()
            .compactMap { $0 }
            .sink { [unowned self] gimbalCalibrationState in
                switch gimbalCalibrationState {
                case .success:
                    descriptionLabel.text = L10n.gimbalCalibrationStereoCameraMessage
                    descriptionLabel.textColor = ActionButtonStyle.validate.backgroundColor
                    descriptionLabel.font = FontStyle.big.font(isRegularSizeClass)
                    gimbalImageView.contentMode = .scaleAspectFit
                    gimbalImageView.image = Asset.Drone.icLoveCamera.image
                    viewModel.startFrontStereoGimbalCalibration()
                case .failure:
                    gimbalCalibrateFail()
                default:
                    break
                }
            }
            .store(in: &cancellables)

        viewModel.$frontStereoGimbalCalibrationProcessState
            .removeDuplicates()
            .compactMap { $0 }
            .sink { [unowned self] frontStereoGimbalCalibrationState in
                switch frontStereoGimbalCalibrationState {
                case .success:
                    gimbalCalibrateSuccess()
                case .failure:
                    gimbalCalibrateFail()
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    /// Update gimbal view after calibration success.
    func gimbalCalibrateSuccess() {
        gimbalImageView.contentMode = .center
        gimbalImageView.image = Asset.Common.Checks.icFillChecked.image

        synchronisationImageView.isHidden = !isLoading
        descriptionLabel.text = L10n.gimbalCalibrationSuccessful
        descriptionLabel.textColor = ActionButtonStyle.validate.backgroundColor
        descriptionLabel.font = FontStyle.big.font(isRegularSizeClass)
        startButton.isEnabled = !isLoading
        startButton.setup(title: L10n.ok, style: .validate)
    }

    /// Update gimbal view  after calibration failure.
    func gimbalCalibrateFail() {
        synchronisationImageView.isHidden = !isLoading
        startButton.isEnabled = !isLoading
        startButton.setup(title: L10n.droneCalibrationRedo, style: .validate)
        descriptionLabel.font = FontStyle.big.font(isRegularSizeClass)
        descriptionLabel.textColor = ActionButtonStyle.destructive.backgroundColor
        descriptionLabel.text = L10n.gimbalCalibrationFailed
    }

    func cancelCalibrations() {
        viewModel.cancelGimbalCalibration()
        viewModel.cancelFrontStereoGimbalCalibration()
    }
}
