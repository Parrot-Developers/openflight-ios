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
    @IBOutlet private weak var gestureView: UIView!
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

    // MARK: - Private Properties
    private var flightPlanPanelViewModel: FlightPlanPanelViewModel!
    private weak var cameraStreamingViewController: HUDCameraStreamingViewController?
    private weak var mapViewController: MapViewController?

    private weak var flightPlanPanelCoordinator: FlightPlanPanelCoordinator?
    private var cancellables = [AnyCancellable]()
    private var cancellableImageRateView: AnyCancellable?

    private var containerStatus: ContainerStatus = .streaming

    // MARK: - Private Enums
    private enum Constants {
        static let disableControlsDuration: TimeInterval = 0.75
        static let buttonsPadding: CGFloat = 10.0
        static let buttonDisabledAlpha: CGFloat = 0.6
        static let buttonEnabledAlpha: CGFloat = 1
    }

    private enum ContainerStatus: Int, CustomStringConvertible {
        /// Container is showing the map
        case map
        /// Container is showing the streaming
        case streaming

        /// Debug description.
        public var description: String {
            switch self {
            case .map:          return "map"
            case .streaming:    return "streaming"
            }
        }
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
        initProgressView()
        bindViewModel()
        setupOrientationObserver()
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        gestureView.addGestureRecognizer(tap)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        containerStatus = .streaming
        initImageRateView()
        cancellableImageRateView = flightPlanPanelViewModel.$imageRate
            .sink(receiveValue: { [unowned self] imageProvider in
                self.flightPlanPanelImageRateView?.setup(
                    provider: .init(dataSettings: imageProvider?.dataSettings),
                    settings: imageProvider?.settings ?? [])
            })
        startStream()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        panelDidShow()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        panelDidHide()
        cancellableImageRateView = nil
        flightPlanPanelImageRateView?.removeFromSuperview()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        switch containerStatus {
        case .map:
            startStream()
            hideMiniMap()
            containerStatus = .streaming
            flightPlanPanelViewModel.showMap()
        case .streaming:
            stopStream()
            showMiniMap()
            containerStatus = .map
            flightPlanPanelViewModel.showStream()
        }
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
        guard cameraStreamingViewController == nil else { return }
        let cameraStreamingVC = HUDCameraStreamingViewController.instantiate()
        addChild(cameraStreamingVC)

        cameraStreamingContainerView.addWithConstraints(subview: cameraStreamingVC.view)
        cameraStreamingVC.mode = .preview
        cameraStreamingVC.didMove(toParent: self)
        cameraStreamingViewController = cameraStreamingVC
        cameraStreamingContainerView.isExclusiveTouch = true
    }

    /// Stops streaming component.
    func stopStream() {
        cameraStreamingContainerView.subviews.first?.removeFromSuperview()
        cameraStreamingViewController?.removeFromParent()
        cameraStreamingViewController = nil
    }

    /// Panel did show.
    func panelDidShow() {
        self.view.isHidden = false
    }

    /// Panel did hide.
    func panelDidHide() {
        self.view.isHidden = true
        flightPlanPanelViewModel.showMap()
        if containerStatus != .streaming {
            hideMiniMap()
            startStream()
            containerStatus = .streaming
        }
    }

    /// Show the map in container
    func showMiniMap() {
        let mapViewControllerVC = MapViewController.instantiate()
        self.addChild(mapViewControllerVC)
        cameraStreamingContainerView.addWithConstraints(subview: mapViewControllerVC.view)
        mapViewControllerVC.didMove(toParent: self)
        mapViewController = mapViewControllerVC
        mapViewController?.clearGraphics()
        cameraStreamingContainerView.isUserInteractionEnabled = false
    }

    /// Hide the map in container.
    func hideMiniMap() {
        cameraStreamingContainerView.subviews.first?.removeFromSuperview()
        mapViewController?.removeFromParent()
        mapViewController = nil
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
        containerStatus = .streaming
        flightPlanPanelViewModel.showMap()
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
        pauseButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: Constants.buttonsPadding, bottom: 0, right: -Constants.buttonsPadding)
        pauseButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: Constants.buttonsPadding)
        pauseButton.setImage(Asset.Common.Icons.pause.image, for: .normal)
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
        editButton.contentMode = .center
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
        flightPlanPanelProgressView = progressView
    }

    /// Inits progress view.
    func initImageRateView() {
        let imageRateView = FlightPlanPanelImageRateView(frame: imageMenuView.frame)
        imageMenuView.addWithConstraints(subview: imageRateView)
        flightPlanPanelImageRateView = imageRateView
    }

    private func updateButtons(_ information: FlightPlanPanelViewModel.ButtonsInformation) {

        playButton.isEnabled = information.areEnabled
        stopButton.isEnabled = information.areEnabled
        pauseButton.isEnabled = information.areEnabled

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
        flightPlanPanelViewModel.$progressModel
            .compactMap({ $0 })
            .sink(receiveValue: { [unowned self] model in
                self.flightPlanPanelProgressView?.model = model
            })
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
        pauseButton.isHidden = true
        playButton.isHidden = true
        stopButton.isHidden = true
        actionButton.isHidden = true
        flightPlanPanelProgressView?.isHidden = true
        editButton.isHidden = true
        projectView.isHidden = true
        noFlightPlanLabel.isHidden = true
        historyButton.isHidden = true
        stopButton.isHidden = true
        actionButton.isHidden = true
        replayButton.isHidden = true
        emptyViews?.forEach({ $0.isHidden = true })
    }

    private func displayCreationState() {
        editButton.setTitle(flightPlanPanelViewModel.newButtonTitle ?? "", for: .normal)
        editButton.setImage(nil, for: .normal)
        editButton.setTitleColor(ColorName.white.color, for: .normal)
        editButton.backgroundColor = ColorName.highlightColor.color
        editButton.isHidden = false
        noFlightPlanLabel.isHidden = false
    }

    private func displayEditionState(_ hasHistory: Bool) {
        playButton.isHidden = false
        flightPlanPanelProgressView?.isHidden = false
        editButton.setTitle("", for: .normal)
        editButton.setImage(Asset.Common.Icons.iconEdit.image, for: .normal)
        editButton.contentMode = .center
        editButton.cornerRadiusedWith(backgroundColor: ColorName.white.color, radius: Style.largeCornerRadius)
        editButton.setTitleColor(ColorName.white.color, for: .normal)
        projectView.isHidden = false
        actionButton.isHidden = false
        buttonsStackView.distribution = .fillEqually
        historyButton.isHidden = false
        historyButton.isEnabled = hasHistory
        historyButton.alpha = hasHistory ? Constants.buttonEnabledAlpha : Constants.buttonDisabledAlpha
    }

    private func displayPlayingState(duration: TimeInterval) {
        pauseButton.isHidden = false
        flightPlanPanelProgressView?.isHidden = false
        projectView.isHidden = false
        stopButton.isHidden = false
        pauseButton.setTitle(duration.formattedHmsString, for: .normal)
        buttonsStackView.distribution = .fillProportionally
    }

    private func displayPausedState() {
        playButton.isHidden = false
        stopButton.isHidden = false
        flightPlanPanelProgressView?.isHidden = false
        projectView.isHidden = false
        buttonsStackView.distribution = .fillEqually
    }

    private func displayResumableState(hasHistory: Bool) {
        playButton.isHidden = false
        replayButton.isHidden = false
        flightPlanPanelProgressView?.isHidden = false
        projectView.isHidden = false
        buttonsStackView.distribution = hasHistory ? .fillEqually : .fillProportionally
        historyButton.isHidden = false
        historyButton.isEnabled = hasHistory
        historyButton.alpha = hasHistory ? Constants.buttonEnabledAlpha : Constants.buttonDisabledAlpha
    }

    private func displayRTHState() {
        stopButton.isHidden = false
        flightPlanPanelProgressView?.isHidden = false
        projectView.isHidden = false
        emptyViews?.forEach({ $0.isHidden = false })
        buttonsStackView.distribution = .fillProportionally
    }
}
