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

/// Graphic class for Flight Plan's point of interest.
public final class FlightPlanPoiPointGraphic: FlightPlanPointGraphic {
    // MARK: - Private Properties
    private var diamondSymbol: AGSSimpleMarkerSymbol? {
        return symbol as? AGSSimpleMarkerSymbol
    }

    // MARK: - Public Properties
    /// Associated point of interest.
    private(set) weak var poiPoint: PoiPoint?

    // MARK: - Override Properties
    override var itemType: FlightPlanGraphicItemType {
        return .poi
    }
    override var itemIndex: Int? {
        return attributes[FlightPlanAGSConstants.poiIndexAttributeKey] as? Int
    }

    // MARK: - Private Enums
    private enum Constants {
        static let outlineColor: UIColor = ColorName.white.color
        static let selectedColor: UIColor = ColorName.greenSpring.color
        static let diamondSize: CGFloat = 54.0
        static let outlineWidth: CGFloat = 2.0
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - poiPoint: point of interest
    ///    - index: index of point of interest
    public init(poiPoint: PoiPoint, index: Int) {
        let diamond = AGSSimpleMarkerSymbol(style: .diamond,
                                            color: FlightPlanAGSConstants.colorForPoiIndex(index),
                                            size: Constants.diamondSize)
        diamond.outline = AGSSimpleLineSymbol(style: .solid,
                                              color: Constants.outlineColor,
                                              width: Constants.outlineWidth)
        super.init(geometry: poiPoint.agsPoint,
                   symbol: diamond,
                   attributes: nil)

        self.poiPoint = poiPoint
        self.attributes[FlightPlanAGSConstants.poiIndexAttributeKey] = index
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - location: point of interest's location
    public init(location: Location3D) {
        let diamond = AGSSimpleMarkerSymbol(style: .diamond,
                                            color: Constants.selectedColor,
                                            size: Constants.diamondSize)
        diamond.outline = AGSSimpleLineSymbol(style: .solid,
                                              color: Constants.outlineColor,
                                              width: Constants.outlineWidth)
        super.init(geometry: location.agsPoint,
                   symbol: diamond,
                   attributes: nil)

        self.attributes[AGSConstants.poiPointAttributeKey] = true
    }

    // MARK: - Override Funcs
    override func updateColors(isSelected: Bool) {
        diamondSymbol?.color = isSelected
            ? Constants.selectedColor
            : FlightPlanAGSConstants.colorForPoiIndex(itemIndex ?? 0)
    }

    override func decrementIndex() {
        guard let index = itemIndex else { return }

        self.attributes[FlightPlanAGSConstants.poiIndexAttributeKey] = index - 1
        updateColors(isSelected: self.isSelected)
    }

    override func updateAltitude(_ altitude: Double) {
        self.geometry = mapPoint?.withAltitude(altitude)
        poiPoint?.altitude = altitude
    }
}

// MARK: - Public Funcs
public extension FlightPlanPoiPointGraphic {
    /// Updates point of interest.
    ///
    /// - Parameters:
    ///    - point: new point to apply
    func update(with point: AGSPoint) {
        self.geometry = point
    }
}
