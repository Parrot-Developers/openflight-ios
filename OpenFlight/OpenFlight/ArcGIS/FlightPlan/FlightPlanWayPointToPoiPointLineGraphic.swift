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

/// Graphic class for Flight Plan's waypoint to point of interest line.
final class FlightPlanWayPointToPoiLineGraphic: FlightPlanGraphic, PoiPointRelatedGraphic {
    // MARK: - Private Properties
    private var lineSymbol: AGSSimpleLineSymbol? {
        return symbol as? AGSSimpleLineSymbol
    }
    private var polyline: AGSPolyline? {
        return geometry as? AGSPolyline
    }

    // MARK: - Internal Properties
    /// Associated waypoint.
    private(set) weak var wayPoint: WayPoint?
    /// Associated point of interest.
    private(set) weak var poiPoint: PoiPoint?

    // MARK: - Override Properties
    override var itemType: FlightPlanGraphicItemType {
        return .lineWayPointToPoi
    }
    override var itemIndex: Int? {
        return attributes[FlightPlanAGSConstants.wayPointIndexAttributeKey] as? Int
    }

    // MARK: - Private Enums
    private enum Constants {
        static let selectedColor: UIColor = ColorName.greenSpring.color
        static let lineWidth: CGFloat = 3.0
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - wayPoint: the waypoint
    ///    - poiPoint: the point of interest
    ///    - wayPointIndex: waypoint's index
    ///    - poiIndex: point of interest's index
    init(wayPoint: WayPoint,
         poiPoint: PoiPoint,
         wayPointIndex: Int,
         poiIndex: Int) {
        let polyline = AGSPolyline(points: [wayPoint.agsPoint,
                                            poiPoint.agsPoint])
        let symbol = AGSSimpleLineSymbol(style: .dot,
                                         color: Constants.selectedColor,
                                         width: Constants.lineWidth)
        super.init(geometry: polyline,
                   symbol: symbol,
                   attributes: nil)

        self.wayPoint = wayPoint
        self.poiPoint = poiPoint
        self.attributes[FlightPlanAGSConstants.wayPointIndexAttributeKey] = wayPointIndex
        self.attributes[FlightPlanAGSConstants.poiIndexAttributeKey] = poiIndex
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - wayPointGraphic: waypoint's graphic
    ///    - poiPointGraphic: point of interest's graphic
    convenience init?(wayPointGraphic: FlightPlanWayPointGraphic,
                      poiPointGraphic: FlightPlanPoiPointGraphic) {
        guard let wayPoint = wayPointGraphic.wayPoint,
              let poiPoint = poiPointGraphic.poiPoint,
              let wpIndex = wayPointGraphic.itemIndex,
              let poiIndex = poiPointGraphic.itemIndex else {
            return nil
        }

        self.init(wayPoint: wayPoint,
                  poiPoint: poiPoint,
                  wayPointIndex: wpIndex,
                  poiIndex: poiIndex)
    }

    // MARK: - Public Funcs
    /// Updates waypoint location.
    ///
    /// - Parameters:
    ///    - wayPoint: waypoint's location
    func updateWayPoint(_ wayPoint: AGSPoint) {
        self.geometry = polyline?.replacingFirstPoint(wayPoint)
    }

    /// Updates point of interest location.
    ///
    /// - Parameters:
    ///    - poiPoint: point of interest's location
    func updatePoiPoint(_ poiPoint: AGSPoint) {
        self.geometry = polyline?.replacingLastPoint(poiPoint)
    }

    /// Decrements waypoint's index.
    func decrementWayPointIndex() {
        guard let index = itemIndex else { return }

        self.attributes[FlightPlanAGSConstants.wayPointIndexAttributeKey] = index - 1
    }

    /// Increments waypoint's index.
    func incrementWayPointIndex() {
        guard let index = itemIndex else { return }

        self.attributes[FlightPlanAGSConstants.wayPointIndexAttributeKey] = index + 1
    }
}
