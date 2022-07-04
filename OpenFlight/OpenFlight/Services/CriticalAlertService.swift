//    Copyright (C) 2022 Parrot Drones SAS
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

import Foundation
import GroundSdk
import Combine

private extension ULogTag {
    static let tag = ULogTag(name: "CriticalAlert")
}

/// Critical alert service.
public protocol CriticalAlertService: AnyObject {
    /// Whether drone can take off.
    var canTakeOff: Bool { get }
    /// Current critical alert.
    var alert: HUDCriticalAlertType? { get }
    /// Publisher for critical alerts.
    var alertPublisher: AnyPublisher<HUDCriticalAlertType?, Never> { get }
    /// Dismisses the current alert.
    func dismissCurrentAlert()
    /// Updates a takeoff alert.
    ///
    /// - Parameters:
    ///    - alert: the alert to update
    ///    - show: whether the alert needs to be shown
    func updateTakeoffAlert(_ alert: HUDCriticalAlertType, show: Bool)
}

/// Implementation of `CriticalAlertService`.
class CriticalAlertServiceImpl {

    // MARK: Private properties

    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// References to instruments and peripherals.
    private var takeoffChecklistRef: Ref<TakeoffChecklist>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    /// Takeoff request observer.
    private var takeoffRequestObserver: Any?
    /// Critical alert.
    private var alertSubject = CurrentValueSubject<HUDCriticalAlertType?, Never>(nil)
    /// Set of currently raised alerts which prevent takeoff.
    private var takeoffAlerts: Set<HUDCriticalAlertType> = []
    /// Set of currently raised alerts which don't prevent takeoff.
    private var otherAlerts: Set<HUDCriticalAlertType> = []
    /// Whether drone is connected.
    private var isDroneConnected = false
    /// Whether drone is flying.
    private var isDroneFlying = false
    /// Whether update alert has been dismissed.
    private var isUpdateAlertDismissed = false

    // MARK: init

    /// Constructor.
    ///
    /// - Parameters:
    ///   - connectedDroneHolder: drone holder
    ///   - updateService: update service
    ///   - removableUserStorageService: removable user storage service
    init(connectedDroneHolder: ConnectedDroneHolder,
         updateService: UpdateService,
         removableUserStorageService: RemovableUserStorageService) {
        listen(connectedDroneHolder: connectedDroneHolder)
        listen(updateService: updateService)
        listen(removableUserStorageService: removableUserStorageService)
        listenTakeoffRequests()
    }

    // MARK: Deinit
    deinit {
        NotificationCenter.default.remove(observer: takeoffRequestObserver)
        takeoffRequestObserver = nil
    }
}

// MARK: Private functions
private extension CriticalAlertServiceImpl {

    /// Listens to connected drone.
    ///
    /// - Parameter connectedDroneHolder: drone holder
    func listen(connectedDroneHolder: ConnectedDroneHolder) {
        connectedDroneHolder.dronePublisher
            .sink { [unowned self] in
                guard let drone = $0 else {
                    isDroneConnected = false
                    takeoffChecklistRef = nil
                    flyingIndicatorsRef = nil
                    return
                }
                isDroneConnected = true
                listenTakeoffChecklist(drone: drone)
                listenFlyingIndicators(drone: drone)
            }
            .store(in: &cancellables)
    }

    /// Listens to update state changes.
    ///
    /// - Parameter updateService: the service
    func listen(updateService: UpdateService) {
        updateService.droneUpdatePublisher.removeDuplicates()
            .combineLatest(updateService.remoteUpdatePublisher.removeDuplicates())
            .sink { [unowned self] updateState in
                takeoffAlerts.update(.droneAndRemoteUpdateRequired, shouldAdd: updateState == (.required, .required))
                takeoffAlerts.update(.droneUpdateRequired, shouldAdd: updateState.0 == .required)
                takeoffAlerts.update(.remoteUpdateRequired, shouldAdd: updateState.1 == .required)
                publish()
            }
            .store(in: &cancellables)
    }

    /// Listens to removable user storage state changes.
    ///
    /// - Parameter removableUserStorageService: the service
    func listen(removableUserStorageService: RemovableUserStorageService) {
        removableUserStorageService.userStoragePhysicalStatePublisher.removeDuplicates()
            .combineLatest(removableUserStorageService.userStorageFileSystemStatePublisher.removeDuplicates())
            .sink { [unowned self] userStorageState in
                otherAlerts.update(.sdCardNotDetected,
                                   shouldAdd: userStorageState.0 == .noMedia)
                otherAlerts.update(.sdCardNeedsFormat,
                                   shouldAdd: userStorageState == (.available, .needFormat))
                publish()
            }
            .store(in: &cancellables)
    }

    /// Listens to takeoff requests.
    func listenTakeoffRequests() {
        takeoffRequestObserver = NotificationCenter.default.addObserver(forName: .takeOffRequestedDidChange,
                                                                        object: nil,
                                                                        queue: nil) { [unowned self] notification in
            let takeoffNotification = notification.userInfo?[HUDCriticalAlertConstants.takeOffRequestedNotificationKey]
            guard (takeoffNotification as? Bool) != nil else { return }

            publish(isTakeoffRequested: true)
        }
    }

    /// Listens to takeoff checklist changes.
    ///
    /// - Parameter drone: drone to monitor
    func listenTakeoffChecklist(drone: Drone) {
        takeoffChecklistRef = drone.getInstrument(Instruments.takeoffChecklist) { [unowned self] checklist in
            guard let checklist = checklist else { return }

            var sensors: [TakeoffAlarm.Kind] = []
            for kind in TakeoffAlarm.Kind.allCases {
                let isAlarmSet = checklist.getAlarm(kind: kind).level == .on
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
                    takeoffAlerts.update(type, shouldAdd: isAlarmSet)
                }
            }

            if let oldSensorAlarm = takeoffAlerts.first(where: { $0.isSensorAlarm }) {
                takeoffAlerts.remove(oldSensorAlarm)
            }
            if !sensors.isEmpty {
                takeoffAlerts.insert(.sensorFailure(sensors))
            }

            publish()
        }
    }

    /// Listens to flying indicators changes.
    ///
    /// - Parameter drone: drone to monitor
    func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [unowned self] flyingIndicators in
            isDroneFlying = flyingIndicators?.state == .flying
        }
    }

    /// Publishes critical alert if any.
    ///
    /// - Parameter isTakeoffRequested: `true` if takeoff has just been requested
    func publish(isTakeoffRequested: Bool = false) {
        // Update alerts are shown once on drone connection, and on each takeoff request.
        // Other takeoff alerts are only shown on takeoff request.
        let takeoffAlert = !isDroneConnected || isDroneFlying
        ? nil
        : takeoffAlerts
            .sorted()
            .first(where: { isTakeoffRequested || ($0.isUpdateRequired && !isUpdateAlertDismissed) })

        alertSubject.value = takeoffAlert ?? otherAlerts.sorted().first

        if let alert = alertSubject.value {
            ULog.d(.tag, "publish alert: \(alert)")
        }
    }
}

// MARK: CriticalAlertService protocol conformance
extension CriticalAlertServiceImpl: CriticalAlertService {

    var canTakeOff: Bool { return takeoffAlerts.isEmpty }

    var alert: HUDCriticalAlertType? { return alertSubject.value }

    var alertPublisher: AnyPublisher<HUDCriticalAlertType?, Never> { alertSubject.eraseToAnyPublisher() }

    func dismissCurrentAlert() {
        guard let alert = alert else { return }

        // Takeoff alerts are not removed, they will be shown again on takeoff request.
        // Other alerts are always removed.
        if alert.isUpdateRequired {
            isUpdateAlertDismissed = true
        } else {
            otherAlerts.remove(alert)
        }

        alertSubject.value = nil
    }

    func updateTakeoffAlert(_ alert: HUDCriticalAlertType, show: Bool) {
        takeoffAlerts.update(alert, shouldAdd: show)
    }
}
