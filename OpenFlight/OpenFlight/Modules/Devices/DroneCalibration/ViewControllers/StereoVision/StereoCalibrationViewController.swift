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
    @IBOutlet weak var optimalCalibrationButton: UIButton!
    @IBOutlet weak var welcomeStackView: UIStackView!
    @IBOutlet weak var quickCalibrationButton: UIButton!

    // MARK: - Private Properties

    private var viewModel: StereoCalibrationViewModel!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Private Enums

    private enum Constants {
        static let currentOrientation: String = "orientation"
        static let optimalAltitude: Float = 120.0
        static let quickAltitude: Float = 50.0
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

    @IBAction func startOptimalCalibration(_ sender: Any) {
        welcomeStackView.isHidden = true
        let progressView = StereoCalibrationProgressView.instantiateView(viewModel: viewModel)
        rightPanelView.addWithConstraints(subview: progressView)
        viewModel.updateCalibrationWith(altitude: 120)
        viewModel.startCalibration(altitude: Constants.optimalAltitude)
    }

    @IBAction func startQuickCalibration(_ sender: Any) {
        welcomeStackView.isHidden = true
        let progressView = StereoCalibrationProgressView.instantiateView(viewModel: viewModel)
        rightPanelView.addWithConstraints(subview: progressView)
        viewModel.updateCalibrationWith(altitude: 50)
        viewModel.startCalibration(altitude: Constants.quickAltitude)
    }

    @IBAction func backButtonTouchedUpInside(_ sender: Any) {
        viewModel.back()
    }
}

// MARK: - UI Setup

private extension StereoCalibrationViewController {

    func initUI() {
        messageLabel.text = L10n.loveCalibrationSetupMessage

        optimalCalibrationButton.cornerRadiusedWith(backgroundColor: UIColor.white,
                                                  radius: Style.largeCornerRadius)
        optimalCalibrationButton.setTitle(L10n.loveCalibrationOptimal, for: .normal)
        optimalCalibrationButton.titleLabel?.textAlignment = .center

        quickCalibrationButton.cornerRadiusedWith(backgroundColor: UIColor.white,
                                                  radius: Style.largeCornerRadius)
        quickCalibrationButton.setTitle(L10n.loveCalibrationQuick, for: .normal)
        quickCalibrationButton.titleLabel?.textAlignment = .center

    }

    func bindViewModel() {
        viewModel.$warningText
            .sink { [unowned self] warningText in
                warningLabel.text = warningText
            }
            .store(in: &cancellables)

        viewModel.$calibrationButtonIsEnable
            .sink { [unowned self] buttonIsEnable in
                optimalCalibrationButton.isEnabled = buttonIsEnable
                quickCalibrationButton.isEnabled = buttonIsEnable
                if buttonIsEnable == false {
                    optimalCalibrationButton.alpha = 0.6
                    quickCalibrationButton.alpha = 0.6
                } else {
                    optimalCalibrationButton.alpha = 1.0
                    quickCalibrationButton.alpha = 1.0
                }
            }
            .store(in: &cancellables)
    }
}
