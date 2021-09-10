// Copyright (C) 2021 Parrot Drones SAS
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

import Foundation
import Combine

/// View Controller used to display the stereo vision calibration screen.
final class StereoCalibrationViewController: UIViewController {

    // MARK: - Outlet

    @IBOutlet weak var rightPanelView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var startCalibrationButton: UIButton!
    @IBOutlet weak var welcomeStackView: UIStackView!
    @IBOutlet weak var altitudeTextField: UITextField!

    // MARK: - Private Properties

    private var viewModel: StereoCalibrationViewModel!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Private Enums

    private enum Constants {
        static let currentOrientation: String = "orientation"
    }

    // MARK: - Setup

    /// Instantiates the view controller.
    ///
    /// - Parameters:
    ///     - viewModel: The view model used by the controller
    ///
    /// - Returns: A view controller of type StereoCalibrationViewController
    static func instantiate(viewModel: StereoCalibrationViewModel) -> StereoCalibrationViewController {
        let viewController = StoryboardScene.StereoCalibration.stereoCalibrationViewController.instantiate()
        viewController.viewModel = viewModel
        return viewController
    }

    // MARK: - Override Funcs

    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
        setupDelegate()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.sensorCalibrationTutorial,
                             logType: .screen)

        viewModel.startMission()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        viewModel.endMission()
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

private extension StereoCalibrationViewController {

    @IBAction func startCalibration(_ sender: Any) {
        welcomeStackView.isHidden = true
        let progressView = StereoCalibrationProgressView.instantiateView(viewModel: viewModel)
        rightPanelView.addWithConstraints(subview: progressView)
        viewModel.startCalibration(altitude: Float(altitudeTextField.text ?? "") ?? 0)
    }

    @IBAction func backButtonTouchedUpInside(_ sender: Any) {
        viewModel.back()
    }
}

// MARK: - UI Setup

private extension StereoCalibrationViewController {

    func initUI() {
        startCalibrationButton.cornerRadiusedWith(backgroundColor: ColorName.warningColor.color,
                                                  radius: Style.largeCornerRadius)
    }

    func setupDelegate() {
        altitudeTextField.delegate = self
    }

    func bindViewModel() {
        viewModel.$calibrationEnded
            .compactMap { $0 }
            .removeDuplicates()
            .sink { [unowned self] calibrationEnded in
                if calibrationEnded == .aborted {
                    viewModel.back()
                }

            }
            .store(in: &cancellables)

        viewModel.$gpsStrength
            .combineLatest(viewModel.$isFlying)
            .sink { [unowned self] (gpsStrength, isFlying) in
                warningLabel.text = viewModel.warningText(isFlying: isFlying, gpsStrength: gpsStrength)
            }
            .store(in: &cancellables)

        viewModel.$calibrationButtonIsEnable
            .sink { [unowned self] buttonIsEnable in
                startCalibrationButton.isEnabled = buttonIsEnable
                if buttonIsEnable == false {
                    startCalibrationButton.alpha = 0.6
                } else {
                    startCalibrationButton.alpha = 1.0
                }
            }
            .store(in: &cancellables)

        viewModel.$missionDescriptionMessage
            .sink { [unowned self] descriptionMessage in
                messageLabel.attributedText = descriptionMessage
            }
            .store(in: &cancellables)
    }
}

extension StereoCalibrationViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidChangeSelection(_ textField: UITextField) {
        viewModel.descriptionTitle(altitude: Int(altitudeTextField.text ?? "") ?? 0)
    }
}
