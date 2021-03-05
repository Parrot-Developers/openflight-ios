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

/// Graphic class for Flight Plan's waypoint's labels.

public final class FlightPlanWayPointLabelsGraphic: FlightPlanLabelGraphic {
    // MARK: - Override Properties
    override var itemType: FlightPlanGraphicItemType {
        return .lineWayPoint
    }
    override var mainLabel: AGSTextSymbol? {
        guard let compositeSymbol = self.symbol as? AGSCompositeSymbol else { return nil }

        return compositeSymbol.symbols.first as? AGSTextSymbol
    }

    // MARK: - Private Enums
    private enum Constants {
        static let mainTextColor: UIColor = ColorName.white.color
        static let mainTextSelectedColor: UIColor = ColorName.black.color
        static let subTextColor: UIColor = ColorName.black.color
        static let smallCircleOffset: CGFloat = 18.0
        static let mainLabelSize: CGFloat = 12.0
        static let subLabelSize: CGFloat = 8.0
        // Labels altitude should be offset to prevent from colliding with other graphics.
        static let textAltitudeOffset: Double = 0.05
        static let displayedIndexOffset: Int = 1
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - wayPoint: waypoint
    ///    - index: index of waypoint
    public convenience init(wayPoint: WayPoint, index: Int) {
        let agsPoint = wayPoint.agsPoint
        let mainLabel = AGSTextSymbol(text: wayPoint.formattedAltitude,
                                      color: Constants.mainTextColor,
                                      size: Constants.mainLabelSize,
                                      horizontalAlignment: .center,
                                      verticalAlignment: .middle)
        let subLabel = AGSTextSymbol(text: String(index + Constants.displayedIndexOffset),
                                     color: Constants.subTextColor,
                                     size: Constants.subLabelSize,
                                     horizontalAlignment: .center,
                                     verticalAlignment: .middle)
        subLabel.offsetX = Constants.smallCircleOffset
        subLabel.offsetY = Constants.smallCircleOffset
        let textsSymbol = AGSCompositeSymbol(symbols: [mainLabel, subLabel])
        let drapedPoint = agsPoint.withAltitude(Constants.textAltitudeOffset)
        let elevatedPoint = agsPoint.withAltitude(wayPoint.altitude + Constants.textAltitudeOffset)
        self.init(symbol: textsSymbol,
                  elevatedPoint: elevatedPoint,
                  drapedPoint: drapedPoint)
        self.attributes[FlightPlanAGSConstants.wayPointIndexAttributeKey] = index
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - location: waypoint's location
    public convenience init(location: Location3D) {
        let mainLabel = AGSTextSymbol(text: location.formattedAltitude,
                                      color: Constants.mainTextColor,
                                      size: Constants.mainLabelSize,
                                      horizontalAlignment: .center,
                                      verticalAlignment: .middle)
        let textsSymbol = AGSCompositeSymbol(symbols: [mainLabel])
        let drapedPoint = location.agsPoint.withAltitude(Constants.textAltitudeOffset)
        let elevatedPoint = location.agsPoint.withAltitude(location.altitude + Constants.textAltitudeOffset)
        self.init(symbol: textsSymbol,
                  elevatedPoint: elevatedPoint,
                  drapedPoint: drapedPoint)
        self.attributes[AGSConstants.wayPointAttributeKey] = true
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - symbol: graphic's symbol
    ///    - elevatedPoint: graphic's geometry for relative surface placement
    ///    - drapedPoint: graphic's geometry for draped surface placement
    private init(symbol: AGSSymbol?, elevatedPoint: AGSPoint, drapedPoint: AGSPoint) {
        super.init(geometry: drapedPoint,
                   symbol: symbol,
                   attributes: nil)
        self.attributes[FlightPlanAGSConstants.agsPointAttributeKey] = elevatedPoint
        self.attributes[FlightPlanAGSConstants.drapedAgsPointAttributeKey] = drapedPoint
    }

    // MARK: - Override Funcs
    override func updateColors(isSelected: Bool) {
        mainLabel?.color = isSelected ? Constants.mainTextSelectedColor : Constants.mainTextColor
    }
}

// MARK: - WayPointRelatedGraphic
extension FlightPlanWayPointLabelsGraphic: WayPointRelatedGraphic {
    func decrementWayPointIndex() {
        guard let index = wayPointIndex else {
            return
        }
        self.attributes[FlightPlanAGSConstants.wayPointIndexAttributeKey] = index - 1
        let indexLabel = (self.symbol as? AGSCompositeSymbol)?.symbols.last as? AGSTextSymbol
        indexLabel?.text = String(index - 1 + Constants.displayedIndexOffset)
    }

    func incrementWayPointIndex() {
        guard let index = wayPointIndex else { return }

        self.attributes[FlightPlanAGSConstants.wayPointIndexAttributeKey] = index + 1
        let indexLabel = (self.symbol as? AGSCompositeSymbol)?.symbols.last as? AGSTextSymbol
        indexLabel?.text = String(index + 1 + Constants.displayedIndexOffset)
    }
}
