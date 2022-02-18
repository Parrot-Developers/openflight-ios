//    Copyright (C) 2021 Parrot Drones SAS
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

import CoreLocation
import Combine
import GroundSdk

private extension ULogTag {
    static let tag = ULogTag(name: "TouchAndFlyService")
}

public enum TouchAndFlyBlocker: Equatable {
    /// Drone is not connected
    case droneNotConnected

    /// Drone gps is not fixed or has a poor accuracy.
    case droneGpsInfoInaccurate

    /// Drone is not calibrated.
    case droneNotCalibrated

    /// Drone is outside of the geofence.
    case droneOutOfGeofence

    /// Drone is too close to the ground.
    case droneTooCloseToGround

    /// Drone is above max altitude.
    case droneAboveMaxAltitude

    /// Drone is not flying.
    case droneNotFlying
}

public enum TouchAndFlyRunningState: Equatable {
    case noTarget(droneConnected: Bool)
    case running
    case ready(paused: Bool)
    case blocked(TouchAndFlyBlocker)
}

public enum TouchAndFlyTarget {
    case none
    case wayPoint(location: CLLocationCoordinate2D, altitude: Double, speed: Double)
    case poi(location: CLLocationCoordinate2D, altitude: Double)
    var type: TouchAndFlyTargetType {
        switch self {
        case .none:
            return .none
        case .wayPoint:
            return .wayPoint
        case .poi:
            return .poi
        }
    }
}

enum TouchAndFlyTargetType: Equatable {
    case none
    case wayPoint
    case poi
}

public protocol TouchAndFlyService: AnyObject {

    var runningStatePublisher: AnyPublisher<TouchAndFlyRunningState, Never> { get }

    var wayPointPublisher: AnyPublisher<CLLocationCoordinate2D?, Never> { get }

    var poiPublisher: AnyPublisher<CLLocationCoordinate2D?, Never> { get }

    var wayPointSpeedPublisher: AnyPublisher<Double, Never> { get }

    var guidingProgressPublisher: AnyPublisher<Double?, Never> { get }

    var guidingTimePublisher: AnyPublisher<TimeInterval?, Never> { get }

    var altitudePublisher: AnyPublisher<Double?, Never> { get }

    var targetPublisher: AnyPublisher<TouchAndFlyTarget, Never> { get }

    var runningState: TouchAndFlyRunningState { get }

    var wayPoint: CLLocationCoordinate2D? { get }

    var poi: CLLocationCoordinate2D? { get }

    var wayPointSpeed: Double { get }

    var altitude: Double? { get }

    var target: TouchAndFlyTarget { get }

    func moveTarget(to location: CLLocationCoordinate2D)

    func setWayPoint(_ location: CLLocationCoordinate2D)

    func setPoi(_ location: CLLocationCoordinate2D)

    func setWayPoint(speed: Double)

    func set(altitude: Double)

    func clear()

    func start()

    func stop()

    func pause()
}

class TouchAndFlyServiceImpl {

    private enum Constants {
        static let defaultHorizontalSpeed = 5.0
        static let defaultVerticalSpeed = 2.0
        static let defaultYawRotationSpeed = 20.0
        static let defaultAltitude = 20.0
    }

    typealias PoiItfState = (blocker: TouchAndFlyBlocker?, inProgress: Bool)
    typealias GuidingItfState = (blocker: TouchAndFlyBlocker?, inProgress: Bool)

    private let locationsTracker: LocationsTracker

    private var cancellables = Set<AnyCancellable>()
    private var guidedPilotingItfRef: Ref<GuidedPilotingItf>?
    private var poiPilotingItfRef: Ref<PointOfInterestPilotingItf>?
    private var altimeterInstrumentRef: Ref<Altimeter>?
    private var flyingInstrumentRef: Ref<FlyingIndicators>?
    private let isPausedSubject = CurrentValueSubject<Bool, Never>(false)
    private let runningStateSubject = CurrentValueSubject<TouchAndFlyRunningState, Never>(.noTarget(droneConnected: false))
    private let wayPointSubject = CurrentValueSubject<CLLocationCoordinate2D?, Never>(nil)
    private let poiSubject = CurrentValueSubject<CLLocationCoordinate2D?, Never>(nil)
    private let wayPointSpeedSubject = CurrentValueSubject<Double, Never>(Constants.defaultHorizontalSpeed)
    private let altitudeSubject = CurrentValueSubject<Double?, Never>(nil)

    private let poiItfState = CurrentValueSubject<PoiItfState, Never>((blocker: nil, inProgress: false))
    private let guidingItfState = CurrentValueSubject<GuidingItfState, Never>((blocker: nil, inProgress: false))

    private var guidingStartCoordinates = CurrentValueSubject<CLLocationCoordinate2D?, Never>(nil)
    private var guidingStartDate = CurrentValueSubject<Date?, Never>(nil)
    private let executionTimer = Timer.publish(every: 1, on: .main, in: .default)
        .autoconnect()
        .eraseToAnyPublisher()

    init(connectedDroneHolder: ConnectedDroneHolder,
         locationsTracker: LocationsTracker,
         currentMissionManager: CurrentMissionManager) {
        self.locationsTracker = locationsTracker
        connectedDroneHolder.dronePublisher
            .sink { [unowned self] in listenDrone(drone: $0) }
            .store(in: &cancellables)
        bindState(connectedDroneHolder: connectedDroneHolder)
        runningStateSubject
            .sink {
                ULog.i(.tag, "State changed to: \($0)")
            }
            .store(in: &cancellables)
        targetPublisher
            .sink {
                ULog.i(.tag, "Target changed to: \($0)")
            }
            .store(in: &cancellables)
        currentMissionManager.modePublisher
            .sink { [unowned self] missionMode in
                if missionMode.key != MissionsConstants.classicMissionTouchAndFlyKey {
                    clear()
                }
            }
            .store(in: &cancellables)
    }
}

private extension TouchAndFlyServiceImpl {

    func listenDrone(drone: Drone?) {
        guard let drone = drone else {
            guidedPilotingItfRef = nil
            poiPilotingItfRef = nil
            altimeterInstrumentRef = nil
            flyingInstrumentRef = nil
            guidingItfState.value = (blocker: .droneNotConnected, inProgress: false)
            poiItfState.value = (blocker: .droneNotConnected, inProgress: false)
            return
        }
        listenAltimeter(drone: drone)
        listenFlyingIndicators(drone: drone)
        listenGuidedPilotingItf(drone: drone)
        listenPoiPilotingItf(drone: drone)
    }

    func listenAltimeter(drone: Drone) {
        altimeterInstrumentRef = drone.getInstrument(Instruments.altimeter) { _ in
            // Nothing to do, just stocking the reference
        }
    }

    func listenFlyingIndicators(drone: Drone) {
        flyingInstrumentRef = drone.getInstrument(Instruments.flyingIndicators) { _ in
            // Nothing to do, just stocking the reference
        }
    }

    func listenGuidedPilotingItf(drone: Drone) {
        guidedPilotingItfRef = drone.getPilotingItf(PilotingItfs.guided) { [unowned self] itf in
            guard let itf = itf else {

                guidingItfState.value = (blocker: .droneNotConnected, inProgress: false)
                return
            }
            if let info = itf.latestFinishedFlightInfo {
                ULog.i(.tag, "Fight did finish with success: \(info.wasSuccessful)")
            }

            var inProgress = false
            if let directive = itf.currentDirective as? LocationDirective {
                inProgress = true
                // Ensure we hold the right values for the current piloting
                poiSubject.value = nil
                wayPointSubject.value = CLLocationCoordinate2D(latitude: directive.latitude, longitude: directive.longitude)
                wayPointSpeedSubject.value = directive.speed?.horizontalSpeed ?? wayPointSpeed
                altitudeSubject.value = directive.altitude
            }

            let blocker = itf.unavailabilityReasons?.first.map(TouchAndFlyBlocker.from)

            guidingItfState.value = (blocker: blocker, inProgress: inProgress)
        }
    }

    /// Starts watcher for point of interest piloting interface.
    func listenPoiPilotingItf(drone: Drone) {
        poiPilotingItfRef = drone.getPilotingItf(PilotingItfs.pointOfInterest) { [unowned self] itf in
            guard let itf = itf else {
                poiItfState.value = (blocker: .droneNotConnected, inProgress: false)
                return
            }

            let inProgress = itf.state == .active && itf.currentPointOfInterest != nil
            let blocker = itf.availabilityIssues?.first.map(TouchAndFlyBlocker.from)

            poiItfState.value = (blocker: blocker, inProgress: inProgress)
        }
    }

    func target(wayPoint: CLLocationCoordinate2D?, poi: CLLocationCoordinate2D?, altitude: Double, wayPointSpeed: Double) -> TouchAndFlyTarget {
        if let wayPoint = wayPoint {
            return .wayPoint(location: wayPoint, altitude: altitude, speed: wayPointSpeed)
        }
        if let poi = poi {
            return .poi(location: poi, altitude: altitude)
        }
        return .none
    }

    func bindState(connectedDroneHolder: ConnectedDroneHolder) {
        targetPublisher
            .sink { [unowned self] _ in
            updateRunningState(connectedDroneHolder: connectedDroneHolder)
        }
        .store(in: &cancellables)

        isPausedSubject
            .removeDuplicates()
            .sink { [unowned self] _ in
            updateRunningState(connectedDroneHolder: connectedDroneHolder)
        }
        .store(in: &cancellables)

        guidingItfState
            .sink { [unowned self] _ in
            updateRunningState(connectedDroneHolder: connectedDroneHolder)
        }
        .store(in: &cancellables)

        poiItfState
            .sink { [unowned self] _ in
            updateRunningState(connectedDroneHolder: connectedDroneHolder)
        }
        .store(in: &cancellables)

        connectedDroneHolder.dronePublisher.map { $0 != nil }
            .removeDuplicates()
            .sink { [unowned self] _ in
            updateRunningState(connectedDroneHolder: connectedDroneHolder)
        }.store(in: &cancellables)
    }

    /// Update running state
    ///
    /// - Parameters:
    ///   - connectedDroneHolder: the connected drone's holder
    private func updateRunningState(connectedDroneHolder: ConnectedDroneHolder) {
        let oldRunningState = runningState
        let isDroneConnected = connectedDroneHolder.drone?.state.connectionState == .connected

        if guidingItfState.value.inProgress || poiItfState.value.inProgress {
            runningStateSubject.value = .running
        } else if poiSubject.value != nil {
            if let blocker = poiItfState.value.blocker {
                runningStateSubject.value = .blocked(blocker)
            } else {
                runningStateSubject.value = .ready(paused: isPausedSubject.value)
            }
        } else if wayPointSubject.value != nil {
            if let blocker = guidingItfState.value.blocker {
                runningStateSubject.value = .blocked(blocker)
            } else {
                runningStateSubject.value = .ready(paused: isPausedSubject.value)
            }
        } else {
            runningStateSubject.value = .noTarget(droneConnected: isDroneConnected)
        }
        if oldRunningState == .running {
            switch runningStateSubject.value {
            case .noTarget, .blocked:
                clear()
            case .running:
                break
            case .ready(paused: let paused):
                if !paused {
                    clear()
                }
            }
        }
    }

    func executeTarget() {

        ULog.i(.tag, "Executing target \(target)")
        // We may be here after a change of target, thus we have to deactivate the unused itf
        switch target {
        case .none:
            return

        case .wayPoint(let location, let altitude, let speed):
            guidingStartCoordinates.value = locationsTracker.droneLocation.coordinates?.coordinate
            guidingStartDate.value = Date()
            _ = poiPilotingItfRef?.value?.deactivate()
            let speedObject = GuidedPilotingSpeed(horizontalSpeed: speed,
                                                  verticalSpeed: Constants.defaultVerticalSpeed,
                                                  yawRotationSpeed: Constants.defaultYawRotationSpeed)
            let locationDirective = LocationDirective(latitude: location.latitude,
                                                      longitude: location.longitude,
                                                      altitude: altitude,
                                                      orientation: .toTarget,
                                                      speed: speedObject)
            guidedPilotingItfRef?.value?.move(directive: locationDirective)

        case .poi(let location, let altitude):
            _ = guidedPilotingItfRef?.value?.deactivate()
            poiPilotingItfRef?.value?.start(latitude: location.latitude, longitude: location.longitude, altitude: altitude, mode: .lockedGimbal)
        }
    }

    func distance(_ point1: CLLocationCoordinate2D, _ point2: CLLocationCoordinate2D) -> Double {
        let loc1 = CLLocation(latitude: point1.latitude, longitude: point1.longitude)
        let loc2 = CLLocation(latitude: point2.latitude, longitude: point2.longitude)
        return loc1.distance(from: loc2)
    }
}

extension TouchAndFlyServiceImpl: TouchAndFlyService {

    var runningStatePublisher: AnyPublisher<TouchAndFlyRunningState, Never> {
        runningStateSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var wayPointPublisher: AnyPublisher<CLLocationCoordinate2D?, Never> { wayPointSubject.eraseToAnyPublisher() }

    var poiPublisher: AnyPublisher<CLLocationCoordinate2D?, Never> { poiSubject.eraseToAnyPublisher() }

    var wayPointSpeedPublisher: AnyPublisher<Double, Never> { wayPointSpeedSubject.eraseToAnyPublisher() }

    var guidingProgressPublisher: AnyPublisher<Double?, Never> {
        locationsTracker.droneLocationPublisher
            .combineLatest(runningStateSubject, targetPublisher, guidingStartCoordinates)
            .map { [unowned self] (droneLocation, runningState, target, startCoordinates) -> Double? in
                guard let startCoordinates = startCoordinates,
                      let droneCoordinates = droneLocation.coordinates?.coordinate,
                      case .running = runningState,
                      case .wayPoint(let targetLocation, _, _) = target else { return nil }
                let totalDistance = distance(targetLocation, startCoordinates)
                if totalDistance == 0 {
                    return 0
                }
                let remainingDistance = distance(droneCoordinates, targetLocation)
                return max(0, min(1, 1 - remainingDistance / totalDistance))
            }
            .eraseToAnyPublisher()
    }

    var guidingTimePublisher: AnyPublisher<TimeInterval?, Never> {
        guidingStartDate
            .combineLatest(executionTimer)
            .map { (startDate, currentDate) in
                guard let startDate = startDate else { return nil }
                return currentDate.timeIntervalSince(startDate)
            }
            .eraseToAnyPublisher()
    }

    var altitudePublisher: AnyPublisher<Double?, Never> { altitudeSubject.eraseToAnyPublisher() }

    var targetPublisher: AnyPublisher<TouchAndFlyTarget, Never> {
        wayPointSubject
            .removeDuplicates()
            .combineLatest(poiSubject, altitudeSubject, wayPointSpeedSubject)
            .map { [unowned self] (wayPoint, poi, altitude, speed) in
                return target(wayPoint: wayPoint, poi: poi, altitude: calculateAltitude(),
                       wayPointSpeed: speed)
            }
            .eraseToAnyPublisher()
    }

    var runningState: TouchAndFlyRunningState { runningStateSubject.value }

    var wayPoint: CLLocationCoordinate2D? { wayPointSubject.value }

    var poi: CLLocationCoordinate2D? { poiSubject.value }

    var wayPointSpeed: Double { wayPointSpeedSubject.value }

    var altitude: Double? { altitudeSubject.value }

    var target: TouchAndFlyTarget {
        return target(wayPoint: wayPoint, poi: poi, altitude: calculateAltitude(), wayPointSpeed: wayPointSpeed)
    }

    private func calculateAltitude() -> Double {
        if flyingInstrumentRef?.value?.flyingState == .flying
            || flyingInstrumentRef?.value?.flyingState == .waiting {
            let altitudeDrone = altimeterInstrumentRef?.value?.groundRelativeAltitude ?? Constants.defaultAltitude
            return altitude ?? round(altitudeDrone)
        }
        return  altitude ?? Constants.defaultAltitude
    }

    func moveTarget(to location: CLLocationCoordinate2D) {
        switch target {
        case .none:
            break
        case .poi:
            setPoi(location)
        case .wayPoint:
            setWayPoint(location)
        }
    }

    func setWayPoint(_ location: CLLocationCoordinate2D) {
        let wasRunning = runningState == .running
        poiSubject.value = nil
        wayPointSubject.value = location
        if wasRunning {
            executeTarget()
        }
    }

    func setPoi(_ location: CLLocationCoordinate2D) {
        let wasRunning = runningState == .running
        wayPointSubject.value = nil
        poiSubject.value = location
        if wasRunning {
            executeTarget()
        }
    }

    func setWayPoint(speed: Double) {
        wayPointSpeedSubject.value = speed
        let isRunning = runningState == .running
        if isRunning {
            start()
        }

    }

    func set(altitude: Double) {
        altitudeSubject.value = altitude
        let isRunning = runningState == .running
        if isRunning {
            start()
        }
    }

    func clear() {
        ULog.i(.tag, "COMMAND Clear")
        isPausedSubject.value = false
        switch runningState {
        case .noTarget:
            guidingStartDate.value = nil
            guidingStartCoordinates.value = nil
            return
        case .running:
            // Don't clear until it's finished
            return
        case .ready, .blocked:
            guidingStartDate.value = nil
            guidingStartCoordinates.value = nil
            wayPointSubject.value = nil
            poiSubject.value = nil
        }
    }

    func start() {
        ULog.i(.tag, "COMMAND Start")
        isPausedSubject.value = false
        executeTarget()
    }

    func stop() {
        ULog.i(.tag, "COMMAND Stop")
        isPausedSubject.value = false
        _ = poiPilotingItfRef?.value?.deactivate()
        _ = guidedPilotingItfRef?.value?.deactivate()
    }

    func pause() {
        ULog.i(.tag, "COMMAND Pause")
        switch runningState {
        case .running:
            isPausedSubject.value = true
            _ = guidedPilotingItfRef?.value?.deactivate()
            _ = poiPilotingItfRef?.value?.deactivate()
        default:
            return
        }
    }

}

private extension TouchAndFlyBlocker {
    static func from(_ issue: GuidedIssue) -> TouchAndFlyBlocker {
        switch issue {
        case .droneNotFlying:
            return .droneNotFlying
        case .droneNotCalibrated:
            return .droneNotCalibrated
        case .droneGpsInfoInaccurate:
            return .droneGpsInfoInaccurate
        case .droneOutOfGeofence:
            return .droneOutOfGeofence
        case .droneTooCloseToGround:
            return .droneTooCloseToGround
        case .droneAboveMaxAltitude:
            return .droneAboveMaxAltitude
        }
    }

    static func from(_ issue: POIIssue) -> TouchAndFlyBlocker {
        switch issue {
        case .droneNotFlying:
            return .droneNotFlying
        case .droneNotCalibrated:
            return .droneNotCalibrated
        case .droneGpsInfoInaccurate:
            return .droneGpsInfoInaccurate
        case .droneOutOfGeofence:
            return .droneOutOfGeofence
        case .droneTooCloseToGround:
            return .droneTooCloseToGround
        case .droneAboveMaxAltitude:
            return .droneAboveMaxAltitude
        }
    }
}
