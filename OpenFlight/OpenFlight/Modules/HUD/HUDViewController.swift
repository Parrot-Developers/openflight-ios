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
import GroundSdk

public protocol CustomIndicatorProvider: AnyObject { }

/// Main view controller for the Heads-Up Display (HUD).
final public class HUDViewController: UIViewController, DelayedTaskProvider {
    // MARK: - Internal Outlets
    @IBOutlet internal weak var splitControls: SplitControls!
    @IBOutlet internal weak var missionControls: MissionControls!
    @IBOutlet internal weak var rightPanelContainerControls: RightPanelContainerControls!
    @IBOutlet internal weak var videoControls: VideoControls!
    @IBOutlet internal weak var alertControls: AlertControls!

    // MARK: - Private Outlets
    @IBOutlet private weak var bannerAlertsContainerTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bannerAlertsContainer: UIView!
    @IBOutlet private weak var joysticksView: JoysticksView!
    @IBOutlet private weak var alertPanelContainerView: UIView!
    @IBOutlet private weak var indicatorContainerView: UIView!
    @IBOutlet private weak var topStackView: UIStackView!
    @IBOutlet private weak var infoBannerTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var dismissMissionLauncherButton: UIButton!
    @IBOutlet private weak var closeBottomBarButton: UIButton!
    @IBOutlet private weak var cameraSlidersLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var actionWidgetBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var actionWidgetStackView: RightSidePanelStackView!
    @IBOutlet private weak var actionWidgetContainerView: UIView!
    @IBOutlet private weak var centerButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var centerButtonBottomConstraint: NSLayoutConstraint!

    // MARK: - Public Properties
    var customControls: CustomHUDControls?

    // MARK: - Internal Properties
    public weak var coordinator: HUDCoordinator?
    var delayedTaskComponents: DelayedTaskComponents = DelayedTaskComponents()

    // MARK: - Private Properties
    private var currentMissionManager: CurrentMissionManager?
    private var airsdkMissionsManager: AirSdkMissionsManager?
    private var topBarService: HudTopBarService?
    private var bottomBarService: HudBottomBarService?
    private var pinCodeService: PinCodeService?
    private var rthService: RthService?
    private var panoramaService: PanoramaService?
    private var uiComponentsDisplayReporter: UIComponentsDisplayReporter?
    private var ophtalmoService: OphtalmoService?
    private var touchAndFly: TouchAndFlyUiService?
    private var missionsStore: MissionsStore?
    private var connectedDroneHolder: ConnectedDroneHolder?

    private var cancellables = Set<AnyCancellable>()
    private var customIndicatorViewModel: CustomIndicatorProvider?
    private var defaultMapViewController: MapViewController?

    /// View models.
    private let topBannerViewModel = HUDTopBannerViewModel()
    private let joysticksViewModel = JoysticksViewModel()
    private let remoteShutdownAlertViewModel = RemoteShutdownAlertViewModel()
    private lazy var helloWorldViewModel: HelloWorldMissionViewModel? = {
        // Prevent from useless helloWorld init if mission is not loaded.
        guard let airsdkMissionsManager = airsdkMissionsManager else { return nil }

        let missionsToLoad = airsdkMissionsManager.getMissionToLoadAtStart()
        let helloMissionId = HelloWorldMissionSignature().missionUID
        guard missionsToLoad.contains(where: { $0.missionUID == helloMissionId }) else { return nil }

        return HelloWorldMissionViewModel()
    }()
    private let landingViewModel = HUDLandingViewModel()
    /// View model which tells if 4G pairing is available.
    private let cellularPairingAvailabilityViewModel = CellularPairingAvailabilityViewModel()

    /// Property used to store the alert panel view controller.
    private var currentAlertPanelVC: AlertPanelViewController?

    /// Optional top overlay view controller used for banner alerts display.
    /// HUD container is used if `topOverlayViewController` is `nil` (default case).
    private let topOverlayViewController: TopOverlayController? = nil

    // MARK: - Private Enums
    private enum Constants {
        static let cameraSlidersButtonWidth: CGFloat = 51
        static let cellularIndicatorTaskKey: String = "cellularIndicatorTaskKey"
        static let orientationKeyWord: String = "orientation"
    }

    // MARK: - Setup

    // swiftlint:disable:next function_parameter_count
    static func instantiate(coordinator: HUDCoordinator,
                            currentMissionManager: CurrentMissionManager,
                            airsdkMissionsManager: AirSdkMissionsManager,
                            topBarService: HudTopBarService,
                            bottomBarService: HudBottomBarService,
                            pinCodeService: PinCodeService,
                            rthService: RthService,
                            panoramaService: PanoramaService,
                            uiComponentsDisplayReporter: UIComponentsDisplayReporter,
                            ophtalmoService: OphtalmoService,
                            touchAndFly: TouchAndFlyUiService,
                            missionsStore: MissionsStore,
                            connectedDroneHolder: ConnectedDroneHolder) -> HUDViewController {
        let viewController = StoryboardScene.Hud.initialScene.instantiate()
        viewController.coordinator = coordinator
        viewController.currentMissionManager = currentMissionManager
        viewController.airsdkMissionsManager = airsdkMissionsManager
        viewController.topBarService = topBarService
        viewController.bottomBarService = bottomBarService
        viewController.pinCodeService = pinCodeService
        viewController.rthService = rthService
        viewController.panoramaService = panoramaService
        viewController.uiComponentsDisplayReporter = uiComponentsDisplayReporter
        viewController.ophtalmoService = ophtalmoService
        viewController.touchAndFly = touchAndFly
        viewController.missionsStore = missionsStore
        viewController.connectedDroneHolder = connectedDroneHolder
        return viewController
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Override Funcs
    public override func viewDidLoad() {
        super.viewDidLoad()
        guard let currentMissionManager = currentMissionManager,
              let touchAndFly = touchAndFly,
              let ophtalmoService = ophtalmoService else { return }

        listenWillEnterForeground()
        splitControls.start(currentMissionManager: currentMissionManager)
        // TODO: this part needs to be fixed, some interactions with the map do not work without that (drag mostly)
        customControls = touchAndFly
        customControls?.start()
        setupAlertPanel()
        setupActionWidgetContainer()
        setupBannerAlertsManagerContainer()

        listenMissionMode()
        listenTopBarChanges()
        listenToBottomBar()
        listenRemoteShutdownAlert()
        listenPinCode()
        listenMissionLauncherState()
        listenToActionWidgets()
        listenLanding()

        // Handle rotation when coming from Onboarding.
        let value = UIInterfaceOrientation.landscapeRight.rawValue
        UIDevice.current.setValue(value, forKey: Constants.orientationKeyWord)
        ophtalmoService.ophtalmoMissionStatePublisher
            .sink { [unowned self] in
                guard let coordinator = coordinator else { return }
                if $0 == .active, self.isViewLoaded && view.window != nil {
                    // check if viewIsDisplayed
                    if (coordinator.childCoordinators.last as? OphtalmoCoordinator) == nil {
                        coordinator.presentCoordinatorWithAnimator(childCoordinator: OphtalmoCoordinator(services: Services.hub))
                    }
                }
            }
            .store(in: &cancellables)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let coordinator = coordinator,
              let pinCodeService = pinCodeService,
              let ophtalmoService = ophtalmoService else { return }

        if (coordinator.childCoordinators.last as? OphtalmoCoordinator) != nil,
           ophtalmoService.ophtalmoMissionState != .active {
                coordinator.childCoordinators.removeLast()
        }

        splitControls.setupSplitIfNeeded()
        splitControls.updateConstraintForForeground()

        // check if ophtalmo is active and show it if it is the case.
        if ophtalmoService.ophtalmoMissionState == .active {
            if (coordinator.childCoordinators.last as? OphtalmoCoordinator) == nil {
                coordinator.presentCoordinatorWithAnimator(childCoordinator: OphtalmoCoordinator(services: Services.hub))
            }
        } else {
            coordinator.displayCriticalAlertsIfNeeded()
            // Show flight plan panel if needed.
            displayCellularPinCode(isPinCodeRequested: pinCodeService.isPinCodeRequestedValue)
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        LogEvent.log(.screen(LogEvent.Screen.hud))
        setupConstraints()
        rightPanelContainerControls.start()
        updateViewModels()
        // Update landing view @willAppear, as it is removed when a fullscreen modal is presented.
        updateLandingView()

        super.viewWillAppear(animated)
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        rightPanelContainerControls.stop()
        removeViewModelObservers()
        stopTasksIfNeeded()
        removeContainerViews()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Banner alerts container update only needs to be performed in case of top overlay container.
        if topOverlayViewController != nil {
            // Update banner alerts container frame in order to take potential right panel appearance into account.
            coordinator?.services.bamService.setContainer(frame: bannerAlertsContainer.frame)
        }
    }

    public override var shouldAutorotate: Bool {
        return true
    }

    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let topBar = segue.destination as? HUDTopBarViewController {
            topBar.navigationDelegate = self
            topBar.bottomBarService = bottomBarService
        } else if let cameraStreamingVC = segue.destination as? HUDCameraStreamingViewController {
            splitControls.cameraStreamingViewController = cameraStreamingVC
            cameraStreamingVC.delegate = self
        } else if let indicatorViewController = segue.destination as? HUDIndicatorViewController {
            splitControls.delegate = indicatorViewController
            indicatorViewController.indicatorViewControllerNavigation = self
        } else if let bottomBarContainerVC = segue.destination as? BottomBarContainerViewController {
            bottomBarContainerVC.coordinator = coordinator
            bottomBarContainerVC.bottomBarService = bottomBarService
        } else if let missionLauncherVC = segue.destination as? MissionProviderSelectorViewController {
            guard let currentMissionManager = currentMissionManager,
                  let missionsStore = missionsStore,
                  let airsdkMissionsManager = airsdkMissionsManager,
                  let connectedDroneHolder = connectedDroneHolder else { return }

            missionLauncherVC.viewModel = MissionProviderSelectorViewModel(currentMissionManager: currentMissionManager,
                                                                           missionsStore: missionsStore,
                                                                           delegate: self,
                                                                           missionsManager: airsdkMissionsManager,
                                                                           connectedDroneHolder: connectedDroneHolder)
        } else if let lockAETargetZoneVC = segue.destination as? LockAETargetZoneViewController {
            videoControls.lockAETargetZoneViewController = lockAETargetZoneVC
        } else if let sliders = segue.destination as? CameraSlidersViewController {
            coordinator?.handleCameraSlidersViewController(sliders)
        }
    }

    public override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    public override var prefersStatusBarHidden: Bool {
        return true
    }

    func setupCustomMessageProvider(customMessageProvider: CustomIndicatorProvider?) {
        customIndicatorViewModel = customMessageProvider
    }
}

// MARK: - Actions
private extension HUDViewController {
    /// Dismiss mission Launcher by tapping outside it
    @IBAction func dismissMissionLauncherButtonTouchedUpInside() {
        coordinator?.hideMissionLauncher()
    }
    /// Closes bottom bar.
    @IBAction func closeBottomBarButtonTouchedUpInside(_ sender: Any) {
        // Close all bottom bar levels whenever a tap on background button is received.
        bottomBarService?.set(mode: .closed)
    }
}

// MARK: - Private Funcs
private extension HUDViewController {

    func listenWillEnterForeground() {
        guard let splitControls = splitControls else { return }
        NotificationCenter.default.addObserver(splitControls,
                                               selector: #selector(splitControls.updateConstraintForForeground),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(splitControls,
                                               selector: #selector(splitControls.updateConstraintForForeground),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    /// Listen for mission mode
    func listenMissionMode() {
        guard let currentMissionManager = currentMissionManager else { return }
        currentMissionManager.modePublisher.sink { [unowned self] mode in
            setupMap()
            coordinator?.presentModeEntryCoordinatorIfNeeded(mode: mode)
            videoControls.enableAeTarget(enabled: mode.isAeLockEnabled)
        }
        .store(in: &cancellables)
    }

    func listenTopBarChanges() {
        guard let topBarService = topBarService else { return }

        topBarService.showTopBarPublisher
            .sink { [weak self] show in
                guard let self = self else { return }
                UIView.animate {
                    self.topStackView.alphaHidden(!show)
                }
            }
            .store(in: &cancellables)
    }

    /// Listens to bottom bar service in order to know if background close button needs to be displayed.
    func listenToBottomBar() {
        bottomBarService?.modePublisher.sink { [weak self] mode in
            self?.closeBottomBarButton.isHiddenInStackView = mode == .closed
        }
        .store(in: &cancellables)
    }

    /// Listens if modal popup can be shown
    func listenRemoteShutdownAlert() {
        remoteShutdownAlertViewModel.canShowModal
            .removeDuplicates()
            .sink { [weak self] canShowModal in
                if canShowModal {
                    self?.showRemoteShutdownAlert()
                }
            }
            .store(in: &cancellables)
    }

    /// Listens to action widgets.
    func listenToActionWidgets() {
        guard let uiComponentsDisplayReporter = uiComponentsDisplayReporter else { return }

        uiComponentsDisplayReporter.isActionWidgetShownPublisher.sink { [weak self] isWidgetShown in
            guard let self = self else { return }
            // Disable user interaction if no action widget is displayed.
            // Do not use isHidden in order to allow hiding animations.
            self.actionWidgetStackView.isUserInteractionEnabled = isWidgetShown
            self.updateCenterButtonBottomConstraint()
        }
        .store(in: &cancellables)
    }

    /// Updates center button bottom constraint depending on layout state.
    func updateCenterButtonBottomConstraint() {
        guard let currentMissionManager = currentMissionManager else { return }
        guard let uiComponentsDisplayReporter = uiComponentsDisplayReporter else { return }

        let isActionWidgetShown = uiComponentsDisplayReporter.isActionWidgetShown
        let isRightPanelRequired = currentMissionManager.mode.isRightPanelRequired
        // Center button bottom constraint (relative to action widget container) should only be
        // active if a widget is displayed and no right panel is required.
        // Top lower priority constraint (relative to bottom bar) will apply if bottom constraint is disabled.
        centerButtonBottomConstraint.isActive = isActionWidgetShown && !isRightPanelRequired
    }

    /// Displays the cellular card pin modal
    ///
    /// - Parameter isPinCodeRequested: If the code pin is requested
    func displayCellularPinCode(isPinCodeRequested: Bool) {
        guard isPinCodeRequested else { return }
        coordinator?.displayCellularPinCode()
    }

    /// Updates cellular process.
    func listenPinCode() {
        guard let pinCodeService = pinCodeService else { return }

        pinCodeService.isPinCodeRequested
            .removeDuplicates()
            .sink { [unowned self] isPinCodeRequested in
                displayCellularPinCode(isPinCodeRequested: isPinCodeRequested)
            }
            .store(in: &cancellables)
    }

    /// Listen for Mission Launcher sate changes
    func listenMissionLauncherState() {
        guard let coordinator = coordinator else { return }

        coordinator.showMissionLauncherPublisher.sink { [unowned self] isShown in
            dismissMissionLauncherButton.isHidden = !isShown
            updateCameraSlidersConstraint(isMissionPanelShown: isShown)
        }
        .store(in: &cancellables)
    }

    /// Sets up the banner alerts manager container.
    func setupBannerAlertsManagerContainer() {
        guard let bannerAlertManagerService = coordinator?.services.bamService else { return }

        // Instantiate VM and VC.
        let bannerAlertManagerViewModel = BannerAlertsManagerViewModel(service: bannerAlertManagerService)
        let bannerAlertsManagerViewController = BannerAlertsManagerViewController.instantiate(viewModel: bannerAlertManagerViewModel)

        if let topOverlayViewController = topOverlayViewController {
            // Top overlay mode: banners will be displayed above any view.
            topOverlayViewController.addAndMakeVisible(viewController: bannerAlertsManagerViewController)
        } else {
            // HUD mode: banners will be displayed in HUD view only.
            add(bannerAlertsManagerViewController, in: bannerAlertsContainer)
        }
    }

    /// Sets up constraints.
    func setupConstraints() {
        bannerAlertsContainerTopConstraint.constant = Layout.hudTopBarHeight(isRegularSizeClass) + Layout.mainSpacing(isRegularSizeClass)
        infoBannerTopConstraint.constant = Layout.hudTopBarHeight(isRegularSizeClass) + Layout.mainSpacing(isRegularSizeClass)
        centerButtonHeightConstraint.constant = Layout.buttonIntrinsicHeight(isRegularSizeClass)
        centerButtonBottomConstraint.constant = -Layout.mainPadding(isRegularSizeClass)
        missionControls.setupUI()
        rightPanelContainerControls.setupUI()
        alertControls.updateConstraints(animated: false)
        updateCameraSlidersConstraint()

        // Use a bottom constraint instead of stackView inner margins, as action widget
        // container either needs to snap to the bottom or follow bottom bar level 1
        // depending on right panel display (goes up with bottom bar level 1 if no panel
        // is displayed, remains snapped to the bottom otherwise).
        actionWidgetBottomConstraint.constant = Layout.mainBottomMargin(isRegularSizeClass) - Layout.mainPadding(isRegularSizeClass)
    }

    /// Camera sliders alignment.
    func updateCameraSlidersConstraint(isMissionPanelShown: Bool = false) {
        let leadingMargin = Layout.mainContainerInnerMargins(isRegularSizeClass,
                                                             screenBorders: isMissionPanelShown ? [.bottom] : [.left, .bottom],
                                                             hasMinLeftPadding: true).leading
        + Layout.buttonIntrinsicHeight(isRegularSizeClass) / 2 - Constants.cameraSlidersButtonWidth / 2
        cameraSlidersLeadingConstraint.constant = leadingMargin
    }

    /// Map setup.
    func setupMap() {
        guard let currentMissionManager = currentMissionManager else { return }

        let mode = currentMissionManager.mode
        if let map = mode.customMapProvider?() as? MapViewController {
            // Add custom map.
            map.customControls = customControls
            customControls?.mapViewController = map
            self.splitControls.addMap(map, parent: self)
            // Force recreate default map next time it will be necessary (this will deinit it).
            defaultMapViewController = nil
        } else {
            // Add default map, create it if needed.
            // defaultMapViewController is used to keep map when mission modes use same default map.
            let map = defaultMapViewController ?? StoryboardScene.Map.initialScene.instantiate()
            defaultMapViewController = map
            map.customControls = customControls
            customControls?.mapViewController = map
            self.splitControls.addMap(map, parent: self)
        }
        updateCenterButtonBottomConstraint()
    }

    /// Sets up left panel for proactive alerts.
    func setupAlertPanel() {
        let currentAlertPanelVC = HUDAlertPanelProvider.shared.alertPanelViewControllers?.alertPanelViewController()
        let alertPanel = currentAlertPanelVC ?? HUDAlertPanelViewController.instantiate()
        alertPanel.delegate = alertControls
        self.addChild(alertPanel)
        alertPanel.view.removeFromSuperview()
        alertPanelContainerView.addWithConstraints(subview: alertPanel.view)
    }

    /// Sets up action widget container.
    func setupActionWidgetContainer() {
        guard let rthService = rthService,
              let panoramaService = panoramaService,
              let currentMissionManager = currentMissionManager else { return }

        let viewModel = ActionWidgetViewModel(rthService: rthService,
                                              panoramaService: panoramaService,
                                              currentMissionManager: currentMissionManager)
        let actionWidgetContainerVC = ActionWidgetContainerViewController.instantiate(viewModel: viewModel)
        addChild(actionWidgetContainerVC)
        actionWidgetContainerView.addWithConstraints(subview: actionWidgetContainerVC.view)
    }

    /// Changes joysticks visibility regarding view model state.
    ///
    /// - Parameters:
    ///     - state: current joysticks visibility state
    func updateJoysticksVisibility(with state: JoysticksState?) {
        joysticksView.isHidden = state?.shouldHideJoysticks == true
    }

    /// Shows remote alert shutdown process.
    func showRemoteShutdownAlert() {
        coordinator?.displayRemoteAlertShutdown()
    }

    /// Updates view models values.
    func updateViewModels() {
        if let helloWorldViewModel = helloWorldViewModel {
            helloWorldViewModel.$missionState.removeDuplicates()
                .combineLatest(helloWorldViewModel.$messageReceivedCount.removeDuplicates())
                .sink { [weak self] (missionState, _) in
                    guard let self = self else { return }
                    self.showHelloWorldIfNeeded(state: missionState)
                    self.showHelloWorldDepth(state: missionState)
                }
                .store(in: &cancellables)
        }

        joysticksViewModel.state.valueChanged = { [weak self] state in
            self?.updateJoysticksVisibility(with: state)
        }

        updateJoysticksVisibility(with: joysticksViewModel.state.value)
        cellularPairingAvailabilityViewModel.updateAvailabilityState()
    }

    func listenLanding() {
        landingViewModel.isLanding
            .removeDuplicates()
            .combineLatest(landingViewModel.isReturnHomeActive.removeDuplicates())
            .sink { [unowned self] (isLanding, isReturnHomeActive) in
                if isLanding || isReturnHomeActive {
                    updateLandingView()
                }
            }
            .store(in: &cancellables)
    }

    /// Removes each view model value changed.
    func removeViewModelObservers() {
        joysticksViewModel.state.valueChanged = nil
    }

    /// Removes container views.
    func removeContainerViews() {
        indicatorContainerView.removeSubViews()
    }

    /// Stops current tasks if its needed.
    func stopTasksIfNeeded() {
        if isTaskPending(key: Constants.cellularIndicatorTaskKey) {
            cancelDelayedTask(key: Constants.cellularIndicatorTaskKey)
        }
    }
}

// MARK: - Utils for Hello World Mission
private extension HUDViewController {

    func updateLandingView() {
        guard landingViewModel.isLandingOrRth else { return }

        let view = HUDLandingView()
        view.commonInitHUDRTHAnimationView()
        addIndicatorView(with: view)
    }

    /// Display a view when the drone sends a Hello World AirSdk message.
    ///
    /// - Parameters:
    ///     - state: The state of the Hello World AirSdk mission
    func showHelloWorldIfNeeded(state: MissionState) {
        guard state == .active,
              let messageToDisplay = helloWorldViewModel?.messageToDisplay(),
              !HelloWorldMessageView.isAlreadyDisplayed(in: self) else {
            return
        }

        let helloWorldMessageView = HelloWorldMessageView()
        helloWorldMessageView.displayThenHide(in: self, with: messageToDisplay)
    }

    /// Display a view when the drone sends a Hello World AirSdk message.
    ///
    /// - Parameters:
    ///     - state: The state of the Hello World AirSdk mission
    func showHelloWorldDepth(state: MissionState) {
        guard state == .active else {
            let helloWorldDepthView = view.subviews.first { $0 is HelloWorldDepthView }
            helloWorldDepthView?.removeFromSuperview()
            return
        }

        guard !HelloWorldDepthView.isAlreadyDisplayed(in: self) else { return }
        let helloWorldDepthView = HelloWorldDepthView()
        helloWorldDepthView.display(in: self)
    }
}

// MARK: - Cellular Landing Indicator Views
private extension HUDViewController {
    /// Adds indicator view.
    ///
    /// - Parameters:
    ///     - view: view to add
    func addIndicatorView(with view: UIView) {
        indicatorContainerView.isHidden = false
        indicatorContainerView.removeSubViews()
        indicatorContainerView.addWithConstraints(subview: view)
    }
}

extension HUDViewController: MissionProviderSelectorViewModelDelegate {
    public func hideMissionMenu() {
        coordinator?.hideMissionLauncher()
    }

    public func showBottomBar() {
        splitControls?.hideBottomBar(hide: false)
    }
}
