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

/// Graphics overlay for Flight Plan labels.

public final class FlightPlanLabelsGraphicsOverlay: AGSGraphicsOverlay {
    // MARK: - Public Properties
    /// Currently dragged graphic, if any.
    weak var draggedGraphic: FlightPlanLabelGraphic?

    // MARK: - Private Properties
    /// Returns all waypoints labels.
    private var wayPointLabels: [FlightPlanWayPointLabelsGraphic] {
        return self.graphics.compactMap { $0 as? FlightPlanWayPointLabelsGraphic }
    }
    /// Returns all points of interest labels.
    private var poiPointLabels: [FlightPlanPoiPointLabelGraphic] {
        return self.graphics.compactMap { $0 as? FlightPlanPoiPointLabelGraphic }
    }

    // MARK: - Private Enums
    private enum Constants {
        // Labels altitude should be offset to prevent from colliding with other graphics.
        static let textAltitudeOffset: Double = 0.05
        static let noIndex: Int = -1
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - graphics: overlay's initial array of graphics.
    public init(graphics: [FlightPlanLabelGraphic]) {
        super.init()
        self.sceneProperties?.surfacePlacement = .relative
        self.graphics.addObjects(from: graphics)
    }

    // MARK: - Public Funcs
    // MARK: Graphics Getters
    /// Returns label graphic associated with item of given type at given index.
    ///
    /// - Parameters:
    ///    - index: item's index
    ///    - itemType: item type
    /// - Returns: result graphic, if it exists
    func labelGraphic(at index: Int,
                      itemType: FlightPlanGraphicItemType) -> FlightPlanLabelGraphic? {
        switch itemType {
        case .wayPoint:
            return wayPointLabelGraphic(at: index)
        case .poi:
            return poiPointLabelGraphic(at: index)
        default:
            return nil
        }
    }

    /// Returns label graphic associated with waypoint at given index.
    ///
    /// - Parameters:
    ///    - index: waypoint's index
    /// - Returns: result graphic, if it exists
    func wayPointLabelGraphic(at index: Int) -> FlightPlanWayPointLabelsGraphic? {
        return self.graphics
            .compactMap { $0 as? FlightPlanWayPointLabelsGraphic }
            .first(where: { $0.wayPointIndex == index })
    }

    /// Returns label graphic associated with point of interest at given index.
    ///
    /// - Parameters:
    ///    - index: point of interest's index
    /// - Returns: result graphic, if it exists
    func poiPointLabelGraphic(at index: Int) -> FlightPlanPoiPointLabelGraphic? {
        return self.graphics
            .compactMap { $0 as? FlightPlanPoiPointLabelGraphic }
            .first(where: { $0.poiIndex == index })
    }

    // MARK: Location Updates
    /// Updates waypoint's graphic altitude.
    ///
    /// - Parameters:
    ///    - index: waypoint's index
    ///    - altitude: new altitude
    func updateWayPointAltitude(at index: Int, altitude: Double) {
        guard let wpLabelGraphic = wayPointLabels
            .first(where: { $0.wayPointIndex == index})
            else {
                return
        }
        wpLabelGraphic.updateAltitude(altitude)
    }

    /// Updates point of interest's graphic altitude.
    ///
    /// - Parameters:
    ///    - index: point of interest's index
    ///    - altitude: new altitude
    func updatePoiPointAltitude(at index: Int, altitude: Double) {
        guard let poiLabelGraphic = poiPointLabels
            .first(where: { $0.poiIndex == index })
            else {
                return
        }
        poiLabelGraphic.updateAltitude(altitude)
    }

    /// Update location of currently dragged graphic.
    ///
    /// - Parameters:
    ///    - mapPoint: new location
    func updateDraggedGraphicLocation(_ mapPoint: AGSPoint) {
        if let altitude = draggedGraphic?.altitude {
            draggedGraphic?.updateLocation(mapPoint.withAltitude(altitude))
        }
    }

    // MARK: - Insertion.
    /// Inserts waypoint label graphic between two existing waypoints.
    ///
    /// - Parameters:
    ///    - wayPoint: waypoint to insert
    ///    - index: index at which it should be inserted
    func insertWayPoint(_ wayPoint: WayPoint, at index: Int) {
        // Create graphic.
        let wayPointLabelGraphic = FlightPlanWayPointLabelsGraphic(wayPoint: wayPoint,
                                                                   index: index)

        // Increment indexes on existing graphics.
        self.wayPointLabels
            .filter { $0.wayPointIndex ?? Constants.noIndex >= index }
            .forEach { $0.incrementWayPointIndex() }

        // Add graphic.
        self.graphics.add(wayPointLabelGraphic)
    }

    // MARK: Deletion
    /// Removes waypoint label at given index and updates related graphics.
    ///
    /// - Parameters:
    ///    - index: waypoint's index
    func removeWayPoint(at index: Int) {
        guard let wpLabelGraphic = wayPointLabels.first(where: { $0.wayPointIndex == index }) else {
            return
        }
        self.graphics.remove(wpLabelGraphic)
        wayPointLabels
            .filter { $0.wayPointIndex ?? Constants.noIndex > index }
            .forEach { $0.decrementWayPointIndex() }
    }

    /// Removes point of interest label at given index and updates related graphics.
    ///
    /// - Parameters:
    ///    - index: point of interest's index
    func removePoiPoint(at index: Int) {
        guard let poiLabelGraphic = poiPointLabels.first(where: { $0.poiIndex == index }) else {
            return
        }
        self.graphics.remove(poiLabelGraphic)
        poiPointLabels
            .filter { $0.poiIndex ?? Constants.noIndex > index }
            .forEach { $0.decrementPoiPointIndex() }
    }

    // MARK: Utility
    /// Updates labels' surface placement. Overlay always stays on relative
    /// and alitude is changed to make labels look like they are draped if needed.
    ///
    /// - Parameters:
    ///    - isDraped: whether labels should look draped
    func updateSurfacePlacement(isDraped: Bool) {
        graphics
            .compactMap { $0 as? FlightPlanLabelGraphic }
            .forEach { graphic in
                let newPoint = isDraped
                    ? graphic.attributes[FlightPlanAGSConstants.drapedAgsPointAttributeKey] as? AGSPoint
                    : graphic.attributes[FlightPlanAGSConstants.agsPointAttributeKey] as? AGSPoint
                graphic.geometry = newPoint
        }
    }

    /// Refreshes all overlay's altitude labels.
    func refreshLabels() {
        self.graphics
            .compactMap { $0 as? FlightPlanLabelGraphic }
            .forEach { $0.refreshLabel() }
    }

    /// Updates graphic selection state.
    ///
    /// - Parameters:
    ///    - graphic: graphic to update (from main overlay)
    ///    - isSelected: whether graphic should be selected
    func updateGraphicSelection(_ graphic: FlightPlanGraphic,
                                isSelected: Bool) {
        switch graphic {
        case let poiPointGraphic as FlightPlanPoiPointGraphic:
            if let index = poiPointGraphic.poiIndex {
                poiPointLabelGraphic(at: index)?.isSelected = isSelected
            }
        case let wayPointGraphic as FlightPlanWayPointGraphic:
            if let index = wayPointGraphic.wayPointIndex {
                wayPointLabelGraphic(at: index)?.isSelected = isSelected
            }
        default:
            break
        }
    }
}
