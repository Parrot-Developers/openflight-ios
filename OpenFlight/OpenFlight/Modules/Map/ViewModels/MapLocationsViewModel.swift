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
import CoreLocation
import ArcGIS
import SwiftyUserDefaults

/// State for `MapLocationsViewModel`.

final class MapLocationsState: DevicesConnectionState {
    // MARK: - Internal Properties
    /// Current drone location.
    fileprivate(set) var droneLocation = OrientedLocation(coordinates: CLLocationCoordinate2D.readDefaultsValue(forKey: DefaultsKeys.lastDroneLocationKey),
                                                          heading: Defaults.lastDroneHeading ?? 0.0)
    /// Current user location.
    fileprivate(set) var userLocation: CLLocation?
    /// Current user device heading.
    fileprivate(set) var userDeviceHeading = 0.0
    /// Current remote control heading.
    fileprivate(set) var remoteControlHeading = 0.0
    /// Boolean describing if drone gps is currently fixed.
    fileprivate(set) var isDroneGpsFixed: Bool = false
    /// Boolean describing if auto center is currently disabled.
    fileprivate(set) var disabledAutoCenter: Bool = false
    /// Boolean to force hide center button.
    fileprivate(set) var forceHideCenterButton: Bool = false
    /// Boolean describing if map should always be centered on drone.
    fileprivate(set) var alwaysCenterOnDroneLocation: Bool = false
    /// Oriented location to display for user.
    /// Remote control's heading is used if available, user device's otherwise.
    var userOrientedLocation: OrientedLocation {
        let heading = remoteControlConnectionState?.isConnected() == true ? remoteControlHeading : userDeviceHeading
        return OrientedLocation(coordinates: userLocation?.coordinate,
                                heading: heading)
    }

    /// Helper for current center state.
    var centerState: MapCenterState {
        if droneLocation.isValid
            && ((self.droneConnectionState?.isConnected() == true && isDroneGpsFixed)
                || alwaysCenterOnDroneLocation) {
            return .drone
        } else if userOrientedLocation.isValid {
            return .user
        } else {
            return .none
        }
    }

    /// Helper for current center coordinates.
    var currentCenterCoordinates: CLLocationCoordinate2D? {
        switch centerState {
        case .drone:
            return droneLocation.coordinates
        case .user:
            return userOrientedLocation.coordinates
        case .none:
            return nil
        }
    }

    /// Helper for center button visibility.
    var shouldHideCenterButton: Bool {
        return centerState == .none
            || !disabledAutoCenter
            || forceHideCenterButton
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
    ///    - droneLocation: drone oriented gps location
    ///    - userLocation: user location
    ///    - userDeviceHeading: user device heading
    ///    - remoteControlHeading: remote control heading
    ///    - isDroneGpsFixed: boolean describing if drone's gps is currently fixed
    ///    - disabledAutoCenter: boolean for disabling auto center
    ///    - forceHideCenterButton: boolean to force hide center button
    ///    - alwaysCenterOnDroneLocation: boolean describing if map should always be centered on drone
    init(droneConnectionState: DeviceConnectionState?,
         remoteControlConnectionState: DeviceConnectionState?,
         droneLocation: OrientedLocation,
         userLocation: CLLocation?,
         userDeviceHeading: Double,
         remoteControlHeading: Double,
         isDroneGpsFixed: Bool,
         disabledAutoCenter: Bool,
         forceHideCenterButton: Bool,
         alwaysCenterOnDroneLocation: Bool) {
        super.init(droneConnectionState: droneConnectionState,
                   remoteControlConnectionState: remoteControlConnectionState)
        self.droneLocation = droneLocation
        self.userLocation = userLocation
        self.userDeviceHeading = userDeviceHeading
        self.remoteControlHeading = remoteControlHeading
        self.isDroneGpsFixed = isDroneGpsFixed
        self.disabledAutoCenter = disabledAutoCenter
        self.forceHideCenterButton = forceHideCenterButton
        self.alwaysCenterOnDroneLocation = alwaysCenterOnDroneLocation
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DevicesConnectionState) -> Bool {
        guard let other = other as? MapLocationsState else {
            return false
        }
        return super.isEqual(to: other)
            && self.droneLocation == other.droneLocation
            && self.userLocation == other.userLocation
            && self.userDeviceHeading == other.userDeviceHeading
            && self.remoteControlHeading == other.remoteControlHeading
            && self.isDroneGpsFixed == other.isDroneGpsFixed
            && self.disabledAutoCenter == other.disabledAutoCenter
            && self.forceHideCenterButton == other.forceHideCenterButton
            && self.alwaysCenterOnDroneLocation == other.alwaysCenterOnDroneLocation
    }

    override func copy() -> MapLocationsState {
        return MapLocationsState(droneConnectionState: self.droneConnectionState,
                                 remoteControlConnectionState: self.remoteControlConnectionState,
                                 droneLocation: self.droneLocation,
                                 userLocation: self.userLocation,
                                 userDeviceHeading: self.userDeviceHeading,
                                 remoteControlHeading: self.remoteControlHeading,
                                 isDroneGpsFixed: self.isDroneGpsFixed,
                                 disabledAutoCenter: self.disabledAutoCenter,
                                 forceHideCenterButton: self.forceHideCenterButton,
                                 alwaysCenterOnDroneLocation: self.alwaysCenterOnDroneLocation)
    }
}

/// View model for drone and user locations on map.

final class MapLocationsViewModel: DevicesStateViewModel<MapLocationsState> {
    // MARK: - Private Properties
    private let groundSdk = GroundSdk()
    private var gpsRef: Ref<Gps>?
    private var droneCompassRef: Ref<Compass>?
    private var userLocationRef: Ref<UserLocation>?
    private var userHeadingRef: Ref<UserHeading>?
    private var remoteControlCompassRef: Ref<Compass>?

    // MARK: - Private Enums
    private enum Constants {
        static let headingOrientationCorrection: Double = 90.0
    }

    // MARK: - Init
    override init() {
        super.init()

        listenUserLocation()
        listenUserHeading()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)
        listenGPS(drone: drone)
        listenCompass(drone: drone)
    }

    override func listenRemoteControl(remoteControl: RemoteControl) {
        super.listenRemoteControl(remoteControl: remoteControl)
        listenCompass(remoteControl: remoteControl)
    }

    // MARK: - Public Funcs
    /// Updates given camera to move it at center location.
    ///
    /// - Parameters:
    ///    - camera: current camera
    ///    - distance: distance to center location
    /// - Returns: new camera looking at center location
    func updateCenteredCamera(_ camera: AGSCamera, distance: Double?) -> AGSCamera {
        guard let currentCenterCoordinates = state.value.currentCenterCoordinates else {
            return camera
        }
        return AGSCamera(lookAt: AGSPoint(clLocationCoordinate2D: currentCenterCoordinates),
                         distance: distance ?? camera.location.z,
                         heading: camera.heading,
                         pitch: camera.pitch,
                         roll: camera.roll)
    }

    /// Updates auto center setting.
    ///
    /// - Parameters:
    ///    - isDisabled: whether auto center should be disabled
    func disableAutoCenter(_ isDisabled: Bool) {
        let copy = self.state.value.copy()
        copy.disabledAutoCenter = isDisabled
        self.state.set(copy)
    }

    /// Updates center button visibility (forced).
    ///
    /// - Parameters:
    ///    - isHidden: whether center button should be hidden
    func forceHideCenterButton(_ isHidden: Bool) {
        let copy = self.state.value.copy()
        copy.forceHideCenterButton = isHidden
        self.state.set(copy)
    }

    /// Updates always center on drone location setting.
    ///
    /// - Parameters:
    ///    - shouldCenterOnDrone: whether map shoul walways be centered on drone.
    func alwaysCenterOnDroneLocation(_ shouldCenterOnDrone: Bool) {
        let copy = self.state.value.copy()
        copy.alwaysCenterOnDroneLocation = shouldCenterOnDrone
        self.state.set(copy)
    }
}

// MARK: - Private Funcs
private extension MapLocationsViewModel {
    /// Starts watcher for GPS.
    func listenGPS(drone: Drone) {
        gpsRef = drone.getInstrument(Instruments.gps) { [weak self] gps in
            guard let gps = gps,
                let location = gps.lastKnownLocation,
                let copy = self?.state.value.copy()
                else {
                    return
            }
            copy.isDroneGpsFixed = gps.fixed
            copy.droneLocation.coordinates = location.coordinate
            self?.state.set(copy)
            self?.saveDroneLocationCoordinates()
        }
    }

    /// Starts watcher for drone's compass.
    func listenCompass(drone: Drone) {
        droneCompassRef = drone.getInstrument(Instruments.compass) { [weak self] compass in
            guard let droneHeading = compass?.heading,
                let copy = self?.state.value.copy()
                else {
                    return
            }
            copy.droneLocation.heading = droneHeading
            self?.state.set(copy)
            self?.saveDroneHeading()
        }
    }

    /// Starts watcher for user location.
    func listenUserLocation() {
        userLocationRef = groundSdk.getFacility(Facilities.userLocation) { [weak self] userLocation in
            guard let userLocation = userLocation,
                userLocation.authorized,
                !userLocation.stopped,
                let copy = self?.state.value.copy()
                else {
                    return
            }
            copy.userLocation = userLocation.location
            self?.state.set(copy)
        }
    }

    /// Starts watcher for user heading.
    func listenUserHeading() {
        userHeadingRef = groundSdk.getFacility(Facilities.userHeading) { [weak self] userHeading in
            guard let heading = userHeading?.heading?.magneticHeading,
                let copy = self?.state.value.copy() else {
                    return
            }

            // Fix heading depending device orientation
            let correctedHeading = UIApplication.shared.statusBarOrientation == .landscapeLeft
                ? heading-Constants.headingOrientationCorrection
                : heading+Constants.headingOrientationCorrection

            copy.userDeviceHeading = correctedHeading
            self?.state.set(copy)
        }
    }

    /// Starts watcher for remote control compass.
    func listenCompass(remoteControl: RemoteControl) {
        remoteControlCompassRef = remoteControl.getInstrument(Instruments.compass) { [weak self] compass in
            guard let remoteControlHeading = compass?.heading,
                let copy = self?.state.value.copy()
                else {
                    return
            }
            copy.remoteControlHeading = remoteControlHeading
            self?.state.set(copy)
        }
    }

    /// Save last drone location coordinates to defaults.
    func saveDroneLocationCoordinates() {
        state.value.droneLocation.coordinates?.saveValueToDefaults(forKey: DefaultsKeys.lastDroneLocationKey)
    }

    /// Save last drone heading to defaults.
    func saveDroneHeading() {
        Defaults.lastDroneHeading = state.value.droneLocation.heading
    }
}
