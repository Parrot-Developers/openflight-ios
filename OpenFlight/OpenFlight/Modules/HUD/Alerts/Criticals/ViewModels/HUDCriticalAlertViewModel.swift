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

/// State for `HUDCriticalAlertViewModel`.
final class HUDCriticalAlertState: DevicesConnectionState {
    // MARK: - Internal Properties
    /// Stack of alerts.
    fileprivate(set) var alertStack: Set<HUDCriticalAlertType> = []
    /// Return true if takeoff is requested.
    fileprivate(set) var isTakeoffRequested: Bool = false
    /// Return true if update alert has been dismissed.
    fileprivate(set) var isUpdateAlertDismissed: Bool = false
    /// Return true if drone is Flying.
    fileprivate(set) var isDroneFlying: Bool = false

    /// Returns the alert to display according to its priority and if it should be displayed.
    var currentAlert: HUDCriticalAlertType? {
        return alertStack
            .sorted()
            .first(where: { isTakeoffRequested ? true : $0.isUpdateRequired && !isUpdateAlertDismissed })
    }

    /// Tells if the alert should be displayed.
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
    ///    - alertStack: stack of HUD critical alerts
    ///    - isTakeoffRequested: tells if takeoff is requested
    ///    - isUpdateAlertDismissed: tells if update alert has been dismissed
    ///    - isDroneFlying: tells if drone is flying
    init(droneConnectionState: DeviceConnectionState?,
         remoteControlConnectionState: DeviceConnectionState?,
         alertStack: Set<HUDCriticalAlertType>,
         isTakeoffRequested: Bool,
         isUpdateAlertDismissed: Bool,
         isDroneFlying: Bool) {
        super.init(droneConnectionState: droneConnectionState,
                   remoteControlConnectionState: remoteControlConnectionState)

        self.alertStack = alertStack
        self.isTakeoffRequested = isTakeoffRequested
        self.isUpdateAlertDismissed = isUpdateAlertDismissed
        self.isDroneFlying = isDroneFlying
    }

    // MARK: - Override Funcs
    override func copy() -> HUDCriticalAlertState {
        return HUDCriticalAlertState(droneConnectionState: droneConnectionState,
                                     remoteControlConnectionState: remoteControlConnectionState,
                                     alertStack: alertStack,
                                     isTakeoffRequested: isTakeoffRequested,
                                     isUpdateAlertDismissed: isUpdateAlertDismissed,
                                     isDroneFlying: isDroneFlying)
    }

    override func isEqual(to other: DevicesConnectionState) -> Bool {
        guard let other = other as? HUDCriticalAlertState else { return false }

        return super.isEqual(to: other)
            && self.alertStack == other.alertStack
            && self.isTakeoffRequested == other.isTakeoffRequested
            && self.isUpdateAlertDismissed == other.isUpdateAlertDismissed
            && self.isDroneFlying == other.isDroneFlying
    }
}

/// Manages critical alert screen visibility.
final class HUDCriticalAlertViewModel: DevicesStateViewModel<HUDCriticalAlertState> {
    // MARK: - Private Properties
    private var takeoffChecklistRef: Ref<TakeoffChecklist>?
    private var remoteUpdaterRef: Ref<Updater>?
    private var droneUpdaterRef: Ref<Updater>?
    private var takeOffRequestedObserver: Any?

    // MARK: - Init
    override init() {
        super.init()

        listenTakeOffRequestDidChange()
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.remove(observer: takeOffRequestedObserver)
        takeOffRequestedObserver = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenTakeoffChecklist(drone)
        listenDroneUpdater(drone)
        listenFlyingIndicators(drone)
    }

    override func listenRemoteControl(remoteControl: RemoteControl) {
        super.listenRemoteControl(remoteControl: remoteControl)

        listenRemoteUpdater(remoteControl)
    }
}

// MARK: - Internal Funcs
extension HUDCriticalAlertViewModel {
    /// Called when current alert is dismissed.
    func onAlertDismissed() {
        let copy = state.value.copy()
        copy.isTakeoffRequested = false
        if state.value.currentAlert?.isUpdateRequired == true {
            copy.isUpdateAlertDismissed = true
        }
        state.set(copy)
    }
}

// MARK: - Private Funcs
private extension HUDCriticalAlertViewModel {
    /// Starts watcher for takeoff checklist.
    func listenTakeoffChecklist(_ drone: Drone) {
        takeoffChecklistRef = drone.getInstrument(Instruments.takeoffChecklist) { [weak self] checklist in
            let copy = self?.state.value.copy()

            var sensors: [TakeoffAlarm.Kind] = []
            for kind in TakeoffAlarm.Kind.allCases {
                let isAlarmSet = checklist?.getAlarm(kind: kind).level == .on
                let type: HUDCriticalAlertType?
                switch kind {
                case .baro,
                     .gps,
                     .gyro,
                     .magneto,
                     .ultrasound,
                     .vcam,
                     .verticalTof:
                    if isAlarmSet {
                        sensors.append(kind)
                    }
                    type = nil
                default:
                    type = HUDCriticalAlertType.from(kind)
                }
                if let type = type {
                    copy?.alertStack.update(type, shouldAdd: isAlarmSet)
                }
            }

            if let oldSensorAlarm = copy?.alertStack.first(where: { $0.isSensorAlarm }) {
                copy?.alertStack.remove(oldSensorAlarm)
            }
            if !sensors.isEmpty {
                copy?.alertStack.insert(.sensorFailure(sensors))
            }

            self?.state.set(copy)
        }
    }

    /// Starts watcher for remote update.
    func listenRemoteUpdater(_ remoteControl: RemoteControl) {
        remoteUpdaterRef = remoteControl.getPeripheral(Peripherals.updater) { [weak self] _ in
            self?.updateFirmwareAlerts()
        }
    }

    /// Starts watcher for drone update.
    func listenDroneUpdater(_ drone: Drone) {
        droneUpdaterRef = drone.getPeripheral(Peripherals.updater) { [weak self] _ in
            self?.updateFirmwareAlerts()
        }
    }

    /// Starts watcher for flying indicators.
    func listenFlyingIndicators(_ drone: Drone) {
        _ = drone.getInstrument(Instruments.flyingIndicators) { [weak self] flyingIndicators in
            let copy = self?.state.value.copy()
            copy?.isDroneFlying = flyingIndicators?.state == .flying
            self?.state.set(copy)
        }
    }

    /// Updates firmware update alerts.
    func updateFirmwareAlerts() {
        let copy = state.value.copy()

        // Updates drone and remote version alert state.
        let remoteUpdateNeeded = remoteUpdaterRef?.value?.applicableFirmwares.isEmpty == false
        let droneUpdateNeeded = droneUpdaterRef?.value?.applicableFirmwares.isEmpty == false

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

        state.set(copy)
    }

    /// Starts watcher for take off availability.
    func listenTakeOffRequestDidChange() {
        takeOffRequestedObserver = NotificationCenter.default.addObserver(forName: .takeOffRequestedDidChange,
                                                                          object: nil,
                                                                          queue: nil) { [weak self] notification in
            let takeOffNotification = notification.userInfo?[HUDCriticalAlertConstants.takeOffRequestedNotificationKey]
            guard (takeOffNotification as? Bool) != nil else { return }

            let copy = self?.state.value.copy()
            copy?.isTakeoffRequested = true
            copy?.isUpdateAlertDismissed = false
            self?.state.set(copy)
        }
    }
}
