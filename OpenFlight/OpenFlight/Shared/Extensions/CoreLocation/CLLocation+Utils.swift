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

/// Utility extension for `CLLocation`.
public extension CLLocation {
    /// Requests the address description of location.
    ///
    /// - Parameters:
    ///     - completion: callback which returns the address description string
    func locationDetail(completion: @escaping(String?) -> Void) {
        CLGeocoder().reverseGeocodeLocation(self) { (placemarks: [CLPlacemark]?, error: Error?) in
            guard let place = placemarks?.first,
                  error == nil else {
                completion(nil)
                return
            }

            completion(place.addressDescription)
        }
    }

    /// Constructor.
    ///
    /// - Parameters:
    ///   - latitude: the latitude
    ///   - longitude: the longitude
    ///   - altitude: the altitude
    ///
    /// - Note: Accuracies are set to 0 and timestamp to the current date.
    convenience init(latitude: CLLocationDegrees,
                     longitude: CLLocationDegrees,
                     altitude: CLLocationDistance) {
        self.init(coordinate: CLLocationCoordinate2D(latitude: latitude,
                                                     longitude: longitude),
                  altitude: altitude,
                  horizontalAccuracy: 0,
                  verticalAccuracy: 0,
                  timestamp: Date())
    }
}

extension CLLocation {
    /// The Null Island location.
    static var nullIsland: Self { .init(latitude: 0, longitude: 0) }

    /// The antipode of the current location.
    var antipode: Self {
        let latitude = -1 * coordinate.latitude
        let longitude = coordinate.longitude > 0
        ? coordinate.longitude - 180
        : coordinate.longitude + 180
        return .init(latitude: latitude, longitude: longitude)
    }

    /// The earth radius in meters.
    static var earthRadius: CLLocationDistance {
        let halfPerimeter = Self.nullIsland.distance(from: Self.nullIsland.antipode)
        return halfPerimeter / .pi
    }

    /// Returns a new location moved by specified distance and  bearing.
    ///
    /// - Parameters:
    ///    - distance: the distance in meters
    ///    - bearing: the bearing in degrees [-180:180]
    ///
    /// - Note: Bearing examples:
    ///             • *0*: North
    ///             • *-90*: West
    ///             • *90*: East
    ///             • *180*: South
    ///             • *-45*: 45° N-W
    func moved(distance: CLLocationDistance, bearing: CLLocationDegrees) -> Self {
        let lat1 = coordinate.latitude.toRadians()
        let long1 = coordinate.longitude.toRadians()
        let bearingRadians = bearing.toRadians()
        let distanceRadians = distance / Self.earthRadius

        let lat2 = asin(sin(lat1) * cos(distanceRadians)
                        + cos(lat1) * sin(distanceRadians) * cos(bearingRadians))
        let long2 = long1 + atan2(sin(bearingRadians) * sin(distanceRadians) * cos(lat1),
                                  cos(distanceRadians) - sin(lat1) * sin(lat2))

        return .init(latitude: lat2.toDegrees(),
                     longitude: long2.toDegrees())
    }
}
