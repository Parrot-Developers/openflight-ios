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

/// Utility extension for `CLLocationCoordinate2D`.
public extension CLLocationCoordinate2D {
    // MARK: - Internal Properties
    /// Returns coordinates as string.
    var coordinatesDescription: String {
        return String(format: Constants.coordinateFormat, latitude, longitude)
    }

    /// Returns true if the coordinate is valid.
    /// Coordinate 0, 0 is assumed invalid here.
    var isValid: Bool {
        return CLLocationCoordinate2DIsValid(self)
            && (latitude != 0.0 && longitude != 0.0)
    }

    // MARK: - Private Enums
    private enum Constants {
        static let gmsFormat: String = "%d°%d'%d\"%@ %d°%d'%d\"%@"
        static let coordinateFormat: String = "%0.6f, %0.6f"
        static let secondsOrDegreesConverter: Int = 3600
        static let minutesConverter: Int = 60
    }

    // MARK: - Internal Funcs
    /// Converts a location into a string in DMS coordinate format.
    ///
    /// - Parameters:
    ///     - latitude: latitude value
    ///     - longitude: longitude value
    func convertToDmsCoordinate() -> String {
        // Get longitude and latitude values in degress, seconds and minutes.
        var latInSeconds = Int(self.latitude * Double(Constants.secondsOrDegreesConverter))
        let latInDegrees = latInSeconds / Constants.secondsOrDegreesConverter
        latInSeconds = abs(latInSeconds % Constants.secondsOrDegreesConverter)
        let latInMinutes = latInSeconds / Constants.minutesConverter
        latInSeconds %= Constants.minutesConverter
        var longInSeconds = Int(self.longitude * Double(Constants.secondsOrDegreesConverter))
        let longInDegrees = longInSeconds / Constants.secondsOrDegreesConverter
        longInSeconds = abs(longInSeconds % Constants.secondsOrDegreesConverter)
        let longInMinutes = longInSeconds / Constants.minutesConverter
        longInSeconds %= Constants.minutesConverter

        return String(format: Constants.gmsFormat,
                      abs(latInDegrees),
                      latInMinutes,
                      latInSeconds, latInDegrees >= 0 ? L10n.cardinalDirectionNorth : L10n.cardinalDirectionSouth,
                      abs(longInDegrees),
                      longInMinutes,
                      longInSeconds,
                      longInDegrees >= 0 ? L10n.cardinalDirectionEast : L10n.cardinalDirectionWest)
    }

    func distance(from: CLLocationCoordinate2D) -> CLLocationDistance {
        let locationFrom = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let locationTo = CLLocation(latitude: self.latitude, longitude: self.longitude)
        return locationFrom.distance(from: locationTo)
    }

    /// Returns the bearing to a given location.
    ///
    /// - Parameters:
    ///     - location: target of the bearing
    func bearingTo(_ location: CLLocationCoordinate2D) -> Double {
        let latitude1 = self.latitude.toRadians()
        let longitude1 = self.longitude.toRadians()
        let latitude2 = location.latitude.toRadians()
        let longitude2 = location.longitude.toRadians()

        let delta = longitude2 - longitude1
        let coordX = sin(delta) * cos(latitude2)
        let coordY = cos(latitude1) * sin(latitude2) - sin(latitude1) * cos(latitude2) * cos(delta)
        let radiansBearing = atan2(coordX, coordY)

        return radiansBearing.toDegrees()
    }
}

/// Extension for `CLLocationCoordinateD2` conformance to `Equatable`.

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude
            && lhs.longitude == rhs.longitude
    }
}
