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

/// Graphic class for Flight Plan's waypoint arrow.
final class FlightPlanWayPointArrowGraphic: FlightPlanPointGraphic, WayPointRelatedGraphic, PoiPointRelatedGraphic {
    // MARK: - Internal Properties
    /// Graphic's orientation (in degrees).
    var angle: Float? {
        get {
            guard let angle = arrowSymbol?.angle else { return nil }

            return angle - Constants.arcGisAngleOffset
        }
        set {
            arrowSymbol?.angle = (newValue ?? 0.0) + Constants.arcGisAngleOffset
        }
    }
    /// Associated waypoint.
    private(set) weak var wayPoint: WayPoint?
    /// Target point of interest, if any.
    private(set) weak var poiPoint: PoiPoint?

    // MARK: - Private Properties
    private var arrowSymbol: AGSSimpleMarkerSymbol? {
        guard let compositeSymbol = symbol as? AGSCompositeSymbol else { return nil }

        return compositeSymbol.symbols
            .compactMap { $0 as? AGSSimpleMarkerSymbol }
            .first(where: { $0.style == .triangle })
    }

    // MARK: - Override Properties
    override var itemType: FlightPlanGraphicItemType {
        return .waypointArrow
    }

    // MARK: - Private Enums
    private enum Constants {
        /// Angle for ArcGIS symbols are defined with a 90 degrees offset compared to cartesian angles.
        static let arcGisAngleOffset: Float = 90.0
        static let selectedColor: UIColor = ColorName.greenSpring.color
        static let arrowSize: CGFloat = 22.0
        static let outlineWidth: CGFloat = 2.0
        static let outlineColor: UIColor = ColorName.white.color
        static let arrowOffset: CGFloat = 40.0
        static let selectionCircleSize: CGFloat = arrowOffset * 2.0 + arrowSize / 2.0
        static let yawEditionTolerance: Double = 30.0
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - wayPoint: the waypoint
    ///    - wayPointIndex: waypoint's index
    ///    - poiPoint: target point of interest, if any
    ///    - poiIndex: point of interest's index, if any
    ///    - angle: graphic's orientation (in degrees)
    init(wayPoint: WayPoint,
         wayPointIndex: Int,
         poiPoint: PoiPoint? = nil,
         poiIndex: Int? = nil,
         angle: Float) {
        let innerColor = FlightPlanWayPointArrowGraphic.innerColor(poiIndex: poiIndex,
                                                                   isSelected: false)
        let arrow = AGSSimpleMarkerSymbol(style: .triangle,
                                          color: innerColor,
                                          size: Constants.arrowSize)
        arrow.outline = AGSSimpleLineSymbol(style: .solid,
                                            color: Constants.outlineColor,
                                            width: Constants.outlineWidth)
        arrow.offsetY = Constants.arrowOffset
        arrow.angle = angle + Constants.arcGisAngleOffset

        let selectionCircle = AGSSimpleMarkerSymbol(style: .circle,
                                                    color: .clear,
                                                    size: Constants.selectionCircleSize)

        let compositeSymbol = AGSCompositeSymbol(symbols: [arrow, selectionCircle])

        super.init(geometry: wayPoint.agsPoint,
                   symbol: compositeSymbol,
                   attributes: nil)

        self.wayPoint = wayPoint
        self.poiPoint = poiPoint
        self.attributes[FlightPlanAGSConstants.wayPointIndexAttributeKey] = wayPointIndex
        self.attributes[FlightPlanAGSConstants.poiIndexAttributeKey] = poiIndex
    }

    // MARK: - Override Funcs
    override func updateColors(isSelected: Bool) {
        arrowSymbol?.color = FlightPlanWayPointArrowGraphic.innerColor(poiIndex: poiIndex,
                                                                       isSelected: isSelected)
    }

    override func updateAltitude(_ altitude: Double) {
        self.geometry = mapPoint?.withAltitude(altitude)
    }
}

// MARK: - Internal Funcs
extension FlightPlanWayPointArrowGraphic {
    /// Add a relation with point of interest.
    ///
    /// - Parameters:
    ///    - poiPointGraphic: point of interest's graphic
    func addPoiPoint(_ poiPointGraphic: FlightPlanPoiPointGraphic) {
        self.poiPoint = poiPointGraphic.poiPoint
        self.attributes[FlightPlanAGSConstants.poiIndexAttributeKey] = poiPointGraphic.poiIndex
    }

    /// Removes relation with point of interest.
    func removePoiPoint() {
        self.poiPoint = nil
        self.attributes.removeObject(forKey: FlightPlanAGSConstants.poiIndexAttributeKey)
        self.isSelected = false
    }

    /// Returns whether arrow orientation can be edited when touching given point.
    ///
    /// - Parameters:
    ///    - mapPoint: touch location
    /// - Returns: boolean indicating result
    func isOrientationEditionAllowed(_ mapPoint: AGSPoint) -> Bool {
        guard poiPoint == nil,
              let wayPoint = wayPoint else {
            return false
        }

        // Checks if yaw for given point is in an acceptable field of view from current
        // waypoint's perspective (if user is trying to touch the arrow graphic).
        let newYaw = AGSGeometryEngine.standardGeodeticDistance(between: wayPoint.agsPoint,
                                                                and: mapPoint,
                                                                azimuthUnit: .degrees())?.azimuth1 ?? 0.0

        return newYaw.asPositiveDegrees.isCloseTo(wayPoint.yaw,
                                                  withDelta: Constants.yawEditionTolerance)
    }
}

// MARK: - Private Funcs
private extension FlightPlanWayPointArrowGraphic {
    /// Returns color for inner part of the arrow.
    ///
    /// - Parameters:
    ///    - poiIndex: index of current poi
    ///    - isSelected: whether arrow is currently selected
    /// - Returns: color for inner part
    static func innerColor(poiIndex: Int?, isSelected: Bool) -> UIColor {
        if isSelected {
            return Constants.selectedColor
        } else if let poiIndex = poiIndex {
            return FlightPlanAGSConstants.colorForPoiIndex(poiIndex)
        } else {
            return Constants.outlineColor
        }
    }
}
