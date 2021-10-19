// Copyright (C) 2020 Parrot Drones SAS
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

// MARK: - Private Enums
private enum Constants {
    /// Distance to geofence limit from which an alert should be displayed (meters).
    static let geofenceDistanceAlertThreshold: Double = 2.0
}

/// Utility extension for Drone's geofence-related functions.
extension Drone {
    // MARK: - Internal Properties
    /// Returns true if drone current altitude is closer
    /// from geofence limit than threshold.
    var isAltitudeCloseToGeofenceLimit: Bool {
        guard let altitude = getInstrument(Instruments.altimeter)?.takeoffRelativeAltitude,
            let geofenceMaxAltitude = getPeripheral(Peripherals.geofence)?.maxAltitude.value
            else {
                return false
        }
        return altitude > geofenceMaxAltitude - Constants.geofenceDistanceAlertThreshold
    }

    /// Returns true if drone current distance to geofence center
    /// is closer from geofence limit than threshold.
    var isDistanceCloseToGeofenceLimit: Bool {
        guard let droneLocation = getInstrument(Instruments.gps)?.lastKnownLocation,
            let geofence = getPeripheral(Peripherals.geofence),
            let distance = geofence.center?.distance(from: droneLocation),
            !distance.isNaN
            else {
                return false
        }
        return distance > geofence.maxDistance.value - Constants.geofenceDistanceAlertThreshold
    }

    /// Returns alert level associated with current geofence distance state.
    var alertLevelForGeofenceDistanceState: AlertLevel {
        let isHorizontalGeofenceActive = getPeripheral(Peripherals.geofence)?.mode.value == .cylinder
        return isDistanceCloseToGeofenceLimit && isHorizontalGeofenceActive ? .warning : .none
    }

    /// Returns current geofence alerts.
    var geofenceAlerts: [HUDAlertType] {
        guard getInstrument(Instruments.gps)?.fixed == true,
            isStateFlying
            else {
                return []
        }
        let hasDistanceAlert = alertLevelForGeofenceDistanceState == .warning
        switch (hasDistanceAlert, isAltitudeCloseToGeofenceLimit) {
        case (true, true):
            return [HUDBannerCriticalAlertType.geofenceAltitudeAndDistance,
                    HUDBannerCriticalAlertType.geofenceAltitude,
                    HUDBannerCriticalAlertType.geofenceDistance]
        case (true, false):
            return [HUDBannerCriticalAlertType.geofenceDistance]
        case (false, true):
            return [HUDBannerCriticalAlertType.geofenceAltitude]
        default:
            return []
        }
    }
}
