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

import UIKit
import GroundSdk
import CoreLocation

/// Class representing a FlightPlan structure including waypoints, POIs, etc.
public final class FlightPlanObject: Codable {
    // MARK: - Public Properties
    public var takeoffActions: [Action]
    public var pois: [PoiPoint]
    public var wayPoints: [WayPoint]
    public var isBuckled: Bool?
    public var shouldContinue: Bool? = true
    public var lastPointRth: Bool? = false

    // MARK: - Internal Properties
    /// Return to launch MAVLink command, if FlightPlan is buckled.
    var returnToLaunchCommand: ReturnToLaunchCommand? {
        guard isBuckled == true else { return nil }
        return ReturnToLaunchCommand()
    }

    /// Returns true if drone should land on last waypoint.
    var shouldRthOnLastPoint: Bool {
        return lastPointRth == true
            && isBuckled != true
    }

    /// Returns Flight Plan photo count.
    var photoCount: Int {
        wayPoints
            .compactMap({ $0.actions })
            .reduce([], +)
            .filter({ $0.type == ActionType.imageStartCapture })
            .count
    }

    /// Returns Flight Plan video count.
    var videoCount: Int {
        wayPoints
            .compactMap({ $0.actions })
            .reduce([], +)
            .filter({ $0.type == ActionType.videoStartCapture })
            .count
    }

    // MARK: - Internal Enums
    enum CodingKeys: String, CodingKey {
        case takeoffActions = "takeoff"
        case wayPoints
        case pois = "poi"
        case isBuckled = "buckled"
        case shouldContinue = "continue"
        case lastPointRth = "RTH"
    }

    // MARK: - Init
    /// Init.
    init() {
        self.takeoffActions = []
        self.pois = []
        self.wayPoints = []
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - takeoffActions: actions to start on takeOff
    ///    - pois: POIs contained in FlightPlan
    ///    - wayPoints: wayPoints contained in FlightPlan
    public init(takeoffActions: [Action],
                pois: [PoiPoint],
                wayPoints: [WayPoint]) {
        self.takeoffActions = takeoffActions
        self.pois = pois
        self.wayPoints = wayPoints
    }

    // MARK: - Public Funcs
    /// Sets up global continue mode.
    ///
    /// - Parameters:
    ///    - shouldContinue: whether global continue mode should be activated
    func setShouldContinue(_ shouldContinue: Bool) {
        self.shouldContinue = shouldContinue
        // FIXME: for now, specific continue mode for each segment is not supported.
        self.wayPoints.forEach { $0.shouldContinue = shouldContinue }
    }

    /// Sets up return to home on last point setting.
    ///
    /// - Parameters:
    ///    - lastPointRth: whether drone should land on last waypoint
    func setLastPointRth(_ lastPointRth: Bool) {
        self.lastPointRth = lastPointRth
        self.wayPoints.last?.updateRTHAction(shouldRthOnLastPoint)
    }

    /// Adds a waypoint at the end of the Flight Plan.
    func addWaypoint(_ wayPoint: WayPoint) {
        let previous = wayPoints.last
        self.wayPoints.append(wayPoint)
        wayPoint.previousWayPoint = previous
        previous?.nextWayPoint = wayPoint
        previous?.updateRTHAction(false)
        wayPoint.updateRTHAction(shouldRthOnLastPoint)
        wayPoint.updateYawAndRelations()
    }

    /// Adds a point of interest to the Flight Plan.
    func addPoiPoint(_ poiPoint: PoiPoint) {
        self.pois.append(poiPoint)
    }

    /// Removes waypoint at given index.
    ///
    /// - Parameters:
    ///    - index: waypoint index
    /// - Returns: removed waypoint, if any
    @discardableResult
    func removeWaypoint(at index: Int) -> WayPoint? {
        guard index < self.wayPoints.count else { return nil }

        let isLastPoint = index == self.wayPoints.count - 1
        let wayPoint = self.wayPoints.remove(at: index)
        // Update previous and next waypoint yaw.
        let previous = wayPoint.previousWayPoint
        let next = wayPoint.nextWayPoint
        previous?.nextWayPoint = next
        next?.previousWayPoint = previous
        previous?.updateYaw()
        next?.updateYaw()
        // Update previous point if it is the new last point.
        if isLastPoint {
            previous?.updateRTHAction(shouldRthOnLastPoint)
        }
        return wayPoint
    }

    /// Removes point of interest at given index.
    ///
    /// - Parameters:
    ///    - index: point of interest index
    /// - Returns: removed point of interest, if any
    @discardableResult
    func removePoiPoint(at index: Int) -> PoiPoint? {
        guard index < self.pois.count else {
            return nil
        }
        wayPoints.forEach {
            guard let poiIndex = $0.poiIndex else { return }

            switch poiIndex {
            case index:
                $0.poiIndex = nil
                $0.poiPoint = nil
            case let supIdx where supIdx > index:
                $0.poiIndex = poiIndex - 1
            default:
                break
            }
        }
        return self.pois.remove(at: index)
    }

    /// Sets up initial relations between Flight Plan's objects.
    /// Should be called after creation.
    func setRelations() {
        var previousWayPoint: WayPoint?
        wayPoints.forEach { wayPoint in
            wayPoint.previousWayPoint = previousWayPoint
            if let poiIndex = wayPoint.poiIndex {
                wayPoint.poiPoint = pois.elementAt(index: poiIndex)
            }
            previousWayPoint?.nextWayPoint = wayPoint
            previousWayPoint = wayPoint
        }
    }
}
