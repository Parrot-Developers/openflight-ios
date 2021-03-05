//
//  Copyright (C) 2021 Parrot Drones SAS.
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

/// Utility extension for `AGSGeometryEngine`.
public extension AGSGeometryEngine {
    /// Computes geodetic distance between given points with standard default
    /// parameters (distance in meters, azimuth in radians, geodesic curve).
    ///
    /// - Parameters:
    ///    - point1: first point
    ///    - point2: second point
    ///    - distanceUnit: unit for distance
    ///    - azimuthUnit: unit for azimuth
    ///    - curveType: type of geodetic curve
    /// - Returns: result distance
    static func standardGeodeticDistance(between point1: AGSPoint,
                                         and point2: AGSPoint,
                                         distanceUnit: AGSLinearUnit = .meters(),
                                         azimuthUnit: AGSAngularUnit = .radians(),
                                         curveType: AGSGeodeticCurveType = .geodesic) -> AGSGeodeticDistanceResult? {
        return geodeticDistanceBetweenPoint1(point1,
                                             point2: point2,
                                             distanceUnit: distanceUnit,
                                             azimuthUnit: azimuthUnit,
                                             curveType: curveType)
    }

    /// Computes geodetic move for given point with standard default
    /// parameters (distance in meters, azimuth in radians, geodesic curve).
    ///
    /// - Parameters:
    ///    - point: point to move
    ///    - distance: distance for move
    ///    - distanceUnit: unit for distance
    ///    - azimuth: azimuth for move
    ///    - azimuthUnit: unit for azimuth
    ///    - curveType: type of geodetic curve
    /// - Returns: moved point
    static func standardGeodeticMove(_ point: AGSPoint,
                                     distance: Double,
                                     distanceUnit: AGSLinearUnit = .meters(),
                                     azimuth: Double,
                                     azimuthUnit: AGSAngularUnit = .radians(),
                                     curveType: AGSGeodeticCurveType = .geodesic) -> AGSPoint? {
        return geodeticMove([point],
                            distance: distance,
                            distanceUnit: .meters(),
                            azimuth: azimuth,
                            azimuthUnit: .radians(),
                            curveType: .geodesic)?.first
    }

    /// Computes geodetic move for given array of points with standard default
    /// parameters (distance in meters, azimuth in radians, geodesic curve).
    ///
    /// - Parameters:
    ///    - points: points to move
    ///    - distance: distance for move
    ///    - distanceUnit: unit for distance
    ///    - azimuth: azimuth for move
    ///    - azimuthUnit: unit for azimuth
    ///    - curveType: type of geodetic curve
    /// - Returns: array of moved points
    static func standardGeodeticMove(_ points: [AGSPoint],
                                     distance: Double,
                                     distanceUnit: AGSLinearUnit = .meters(),
                                     azimuth: Double,
                                     azimuthUnit: AGSAngularUnit = .radians(),
                                     curveType: AGSGeodeticCurveType = .geodesic) -> [AGSPoint]? {
        return geodeticMove(points,
                            distance: distance,
                            distanceUnit: .meters(),
                            azimuth: azimuth,
                            azimuthUnit: .radians(),
                            curveType: .geodesic)
    }
}
