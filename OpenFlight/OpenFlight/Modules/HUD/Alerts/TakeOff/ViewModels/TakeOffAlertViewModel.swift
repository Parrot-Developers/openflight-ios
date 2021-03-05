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

/// State for `TakeOffAlertViewModel`.
final class TakeOffAlertState: DevicesConnectionState {
    // MARK: - Internal Properties
    /// Stack of alerts.
    fileprivate(set) var alertStack: Set<HUDCriticalAlertType> = []
    /// Stack of alerts dismissed by the user.
    fileprivate(set) var alertStackDismissed: Set<HUDCriticalAlertType> = []
    /// Return true if drone is Flying.
    fileprivate(set) var isDroneFlying: Bool = false

    /// Returns the alert to display according to its priority and if it's not in the dismissed alert stack.
    var currentAlert: HUDCriticalAlertType? {
        return alertStack
            .sorted()
            .first(where: {!alertStackDismissed.contains($0)})
    }

    /// Tells if the alert should be display.
    var canShowAlert: Bool {
        return currentAlert != nil
            && droneConnectionState?.isConnected() == true
            && !isDroneFlying
    }

    /// Tells if drone can take off.
    var canTakeOff: Bool {
        return alertStack.isEmpty
    }

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - droneConnectionState: drone connection state
    ///    - remoteControlConnectionState: remote control connection state
    ///    - alertStack: stack of take off unavailability alerts
    ///    - alertStackDismissed: stack of take off unavailability alerts which have been dismissed by the user
    ///    - isDroneFlying: tells if drone is flying
    init(droneConnectionState: DeviceConnectionState?,
         remoteControlConnectionState: DeviceConnectionState?,
         alertStack: Set<HUDCriticalAlertType>,
         alertStackDismissed: Set<HUDCriticalAlertType>,
         isDroneFlying: Bool) {
        super.init(droneConnectionState: droneConnectionState,
                   remoteControlConnectionState: remoteControlConnectionState)

        self.alertStack = alertStack
        self.alertStackDismissed = alertStackDismissed
        self.isDroneFlying = isDroneFlying
    }

    // MARK: - Override Funcs
    override func copy() -> TakeOffAlertState {
        return TakeOffAlertState(droneConnectionState: droneConnectionState,
                                 remoteControlConnectionState: remoteControlConnectionState,
                                 alertStack: alertStack,
                                 alertStackDismissed: alertStackDismissed,
                                 isDroneFlying: isDroneFlying)
    }

    override func isEqual(to other: DevicesConnectionState) -> Bool {
        guard let other = other as? TakeOffAlertState else { return false }

        return super.isEqual(to: other)
            && self.alertStack == other.alertStack
            && self.alertStackDismissed == other.alertStackDismissed
            && self.isDroneFlying == other.isDroneFlying
    }
}

/// Manages critical alert screen visibility when take off in unavailable.
final class TakeOffAlertViewModel: DevicesStateViewModel<TakeOffAlertState> {
    // MARK: - Private Properties
    private var alarmRef: Ref<Alarms>?
    private var remoteUpdaterRef: Ref<Updater>?
    private var droneUpdaterRef: Ref<Updater>?
    private var magnetometerRef: Ref<Magnetometer>?
    private var takeOffRequestedObserver: Any?
    private var remoteControlButtonGrabber: RemoteControlButtonGrabber?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?

    /// Defines a key when we grab the front bottom button of the remote.
    private var actionKey: String {
        return NSStringFromClass(type(of: self)) + SkyCtrl3ButtonEvent.frontBottomButton.description
    }

    // MARK: - Init
    override init(stateDidUpdate: ((TakeOffAlertState) -> Void)? = nil) {
        super.init(stateDidUpdate: stateDidUpdate)

        observesAppContext()
        listenTakeOffRequestDidChange()
        initGrabber()
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.remove(observer: takeOffRequestedObserver)
        takeOffRequestedObserver = nil
        remoteControlButtonGrabber?.ungrab()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenAlarm(drone)
        listenDroneUpdater(drone)
        listenDroneMagnetometer(drone)
        listenFlyingIndicators(drone)
        updateAlertsState()
    }

    override func listenRemoteControl(remoteControl: RemoteControl) {
        super.listenRemoteControl(remoteControl: remoteControl)

        listenRemoteUpdater(remoteControl)
        updateAlertsState()
    }

    override func remoteControlConnectionStateDidChange() {
        super.remoteControlConnectionStateDidChange()

        remoteControlButtonGrabber?.ungrab()
    }
}

// MARK: - Internal Funcs
extension TakeOffAlertViewModel {
    /// Dismisses current alert.
    func dimissCurrentAlert() {
        guard let alertToDismiss = state.value.currentAlert else { return }

        let copy = state.value.copy()
        copy.alertStackDismissed.insert(alertToDismiss)
        state.set(copy)
    }

    /// Updates both remote and app take off buttons.
    func updateTakeOffStatus() {
        if state.value.canTakeOff {
            remoteControlButtonGrabber?.ungrab()
        } else {
            remoteControlButtonGrabber?.grab()
        }
    }
}

// MARK: - Private Funcs
private extension TakeOffAlertViewModel {
    /// Starts watcher for drone alarm.
    func listenAlarm(_ drone: Drone) {
        alarmRef = drone.getInstrument(Instruments.alarms) { [weak self] _ in
            self?.updateAlertsState()
        }
    }

    /// Starts watcher for remote update.
    func listenRemoteUpdater(_ remoteControl: RemoteControl) {
        remoteUpdaterRef = remoteControl.getPeripheral(Peripherals.updater) { [weak self] _ in
            self?.updateAlertsState()
        }
    }

    /// Starts watcher for drone update.
    func listenDroneUpdater(_ drone: Drone) {
        droneUpdaterRef = drone.getPeripheral(Peripherals.updater) { [weak self] _ in
            self?.updateAlertsState()
        }
    }

    /// Starts watcher for drone magnetometer state.
    func listenDroneMagnetometer(_ drone: Drone) {
        magnetometerRef = drone.getPeripheral(Peripherals.magnetometer) { [weak self] _ in
            self?.updateAlertsState()
        }
    }

    /// Starts watcher for flying indicators.
    func listenFlyingIndicators(_ drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] _ in
            self?.updateAlertsState()
        }
    }

    /// Updates each alert state.
    func updateAlertsState() {
        let copy = state.value.copy()

        // Updates drone and remote version alert state.
        let remoteUpdateNeeded = remoteControl?.getPeripheral(Peripherals.updater)?.isUpToDate == false
        let droneUpdateNeeded = drone?.getPeripheral(Peripherals.updater)?.isUpToDate == false

        copy.alertStack.update(.droneAndRemoteUpdateRequired,
                               shouldAdd: remoteUpdateNeeded && droneUpdateNeeded)
        copy.alertStack.update(.droneUpdateRequired,
                               shouldAdd: droneUpdateNeeded)

        #if DEBUG
        // Remove update alerts for Sphinx.
        if drone?.getPeripheral(Peripherals.systemInfo)?.serial == "000000000000000000" {
            copy.alertStack.remove(.droneAndRemoteUpdateRequired)
            copy.alertStack.remove(.droneUpdateRequired)
        }
        #endif

        // Updates Alarms alerts.
        let alarms = drone?.getInstrument(Instruments.alarms)
        copy.alertStack.update(.highTemperature,
                               shouldAdd: alarms?.getAlarm(kind: .batteryTooHot).level == .critical)
        copy.alertStack.update(.lowTemperature,
                               shouldAdd: alarms?.getAlarm(kind: .batteryTooCold).level == .critical)
        copy.alertStack.update(.verticalCameraFailure,
                               shouldAdd: alarms?.getAlarm(kind: .verticalCamera).level == .critical)
        copy.alertStack.update(.droneCalibrationRequired,
                               shouldAdd: drone?.getPeripheral(Peripherals.magnetometer)?.calibrationState == .required)

        // Updates current flying state.
        copy.isDroneFlying = drone?.getInstrument(Instruments.flyingIndicators)?.state == .flying

        state.set(copy)
    }

    /// Starts watcher for app entering in background.
    func observesAppContext() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(cleanDimissedAlertsStackView),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }

    /// Cleans the dismissed alert stack.
    @objc func cleanDimissedAlertsStackView() {
        cleanDismissedAlerts()
    }

    /// Starts watcher for take off availability.
    func listenTakeOffRequestDidChange() {
        takeOffRequestedObserver = NotificationCenter.default.addObserver(forName: .takeOffRequestedDidChange,
                                                                          object: nil,
                                                                          queue: nil) { [weak self] notification in
            let takeOffNotification = notification.userInfo?[HUDCriticalAlertConstants.takeOffRequestedNotificationKey]
            guard (takeOffNotification as? Bool) != nil else { return }

            self?.cleanDismissedAlerts()
        }
    }

    /// Inits remote control grabber.
    func initGrabber() {
        // TODO: Will be reworked with MPP4.
        remoteControlButtonGrabber = RemoteControlButtonGrabber(button: .frontBottomButton,
                                                                event: .frontBottomButton,
                                                                key: actionKey,
                                                                action: { [weak self] _ in
                                                                    // We can show dismissed alert when user requests a take off.
                                                                    self?.cleanDismissedAlerts()
                                                                })
    }

    /// Cleans dismissed alerts when user wants to take off.
    func cleanDismissedAlerts() {
        guard !state.value.alertStackDismissed.isEmpty else { return }

        let copy = state.value.copy()
        copy.alertStackDismissed.removeAll()
        state.set(copy)
    }
}
