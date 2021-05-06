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

/// View model for geofence banner alerts.

final class HUDAlertBannerGeofenceViewModel: DroneWatcherViewModel<HUDAlertBannerSubState> {
    // MARK: - Private Properties
    private let groundSdk = GroundSdk()
    private var geofenceRef: Ref<Geofence>?
    private var altimeterRef: Ref<Altimeter>?
    private var gpsRef: Ref<Gps>?
    private var userLocationRef: Ref<UserLocation>?

    // MARK: - Override Funcs
    override init() {
        super.init()

        listenUserLocation()
    }

    override func listenDrone(drone: Drone) {
        listenGeofence(drone: drone)
        listenAltimeter(drone: drone)
        listenGps(drone: drone)
    }
}

// MARK: - Private Funcs
private extension HUDAlertBannerGeofenceViewModel {
    /// Starts watcher for geofence.
    func listenGeofence(drone: Drone) {
        geofenceRef = drone.getPeripheral(Peripherals.geofence) { [weak self] _ in
            self?.updateState()
        }
    }

    /// Starts watcher for altimeter.
    func listenAltimeter(drone: Drone) {
        altimeterRef = drone.getInstrument(Instruments.altimeter) { [weak self] _ in
            self?.updateState()
        }
    }

    /// Starts watcher for drone's gps.
    func listenGps(drone: Drone) {
        gpsRef = drone.getInstrument(Instruments.gps) { [weak self] _ in
            self?.updateState()
        }
    }

    /// Starts watcher for user location.
    func listenUserLocation() {
        userLocationRef = groundSdk.getFacility(Facilities.userLocation) { [weak self] _ in
            self?.updateState()
        }
    }

    /// Updates current state.
    func updateState() {
        guard let drone = drone else {
            self.state.set(HUDAlertBannerSubState(alerts: []))
            return
        }
        self.state.set(HUDAlertBannerSubState(alerts: drone.geofenceAlerts))
    }
}
