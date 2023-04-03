//    Copyright (C) 2020 Parrot Drones SAS
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
import ArcGIS
import SwiftyUserDefaults

// MARK: - Public Structs
/// Represents a location with coordinates and an altitude.
public struct Location3D: Equatable {
    public var coordinate: CLLocationCoordinate2D
    public var altitude: Double

    /// Returns altitude value with unit.
    public var formattedAltitude: String {
        return UnitHelper.stringDistanceWithDouble(self.altitude, spacing: false)
    }

    /// Returns location as `AGSPoint`.
    public var agsPoint: AGSPoint {
        return AGSPoint(x: self.coordinate.longitude,
                        y: self.coordinate.latitude,
                        z: self.altitude,
                        spatialReference: .wgs84())
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - coordinate: the 2D coordinate (LatLong format)
    ///    - altitude: the altitude
    public init(coordinate: CLLocationCoordinate2D,
                altitude: Double) {
        self.coordinate = coordinate
        self.altitude = altitude
    }
}

/// Extension for reading/writing `Location3D` to/from UserDefaults.

extension Location3D {
    // MARK: - Private Enums
    private enum Constants {
        static let latitudeKey = "latitude"
        static let longitudeKey = "longitude"
        static let altitudeKey = "altitude"
    }

    // MARK: - Public Funcs
    /// Save current value to UserDefaults.
    ///
    /// - Parameters:
    ///    - key: Defaults key
    func saveValueToDefaults(forKey key: DefaultsKey<Data?>) {
        let values = [Constants.latitudeKey: self.coordinate.latitude,
                      Constants.longitudeKey: self.coordinate.longitude,
                      Constants.altitudeKey: self.altitude]
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: values, requiringSecureCoding: false) {
            Defaults[key: key] = data
        }
    }

    /// Get UserDefaults value from key in parameter.
    ///
    /// - Parameters:
    ///    - key: Defaults key
    ///
    /// - Returns: Location saved in UserDefaults for the mentionned key (if available).
    static func readDefaultsValue(forKey key: DefaultsKey<Data?>) -> Location3D? {
        guard let data = Defaults[key: key],
            let extractedData = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String: Any],
            let latitude = extractedData[Constants.latitudeKey] as? CLLocationDegrees,
            let longitude = extractedData[Constants.longitudeKey] as? CLLocationDegrees,
            let altitude = extractedData[Constants.altitudeKey] as? Double
            else {
            return nil
        }
        return Location3D(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                          altitude: altitude)
    }
}
