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

/// Graphic class for Flight Plan's point of interest's label.

public final class FlightPlanPoiPointLabelGraphic: FlightPlanLabelGraphic, PoiPointRelatedGraphic {
    // MARK: - Override Properties
    override var itemType: FlightPlanGraphicItemType {
        return .poi
    }
    override var mainLabel: AGSTextSymbol? {
        return self.symbol as? AGSTextSymbol
    }

    // MARK: - Private Enums
    private enum Constants {
        static let textColor: UIColor = ColorName.black.color
        static let labelSize: CGFloat = 12.0
        // Labels altitude should be offset to prevent from colliding with other graphics.
        static let textAltitudeOffset: Double = 0.05
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - poiPoint: point of interest
    ///    - index: index of point of interest
    public convenience init(poiPoint: PoiPoint, index: Int) {
        let agsPoint = poiPoint.agsPoint
        let label = AGSTextSymbol(text: poiPoint.formattedAltitude,
                                  color: Constants.textColor,
                                  size: Constants.labelSize,
                                  horizontalAlignment: .center,
                                  verticalAlignment: .middle)
        let drapedPoint = agsPoint.withAltitude(Constants.textAltitudeOffset)
        let elevatedPoint = agsPoint.withAltitude(poiPoint.altitude + Constants.textAltitudeOffset)
        self.init(symbol: label,
                  elevatedPoint: elevatedPoint,
                  drapedPoint: drapedPoint)
        self.attributes[FlightPlanAGSConstants.poiIndexAttributeKey] = index
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - location: point of interest's location
    public convenience init(location: Location3D) {
        let label = AGSTextSymbol(text: location.formattedAltitude,
                                  color: Constants.textColor,
                                  size: Constants.labelSize,
                                  horizontalAlignment: .center,
                                  verticalAlignment: .middle)
        let drapedPoint = location.agsPoint.withAltitude(Constants.textAltitudeOffset)
        let elevatedPoint = location.agsPoint.withAltitude(location.altitude + Constants.textAltitudeOffset)
        self.init(symbol: label,
                  elevatedPoint: elevatedPoint,
                  drapedPoint: drapedPoint)
        self.attributes[AGSConstants.poiPointAttributeKey] = true
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
}
