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
            return Asset.Alertes.icPanelActionButton.image
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
    public var cancelDelayEnded: Bool?
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
        return .classic
    }
    /// Should be shown if it is available and if it is not in force hidden state.
    public var shouldShowAlertPanel: Bool {
        return droneConnectionState?.isConnected() == true
            && (state == .available || currentAlert == .autoLandingAlert)
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
            .sorted(by: { $0.priority > $1.priority })
            .first(where: {!alertsDismissed.contains($0)})
    }

    // MARK: - Private Properties
    /// Tells whether the current alert as been dismissed.
    private var canShowAlert: Bool {
        return currentAlert != nil
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
    /// Returns true if the home is unreachable.
    private var isHomeUnreachable: Bool {
        guard let returnHome = drone?.getPilotingItf(PilotingItfs.returnHome) else {
            return true
        }

        return returnHome.homeReachability == .notReachable
            || returnHome.homeReachability == .unknown
            || state.value.state == .unavailable
    }

    // MARK: - Init
    init() {
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
        listenArlams(drone: drone)
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
    func listenArlams(drone: Drone) {
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

        switch returnHomeRef?.value?.state {
        case .active:
            copy.state = .started
        case .idle:
            copy.state = .available
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
        if flyingIndicatorsRef?.value?.flyingState.isFlyingOrWaiting == true,
           returnHomeRef?.value?.state == .idle,
           alertLevel?.isWarningOrCritical == true {
            copy.subtitleColor = alertLevel?.color

            switch alertLevel {
            case .critical where deviceType == .drone:
                guard !copy.alertsDismissed.contains(.droneBatteryCriticalAlert) else {
                    return
                }

                copy.currentAlertsStack.insert(.droneBatteryCriticalAlert)
            case .critical where deviceType == .remoteControl:
                guard !copy.alertsDismissed.contains(.remoteBatteryCriticalAlert) else {
                    return
                }

                copy.currentAlertsStack.insert(.remoteBatteryCriticalAlert)
            case .critical where deviceType == .userDevice:
                guard !copy.alertsDismissed.contains(.userDeviceCriticalAlert) else {
                    return
                }

                copy.currentAlertsStack.insert(.userDeviceCriticalAlert)
            case .warning where deviceType == .drone:
                guard !copy.alertsDismissed.contains(.droneBatteryWarningAlert) else {
                    return
                }

                copy.currentAlertsStack.insert(.droneBatteryWarningAlert)
            case .warning where deviceType == .remoteControl:
                guard !copy.alertsDismissed.contains(.remoteBatteryWarningAlert) else {
                    return
                }

                copy.currentAlertsStack.insert(.remoteBatteryWarningAlert)
            case .warning where deviceType == .userDevice:
                guard !copy.alertsDismissed.contains(.userDeviceWarningAlert) else {
                    return
                }

                copy.currentAlertsStack.insert(.userDeviceWarningAlert)
            default:
                break
            }
        }

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
        updateBatteryInfoState(alertLevel: batteryRemoteControlRef?.value?.alertLevel,
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
        let delay = alarmsRef?.value?.automaticLandingDelay ?? 0
        let autoLandingAlarm = alarmsRef?.value?.getAlarm(kind: .automaticLandingBatteryIssue).level

        if autoLandingAlarm == .critical,
           delay > 0.0,
           drone?.isStateFlying == true,
           isHomeUnreachable {
            let copy = state.value.copy()
            copy.currentAlertsStack.insert(.autoLandingAlert)
            copy.subtitleColor = ColorName.redTorch.color
            copy.countdown = Int(delay)
            state.set(copy)
        } else {
            let powerAlarmLevel = alarmsRef?.value?.getAlarm(kind: .power).level
            switch powerAlarmLevel {
            case .critical:
                updateBatteryInfoState(alertLevel: .critical,
                                       deviceType: .drone)
            case .warning:
                updateBatteryInfoState(alertLevel: .warning,
                                       deviceType: .drone)
            default:
                break
            }
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
        stopReturnHome()
        dismissPanel()
    }

    func startTimer() {
        // Do nothing.
    }
}
