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

public protocol CustomIndicatorProvider: AnyObject {

    var customMessage: AnyPublisher<String?, Never> { get }
    var shouldShowLoader: AnyPublisher<Bool, Never> { get }
    var customMissionActive: AnyPublisher<Bool, Never> { get }
}

/// Main view controller for the Heads-Up Display (HUD).
final public class HUDViewController: UIViewController, DelayedTaskProvider {
    // MARK: - Internal Outlets
    @IBOutlet internal weak var splitControls: SplitControls!
    @IBOutlet internal weak var missionControls: MissionControls!
    @IBOutlet internal weak var rightPanelContainerControls: RightPanelContainerControls!
    @IBOutlet internal weak var videoControls: VideoControls!
    @IBOutlet internal weak var alertControls: AlertControls!

    // MARK: - Private Outlets
    @IBOutlet private weak var joysticksView: JoysticksView!
    @IBOutlet private weak var alertPanelContainerView: UIView!
    @IBOutlet private weak var customValidationView: UIView!
    @IBOutlet private weak var AELockContainerView: UIView!
    @IBOutlet private weak var indicatorContainerView: UIView!
    @IBOutlet private weak var topStackView: UIStackView!
    @IBOutlet private weak var infoBannerTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var dismissMissionLauncherButton: UIButton!
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
    // TODO: wrong injection
    private unowned var currentMissionManager = Services.hub.currentMissionManager
    private unowned var airsdkMissionsManager = Services.hub.drone.airsdkMissionsManager
    private unowned var topBarService = Services.hub.ui.hudTopBarService
    private unowned var pinCodeService = Services.hub.drone.pinCodeService

    private var cancellables = Set<AnyCancellable>()
    private var customIndicatorViewModel: CustomIndicatorProvider?
    private var defaultMapViewController: MapViewController?

    /// View models.
    private let joysticksViewModel = JoysticksViewModel()
    private let remoteShutdownAlertViewModel = RemoteShutdownAlertViewModel()
    private lazy var helloWorldViewModel: HelloWorldMissionViewModel? = {
        // Prevent from useless helloWorld init if mission is not loaded.
        let missionsToLoad = airsdkMissionsManager.getMissionToLoadAtStart()
        let helloMissionId = HelloWorldMissionSignature().missionUID
        guard missionsToLoad.contains(where: { $0.missionUID == helloMissionId }) else { return nil }

        return HelloWorldMissionViewModel()
    }()
    private let landingViewModel = HUDLandingViewModel()
    /// Cellular indicator view model. Used to display indicator in the center of the HUD.
    private let cellularIndicatorViewModel = HUDCellularIndicatorViewModel()
    /// View model which tells if 4G pairing is available.
    private let cellularPairingAvailabilityViewModel = CellularPairingAvailabilityViewModel()

    /// Property used to store the alert panel view controller.
    private var currentAlertPanelVC: AlertPanelViewController?

    // MARK: - Private Enums
    private enum Constants {
        static let indicatorDelay: Double = 2.0
        static let cameraSlidersButtonWidth: CGFloat = 51
        static let cellularIndicatorTaskKey: String = "cellularIndicatorTaskKey"
        static let orientationKeyWord: String = "orientation"
    }

    // MARK: - Setup
    static func instantiate(coordinator: HUDCoordinator) -> HUDViewController {
        let viewController = StoryboardScene.Hud.initialScene.instantiate()
        viewController.coordinator = coordinator
        return viewController
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Override Funcs
    public override func viewDidLoad() {
        super.viewDidLoad()
        listenWillEnterForeground()
        splitControls.start(currentMissionManager: Services.hub.currentMissionManager)
        // TODO: this part needs to be fixed, some interactions with the map do not work without that (drag mostly)
        customControls = Services.hub.ui.touchAndFly
        customControls?.start()
        setupAlertPanel()
        setupActionWidgetContainer()

        listenMissionMode()
        listenTopBarChanges()
        listenRemoteShutdownAlert()
        listenPinCode()
        listenMissionLauncherState()
        listenToActionWidgets()

        // Handle rotation when coming from Onboarding.
        let value = UIInterfaceOrientation.landscapeRight.rawValue
        UIDevice.current.setValue(value, forKey: Constants.orientationKeyWord)
        Services.hub.drone.ophtalmoService.ophtalmoMissionStatePublisher
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
        guard let coordinator = coordinator else { return }

        if (coordinator.childCoordinators.last as? OphtalmoCoordinator) != nil,
           Services.hub.drone.ophtalmoService.ophtalmoMissionState != .active {
                coordinator.childCoordinators.removeLast()
        }

        splitControls.setupSplitIfNeeded()
        splitControls.updateConstraintForForeground()
        // Check if any critical alert needs to be displayed.
        rightPanelContainerControls.viewModel.forceHidePanel(!currentMissionManager.mode.isRightPanelRequired)

        // check if ophtalmo is active and show it if it is the case.
        if Services.hub.drone.ophtalmoService.ophtalmoMissionState == .active {
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

        super.viewWillAppear(animated)
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        rightPanelContainerControls.stop()
        removeViewModelObservers()
        stopTasksIfNeeded()
        removeContainerViews()
    }

    public override var shouldAutorotate: Bool {
        return true
    }

    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let topBar = segue.destination as? HUDTopBarViewController {
            topBar.navigationDelegate = self
        } else if let cameraStreamingVC = segue.destination as? HUDCameraStreamingViewController {
            splitControls.cameraStreamingViewController = cameraStreamingVC
            cameraStreamingVC.delegate = self
        } else if let indicatorViewController = segue.destination as? HUDIndicatorViewController {
            splitControls.delegate = indicatorViewController
            indicatorViewController.indicatorViewControllerNavigation = self
        } else if let bottomBarContainerVC = segue.destination as? BottomBarContainerViewController {
            bottomBarContainerVC.coordinator = coordinator
        } else if let missionLauncherVC = segue.destination as? MissionProviderSelectorViewController {
            // TODO: wrong injection. Also... SEGUES
            let services: ServiceHub = Services.hub
            missionLauncherVC.viewModel = MissionProviderSelectorViewModel(currentMissionManager: services.currentMissionManager,
                                                                           missionsStore: services.missionsStore,
                                                                           delegate: self,
                                                                           missionsManager: services.drone.airsdkMissionsManager,
                                                                           connectedDroneHolder: services.connectedDroneHolder)
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
        listenLanding()
    }
}

// MARK: - Actions
private extension HUDViewController {
    /// Dismiss mission Launcher by tapping outside it
    @IBAction func dismissMissionLauncherButtonTouchedUpInside() {
        coordinator?.hideMissionLauncher()
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
        currentMissionManager.modePublisher.sink { [unowned self] mode in
            setupMap()
            coordinator?.presentModeEntryCoordinatorIfNeeded(mode: mode)
            videoControls.enableAeTarget(enabled: mode.isAeLockEnabled)
        }
        .store(in: &cancellables)
    }

    func listenTopBarChanges() {
        topBarService.showTopBarPublisher
            .sink { [weak self] show in
                guard let self = self else { return }
                UIView.animate {
                    self.topStackView.alphaHidden(!show)
                }
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
        guard let coordinator = coordinator else { return }
        coordinator.services.ui.uiComponentsDisplayReporter.isActionWidgetShownPublisher.sink { [weak self] isWidgetShown in
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
        let isActionWidgetShown = coordinator?.services.ui.uiComponentsDisplayReporter.isActionWidgetShown ?? false
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

    /// Sets up constraints.
    func setupConstraints() {
        infoBannerTopConstraint.constant = Layout.hudTopBarHeight(isRegularSizeClass) + Layout.mainSpacing(isRegularSizeClass)
        centerButtonHeightConstraint.constant = Layout.buttonIntrinsicHeight(isRegularSizeClass)
        centerButtonBottomConstraint.constant = -Layout.mainPadding(isRegularSizeClass)
        missionControls.updateConstraints(animated: false)
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
        let mode = currentMissionManager.mode
        if let map = mode.customMapProvider?() as? MapViewController {
            // Add custom map.
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
        guard let coordinator = coordinator else { return }
        let viewModel = ActionWidgetViewModel(rthService: coordinator.services.drone.rthService,
                                              panoramaService: coordinator.services.panoramaService,
                                              currentMissionManager: coordinator.services.currentMissionManager)
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
        helloWorldViewModel?.state.valueChanged = { [weak self] state in
            self?.showHelloWorldIfNeeded(state: state)
        }
        joysticksViewModel.state.valueChanged = { [weak self] state in
            self?.updateJoysticksVisibility(with: state)
        }
        cellularIndicatorViewModel.state.valueChanged = { [weak self] state in
            self?.updateCellularIndicatorView(with: state)
        }
        if let state = helloWorldViewModel?.state.value {
            showHelloWorldIfNeeded(state: state)
        }

        updateJoysticksVisibility(with: joysticksViewModel.state.value)
        updateCellularIndicatorView(with: cellularIndicatorViewModel.state.value)
        cellularPairingAvailabilityViewModel.updateAvailabilityState()
    }

    func listenLanding() {
        landingViewModel.isLanding
            .removeDuplicates()
            .combineLatest(landingViewModel.isReturnHomeActive.removeDuplicates())
            .sink { [unowned self] (isLanding, isReturnHomeActive) in
                if isLanding || isReturnHomeActive {
                    updateLandingView(customIndicatorProvider: customIndicatorViewModel)
                }
            }
            .store(in: &cancellables)
    }

    /// Removes each view model value changed.
    func removeViewModelObservers() {
        joysticksViewModel.state.valueChanged = nil
        helloWorldViewModel?.state.valueChanged = nil
        cellularIndicatorViewModel.state.valueChanged = nil
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

    func updateLandingView(customIndicatorProvider: CustomIndicatorProvider?) {
        guard landingViewModel.isLandingOrRth else { return }

        let view = HUDLandingView()
        view.setCustomProvider(customIndicatorProvider: customIndicatorProvider)
        view.commonInitHUDRTHAnimationView()
        addIndicatorView(with: view)
    }

    /// Display a view when the drone sends a Hello World AirSdk message.
    ///
    /// - Parameters:
    ///     - state: The state of the Hello World AirSdk mission
    func showHelloWorldIfNeeded(state: HelloWorldMissionState) {
        guard state.missionState == .active,
              let messageToDisplay = helloWorldViewModel?.messageToDisplay(),
              !HelloWorldMessageView.isAlreadyDisplayed(in: self) else {
                  return
              }

        let helloWorldMessageView = HelloWorldMessageView()
        helloWorldMessageView.displayThenHide(in: self, with: messageToDisplay)
    }
}

// MARK: - Cellular Landing Indicator Views
private extension HUDViewController {
    /// Updates cellular indicator view or display error.
    ///
    /// - Parameters:
    ///     - state: The cellular indicator state
    func updateCellularIndicatorView(with state: HUDCellularIndicatorState?) {
        guard let state = state else { return }

        if state.shouldShowCellularAlert {
            switch state.currentAlert {
            case .airplaneMode,
                    .networkStatusDenied,
                    .networkStatusError,
                    .notRegistered,
                    .simBlocked:
                displayCellularAlert(with: state)
            default:
                break
            }
        } else if state.shouldShowCellularInfo {
            guard landingViewModel.isLandingOrRth else { return }

            displayCellularIndicatorView(with: state)
        }
    }

    /// Displays a cellular alert.
    ///
    /// - Parameters:
    ///     - state: The cellular indicator state
    func displayCellularAlert(with state: HUDCellularIndicatorState) {
        guard let title = state.currentAlert?.title,
              let description = state.currentAlert?.description else {
                  return
              }

        let resumeAction = AlertAction(title: L10n.commonRetry, actionHandler: { [weak self] in
            self?.cellularIndicatorViewModel.resumeProcess()
        })

        let cancelAction = AlertAction(title: L10n.cancel,
                                       actionHandler: { [weak self] in
            self?.cellularIndicatorViewModel.stopProcess()
        })

        let alert = AlertViewController.instantiate(title: title,
                                                    message: description,
                                                    messageColor: .errorColor,
                                                    closeButtonStyle: .cross,
                                                    cancelAction: cancelAction,
                                                    validateAction: resumeAction)

        self.present(alert, animated: true)
    }

    /// Adds a cellular indicator view.
    ///
    /// - Parameters:
    ///     - state: The cellular indicator state
    func displayCellularIndicatorView(with state: HUDCellularIndicatorState) {
        let view = HUDCellularIndicatorView()
        view.configure(state: state.currentCellularState)
        addIndicatorView(with: view)
        setupDelayedTask(addCellularAnimation,
                         delay: Constants.indicatorDelay,
                         key: Constants.cellularIndicatorTaskKey)
    }

    /// Adds the cellular animation.
    func addCellularAnimation() {
        UIView.animate(withDuration: Style.longAnimationDuration,
                       delay: 0.0,
                       options: .curveEaseOut,
                       animations: {
            self.indicatorContainerView.alpha = 0.0
        }, completion: { (_) in
            self.indicatorContainerView.isHidden = true
            self.indicatorContainerView.alpha = 1.0
            self.cellularIndicatorViewModel.stopProcess()
        })
    }

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
