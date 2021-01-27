// Copyright (C) 2020 Parrot Drones SAS
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

/// Main view controller for the Heads-Up Display (HUD).
final class HUDViewController: UIViewController {
    // MARK: - Internal Outlets
    @IBOutlet internal weak var splitControls: SplitControls!
    @IBOutlet internal weak var missionControls: MissionControls!
    @IBOutlet internal weak var flightPlanControls: FlightPlanControls!
    @IBOutlet internal weak var videoControls: VideoControls!
    @IBOutlet internal weak var alertControls: AlertControls!

    // MARK: - Private Outlets
    @IBOutlet private weak var joysticksView: JoysticksView!
    @IBOutlet private weak var liveStreamingWidgetView: LiveStreamingWidgetView!
    @IBOutlet private weak var alertPanelContainerView: UIView!
    @IBOutlet private weak var customValidationView: UIView!
    @IBOutlet private weak var AELockContainerView: UIView!
    // MARK: - Public Properties
    var customControls: CustomHUDControls?

    // MARK: - Internal Properties
    weak var coordinator: HUDCoordinator?

    // MARK: - Private Properties
    private var defaultMapViewController: MapViewController?
    private var missionModeViewModel = MissionLauncherViewModel()
    private var joysticksViewModel: JoysticksViewModel?
    private var flightReportViewModel = FlightReportViewModel()
    private var liveStreamingWidgetViewModel: LiveStreamingWidgetViewModel?
    private var takeOffAlertViewModel: TakeOffAlertViewModel?
    private var cellularPairingViewModel: CellularPairingViewModel?
    private var lockAETargetZoneViewController: LockAETargetZoneViewController?
    private var remoteShutdownAlertViewModel: RemoteShutdownAlertViewModel?
    private var helloWorldViewModel = HelloWorldMissionViewModel()

    /// Property used to store the alert panel view controller.
    private var currentAlertPanelVC: AlertPanelViewController?

    // MARK: - Private Enums
    /// Enum which stores messages to log.
    private enum EventLoggerConstants {
        static let screenMessage: String = "HUD"
    }

    // MARK: - Setup
    static func instantiate(coordinator: HUDCoordinator) -> HUDViewController {
        let viewController = StoryboardScene.Hud.initialScene.instantiate()
        viewController.coordinator = coordinator
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        splitControls.start()
        flightPlanControls.start()
        customControls = CustomHUDControlsProvider.shared.customControls
        customControls?.validationView = customValidationView
        customControls?.start()
        videoControls.hideAETargetZone()
        setupMap()
        setupViewModels()
        initAlertPanel()
        coordinator?.hudCriticalAlertDelegate = self
        liveStreamingWidgetView.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        splitControls.setupSplitIfNeeded()
        splitControls.updateSecondaryViewContent()
        // Show flight plan panel if needed.
        if let missionMode = MissionLauncherViewModel().state.value.mode,
           missionMode.isFlightPlanPanelRequired {
            flightPlanControls.viewModel.forceHidePanel(false)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        logScreen(logMessage: EventLoggerConstants.screenMessage)
        showCellularPairingIfNeeded()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
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
            bottomBarContainerVC.bottomBarDelegate = self
            bottomBarContainerVC.coordinator = coordinator
        } else if let missionLauncherVC = segue.destination as? MissionProviderSelectorViewController {
            missionControls.missionLauncherViewController = missionLauncherVC
        } else if let flightPlanPanelVC = segue.destination as? FlightPlanPanelViewController {
            flightPlanPanelVC.delegate = self
            flightPlanControls.flightPlanPanelViewController = flightPlanPanelVC
        } else if let lockAETargetZoneVC = segue.destination as? LockAETargetZoneViewController {
            videoControls.lockAETargetZoneViewController = lockAETargetZoneVC
        }
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Private Funcs
private extension HUDViewController {
    /// Map setup.
    ///
    /// - Parameters:
    ///     - missionLauncherState: mission launcher state
    func setupMap(with missionLauncherState: MissionLauncherState? = nil) {
        if let map = missionLauncherState?.mode?.customMapProvider?() as? MapViewController {
            // Add custom map.
            map.editionDelegate = self
            self.splitControls.addMap(map, parent: self)
            // Force recreate default map next time it will be necessary (this will deinit it).
            defaultMapViewController = nil
        } else {
            // Add default map, create it if needed.
            // defaultMapViewController is used to keep map when mission modes use same default map.
            let map = defaultMapViewController ?? StoryboardScene.Map.initialScene.instantiate()
            map.editionDelegate = self
            defaultMapViewController = map
            map.customControls = customControls
            customControls?.mapViewController = map
            self.splitControls.addMap(map, parent: self)
        }
    }

    /// Inits left panel for proactive alerts.
    func initAlertPanel() {
        let currentAlertPanelVC = HUDAlertPanelProvider.shared.alertPanelViewControllers?.alertPanelViewController()
        let alertPanel = currentAlertPanelVC ?? HUDAlertPanelViewController.instantiate()
        alertPanel.delegate = alertControls
        self.addChild(alertPanel)
        alertPanel.view.removeFromSuperview()
        alertPanelContainerView.addWithConstraints(subview: alertPanel.view)
    }

    /// Changes joysticks visibility regarding view model state.
    ///
    /// - Parameters:
    ///     - state: current joysticks visibility state
    func updateJoysticksVisibility(with state: JoysticksState?) {
        joysticksView.isHidden = state?.shouldHideJoysticks == true
    }

    /// Changes live streaming widget visibility regarding view model state.
    ///
    /// - Parameters:
    ///     - state: current streaming state
    func updateLiveStreamingWidgetVisibility(with state: LiveStreamingWidgetState?) {
        liveStreamingWidgetView.isHidden = !(state?.shouldShowWidget ?? false)
    }

    /// Changes take off unavailability alert modal visibility regarding view model state.
    ///
    /// - Parameters:
    ///     - state: The alert state
    func updateTakeOffAlertVisibility(with state: TakeOffAlertState?) {
        takeOffAlertViewModel?.updateTakeOffStatus()

        guard state?.canShowAlert == true else { return }

        coordinator?.displayTakeOffAlert(alert: state?.currentAlert)
    }

    /// Shows the drone cellular process if its available.
    func showCellularPairingIfNeeded() {
        guard cellularPairingViewModel?.state.value.canShowModal == true else { return }

        coordinator?.displayCellularPairingAvailable()
    }

    /// Shows remote alert shutdown process.
    func showRemoteShutdownAlert() {
        guard remoteShutdownAlertViewModel?.state.value.canShowModal == true else { return }

        coordinator?.displayRemoteAlertShutdown()
    }

    /// Setup all view models.
    func setupViewModels() {
        missionModeViewModel.state.valueChanged = { [weak self] state in
            self?.setupMap(with: state)
            self?.coordinator?.presentModeEntryCoordinatorIfNeeded(state: state)
        }
        joysticksViewModel = JoysticksViewModel(stateDidUpdate: { [weak self] state in
            self?.updateJoysticksVisibility(with: state)
        })
        flightReportViewModel.state.valueChanged = { [weak self] state in
            if state.shouldDisplayFlightReport {
                self?.coordinator?.displayFlightReport()
            }
        }
        liveStreamingWidgetViewModel = LiveStreamingWidgetViewModel(stateDidUpdate: { [weak self] state in
            self?.updateLiveStreamingWidgetVisibility(with: state)
        })
        takeOffAlertViewModel = TakeOffAlertViewModel(stateDidUpdate: { [weak self] state in
            self?.updateTakeOffAlertVisibility(with: state)
        })
        cellularPairingViewModel = CellularPairingViewModel(stateDidUpdate: { [weak self] _ in
            self?.showCellularPairingIfNeeded()
        })
        remoteShutdownAlertViewModel = RemoteShutdownAlertViewModel(stateDidUpdate: { [weak self] _ in
            self?.showRemoteShutdownAlert()
        })
        helloWorldViewModel.state.valueChanged = { [weak self] state in
            self?.showHelloWorldIfNeeded(state: state)
        }

        updateLiveStreamingWidgetVisibility(with: liveStreamingWidgetViewModel?.state.value)
        updateJoysticksVisibility(with: joysticksViewModel?.state.value)
        updateTakeOffAlertVisibility(with: takeOffAlertViewModel?.state.value)
        showCellularPairingIfNeeded()
    }
}

// MARK: - LiveStreamingDelegate
extension HUDViewController: LiveStreamingDelegate {
    func displayLiveStreamingPanel() {
        coordinator?.displayLiveStreaming()
    }
}

// MARK: - HUDCoordinatorCriticalAlertDelegate
extension HUDViewController: HUDCoordinatorCriticalAlertDelegate {
    func onCriticalAlertDismissed() {
        takeOffAlertViewModel?.dimissCurrentAlert()
        self.showCellularPairingIfNeeded()
    }
}

// MARK: - Utils for Hello World Mission
private extension HUDViewController {
    /// Display a view when the drone sends a Hello World protobuf message.
    /// - Parameters:
    ///     - state: The state of the Hello World Protobuf mission
    func showHelloWorldIfNeeded(state: HelloWorldMissionState) {
        guard state.missionState == .active,
              let messageToDisplay = helloWorldViewModel.messageToDisplay(),
              !HelloWorldMessageView.isAlreadyDisplayed(in: self) else {
            return
        }

        let helloWorldMessageView = HelloWorldMessageView()
        helloWorldMessageView.displayThenHide(in: self, with: messageToDisplay)
    }
}
