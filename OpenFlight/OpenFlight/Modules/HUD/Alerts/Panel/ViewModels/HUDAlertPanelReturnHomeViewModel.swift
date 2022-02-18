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

import GroundSdk
import UIKit

/// Delay before triggering alerts (in seconds).
public struct AlertDelayThreshold {
    static let smartRth: TimeInterval = 10
    static let autoLanding: TimeInterval = 10
}

/// State for `HUDAlertPanelReturnHomeViewModel`.
public final class HUDAlertPanelReturnHomeState: DevicesConnectionState, AlertPanelState {
    // MARK: - AlertPanelState Properties
    public var title: String? {
        switch currentAlert {
        case .autoLandingAlert:
            return L10n.alertAutoLanding
        default:
            return L10n.alertReturnHomeTitle
        }
    }
    public var icon: UIImage? {
        switch currentAlert {
        case .autoLandingAlert:
            return Asset.Alertes.AutoLanding.icAutoLanding.image
        default:
            return Asset.Alertes.Rth.icRTHAlertPanel.image
        }
    }
    /// Returns the alert subtitle regarding the current alert.
    public var subtitle: String? {
        return currentAlert?.subtitle
    }
    public var subtitleColor: UIColor?
    /// No images for animation in this alert type.
    public var animationImages: [UIImage]?
    public var state: AlertPanelCurrentState?
    public var isAlertForceHidden: Bool = false
    public var countdown: Int?
    public var initialCountdown: TimeInterval?
    public var startViewIsVisible: Bool {
        return false
    }
    public var actionLabelIsVisible: Bool {
        return false
    }
    public var actionLabelText: String?
    public var rthAlertType: RthAlertType? {
        return currentAlert
    }
    public var stopViewStyle: StopViewStyle? {
        currentAlert == .autoLandingAlert
        ? .cancelAlert
        : .classic
    }
    /// Should be shown if it is available and if it is not in force hidden state.
    public var shouldShowAlertPanel: Bool {
        droneConnectionState?.isConnected() == true
        && (shouldShowRthAlert || shouldShowAutolandingAlert)
        && canShowAlert
    }
    public var hasAnimation: Bool {
        return true
    }
    public var hasTextCountdown: Bool {
        return false
    }
    public var countdownMessage: ((Int) -> String)? {
        return nil
    }

    // MARK: - Internal Properties
    /// Stores all current alerts.
    var currentAlertsStack: Set<RthAlertType> = []
    /// Property used to tell if the user dismiss a specific alert in order to not show it again.
    var alertsDismissed: Set<RthAlertType> = []
    /// Returns current alert type with the highest priority.
    var currentAlert: RthAlertType? {
        return currentAlertsStack
            .sorted(by: { $0.priority < $1.priority })
            .first(where: {!alertsDismissed.contains($0)})
    }

    // MARK: - Private Properties
    /// Tells whether the current alert as been dismissed.
    private var canShowAlert: Bool {
        return currentAlert != nil
    }
    private var shouldShowRthAlert: Bool {
        state == .available && countdown != 0 // Need to close alert when countdown has reached 0.
    }
    private var shouldShowAutolandingAlert: Bool {
        currentAlert == .autoLandingAlert && countdown != 0 // Need to close alert when countdown has reached 0.
    }

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - droneConnectionState: drone connection state
    ///    - remoteControlConnectionState: remote connection state
    ///    - state: return to home state
    ///    - alertsDismissed: array which contains all alerts which have been dismissed
    ///    - subtitleColor: subtitle color
    ///    - countdown: countdown before starting action
    ///    - currentAlertsStack: current stack of alerts
    init(droneConnectionState: DeviceConnectionState?,
         remoteControlConnectionState: DeviceConnectionState?,
         state: AlertPanelCurrentState?,
         alertsDismissed: Set<RthAlertType>,
         subtitleColor: UIColor?,
         countdown: Int?,
         initialCountdown: TimeInterval?,
         currentAlertsStack: Set<RthAlertType>) {
        super.init(droneConnectionState: droneConnectionState,
                   remoteControlConnectionState: remoteControlConnectionState)
        self.state = state
        self.alertsDismissed = alertsDismissed
        self.subtitleColor = subtitleColor
        self.countdown = countdown
        self.initialCountdown = initialCountdown
        self.currentAlertsStack = currentAlertsStack
    }

    // MARK: - Override Funcs
    public override func isEqual(to other: DevicesConnectionState) -> Bool {
        guard let other = other as? HUDAlertPanelReturnHomeState else {
            return false
        }
        return super.isEqual(to: other)
        && self.state == other.state
        && self.alertsDismissed == other.alertsDismissed
        && self.subtitleColor == other.subtitleColor
        && self.countdown == other.countdown
        && self.initialCountdown == other.initialCountdown
        && self.currentAlertsStack == other.currentAlertsStack
    }

    public override func copy() -> HUDAlertPanelReturnHomeState {
        return HUDAlertPanelReturnHomeState(droneConnectionState: self.droneConnectionState,
                                            remoteControlConnectionState: self.remoteControlConnectionState,
                                            state: self.state,
                                            alertsDismissed: self.alertsDismissed,
                                            subtitleColor: self.subtitleColor,
                                            countdown: self.countdown,
                                            initialCountdown: initialCountdown,
                                            currentAlertsStack: self.currentAlertsStack)
    }
}

/// View model which manages Return Home panel.
final class HUDAlertPanelReturnHomeViewModel: DevicesStateViewModel<HUDAlertPanelReturnHomeState> {
    // MARK: - Private Properties
    private var returnHomeRef: Ref<ReturnHomePilotingItf>?
    private var batteryRemoteControlRef: Ref<BatteryInfo>?
    private var alarmsRef: Ref<Alarms>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var connectionStateRef: Ref<DeviceState>?

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)
        listenReturnHome(drone: drone)
        listenFlyingIndicators(drone: drone)
        listenAlarms(drone: drone)
    }
}

// MARK: - Private Funcs
private extension HUDAlertPanelReturnHomeViewModel {
    /// Starts watcher for Return Home.
    func listenReturnHome(drone: Drone) {
        returnHomeRef = drone.getPilotingItf(PilotingItfs.returnHome) { [weak self] _ in
            self?.updateReturnHomeAvailability()
        }
    }

    /// Starts watcher for flying indicators.
    func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] state in
            self?.updateReturnHomeAvailability()
            if state?.state == .landed {
                self?.resetAlertVisibility()
            }
        }
    }

    /// Starts watcher for drone power alarm.
    func listenAlarms(drone: Drone) {
        alarmsRef = drone.getInstrument(Instruments.alarms) { [weak self] _ in
            self?.updatePowerAlarm()
        }
    }

    /// Updates Return Home availability.
    func updateReturnHomeAvailability() {
        let copy = state.value.copy()

        guard copy.currentAlert != .autoLandingAlert else { return }

        let returnHome = drone?.getPilotingItf(PilotingItfs.returnHome)

        switch returnHome?.state {
        case .active:
            copy.state = .started
        case .idle:
            // Delay reported by drone may decrease faster than every second.
            // => Need to check if threshold has been reached or passed.
            if let smartRthDelay = returnHome?.autoTriggerDelay,
               smartRthDelay <= AlertDelayThreshold.smartRth,
               returnHome?.homeReachability == .warning,
               drone?.isLanding != true {
                let isAlertActive = copy.currentAlertsStack.contains(.droneBatteryWarningAlert)
                if copy.initialCountdown == nil || !isAlertActive {
                    // New alert => need to set initialCountdown in order to correctly update panel's progress bar.
                    // Reset initialCountdown to nil in case 0 is the first delay value received for current alert
                    // in order to avoid stuck countdown (alert will never be actually displayed and therefore
                    // won't be closed, leading to 0 being considered as latest active countdown value).
                    copy.initialCountdown = smartRthDelay == 0 ? nil : smartRthDelay
                }
                copy.currentAlertsStack.insert(.droneBatteryWarningAlert)
                copy.countdown = Int(smartRthDelay)
                copy.subtitleColor = AlertLevel.warning.color
                copy.state = .available
            } else {
                copy.state = .unavailable
            }
        default:
            copy.state = .unavailable
        }

        // Do not update state if `.droneBatteryWarningAlert` is not current alert in order to
        // avoid view model properties conflicts in case of overriding alerts (instruments updates
        // still trigger even if alert is not active one).
        guard copy.currentAlert == .droneBatteryWarningAlert else { return }
        state.set(copy)
    }

    /// Starts Return Home.
    func startReturnHome() {
        LogEvent.log(.simpleButton(LogEvent.LogKeyHUDPanelButton.start.name))
        _ = returnHomeRef?.value?.activate()
    }

    /// Stops Return Home.
    func stopReturnHome() {
        LogEvent.log(.simpleButton(LogEvent.LogKeyHUDPanelButton.stop.name))
        _ = returnHomeRef?.value?.deactivate()
    }

    /// Cancels auto-triggered RTH.
    func cancelAutoTriggerRTH() {
        LogEvent.log(.simpleButton(LogEvent.LogKeyHUDPanelButton.cancel.name))
        _ = drone?.cancelAutoTriggerReturnHome()
    }

    /// Lands the drone.
    func landDrone() {
        LogEvent.log(.simpleButton(LogEvent.LogKeyHUDPanelButton.start.name))
        guard let manualPiloting = drone?.getPilotingItf(PilotingItfs.manualCopter) else { return }
        manualPiloting.land()
    }

    /// Manages panel visibility for the current alert.
    func dismissPanel() {
        let copy = state.value.copy()
        copy.countdown = 0
        copy.initialCountdown = nil

        if let alert = copy.currentAlert {
            // Dismiss the current alert.
            copy.alertsDismissed.insert(alert)
        }

        self.state.set(copy)
        updatePowerAlarm()
    }

    /// Resets alert visibility.
    func resetAlertVisibility() {
        let copy = state.value.copy()
        copy.alertsDismissed.removeAll()
        copy.currentAlertsStack.removeAll()
        self.state.set(copy)
    }

    /// Updates drone power alarm.
    func updatePowerAlarm() {
        guard let alarms = drone?.getInstrument(Instruments.alarms) else { return }
        let autolandingAlarmLevel = alarms.getAlarm(kind: .automaticLandingBatteryIssue).level

        // Delay reported by drone may decrease faster than every second.
        // => Need to check if threshold has been reached or passed.
        if alarms.automaticLandingDelay <= AlertDelayThreshold.autoLanding,
           autolandingAlarmLevel != .off,
           autolandingAlarmLevel != .notAvailable,
           drone?.isStateFlying == true {
            let copy = state.value.copy()
            let isAlertActive = copy.currentAlertsStack.contains(.autoLandingAlert)
            if copy.initialCountdown == nil || !isAlertActive {
                // New alert => need to set initialCountdown in order to correctly update panel's progress bar.
                // Reset initialCountdown to nil in case 0 is the first delay value received for current alert
                // in order to avoid stuck countdown (alert will never be actually displayed and therefore
                // won't be closed, leading to 0 being considered as latest active countdown value).
                copy.initialCountdown = alarms.automaticLandingDelay == 0 ? nil : alarms.automaticLandingDelay
            }
            copy.currentAlertsStack.insert(.autoLandingAlert)
            // Do not update state if `.autoLandingAlert` is not current alert in order to
            // avoid view model properties conflicts in case of overriding alerts (should never
            // occur for autoLanding for now, as it's the highest priority alert).
            guard copy.currentAlert == .autoLandingAlert else { return }
            copy.subtitleColor = AlertLevel.critical.color
            copy.countdown = Int(alarms.automaticLandingDelay)
            copy.state = .available
            state.set(copy)
        }
    }
}

// MARK: - AlertPanelActionType
extension HUDAlertPanelReturnHomeViewModel: AlertPanelActionType {
    func startAction() {
        guard state.value.state == .available else { return }

        if state.value.currentAlert == .autoLandingAlert {
            landDrone()
        } else {
            startReturnHome()
        }
        dismissPanel()
    }

    func cancelAction() {
        cancelAutoTriggerRTH()
        dismissPanel()
    }
}
