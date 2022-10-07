//    Copyright (C) 2021 Parrot Drones SAS
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
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var optimalCalibrationButton: ActionButton!
    @IBOutlet weak var welcomeStackView: RightSidePanelStackView!
    @IBOutlet weak var stopView: StopView!
    @IBOutlet weak var quickCalibrationButton: ActionButton!
    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var alertLabel: UILabel!
    @IBOutlet weak var animationImageView: UIImageView!
    @IBOutlet weak var countdownLabel: UILabel!

    private let progressView = StereoCalibrationProgressView()

    // MARK: - Private Properties

    private var viewModel: StereoCalibrationViewModel!
    private var cancellables = Set<AnyCancellable>()

    private var fisrtAttributes: [NSAttributedString.Key: UIFont] {
        return isRegularSizeClass ?
        [NSAttributedString.Key.font: UIFont(name: "Rajdhani-Semibold", size: 18.0) ?? UIFont.systemFont(ofSize: 10)] :
        [NSAttributedString.Key.font: UIFont(name: "Rajdhani-Semibold", size: 15.0) ?? UIFont.systemFont(ofSize: 10)]
    }

    private var secondeAttributes: [NSAttributedString.Key: UIFont] {
        return isRegularSizeClass ?
        [NSAttributedString.Key.font: UIFont(name: "Rajdhani-Semibold", size: 15.0) ?? UIFont.systemFont(ofSize: 10)] :
        [NSAttributedString.Key.font: UIFont(name: "Rajdhani-Semibold", size: 13.0) ?? UIFont.systemFont(ofSize: 10)]
    }

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

        viewModel.ophtalmoService
            .calibrationStatusPublisher
            .compactMap { $0 }
            .removeDuplicates()
            .sink { [unowned self] status in
                switch status {
                case .idle:
                    progressView.removeFromSuperview()
                    welcomeStackView.isHidden = false
                default:
                    welcomeStackView.isHidden = true
                    viewModel.updateCalibrationWith(altitude: viewModel.ophtalmoService.altitude)
                    progressView.setup(viewModel: viewModel)
                    rightPanelView.addWithConstraints(subview: progressView)
                }
            }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.log(.screen(LogEvent.Screen.sensorCalibrationTutorial))

        viewModel.startMission()
        alertView.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        viewModel.endMission()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let topBarVc = segue.destination as? HUDTopBarViewController {
            topBarVc.navigationDelegate = self
        }
    }
}

// MARK: - Actions

private extension StereoCalibrationViewController {

    @IBAction func startOptimalCalibration(_ sender: Any) {
        viewModel.startCalibration(altitude: Constants.optimalAltitude)
    }

    @IBAction func startQuickCalibration(_ sender: Any) {
        viewModel.startCalibration(altitude: Constants.quickAltitude)
    }
}

// MARK: - UI Setup

private extension StereoCalibrationViewController {

    func initUI() {
        titleLabel.text = L10n.loveCalibrationTitle
        messageLabel.text = L10n.loveCalibrationSetupMessage

        let optimalAttributedString = NSMutableAttributedString(string: L10n.loveCalibrationOptimal, attributes: fisrtAttributes)

        let optimalAttributesText2 = NSAttributedString(string: "\n" + L10n.loveCalibrationOptimalDescription, attributes: secondeAttributes)
        optimalAttributedString.append(optimalAttributesText2)

        optimalCalibrationButton.setup(style: .default1)
        optimalCalibrationButton.setAttributedTitle(optimalAttributedString, for: .normal)

        let quickAttributedString = NSMutableAttributedString(string: L10n.loveCalibrationQuick, attributes: fisrtAttributes)

        let quickAttributedText2 = NSAttributedString(string: "\n" + L10n.loveCalibrationQuickDescription, attributes: secondeAttributes)
        quickAttributedString.append(quickAttributedText2)

        quickCalibrationButton.setup(style: .default1)
        quickCalibrationButton.setAttributedTitle(quickAttributedString, for: .normal)

        alertView.cornerRadiusedWith(backgroundColor: .white, radius: Style.largeCornerRadius)
        alertLabel.makeUp(with: .large)
        alertLabel.textColor = .black

        stopView.style = .classic
        stopView.delegate = self

        countdownLabel.makeUp(with: .giant, and: .defaultTextColor)
    }

    func bindViewModel() {
        viewModel.$calibrationMessage
            .removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.messageLabel.text = $0
            }
            .store(in: &cancellables)

        viewModel.$shouldHideMessageLabel
            .removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.messageLabel.isHidden = $0
            }
            .store(in: &cancellables)

        viewModel.$subtitle
            .removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.subtitleLabel.text = $0
                self.subtitleLabel.isHidden = $0 == nil
            }
            .store(in: &cancellables)

        viewModel.$subtitleColor
            .removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.subtitleLabel.textColor = $0
            }
            .store(in: &cancellables)

        viewModel.$animationImages
            .removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                if let animationImages = $0 {
                    self.animationImageView.image = UIImage.animatedImage(with: animationImages,
                                                                          duration: Style.longAnimationDuration)
                    self.animationImageView.startAnimating()
                } else {
                    self.animationImageView.image = nil
                }
            }
            .store(in: &cancellables)

        viewModel.$countdownMessage
            .removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                if let countdownMessage = $0 {
                    self.countdownLabel.text = countdownMessage
                }
                self.countdownLabel.alphaHidden($0 == nil)
            }
            .store(in: &cancellables)

        viewModel.$warningText
            .sink { [unowned self] warningText in
                warningLabel.isHidden = warningText == nil
                warningLabel.text = warningText
            }
            .store(in: &cancellables)

        viewModel.$isCalibrationButtonEnabled
            .removeDuplicates()
            .combineLatest(viewModel.$isCalibrationButtonHidden.removeDuplicates())
            .sink { [unowned self] isCalibrationButtonEnabled, isCalibrationButtonHidden in
                optimalCalibrationButton.isHidden = isCalibrationButtonHidden
                quickCalibrationButton.isHidden = isCalibrationButtonHidden
                stopView.isHidden = !isCalibrationButtonHidden
                optimalCalibrationButton.isEnabled = isCalibrationButtonEnabled
                quickCalibrationButton.isEnabled = isCalibrationButtonEnabled
                optimalCalibrationButton.alphaWithEnabledState(isCalibrationButtonEnabled)
                quickCalibrationButton.alphaWithEnabledState(isCalibrationButtonEnabled)
            }
            .store(in: &cancellables)

        viewModel.errorMessage
            .dropFirst()
            .sink { [unowned self] error in
                if let error = error {
                    alertLabel.text = error.label
                    alertLabel.isHidden = false
                    alertView.isHidden = false
                } else {
                    alertLabel.isHidden = true
                    alertView.isHidden = true
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - HUD Top Bar Navigation
extension StereoCalibrationViewController: HUDTopBarViewControllerNavigation {
    func openDashboard() {
        viewModel.askingForBack()
    }

    func openSettings(_ type: SettingsType?) {
        viewModel.openSettings(type)
    }

    func openRemoteControlInfos() {
        viewModel.openRemoteControlInfos()
    }

    func openDroneInfos() {
        viewModel.openDroneInfos()
    }

    func back() {
        viewModel.askingForBack()
    }
}

// MARK: - StopViewDelegate
extension StereoCalibrationViewController: StopViewDelegate {
    func didClickOnStop() {
        viewModel.stop()
    }
}
