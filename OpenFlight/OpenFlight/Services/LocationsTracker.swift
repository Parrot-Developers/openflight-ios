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
    /// Drone location publisher with altitude relative to take off
    var droneLocationPublisher: AnyPublisher<OrientedLocation, Never> { get }
    /// Drone location publisher with absolute altitude
    var droneAbsoluteLocationPublisher: AnyPublisher<OrientedLocation, Never> { get }
    /// Return home location publisher
    var returnHomeLocationPublisher: AnyPublisher<CLLocationCoordinate2D?, Never> { get }
    /// Drone gps fixed publisher
    var droneGpsFixedPublisher: AnyPublisher<Bool, Never> { get }
    /// User location
    var userLocation: OrientedLocation { get }
    /// Drone location
    var droneLocation: OrientedLocation { get }
    /// Drone location with absolute altitude
    var droneAbsoluteLocation: OrientedLocation { get }
    /// Connected drone current location.
    /// - Note: Unlike `droneLocation`, which represents the last known drone location (even if the drone is not connected),
    ///         `connectedDroneCurrentLocation` is the current connected drone location (`nil` if not connected or GPS not fixed).
    var connectedDroneCurrentLocation: OrientedLocation? { get }
    /// Return home location
    var returnHomeLocation: CLLocationCoordinate2D? { get }
}

/// Private UserDefaults keys
private extension DefaultsKeys {
    var lastDroneLocation: DefaultsKey<Data?> { DefaultsKeys.lastDroneLocationKey }
    var lastDroneHeading: DefaultsKey<Double?> { DefaultsKeys.lastDroneHeadingKey }

    static let lastDroneLocationKey: DefaultsKey<Data?> = DefaultsKey<Data?>("key_lastDroneLocation")
    static let lastDroneHeadingKey: DefaultsKey<Double?> = DefaultsKey<Double?>("key_lastDroneHeading")
}

/// Implementation for `LocationsTracker`
class LocationsTrackerImpl {

    /// Constants
    private enum Constants {
        static let headingOrientationCorrection: Double = 90.0
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
    private var absoluteAltitude: Double?
    private var takeOffAltitude: Double?

    /// Current user location.
    private var userLocationSubject = CurrentValueSubject<CLLocation?, Never>(nil)
    /// Current drone location UserDefaults storage.
    private var droneLocationStorage: Location3D? {
        get { Location3D.readDefaultsValue(forKey: DefaultsKeys.lastDroneLocationKey) }
        set { newValue?.saveValueToDefaults(forKey: DefaultsKeys.lastDroneLocationKey) }
    }
    /// Current drone location
    private var droneLocationSubject = CurrentValueSubject<Location3D?, Never>(nil)
    /// Current drone absolute location
    private var droneAbsoluteLocationSubject = CurrentValueSubject<Location3D?, Never>(nil)
    /// Current drone location
    private var connectedDroneLocationSubject = CurrentValueSubject<Location3D?, Never>(nil)
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
        // Wire drone location storage and subject
        droneLocationSubject.value = droneLocationStorage
        droneLocationSubject
            .sink { [unowned self] in droneLocationStorage = $0 }
            .store(in: &cancellables)
        droneAbsoluteLocationSubject.value = droneLocationStorage
        droneAbsoluteLocationSubject
            .sink { [unowned self] in droneLocationStorage = $0 }
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
                    connectedDroneLocationSubject.value = nil
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
            droneLocationSubject.value = Location3D(coordinate: location.coordinate,
                                                    altitude: takeOffAltitude ?? 0.0)
            droneAbsoluteLocationSubject.value = Location3D(coordinate: location.coordinate,
                                                    altitude: absoluteAltitude ?? 0.0)
            // The connected drone's current location is treated as unkown when GPS is not fixed.
            connectedDroneLocationSubject.value = gps.fixed ? droneLocationSubject.value : nil
        }
    }

    /// Starts watcher for altimeter.
    func listenAltimeter(drone: Drone) {
        altimeterRef = drone.getInstrument(Instruments.altimeter) { [unowned self] altimeter in
            absoluteAltitude = altimeter?.absoluteAltitude
            takeOffAltitude = altimeter?.takeoffRelativeAltitude
            if let coordinate = droneLocationSubject.value?.coordinate {
                droneLocationSubject.value = Location3D(coordinate: coordinate,
                                                        altitude: takeOffAltitude ?? 0.0)
                droneAbsoluteLocationSubject.value = Location3D(coordinate: coordinate,
                                                        altitude: absoluteAltitude ?? 0.0)
            }
            // Update the connected drone's current location only when GPS has a fixed drone's location.
            if let coordinate = connectedDroneLocationSubject.value?.coordinate,
               gpsRef?.value?.fixed == true {
                connectedDroneLocationSubject.value = Location3D(coordinate: coordinate,
                                                                 altitude: absoluteAltitude ?? 0.0)
            }
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
}

/// `LocationsTracker` conformance
extension LocationsTrackerImpl: LocationsTracker {

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

    var droneLocation: OrientedLocation {
        OrientedLocation(coordinates: droneLocationSubject.value,
                         heading: droneHeadingSubject.value)
    }

    var droneAbsoluteLocation: OrientedLocation {
        OrientedLocation(coordinates: droneAbsoluteLocationSubject.value,
                         heading: droneHeadingSubject.value)
    }

    var connectedDroneCurrentLocation: OrientedLocation? {
        OrientedLocation(coordinates: connectedDroneLocationSubject.value,
                         heading: droneHeadingSubject.value)
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

    var droneLocationPublisher: AnyPublisher<OrientedLocation, Never> {
        droneLocationSubject.combineLatest(droneHeadingSubject)
            .map { OrientedLocation(coordinates: $0.0, heading: $0.1) }
            .eraseToAnyPublisher()
    }

    var droneAbsoluteLocationPublisher: AnyPublisher<OrientedLocation, Never> {
        droneAbsoluteLocationSubject.combineLatest(droneHeadingSubject)
            .map { OrientedLocation(coordinates: $0.0, heading: $0.1) }
            .eraseToAnyPublisher()
    }

    var returnHomeLocationPublisher: AnyPublisher<CLLocationCoordinate2D?, Never> {
        returnHomeLocationSubject.eraseToAnyPublisher()
    }

    var droneGpsFixedPublisher: AnyPublisher<Bool, Never> { isDroneGpsFixedSubject.eraseToAnyPublisher() }
}
