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

import UIKit
import CoreLocation
import GroundSdk

/// Class representing a FlightPlan Point Of Interest (POI).

public final class PoiPoint: Codable {
    // MARK: - Public Properties
    var index: Int?
    var color: Int
    var altitude: Double

    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }

    /// ROI MAVLink command.
    var mavlinkCommand: MavlinkStandard.SetRoiLocationCommand {
        return MavlinkStandard.SetRoiLocationCommand(latitude: latitude,
                                                     longitude: longitude,
                                                     altitude: altitude)
    }

    /// Returns altitude value with unit.
    var formattedAltitude: String {
        return UnitHelper.stringDistanceWithDouble(self.altitude, spacing: false)
    }

    /// Returns provider for point of interest settings.
    var settingsProvider: PoiPointSettingsProvider {
        return PoiPointSettingsProvider(poiPoint: self)
    }

    /// Related waypoints, if any.
    var wayPoints: [WayPoint]?

    // MARK: - Private Properties
    private var latitude: Double
    private var longitude: Double

    // MARK: - Private Enums
    enum CodingKeys: String, CodingKey {
        case index
        case color
        case latitude
        case longitude
        case altitude
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - coordinate: POI GPS coordinate
    ///    - altitude: POI altitude (in meters)
    ///    - color: POI color
    public init(coordinate: CLLocationCoordinate2D,
                altitude: Double,
                color: Int = 0) {
        self.index = -1
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.altitude = altitude
        self.color = color
        self.wayPoints = []
    }

    /// Init with Mavlink command.
    ///
    /// - Parameters:
    ///    - roiMavLinkCommand: ROI Mavlink location command
    public init(roiMavLinkCommand: MavlinkStandard.SetRoiLocationCommand) {
        self.index = -1
        self.latitude = roiMavLinkCommand.latitude
        self.longitude = roiMavLinkCommand.longitude
        self.altitude = roiMavLinkCommand.altitude
        self.color = 0
        self.wayPoints = []
    }

    /// Add POI Index.
    ///
    /// - Parameters:
    ///    - index: POI Index used as identifier
    public func addIndex(index: Int) {
        self.index = index
    }

    /// Assigns waypoint to point of interest.
    ///
    /// - Parameters:
    ///    - wayPoint: waypoint to assign
    func assignWayPoint(wayPoint: WayPoint?) {
        if let wayPoint = wayPoint {
            if self.wayPoints == nil {
                self.wayPoints = []
            }
            self.wayPoints?.append(wayPoint)
        }
    }

    /// Unassigns waypoints that do not match POI index
    func cleanWayPoints() {
        self.wayPoints?.removeAll(where: {
            $0.poiIndex != self.index
        })
    }
}
