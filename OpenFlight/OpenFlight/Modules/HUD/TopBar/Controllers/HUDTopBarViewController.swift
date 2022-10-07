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

// MARK: - Protocols
protocol HUDTopBarViewControllerNavigation: AnyObject {
    /// Called when dashboard should be opened.
    func openDashboard()

    /// Called when settings should be opened.
    ///
    /// - Parameters:
    ///    - type: opens a specific part of the settings (optional)
    func openSettings(_ type: SettingsType?)

    /// Called when remote control informations screen should be opened.
    func openRemoteControlInfos()

    /// Called when drone informations screen should be opened.
    func openDroneInfos()
    /// Called when back button is tapped.
    func back()
}

// MARK: - Internal Enums
/// Context for `HUDTopBarViewController`.
enum HUDTopBarContext {
    /// Standard HUD.
    case standard
    /// Flight Plan Edition.
    case flightPlanEdition
}

/// Main view controller for HUD's Top Bar.
final class HUDTopBarViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var hudHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var infoPanelWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var radarView: HUDRadarView!
    @IBOutlet private weak var droneActionView: DroneActionView!
    @IBOutlet private weak var dashboardButton: UIButton!
    @IBOutlet private weak var settingsButton: UIButton!
    @IBOutlet private weak var topBarView: UIView!
    @IBOutlet private weak var telemetryBarViewController: UIView!
    @IBOutlet private weak var backButtonWidthConstraint: NSLayoutConstraint!

    // MARK: - Internal Properties
    weak var navigationDelegate: HUDTopBarViewControllerNavigation?
    weak var bottomBarService: HudBottomBarService?
    var context: HUDTopBarContext = .standard
    private var cancellables = Set<AnyCancellable>()

    private var hideRadarView = false

    // MARK: - Private Properties
    private let radarViewModel = HUDRadarViewModel()
    private let topBarViewModel = TopBarViewModel(service: Services.hub.ui.hudTopBarService,
                                                  uiComponentsDisplay: Services.hub.ui.uiComponentsDisplayReporter,
                                                  connectedDroneHolder: Services.hub.connectedDroneHolder,
                                                  connectedRemoteControlHolder: Services.hub.connectedRemoteControlHolder)

    // MARK: - Private Enums
    private enum Constants {
        /// Minimum width of main view for which the radar is displayed.
        static let minimumViewWidthForRadar: CGFloat = 667.0
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()

        topBarViewModel.shouldHideRadarPublisher
            .sink { [unowned self] in
                hideRadarView = $0
                updateRadarViewVisibility()
            }
            .store(in: &cancellables)
        topBarViewModel.shouldHideDroneActionPublisher
            .sink { [unowned self] in
                droneActionView.isHidden = $0
            }
            .store(in: &cancellables)

        topBarViewModel.goBackPublisher
            .sink { [weak self] in
                // Return to previous view in the stack.
                self?.navigationDelegate?.back()
            }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        dashboardButton.isHidden = context == .flightPlanEdition
        settingsButton.isHidden = context == .flightPlanEdition

        // Ensure increased hit area is on top for small buttons.
        stackView.bringSubviewToFront(dashboardButton)
        stackView.bringSubviewToFront(settingsButton)
        // Configure margins.
        stackView.directionalLayoutMargins = .init(top: 0,
                                                   leading: Layout.hudTopBarInnerMargins(isRegularSizeClass).leading,
                                                   bottom: 0,
                                                   trailing: Layout.hudTopBarInnerMargins(isRegularSizeClass).trailing)
        stackView.isLayoutMarginsRelativeArrangement = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateRadarViewVisibility()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let telemetryVC = segue.destination as? TelemetryBarViewController {
            telemetryVC.navigationDelegate = self
        } else if let controlsInfoVC = segue.destination as? HUDControlsInfoViewController {
            controlsInfoVC.navigationDelegate = self
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension HUDTopBarViewController {
    /// Called when user taps the Dashboard button.
    @IBAction func dashboardButtonTouchedUpInside(_ sender: Any) {
        LogEvent.log(.simpleButton(LogEvent.LogKeyHUDTopBarButton.dashboard))

        // Dashboard button can also be used to pop bottom bar levels whenever needed.
        // => Need to check if a level has to be popped. If so (`.pop()` returns `true`),
        // then button has completed its purpose and navigation needs to be aborted.
        if bottomBarService?.pop() ?? false { return }

        // Depending which view has opened the HUD, we must navigate throw back to display the correct
        // previous view. The navigation delegate is responsible to show the Dashboard if no view exist
        // in the navigation stack.
        navigationDelegate?.back()
    }

    /// Called when user taps the settings button.
    @IBAction func settingsButtonTouchedUpInside(_ sender: Any) {
        LogEvent.log(.simpleButton(LogEvent.LogKeyHUDTopBarButton.settings))
        navigationDelegate?.openSettings(SettingsType.defaultType)
    }
}

// MARK: - Private Funcs
private extension HUDTopBarViewController {
    /// Sets up view.
    func setupView() {
        dashboardButton.tintColor = .white
        backButtonWidthConstraint.constant = Layout.backButtonIntrinsicWidth(isRegularSizeClass)
        hudHeightConstraint.constant = Layout.hudTopBarHeight(isRegularSizeClass)
        infoPanelWidthConstraint.constant = Layout.hudTopBarPanelWidth(isRegularSizeClass)
        infoPanelWidthConstraint.isActive = view.bounds.width > Constants.minimumViewWidthForRadar
        dashboardButton.setImage(Asset.Common.Icons.icBack.image, for: .normal)
    }

    /// Starts view model and shows radar view if size is sufficient.
    /// Removes it otherwise.
    func updateRadarViewVisibility() {
        if view.frame.width >= Constants.minimumViewWidthForRadar {
            radarViewModel.state.valueChanged = { [weak self] state in
                self?.radarView.state = state
            }
            // set initial state
            radarView.state = radarViewModel.state.value
            radarView.isHidden = hideRadarView
        } else {
            radarViewModel.state.valueChanged = nil
            radarView.isHidden = true
        }
    }
}

// MARK: - TelemetryBarViewControllerNavigation
extension HUDTopBarViewController: TelemetryBarViewControllerNavigation {
    func openBehaviourSettings() {
        navigationDelegate?.openSettings(SettingsType.behaviour)
    }

    func openGeofenceSettings() {
        navigationDelegate?.openSettings(SettingsType.geofence)
    }

    func openQuickSettings() {
        navigationDelegate?.openSettings(SettingsType.quick)
    }
}

// MARK: - HUDControlsInfoViewControllerNavigation
extension HUDTopBarViewController: HUDControlsInfoViewControllerNavigation {
    func openRemoteControlInfos() {
        navigationDelegate?.openRemoteControlInfos()
    }

    func openDroneInfos() {
        navigationDelegate?.openDroneInfos()
    }

    func openNetworkSettings() {
        navigationDelegate?.openSettings(SettingsType.network)
    }
}
