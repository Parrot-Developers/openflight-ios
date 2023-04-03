//    Copyright (C) 2019 Parrot Drones SAS
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

import ArcGIS

/// Utility extension for `AGSPoint`.
public extension AGSPoint {

    /// Returns true if the coordinate is valid.
    /// Coordinate 0, 0 is assumed invalid here.
    var isValid: Bool {
        let coordinate = self.toCLLocationCoordinate2D()
        return CLLocationCoordinate2DIsValid(coordinate)
        && (coordinate.latitude != 0.0 || coordinate.longitude != 0.0)
    }

    /// Creates a new point with given altitude.
    ///
    /// - Parameters:
    ///    - altitude: altitude to apply
    /// - Returns: new point with custom altitude
    func withAltitude(_ altitude: Double) -> AGSPoint {
        return AGSPoint(x: x, y: y, z: altitude, spatialReference: spatialReference)
    }

    /// Computes the distance between self and another `AGSPoint`.
    /// Result of this is approximative at very long distances.
    ///
    /// - Parameters:
    ///    - point: target point
    /// - Returns: distance between the two points, in meters
    func distanceToPoint(_ point: AGSPoint) -> Double {
        let diffZ = point.z - z
        let points = AGSPolyline(points: [self, point])
        return sqrt(diffZ.square + AGSGeometryEngine.geodeticLength(of: points, lengthUnit: .meters(), curveType: .geodesic).square)
    }
}
