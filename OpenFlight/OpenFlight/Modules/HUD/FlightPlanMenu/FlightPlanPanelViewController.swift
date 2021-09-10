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

/// Manages HUD's flight plan right panel.
final class FlightPlanPanelViewController: UIViewController {
    // MARK: - Outlets

    @IBOutlet private weak var imageMenuView: UIView!
    @IBOutlet private weak var projectView: UIView!
    @IBOutlet private weak var projectNameLabel: UILabel!
    @IBOutlet private weak var projectButton: UIButton!
    @IBOutlet private weak var folderButton: UIButton! {
        didSet {
            folderButton.cornerRadiusedWith(backgroundColor: ColorName.white.color, radius: Style.largeCornerRadius)
        }
    }

    @IBOutlet private weak var pauseButton: UIButton!
    @IBOutlet private weak var historyButton: UIButton!
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var arrowView: SimpleArrowView! {
        didSet {
            arrowView.orientation = .bottom
        }
    }

    @IBOutlet private var emptyViews: [UIView]?
    @IBOutlet private weak var replayButton: UIButton!
    @IBOutlet private weak var stopButton: UIButton!
    @IBOutlet private weak var editButton: UIButton!
    @IBOutlet private weak var buttonsStackView: UIStackView!
    @IBOutlet private weak var noFlightPlanLabel: UILabel!
    @IBOutlet private weak var cameraStreamingContainerView: UIView!
    @IBOutlet private weak var progressViewContainer: UIView!
    @IBOutlet private weak var bottomStackViewSafeAreaTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bottomStackViewSuperviewTrailingConstraint: NSLayoutConstraint!

    // MARK: - Internal Properties

    /// Expose this label to customize it in extensions.
    var infoLabel: UILabel {
        return noFlightPlanLabel
    }
    /// Expose this button to customize it in extensions.
    var actionButton: UIButton {
        return editButton
    }
    var flightPlanPanelProgressView: FlightPlanPanelProgressView?
    var flightPlanPanelImageRateView: FlightPlanPanelImageRateView?
    var flightPlanPanelStatusView: UIView?

    // MARK: - Private Properties
    private var flightPlanPanelViewModel: FlightPlanPanelViewModel!
    private weak var cameraStreamingViewController: HUDCameraStreamingViewController?
    private var flightPlanPanelCoordinator: FlightPlanPanelCoordinator?
    private var cancellables = [AnyCancellable]()
    private var cancellableUpdating = [AnyCancellable]()
    private var cancellableProgressView: AnyCancellable?
    private var cancellableImageRateView: AnyCancellable?

    // MARK: - Private Enums
    private enum Constants {
        static let disableControlsDuration: TimeInterval = 0.75
    }

    // MARK: - Setup
    static func instantiate(flightPlanPanelViewModel: FlightPlanPanelViewModel) -> FlightPlanPanelViewController {
        let flightPlanPanelVC = StoryboardScene.FlightPlanPanel.initialScene.instantiate()
        flightPlanPanelVC.flightPlanPanelViewModel = flightPlanPanelViewModel
        return flightPlanPanelVC
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        bindViewModel()
        setupOrientationObserver()
        panelDidHide()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        initProgressView()
        initImageRateView()
        cancellableProgressView = flightPlanPanelViewModel.$progressModel
            .compactMap({ $0 })
            .sink(receiveValue: { [unowned self] model in
                self.flightPlanPanelProgressView?.model = model
            })

        cancellableImageRateView = flightPlanPanelViewModel.$imageRate
            .sink(receiveValue: { [unowned self] imageProvider in
                self.flightPlanPanelImageRateView?.setup(
                    provider: .init(dataSettings: imageProvider?.dataSettings),
                    settings: imageProvider?.settings ?? [])
            })
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancellableProgressView = nil
        flightPlanPanelProgressView?.removeFromSuperview()
        cancellableImageRateView = nil
        flightPlanPanelImageRateView?.removeFromSuperview()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Internal Funcs
extension FlightPlanPanelViewController {
    /// Starts streaming component.
    func startStream() {
        let cameraStreamingVC = HUDCameraStreamingViewController.instantiate()
        self.addChild(cameraStreamingVC)
        cameraStreamingContainerView.addWithConstraints(subview: cameraStreamingVC.view)
        cameraStreamingVC.mode = .preview
        cameraStreamingVC.didMove(toParent: self)
        self.cameraStreamingViewController = cameraStreamingVC
    }

    /// Stops streaming component.
    func stopStream() {
        self.cameraStreamingContainerView.subviews.first?.removeFromSuperview()
        self.cameraStreamingViewController?.removeFromParent()
        self.cameraStreamingViewController = nil
    }

    /// Panel did show.
    func panelDidShow() {
        self.view.isHidden = false
    }

    /// Panel did hide.
    func panelDidHide() {
        self.view.isHidden = true
    }

}

// MARK: - Actions
private extension FlightPlanPanelViewController {

    @IBAction func replayButtonTouchUpInside(_ sender: Any) {
        flightPlanPanelViewModel.replayFlightPlan()
    }

    @IBAction func pauseButtonTouchedUpInside(_ sender: Any) {
        flightPlanPanelViewModel.pauseFlightPlan()
    }

    /// History button touched up inside.
    @IBAction func historyTouchUpInside(_ sender: Any) {
        flightPlanPanelViewModel.historyTouchUpInside()
    }

    /// Project button touched up inside.
    @IBAction func projectTouchUpInside(_ sender: Any) {
        flightPlanPanelViewModel.projectTouchUpInside()
    }

    /// Play button touched up inside.
    @IBAction func playButtonTouchedUpInside(_ sender: Any) {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyHUDPanelButton.play.name,
                             newValue: nil,
                             logType: .button)
        disableControlsForDelay()
        flightPlanPanelViewModel.playButtonTouchedUpInside()
    }

    /// Edit button touched up inside.
    @IBAction func editButtonTouchedUpInside(_ sender: Any) {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyHUDPanelButton.edit.name,
                             newValue: nil,
                             logType: .button)
        flightPlanPanelViewModel.editButtonTouchedUpInside()
    }

    /// Stop button touched up inside.
    @IBAction func stopButtonTouchedUpInside(_ sender: Any) {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyHUDPanelButton.stop.name,
                             newValue: nil,
                             logType: .button)
        disableControlsForDelay()
        flightPlanPanelViewModel.stopFlightPlan()
    }
}

// MARK: - Private Funcs
private extension FlightPlanPanelViewController {
    /// Inits view.
    func initView() {
        pauseButton.cornerRadiusedWith(backgroundColor: .white, radius: Style.largeCornerRadius)
        projectNameLabel.text = L10n.flightPlanMenuProject.uppercased()
        folderButton.cornerRadiusedWith(backgroundColor: ColorName.white.color, radius: Style.largeCornerRadius)
        historyButton.cornerRadiusedWith(backgroundColor: ColorName.white.color, radius: Style.largeCornerRadius)
        playButton.makeup()
        playButton.setImage(Asset.Common.Icons.play.image, for: .normal)
        playButton.setTitleColor(ColorName.white.color, for: .normal)
        playButton.setTitleColor(ColorName.white30.color, for: .disabled)
        playButton.cornerRadiusedWith(backgroundColor: ColorName.highlightColor.color, radius: Style.largeCornerRadius)
        stopButton.cornerRadiusedWith(backgroundColor: ColorName.errorColor.color, radius: Style.largeCornerRadius)
        stopButton.setImage(Asset.Common.Icons.stop.image, for: .normal)
        editButton.cornerRadiusedWith(backgroundColor: ColorName.white.color, radius: Style.largeCornerRadius)
        editButton.tintColor = ColorName.defaultTextColor.color
        editButton.makeup(with: .large, color: .defaultTextColor)
        replayButton.cornerRadiusedWith(backgroundColor: ColorName.white.color, radius: Style.largeCornerRadius)
        replayButton.tintColor = ColorName.defaultTextColor.color
        replayButton.makeup(with: .large, color: .defaultTextColor)
        infoLabel.makeUp(with: .large, and: .defaultTextColor)
        imageMenuView.backgroundColor = ColorName.white.color
    }

    /// Inits progress view.
    func initProgressView() {
        let progressView = FlightPlanPanelProgressView(frame: progressViewContainer.frame)
        progressViewContainer.addWithConstraints(subview: progressView)
        self.flightPlanPanelProgressView = progressView
    }

    /// Inits progress view.
    func initImageRateView() {
        let imageRateView = FlightPlanPanelImageRateView(frame: imageMenuView.frame)
        imageMenuView.addWithConstraints(subview: imageRateView)
        self.flightPlanPanelImageRateView = imageRateView
    }

    private func updateButtons(_ information: FlightPlanPanelViewModel.ButtonsInformation) {

        self.playButton.isEnabled = information.areEnabled
        self.stopButton.isEnabled = information.areEnabled
        self.pauseButton.isEnabled = information.areEnabled

        switch information.startButtonState {
        case .canPlay:
            playButton.cornerRadiusedWith(backgroundColor: ColorName.highlightColor.color,
                                          radius: Style.largeCornerRadius)
        case .paused:
            playButton.cornerRadiusedWith(backgroundColor: ColorName.warningColor.color,
                                          radius: Style.largeCornerRadius)
        case .blockingIssue:
            playButton.backgroundColor = ColorName.errorColor.color
        }
    }

    /// Disables controls for a specified time interval.
    ///
    /// - Parameters:
    ///     - delay: enable controls after this delay
    func disableControlsForDelay(_ delay: TimeInterval = Constants.disableControlsDuration) {
        buttonsStackView.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: { [weak self] in
            self?.buttonsStackView.isUserInteractionEnabled = true
        })
    }

    /// Sets up observer for device orientation.
    func setupOrientationObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateTrailingConstraint),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
        updateTrailingConstraint()
    }

    /// Updates trailing constraint according to current orientation.
    @objc func updateTrailingConstraint() {
        switch UIApplication.shared.statusBarOrientation {
        case .landscapeLeft:
            bottomStackViewSuperviewTrailingConstraint.isActive = false
            bottomStackViewSafeAreaTrailingConstraint.isActive = true
        case .landscapeRight:
            bottomStackViewSafeAreaTrailingConstraint.isActive = false
            bottomStackViewSuperviewTrailingConstraint.isActive = true
        default:
            break
        }
    }

    func bindViewModel() {
        flightPlanPanelViewModel.$titleProject
            .sink(receiveValue: { [unowned self] title in
                self.projectButton.setTitle(title, for: .normal)
            })
            .store(in: &cancellables)

        flightPlanPanelViewModel.$viewState
            .sink { [unowned self] viewState in
                hiddeAllButtons()
                switch viewState {
                case .creation:
                    displayCreationState()

                case let .edition(hasHistory):
                    displayEditionState(hasHistory)

                case let .playing(duration):
                    displayPlayingState(duration: duration)

                case let .resumable(hasHistory):
                    displayResumableState(hasHistory: hasHistory)

                case .paused:
                    displayPausedState()

                case .rth:
                    displayRTHState()
                }
            }
            .store(in: &cancellables)

        flightPlanPanelViewModel.$buttonsState
            .sink { [unowned self] in updateButtons($0) }
            .store(in: &cancellables)

        flightPlanPanelViewModel.$extraViews
            .sink { [unowned self] in flightPlanPanelProgressView?.setExtraViews($0) }
            .store(in: &cancellables)

        flightPlanPanelViewModel.$createFirstTitle
            .sink { [unowned self] in
                self.infoLabel.text = $0 ?? ""
            }
            .store(in: &cancellables)
        flightPlanPanelViewModel.$newButtonTitle
            .sink { [unowned self] in
                self.editButton.setTitle($0 ?? "", for: .normal)
            }
            .store(in: &cancellables)
    }

    private func hiddeAllButtons() {
        self.pauseButton.isHidden = true
        self.playButton.isHidden = true
        self.stopButton.isHidden = true
        self.actionButton.isHidden = true
        self.flightPlanPanelProgressView?.isHidden = true
        self.editButton.isHidden = true
        self.projectView.isHidden = true
        self.noFlightPlanLabel.isHidden = true
        self.historyButton.isHidden = true
        self.stopButton.isHidden = true
        self.actionButton.isHidden = true
        self.replayButton.isHidden = true
        self.emptyViews?.forEach({ $0.isHidden = true })
    }

    private func displayCreationState() {
        self.editButton.setTitle(flightPlanPanelViewModel.newButtonTitle ?? "", for: .normal)
        self.editButton.setImage(nil, for: .normal)
        self.editButton.setTitleColor(ColorName.white.color, for: .normal)
        self.editButton.backgroundColor = ColorName.highlightColor.color
        self.editButton.isHidden = false
        self.noFlightPlanLabel.isHidden = false
    }

    private func displayEditionState(_ hasHistory: Bool) {
        self.playButton.isHidden = false
        self.flightPlanPanelProgressView?.isHidden = false
        self.editButton.setTitle("", for: .normal)
        self.editButton.setImage(Asset.Common.Icons.iconEdit.image, for: .normal)
        self.editButton.cornerRadiusedWith(backgroundColor: ColorName.white.color, radius: Style.largeCornerRadius)
        self.editButton.setTitleColor(ColorName.white.color, for: .normal)
        self.projectView.isHidden = false
        self.actionButton.isHidden = false
        self.buttonsStackView.distribution = .fillEqually
        self.historyButton.isHidden = !hasHistory
    }

    private func displayPlayingState(duration: TimeInterval) {
        self.pauseButton.isHidden = false
        self.flightPlanPanelProgressView?.isHidden = false
        self.projectView.isHidden = false
        self.stopButton.isHidden = false
        self.pauseButton.setTitle(duration.formattedHmsString, for: .normal)
        self.buttonsStackView.distribution = .fillProportionally
    }

    private func displayPausedState() {
        self.playButton.isHidden = false
        self.stopButton.isHidden = false
        self.flightPlanPanelProgressView?.isHidden = false
        self.projectView.isHidden = false
        self.buttonsStackView.distribution = .fillEqually
    }

    private func displayResumableState(hasHistory: Bool) {
        self.playButton.isHidden = false
        self.replayButton.isHidden = false
        self.flightPlanPanelProgressView?.isHidden = false
        self.projectView.isHidden = false
        self.buttonsStackView.distribution = hasHistory ? .fillEqually : .fillProportionally
        self.historyButton.isHidden = !hasHistory
    }

    private func displayRTHState() {
        self.stopButton.isHidden = false
        self.flightPlanPanelProgressView?.isHidden = false
        self.projectView.isHidden = false
        self.emptyViews?.forEach({ $0.isHidden = false })
        self.buttonsStackView.distribution = .fillProportionally
    }
}
