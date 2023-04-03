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

import Foundation
import Combine
import CoreLocation
import SwiftyUserDefaults
import GroundSdk
import ArcGIS

/// Service monitoring user device and drone location
public protocol LocationsTracker: AnyObject {

    /// User location publisher
    var userLocationPublisher: AnyPublisher<OrientedLocation, Never> { get }
    /// Drone 2D location publisher
    func drone2DLocationPublisher(animated: Bool) -> AnyPublisher<CLLocationCoordinate2D, Never>
    /// Drone 2D oriented location publisher
    func drone2DOrientedLocationPublisher(animated: Bool) -> AnyPublisher<OrientedLocation, Never>
    /// Drone 3D location
    func drone3DLocation(absoluteAltitude: Bool) -> OrientedLocation
    /// Drone 3D location publisher
    func drone3DLocationPublisher(animated: Bool, absoluteAltitude: Bool) -> AnyPublisher<OrientedLocation, Never>
    /// Drone Altitude
    func droneAltitudePublisher(absoluteAltitude: Bool) -> AnyPublisher<Double, Never>
    /// Return home location publisher
    var returnHomeLocationPublisher: AnyPublisher<CLLocationCoordinate2D?, Never> { get }
    /// Drone gps fixed publisher
    var droneGpsFixedPublisher: AnyPublisher<Bool, Never> { get }
    /// User location
    var userLocation: OrientedLocation { get }
    /// Drone location
    var droneLocation: CLLocationCoordinate2D? { get }
    /// Drone absolute altitude
    var droneAbsoluteAltitude: Double? { get }
    /// Drone heading
    var droneHeading: Double? { get }
    /// Indicates if the last know gps position is fixed
    var isDroneGpsFixed: Bool { get }
    /// Return home location
    var returnHomeLocation: CLLocationCoordinate2D? { get }
}

/// Private UserDefaults keys
private extension DefaultsKeys {
    var lastDroneLocation: DefaultsKey<Data?> { DefaultsKeys.lastDroneLocationKey }
    var lastDroneAbsoluteAltitude: DefaultsKey<Double?> { DefaultsKeys.lastDroneAbsoluteAltitudeKey }
    var lastDroneHeading: DefaultsKey<Double?> { DefaultsKeys.lastDroneHeadingKey }

    static let lastDroneLocationKey: DefaultsKey<Data?> = DefaultsKey<Data?>("key_lastDroneLocation")
    static let lastDroneAbsoluteAltitudeKey: DefaultsKey<Double?> = DefaultsKey<Double?>("key_lastDroneAbsoluteAltitude")
    static let lastDroneHeadingKey: DefaultsKey<Double?> = DefaultsKey<Double?>("key_lastDroneHeading")
}

/// Implementation for `LocationsTracker`
class LocationsTrackerImpl {

    /// Constants
    private enum Constants {
        static let headingOrientationCorrection: Double = 90.0
        static let animationMaxSteps: Int = 8
        static let animationInterval: Double = 0.2
        static let animationMinStep: Double = 0.3
        static let animationMaxDistance: Double = 50
    }

    // MARK: Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var gpsRef: Ref<Gps>?
    private var altimeterRef: Ref<Altimeter>?
    private var droneGimbalRef: Ref<Gimbal>?
    private var userLocationRef: Ref<UserLocation>?
    private var userHeadingRef: Ref<UserHeading>?
    private var returnHomeRef: Ref<ReturnHomePilotingItf>?
    private var remoteControlCompassRef: Ref<Compass>?
    private var oldLandscapeInterfaceOrientation: UIInterfaceOrientation = .landscapeLeft

    /// Current user location.
    private var userLocationSubject = CurrentValueSubject<CLLocation?, Never>(nil)
    /// Current drone location UserDefaults storage.
    private var droneLocationStorage: Location3D? {
        get { Location3D.readDefaultsValue(forKey: DefaultsKeys.lastDroneLocationKey) }
        set { newValue?.saveValueToDefaults(forKey: DefaultsKeys.lastDroneLocationKey) }
    }
    /// Current drone location
    private var droneRealLocationSubject = CurrentValueSubject<CLLocationCoordinate2D?, Never>(nil)
    /// Animated drone location
    private var droneAnimatedLocationSubject = CurrentValueSubject<CLLocationCoordinate2D?, Never>(nil)
    /// Current drone absolute altitude
    private var droneAbsoluteAltitudeSubject = CurrentValueSubject<Double?, Never>(nil)
    /// Current drone take off altitude
    private var droneTakeOffAltitudeSubject = CurrentValueSubject<Double?, Never>(nil)
    /// Current return home location
    private var returnHomeLocationSubject = CurrentValueSubject<CLLocationCoordinate2D?, Never>(nil)

    /// Current user device heading from GroundSdk
    private var rawUserDeviceHeadingSubject = CurrentValueSubject<Double, Never>(0.0)
    /// Device's orientation
    private var deviceOrientationSubject = CurrentValueSubject<UIDeviceOrientation, Never>(UIDevice.current.orientation)
    /// Corrected user device heading taking orientation into account.
    private var userDeviceHeadingPublisher: AnyPublisher<Double, Never> {
        rawUserDeviceHeadingSubject.combineLatest(deviceOrientationSubject)
            .map {
                let (rawHeading, orientation) = $0
                var correctedHeading = rawHeading
                switch orientation {
                case .landscapeLeft:
                    correctedHeading += Constants.headingOrientationCorrection
                case .landscapeRight:
                    correctedHeading -= Constants.headingOrientationCorrection
                case .portraitUpsideDown:
                    if self.oldLandscapeInterfaceOrientation == .landscapeLeft {
                        correctedHeading += Constants.headingOrientationCorrection
                    } else {
                        correctedHeading -= Constants.headingOrientationCorrection
                    }
                default:
                   if self.oldLandscapeInterfaceOrientation == .landscapeRight {
                        correctedHeading -= Constants.headingOrientationCorrection
                    } else {
                        correctedHeading += Constants.headingOrientationCorrection
                    }
                }
                return correctedHeading
            }
            .eraseToAnyPublisher()
    }
    /// Drone heading storage
    private var droneHeadingStorage: Double {
        get { Defaults.lastDroneHeading ?? 0.0 }
        set { Defaults.lastDroneHeading = newValue }
    }
    /// Current drone heading.
    private var droneHeadingSubject = CurrentValueSubject<Double, Never>(0.0)
    /// Boolean describing if drone gps is currently fixed.
    private var isDroneGpsFixedSubject = CurrentValueSubject<Bool, Never>(false)

    /// Location interpolation timer
    private var animationTimer: Timer?
    /// Keeps track of location interpolation remaining movements
    private var animationIterations: Int = 0

    // MARK: Init
    init(connectedDroneHolder: ConnectedDroneHolder,
         connectedRcHolder: ConnectedRemoteControlHolder) {
        listen(connectedDroneHolder: connectedDroneHolder)
        listen(connectedRcHolder: connectedRcHolder)
        // Wire drone heading storage and subject
        droneHeadingSubject.value = droneHeadingStorage
        droneHeadingSubject
            .sink { [unowned self] in droneHeadingStorage = $0 }
            .store(in: &cancellables)

        droneRealLocationSubject
            .sink { [unowned self] coordinate in
                guard let coordinate = coordinate else { return }
                self.interpolateLocation(newLocation: coordinate)
            }
            .store(in: &cancellables)

        droneRealLocationSubject.value = droneLocationStorage?.coordinate
        droneTakeOffAltitudeSubject.value = droneLocationStorage?.altitude
        droneRealLocationSubject
            .combineLatest(droneTakeOffAltitudeSubject)
            .sink { [unowned self] (coordinate, altitude) in
                guard let coordinate = coordinate, let altitude = altitude else { return }
                droneLocationStorage = Location3D(coordinate: coordinate, altitude: altitude)
            }
            .store(in: &cancellables)

        droneAbsoluteAltitudeSubject.value = Defaults.lastDroneAbsoluteAltitude
        droneAbsoluteAltitudeSubject
            .sink { Defaults.lastDroneAbsoluteAltitude = $0 }
            .store(in: &cancellables)

        let groundSdk = GroundSdk()
        listenUserHeading(groundSdk: groundSdk)
        listenUserLocation(groundSdk: groundSdk)
        listenDeviceOrientation()
    }

    func listen(connectedDroneHolder: ConnectedDroneHolder) {
        connectedDroneHolder.dronePublisher
            .sink { [unowned self] in
                guard let drone = $0 else {
                    isDroneGpsFixedSubject.value = false
                    gpsRef = nil
                    droneGimbalRef = nil
                    altimeterRef = nil
                    return
                }
                listenGPS(drone: drone)
                listenGimbal(drone: drone)
                listenAltimeter(drone: drone)
                listenRth(drone: drone)
            }
            .store(in: &cancellables)
    }

    func listen(connectedRcHolder: ConnectedRemoteControlHolder) {
        connectedRcHolder.remoteControlPublisher
            .sink { [unowned self] in
                guard let remoteControl = $0 else {
                    remoteControlCompassRef = nil
                    return
                }
                listenCompass(remoteControl: remoteControl)
            }
            .store(in: &cancellables)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Private Funcs
private extension LocationsTrackerImpl {
    /// Starts watcher for GPS.
    func listenGPS(drone: Drone) {
        gpsRef = drone.getInstrument(Instruments.gps) { [unowned self] gps in
            guard let gps = gps,
                  let location = gps.lastKnownLocation else { return }
            isDroneGpsFixedSubject.value = gps.fixed
            droneRealLocationSubject.value = location.coordinate
        }
    }

    /// Starts watcher for altimeter.
    func listenAltimeter(drone: Drone) {
        altimeterRef = drone.getInstrument(Instruments.altimeter) { [unowned self] altimeter in
            guard let altimeter = altimeter else { return }
            droneAbsoluteAltitudeSubject.value = altimeter.absoluteAltitude
            droneTakeOffAltitudeSubject.value = altimeter.takeoffRelativeAltitude
        }
    }

    /// Starts watcher for drone's gimbal.
    func listenGimbal(drone: Drone) {
        droneGimbalRef = drone.getPeripheral(Peripherals.gimbal) { [unowned self] gimbal in
            guard let gimbalHeading = gimbal?.currentAttitude(frameOfReference: .absolute)[.yaw] else { return }
            droneHeadingSubject.value = gimbalHeading
        }
    }

    /// Starts watcher for user location.
    ///
    /// - Parameters:
    ///     - groundSdk: The GroundSdk instance
    func listenUserLocation(groundSdk: GroundSdk) {
        userLocationRef = groundSdk.getFacility(Facilities.userLocation) { [unowned self] userLocation in
            guard let userLocation = userLocation,
                userLocation.authorized,
                !userLocation.stopped else { return }
            userLocationSubject.value = userLocation.location
        }
    }

    /// Starts watcher for user heading.
    ///
    /// - Parameters:
    ///     - groundSdk: The GroundSdk instance
    func listenUserHeading(groundSdk: GroundSdk) {
        userHeadingRef = groundSdk.getFacility(Facilities.userHeading) { [unowned self] userHeading in
            guard let heading = userHeading?.heading?.magneticHeading else { return }
            if remoteControlCompassRef == nil {
                rawUserDeviceHeadingSubject.value = heading
            }
        }
    }

    /// Listen for device's orientation changes
    func listenDeviceOrientation() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleOrientationChange),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }

    /// Handle device's orientation changes
    @objc func handleOrientationChange() {
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            oldLandscapeInterfaceOrientation = .landscapeLeft
        case .landscapeRight:
            oldLandscapeInterfaceOrientation = .landscapeRight
        default:
            break
        }
        deviceOrientationSubject.value = UIDevice.current.orientation
    }

    /// Starts watcher for remote control compass.
    func listenCompass(remoteControl: RemoteControl) {
        remoteControlCompassRef = remoteControl.getInstrument(Instruments.compass) { [unowned self] compass in
            guard let remoteControlHeading = compass?.heading else { return }
            rawUserDeviceHeadingSubject.value = remoteControlHeading > 180 ? remoteControlHeading - 360 : remoteControlHeading
        }
    }

    /// Starts watcher for return home
    func listenRth(drone: Drone) {
        returnHomeRef = drone.getPilotingItf(PilotingItfs.returnHome) { [unowned self] returnHome in
            guard let returnHomeLocation = returnHome?.homeLocation else { return }
            self.returnHomeLocationSubject.value = returnHomeLocation.coordinate
        }
    }

    /// Populate droneAbsoluteInterpolatedLocationSubject with drone absolute location and linear interpolation.
    ///
    /// When we have a new real drone location, `droneAbsoluteInterpolatedLocationSubject` will be updated up to `Constants.animationMaxSteps` times with
    /// equidistant locations for `Constants.animationInterval` seconds.
    /// The new location distance from current location in meters should be : `Constants.animationMinStep` < `distance` < `Constants.animationMaxDistance`
    ///
    /// - Parameters:
    ///     - newLocation: new drone real location
    func interpolateLocation(newLocation: CLLocationCoordinate2D) {
        guard let oldLocation = droneAnimatedLocationSubject.value else {
            animationTimer?.invalidate()
            droneAnimatedLocationSubject.value = newLocation
            return
        }
        let movement = oldLocation.distance(from: newLocation)
        guard movement > 0 else { return }
        guard movement < Constants.animationMaxDistance else {
            animationTimer?.invalidate()
            droneAnimatedLocationSubject.value = newLocation
            return
        }

        animationIterations = min(Constants.animationMaxSteps, animationIterations + Int(movement / Constants.animationMinStep))
        guard animationIterations > 1 else {
            animationTimer?.invalidate()
            droneAnimatedLocationSubject.value = newLocation
            return
        }
        animationTimer?.invalidate()
        let totalIterations = animationIterations
        let timeInterval = Constants.animationInterval / Double(Constants.animationMaxSteps)
        animationTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            self.animationIterations -= 1
            let progressCoef = Double(totalIterations - self.animationIterations) / Double(totalIterations)
            self.droneAnimatedLocationSubject.value = CLLocationCoordinate2D(
                latitude: oldLocation.latitude + (newLocation.latitude - oldLocation.latitude) * progressCoef,
                longitude: oldLocation.longitude + (newLocation.longitude - oldLocation.longitude) * progressCoef)
            if self.animationIterations <= 0 {
                timer.invalidate()
                self.animationTimer = nil
            }
        }
        animationTimer?.fire()
    }
}

/// `LocationsTracker` conformance
extension LocationsTrackerImpl: LocationsTracker {

    func drone2DLocationPublisher(animated: Bool) -> AnyPublisher<CLLocationCoordinate2D, Never> {
        let locationSubject = animated ? droneAnimatedLocationSubject : droneRealLocationSubject
        return locationSubject.compactMap({$0}).eraseToAnyPublisher()
    }

    func drone2DOrientedLocationPublisher(animated: Bool) -> AnyPublisher<OrientedLocation, Never> {
        let locationSubject = animated ? droneAnimatedLocationSubject : droneRealLocationSubject
        return locationSubject.compactMap({$0}).combineLatest(droneHeadingSubject)
            .map({ (location, heading) in
                OrientedLocation(coordinates: Location3D(coordinate: location, altitude: 0), heading: heading)
            }).eraseToAnyPublisher()
    }

    func drone3DLocation(absoluteAltitude: Bool) -> OrientedLocation {
        var coordinates: Location3D?
        if let location = droneRealLocationSubject.value,
            let altitude = (absoluteAltitude ? droneAbsoluteAltitudeSubject : droneTakeOffAltitudeSubject).value {
            coordinates = Location3D(coordinate: location, altitude: altitude)
        }
        return OrientedLocation(coordinates: coordinates, heading: droneHeadingSubject.value)
    }

    func droneAltitudePublisher(absoluteAltitude: Bool) -> AnyPublisher<Double, Never> {
        let altitudePublisher = absoluteAltitude ? droneAbsoluteAltitudeSubject : droneTakeOffAltitudeSubject
        return altitudePublisher.compactMap { $0 }.eraseToAnyPublisher()
    }

    func drone3DLocationPublisher(animated: Bool, absoluteAltitude: Bool) -> AnyPublisher<OrientedLocation, Never> {
        let locationSubject = animated ? droneAnimatedLocationSubject : droneRealLocationSubject
        let altitudeSubject = absoluteAltitude ? droneAbsoluteAltitudeSubject : droneTakeOffAltitudeSubject
        return locationSubject.combineLatest(altitudeSubject, droneHeadingSubject)
            .map({ (location, altitude, heading) in
                var coordinates: Location3D?
                if let location = location, let altitude = altitude {
                    coordinates = Location3D(coordinate: location, altitude: altitude)
                }
                return OrientedLocation(coordinates: coordinates, heading: heading)
            }).eraseToAnyPublisher()
    }

    var returnHomeLocation: CLLocationCoordinate2D? {
        return returnHomeLocationSubject.value
    }

    var userLocation: OrientedLocation {
        if let location = userLocationSubject.value {
            return OrientedLocation(coordinates: Location3D(coordinate: location.coordinate,
                                                           altitude: location.altitude),
                                    heading: rawUserDeviceHeadingSubject.value)
        }
        return OrientedLocation(coordinates: nil,
                                heading: rawUserDeviceHeadingSubject.value)
    }

    var droneLocation: CLLocationCoordinate2D? {
        droneRealLocationSubject.value
    }

    var droneAbsoluteAltitude: Double? {
        droneAbsoluteAltitudeSubject.value
    }

    var droneHeading: Double? {
        droneHeadingSubject.value
    }

    var isDroneGpsFixed: Bool {
        isDroneGpsFixedSubject.value
    }

    var userLocationPublisher: AnyPublisher<OrientedLocation, Never> {
        userLocationSubject.combineLatest(userDeviceHeadingPublisher)
            .map {
                let heading = self.remoteControlCompassRef == nil ? $0.1 : self.rawUserDeviceHeadingSubject.value
                if let location = $0.0 {
                    return OrientedLocation(coordinates: Location3D(coordinate: location.coordinate,
                                                                    altitude: location.altitude),
                                            heading: heading)
                }
                return OrientedLocation(coordinates: nil,
                                        heading: heading)
            }
            .eraseToAnyPublisher()
    }

    var returnHomeLocationPublisher: AnyPublisher<CLLocationCoordinate2D?, Never> {
        returnHomeLocationSubject.eraseToAnyPublisher()
    }

    var droneGpsFixedPublisher: AnyPublisher<Bool, Never> { isDroneGpsFixedSubject.eraseToAnyPublisher() }
}
