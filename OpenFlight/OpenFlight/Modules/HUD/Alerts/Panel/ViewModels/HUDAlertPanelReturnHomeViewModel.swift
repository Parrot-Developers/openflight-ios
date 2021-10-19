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
    public var startViewIsVisible: Bool {
        return false
    }
    public var actionLabelIsVisible: Bool {
        return true
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
    public var hasProgressView: Bool {
        return false
    }
    public var countdownMessage: ((Int) -> String)? {
        return currentAlert == .autoLandingAlert
            ? L10n.alertAutolandingRemainingTime
            : L10n.alertReturnHomeRemainingTime
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
         currentAlertsStack: Set<RthAlertType>) {
        super.init(droneConnectionState: droneConnectionState,
                   remoteControlConnectionState: remoteControlConnectionState)
        self.state = state
        self.alertsDismissed = alertsDismissed
        self.subtitleColor = subtitleColor
        self.countdown = countdown
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
            && self.currentAlertsStack == other.currentAlertsStack
    }

    public override func copy() -> HUDAlertPanelReturnHomeState {
        return HUDAlertPanelReturnHomeState(droneConnectionState: self.droneConnectionState,
                                            remoteControlConnectionState: self.remoteControlConnectionState,
                                            state: self.state,
                                            alertsDismissed: self.alertsDismissed,
                                            subtitleColor: self.subtitleColor,
                                            countdown: self.countdown,
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

    // Convenience computed properties
    private var isLanding: Bool { flyingIndicatorsRef?.value?.flyingState == .landing }
    private var smartRthDelay: TimeInterval? { returnHomeRef?.value?.autoTriggerDelay }
    private var homeReachability: HomeReachability? { returnHomeRef?.value?.homeReachability }
    private var autolandingDelay: TimeInterval? { alarmsRef?.value?.automaticLandingDelay }
    private var autolandingAlarmLevel: Alarm.Level? { alarmsRef?.value?.getAlarm(kind: .automaticLandingBatteryIssue).level }

    // MARK: - Init
    override init() {
        super.init()

        listenBatteryInfo()
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)
        listenReturnHome(drone: drone)
        listenFlyingIndicators(drone: drone)
        listenAlarms(drone: drone)
    }

    override func listenRemoteControl(remoteControl: RemoteControl) {
        super.listenRemoteControl(remoteControl: remoteControl)
        listenRemoteControlBattery(remoteControl: remoteControl)
    }
}

// MARK: - Private Funcs
private extension HUDAlertPanelReturnHomeViewModel {
    /// Starts watcher for user device battery.
    func listenBatteryInfo() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.updateUserBatteryLevel),
                                               name: UIDevice.batteryLevelDidChangeNotification,
                                               object: nil)
        updateUserBatteryLevel()
    }

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

    /// Starts watcher for remote control battery info.
    func listenRemoteControlBattery(remoteControl: RemoteControl) {
        batteryRemoteControlRef = remoteControl.getInstrument(Instruments.batteryInfo) { [weak self] batteryInfo in
            self?.updateBatteryInfoState(alertLevel: batteryInfo?.batteryValueModel.alertLevel,
                                         deviceType: .remoteControl)
        }
    }

    /// Updates Return Home availability.
    func updateReturnHomeAvailability() {
        let copy = state.value.copy()

        guard copy.currentAlert != .autoLandingAlert else { return }

        switch returnHomeRef?.value?.state {
        case .active:
            copy.state = .started
        case .idle:
            // Delay reported by drone may decrease faster than every second.
            // => Need to check if threshold has been reached or passed.
            if let smartRthDelay = smartRthDelay,
               smartRthDelay <= AlertDelayThreshold.smartRth,
               let homeReachability = homeReachability,
               homeReachability == .warning,
               !isLanding {
                copy.countdown = Int(smartRthDelay)
                if !copy.currentAlertsStack.contains(.droneBatteryWarningAlert) {
                    copy.currentAlertsStack.insert(.droneBatteryWarningAlert)
                }
                copy.subtitleColor = AlertLevel.warning.color
                copy.state = .available
            } else {
                copy.state = .unavailable
            }
        default:
            copy.state = .unavailable
        }

        state.set(copy)
    }

    /// Update the device battery level.
    @objc func updateUserBatteryLevel() {
        updateBatteryInfoState(alertLevel: UIDevice.current.batteryValueModel.alertLevel,
                               deviceType: .userDevice)
    }

    /// Update state according to battery state.
    ///
    /// - Parameters:
    ///     - alertLevel: current device battery alert
    ///     - deviceType: device type
    func updateBatteryInfoState(alertLevel: AlertLevel?, deviceType: DeviceType) {
        let copy = state.value.copy()

        guard copy.currentAlert != .autoLandingAlert,
              flyingIndicatorsRef?.value?.flyingState.isFlyingOrWaiting == true,
              returnHomeRef?.value?.state == .idle,
              alertLevel?.isWarningOrCritical == true else {
            return
        }

        copy.subtitleColor = alertLevel?.color

        switch alertLevel {
        case .veryCritical where deviceType == .remoteControl:
            guard !copy.alertsDismissed.contains(.remoteBatteryCriticalAlert) else {
                return
            }

            copy.currentAlertsStack.insert(.remoteBatteryCriticalAlert)
        case .critical where deviceType == .userDevice:
            guard !copy.alertsDismissed.contains(.userDeviceCriticalAlert) else {
                return
            }

            copy.currentAlertsStack.insert(.userDeviceCriticalAlert)
        case .warning where deviceType == .userDevice:
            guard !copy.alertsDismissed.contains(.userDeviceWarningAlert) else {
                return
            }

            copy.currentAlertsStack.insert(.userDeviceWarningAlert)
        default:
            break
        }

        copy.state = .available

        state.set(copy)
    }

    /// Starts Return Home.
    func startReturnHome() {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyHUDPanelButton.start.name,
                             newValue: nil,
                             logType: .button)
        _ = returnHomeRef?.value?.activate()
    }

    /// Stops Return Home.
    func stopReturnHome() {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyHUDPanelButton.stop.name,
                             newValue: nil,
                             logType: .button)
        _ = returnHomeRef?.value?.deactivate()
    }

    /// Cancels auto-triggered RTH.
    func cancelAutoTriggerRTH() {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyHUDPanelButton.cancel.name,
                             newValue: nil,
                             logType: .button)
        _ = drone?.cancelAutoTriggerReturnHome()
    }

    /// Manages panel visibility for the current alert.
    func dismissPanel() {
        let copy = state.value.copy()
        copy.countdown = 0

        if let alert = copy.currentAlert {
            // Dismiss the current alert.
            copy.alertsDismissed.insert(alert)
        }

        self.state.set(copy)
        updatePowerAlarm()
        let remoteBatteryInfo = remoteControl?.getInstrument(Instruments.batteryInfo)
        updateBatteryInfoState(alertLevel: remoteBatteryInfo?.batteryValueModel.alertLevel,
                               deviceType: .remoteControl)
        updateBatteryInfoState(alertLevel: UIDevice.current.batteryValueModel.alertLevel,
                               deviceType: .userDevice)
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
        // Delay reported by drone may decrease faster than every second.
        // => Need to check if threshold has been reached or passed.
        if let autolandingDelay = autolandingDelay,
           autolandingDelay <= AlertDelayThreshold.autoLanding,
           let autolandingAlarmLevel = autolandingAlarmLevel,
           autolandingAlarmLevel != .off,
           autolandingAlarmLevel != .notAvailable,
           drone?.isStateFlying == true {
            let copy = state.value.copy()
            copy.currentAlertsStack.insert(.autoLandingAlert)
            copy.subtitleColor = AlertLevel.critical.color
            copy.countdown = Int(autolandingDelay)

            state.set(copy)
        }
    }
}

// MARK: - AlertPanelActionType
extension HUDAlertPanelReturnHomeViewModel: AlertPanelActionType {
    func startAction() {
        guard state.value.state == .available else { return }

        startReturnHome()
        dismissPanel()
    }

    func cancelAction() {
        cancelAutoTriggerRTH()
        dismissPanel()
    }

    func startTimer() {
        // Do nothing.
    }
}
