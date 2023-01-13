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
import SdkCore

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

    /// Drone is taking off.
    case droneTakingOff
}

public enum TouchAndFlyRunningState: Equatable {
    case noTarget(droneConnected: Bool)
    case running
    case ready
    case blocked(TouchAndFlyBlocker)
}

public enum TouchAndFlyTarget: Equatable {
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

    public static func == (lhs: TouchAndFlyTarget, rhs: TouchAndFlyTarget) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.wayPoint(let locationLhs, let altitudeLhs, let speedLhs), .wayPoint(let locationRhs, let altitudeRhs, let speedRhs)):
            return locationLhs == locationRhs && altitudeLhs == altitudeRhs
                && speedLhs == speedRhs
        case (.poi(let locationLhs, let altitudeLhs), .poi(let locationRhs, let altitudeRhs)):
            return locationLhs == locationRhs && altitudeLhs == altitudeRhs
        default:
            return false
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
    var streamElementPublisher: AnyPublisher<StreamElement, Never> { get }

    var runningState: TouchAndFlyRunningState { get }
    var wayPoint: CLLocationCoordinate2D? { get }
    var poi: CLLocationCoordinate2D? { get }
    var wayPointSpeed: Double { get }
    var altitude: Double? { get }
    var targetAltitude: Double { get }
    var target: TouchAndFlyTarget { get }
    func setWayPoint(_ location: CLLocationCoordinate2D, altitude: Double?)
    func moveWayPoint(to location: CLLocationCoordinate2D, altitude: Double?)
    func setPoi(_ location: CLLocationCoordinate2D, altitude: Double?)
    func movePoi(to location: CLLocationCoordinate2D, altitude: Double?)
    func setWayPoint(speed: Double)
    func set(altitude: Double)
    func clear()
    func start()
    func stop()
    func setPoiLocation(point: CGPoint) -> CLLocation?
    func setWaypointLocation(point: CGPoint) -> CLLocation?

    func frameUpdate(mediaInfoHandle: UnsafeRawPointer?, metadataHandle: UnsafeRawPointer?)

}

class TouchAndFlyServiceImpl {

    private enum Constants {
        static let defaultHorizontalSpeed = 5.0
        static let defaultVerticalSpeed = 2.0
        static let defaultYawRotationSpeed = 20.0
        static let defaultWayPointAltitude = 20.0
        static let defaultPoiAltitude = 0.0
        static let defaultNewPointDistance: Float = 100.0
    }

    typealias PoiItfState = (blocker: TouchAndFlyBlocker?, inProgress: Bool)
    typealias GuidingItfState = (blocker: TouchAndFlyBlocker?, inProgress: Bool)

    private let locationsTracker: LocationsTracker
    private let bamService: BannerAlertManagerService

    private var cancellables = Set<AnyCancellable>()
    private var guidedPilotingItfRef: Ref<GuidedPilotingItf>?
    private var poiPilotingItfRef: Ref<PointOfInterestPilotingItf>?
    private var rthPilotingItfRef: Ref<ReturnHomePilotingItf>?
    private var altimeterInstrumentRef: Ref<Altimeter>?
    private var flyingInstrumentRef: Ref<FlyingIndicators>?
    private var streamServerRef: Ref<StreamServer>?
    private var cameraLiveRef: Ref<CameraLive>?
    private var userLocationRef: Ref<UserLocation>?
    private var mainCameraRef: Ref<MainCamera2>?

    private var frameCount: Int = 0
    private let runningStateSubject = CurrentValueSubject<TouchAndFlyRunningState, Never>(.noTarget(droneConnected: false))
    private let wayPointSubject = CurrentValueSubject<CLLocationCoordinate2D?, Never>(nil)
    private let poiSubject = CurrentValueSubject<CLLocationCoordinate2D?, Never>(nil)
    private let wayPointSpeedSubject = CurrentValueSubject<Double, Never>(Constants.defaultHorizontalSpeed)
    private let altitudeSubject = CurrentValueSubject<Double?, Never>(nil)
    private let streamElementSubject = CurrentValueSubject<StreamElement, Never>(.none)
    private let poiItfState = CurrentValueSubject<PoiItfState, Never>((blocker: nil, inProgress: false))
    private let guidingItfState = CurrentValueSubject<GuidingItfState, Never>((blocker: nil, inProgress: false))

    private var guidingStartCoordinates = CurrentValueSubject<CLLocationCoordinate2D?, Never>(nil)
    private var guidingStartDate = CurrentValueSubject<Date?, Never>(nil)
    private let executionTimer = Timer.publish(every: 1, on: .main, in: .default)
        .autoconnect()
        .eraseToAnyPublisher()

    private var latestFlyingState: FlyingIndicatorsFlyingState?
    private var latestBlocker: TouchAndFlyBlocker?
    private var startWpOfPoiAfterTakeOff: Bool = false

    /// Whether drone is in flying (or waiting) state.
    private var isDroneFlyingOrWaiting: Bool?

    private let lic = SdkCoreLic()

    init(connectedDroneHolder: ConnectedDroneHolder,
         locationsTracker: LocationsTracker,
         currentMissionManager: CurrentMissionManager,
         bamService: BannerAlertManagerService) {
        self.locationsTracker = locationsTracker
        self.bamService = bamService
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

    func frameUpdate(mediaInfoHandle: UnsafeRawPointer?, metadataHandle: UnsafeRawPointer?) {
        lic.update(mediaInfo: mediaInfoHandle, metadata: metadataHandle)

        if (frameCount % 100) == 0 {
            ULog.i(.tag, "Frame ready count \(frameCount)")
        }
        frameCount = frameCount > Int.max - 1 ? 0 : frameCount + 1

        switch target {
        case .none:
            streamElementSubject.value = .none
        case .poi(let location, let altitude):
            let takeOffAltitudeDrone = altimeterInstrumentRef?.value?.takeoffRelativeAltitude ?? 0
            let absoluteAltitudeDrone = altimeterInstrumentRef?.value?.absoluteAltitude ?? 0
            let newAltitude = altitude + (absoluteAltitudeDrone - takeOffAltitudeDrone)
            let newLocation = CLLocation(coordinate: location,
                                       altitude: newAltitude,
                                       horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: Date())
            do {
                let location = try lic.position(from: newLocation)
                streamElementSubject.value = .poi(point: CGPoint(x: location.x, y: location.y), altitude: altitude, distance: location.distance)
                if (frameCount % 30) == 0 {
                    ULog.d(.tag, "frameReady poi \(newLocation.coordinate),alt:\(newLocation.altitude) -> \(location)")
                }
            } catch {
                // could not compute position
                streamElementSubject.value = .poi(point: .zero, altitude: altitude, distance: .zero)
            }

        case .wayPoint(let location, let altitude, _):
            let takeOffAltitudeDrone = altimeterInstrumentRef?.value?.takeoffRelativeAltitude ?? 0
            let absoluteAltitudeDrone = altimeterInstrumentRef?.value?.absoluteAltitude ?? 0
            let newAltitude = altitude + (absoluteAltitudeDrone - takeOffAltitudeDrone)
            let newLocation = CLLocation(coordinate: location,
                                       altitude: newAltitude,
                                       horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: Date())

            do {
                let location = try lic.position(from: newLocation)
                streamElementSubject.value = .waypoint(point: CGPoint(x: location.x, y: location.y), altitude: altitude, distance: location.distance)
                if (frameCount % 30) == 0 {
                    ULog.d(.tag, "frameReady waypoint \(newLocation.coordinate),alt:\(newLocation.altitude) -> \(location)")
                }
            } catch {
                // could not compute position
                streamElementSubject.value = .waypoint(point: .zero, altitude: altitude, distance: .zero)
            }
        }
    }
}

private extension TouchAndFlyServiceImpl {

    func listenDrone(drone: Drone?) {
        guard let drone = drone else {
            guidedPilotingItfRef = nil
            poiPilotingItfRef = nil
            altimeterInstrumentRef = nil
            flyingInstrumentRef = nil
            rthPilotingItfRef = nil
            mainCameraRef = nil
            guidingItfState.value = (blocker: .droneNotConnected, inProgress: false)
            poiItfState.value = (blocker: .droneNotConnected, inProgress: false)
            streamElementSubject.value = .none
            clear()
            return
        }
        listenAltimeter(drone: drone)
        listenFlyingIndicators(drone: drone)
        listenGuidedPilotingItf(drone: drone)
        listenPoiPilotingItf(drone: drone)
        listenRth(drone: drone)
        listenStreamServer(drone: drone)
        listenUser()
        listenCamera(drone: drone)
    }

    func listenUser() {
        let groundSdk = GroundSdk()
        userLocationRef = groundSdk.getFacility(Facilities.userLocation) { _ in
            // nothing to do
        }
    }

    func listenCamera(drone: Drone) {
        mainCameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [weak self] mainCamera2 in
            guard let self = self else { return }
            guard mainCamera2 != nil else {
                self.streamElementSubject.value = .none
                return
            }
        }
    }

    /// Starts watcher for stream server state.
    func listenStreamServer(drone: Drone) {
        streamServerRef = drone.getPeripheral(Peripherals.streamServer) { [weak self] streamServer in
            guard let self = self else { return }
            guard let streamServer = streamServer,
                  streamServer.enabled else {
                      // avoid issues when dismissing App and returning on it
                      self.cameraLiveRef = nil
                      return
                  }
        }
    }

    func listenAltimeter(drone: Drone) {
        altimeterInstrumentRef = drone.getInstrument(Instruments.altimeter) { _ in
            // Nothing to do, just stocking the reference
        }
    }

    func listenFlyingIndicators(drone: Drone) {
        flyingInstrumentRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] itf in
            guard let self = self, let itf = itf else { return }

            if itf.flyingState == .landing {
                // Clear target info if drone is landing.
                self.clear()
            }

            if itf.flyingState == .none {
                // When landed, update the current guideditf state (could be disabled during landing).
                self.guidingItfState.value = (blocker:self.latestBlocker, inProgress: false)
            }

            self.isDroneFlyingOrWaiting = itf.flyingState.isFlyingOrWaiting

            if self.isDroneFlyingOrWaiting == true, self.latestFlyingState == .takingOff {
                self.startWpOfPoiAfterTakeOff = true
            } else {
                self.startWpOfPoiAfterTakeOff = false
            }
            self.latestFlyingState = itf.flyingState
        }
    }

    func listenGuidedPilotingItf(drone: Drone) {
        guidedPilotingItfRef = drone.getPilotingItf(PilotingItfs.guided) { [unowned self] itf in
            guard let itf = itf else {
                guidingItfState.value = (blocker: .droneNotConnected, inProgress: false)
                return
            }

            let blocker = itf.unavailabilityReasons?.first.map(TouchAndFlyBlocker.from)
            self.latestBlocker = blocker

            if blocker == .droneNotFlying && latestFlyingState == .landing {
                // When landing, the blocker droneNotFlying is enabled, but we ignore it to keep the running state ready.
                guidingItfState.value = (blocker: nil, inProgress: false)
                return
            }
            guard itf.state != .unavailable else {
                guidingItfState.value = (blocker: blocker, inProgress: false)
                return
            }

            if let info = itf.latestFinishedFlightInfo, isDroneFlyingOrWaiting == true, !startWpOfPoiAfterTakeOff {
                // `latestFinishedFlightInfo` remains available even after landing. This can lead
                // a new WP set before takeOff to be erased at takeOff because it would be
                // mistaken with a reached target point.
                // => Ensure drone is actually flying before removing active WP.
                ULog.i(.tag, "Flight did finish with success: \(info.wasSuccessful)")
                wayPointSubject.value = nil
            }

            var inProgress = false
            if let directive = itf.currentDirective as? LocationDirective {
                inProgress = true
                let newLocation = CLLocationCoordinate2D(latitude: directive.latitude, longitude: directive.longitude)
                if wayPointSubject.value != newLocation {
                    ULog.i(.tag, "listenGuidedPilotingItf: new waypoint location: \(newLocation)")
                }
                // Ensure we hold the right values for the current piloting
                wayPointSubject.value = newLocation
                guidingStartCoordinates.value = locationsTracker.droneLocation.coordinates?.coordinate
                wayPointSpeedSubject.value = directive.speed?.horizontalSpeed ?? wayPointSpeed
                altitudeSubject.value = directive.altitude
            }

            guidingItfState.value = (blocker: blocker, inProgress: inProgress)
        }
    }

    /// Starts watcher for point of interest piloting interface.
    func listenPoiPilotingItf(drone: Drone) {
        poiPilotingItfRef = drone.getPilotingItf(PilotingItfs.pointOfInterest) { [unowned self] itf in
            if case .wayPoint = target {
                // Currently watching a WP => reset `poiItfState` in order to ensure it's not
                // in running state (can occur if POI tracking has not been stopped by user before
                // new WP creation).
                poiItfState.value = (blocker: nil, inProgress: false)
                startWatchingWpOrPoiAfterTakeOff()
                return
            } else if case .poi = target {
                startWatchingWpOrPoiAfterTakeOff()
            }

            guard let itf = itf else {
                poiItfState.value = (blocker: .droneNotConnected, inProgress: false)
                return
            }

            let inProgress = itf.state == .active && itf.currentPointOfInterest != nil
            let blocker = itf.availabilityIssues?.first.map(TouchAndFlyBlocker.from)
            poiItfState.value = (blocker: blocker, inProgress: inProgress)

            if let poi = itf.currentPointOfInterest {
                poiSubject.value = CLLocationCoordinate2D(latitude: poi.latitude, longitude: poi.longitude)
                altitudeSubject.value = poi.altitude
            }
        }
    }

    // Start looking at a waypoint or poi just after taking off.
    private func startWatchingWpOrPoiAfterTakeOff() {
        guard let rth = self.rthPilotingItfRef?.value, let poiItf = poiPilotingItfRef?.value else { return }

        if startWpOfPoiAfterTakeOff, rth.state != .active, poiItf.state == .idle {
            startWpOfPoiAfterTakeOff = false
            if self.poiSubject.value != nil {
                self.start()
            } else if self.wayPointSubject.value != nil {
                self.startWayPoint()
            }
        }
    }

    func listenRth(drone: Drone) {
        rthPilotingItfRef = drone.getPilotingItf(PilotingItfs.returnHome) { [weak self] itf in
            guard let itf = itf, let self = self else { return }

            if itf.state == .active {
                self.clear()
            }

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
        let isDroneConnected = connectedDroneHolder.drone?.state.connectionState == .connected

        if guidingItfState.value.inProgress || poiItfState.value.inProgress {
            runningStateSubject.value = .running
        } else if poiSubject.value != nil {
            if let blocker = poiItfState.value.blocker {
                runningStateSubject.value = .blocked(blocker)
            } else {
                runningStateSubject.value = .ready
            }
        } else if wayPointSubject.value != nil {
            if let blocker = guidingItfState.value.blocker {
                runningStateSubject.value = .blocked(blocker)
            } else {
                runningStateSubject.value = .ready
            }
        } else {
            runningStateSubject.value = .noTarget(droneConnected: isDroneConnected)
        }
    }

    func watchWayPoint() {
        switch target {
        case .wayPoint(let location, _, _):
            _ = guidedPilotingItfRef?.value?.deactivate()
            poiPilotingItfRef?.value?.start(latitude: location.latitude,
                                            longitude: location.longitude,
                                            altitude: targetAltitude,
                                            mode: .freeGimbal)
        default:
            break
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
}

extension TouchAndFlyServiceImpl: TouchAndFlyService {

    var streamElementPublisher: AnyPublisher<StreamElement, Never> { streamElementSubject.eraseToAnyPublisher() }

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
            .removeDuplicates()
            .combineLatest(runningStateSubject, targetPublisher, guidingStartCoordinates)
            .map { (droneLocation, runningState, target, startCoordinates) -> Double? in
                guard let startCoordinates = startCoordinates,
                      let droneCoordinates = droneLocation.coordinates?.coordinate,
                      case .running = runningState,
                      case .wayPoint(let targetLocation, _, _) = target else { return nil }
                let totalDistance = targetLocation.distance(from: startCoordinates)
                if totalDistance == 0 {
                    return 0
                }
                let remainingDistance = targetLocation.distance(from: droneCoordinates)
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
            .combineLatest(poiSubject, altitudeSubject, wayPointSpeedSubject)
            .map { [unowned self] _ in target }
            .eraseToAnyPublisher()
    }

    var runningState: TouchAndFlyRunningState { runningStateSubject.value }

    var wayPoint: CLLocationCoordinate2D? { wayPointSubject.value }

    var poi: CLLocationCoordinate2D? { poiSubject.value }

    var wayPointSpeed: Double { wayPointSpeedSubject.value }

    var altitude: Double? { altitudeSubject.value }

    /// The active target defined by current WP (location, dynamic altitude and speed) or POI parameters.
    var target: TouchAndFlyTarget {
        target(wayPoint: wayPoint,
               poi: poi,
               altitude: targetAltitude,
               wayPointSpeed: wayPointSpeed)
    }

    /// The current drone altitude if available (default WP altitude otherwise).
    private var droneAltitude: Double {
        round(altimeterInstrumentRef?.value?.takeoffRelativeAltitude ?? Constants.defaultWayPointAltitude)
    }

    /// The waypoint target altitude for flying state.
    /// User defined settings takes precedence if defined (after a user interaction).
    /// Current drone's altitude (if available) will be returned otherwise, as `altitude` value is reset
    /// to `nil` as soon as a WP is set on map.
    var targetAltitude: Double {
        altitude ?? droneAltitude
    }

    /// Sets WP location to new value and starts WP.
    ///
    /// - Parameters:
    ///    - location: the location
    ///    - altitude: the altitude
    func moveWayPoint(to location: CLLocationCoordinate2D, altitude: Double? = nil) {
        ULog.d(.tag, "move waypoint to location:\(location) altitude:\(String(describing: altitude))")
        poiSubject.value = nil
        wayPointSubject.value = location
        if let altitude = altitude {
            altitudeSubject.value = altitude
        }
        startWayPoint()
    }

    /// Sets WP location to new value and update altitude.
    ///
    /// - Parameters:
    ///    - location: the location
    ///    - altitude: the altitude
    func setWayPoint(_ location: CLLocationCoordinate2D, altitude: Double? = nil) {
        if isDroneFlyingOrWaiting == true {
            // Altitude needs to be dynamically updated in order to match drone's value when flying.
            // => Reset `altitudeSubject` value to `nil` in order to get live update.
            altitudeSubject.value = nil
        } else {
            // Drone is landed => use default WP altitude value.
            altitudeSubject.value = Constants.defaultWayPointAltitude
        }
        moveWayPoint(to: location, altitude: altitude)
    }

    /// Starts watching or following waypoint.
    private func startWayPoint() {
        let isIdle = runningState != .running
        let isPoiInProgress = poiItfState.value.inProgress

        if isIdle || isPoiInProgress {
            // Watch WP at `start` if state is idle, or if POI interface is still
            // in progress (we do not want to directly fly to WP if it's created
            // while POI tracking is still active).
            watchWayPoint()
        } else {
            executeTarget()
        }
    }

    /// Sets POI location to new value and execute target.
    ///
    /// - Parameters:
    ///    - location: the POI location
    ///    - altitude: the altitude
    func movePoi(to location: CLLocationCoordinate2D, altitude: Double?) {
        wayPointSubject.value = nil
        poiSubject.value = location
        if let altitude = altitude {
            altitudeSubject.value = altitude
        }
        executeTarget()
    }

    /// Sets POI location to new value and update altitude.
    ///
    /// - Parameters:
    ///    - location: the POI location
    ///    - altitude: the altitude
    func setPoi(_ location: CLLocationCoordinate2D, altitude: Double?) {
        // Unconditionally use default altitude when setting a POI.
        // Value can be modified by user via setting ruler.
        if let altitude = altitude {
            altitudeSubject.value = altitude
        } else {
            altitudeSubject.value = Constants.defaultPoiAltitude
        }
        movePoi(to: location, altitude: altitudeSubject.value)
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
        switch runningState {
        case .running:
            // WP or POI running => executeTarget.
            start()
        case .ready:
            // State is ready => watch WP in order to point to new altitude.
            // (`watchWayPoint()` has no effect if target is not a WP.)
            watchWayPoint()
        default:
            break
        }
    }

    func clear() {
        wayPointSubject.value = nil
        altitudeSubject.value = nil
        poiSubject.value = nil
        streamElementSubject.value = .none
        guidingStartDate.value = nil
        guidingStartCoordinates.value = nil
    }

    func start() {
        ULog.i(.tag, "COMMAND Start")
        executeTarget()
    }

    func stop() {
        ULog.i(.tag, "COMMAND Stop")
        clear()
        guard poiPilotingItfRef?.value?.currentPointOfInterest != nil ||
              guidedPilotingItfRef?.value?.currentDirective != nil else { return }
        _ = poiPilotingItfRef?.value?.deactivate()
        _ = guidedPilotingItfRef?.value?.deactivate()
    }

    func setPoiLocation(point: CGPoint) -> CLLocation? {
        let takeoffRelativeAltitude = altimeterInstrumentRef?.value?.takeoffRelativeAltitude ?? 0
        let absoluteAltitudeDrone = altimeterInstrumentRef?.value?.absoluteAltitude ?? 0
        // Takeoff altitude above sea (in meters)
        let takeOffAltitude = absoluteAltitudeDrone - takeoffRelativeAltitude
        let locationAltitude = (altitudeSubject.value ?? 0) + takeOffAltitude

        do {
            bamService.hide(AdviceBannerAlert.unableToComputePoi)
            let newLocation = try lic.location(fromPosition: point, forAltitude: Float(locationAltitude))
            let finalLocation = CLLocation(coordinate: newLocation.coordinate,
                                           altitude: newLocation.altitude - takeOffAltitude,
                                           horizontalAccuracy: newLocation.horizontalAccuracy,
                                           verticalAccuracy: newLocation.verticalAccuracy,
                                           timestamp: newLocation.timestamp)
            return finalLocation
        } catch let error as SdkCoreLicError {
            ULog.d(.tag, "*** Could not compute a new poi location. point:\(point), poi:\(String(describing: poiSubject.value)), error:\(error.code)")
            if error.code == .outOfRange {
                bamService.show(AdviceBannerAlert.unableToComputePoi)
            }
            streamElementSubject.value = .none
            return nil
        } catch {
            // not a SDKCoreLicError
            ULog.e(.tag, "Unhandled error : \(error)")
            streamElementSubject.value = .none
            return nil
        }
    }

    func setWaypointLocation(point: CGPoint) -> CLLocation? {
        let takeoffRelativeAltitude = altimeterInstrumentRef?.value?.takeoffRelativeAltitude ?? 0
        let absoluteAltitudeDrone = altimeterInstrumentRef?.value?.absoluteAltitude ?? 0
        // Takeoff altitude above sea (in meters)
        let takeOffAltitude = absoluteAltitudeDrone - takeoffRelativeAltitude
        let locationAltitude = (altitudeSubject.value ?? 0) + takeOffAltitude

        var newLocation: CLLocation
        do {
            if let location = wayPointSubject.value {
                let location2D = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                let location3D = CLLocation(coordinate: location2D,
                                            altitude: locationAltitude, horizontalAccuracy: 0,
                                            verticalAccuracy: 0, timestamp: Date())
                newLocation = try lic.location(fromPosition: point, for: location3D)
            } else {
                newLocation = try lic.location(fromPosition: point, forDistance: Constants.defaultNewPointDistance)
            }
            let finalLocation = CLLocation(coordinate: newLocation.coordinate,
                                           altitude: newLocation.altitude - takeOffAltitude,
                                           horizontalAccuracy: newLocation.horizontalAccuracy,
                                           verticalAccuracy: newLocation.verticalAccuracy,
                                           timestamp: newLocation.timestamp)
            return finalLocation
        } catch {
            ULog.d(.tag, "Could not compute a new waypoint location. point:\(point), waypoint:\(String(describing: wayPointSubject.value))")
            streamElementSubject.value = .none
            return nil
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
