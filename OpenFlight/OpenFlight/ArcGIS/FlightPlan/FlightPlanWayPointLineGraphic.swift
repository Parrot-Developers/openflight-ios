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

/// Graphic class for Flight Plan's waypoint line.
public final class FlightPlanWayPointLineGraphic: FlightPlanGraphic {
    // MARK: - Internal Properties
    /// Returns middle point of the line.
    var middlePoint: AGSPoint? {
        return polyline?.middlePoint
    }
    /// Origin waypoint.
    private(set) weak var originWayPoint: WayPoint?
    /// Destination waypoint.
    private(set) weak var destinationWayPoint: WayPoint?

    // MARK: - Private Properties
    private var lineSymbol: AGSSimpleLineSymbol? {
        guard let compositeSymbol = symbol as? AGSCompositeSymbol else { return nil }

        return compositeSymbol.symbols
            .compactMap { $0 as? AGSSimpleLineSymbol }
            .last(where: { $0.style == .solid })
    }
    private var polyline: AGSPolyline? {
        return geometry as? AGSPolyline
    }

    // MARK: - Override Properties
    override var itemType: FlightPlanGraphicItemType {
        return .lineWayPoint
    }

    // MARK: - Private Enums
    private enum Constants {
        static let defaultColor: UIColor = ColorName.blueDodger.color
        static let selectedColor: UIColor = ColorName.greenSpring.color
        static let touchAreaColor: UIColor = .clear
        static let lineWidth: CGFloat = 2.0
        static let lineWidthTouchArea: CGFloat = 20.0
        static let invisibleLineWidth: CGFloat = 40.0
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - origin: origin waypoint
    ///    - destination: destination waypoint
    ///    - originIndex: index of the origin waypoint
    init(origin: WayPoint,
         destination: WayPoint,
         originIndex: Int) {
        let polyline = AGSPolyline(points: [origin.agsPoint,
                                            destination.agsPoint])

        // Symbol used to make touch area bigger, invisible.
        let symbolTouchArea = AGSSimpleLineSymbol(style: .solid,
                                                  color: Constants.touchAreaColor,
                                                  width: Constants.lineWidthTouchArea)
        // visible line
        let symbol = AGSSimpleLineSymbol(style: .solid,
                                         color: Constants.defaultColor,
                                         width: Constants.lineWidth)

        // Larger invisible line symbol is created to ease graphic selection (workaround
        // due to ArcGIS not handling identify tolerance properly on line graphics).
        let invisibleSymbol = AGSSimpleLineSymbol(style: .null,
                                                  color: UIColor.clear,
                                                  width: Constants.invisibleLineWidth)

        let compositeSymbol = AGSCompositeSymbol(symbols: [symbolTouchArea, symbol, invisibleSymbol])

        super.init(geometry: polyline,
                   symbol: compositeSymbol,
                   attributes: nil)

        originWayPoint = origin
        destinationWayPoint = destination
        attributes[FlightPlanAGSConstants.lineOriginWayPointAttributeKey] = originIndex
        attributes[FlightPlanAGSConstants.lineDestinationWayPointAttributeKey] = originIndex + 1
    }

    // MARK: - Override Funcs
    override func updateColors(isSelected: Bool) {
        lineSymbol?.color = isSelected
            ? Constants.selectedColor
            : Constants.defaultColor
    }

    // MARK: - Public Funcs
    /// Updates polyline start point.
    ///
    /// - Parameters:
    ///    - startPoint: new start point
    func updateStartPoint(_ startPoint: AGSPoint) {
        geometry = polyline?.replacingFirstPoint(startPoint)
    }

    /// Updates polyline end point.
    ///
    /// - Parameters:
    ///    - endPoint: new end point
    func updateEndPoint(_ endPoint: AGSPoint) {
        geometry = polyline?.replacingLastPoint(endPoint)
    }
}

// MARK: WayPointRelatedGraphic
extension FlightPlanWayPointLineGraphic: WayPointRelatedGraphic {
    /// Waypoint's index.
    ///
    /// Note: in waypoint line case, index is the index of origin waypoint.
    var wayPointIndex: Int? {
        get {
            return attributes[FlightPlanAGSConstants.lineOriginWayPointAttributeKey] as? Int
        }
        set {
            attributes[FlightPlanAGSConstants.lineOriginWayPointAttributeKey] = newValue
        }
    }

    /// Increments waypoint's index.
    ///
    /// Note: in waypoint line case, this increments both related waypoints.
    func incrementWayPointIndex() {
        guard let index = wayPointIndex else { return }

        attributes[FlightPlanAGSConstants.lineOriginWayPointAttributeKey] = index + 1
        attributes[FlightPlanAGSConstants.lineDestinationWayPointAttributeKey] = index + 2
    }

    /// Decrements waypoint's index.
    ///
    /// Note: in waypoint line case, this decrements both related waypoints.
    func decrementWayPointIndex() {
        guard let index = wayPointIndex,
              index > 0 else {
            return
        }

        attributes[FlightPlanAGSConstants.lineOriginWayPointAttributeKey] = index - 1
        attributes[FlightPlanAGSConstants.lineDestinationWayPointAttributeKey] = index
    }
}
