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

// MARK: - Protocols
protocol HUDTopBarViewControllerNavigation: class {
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
    @IBOutlet private weak var radarView: HUDRadarView!
    @IBOutlet private weak var droneActionView: DroneActionView!
    @IBOutlet private weak var dashboardButton: UIButton!
    @IBOutlet private weak var settingsButton: UIButton!
    @IBOutlet private weak var topBarView: UIView!
    @IBOutlet private weak var telemetryBarViewController: UIView!

    // MARK: - Internal Properties
    weak var navigationDelegate: HUDTopBarViewControllerNavigation?
    var context: HUDTopBarContext = .standard

    // MARK: - Private Properties
    private var radarViewModel: HUDRadarViewModel?
    private var topBarViewModel: TopBarViewModel?

    // MARK: - Private Enums
    private enum Constants {
        /// Minimum width of main view for which the radar is displayed.
        static let minimumViewWidthForRadar: CGFloat = 667.0
        /// Gradient layer start alpha.
        static let gradientStartAlpha: CGFloat = 0.7
        /// Gradient layer end alpha.
        static let gradientEndAlpha: CGFloat = 0.0
        /// Default animation duration.
        static let defaultAnimationDuration: TimeInterval = 0.35
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        topBarViewModel = TopBarViewModel(stateDidUpdate: { [weak self] state in
            UIView.animate(withDuration: Constants.defaultAnimationDuration) {
                self?.topBarView.alphaHidden(state.shouldHide)
            }
            self?.updateRadarViewVisibility()
            self?.updateDroneActionViewVisibility()
            self?.updateTelemetryVisibility()
        })
        updateRadarViewVisibility()
        updateDroneActionViewVisibility()
        updateTelemetryVisibility()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        dashboardButton.isHidden = context == .flightPlanEdition
        settingsButton.isHidden = context == .flightPlanEdition
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        view.addGradient(startAlpha: Constants.gradientStartAlpha,
                         endAlpha: Constants.gradientEndAlpha,
                         superview: view)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateRadarViewVisibility()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let telemetryVC = segue.destination as? TelemetryBarViewController {
            telemetryVC.navigationDelegate = self
        } else if let droneInfosVC = segue.destination as? HUDDroneInfoViewController {
            droneInfosVC.navigationDelegate = self
        } else if let controllerInfosVC = segue.destination as? HUDControllerInfoViewController {
            controllerInfosVC.navigationDelegate = self
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
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyHUDTopBarButton.dashboard, logType: .simpleButton)
        navigationDelegate?.openDashboard()
    }

    /// Called when user taps the settings button.
    @IBAction func settingsButtonTouchedUpInside(_ sender: Any) {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyHUDTopBarButton.settings, logType: .simpleButton)
        navigationDelegate?.openSettings(SettingsType.defaultType)
    }
}

// MARK: - Private Funcs
private extension HUDTopBarViewController {
    /// Starts view model and shows radar view if size is sufficient.
    /// Removes it otherwise.
    func updateRadarViewVisibility() {
        if view.frame.width >= Constants.minimumViewWidthForRadar {
            radarViewModel = HUDRadarViewModel(stateDidUpdate: { [weak self] state in
                self?.radarView.state = state
            })
            // Set initial state.
            radarView.state = radarViewModel?.state.value
            radarView.isHidden = topBarViewModel?.state.value.shouldHideRadar == true
        } else {
            radarViewModel = nil
            radarView.isHidden = true
        }
    }

    /// Update Drone action buttons visibility.
    func updateDroneActionViewVisibility() {
        guard let state = topBarViewModel?.state.value else {
            droneActionView.isHidden = false
            return
        }
        droneActionView.isHidden = state.shouldHideDroneAction == true
    }

    /// Update telemetry bar visibility.
    func updateTelemetryVisibility() {
        telemetryBarViewController.isHidden = topBarViewModel?.state.value.shouldHideTelemetry == true
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
}

// MARK: - HUDDroneInfoViewControllerNavigation
extension HUDTopBarViewController: HUDDroneInfoViewControllerNavigation {
    func openDroneInfos() {
        navigationDelegate?.openDroneInfos()
    }
}

// MARK: - HUDControllerInfoViewControllerNavigation
extension HUDTopBarViewController: HUDControllerInfoViewControllerNavigation {
    func openRemoteControlInfos() {
        navigationDelegate?.openRemoteControlInfos()
    }
}
