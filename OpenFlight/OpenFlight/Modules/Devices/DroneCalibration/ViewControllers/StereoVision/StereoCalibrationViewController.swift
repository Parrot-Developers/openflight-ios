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

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var optimalCalibrationButton: ActionButton!
    @IBOutlet weak var welcomeStackView: RightSidePanelStackView!
    @IBOutlet weak var stopView: StopView!
    @IBOutlet weak var quickCalibrationButton: ActionButton!
    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var alertLabel: UILabel!
    @IBOutlet weak var alertPanelContainerView: UIView!
    @IBOutlet weak var alertControls: AlertControls!
    @IBOutlet weak var progressView: StereoCalibrationProgressView!

    // MARK: - Private Properties

    private var viewModel: StereoCalibrationViewModel!
    private var cancellables = Set<AnyCancellable>()
    private weak var alertPanel: HUDAlertPanelViewController?

    private var firstAttributes: [NSAttributedString.Key: UIFont] {
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.log(.screen(LogEvent.Screen.sensorCalibrationTutorial))
        setupConstraints()
        viewModel.startMission()
        alertView.isHidden = true
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
        titleLabel.makeUp(with: .title, color: .defaultTextColor)
        stateLabel.makeUp(with: .current, color: .defaultTextColor80)
        messageLabel.text = L10n.loveCalibrationSetupMessage

        let optimalAttributedString = NSMutableAttributedString(string: L10n.loveCalibrationOptimal, attributes: firstAttributes)

        let optimalAttributesText2 = NSAttributedString(string: "\n" + L10n.loveCalibrationOptimalDescription, attributes: secondeAttributes)
        optimalAttributedString.append(optimalAttributesText2)

        optimalCalibrationButton.setup(style: .default1)
        optimalCalibrationButton.setAttributedTitle(optimalAttributedString, for: .normal)

        let quickAttributedString = NSMutableAttributedString(string: L10n.loveCalibrationQuick, attributes: firstAttributes)

        let quickAttributedText2 = NSAttributedString(string: "\n" + L10n.loveCalibrationQuickDescription, attributes: secondeAttributes)
        quickAttributedString.append(quickAttributedText2)

        quickCalibrationButton.setup(style: .default1)
        quickCalibrationButton.setAttributedTitle(quickAttributedString, for: .normal)

        alertView.cornerRadiusedWith(backgroundColor: .white, radius: Style.largeCornerRadius)
        alertLabel.makeUp(with: .large)
        alertLabel.textColor = .black

        stopView.style = .classic
        stopView.delegate = self

        progressView.setup(viewModel: viewModel)

        addAlertPanel()
    }

    /// Adds left panel for proactive alerts.
    func addAlertPanel() {
        guard alertPanel == nil else { return }

        let alertPanel = HUDAlertPanelViewController.instantiate()
        alertPanel.delegate = alertControls
        add(alertPanel, in: alertPanelContainerView)
        self.alertPanel = alertPanel
    }

    /// Removes left panel for proactive alerts.
    func removeAlertPanel() {
        alertControls.hideAlertPanel()
        alertPanel?.remove()
        alertPanel = nil
    }

    /// Sets up constraints.
    func setupConstraints() {
        alertControls.updateConstraints(animated: false)
    }

    /// Starts watcher of published properties from view model..
    func bindViewModel() {
        viewModel.shouldHideProgressViewPublisher
            .removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.progressView.isHidden = $0
                self.welcomeStackView.isHidden = !$0
            }
            .store(in: &cancellables)

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

        viewModel.$warningText
            .removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.warningLabel.isHidden = $0 == nil
                self.warningLabel.text = $0
            }
            .store(in: &cancellables)

        viewModel.$isCalibrationButtonEnabled
            .removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.optimalCalibrationButton.isEnabled = $0
                self.quickCalibrationButton.isEnabled = $0
                self.optimalCalibrationButton.alphaWithEnabledState($0)
                self.quickCalibrationButton.alphaWithEnabledState($0)
            }
            .store(in: &cancellables)

        viewModel.$calibrationStateHidden
            .removeDuplicates()
            .sink { [unowned self] in
                stateLabel.isHidden = $0
            }
            .store(in: &cancellables)

        viewModel.$calibrationStateColor
            .removeDuplicates()
            .sink { [unowned self] in
                stateLabel.textColor = $0
            }
            .store(in: &cancellables)

        viewModel.$calibrationStateText
            .removeDuplicates()
            .sink { [unowned self] in
                stateLabel.text = $0
            }
            .store(in: &cancellables)

        viewModel.$alertMessage
            .removeDuplicates()
            .sink { [weak self] message in
                guard let self = self else { return }
                self.alertLabel.text = message
                self.alertView.isHidden = message == nil
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
        viewModel.stopHandLaunch()
    }
}
