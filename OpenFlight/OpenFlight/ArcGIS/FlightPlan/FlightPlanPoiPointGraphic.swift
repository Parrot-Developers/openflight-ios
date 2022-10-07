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

/// Graphic class for Flight Plan's point of interest.
public final class FlightPlanPoiPointGraphic: FlightPlanPointGraphic, PoiPointRelatedGraphic {
    // MARK: - Private Properties
    private var mainLabel: AGSPictureMarkerSymbol?
    private var diamondSymbol: AGSPictureMarkerSymbol?
    private var touchAreaCircle: AGSSimpleMarkerSymbol

    public static let poiSelected = ImageAsset(name: "poi_selected").image
    public static let poiBlackAndWhite = ImageAsset(name: "poi_black_and_white").image

    private static let colors: [UIImage] = [ImageAsset(name: "poi_light_blue").image,
                                            ImageAsset(name: "poi_green").image,
                                            ImageAsset(name: "poi_yellow").image,
                                            ImageAsset(name: "poi_orange").image,
                                            ImageAsset(name: "poi_pink").image,
                                            ImageAsset(name: "poi_purple").image,
                                            ImageAsset(name: "poi_blue").image]

    /// Camera heading
    private var heading: Int = 0

    // MARK: - Public Properties
    /// Associated point of interest.
    private(set) var poiPoint: PoiPoint?

    // MARK: - Override Properties
    override var itemType: FlightPlanGraphicItemType {
        return .poi
    }
    public override var deletable: Bool {
        return true
    }

    // MARK: - Private Enums
    private enum Constants {
        static let touchAreaCircleSize: CGFloat = 60.0
        static let touchAreaColor: UIColor = ColorName.clear.color
        static let outlineColor: UIColor = ColorName.white.color
        static let selectedColor: UIColor = ColorName.highlightColor.color
        static let diamondSize: CGFloat = 54.0
        static let outlineWidth: CGFloat = 1.0
        static let textColor: UIColor = ColorName.black.color
        static let labelSize: CGFloat = 34.0
        static let fontSize: CGFloat = 13.0
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - poiPoint: point of interest
    ///    - index: index of point of interest
    ///    - heading: camera heading
    public init(poiPoint: PoiPoint, index: Int, heading: Double) {

        self.heading = Int(heading)
        touchAreaCircle = AGSSimpleMarkerSymbol(style: .circle,
                                                color: Constants.touchAreaColor,
                                                size: Constants.touchAreaCircleSize)
        let newIndex = index % FlightPlanPoiPointGraphic.colors.count
        diamondSymbol = AGSPictureMarkerSymbol(image: FlightPlanPoiPointGraphic.colors[newIndex])

        var array = [AGSSymbol]()
        if let diamondSymbol = diamondSymbol {
            array.append(diamondSymbol)
        }

        let symbol = AGSCompositeSymbol(symbols: array)

        super.init(geometry: poiPoint.agsPoint,
                   symbol: symbol,
                   attributes: nil)

        zIndex = Int(poiPoint.altitude)
        self.poiPoint = poiPoint
        attributes[FlightPlanAGSConstants.poiIndexAttributeKey] = index
        refreshText(altitude: poiPoint.formattedAltitude)
        applyRotation()
        self.symbol = getSymbol()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - location: point of interest's location
    public init(location: Location3D) {
        touchAreaCircle = AGSSimpleMarkerSymbol(style: .circle,
                                                color: Constants.touchAreaColor,
                                                size: Constants.touchAreaCircleSize)
        diamondSymbol = AGSPictureMarkerSymbol(image: FlightPlanPoiPointGraphic.poiBlackAndWhite)

        // add altitude
        var array = [AGSSymbol]()
        if let diamondSymbol = diamondSymbol {
            array.append(diamondSymbol)
        }

        let symbol = AGSCompositeSymbol(symbols: array)

        super.init(geometry: location.agsPoint,
                   symbol: symbol,
                   attributes: nil)

        attributes[AGSConstants.poiPointAttributeKey] = true
        refreshText(altitude: location.formattedAltitude)
        self.symbol = getSymbol()
    }

    // MARK: - Override Funcs
    override func updateColors(isSelected: Bool) {
        let newIndex = (poiIndex ?? 0) % FlightPlanPoiPointGraphic.colors.count
        diamondSymbol = isSelected ? AGSPictureMarkerSymbol(image: FlightPlanPoiPointGraphic.poiSelected)
                                    : AGSPictureMarkerSymbol(image: FlightPlanPoiPointGraphic.colors[newIndex])
        applyRotation()
        symbol = getSymbol()

    }

    override func updateAltitude(_ altitude: Double) {
        let changeAltitude = (poiPoint?.altitude ?? 0.0) != altitude
        geometry = mapPoint?.withAltitude(altitude)
        poiPoint?.altitude = altitude

        if changeAltitude {
            zIndex = Int(altitude)
            refreshText(altitude: poiPoint?.formattedAltitude ?? "")
            applyRotation()
            symbol = getSymbol()
        }
    }

    /// Refresh text of main label
    ///
    /// - Parameters:
    ///     - altitude: altitude to display
    private func refreshText(altitude: String) {
        var textColor = Constants.textColor
        if (attributes[AGSConstants.poiPointAttributeKey] != nil) == true {
            textColor = .white
        }
        let altitudeImage = FlightPlanPointGraphic.imageWith(name: altitude,
                            textColor: textColor,
                            fontSize: Constants.fontSize,
                            size: CGSize(width: Constants.diamondSize, height: Constants.diamondSize))

        if let image = altitudeImage {
            mainLabel = AGSPictureMarkerSymbol(image: image)
        }
    }

    /// Get symbol
    ///
    /// - Returns: symbol
    private func getSymbol() -> AGSCompositeSymbol {
        var array = [AGSSymbol]()
        array.append(touchAreaCircle)
        if let diamondSymbol = diamondSymbol {
            array.append(diamondSymbol)
        }
        if let mainLabel = mainLabel {
            array.append(mainLabel)
        }
        return AGSCompositeSymbol(symbols: array)
    }

    /// Updates camera heading.
    ///
    /// - Parameters:
    ///     - heading: camera heading
    public func update(heading newHeading: Double) {
        if heading != Int(newHeading) {
            heading = Int(newHeading)
            applyRotation()
            symbol = getSymbol()
        }
    }

    /// Applies rotation to symbols.
    private func applyRotation() {
        mainLabel?.angle = Float(heading) * FlightPlanGraphic.Constants.rotationFactor
        diamondSymbol?.angle = Float(heading) * FlightPlanGraphic.Constants.rotationFactor
    }
}

// MARK: - Public Funcs
public extension FlightPlanPoiPointGraphic {
    /// Updates point of interest.
    ///
    /// - Parameters:
    ///    - location: new location to apply
    func update(location: Location3D) {
        geometry = location.agsPoint
        refreshText(altitude: location.formattedAltitude)
        applyRotation()
        self.symbol = getSymbol()
    }
}
