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

import ArcGIS
import GroundSdk

private extension ULogTag {
    static let tag = ULogTag(name: "FlightPlanDataSetting.ArcGIS")
}

/// Utility extension for `FlightPlanObject` usage with ArcGIS.
extension FlightPlanDataSetting {
    // MARK: - Public Properties
    /// Returns plan estimations.
    public var estimations: FlightPlanEstimationsModel {
        let estimations = FlightPlanEstimationsModel()
        var lastPoint: WayPoint?
        var totalDistance: Double = 0.0
        var totalTime: TimeInterval = 0.0

        let verticalSpeedUp = 4.0
        let verticalSpeedDown = -3.0
        /// Max acceleration. Should be different from 0
        let maxAcceleration = 1.5
        /// Min speed. Should be different from 0
        var speedMin = 0.5
        if let speedSettingMin = SpeedSettingType().allValues.first, speedSettingMin != 0 {
            speedMin = Double(speedSettingMin) * SpeedSettingType().divider
        }
        var speedMax = 14.0
        if let speedSettingMax = SpeedSettingType().allValues.last, speedSettingMax != 0 {
            speedMax = Double(speedSettingMax) * SpeedSettingType().divider
        }
        if obstacleAvoidanceActivated, speedMax > 8.0 {
            speedMax = 8.0
        }

        wayPoints.forEach { wayPoint in
            if let lastPoint = lastPoint {
                let speedReference = wayPoint.speed * SpeedSettingType().divider
                let distance = lastPoint.agsPoint.distanceToPoint(wayPoint.agsPoint)
                let speedClamped = clampVelocity(firstPoint: lastPoint, secondPoint: wayPoint,
                                                    speed: speedReference, speedMin: speedMin, speedMax: speedMax,
                                                    verticalSpeedUp: verticalSpeedUp,
                                                    verticalSpeedDown: verticalSpeedDown)

                let speedBound = maxReachableSpeed(distance: distance, accelerationMax: maxAcceleration,
                                                   speedMin: speedMin)

                let speed = min(speedClamped, speedBound)
                let pieceDuration = pieceDurationPessimistic(distance: distance,
                                                             speed: (speed != 0 ? speed : speedMin),
                                                             accelerationMax: maxAcceleration)
                totalTime += pieceDuration
                totalDistance += distance
            }
            lastPoint = wayPoint
        }
        estimations.distance = totalDistance
        estimations.duration = totalTime
        // TODO: memory size in next gerrit (need more informations)

        return estimations
    }

    /// Clamp velocity into the feasible speed
    ///
    /// - Parameters:
    ///     - firstPoint: first way point
    ///     - secondPoint: second way point
    ///     - speed: speed to apply
    ///     - speedMin: minimum speed available
    ///     - speedMax: maximum speed available
    ///     - verticalSpeedUp: vertical speed up
    ///     - verticalSpeedDown: vertical speed down
    private func clampVelocity(firstPoint: WayPoint,
                               secondPoint: WayPoint,
                               speed: Double,
                               speedMin: Double,
                               speedMax: Double,
                               verticalSpeedUp: Double,
                               verticalSpeedDown: Double) -> Double {
        var clampSpeed = (speedMin...speedMax).clamp(speed)
        let distance = firstPoint.agsPoint.distanceToPoint(secondPoint.agsPoint)
        if clampSpeed != 0, distance != 0 {
            let verticalVelocity = clampSpeed * (secondPoint.altitude - firstPoint.altitude) / distance
            let clampedVerticalVelocity = (verticalSpeedDown...verticalSpeedUp).clamp(verticalVelocity)
            if verticalVelocity != 0 {
                clampSpeed *= clampedVerticalVelocity / verticalVelocity
            }
        }

        return clampSpeed
    }

    /// Max reachable speed
    ///
    /// - Parameters:
    ///     - distance: distance
    ///     - accelerationMax: maximum acceleration
    ///     - speedMin: minimum  speed
    private func maxReachableSpeed(distance: Double, accelerationMax: Double, speedMin: Double) -> Double {
        return max(sqrt(accelerationMax * distance / 3.0), speedMin)
    }

    /// Pessimistic estimation of the duration to travel a given distance at a given speed
    ///
    /// - Parameters:
    ///     - distance: distance
    ///     - speed: speed, should be different from 0
    ///     - accelerationMax: maximum acceleration, should be different from 0
    private func pieceDurationPessimistic(distance: Double, speed: Double, accelerationMax: Double) -> Double {
        if distance > (pow(speed, 2) / accelerationMax) {
            return distance / speed + speed / accelerationMax
        } else {
            return 2.0 * sqrt(distance / accelerationMax)
        }
    }

    // MARK: - Internal Properties
    /// Returns an array with all lines graphics.
    /// - Parameters:
    ///     - mapMode: The current map mode
    func allLinesGraphics() -> [FlightPlanWayPointLineGraphic] {
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
    /// - Parameters:
    ///     - mapMode: The current map mode
    func allLinesAndMarkersGraphics(mapMode: MapMode) -> [FlightPlanGraphic] {
        return allLinesGraphics()
            + waypointsArrowGraphics
            + waypointsMarkersGraphics(mapMode: mapMode)
            + poisMarkersGraphics
    }

    /// Returns an array with all flight plan's lines and waypoints.
    /// - Parameters:
    ///     - mapMode: The current map mode
    func linesAndWaypointsGraphics(mapMode: MapMode) -> [FlightPlanGraphic] {
        return allLinesGraphics() + waypointsMarkersGraphics(mapMode: mapMode)
    }

    /// Returns ArcGis graphics generation result.
    ///
    /// - Parameters:
    ///    - mapMode: the current map mode
    ///    - graphicsMode: the graphics mode
    /// - Returns: the `FlightPlanGraphicsGenerationResult`
    ///
    /// - Note: it would be better to have only one loop to generate WP related graphics
    ///         but performing in several steps allows to display the minimum needed graphics in case of low memory.
    @MainActor
    func graphics(for mapMode: MapMode,
                  graphicsMode: FlightPlanGraphicsMode) async -> FlightPlanGraphicsGenerationResult {
        var graphics = [FlightPlanGraphic]()

        // Generate trajectory lines.
        for (index, wayPoint) in wayPoints.enumerated() {
            guard let next = wayPoint.nextWayPoint else { continue }
            graphics.append(FlightPlanWayPointLineGraphic(origin: wayPoint,
                                                          destination: next,
                                                          originIndex: index))
            if Task.isCancelled {
                ULog.i(.tag, "Cancelling trajectory graphics generation at index \(index) (WP count: \(wayPoints.count).")
                return .failed
            }
        }

        // Generate trajectory arrows if needed (in `.myFlights` the arrows are never shown).
        if graphicsMode.isArrowIncluded && mapMode != .myFlights {
            for (index, wayPoint) in wayPoints.enumerated() {
                graphics.append(wayPoint.arrowGraphic(index: index))
                if Task.isCancelled {
                    ULog.i(.tag, "Cancelling trajectory arrows generation at index \(index) (WP count: \(wayPoints.count).")
                    // Task has been cancelled but we can still want to display only the trajactory line
                    // (e.g. in case of low memory warning).
                    return .init(partially: .onlyTrajectory, graphics: graphics)
                }
            }
        }

        // Generate WP markers if needed.
        if graphicsMode.isWayPointMarkersIncluded {
            for (index, wayPoint) in wayPoints.enumerated() {
                graphics .append(wayPoint.markerGraphic(index: index, isDetail: mapMode == .myFlights))
                if Task.isCancelled {
                    ULog.i(.tag, "Cancelling way points generation at index \(index) (WP count: \(wayPoints.count).")
                    let mode: FlightPlanGraphicsMode = graphicsMode.isArrowIncluded ? .trajectoryAndArrows : .onlyTrajectory
                    return .init(partially: mode, graphics: graphics)
                }
            }
        }

        // Generate POI markers if needed (in `.myFlights` the arrows are never shown).
        if graphicsMode.isPoiMarkersIncluded && mapMode != .myFlights {
            for (index, poiPoint) in pois.enumerated() {
                graphics .append(poiPoint.markerGraphic(index: index))
                if Task.isCancelled {
                    ULog.i(.tag, "Cancelling pois generation at index \(index) (WP count: \(wayPoints.count).")
                    return .init(status: .incompletePois, graphics: graphics)
                }
            }
        }

        return .init(succeeded: graphics)
    }

    /// Returns a simple `AGSPolyline` with all points.
    var polyline: AGSPolyline {
        return AGSPolyline(points: wayPoints.compactMap { return $0.agsPoint }
            + pois.compactMap { return $0.agsPoint })
    }

    // MARK: - Private Properties
    /// Returns an array with waypoints' markers graphics.
    /// - Parameters:
    ///     - mapMode: The current map mode
    private func waypointsMarkersGraphics(mapMode: MapMode) -> [FlightPlanWayPointGraphic] {
        return wayPoints
            .enumerated()
            .map { (index, wayPoint) in
                wayPoint.markerGraphic(index: index, isDetail: mapMode == .myFlights)
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

    /// Returns an array with pois' markers graphics.
    private var poisMarkersGraphics: [FlightPlanPoiPointGraphic] {
        return pois
            .enumerated()
            .map { (index, poiPoint) in
                poiPoint.markerGraphic(index: index)
        }
    }

    /// Returns weight of all waypoint segments (the fraction of the total distance corresponding to
    /// each segment of the Flight Plan).
    private var segmentWeights: [Double] {
        guard let totalDistance = estimations.distance else { return [] }

        return wayPoints.map { $0.navigateToNextDistance / totalDistance }
    }

    /// Computes current Flight Plan progress with given location and last waypoint index.
    ///
    /// - Parameters:
    ///    - currentLocation: location from which progress should be calculated
    ///    - lastWayPointIndex: index of the last passed waypoint
    /// - Returns: global Flight Plan progress, from 0.0 to 1.0.
    func completionProgress(with currentLocation: AGSPoint?, lastWayPointIndex: Int) -> Double {
        guard !wayPoints.isEmpty,
              (0...wayPoints.count-1).contains(lastWayPointIndex) else { return 0.0 }

        // Percentage of completion of the current segment being traveled
        var currentSegmentProgress: Double
        if let currentLocation = currentLocation {
            currentSegmentProgress = self.wayPoints[lastWayPointIndex].navigateToNextProgress(with: currentLocation)
        } else {
            currentSegmentProgress = 0
        }

        // Percentage of completion up to the last validated waypoint
        let progressAtWayPoint = self.segmentWeights
            .prefix(lastWayPointIndex)
            .reduce(0.0) { return $0 + $1 }

        // Sum of the progress up to the last validated waypoint
        // and the weighted progress of the segment being traveled
        let currentProgress = progressAtWayPoint + segmentWeights[lastWayPointIndex] * currentSegmentProgress
        return (0.0...1.0).clamp(currentProgress)
    }
}
