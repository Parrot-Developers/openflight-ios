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
    /// Whether the associated poi is selected or not.
    public var poiIsSelected: Bool = false

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
        static let borderColor: UIColor = UIColor(red: 167.0/255.0, green: 167.0/255.0, blue: 167.0/255.0, alpha: 1.0)
        static let arrowSizeHeight: CGFloat = 26.0
        static let arrowSizeWidth: CGFloat = 25.0
        static let selectedArrowSizeHeight: CGFloat = 29.0
        static let selectedArrowSizeWidth: CGFloat = 30.0
        static let outlineColor: UIColor = ColorName.white.color
        static let arrowOffset: CGFloat = 33.0
        static let selectedArrowOffset: CGFloat = 41.0
        static let selectionCircleSize: CGFloat = 150.0
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
                                                                       isSelected: poiIsSelected)

        if isSelected {
            if poiPoint != nil {
                let triangleView = TriangleView(frame: CGRect(x: 0, y: 0,
                                                              width: !poiIsSelected ? Constants.selectedArrowSizeWidth : Constants.arrowSizeWidth,
                                                              height: !poiIsSelected ? Constants.selectedArrowSizeHeight : Constants.arrowSizeHeight),
                                                color: !poiIsSelected ? innerColor : Constants.selectedColor,
                                                externalColor: !poiIsSelected ? Constants.borderColor : Constants.outlineColor,
                                                selected: !poiIsSelected)

                arrow = AGSPictureMarkerSymbol(image: triangleView.asImage())
                arrow?.offsetY = !poiIsSelected ? Constants.selectedArrowOffset :  Constants.arrowOffset
            } else {
                let triangleView = TriangleView(frame: CGRect(x: 0, y: 0,
                                                              width: Constants.selectedArrowSizeWidth,
                                                              height: Constants.selectedArrowSizeHeight),
                                                color: Constants.selectedColor,
                                                externalColor: Constants.outlineColor,
                                                selected: true)
                arrow = AGSPictureMarkerSymbol(image: triangleView.asImage())
                arrow?.offsetY = Constants.selectedArrowOffset
            }
        } else {
            let triangleView = TriangleView(frame: CGRect(x: 0, y: 0, width: Constants.arrowSizeWidth,
                                                          height: Constants.arrowSizeHeight),
                                            color: poiPoint != nil ? innerColor : Constants.outlineColor,
                                            externalColor: poiPoint != nil ? Constants.outlineColor : Constants.borderColor, selected: false)

            arrow = AGSPictureMarkerSymbol(image: triangleView.asImage())
            arrow?.offsetY = Constants.arrowOffset
        }

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
        poiIsSelected = true
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
    private var externalColor: UIColor = .gray
    private var selected: Bool = false

    public init(frame: CGRect, color: UIColor, externalColor: UIColor = .gray, selected: Bool = false) {
        self.color = color
        self.externalColor = externalColor
        self.selected = selected
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override public func draw(_ rect: CGRect) {
        if !selected {
            // internal shape
            let shape = UIBezierPath()
            shape.move(to: CGPoint(x: 12.78, y: 0))
            shape.addLine(to: CGPoint(x: 25.55, y: 24.33))
            shape.addLine(to: CGPoint(x: 22.85, y: 23.06))
            shape.addCurve(to: CGPoint(x: 12.77, y: 20.81), controlPoint1: CGPoint(x: 19.79, y: 21.61), controlPoint2: CGPoint(x: 16.37, y: 20.81))
            shape.addCurve(to: CGPoint(x: 2.7, y: 23.05), controlPoint1: CGPoint(x: 9.17, y: 20.81), controlPoint2: CGPoint(x: 5.75, y: 21.61))
            shape.addLine(to: CGPoint(x: 0, y: 24.32))
            shape.addLine(to: CGPoint(x: 12.78, y: 0))
            shape.close()
            color.setFill()
            shape.fill()
            // external shape (border)
            shape.move(to: CGPoint(x: 2.27, y: 22.15))
            shape.addCurve(to: CGPoint(x: 3.73, y: 21.52), controlPoint1: CGPoint(x: 2.75, y: 21.92), controlPoint2: CGPoint(x: 3.24, y: 21.71))
            shape.addCurve(to: CGPoint(x: 12.77, y: 19.81), controlPoint1: CGPoint(x: 6.53, y: 20.41), controlPoint2: CGPoint(x: 9.58, y: 19.81))
            shape.addCurve(to: CGPoint(x: 21.81, y: 21.52), controlPoint1: CGPoint(x: 15.96, y: 19.81), controlPoint2: CGPoint(x: 19.01, y: 20.41))
            shape.addCurve(to: CGPoint(x: 23.27, y: 22.15), controlPoint1: CGPoint(x: 22.31, y: 21.71), controlPoint2: CGPoint(x: 22.79, y: 21.93))
            shape.addLine(to: CGPoint(x: 12.77, y: 2.15))
            shape.addLine(to: CGPoint(x: 2.27, y: 22.15))
            shape.close()
            externalColor.setFill()
            shape.fill()
        } else {

            let shape = UIBezierPath()
            shape.move(to: CGPoint(x: 15.75, y: 0.84))
            shape.addLine(to: CGPoint(x: 30.73, y: 29.74))
            shape.addLine(to: CGPoint(x: 28, y: 28.51))
            shape.addCurve(to: CGPoint(x: 15.75, y: 25.79), controlPoint1: CGPoint(x: 24.34, y: 26.84), controlPoint2: CGPoint(x: 20.01, y: 25.79))
            shape.addCurve(to: CGPoint(x: 3.52, y: 28.5), controlPoint1: CGPoint(x: 11.26, y: 25.79), controlPoint2: CGPoint(x: 7.3, y: 26.69))
            shape.addLine(to: CGPoint(x: 0.73, y: 29.84))
            shape.addLine(to: CGPoint(x: 15.75, y: 0.84))
            shape.close()
            color.setFill()
            shape.fill()
            shape.move(to: CGPoint(x: 3.08, y: 27.56))
            shape.addCurve(to: CGPoint(x: 4.6, y: 26.88), controlPoint1: CGPoint(x: 3.58, y: 27.32), controlPoint2: CGPoint(x: 4.09, y: 27.09))
            shape.addCurve(to: CGPoint(x: 15.75, y: 24.75), controlPoint1: CGPoint(x: 8.06, y: 25.45), controlPoint2: CGPoint(x: 11.71, y: 24.75))
            shape.addCurve(to: CGPoint(x: 26.94, y: 26.93), controlPoint1: CGPoint(x: 19.6, y: 24.75), controlPoint2: CGPoint(x: 23.5, y: 25.58))
            shape.addCurve(to: CGPoint(x: 28.43, y: 27.56), controlPoint1: CGPoint(x: 27.44, y: 27.13), controlPoint2: CGPoint(x: 27.94, y: 27.34))
            shape.addLine(to: CGPoint(x: 15.75, y: 3.09))
            shape.addLine(to: CGPoint(x: 3.08, y: 27.56))
            shape.close()

            externalColor.setFill()
            shape.fill()

        }
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
