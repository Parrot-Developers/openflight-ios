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

/// Graphics overlay for Flight Plan.
public final class FlightPlanGraphicsOverlay: AGSGraphicsOverlay {
    // MARK: - Public Properties
    /// Returns true if a graphic is currently selected inside Flight Plan.
    var hasSelection: Bool {
        return flightPlanGraphics.contains(where: { $0.isSelected })
    }

    /// Returns a graphic is currently selected inside Flight Plan.
    var currentSelection: FlightPlanGraphic? {
        return flightPlanGraphics.first(where: { $0.isSelected })
    }

    /// Returns all Flight Plan's waypoint arrows.
    var wayPointArrows: [FlightPlanWayPointArrowGraphic] {
        return graphics.compactMap { $0 as? FlightPlanWayPointArrowGraphic }
    }

    /// Last manually selected graphic.
    var lastManuallySelectedGraphic: FlightPlanGraphic?

    /// Currently dragged graphic, if any.
    weak var draggedGraphic: FlightPlanPointGraphic?
    /// Timestamp at which the drag started.
    var startDragTimeStamp: TimeInterval = 0.0

    /// Heading of camera.
    var cameraHeading: Double = 0

    // MARK: - Private Properties
    /// Returns all Flight Plan's graphics.
    private var flightPlanGraphics: [FlightPlanGraphic] {
        return graphics.compactMap { $0 as? FlightPlanGraphic }
    }
    /// Returns all Flight Plan's waypoint to point of interest graphics.
    private var wayPointToPoiLines: [FlightPlanWayPointToPoiLineGraphic] {
        return graphics.compactMap { $0 as? FlightPlanWayPointToPoiLineGraphic }
    }
    /// Returns all Flight Plan's waypoint line graphics.
    private var wayPointLines: [FlightPlanWayPointLineGraphic] {
        return graphics.compactMap { $0 as? FlightPlanWayPointLineGraphic }
    }
    /// Returns all Flight Plan's waypoint graphics.
    private var wayPoints: [FlightPlanWayPointGraphic] {
        return graphics.compactMap { $0 as? FlightPlanWayPointGraphic }
    }
    /// Returns all Flight Plan's point of interest graphics.
    private var poiPoints: [FlightPlanPoiPointGraphic] {
        return graphics.compactMap { $0 as? FlightPlanPoiPointGraphic }
    }
    /// Returns current insert waypoint graphic, if any (when line is selected).
    private var currentInsertWayPointGraphic: FlightPlanInsertWayPointGraphic? {
        return graphics.compactMap { $0 as? FlightPlanInsertWayPointGraphic }.first
    }
    /// Drone location graphic.
    private var droneGraphic: FlightPlanLocationGraphic?
    /// User location graphic.
    private var userGraphic: FlightPlanLocationGraphic?

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

        sceneProperties?.surfacePlacement = .drapedFlat
        self.graphics.addObjects(from: graphics)
        sortGraphics()
    }

    // MARK: - Override Funcs
    override func deselectAllGraphics() {
        super.deselectAllGraphics()

        let poiLines = graphics.compactMap { $0 as? FlightPlanWayPointToPoiLineGraphic }
        graphics.removeObjects(in: poiLines)
    }
}

// MARK: - Internal Funcs
extension FlightPlanGraphicsOverlay {
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
        case let wayPointGraphic as FlightPlanWayPointGraphic:
            updateWayPointSelection(wayPointGraphic,
                                    isSelected: isSelected)
        default:
            graphic.isSelected = isSelected
        }
        sortGraphics()
        // workound to ensure that graphics order is taken into account by map renderer
        // TODO find a better way to do this
        sortGraphicsDelayed()
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
            poiPointGraphic.poiPoint?.cleanWayPoints()
        } else {
            // Otherwise, create relation.
            assignPoiPointToWayPoint(wayPointGraphic: wayPointGraphic,
                                     poiPointGraphic: poiPointGraphic)
        }
        sortGraphics()
        // workound to ensure that graphics order is taken into account by map renderer
        // TODO find a better way to do this
        sortGraphicsDelayed()
    }

    /// Removes all the lines between waypoints and points of interest.
    func removeAllLinesToPoi() {
        graphics.removeObjects(in: wayPointToPoiLines)
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

        sortGraphics()
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
        sortGraphics()
    }

    /// Move currently dragged graphic to location.
    ///
    /// - Parameters:
    ///    - mapPoint: location to move to
    ///    - editor: flight plan edition view controller
    func updateDraggedGraphicLocation(_ mapPoint: AGSPoint, editor: FlightPlanEditionViewController?) {
        guard let draggedGraphic = draggedGraphic,
              let altitude = draggedGraphic.altitude else {
            return
        }

        let newPoint = mapPoint.withAltitude(altitude)
        switch draggedGraphic {
        case let wayPointGraphic as FlightPlanWayPointGraphic:
            updateWayPointLocation(wayPointGraphic,
                                   location: newPoint, editor: editor)
        case let poiPointGraphic as FlightPlanPoiPointGraphic:
            updatePoiPointLocation(poiPointGraphic,
                                   location: newPoint, editor: editor)
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
    ///    - editor: flight plan edition view controller
    func updateWayPointLocation(_ wayPointGraphic: FlightPlanWayPointGraphic,
                                location: AGSPoint, editor: FlightPlanEditionViewController?) {
        guard let index = wayPointGraphic.wayPointIndex else { return }

        // Update Flight Plan.
        wayPointGraphic.wayPoint?.setCoordinate(location.toCLLocationCoordinate2D())
        wayPointGraphic.wayPoint?.updateTiltRelation()

        // refresh current interface if a wayPoint is selected
        if wayPointGraphic.isSelected, let tilt = wayPointGraphic.wayPoint?.tilt {
            editor?.updateSettingValue(for: TiltAngleSettingType().key, value: Int(tilt))
        }

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
        arrow?.refreshOrientation()
        wayPointGraphic.geometry = location
        let previousArrow = wayPointArrows.first(where: { $0.wayPointIndex == index - 1 })
        let nextArrow = wayPointArrows.first(where: { $0.wayPointIndex == index + 1 })
        previousArrow?.refreshOrientation()
        nextArrow?.refreshOrientation()
    }

    /// Updates location of a point of interest.
    ///
    /// - Parameters:
    ///    - poiPointGraphic: point of interest's graphic
    ///    - location: new location
    ///    - editor: flight plan edition view controller
    func updatePoiPointLocation(_ poiPointGraphic: FlightPlanPoiPointGraphic,
                                location: AGSPoint, editor: FlightPlanEditionViewController?) {
        guard let index = poiPointGraphic.poiIndex else { return }

        // Update Flight Plan.
        poiPointGraphic.poiPoint?.coordinate = location.toCLLocationCoordinate2D()
        wayPoints
            .filter { $0.poiIndex == index }
            .map { $0.wayPoint }
            .forEach {
                $0?.updateYaw()
                $0?.updateTiltRelation()
            }

        // refresh current interface if a wayPoint is selected
        wayPoints.forEach { wayPointGraphic in
            if wayPointGraphic.isSelected, let tilt = wayPointGraphic.wayPoint?.tilt {
                editor?.updateSettingValue(for: TiltAngleSettingType().key, value: Int(tilt))
            }
        }

        // Update all lines towards point of interest.
        wayPointToPoiLines
            .filter { $0.poiIndex == index }
            .forEach { $0.updatePoiPoint(location) }
        poiPointGraphic.geometry = location

        // Update all arrows orientation.
        wayPointArrows
            .filter { $0.poiIndex == index }
            .forEach { $0.refreshOrientation() }
    }

    /// Updates orientation of a waypoint.
    ///
    /// - Parameters:
    ///    - wayPointArrowGraphic: waypoint's arrow graphic
    ///    - location: touch location
    func updateWayPointArrowRotation(_ wayPointArrowGraphic: FlightPlanWayPointArrowGraphic,
                                     location: AGSPoint) {
        guard let wayPointLocation = wayPointArrowGraphic.wayPoint?.agsPoint else { return }

        let newYaw = AGSGeometryEngine.standardGeodeticDistance(between: wayPointLocation,
                                                                and: location,
                                                                azimuthUnit: .degrees())?.azimuth1 ?? 0.0
        wayPointArrowGraphic.wayPoint?.setCustomYaw(newYaw.asPositiveDegrees)
        wayPointArrowGraphic.refreshOrientation()
    }

    // MARK: - Insertion
    /// Inserts waypoint graphics between two existing waypoints.
    ///
    /// - Parameters:
    ///    - wayPoint: waypoint to insert
    ///    - index: index at which it should be inserted
    /// - Returns: inserted waypoint graphic
    func insertWayPoint(_ wayPoint: WayPoint, at index: Int) -> FlightPlanWayPointGraphic? {
        guard let line = wayPointLines.first(where: { $0.wayPointIndex == index - 1 }),
              let originWayPoint = line.originWayPoint,
              let destinationWayPoint = line.destinationWayPoint else {
            return nil
        }

        // Create new graphics.
        let wayPointGraphic = FlightPlanWayPointGraphic(wayPoint: wayPoint,
                                                        index: index, heading: cameraHeading)
        let arrowGraphic = wayPoint.arrowGraphic(index: index)
        let lineBefore = FlightPlanWayPointLineGraphic(origin: originWayPoint,
                                                       destination: wayPoint,
                                                       originIndex: index - 1)
        let lineAfter = FlightPlanWayPointLineGraphic(origin: wayPoint,
                                                      destination: destinationWayPoint,
                                                      originIndex: index)

        // Increment indexes on existing graphics.
        flightPlanGraphics
            .compactMap { $0 as? WayPointRelatedGraphic }
            .filter { $0.wayPointIndex ?? Constants.noIndex >= index }
            .forEach { $0.incrementWayPointIndex() }

        // Refresh previous and next arrow orientation.
        let previousArrow = wayPointArrows.first(where: { $0.wayPointIndex == index - 1 })
        let nextArrow = wayPointArrows.first(where: { $0.wayPointIndex == index + 1 })
        previousArrow?.refreshOrientation()
        nextArrow?.refreshOrientation()

        // Remove existing line.
        graphics.remove(line)

        // Add new graphics.
        graphics.add(wayPointGraphic)
        graphics.add(arrowGraphic)
        graphics.add(lineBefore)
        graphics.add(lineAfter)

        sortGraphics()

        return wayPointGraphic
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
            graphics.add(newGraphic)
        }
        // Remove graphics.
        graphics.remove(wayPoint)
        if let lineBefore = lineBefore {
            graphics.remove(lineBefore)
        }
        if let lineAfter = lineAfter {
            graphics.remove(lineAfter)
        }
        if let poiLine = poiLineForWayPoint(at: index) {
            graphics.remove(poiLine)
        }
        if let arrow = wayPointArrows.first(where: { $0.wayPointIndex == index }) {
            graphics.remove(arrow)
        }
        // Decrement subsequent waypoints, waypoint lines
        // and waypoint to point of interest lines indexes.
        self.flightPlanGraphics
            .compactMap { $0 as? WayPointRelatedGraphic }
            .filter { $0.wayPointIndex ?? Constants.noIndex > index }
            .forEach { $0.decrementWayPointIndex() }

        // Refresh previous and next arrow.
        let previousArrow = wayPointArrows.first(where: { $0.wayPointIndex == index - 1})
        let nextArrow = wayPointArrows.first(where: { $0.wayPointIndex == index })
        previousArrow?.refreshOrientation()
        nextArrow?.refreshOrientation()

        sortGraphics()
    }

    /// Removes point of interest at given index and updates related graphics.
    ///
    /// - Parameters:
    ///    - index: point of interest's index
    func removePoiPoint(at index: Int) {
        guard let poiPoint = poiPoints.first(where: { $0.poiIndex == index }) else { return }

        // Remove graphic.
        graphics.remove(poiPoint)
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

        sortGraphics()
    }

    // MARK: Selected graphic
    /// Returns index of selected graphic.
    ///
    /// - Parameters:
    ///     - type: graphic item type
    /// - Returns: selected item index
    func selectedGraphicIndex(for type: FlightPlanGraphicItemType) -> Int? {
        switch type {
        case .wayPoint:
            return self.wayPoints.first(where: { $0.isSelected })?.wayPointIndex
        case .poi:
            return self.poiPoints.first(where: { $0.isSelected })?.poiIndex
        case .lineWayPoint:
            return self.wayPointLines.first(where: { $0.isSelected })?.wayPointIndex
        case .insertWayPoint,
             .waypointArrow,
             .lineWayPointToPoi,
             .location,
             .none:
            return nil
        }
    }

    /// Retruns graphic for an index and graphic type.
    ///
    /// - Parameters:
    ///     - index: graphic item index
    ///     - type: graphic item type
    /// - Returns: graphic item
    func graphicForIndex(_ index: Int, type: FlightPlanGraphicItemType) -> FlightPlanGraphic? {
        switch type {
        case .wayPoint:
            return wayPoints.first(where: { $0.wayPointIndex == index })
        case .poi:
            return poiPoints.first(where: { $0.poiIndex == index })
        case .lineWayPoint:
            return wayPointLines.first(where: { $0.wayPointIndex == index })
        case .insertWayPoint,
             .waypointArrow,
             .lineWayPointToPoi,
             .location,
             .none:
            return nil
        }
    }

    /// Updates camera heading.
    ///
    /// - Parameters:
    ///     - heading: camera heading
    func update(heading: Double) {
        cameraHeading = heading
        wayPoints.forEach { $0.update(heading: heading) }
        poiPoints.forEach { $0.update(heading: heading) }
        droneGraphic?.update(cameraHeading: heading)
        userGraphic?.update(cameraHeading: heading)
    }

    /// Sets drone location graphic.
    ///
    /// - Parameter graphic: drone location graphic
    func setDroneGraphic(_ graphic: FlightPlanLocationGraphic?) {
        if let graphic = graphic {
            graphics.add(graphic)
            sortGraphicsDelayed()
        } else if let droneGraphic = droneGraphic {
            graphics.remove(droneGraphic)
        }
        droneGraphic = graphic
    }

    /// Sets user location graphic.
    ///
    /// - Parameter graphic: user location graphic
    func setUserGraphic(_ graphic: FlightPlanLocationGraphic?) {
        if let graphic = graphic {
            graphics.add(graphic)
            sortGraphicsDelayed()
        } else if let userGraphic = userGraphic {
            graphics.remove(userGraphic)
        }
        userGraphic = graphic
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
        poiPoint.assignWayPoint(wayPoint: wayPointGraphic.wayPoint)
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
            graphics.add(line)
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
            graphics.remove(line)
        }

        // Update arrow.
        if let arrow = wayPointArrows.first(where: { $0.wayPointIndex == wayPointGraphic.wayPointIndex }) {
            arrow.removePoiPoint()
        }
    }

    /// Selects/deselects waypoint.
    ///
    /// - Parameters:
    ///    - wayPointGraphic: waypoint's graphic
    ///    - isSelected: whether waypoint should be selected.
    func updateWayPointSelection(_ wayPointGraphic: FlightPlanWayPointGraphic,
                                 isSelected: Bool) {
        wayPointGraphic.isSelected = isSelected

        // Update arrow selection if waypoint is not related to a point of interest.
        if wayPointGraphic.poiIndex == nil,
           let arrow = wayPointArrows.first(where: { $0.wayPointIndex == wayPointGraphic.wayPointIndex }) {
            arrow.isSelected = isSelected
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
            graphics.addObjects(from: poiLines)
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

            graphics.add(addGraphic)
        } else {
            guard let graphic = currentInsertWayPointGraphic else { return }

            graphics.remove(graphic)
        }

        // Update waypoint arrows selection if they are not related to points of interest.
        if let originIndex = wayPointLineGraphic.wayPointIndex {
            let previousArrow = wayPointArrows.first(where: { $0.wayPointIndex == originIndex })
            let nextArrow = wayPointArrows.first(where: { $0.wayPointIndex == originIndex + 1 })
            previousArrow?.isSelected = previousArrow?.poiIndex == nil ? isSelected : false
            nextArrow?.isSelected = nextArrow?.poiIndex == nil ? isSelected : false
        }
    }

    /// Sorts displayed graphics asynchronously after a delay.
    ///
    /// This is used as a workaround for overlay rendering issue.
    /// Sometimes, graphics order is not taken into account immediately.
    func sortGraphicsDelayed() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.sortGraphics()
        }
    }

    /// Sorts displayed graphics.
    ///
    /// When using `AGSSceneView` and overlays configured in `drapedFlat` mode,
    /// graphics are render in the order of `graphics` array.
    /// This method arranges the order of graphics elements, in order to control
    /// in what order they are renderer.
    func sortGraphics() {
        guard let fpGraphics = graphics as? [AGSGraphic] else { return }

        // sort by zIndex
        let sortedGraphics = fpGraphics.sorted { $0.zIndex < $1.zIndex }

        // sort by types
        let linesGraphics = sortedGraphics.filter { ($0 as? FlightPlanGraphic)?.itemType == .lineWayPoint }
        let linesToPoiGraphics = sortedGraphics.filter { ($0 as? FlightPlanGraphic)?.itemType == .lineWayPointToPoi }
        let poiGraphics = sortedGraphics.filter { ($0 as? FlightPlanGraphic)?.itemType == .poi }
        let otherGraphics = sortedGraphics.filter {
            !linesGraphics.contains($0)
                && !linesToPoiGraphics.contains($0)
                && !poiGraphics.contains($0)
                && $0 !== userGraphic
                && $0 !== droneGraphic
        }

        var allGraphics = linesGraphics
        allGraphics.append(contentsOf: linesToPoiGraphics)
        allGraphics.append(contentsOf: poiGraphics)
        allGraphics.append(contentsOf: otherGraphics)
        if let userGraphic = userGraphic {
            allGraphics.append(userGraphic)
        }
        if let droneGraphic = droneGraphic {
            allGraphics.append(droneGraphic)
        }

        // raise selected item
        if let selected = allGraphics.first(where: { $0.isSelected }) {
            raiseItem(graphics: &allGraphics, item: selected)
            switch selected {
            case let selected as FlightPlanWayPointLineGraphic:
                // raise origin waypoint, destination waypoint, and insert waypoint graphics
                if let wayPointIndex = selected.wayPointIndex {
                    if let originWayPoint = allGraphics.first(where: { ($0 as? FlightPlanWayPointGraphic)?.wayPointIndex == wayPointIndex }) {
                        raiseItem(graphics: &allGraphics, item: originWayPoint)
                    }
                    if let destWayPoint = allGraphics.first(where: { ($0 as? FlightPlanWayPointGraphic)?.wayPointIndex == wayPointIndex + 1 }) {
                        raiseItem(graphics: &allGraphics, item: destWayPoint)
                    }
                    if let insertWayPoint = allGraphics.first(where: { ($0 as? FlightPlanGraphic)?.itemType == .insertWayPoint }) {
                        raiseItem(graphics: &allGraphics, item: insertWayPoint)
                    }
                }
            case let selected as FlightPlanWayPointGraphic:
                if let wayPointIndex = selected.wayPointIndex {
                    // raise waypoint's arrow
                    if let arrow = allGraphics.first(where: { ($0 as? FlightPlanWayPointArrowGraphic)?.wayPointIndex == wayPointIndex }) {
                        raiseItem(graphics: &allGraphics, item: arrow)
                    }
                }
            case let selected as FlightPlanPoiPointGraphic:
                if let poiIndex = selected.poiIndex {
                    // raise arrows pointing to POI
                    allGraphics.filter { ($0 as? FlightPlanWayPointArrowGraphic)?.poiIndex == poiIndex}
                        .forEach {
                            raiseItem(graphics: &allGraphics, item: $0)
                        }
                }
            default:
                break
            }
        }

        // replace gaphics
        graphics.removeAllObjects()
        graphics.addObjects(from: allGraphics)
    }

    /// Raises a graphic item on top of grahics.
    ///
    /// This moves the item at the end of graphics array.
    ///
    /// - Parameters:
    ///   - graphics: graphics array
    ///   - item: graphic item to raise
    func raiseItem(graphics: inout [AGSGraphic], item: AGSGraphic) {
        if let index = graphics.firstIndex(of: item) {
            graphics.remove(at: index)
        }
        graphics.append(item)
    }
}
