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

/// Graphics overlay for Flight Plan.
public final class FlightPlanGraphicsOverlay: AGSGraphicsOverlay {
    // MARK: - Public Properties
    /// Returns true if a graphic is currently selected inside Flight Plan.
    var hasSelection: Bool {
        return self.flightPlanGraphics.contains(where: { $0.isSelected })
    }

    /// Returns index of selected waypoint.
    var selectedWayPointIndex: Int? {
        let selection = self.wayPoints.first(where: { $0.isSelected })

        return selection?.wayPointIndex
    }

    /// Returns all Flight Plan's waypoint arrows.
    var wayPointArrows: [FlightPlanWayPointArrowGraphic] {
        return self.graphics.compactMap { $0 as? FlightPlanWayPointArrowGraphic }
    }
    /// Currently dragged graphic, if any.
    weak var draggedGraphic: FlightPlanPointGraphic?
    /// Timestamp at which the drag started.
    var startDragTimeStamp: TimeInterval = 0.0

    // MARK: - Private Properties
    /// Returns all Flight Plan's graphics.
    private var flightPlanGraphics: [FlightPlanGraphic] {
        return self.graphics.compactMap { $0 as? FlightPlanGraphic }
    }
    /// Returns all Flight Plan's waypoint to point of interest graphics.
    private var wayPointToPoiLines: [FlightPlanWayPointToPoiLineGraphic] {
        return self.graphics.compactMap { $0 as? FlightPlanWayPointToPoiLineGraphic }
    }
    /// Returns all Flight Plan's waypoint line graphics.
    private var wayPointLines: [FlightPlanWayPointLineGraphic] {
        return self.graphics.compactMap { $0 as? FlightPlanWayPointLineGraphic }
    }
    /// Returns all Flight Plan's waypoint graphics.
    private var wayPoints: [FlightPlanWayPointGraphic] {
        return self.graphics.compactMap { $0 as? FlightPlanWayPointGraphic }
    }
    /// Returns all Flight Plan's point of interest graphics.
    private var poiPoints: [FlightPlanPoiPointGraphic] {
        return self.graphics.compactMap { $0 as? FlightPlanPoiPointGraphic }
    }
    /// Returns current insert waypoint graphic, if any (when line is selected).
    private var currentInsertWayPointGraphic: FlightPlanInsertWayPointGraphic? {
        return self.graphics.compactMap { $0 as? FlightPlanInsertWayPointGraphic }.first
    }

    // MARK: - Private Enums
    private enum Constants {
        static let noIndex: Int = -1
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - graphics: overlay's initial array of graphics.
    public init(graphics: [FlightPlanGraphic]) {
        super.init()

        self.sceneProperties?.surfacePlacement = .relative
        self.graphics.addObjects(from: graphics)
    }

    // MARK: - Override Funcs
    override func deselectAllGraphics() {
        super.deselectAllGraphics()

        let poiLines = self.graphics.compactMap { $0 as? FlightPlanWayPointToPoiLineGraphic }
        self.graphics.removeObjects(in: poiLines)
    }

    // MARK: - Public Funcs
    // MARK: Graphics Getters
    /// Returns point of interest graphic at given index.
    ///
    /// - Parameters:
    ///    - index: point of interest's index
    /// - Returns: point of interest's graphic, if it exists
    func poiPoint(at index: Int) -> FlightPlanPoiPointGraphic? {
        return poiPoints
            .first(where: { $0.poiIndex == index })
    }

    /// Returns waypoint line before waypoint at given index.
    ///
    /// - Parameters:
    ///    - index: waypoint's index
    /// - Returns: waypoint line, if it exists
    func lineBeforeWayPoint(at index: Int) -> FlightPlanWayPointLineGraphic? {
        return wayPointLines
            .first(where: { $0.wayPointIndex == index-1 })
    }

    /// Returns waypoint line after waypoint at given index.
    ///
    /// - Parameters:
    ///    - index: waypoint's index
    /// - Returns: waypoint line, if it exists
    func lineAfterWayPoint(at index: Int) -> FlightPlanWayPointLineGraphic? {
        return wayPointLines
            .first(where: { $0.wayPointIndex == index })
    }

    /// Returns point of interest line for waypoint at given index.
    ///
    /// - Parameters:
    ///    - index: waypoint's index
    /// - Returns: point of interest line, if it exists
    func poiLineForWayPoint(at index: Int) -> FlightPlanWayPointToPoiLineGraphic? {
        return wayPointToPoiLines
            .first(where: { $0.wayPointIndex == index })
    }

    /// Returns arrow for waypoint at given index.
    ///
    /// - Parameters:
    ///    - index; waypoint's index
    /// - Returns: arrow graphic, if it exists
    func arrowForWayPoint(at index: Int) -> FlightPlanWayPointArrowGraphic? {
        return wayPointArrows
            .first(where: { $0.wayPointIndex == index })
    }

    /// Updates given graphic selection state.
    ///
    /// - Parameters:
    ///    - graphic: graphic to select/deselect
    ///    - isSelected: whether graphic should be selected
    func updateGraphicSelection(_ graphic: FlightPlanGraphic,
                                isSelected: Bool) {
        switch graphic {
        case let poiPointGraphic as FlightPlanPoiPointGraphic:
            updatePoiPointSelection(poiPointGraphic,
                                    isSelected: isSelected)
        case let wayPointLineGraphic as FlightPlanWayPointLineGraphic:
            updateWayPointLineSelection(wayPointLineGraphic,
                                        isSelected: isSelected)
        default:
            graphic.isSelected = isSelected
        }
    }

    /// Toggles relation state between waypoint and point of interest.
    ///
    /// - Parameters:
    ///    - wayPointGraphic: waypoint's graphic
    ///    - poiPointGraphic: point of interest's graphic
    func toggleRelation(between wayPointGraphic: FlightPlanWayPointGraphic,
                        and poiPointGraphic: FlightPlanPoiPointGraphic) {
        if wayPointGraphic.poiIndex == poiPointGraphic.poiIndex {
            // Points are related, remove relation.
            unassignPoiPointFrom(wayPointGraphic)
        } else {
            // Otherwise, create relation.
            assignPoiPointToWayPoint(wayPointGraphic: wayPointGraphic,
                                     poiPointGraphic: poiPointGraphic)
        }
    }

    /// Removes all the lines between waypoints and points of interest.
    func removeAllLinesToPoi() {
        self.graphics.removeObjects(in: wayPointToPoiLines)
    }

    // MARK: Location Updates
    /// Updates altitude for waypoint at given index.
    ///
    /// - Parameters:
    ///    - index: waypoint's index
    ///    - altitude: new altitude
    func updateWayPointAltitude(at index: Int, altitude: Double) {
        guard let wpGraphic = wayPoints.first(where: { $0.wayPointIndex == index }) else { return }

        wpGraphic.updateAltitude(altitude)
        wayPointArrows
            .first(where: { $0.wayPointIndex == index })?
            .updateAltitude(altitude)
        if let mapPoint = wpGraphic.mapPoint {
            lineBeforeWayPoint(at: index)?.updateEndPoint(mapPoint)
            lineAfterWayPoint(at: index)?.updateStartPoint(mapPoint)
        }
    }

    /// Updates altitude for point of interest at given index.
    ///
    /// - Parameters:
    ///    - index: point of interest's index
    ///    - altitude: new altitude
    func updatePoiPointAltitude(at index: Int, altitude: Double) {
        guard let poiGraphic = poiPoints.first(where: { $0.poiIndex == index }) else { return }

        poiGraphic.updateAltitude(altitude)
        if let mapPoint = poiGraphic.mapPoint {
            // Only lines for active point of interest are displayed.
            wayPointToPoiLines.forEach { $0.updatePoiPoint(mapPoint) }
        }
    }

    /// Move currently dragged graphic to location.
    ///
    /// - Parameters:
    ///    - mapPoint: location to move to
    func updateDraggedGraphicLocation(_ mapPoint: AGSPoint) {
        guard let draggedGraphic = draggedGraphic,
              let altitude = draggedGraphic.altitude else {
            return
        }

        let newPoint = mapPoint.withAltitude(altitude)
        switch draggedGraphic {
        case let wayPointGraphic as FlightPlanWayPointGraphic:
            updateWayPointLocation(wayPointGraphic,
                                   location: newPoint)
        case let poiPointGraphic as FlightPlanPoiPointGraphic:
            updatePoiPointLocation(poiPointGraphic,
                                   location: newPoint)
        case let wayPointArrowGraphic as FlightPlanWayPointArrowGraphic:
            updateWayPointArrowRotation(wayPointArrowGraphic,
                                        location: newPoint)
        default:
            break
        }
    }

    /// Updates location of a waypoint.
    ///
    /// - Parameters:
    ///    - wayPointGraphic: waypoint's graphic
    ///    - location: new location
    func updateWayPointLocation(_ wayPointGraphic: FlightPlanWayPointGraphic,
                                location: AGSPoint) {
        guard let index = wayPointGraphic.wayPointIndex else { return }

        // Update Flight Plan.
        wayPointGraphic.wayPoint?.setCoordinate(location.toCLLocationCoordinate2D())

        // Get all lines concerned by this waypoint.
        let lines = wayPointLines
        let lineBefore = lines.first(where: { $0.wayPointIndex == index-1 })
        let lineAfter = lines.first(where: { $0.wayPointIndex == index })
        let poiLine = wayPointToPoiLines.first(where: { $0.wayPointIndex == index })
        let arrow = wayPointArrows.first(where: { $0.wayPointIndex == index })

        /// Update geometries.
        lineBefore?.updateEndPoint(location)
        lineAfter?.updateStartPoint(location)
        if let addGraphic = self.currentInsertWayPointGraphic {
            if lineBefore?.isSelected == true {
                addGraphic.geometry = lineBefore?.middlePoint
            } else if lineAfter?.isSelected == true {
                addGraphic.geometry = lineAfter?.middlePoint
            }
        }
        poiLine?.updateWayPoint(location)
        arrow?.geometry = location
        wayPointGraphic.geometry = location
    }

    /// Updates location of a point of interest.
    ///
    /// - Parameters:
    ///    - poiPointGraphic: point of interest's graphic
    ///    - location: new location
    func updatePoiPointLocation(_ poiPointGraphic: FlightPlanPoiPointGraphic,
                                location: AGSPoint) {
        guard let index = poiPointGraphic.poiIndex else { return }

        // Update Flight Plan.
        poiPointGraphic.poiPoint?.coordinate = location.toCLLocationCoordinate2D()
        wayPoints
            .compactMap { return $0.poiIndex == index ? $0.wayPoint : nil }
            .forEach { $0.updateYaw() }
        // Update all lines towards point of interest.
        wayPointToPoiLines
            .filter { $0.poiIndex == index }
            .forEach { $0.updatePoiPoint(location) }
        poiPointGraphic.geometry = location
    }

    /// Updates orientation of a waypoint.
    ///
    /// - Parameters:
    ///    - wayPointArrowGraphic: waypoint's arrow graphic
    ///    - location: touch location
    func updateWayPointArrowRotation(_ wayPointArrowGraphic: FlightPlanWayPointArrowGraphic,
                                     location: AGSPoint) {
        guard let wayPointLocation = wayPointArrowGraphic.wayPoint?.coordinate else { return }

        let newYaw = GeometryUtils.yaw(fromLocation: wayPointLocation,
                                       toLocation: location.toCLLocationCoordinate2D()).toBoundedDegrees()
        wayPointArrowGraphic.wayPoint?.setCustomYaw(newYaw)
    }

    // MARK: - Insertion
    /// Inserts waypoint graphics between two existing waypoints.
    ///
    /// - Parameters:
    ///    - wayPoint: waypoint to insert
    ///    - index: index at which it should be inserted
    func insertWayPoint(_ wayPoint: WayPoint, at index: Int) {
        guard let line = wayPointLines.first(where: { $0.wayPointIndex == index - 1 }),
              let originWayPoint = line.originWayPoint,
              let destinationWayPoint = line.destinationWayPoint else {
            return
        }

        // Create new graphics.
        let wayPointGraphic = FlightPlanWayPointGraphic(wayPoint: wayPoint,
                                                        index: index)
        let arrowGraphic = wayPoint.arrowGraphic(index: index)
        let lineBefore = FlightPlanWayPointLineGraphic(origin: originWayPoint,
                                                       destination: wayPoint,
                                                       originIndex: index - 1)
        let lineAfter = FlightPlanWayPointLineGraphic(origin: wayPoint,
                                                      destination: destinationWayPoint,
                                                      originIndex: index)

        // Increment indexes on existing graphics.
        self.flightPlanGraphics
            .compactMap { $0 as? WayPointRelatedGraphic }
            .filter { $0.wayPointIndex ?? Constants.noIndex >= index }
            .forEach { $0.incrementWayPointIndex() }

        // Remove existing line.
        self.graphics.remove(line)

        // Add new graphics.
        self.graphics.add(wayPointGraphic)
        self.graphics.add(arrowGraphic)
        self.graphics.add(lineBefore)
        self.graphics.add(lineAfter)
    }

    // MARK: Deletion
    /// Removes waypoint at given index and updates related graphics.
    ///
    /// - Parameters:
    ///    - index: waypoint's index
    func removeWayPoint(at index: Int) {
        guard let wayPoint = wayPoints.first(where: { $0.wayPointIndex == index }) else { return }

        let wpLines = wayPointLines
        let lineBefore = wpLines.first(where: { $0.wayPointIndex == index-1 })
        let lineAfter = wpLines.first(where: { $0.wayPointIndex == index })
        // Add new waypoint line if needed.
        if let startPoint = lineBefore?.originWayPoint,
           let endPoint = lineAfter?.destinationWayPoint {
            let newGraphic = FlightPlanWayPointLineGraphic(origin: startPoint,
                                                           destination: endPoint,
                                                           originIndex: index-1)
            self.graphics.add(newGraphic)
        }
        // Remove graphics.
        self.graphics.remove(wayPoint)
        if let lineBefore = lineBefore {
            self.graphics.remove(lineBefore)
        }
        if let lineAfter = lineAfter {
            self.graphics.remove(lineAfter)
        }
        if let poiLine = poiLineForWayPoint(at: index) {
            self.graphics.remove(poiLine)
        }
        if let arrow = wayPointArrows.first(where: { $0.wayPointIndex == index }) {
            self.graphics.remove(arrow)
        }
        // Decrement subsequent waypoints, waypoint lines
        // and waypoint to point of interest lines indexes.
        self.flightPlanGraphics
            .compactMap { $0 as? WayPointRelatedGraphic }
            .filter { $0.wayPointIndex ?? Constants.noIndex > index }
            .forEach { $0.decrementWayPointIndex() }
    }

    /// Removes point of interest at given index and updates related graphics.
    ///
    /// - Parameters:
    ///    - index: point of interest's index
    func removePoiPoint(at index: Int) {
        guard let poiPoint = poiPoints.first(where: { $0.poiIndex == index }) else { return }

        // Remove graphic.
        self.graphics.remove(poiPoint)
        // Update related waypoints.
        wayPoints
            .filter { $0.poiIndex == index }
            .forEach { unassignPoiPointFrom($0) }
        // Decrement subsequent points of interest and
        // waypoint to point of interest lines/arrows indexes.
        graphics
            .compactMap { $0 as? PoiPointRelatedGraphic }
            .filter { $0.poiIndex ?? Constants.noIndex > index }
            .forEach { $0.decrementPoiPointIndex() }
    }
}

// MARK: - Private Funcs
private extension FlightPlanGraphicsOverlay {
    /// Adds relation between waypoint and point of interest.
    ///
    /// - Parameters:
    ///    - wayPointGraphic: waypoint's graphic
    ///    - poiPointGraphic: point of interest's graphic
    func assignPoiPointToWayPoint(wayPointGraphic: FlightPlanWayPointGraphic,
                                  poiPointGraphic: FlightPlanPoiPointGraphic) {
        guard let poiPoint = poiPointGraphic.poiPoint,
              let poiIndex = poiPointGraphic.poiIndex else {
            return
        }

        // Remove previous relation.
        unassignPoiPointFrom(wayPointGraphic)
        // Update Flight Plan.
        wayPointGraphic.wayPoint?.assignPoiPoint(poiPoint: poiPoint,
                                                 poiIndex: poiIndex)
        // Update graphic.
        wayPointGraphic.poiIndex = poiPointGraphic.poiIndex

        // Update arrow.
        if let arrow = wayPointArrows.first(where: { $0.wayPointIndex == wayPointGraphic.wayPointIndex }) {
            arrow.addPoiPoint(poiPointGraphic)
            arrow.isSelected = true
        }

        // Add line.
        if let line = FlightPlanWayPointToPoiLineGraphic(wayPointGraphic: wayPointGraphic,
                                                         poiPointGraphic: poiPointGraphic) {
            self.graphics.add(line)
        }
    }

    /// Removes relation between waypoint and its target point of interest.
    ///
    /// - Parameters:
    ///    - wayPointGraphic: waypoint's graphic
    func unassignPoiPointFrom(_ wayPointGraphic: FlightPlanWayPointGraphic) {
        // Update Flight Plan.
        wayPointGraphic.wayPoint?.unassignPoiPoint()

        // Update graphics.
        wayPointGraphic.poiIndex = nil

        // Remove line.
        if let line = wayPointToPoiLines.first(where: { $0.wayPointIndex == wayPointGraphic.wayPointIndex }) {
            self.graphics.remove(line)
        }

        // Update arrow.
        if let arrow = wayPointArrows.first(where: { $0.wayPointIndex == wayPointGraphic.wayPointIndex }) {
            arrow.removePoiPoint()
        }
    }

    /// Selects/deselects point of interest.
    ///
    /// - Parameters:
    ///    - poiPointGraphic: point of interest's graphic
    ///    - isSelected: whether point of interest should be selected.
    func updatePoiPointSelection(_ poiPointGraphic: FlightPlanPoiPointGraphic,
                                 isSelected: Bool) {
        poiPointGraphic.isSelected = isSelected
        wayPointArrows
            .filter { $0.poiIndex == poiPointGraphic.poiIndex }
            .forEach { $0.isSelected = isSelected }
        if isSelected {
            // Creates waypoint to point of interest lines.
            let poiLines = wayPoints
                .filter { $0.poiIndex == poiPointGraphic.poiIndex }
                .compactMap { wayPointGraphic in
                    return FlightPlanWayPointToPoiLineGraphic(wayPointGraphic: wayPointGraphic,
                                                              poiPointGraphic: poiPointGraphic)
                }
            self.graphics.addObjects(from: poiLines)
        } else {
            // Removes waypoint to point of interest lines.
            self.removeAllLinesToPoi()
        }
    }

    /// Selects/deselects waypoint line.
    ///
    /// - Parameters:
    ///    - wayPointLineGraphic: waypoint line's graphic
    ///    - isSelected: whether point of interest should be selected.
    func updateWayPointLineSelection(_ wayPointLineGraphic: FlightPlanWayPointLineGraphic,
                                     isSelected: Bool) {
        wayPointLineGraphic.isSelected = isSelected
        if isSelected {
            guard let middlePoint = wayPointLineGraphic.middlePoint,
                  let originIndex = wayPointLineGraphic.wayPointIndex else { return }

            let addGraphic = FlightPlanInsertWayPointGraphic(middlePoint,
                                                             index: originIndex + 1)

            self.graphics.add(addGraphic)
        } else {
            guard let graphic = self.currentInsertWayPointGraphic else { return }

            self.graphics.remove(graphic)
        }
    }
}
