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

import ArcGIS

/// Utility extension for `WayPoint` usage with ArcGIS.
extension WayPoint {
    // MARK: - Public Properties
    /// Returns AGSPoint for waypoint.
    public var agsPoint: AGSPoint {
        return AGSPoint(x: self.coordinate.longitude,
                        y: self.coordinate.latitude,
                        z: self.altitude,
                        spatialReference: .wgs84())
    }

    // MARK: - Internal Properties
    /// Returns a target point for current waypoint yaw.
    var target: AGSPoint? {
        return AGSGeometryEngine.standardGeodeticMove(agsPoint,
                                                      distance: Constants.targetDistance,
                                                      distanceUnit: .meters(),
                                                      azimuth: -yaw,
                                                      azimuthUnit: .degrees(),
                                                      curveType: .normalSection)
    }

    /// Returns duration to get to next waypoint, 0.0 if no next waypoint or inconsistent data.
    var navigateToNextDuration: Double {
        guard let nextWayPointLocation = nextWayPoint?.agsPoint,
              let distance = AGSGeometryEngine.standardGeodeticDistance(between: self.agsPoint,
                                                                        and: nextWayPointLocation)?.distance,
              speed > 0.0 else { return 0.0 }

        return distance / speed
    }

    // MARK: - Private Enums
    private enum Constants {
        static let targetDistance: Double = 500.0
    }

    // MARK: - Internal Funcs
    /// Computes progress towards next waypoint location, if any. This calculates a progress
    /// considering that the drone goes straight to the next waypoint from given location.
    /// Note that it will handle deviations from OA, but the bigger the detour is, the less precise result gets.
    ///
    /// - Parameters:
    ///    - currentLocation: location from which progress should be calculated
    /// - Returns: computed progress, 0.0 if no next waypoint or inconsistent data input.
    func navigateToNextProgress(with currentLocation: AGSPoint) -> Double {
        guard let nextWayPointLocation = nextWayPoint?.agsPoint,
              let distanceFromOrigin = AGSGeometryEngine.standardGeodeticDistance(between: currentLocation,
                                                                                  and: self.agsPoint),
              let distanceToDestination = AGSGeometryEngine.standardGeodeticDistance(between: currentLocation,
                                                                                     and: nextWayPointLocation) else { return 0.0 }

        return distanceFromOrigin.distance / (distanceFromOrigin.distance + distanceToDestination.distance)
    }

    /// Computes marker graphic for waypoint.
    /// Marker is a large circle and a small
    /// offseted circle for index display.
    ///
    /// - Parameters:
    ///    - index: waypoint's index
    /// - Returns: computed graphic
    func markerGraphic(index: Int) -> FlightPlanWayPointGraphic {
        return FlightPlanWayPointGraphic(wayPoint: self,
                                         index: index)
    }

    /// Computes arrow graphic for waypoint.
    ///
    /// - Parameters:
    ///    - index: waypoint's index
    /// - Returns: computed graphic
    func arrowGraphic(index: Int) -> FlightPlanWayPointArrowGraphic {
        return FlightPlanWayPointArrowGraphic(wayPoint: self,
                                              wayPointIndex: index,
                                              poiPoint: poiPoint,
                                              poiIndex: poiIndex,
                                              angle: Float(-yaw))
    }

    /// Computes label graphic for waypoint.
    /// Altitude is displayed in the large circle,
    /// index is displayed in the small offseted circle.
    ///
    /// - Parameters:
    ///    - index: waypoint's index
    /// - Returns: computed graphic
    func labelsGraphic(index: Int) -> FlightPlanWayPointLabelsGraphic {
        return FlightPlanWayPointLabelsGraphic(wayPoint: self,
                                                  index: index)
    }
}
