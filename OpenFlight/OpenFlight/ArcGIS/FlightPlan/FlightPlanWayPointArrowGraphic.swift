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

import ArcGIS

/// Graphic class for Flight Plan's waypoint arrow.
final class FlightPlanWayPointArrowGraphic: FlightPlanPointGraphic, WayPointRelatedGraphic, PoiPointRelatedGraphic {
    // MARK: - Internal Properties
    /// Associated waypoint.
    private(set) var wayPoint: WayPoint?
    /// Target point of interest, if any.
    private(set) var poiPoint: PoiPoint?

    /// Symbols
    private var arrow: AGSPictureMarkerSymbol?
    private var selectionCircle: AGSSimpleMarkerSymbol?

    // MARK: - Override Properties
    override var itemType: FlightPlanGraphicItemType {
        return .waypointArrow
    }

    // MARK: - Private Enums
    private enum Constants {
        static let selectedColor: UIColor = ColorName.greenSpring.color
        static let arrowSizeHeight: CGFloat = 15.0
        static let arrowSizeWidth: CGFloat = 20.0
        static let outlineWidth: CGFloat = 2.0
        static let outlineColor: UIColor = ColorName.white.color
        static let arrowOffset: CGFloat = 36.0
        static let selectionCircleSize: CGFloat = arrowOffset * 2.0 + arrowSizeHeight / 2.0
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

        selectionCircle = AGSSimpleMarkerSymbol(style: .circle,
                                                color: .clear,
                                                size: Constants.selectionCircleSize)

        super.init(geometry: wayPoint.agsPoint,
                   symbol: nil,
                   attributes: nil)

        zIndex = Int(wayPoint.altitude)
        self.wayPoint = wayPoint
        self.poiPoint = poiPoint
        attributes[FlightPlanAGSConstants.wayPointIndexAttributeKey] = wayPointIndex
        attributes[FlightPlanAGSConstants.poiIndexAttributeKey] = poiIndex
        refreshArrow()
        symbol = getSymbol()
    }

    /// Get symbol
    ///
    /// - Returns: symbol
    private func getSymbol() -> AGSCompositeSymbol {
        var array = [AGSSymbol]()
        if let arrow = arrow {
            array.append(arrow)
        }
        if isSelected, let selectionCircle = selectionCircle {
            array.append(selectionCircle)
        }
        return AGSCompositeSymbol(symbols: array)
    }

    /// Refresh position and color of the arrow.
    private func refreshArrow() {
        let innerColor = FlightPlanWayPointArrowGraphic.innerColor(poiIndex: poiIndex,
                                                                   isSelected: isSelected)
        let triangleView = TriangleView(frame: CGRect(x: 0, y: 0, width: Constants.arrowSizeWidth,
                                                      height: Constants.arrowSizeHeight), color: innerColor)
        arrow = AGSPictureMarkerSymbol(image: triangleView.asImage())
        arrow?.offsetY = Constants.arrowOffset
        arrow?.angle = FlightPlanGraphic.Constants.rotationFactor * Float(wayPoint?.yaw ?? 0.0)
        arrow?.angleAlignment = .map
        self.symbol = getSymbol()
    }

    // MARK: - Override Funcs
    override func updateColors(isSelected: Bool) {
        refreshArrow()
    }

    override func updateAltitude(_ altitude: Double) {
        self.geometry = mapPoint?.withAltitude(altitude)
        zIndex = Int(altitude)
    }
}

// MARK: - Internal Funcs
extension FlightPlanWayPointArrowGraphic {
    /// Add a relation with point of interest.
    ///
    /// - Parameters:
    ///    - poiPointGraphic: point of interest's graphic
    func addPoiPoint(_ poiPointGraphic: FlightPlanPoiPointGraphic) {
        poiPoint = poiPointGraphic.poiPoint
        attributes[FlightPlanAGSConstants.poiIndexAttributeKey] = poiPointGraphic.poiIndex
        refreshOrientation()
    }

    /// Removes relation with point of interest.
    func removePoiPoint() {
        poiPoint = nil
        attributes.removeObject(forKey: FlightPlanAGSConstants.poiIndexAttributeKey)
        isSelected = false
        refreshOrientation()
    }

    /// Returns whether arrow orientation can be edited when touching given point.
    ///
    /// - Parameters:
    ///    - mapPoint: touch location
    /// - Returns: boolean indicating result
    func isOrientationEditionAllowed(_ mapPoint: AGSPoint) -> Bool {
        // Assuming arrow is not editable if yaw is nil.
        guard poiPoint == nil,
              let wayPoint = wayPoint,
              let yaw = wayPoint.yaw else {
            return false
        }

        // Checks if yaw for given point is in an acceptable field of view from current
        // waypoint's perspective (if user is trying to touch the arrow graphic).
        let newYaw = AGSGeometryEngine.standardGeodeticDistance(between: wayPoint.agsPoint,
                                                                and: mapPoint,
                                                                azimuthUnit: .degrees())?.azimuth1 ?? 0.0

        return newYaw.asPositiveDegrees.isCloseTo(yaw,
                                                  withDelta: Constants.yawEditionTolerance)
    }

    /// Refreshes arrow orientation with associated `WayPoint` object.
    func refreshOrientation() {
        refreshArrow()
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

// Generate a triangle view to add to waypoint
public class TriangleView: UIView {
    private var color: UIColor = .white
    private var externalColor: UIColor = .white
    private var borderSize: CGFloat = 2.0

    public init(frame: CGRect, color: UIColor, externalColor: UIColor = .white, borderSize: CGFloat = 2.0) {
        self.color = color
        self.externalColor = externalColor
        self.borderSize = borderSize
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override public func draw(_ rect: CGRect) {
        let drawSize = CGSize(width: rect.width, height: rect.height)
        let trianglePath = UIBezierPath()
        trianglePath.move(to: CGPoint(x: drawSize.width / 2, y: borderSize))
        trianglePath.addLine(to: CGPoint(x: borderSize, y: drawSize.height - borderSize))
        trianglePath.addLine(to: CGPoint(x: drawSize.width - borderSize,
                                         y: drawSize.height - borderSize))

        trianglePath.lineWidth = borderSize
        trianglePath.close()
        color.setFill()
        externalColor.setStroke()
        trianglePath.stroke()
        trianglePath.fill()
    }

    func asImage() -> UIImage {
        self.isOpaque = false
        self.layer.isOpaque = false
        self.layer.backgroundColor = UIColor.clear.cgColor
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
