//
//  Copyright (C) 2021 Parrot Drones SAS.
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

/// Graphic class for Flight Plan's insert symbol over `FlightPlanWayPointLineGraphic`.
final class FlightPlanInsertWayPointGraphic: FlightPlanPointGraphic {
    // MARK: - Override Properties
    override var itemType: FlightPlanGraphicItemType {
        return .insertWayPoint
    }

    // MARK: - Internal Properties
    /// Returns index for waypoint that might get created from this.
    var targetIndex: Int? {
        return self.attributes[FlightPlanAGSConstants.wayPointIndexAttributeKey] as? Int
    }

    // MARK: - Private Enums
    private enum Constants {
        static let circleSize: CGFloat = 22.0
        static let outlineWidth: CGFloat = 2.0
        static let crossSize: CGFloat = 14.0
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - mapPoint: location of graphic
    ///    - index: index of the waypoint that might get created
    init(_ mapPoint: AGSPoint,
         index: Int) {
        let circle = AGSSimpleMarkerSymbol(style: .circle,
                                           color: ColorName.greenPea.color,
                                           size: Constants.circleSize)
        circle.outline = AGSSimpleLineSymbol(style: .solid,
                                             color: ColorName.greenSpring.color,
                                             width: Constants.outlineWidth)
        let cross = AGSSimpleMarkerSymbol(style: .cross,
                                          color: ColorName.white.color,
                                          size: Constants.crossSize)
        let symbol = AGSCompositeSymbol(symbols: [circle, cross])

        super.init(geometry: mapPoint,
                   symbol: symbol,
                   attributes: nil)

        self.attributes[FlightPlanAGSConstants.wayPointIndexAttributeKey] = index
    }
}
