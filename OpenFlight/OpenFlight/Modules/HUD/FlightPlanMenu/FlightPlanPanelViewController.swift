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

    @IBOutlet private weak var projectStackView: MainContainerStackView!
    @IBOutlet private weak var projectButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var projectNameLabel: UILabel!
    @IBOutlet private weak var projectTitleLabel: UILabel!
    @IBOutlet private weak var executionNameLabel: UILabel!
    @IBOutlet private weak var folderButton: ActionButton!
    @IBOutlet private weak var noFlightPlanContainer: UIView!
    @IBOutlet private weak var noFlightPlanLabel: UILabel!
    @IBOutlet private weak var cameraStreamingContainerView: UIView!
    @IBOutlet private weak var bottomGradientView: BottomGradientView!
    @IBOutlet private weak var bottomStackView: MainContainerStackView!
    @IBOutlet private weak var progressViewContainer: FlightPlanPanelProgressView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var headerView: UIView!
    @IBOutlet private weak var sideNavigationBarView: UIView!
    @IBOutlet private weak var pendingExecutionCellContainer: UIView!
    @IBOutlet private weak var footerBackgroundView: UIView!
    @IBOutlet private weak var widgetContainerStackView: PassThroughBasicStackView!
    @IBOutlet private weak var rthWidget: ReturnHomeBottomBarView!

    // Action Buttons
    @IBOutlet private weak var playingButtonsStackView: ActionStackView!
    @IBOutlet private weak var launcherButtonsStackView: ActionStackView!
    @IBOutlet private weak var createButton: ActionButton!
    @IBOutlet private weak var playButton: ActionButton!
    @IBOutlet private weak var resumeButton: ActionButton!
    @IBOutlet private weak var editButton: ActionButton!
    @IBOutlet private weak var stopLeadingSpacer: HSpacerView!
    @IBOutlet private weak var stopTrailingSpacer: HSpacerView!
    @IBOutlet private weak var stopButton: ActionButton!
    @IBOutlet private weak var historyButton: ActionButton!
    @IBOutlet private var actionButtons: [ActionButton]!

    // MARK: - Private Properties
    private var flightPlanPanelViewModel: FlightPlanPanelViewModel!
    private var pendingExecutionCell: FlightPlanExecutionCell = FlightPlanExecutionCell.loadFromNib()
    private weak var cameraStreamingViewController: HUDCameraStreamingViewController?
    private weak var mapViewController: MapViewController?
    /// Whether the main RTH widget is shown.
    private var isMainRthWidgetShown = false {
        didSet { updateActionButtonsVisibility() }
    }
    /// Whether the FP RTH widget is shown.
    private var isFpRthWidgetShown = false {
        didSet { updateActionButtonsVisibility() }
    }

    private var cancellables = [AnyCancellable]()

    private var containerStatus: ContainerStatus = .streaming
    private var settingsSections: [FlightPlanPanelViewModel.SettingsSection] = []

    /// Whether the custom rth setting is activated
    private var customRth: Bool = false

    // MARK: - Private Enums
    private enum Constants {
        static let disableControlsDuration: TimeInterval = 0.75
        static let streamRatio: CGFloat = 9/16
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
        initTableView()
        bindViewModel()
        listenToActionWidgets()
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        cameraStreamingContainerView.addGestureRecognizer(tap)
        // Plug RTH widget STOP to FP stop action.
        rthWidget.customStopAction = stopAction
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Services.hub.ui.hudTopBarService.allowTopBarDisplay()
        containerStatus = .streaming
        startStream()
        // Update pending execution in case it was removed from execution details view.
        flightPlanPanelViewModel.updatePendingExecution()
    }

    override func viewWillDisappear(_ animated: Bool) {
        panelDidHide()
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

        // Adjust settings tableView content inset according to bottomStackView height.
        tableView.contentInset.bottom = bottomStackView.bounds.height

        updateTableHeaderView()
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
    /// Listens to action widgets and hide controls if needed.
    func listenToActionWidgets() {
        Services.hub.ui.uiComponentsDisplayReporter.isActionWidgetShownPublisher.sink { [weak self] isWidgetShown in
            self?.isMainRthWidgetShown = isWidgetShown
        }
        .store(in: &cancellables)
    }

    /// Starts streaming component.
    func startStream() {
        guard cameraStreamingViewController == nil else { return }
        cameraStreamingViewController?.doNotPauseStreamOnDisappear = true
        let cameraStreamingVC = HUDCameraStreamingViewController.instantiate()
        addChild(cameraStreamingVC)

        cameraStreamingContainerView.addWithConstraints(subview: cameraStreamingVC.view)
        cameraStreamingContainerView.addSubview(cameraStreamingVC.view)
        cameraStreamingVC.didMove(toParent: self)
        cameraStreamingContainerView.updateConstraints()
        cameraStreamingViewController = cameraStreamingVC
        cameraStreamingVC.touchView.frame = cameraStreamingContainerView.frame
    }

    /// Stops streaming component.
    func stopStream() {
        cameraStreamingViewController?.doNotPauseStreamOnDisappear = true
        cameraStreamingContainerView.subviews.first?.removeFromSuperview()
        cameraStreamingViewController?.removeFromParent()
        cameraStreamingViewController = nil
    }

    /// Panel did hide.
    func panelDidHide() {
        if containerStatus != .streaming {
            flightPlanPanelViewModel.showMap()
            hideMiniMap()
            startStream()
            containerStatus = .streaming
        }
    }

    /// Show the map in container
    func showMiniMap() {
        let mapViewControllerVC = MapViewController.instantiate(isMiniMap: true)
        self.addChild(mapViewControllerVC)
        cameraStreamingContainerView.addWithConstraints(subview: mapViewControllerVC.view)
        mapViewControllerVC.didMove(toParent: self)
        mapViewController = mapViewControllerVC
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
    /// Pending execution button touched up inside.
    @IBAction func pendingExecutionButtonTouchedUpInside(_ sender: Any) {
        flightPlanPanelViewModel.pendingExecutionButtonTouchedUpInside()
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
        LogEvent.log(.simpleButton(LogEvent.LogKeyHUDPanelButton.play.name))
        disableControlsForDelay()
        flightPlanPanelViewModel.playButtonTouchedUpInside()
    }

    /// Edit button touched up inside.
    @IBAction func editButtonTouchedUpInside(_ sender: Any) {
        if containerStatus == .map {
            flightPlanPanelViewModel.showMap()
            hideMiniMap()
            containerStatus = .streaming
        }
        LogEvent.log(.simpleButton(LogEvent.LogKeyHUDPanelButton.edit.name))
        disableControlsForDelay()
        flightPlanPanelViewModel.editButtonTouchedUpInside()
    }

    /// Stop button touched up inside.
    @IBAction func stopButtonTouchedUpInside(_ sender: Any) {
        LogEvent.log(.simpleButton(LogEvent.LogKeyHUDPanelButton.stop.name))
        stopAction()
    }

    /// Triggers stop (either requested via main STOP or RTH STOP button).
    func stopAction() {
        disableControlsForDelay()
        flightPlanPanelViewModel.stopFlightPlan()
    }
}

// MARK: - Private Funcs
private extension FlightPlanPanelViewController {

    /// Inits view.
    func initView() {

        projectButtonHeightConstraint.constant = Layout.buttonIntrinsicHeight(isRegularSizeClass)
        sideNavigationBarView.heightAnchor.constraint(equalToConstant: Layout.hudTopBarHeight(isRegularSizeClass)).isActive = true

        projectStackView.directionalLayoutMargins = .init(top: 0,
                                                          leading: Layout.mainPadding(isRegularSizeClass),
                                                          bottom: Layout.mainPadding(isRegularSizeClass),
                                                          trailing: Layout.mainPadding(isRegularSizeClass))

        bottomStackView.screenBorders = [.bottom]

        // RTH widget container.
        widgetContainerStackView.insetsLayoutMarginsFromSafeArea = false
        widgetContainerStackView.isLayoutMarginsRelativeArrangement = true
        widgetContainerStackView.directionalLayoutMargins = Layout.mainContainerInnerMargins(isRegularSizeClass,
                                                                                              screenBorders: [.bottom])

        projectTitleLabel.makeUp(with: .caps, color: .disabledTextColor)
        projectTitleLabel.text = L10n.flightPlanMenuProject.uppercased()

        projectNameLabel.makeUp(with: .current, color: .defaultTextColor)
        projectNameLabel.lineBreakMode = .byTruncatingTail

        executionNameLabel.makeUp(with: .current, color: .defaultTextColor)

        projectStackView.tapGesturePublisher
            .sink { [unowned self] _ in
                // Disallow to open the project manager when the folder button is hidden.
                guard !folderButton.isHiddenInStackView else { return }
                flightPlanPanelViewModel.projectTouchUpInside()
            }
            .store(in: &cancellables)

        folderButton.setup(image: Asset.MyFlights.folder.image,
                           style: .default1)

        noFlightPlanLabel.makeUp(with: .large, and: .defaultTextColor)

        createButton.setup(style: .validate)
        playButton.setup(image: Asset.Common.Icons.play.image, style: .validate)
        resumeButton.setup(image: Asset.Common.Icons.icResume.image, style: .validate)
        editButton.setup(image: Asset.Common.Icons.iconEdit.image, style: .default1)
        historyButton.setup(image: Asset.MyFlights.history.image, style: .default1)
        stopButton.setup(image: Asset.Common.Icons.stop.image, style: .destructive)

        footerBackgroundView.backgroundColor = ColorName.defaultBgcolor.color
        footerBackgroundView.addShadow(shadowOffset: .init(width: 0, height: -1),
                                       shadowRadius: 7)

        // Update bottom gradient view.
        bottomGradientView.shortGradient()

        // Pending execution cell.
        pendingExecutionCellContainer.addWithConstraints(subview: pendingExecutionCell.contentView)
        pendingExecutionCellContainer.layoutMargins = .zero
        pendingExecutionCell.enabledMargins.removeAll()
        pendingExecutionCell.contentView.isUserInteractionEnabled = false
    }

    /// Inits table view
    func initTableView() {
        tableView.insetsContentViewsToSafeArea = false // Safe area is handled in this VC, not in content
        tableView.register(cellType: SettingsImageTableViewCell.self)
        tableView.register(cellType: SettingsMenuTableViewCell.self)
        tableView.register(cellType: SettingsModeTableViewCell.self)
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.makeUp(backgroundColor: .clear)
    }

    func updateTableHeaderView() {
        let width = Layout.sidePanelWidth(isRegularSizeClass)
        let height = Constants.streamRatio * width
            + projectStackView.bounds.height
            + sideNavigationBarView.bounds.height
            + Layout.mainSpacing(isRegularSizeClass)
        headerView.frame.size = .init(width: width, height: height)
        tableView.tableHeaderView = headerView
        tableView.alwaysBounceVertical = tableView.contentSize.height > tableView.bounds.height
    }

    /// Update buttons
    ///
    /// - Parameters:
    ///    - information: buttons information
    private func updatePlayButtonState(_ information: FlightPlanPanelViewModel.ButtonsInformation) {
        playButton.isEnabled = information.startEnabled
        resumeButton.isEnabled = information.startEnabled
        stopButton.isEnabled = information.stopEnabled
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

        flightPlanPanelViewModel.$titleExecution
            .sink { [weak self] title in
                guard let self = self else { return }
                self.executionNameLabel.text = title
            }
            .store(in: &cancellables)

        flightPlanPanelViewModel.$viewState
            .removeDuplicates()
            .sink { [weak self] viewState in
                guard let self = self else { return }
                UIView.animate {
                    self.updateButtons(viewState: viewState)
                }
            }
            .store(in: &cancellables)

        flightPlanPanelViewModel.$pendingExecution
            .sink { [weak self] latestExecution in
                self?.updatePendingExecutionTile(execution: latestExecution)
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
        flightPlanPanelViewModel.$settingsSections
            .sink { [weak self] in
                guard let self = self else { return }
                self.settingsSections = $0
                self.tableView.reloadData()
            }
            .store(in: &cancellables)
        flightPlanPanelViewModel.$bottomGradientIsVisible
            .sink { [weak self] in
                guard let self = self else { return }
                self.bottomGradientView.isHidden = !$0
            }
            .store(in: &cancellables)
    }

    /// Updates action buttons according to view model's state.
    ///
    /// - Parameter viewState: the state of the view model
    private func updateButtons(viewState: FlightPlanPanelViewModel.ViewState) {
        // Reset states.
        actionButtons.forEach { $0.isHiddenInStackView = true }
        updateHeader(viewState: viewState)

        let isCreationState = viewState == .creation
        let isRthState = viewState == .rth
        noFlightPlanContainer.isHiddenInStackView = !isCreationState
        progressViewContainer.isHiddenInStackView = isCreationState || isRthState
        projectStackView.isHiddenInStackView = isCreationState

        switch viewState {
        case .creation:
            createButton.isHiddenInStackView = false

        case let .edition(hasHistory, canEdit):
            playButton.isHiddenInStackView = false
            editButton.isHiddenInStackView = false
            historyButton.isHiddenInStackView = false
            editButton.isEnabled = canEdit
            historyButton.isEnabled = hasHistory

        case .playing, .navigatingToStartingPoint:
            stopLeadingSpacer.isHiddenInStackView = false
            stopTrailingSpacer.isHiddenInStackView = false
            stopButton.isHiddenInStackView = false
            executionNameLabel.isHiddenInStackView = false

        case .paused, .resumable:
            resumeButton.isHiddenInStackView = false
            stopButton.isHiddenInStackView = false

        case .rth:
            break
        }

        updateRthWidget(show: isRthState)
    }

    /// Updates RTH widget appearance.
    ///
    /// - Parameter show: show widget if `true`, hide it otherwise
    func updateRthWidget(show: Bool) {
        widgetContainerStackView.showFromEdge(.bottom,
                               offset: Layout.mainBottomMargin(isRegularSizeClass),
                               show: show,
                               fadeFrom: 1)
        isFpRthWidgetShown = show
    }

    /// Updates the action buttons visibility according to RTH widgets state.
    func updateActionButtonsVisibility() {
        // Action buttons should be displayed only if no RTH widget is shown.
        let showActionButtons = !isMainRthWidgetShown && !isFpRthWidgetShown
        launcherButtonsStackView.animateScaleAndAlpha(show: showActionButtons)
        playingButtonsStackView.animateScaleAndAlpha(show: showActionButtons)
    }

    /// Updates the header panel according to view model's state.
    ///
    /// - Parameter viewState: the state of the view model
    private func updateHeader(viewState: FlightPlanPanelViewModel.ViewState) {
        var inProgress = false
        switch viewState {
        case .playing, .rth, .navigatingToStartingPoint:
            inProgress = true
        default:
            break
        }

        folderButton.animateIsHiddenInStackView(inProgress)
        executionNameLabel.animateIsHiddenInStackView(!inProgress)
        projectNameLabel.numberOfLines = (!inProgress).toInt + 1
    }

    /// Updates pending execution tile according to current pending execution.
    /// Tile is shown and filled with current pending execution content if not `nil`, hidden otherwise.
    ///
    /// - Parameter execution: the current pending execution (if any)
    func updatePendingExecutionTile(execution: FlightPlanModel?) {
        guard let execution = execution else {
            // No current pending execution => hide tile.
            showPendingExecutionTile(show: false)
            return
        }

        showPendingExecutionTile(show: true)
        pendingExecutionCell.fill(execution: execution, customTitle: L10n.flightPlanLatestExecution)
    }

    /// Shows or hide pending execution tile.
    ///
    /// - Parameter show: show tile if `true`,  hide it otherwise
    func showPendingExecutionTile(show: Bool) {
        pendingExecutionCellContainer.animateIsHiddenInStackView(!show)
    }
}
// MARK: - UITableViewDataSource
extension FlightPlanPanelViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return settingsSections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let type = settingsSections[section]
        switch type {
        case let .settings(_, fpSettings):
            return fpSettings.count
        case .image,
             .mode:
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let type = settingsSections[indexPath.section]
        switch type {
        case let .settings(_, fpSettings):
            let cell = tableView.dequeueReusableCell(for: indexPath) as SettingsMenuTableViewCell
            let setting = fpSettings[indexPath.row]
            if setting.key == ClassicFlightPlanSettingType.customRth.key {
                customRth = setting.currentValue == 0
            }
            // Configure setting as non-editable in FP panel VC (displayed during FP execution for
            // information purpose only).
            cell.setup(setting: setting,
                       index: indexPath.row,
                       numberOfRows: tableView.numberOfRows(inSection: indexPath.section),
                       isEditable: false,
                       inEditionMode: false,
                       customRth: customRth)
            return cell
        case let .image(hasCustomType, fpSettings, fpDataSettings):
            let cell = tableView.dequeueReusableCell(for: indexPath) as SettingsImageTableViewCell
            let cellProvider = ImageMenuCellProvider(dataSettings: fpDataSettings)
            cell.setup(provider: cellProvider, settings: fpSettings, hasCustomType: hasCustomType)
            return cell
        case let .mode(type):
            let cell = tableView.dequeueReusableCell(for: indexPath) as SettingsModeTableViewCell
            cell.setup(with: type)
            return cell
        }
    }
}
