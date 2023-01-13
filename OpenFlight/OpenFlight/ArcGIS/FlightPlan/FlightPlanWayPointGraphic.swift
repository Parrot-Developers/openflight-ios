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

/// Graphic class for Flight Plan's waypoint.
public final class FlightPlanWayPointGraphic: FlightPlanPointGraphic, WayPointRelatedGraphic, PoiPointRelatedGraphic {
    // MARK: - Public Properties
    /// Associated waypoint.
    private(set) var wayPoint: WayPoint?
    /// 3D location of waypoint
    private(set) var location: Location3D?
    // MARK: - Private Properties
    private var mainLabel: AGSPictureMarkerSymbol?
    private var subLabel: AGSPictureMarkerSymbol?
    private var largeCircle: AGSSimpleMarkerSymbol
    private var selectedLargeCircle: AGSSimpleMarkerSymbol
    private var smallCircle: AGSSimpleMarkerSymbol?
    private var touchAreaCircle: AGSSimpleMarkerSymbol?
    private var isReduced = false

    /// Camera heading
    private var heading: Int = 0

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
        static let customSecondaryColor: UIColor = ColorName.white.color
        static let touchAreaCircleSize: CGFloat = 60.0
        static let touchAreaColor: UIColor = ColorName.clear.color
        static let largeCircleSize: CGFloat = 42.0
        static let largeCircleOutlineWidth: CGFloat = 1.0
        static let selectedLargeCircle: CGFloat = 50.0
        static let smallCircleSize: CGFloat = 14.0
        static let smallCircleOffset: CGFloat = 15.0
        static let selectedSmallCircleOffset: CGFloat = 16.0
        static let smallCircleOutlineWidth: CGFloat = 1.0
        static let displayedIndexOffset: Int = 1
        static let mainTextColor: UIColor = ColorName.white.color
        static let mainTextSelectedColor: UIColor = ColorName.black.color
        static let fontSizeMainLabel: CGFloat = 13.0
        static let fontSizeSubLabel: CGFloat = 10.0
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - wayPoint: waypoint
    ///    - index: index of waypoint
    ///    - heading: camera heading
    ///    - isDetail: If the detail execution screen is open
    public init(wayPoint: WayPoint, index: Int, heading: Double, isDetail: Bool = false) {
        self.heading = Int(heading)
        if !isDetail {
            touchAreaCircle = AGSSimpleMarkerSymbol(style: .circle,
                                                    color: Constants.touchAreaColor,
                                                    size: Constants.touchAreaCircleSize)
        }
        largeCircle = AGSSimpleMarkerSymbol(style: .circle,
                                            color: Constants.defaultColor,
                                            size: Constants.largeCircleSize)
        largeCircle.outline = AGSSimpleLineSymbol(style: .solid,
                                                  color: Constants.secondaryColor,
                                                  width: Constants.largeCircleOutlineWidth)
        selectedLargeCircle = AGSSimpleMarkerSymbol(style: .circle,
                                                    color: Constants.selectedColor,
                                                    size: Constants.selectedLargeCircle)
        selectedLargeCircle.outline = AGSSimpleLineSymbol(style: .solid,
                                                  color: Constants.customSecondaryColor,
                                                  width: Constants.largeCircleOutlineWidth)
        smallCircle = AGSSimpleMarkerSymbol(style: .circle,
                                            color: Constants.secondaryColor,
                                            size: Constants.smallCircleSize)
        smallCircle?.outline = AGSSimpleLineSymbol(style: .solid,
                                                   color: Constants.defaultColor,
                                                   width: Constants.smallCircleOutlineWidth)
        smallCircle?.offsetX = Constants.smallCircleOffset
        smallCircle?.offsetY = Constants.smallCircleOffset
        var array = [AGSSymbol]()
        array.append(largeCircle)

        if let smallCircle = smallCircle {
            array.append(smallCircle)
        }
        let symbol = AGSCompositeSymbol(symbols: array)

        super.init(geometry: wayPoint.agsPoint,
                   symbol: symbol,
                   attributes: nil)

        zIndex = Int(wayPoint.altitude)
        self.wayPoint = wayPoint
        attributes[FlightPlanAGSConstants.wayPointIndexAttributeKey] = index
        attributes[FlightPlanAGSConstants.poiIndexAttributeKey] = wayPoint.poiIndex

        refreshText(altitude: wayPoint.formattedAltitude)
        applyRotation()
        refreshIndex(index: String(index + Constants.displayedIndexOffset))
        self.symbol = getSymbol()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - location: waypoint's location
    public init(location: Location3D) {
        touchAreaCircle = AGSSimpleMarkerSymbol(style: .circle,
                                                color: Constants.touchAreaColor,
                                                size: Constants.touchAreaCircleSize)
        largeCircle = AGSSimpleMarkerSymbol(style: .circle,
                                            color: Constants.defaultColor,
                                            size: Constants.largeCircleSize)
        largeCircle.outline = AGSSimpleLineSymbol(style: .solid,
                                                  color: Constants.customSecondaryColor,
                                                  width: Constants.largeCircleOutlineWidth)
        selectedLargeCircle = AGSSimpleMarkerSymbol(style: .circle,
                                                    color: Constants.selectedColor,
                                                    size: Constants.selectedLargeCircle)
        selectedLargeCircle.outline = AGSSimpleLineSymbol(style: .solid,
                                                  color: Constants.customSecondaryColor,
                                                  width: Constants.largeCircleOutlineWidth)
        self.location = location
        var array = [AGSSymbol]()
        array.append(largeCircle)
        let symbol = AGSCompositeSymbol(symbols: array)
        super.init(geometry: location.agsPoint,
                   symbol: symbol,
                   attributes: nil)

        attributes[AGSConstants.wayPointAttributeKey] = true
        refreshText(altitude: location.formattedAltitude)
        self.symbol = getSymbol()
    }

    /// Get symbol
    ///
    /// - Returns: symbol
    private func getSymbol() -> AGSCompositeSymbol {
        var array = [AGSSymbol]()
        if let touchAreaCircle = touchAreaCircle {
            array.append(touchAreaCircle)
        }
        if graphicIsSelected {
            array.append(selectedLargeCircle)
        } else {
            array.append(largeCircle)
        }
        if let mainLabel = mainLabel {
            array.append(mainLabel)
        }
        if let smallCircle = smallCircle, !isReduced {
            array.append(smallCircle)
        }
        if let subLabel = subLabel, !isReduced {
            array.append(subLabel)
        }
        return AGSCompositeSymbol(symbols: array)
    }

    // MARK: - Override Funcs
    override func updateColors(isSelected: Bool) {
        if graphicIsSelected {
            smallCircle?.offsetX = Constants.selectedSmallCircleOffset
            smallCircle?.offsetY = Constants.selectedSmallCircleOffset
            subLabel?.offsetX = Constants.selectedSmallCircleOffset
            subLabel?.offsetY = Constants.selectedSmallCircleOffset
        } else {
            smallCircle?.offsetX = Constants.smallCircleOffset
            smallCircle?.offsetY = Constants.smallCircleOffset
            subLabel?.offsetX = Constants.smallCircleOffset
            subLabel?.offsetY = Constants.smallCircleOffset
        }
        if graphicIsSelected {
            zIndex = FlightPlanConstants.maxZIndex
        } else {
            zIndex = Int(altitude ?? 0)
        }
        refreshText(altitude: wayPoint?.formattedAltitude ?? "")
        applyRotation()
        symbol = getSymbol()
    }

    override func updateAltitude(_ altitude: Double) {
        let changeAltitude = (wayPoint?.altitude ?? 0.0) != altitude
        geometry = mapPoint?.withAltitude(altitude)
        wayPoint?.altitude = altitude

        if changeAltitude {
            zIndex = graphicIsSelected ? FlightPlanConstants.maxZIndex : Int(altitude)
            refreshText(altitude: wayPoint?.formattedAltitude ?? "")
            applyRotation()
            symbol = getSymbol()
        }
    }

    /// Refresh text of main label
    ///
    /// - Parameters:
    ///     - altitude: altitude to display
    private func refreshText(altitude: String) {
        let altitudeImage = FlightPlanPointGraphic.imageWith(name: altitude,
                            textColor: graphicIsSelected ? Constants.mainTextSelectedColor : Constants.mainTextColor,
                            fontSize: Constants.fontSizeMainLabel,
                            size: CGSize(width: Constants.largeCircleSize, height: Constants.largeCircleSize))

        if let image = altitudeImage {
            mainLabel = AGSPictureMarkerSymbol(image: image)
        }
    }

    /// Refresh index
    ///
    /// - Parameters:
    ///     - index: index to display
    private func refreshIndex(index: String) {
        let indexImage = FlightPlanPointGraphic.imageWith(
            name: index,
            textColor: Constants.mainTextSelectedColor, fontSize: Constants.fontSizeSubLabel,
            size: CGSize(width: Constants.largeCircleSize, height: Constants.largeCircleSize))
        if let image = indexImage {
            subLabel = AGSPictureMarkerSymbol(image: image)
            subLabel?.offsetX = Constants.smallCircleOffset
            subLabel?.offsetY = Constants.smallCircleOffset
        }
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
        mainLabel?.angle = Float(heading)
        subLabel?.angle = Float(heading)
        smallCircle?.angle = Float(heading)
    }
}

// MARK: - Public Funcs
public extension FlightPlanWayPointGraphic {
    /// Updates waypoint.
    ///
    /// - Parameters:
    ///    - location: new location to apply
    func update(location: Location3D) {
        self.location = location
        geometry = location.agsPoint
        zIndex = Int(location.altitude)
        refreshText(altitude: location.formattedAltitude)
        applyRotation()
        symbol = getSymbol()
    }

    func decrementWayPointIndex() {
        guard let index = wayPointIndex, index > 0 else { return }
        attributes[FlightPlanAGSConstants.wayPointIndexAttributeKey] = index - 1
        refreshIndex(index: String(index - 1 + Constants.displayedIndexOffset))
        applyRotation()
        symbol = getSymbol()
    }

    func incrementWayPointIndex() {
        guard let index = wayPointIndex, index > 0 else { return }
        attributes[FlightPlanAGSConstants.wayPointIndexAttributeKey] = index + 1
        refreshIndex(index: String(index + 1 + Constants.displayedIndexOffset))
        applyRotation()
        symbol = getSymbol()
    }

    /// Set reduced mode, this is used when map is mini.
    ///
    /// - Parameters:
    ///    - value: the new value
    func setReduced(_ value: Bool) {
        self.isReduced = value
        symbol = getSymbol()
    }
}
