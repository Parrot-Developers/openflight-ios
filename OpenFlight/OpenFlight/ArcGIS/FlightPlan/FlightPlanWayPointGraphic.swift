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

/// Graphic class for Flight Plan's waypoint.
public final class FlightPlanWayPointGraphic: FlightPlanPointGraphic, WayPointRelatedGraphic, PoiPointRelatedGraphic {
    // MARK: - Private Properties
    private var largeCircleSymbol: AGSSimpleMarkerSymbol? {
        guard let compositeSymbol = self.symbol as? AGSCompositeSymbol,
            let symbol = compositeSymbol.symbols.first as? AGSSimpleMarkerSymbol else {
            return nil
        }

        return symbol
    }

    // MARK: - Public Properties
    /// Associated waypoint.
    private(set) weak var wayPoint: WayPoint?

    // MARK: - Override Properties
    override var itemType: FlightPlanGraphicItemType {
        return .wayPoint
    }
    override var altitude: Double? {
        return mapPoint?.z
    }
    public override var deletable: Bool {
        return true
    }

    // MARK: - Private Constants
    private enum Constants {
        static let defaultColor: UIColor = ColorName.black.color
        static let selectedColor: UIColor = ColorName.greenSpring.color
        static let secondaryColor: UIColor = ColorName.white.color
        static let customSecondaryColor: UIColor = ColorName.greenSpring.color
        static let largeCircleSize: CGFloat = 48.0
        static let largeCircleOutlineWidth: CGFloat = 2.0
        static let smallCircleSize: CGFloat = 15.0
        static let smallCircleOffset: CGFloat = 18.0
        static let smallCircleOutlineWidth: CGFloat = 1.0
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - wayPoint: waypoint
    ///    - index: index of waypoint
    public init(wayPoint: WayPoint, index: Int) {
        let largeCircle = AGSSimpleMarkerSymbol(style: .circle,
                                                color: Constants.defaultColor,
                                                size: Constants.largeCircleSize)
        largeCircle.outline = AGSSimpleLineSymbol(style: .solid,
                                                  color: Constants.secondaryColor,
                                                  width: Constants.largeCircleOutlineWidth)
        let smallCircle = AGSSimpleMarkerSymbol(style: .circle,
                                                color: Constants.secondaryColor,
                                                size: Constants.smallCircleSize)
        smallCircle.outline = AGSSimpleLineSymbol(style: .solid,
                                                  color: Constants.defaultColor,
                                                  width: Constants.smallCircleOutlineWidth)
        smallCircle.offsetX = Constants.smallCircleOffset
        smallCircle.offsetY = Constants.smallCircleOffset
        let symbol = AGSCompositeSymbol(symbols: [largeCircle, smallCircle])
        super.init(geometry: wayPoint.agsPoint,
                   symbol: symbol,
                   attributes: nil)

        self.wayPoint = wayPoint
        self.attributes[FlightPlanAGSConstants.wayPointIndexAttributeKey] = index
        self.attributes[FlightPlanAGSConstants.poiIndexAttributeKey] = wayPoint.poiIndex
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - location: waypoint's location
    public init(location: Location3D) {
        let largeCircle = AGSSimpleMarkerSymbol(style: .circle,
                                                color: Constants.defaultColor,
                                                size: Constants.largeCircleSize)
        largeCircle.outline = AGSSimpleLineSymbol(style: .solid,
                                                  color: Constants.customSecondaryColor,
                                                  width: Constants.largeCircleOutlineWidth)
        super.init(geometry: location.agsPoint,
                   symbol: largeCircle,
                   attributes: nil)

        self.attributes[AGSConstants.wayPointAttributeKey] = true
    }

    // MARK: - Override Funcs
    override func updateColors(isSelected: Bool) {
        largeCircleSymbol?.color = isSelected
            ? Constants.selectedColor
            : Constants.defaultColor
    }

    override func updateAltitude(_ altitude: Double) {
        self.geometry = mapPoint?.withAltitude(altitude)
        wayPoint?.altitude = altitude
    }
}

// MARK: - Public Funcs
public extension FlightPlanWayPointGraphic {
    /// Updates waypoint.
    ///
    /// - Parameters:
    ///    - point: new point to apply
    func update(with point: AGSPoint) {
        self.geometry = point
    }
}
