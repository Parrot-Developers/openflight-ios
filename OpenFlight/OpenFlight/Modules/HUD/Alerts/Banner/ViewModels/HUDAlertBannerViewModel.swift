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

/// State for `HUDAlertBannerViewModel`.
final class HUDAlertBannerState: DeviceConnectionState {
    /// Alert to display.
    fileprivate(set) var alert: HUDAlertType?
    /// Whether phone should vibrate for alert.
    fileprivate(set) var shouldVibrate: Bool = false

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: drone connection state
    ///    - alert: alert to display
    ///    - shouldVibrate: whether user device should vibrate
    init(connectionState: DeviceState.ConnectionState,
         alert: HUDAlertType?,
         shouldVibrate: Bool) {
        super.init(connectionState: connectionState)
        self.alert = alert
        self.shouldVibrate = shouldVibrate
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? HUDAlertBannerState else { return false }

        return super.isEqual(to: other)
            && (self.alert?.isSameAlert(as: other.alert) == true
                    || (self.alert == nil && other.alert == nil))
            && self.shouldVibrate == other.shouldVibrate
    }

    override func copy() -> HUDAlertBannerState {
        return HUDAlertBannerState(connectionState: self.connectionState,
                                   alert: self.alert,
                                   shouldVibrate: self.shouldVibrate)
    }
}

private extension ULogTag {
    static let tag = ULogTag(name: "HUDAlertBannerVM")
}

/// View model for `HUDAlertBannerViewController`.
/// Computes all current alerts and notifies on higher priority alert change.
final class HUDAlertBannerViewModel: DroneStateViewModel<HUDAlertBannerState> {
    // MARK: - Private Properties
    private var alarmsRef: Ref<Alarms>?
    private var takeoffChecklistRef: Ref<TakeoffChecklist>?
    private var motorsRef: Ref<CopterMotors>?
    private var cameraRef: Ref<MainCamera2>?
    private var gimbalRef: Ref<Gimbal>?
    private var networkControlRef: Ref<NetworkControl>?
    private var gpsRef: Ref<Gps>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var alertList = AlertList()
    private var lastVibrationTimestamps = [AlertCategoryType: TimeInterval]()
    private let geofenceViewModel = HUDAlertBannerGeofenceViewModel()
    private let autoLandingViewModel = HUDAlertBannerAutoLandingViewModel()
    private let userStorageViewModel = HUDAlertBannerUserStorageViewModel()
    private let commonAlertViewModel = HUDAlertBannerProvider.shared.alertBannerCommonViewModel

    /// Latest received gimbal errors, `nil` if unavailable.
    private var gimbalErrors: Set<GimbalError>?

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenAlarms(drone: drone)
        listenTakeoffChecklist(drone: drone)
        listenMotors(drone: drone)
        listenCamera(drone: drone)
        listenGimbal(drone: drone)
        listenNetworkControl(drone: drone)
        listenGps(drone: drone)
        listenFlyingIndicators(drone: drone)
        listenGeofence()
        listenAutoLanding()
        listenUserStorage()
        listenCommonAlertViewModel()
    }
}

// MARK: - Private Funcs
/// Listener Methods.
private extension HUDAlertBannerViewModel {
    /// Starts watcher for alarms.
    func listenAlarms(drone: Drone) {
        alarmsRef = drone.getInstrument(Instruments.alarms) { [weak self] _ in
            self?.updateMotorsAlerts(drone)
            self?.updateConditionsAlerts(drone)
            self?.updateImuSaturationAlerts(drone)
            self?.updateObstacleAvoidanceAlerts(drone)
            self?.updateState()
        }
    }

    /// Starts watcher for alarms.
    func listenTakeoffChecklist(drone: Drone) {
        takeoffChecklistRef = drone.getInstrument(Instruments.takeoffChecklist) { [weak self] checklist in
            if let checklist = checklist {
                self?.updateTakeoffAlerts(checklist)
                self?.updateState()
            }
        }
    }

    /// Starts watcher for motors.
    func listenMotors(drone: Drone) {
        motorsRef = drone.getPeripheral(Peripherals.copterMotors) { [weak self] _ in
            self?.updateMotorsAlerts(drone)
            self?.updateState()
        }
    }

    /// Starts watcher for camera.
    func listenCamera(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [weak self] _ in
            self?.updateConditionsAlerts(drone)
            self?.updateState()
        }
    }

    /// Starts watcher for gimbal.
    func listenGimbal(drone: Drone) {
        // reset latest received gimbal errors
        gimbalErrors = nil

        gimbalRef = drone.getPeripheral(Peripherals.gimbal) { [unowned self] gimbal in
            // gimbal observer is called very often, so filter theses events,
            // to do the state update only when gimbal errors change
            let errors = gimbal?.currentErrors ?? []
            guard errors != gimbalErrors else { return }
            gimbalErrors = errors

            alertList.cleanAlerts(withCategories: [.componentsCamera])
            if let alerts = gimbal?.currentAlerts {
                alertList.addAlerts(alerts)
            }
            updateState()
        }
    }

    /// Starts watcher for network control.
    func listenNetworkControl(drone: Drone) {
        networkControlRef = drone.getPeripheral(Peripherals.networkControl) { [weak self] networkControl in
            self?.alertList.cleanAlerts(withCategories: [.wifi])
            if let alerts = networkControl?.currentWifiAlerts {
                self?.alertList.addAlerts(alerts)
            }
            self?.updateState()
        }
    }

    /// Starts watcher for drone's gps.
    func listenGps(drone: Drone) {
        gpsRef = drone.getInstrument(Instruments.gps) { [weak self] _ in
            self?.updateConditionsAlerts(drone)
            self?.updateState()
        }
    }

    /// Starts watcher for flying indicators.
    func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] _ in
            self?.updateConditionsAlerts(drone)
            self?.updateState()
        }
    }

    /// Starts watcher for geofence alerts.
    func listenGeofence() {
        geofenceViewModel.state.valueChanged = { [weak self] state in
            self?.alertList.cleanAlerts(withCategories: [.geofence])
            self?.alertList.addAlerts(state.alerts)
            self?.updateState()
        }
    }

    /// Starts watcher for auto landing alerts.
    func listenAutoLanding() {
        autoLandingViewModel.state.valueChanged = { [weak self] state in
            self?.alertList.cleanAlerts(withCategories: [.autoLanding])
            self?.alertList.addAlerts(state.alerts)
            self?.updateState()
        }
    }

    /// Starts watcher for user storage alerts.
    func listenUserStorage() {
        userStorageViewModel.state.valueChanged = { [weak self] state in
            self?.alertList.cleanAlerts(withCategories: [.sdCard])
            self?.alertList.addAlerts(state.alerts)
            self?.updateState()
        }
    }

    /// Starts watcher for a common view model.
    func listenCommonAlertViewModel() {
        commonAlertViewModel?.state.valueChanged = { [weak self] state in
            self?.alertList.cleanAlerts(withCategories: [.flightMode])
            self?.alertList.addAlerts(state.alerts)
            self?.updateState()
        }
    }
}

/// State update Methods.
private extension HUDAlertBannerViewModel {
    /// Updates obstacle avoidance alerts.
    func updateObstacleAvoidanceAlerts(_ drone: Drone) {
        alertList.cleanAlerts(withCategories: [.obstacleAvoidance])
        if let alerts = drone.getInstrument(Instruments.alarms)?.obastacleAvoidanceAlerts(drone: drone) {
            alertList.addAlerts(alerts)
        }
    }

    /// Updates alerts for motors.
    func updateMotorsAlerts(_ drone: Drone) {
        alertList.cleanAlerts(withCategories: [.componentsMotor])
        if let alerts = drone.getInstrument(Instruments.alarms)?.motorAlerts(drone: drone) {
            alertList.addAlerts(alerts)
        }
    }

    /// Updates special conditions alerts.
    func updateConditionsAlerts(_ drone: Drone) {
        alertList.cleanAlerts(withCategories: [.conditions, .conditionsWind])
        if let alerts = drone.getInstrument(Instruments.alarms)?.conditionsAlerts(drone: drone) {
            alertList.addAlerts(alerts)
        }
    }

    /// Updates alerts for Imu saturation.
    func updateImuSaturationAlerts(_ drone: Drone) {
        alertList.cleanAlerts(withCategories: [.componentsImu])
        if let alert = drone.getInstrument(Instruments.alarms)?.imuSaturationAlerts(drone: drone) {
            alertList.addAlerts([alert])
        }
    }

    /// Updates alerts from takeoff checklist.
    func updateTakeoffAlerts(_ checklist: TakeoffChecklist) {
        alertList.cleanAlerts(withCategories: [.takeoff])
        if checklist.getAlarm(kind: TakeoffAlarm.Kind.batteryGaugeUpdateRequired).level == .on
            || checklist.getAlarm(kind: TakeoffAlarm.Kind.batteryIdentification).level == .on {
            alertList.addAlerts([HUDBannerCriticalAlertType.takeoffUnavailable])
        }
    }

    /// Updates view model's state.
    func updateState() {
        var shouldVibrate = false
        if let newAlert = alertList.mainAlert,
           newAlert.level.isError,
           alertList.mainAlert?.isSameAlert(as: state.value.alert) == false {
            // Alert changed, should compute vibration.
            if let timestamp = lastVibrationTimestamps[newAlert.category] {
                if Date.timeIntervalSinceReferenceDate - timestamp > newAlert.vibrationDelay {
                    shouldVibrate = true
                }
            } else {
                shouldVibrate = true
            }

            // Save last vibration timestamp.
            if shouldVibrate {
                lastVibrationTimestamps[newAlert.category] = Date.timeIntervalSinceReferenceDate
            }
        }

        if let mainAlert = alertList.mainAlert {
            ULog.i(.tag, "Got alerts: \(alertList)")
            ULog.i(.tag, "Main alert: \(mainAlert.label)")
        }
        let copy = state.value.copy()
        copy.alert = alertList.mainAlert
        copy.shouldVibrate = shouldVibrate
        state.set(copy)
    }
}
