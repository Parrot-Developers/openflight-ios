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

/// Utility extension for `FlightPlanObject` usage with ArcGIS.
extension FlightPlanObject {
    // MARK: - Public Properties
    /// Returns plan estimations.
    public var estimations: FlightPlanEstimationsModel {
        var estimations = FlightPlanEstimationsModel()
        var lastPoint: WayPoint?
        var totalDistance: Double = 0.0
        var totalTime: TimeInterval = 0.0
        wayPoints
            .forEach { wayPoint in
                if let lastPoint = lastPoint {
                    let distance = lastPoint.agsPoint.distanceToPoint(wayPoint.agsPoint)
                    totalTime += distance / lastPoint.speed
                    totalDistance += distance
                }
                lastPoint = wayPoint
            }
        estimations.distance = totalDistance
        estimations.duration = totalTime
        // TODO: memory size in next gerrit (need more informations)

        return estimations
    }

    // MARK: - Internal Properties
    /// Returns an array with all lines graphics.
    var allLinesGraphics: [FlightPlanWayPointLineGraphic] {
        return wayPoints
            .enumerated()
            .compactMap { (index, point) in
                guard let next = point.nextWayPoint else { return nil }

                return FlightPlanWayPointLineGraphic(origin: point,
                                                     destination: next,
                                                     originIndex: index)
            }
    }

    /// Returns last waypoint line graphic.
    var lastLineGraphic: FlightPlanWayPointLineGraphic? {
        guard wayPoints.count >= 2 else {
            return nil
        }
        let originIndex = wayPoints.count-2
        let waypointA = wayPoints[originIndex]
        let waypointB = wayPoints[originIndex+1]
        return FlightPlanWayPointLineGraphic(origin: waypointA,
                                             destination: waypointB,
                                             originIndex: originIndex)
    }

    /// Returns an array with all flight plan's graphics, except labels.
    var allLinesAndMarkersGraphics: [FlightPlanGraphic] {
        return allLinesGraphics
            + waypointsMarkersGraphics
            + waypointsArrowGraphics
            + poisMarkersGraphics
    }

    /// Returns an array with all flight plan's labels graphics.
    var allLabelsGraphics: [FlightPlanLabelGraphic] {
        return waypointsLabelsGraphics + poiLabelsGraphics
    }

    /// Returns a simple `AGSPolyline` with all points.
    var polyline: AGSPolyline {
        return AGSPolyline(points: wayPoints.compactMap { return $0.agsPoint }
            + pois.compactMap { return $0.agsPoint })
    }

    // MARK: - Private Properties
    /// Returns an array with waypoints' markers graphics.
    private var waypointsMarkersGraphics: [FlightPlanWayPointGraphic] {
        return wayPoints
            .enumerated()
            .map { (index, wayPoint) in
                wayPoint.markerGraphic(index: index)
        }
    }

    /// Returns an array with waypoints' arrows graphics.
    private var waypointsArrowGraphics: [FlightPlanWayPointArrowGraphic] {
        return wayPoints
            .enumerated()
            .map { (index, wayPoint) in
                wayPoint.arrowGraphic(index: index)
        }
    }

    /// Returns an array with waypoints' labels graphics.
    private var waypointsLabelsGraphics: [FlightPlanWayPointLabelsGraphic] {
        return wayPoints
            .enumerated()
            .map { (index, wayPoint) in
                wayPoint.labelsGraphic(index: index)
        }
    }

    /// Returns an array with pois' markers graphics.
    private var poisMarkersGraphics: [FlightPlanPoiPointGraphic] {
        return pois
            .enumerated()
            .map { (index, poiPoint) in
                poiPoint.markerGraphic(index: index)
        }
    }

    /// Returns an array with pois' labels graphics.
    private var poiLabelsGraphics: [FlightPlanPoiPointLabelGraphic] {
        return pois
            .enumerated()
            .map { (index, poiPoint) in
                poiPoint.labelGraphic(index: index)
        }
    }

    /// Returns weight of all waypoint segments (a fraction representing their
    /// relative duration inside the entire Flight Plan).
    private var segmentWeights: [Double] {
        guard let totalDuration = estimations.duration else { return [] }

        return wayPoints.map { $0.navigateToNextDuration / totalDuration }
    }

    // MARK: - Public Funcs
    /// Computes all lines towards point of interest at given index.
    ///
    /// - Parameters:
    ///    - poiIndex: point of interest's index
    /// - Returns: computed line graphics
    func wayPointToPoiLinesGraphic(poiIndex: Int) -> [FlightPlanWayPointToPoiLineGraphic] {
        let poiPoint = pois[poiIndex]
        return wayPoints
            .enumerated()
            .filter { $1.poiIndex == poiIndex }
            .compactMap { (index, wayPoint) in
                return FlightPlanWayPointToPoiLineGraphic(wayPoint: wayPoint,
                                                          poiPoint: poiPoint,
                                                          wayPointIndex: index,
                                                          poiIndex: poiIndex)
        }
    }

    /// Inserts a waypoint at given index.
    ///
    /// - Parameters:
    ///    - mapPoint: location of the new waypoint
    ///    - index: index at which waypoint should be inserted
    /// - Returns: new waypoint, nil if index is invalid
    func insertWayPoint(with mapPoint: AGSPoint,
                        at index: Int) -> WayPoint? {
        guard index > 0,
              index < wayPoints.count,
              let previousWayPoint = wayPoints.elementAt(index: index - 1),
              let nextWayPoint = wayPoints.elementAt(index: index) else { return nil }

        let tilt = (previousWayPoint.tilt + nextWayPoint.tilt) / 2.0

        // Create new waypoint.
        let wayPoint = WayPoint(coordinate: mapPoint.toCLLocationCoordinate2D(),
                                altitude: mapPoint.z,
                                speed: nextWayPoint.speed,
                                shouldContinue: self.shouldContinue ?? true,
                                tilt: tilt.rounded())

        // Associate waypoints.
        previousWayPoint.nextWayPoint = wayPoint
        nextWayPoint.previousWayPoint = wayPoint
        wayPoint.previousWayPoint = previousWayPoint
        wayPoint.nextWayPoint = nextWayPoint

        // Insert in array.
        self.wayPoints.insert(wayPoint, at: index)

        // Update yaws.
        previousWayPoint.updateYaw()
        nextWayPoint.updateYaw()
        wayPoint.updateYaw()

        return wayPoint
    }

    /// Computes current Flight Plan progress with given location and last waypoint index.
    ///
    /// - Parameters:
    ///    - currentLocation: location from which progress should be calculated
    ///    - lastWayPointIndex: index of the last passed waypoint
    /// - Returns: global Flight Plan progress, from 0.0 to 1.0.
    func completionProgress(with currentLocation: AGSPoint, lastWayPointIndex: Int) -> Double {
        guard !wayPoints.isEmpty,
              (0...wayPoints.count-1).contains(lastWayPointIndex) else { return 0.0 }

        let currentSegmentProgress = self.wayPoints[lastWayPointIndex].navigateToNextProgress(with: currentLocation)
        let progressAtWayPoint = self.segmentWeights
            .prefix(lastWayPointIndex)
            .reduce(0.0) { return $0 + $1 }

        return (0.0...1.0).clamp(progressAtWayPoint + segmentWeights[lastWayPointIndex] * currentSegmentProgress)
    }
}
