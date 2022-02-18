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

/// Manages HUD's flight plan right panel.
final class FlightPlanPanelViewController: UIViewController {
    // MARK: - Outlets

    @IBOutlet private weak var imageMenuView: UIView!
    @IBOutlet private weak var projectStackView: MainContainerStackView!
    @IBOutlet private weak var projectButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var projectNameLabel: UILabel!
    @IBOutlet private weak var projectTitleLabel: UILabel!
    @IBOutlet private weak var folderButton: ActionButton!
    @IBOutlet private weak var noFlightPlanContainer: UIView!
    @IBOutlet private weak var noFlightPlanLabel: UILabel!
    @IBOutlet private weak var cameraStreamingContainerView: UIView!
    @IBOutlet private weak var gestureView: UIView!
    @IBOutlet private weak var cameraStreamingBottomBannerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bottomStackView: MainContainerStackView!
    @IBOutlet private weak var progressViewContainer: FlightPlanPanelProgressView!

    // Action Buttons
    @IBOutlet private weak var buttonsStackView: ActionStackView!
    @IBOutlet private weak var createButton: ActionButton!
    @IBOutlet private weak var playButton: ActionButton!
    @IBOutlet private weak var editButton: ActionButton!
    @IBOutlet private weak var stopLeadingSpacer: HSpacerView!
    @IBOutlet private weak var stopTrailingSpacer: HSpacerView!
    @IBOutlet private weak var stopButton: ActionButton!
    @IBOutlet private weak var historyButton: ActionButton!
    @IBOutlet private var actionButtons: [ActionButton]!

    // MARK: - Internal Properties
    var flightPlanPanelImageRateView: FlightPlanPanelImageRateView?

    // MARK: - Private Properties
    private var flightPlanPanelViewModel: FlightPlanPanelViewModel!
    private weak var cameraStreamingViewController: HUDCameraStreamingViewController?
    private weak var mapViewController: MapViewController?

    private var cancellables = [AnyCancellable]()
    private var cancellableImageRateView: AnyCancellable?

    private var containerStatus: ContainerStatus = .streaming

    // MARK: - Private Enums
    private enum Constants {
        static let disableControlsDuration: TimeInterval = 0.75
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
    private var stopStreamOnSizeEvent = false

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
        panelDidShow()
        Services.hub.ui.hudTopBarService.allowTopBarDisplay()
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        panelDidHide()
        cancellableImageRateView = nil
        flightPlanPanelImageRateView?.removeFromSuperview()
        super.viewWillDisappear(animated)
    }

    // There is a bug in the StreamView. If the size (width or height) is zero, the stream is broken
    // A workaround is to stop and restart the stream
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard containerStatus == .streaming else {
            return
        }
        if (view.frame.size.width == 0 || view.frame.size.height == 0) && stopStreamOnSizeEvent == false {
            // bug detected (StreamView)
            stopStream()
            stopStreamOnSizeEvent = true
        } else if view.frame.size.width > 0 && view.frame.size.height > 0 && stopStreamOnSizeEvent == true {
            // restart the stream
            startStream()
            stopStreamOnSizeEvent = false
        }
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
        LogEvent.log(.simpleButton(LogEvent.LogKeyHUDPanelButton.play.name))
        disableControlsForDelay()
        flightPlanPanelViewModel.playButtonTouchedUpInside()
    }

    /// Edit button touched up inside.
    @IBAction func editButtonTouchedUpInside(_ sender: Any) {
        if containerStatus == .map {
            flightPlanPanelViewModel.showMap()
            containerStatus = .streaming
        }
        LogEvent.log(.simpleButton(LogEvent.LogKeyHUDPanelButton.edit.name))
        flightPlanPanelViewModel.editButtonTouchedUpInside()
    }

    /// Stop button touched up inside.
    @IBAction func stopButtonTouchedUpInside(_ sender: Any) {
        LogEvent.log(.simpleButton(LogEvent.LogKeyHUDPanelButton.stop.name))
        disableControlsForDelay()
        flightPlanPanelViewModel.stopFlightPlan()
    }
}

// MARK: - Private Funcs
private extension FlightPlanPanelViewController {

    /// Inits view.
    func initView() {

        cameraStreamingBottomBannerHeightConstraint.constant = Layout.hudTopBarHeight(isRegularSizeClass)

        projectButtonHeightConstraint.constant = Layout.buttonIntrinsicHeight(isRegularSizeClass)

        projectStackView.directionalLayoutMargins = .init(top: 0,
                                                          leading: Layout.mainPadding(isRegularSizeClass),
                                                          bottom: Layout.mainPadding(isRegularSizeClass),
                                                          trailing: Layout.mainPadding(isRegularSizeClass))

        bottomStackView.screenBorders = [.bottom]

        projectTitleLabel.makeUp(with: .caps, color: .disabledTextColor)
        projectTitleLabel.text = L10n.flightPlanMenuProject.uppercased()

        projectNameLabel.makeUp(with: .current, color: .defaultTextColor)
        projectNameLabel.lineBreakMode = .byTruncatingTail

        projectStackView.tapGesturePublisher
            .sink { [unowned self] _ in
                flightPlanPanelViewModel.projectTouchUpInside()
            }
            .store(in: &cancellables)

        folderButton.setup(image: Asset.MyFlights.folder.image,
                           style: .default1)

        noFlightPlanLabel.makeUp(with: .large, and: .defaultTextColor)
        imageMenuView.backgroundColor = ColorName.white.color

        createButton.setup(style: .validate)
        playButton.setup(image: Asset.Common.Icons.play.image, style: .validate)
        editButton.setup(image: Asset.Common.Icons.iconEdit.image, style: .default1)
        historyButton.setup(image: Asset.MyFlights.history.image, style: .default1)
        stopButton.setup(image: Asset.Common.Icons.stop.image, style: .destructive)

    }

    /// Inits progress view.
    func initImageRateView() {
        let imageRateView = FlightPlanPanelImageRateView(frame: imageMenuView.frame)
        imageMenuView.addWithConstraints(subview: imageRateView)
        flightPlanPanelImageRateView = imageRateView
    }

    /// Update buttons
    ///
    /// - Parameters:
    ///    - information: buttons information
    private func updatePlayButtonState(_ information: FlightPlanPanelViewModel.ButtonsInformation) {
        playButton.setup(image: information.startButtonState.icon,
                         style: information.startButtonState.style)
        playButton.isEnabled = information.areEnabled
    }

    /// Disables controls for a specified time interval.
    ///
    /// - Parameters:
    ///     - delay: enable controls after this delay
    func disableControlsForDelay(_ delay: TimeInterval = Constants.disableControlsDuration) {
        actionButtons.forEach { $0.isUserInteractionEnabled = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            self.actionButtons.forEach { $0.isUserInteractionEnabled = true }
        }
    }

    func bindViewModel() {
        flightPlanPanelViewModel.$titleProject
            .sink(receiveValue: { [unowned self] title in
                projectNameLabel.text = title
            })
            .store(in: &cancellables)

        flightPlanPanelViewModel.$viewState
            .sink { [weak self] viewState in
                guard let self = self else { return }
                UIView.animate {
                    self.updateButtons(viewState: viewState)
                }
            }
            .store(in: &cancellables)

        flightPlanPanelViewModel.$buttonsState
            .sink { [weak self] state in
                guard let self = self else { return }
                self.updatePlayButtonState(state)
            }
            .store(in: &cancellables)

        flightPlanPanelViewModel.$extraViews
            .sink { [unowned self] in progressViewContainer?.setExtraViews($0) }
            .store(in: &cancellables)
        flightPlanPanelViewModel.$progressModel
            .compactMap({ $0 })
            .sink(receiveValue: { [unowned self] model in
                self.progressViewContainer?.model = model
            })
            .store(in: &cancellables)
        flightPlanPanelViewModel.$createFirstTitle
            .sink { [unowned self] in
                self.noFlightPlanLabel.text = $0 ?? ""
            }
            .store(in: &cancellables)
        flightPlanPanelViewModel.$newButtonTitle
            .sink { [unowned self] in
                self.createButton.setTitle($0 ?? "", for: .normal)
            }
            .store(in: &cancellables)
    }

    /// Updates action buttons according to view model's state.
    ///
    /// - Parameter viewState: the state of the view model
    private func updateButtons(viewState: FlightPlanPanelViewModel.ViewState) {
        // Reset states.
        actionButtons.forEach { $0.isHiddenInStackView = true }
        stopLeadingSpacer.isHiddenInStackView = true
        stopTrailingSpacer.isHiddenInStackView = true
        buttonsStackView.distribution = .fill

        let isCreationState = viewState == .creation
        noFlightPlanContainer.isHiddenInStackView = !isCreationState
        progressViewContainer.isHiddenInStackView = isCreationState
        projectStackView.isHiddenInStackView = isCreationState

        switch viewState {
        case .creation:
            createButton.isHiddenInStackView = false

        case let .edition(hasHistory, canEdit):
            buttonsStackView.distribution = .fillEqually
            playButton.isHiddenInStackView = false
            editButton.isHiddenInStackView = false
            historyButton.isHiddenInStackView = false
            editButton.isEnabled = canEdit
            historyButton.isEnabled = hasHistory

        case .playing, .rth, .navigatingToStartingPoint:
            stopLeadingSpacer.isHiddenInStackView = false
            stopTrailingSpacer.isHiddenInStackView = false
            stopButton.isHiddenInStackView = false

        case .paused, .resumable:
            playButton.isHiddenInStackView = false
            stopButton.isHiddenInStackView = false
        }
    }
}
