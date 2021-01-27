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

// MARK: - Internal Enums
/// Public constants for flight plan display with ArcGIS.
enum FlightPlanAGSConstants {
    /// Key to store a point in graphic attributes.
    static let agsPointAttributeKey = "agsPoint"
    /// Key to store a draped point in graphic attribute.
    static let drapedAgsPointAttributeKey = "drapedAgsPoint"
    /// Key to store WayPoint index.
    static let wayPointIndexAttributeKey = "wayPointIndex"
    /// Key to store Poi index.
    static let poiIndexAttributeKey = "poiIndex"
    /// Key to store origin WayPoint index (for lines).
    static let lineOriginWayPointAttributeKey = "lineOriginWayPointIndex"
    /// Key to store destination WayPoint index (for lines).
    static let lineDestinationWayPointAttributeKey = "lineDestinationWayPointIndex"
    /// Key to store target Poi index (for Waypoints).
    static let targetPoiAttributeKey = "targetPoiIndex"
    /// Set of colors for point of interest's related graphcis.
    // TODO: define point of interest's colors.
    private static let colors: [UIColor] = [.orange,
                                            .systemPink,
                                            .yellow,
                                            .red,
                                            .purple]

    /// Returns color associated with given point of interest's index.
    ///
    /// - Parameters:
    ///    - index: point of interest's index
    static func colorForPoiIndex(_ index: Int) -> UIColor {
        return colors[index % colors.count]
    }
}

/// Type of the item.
/// Order determines priority for selection.
enum FlightPlanGraphicItemType: Int, CaseIterable {
    case wayPoint
    case poi
    case insertWayPoint
    case waypointArrow
    case lineWayPoint
    case lineWayPointToPoi
    case none

    /// Returns true if graphical object can be dragged on the map.
    var draggable: Bool {
        switch self {
        case .wayPoint, .poi, .waypointArrow:
            return true
        default:
            return false
        }
    }

    /// Returns true if graphical object can be selected for edition.
    var selectable: Bool {
        switch self {
        case .wayPoint,
             .poi,
             .insertWayPoint,
             .lineWayPoint:
            return true
        default:
            return false
        }
    }
}
