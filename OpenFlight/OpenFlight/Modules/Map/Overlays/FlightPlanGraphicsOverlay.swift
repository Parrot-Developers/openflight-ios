//    Copyright (C) 2022 Parrot Drones SAS
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
import GroundSdk
import CoreLocation
import Combine

// swiftlint:disable file_length
// swiftlint:disable type_body_length

private extension ULogTag {
    static let tag = ULogTag(name: "FlightPlanGraphicsOverlay")
}

/// Flight plan overlay.
public final class FlightPlanGraphicsOverlay: AGSGraphicsOverlay {
    static let Key = "FlightPlanGraphicsOverlayKey"

    // MARK: - Private Enums
    private enum Constants {
        static let overlayKey: String = "flightPlanOverlayKey"
        static let defaultPointAltitude: Double = 5.0
        static let defaultWayPointYaw: Double = 0.0
        static let noIndex: Int = -1
    }

    /// The display tasks cancellation reasons.
    private enum DisplayTasksCancellationReason {
        /// No cancellation ongoing.
        case none
        /// Cancellation due to a memory pressure.
        case memoryPressure(MemoryPressureState)
        /// Cancellation due to a new display call.
        case refreshNeeded(flightPlan: FlightPlanModel,
                           shouldReloadCamera: Bool,
                           mapMode: MapMode,
                           degradedMode: Bool)
        /// Unknown reason.
        case unknown
    }

    // MARK: - Public Properties
    public var flightPlanViewModel = FlightPlanGraphicsOverlayViewModel()
    /// Mission provider.
    private let missionProviderViewModel = MissionProviderViewModel()
    public var flightPlanEditionviewModel: FlightPlanEditionViewModel?
    public var currentMissionProviderState: MissionProviderState?
    public var flightPlanEditionService: FlightPlanEditionService?
    public var isMiniMap: Bool = false {
        didSet {
            refreshOverlay()
        }
    }
    public var flightPlanRunManager: FlightPlanRunManager?

    /// Combine cancellables for current edited flight plan.
    var editionCancellables = Set<AnyCancellable>()

    // MARK: - Public Properties
    /// Returns true if a graphic is currently selected inside Flight Plan.
    var hasSelection: Bool {
        flightPlanGraphics.contains { $0.graphicIsSelected }
    }

    /// Returns a graphic is currently selected inside Flight Plan.
    var currentSelection: FlightPlanGraphic? {
        flightPlanGraphics.first { $0.graphicIsSelected }
    }

    /// Returns all Flight Plan's waypoint arrows.
    var wayPointArrows: [FlightPlanWayPointArrowGraphic] {
        graphics.compactMap { $0 as? FlightPlanWayPointArrowGraphic }
    }

    /// Last manually selected graphic.
    var lastManuallySelectedGraphic: FlightPlanGraphic?

    /// Currently dragged graphic, if any.
    weak var draggedGraphic: FlightPlanPointGraphic?
    /// Timestamp at which the drag started.
    var startDragTimeStamp: TimeInterval = 0.0

    /// Heading of camera.
    var cameraHeading: Double = 0

    /// Returns all Flight Plan's graphics.
    public var flightPlanGraphics: [FlightPlanGraphic] {
        graphics.compactMap { $0 as? FlightPlanGraphic }
    }
    // MARK: - Private Properties
    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    /// Returns all Flight Plan's waypoint to point of interest graphics.
    private var wayPointToPoiLines: [FlightPlanWayPointToPoiLineGraphic] {
        graphics.compactMap { $0 as? FlightPlanWayPointToPoiLineGraphic }
    }
    /// Returns all Flight Plan's waypoint line graphics.
    private var wayPointLines: [FlightPlanWayPointLineGraphic] {
        graphics.compactMap { $0 as? FlightPlanWayPointLineGraphic }
    }
    /// Returns all Flight Plan's waypoint graphics.
    public var wayPoints: [FlightPlanWayPointGraphic] {
        graphics.compactMap { $0 as? FlightPlanWayPointGraphic }
    }
    /// Returns all Flight Plan's point of interest graphics.
    private var poiPoints: [FlightPlanPoiPointGraphic] {
        graphics.compactMap { $0 as? FlightPlanPoiPointGraphic }
    }
    /// Returns current insert waypoint graphic, if any (when line is selected).
    private var currentInsertWayPointGraphic: FlightPlanInsertWayPointGraphic? {
        graphics.compactMap { $0 as? FlightPlanInsertWayPointGraphic }.first
    }
    /// Task dedicated to generate all FP graphics.
    private var generationTask: Task<Void, Never>?
    /// Task dedicated to add all FP graphics to the overlay.
    private var drawingTask: Task<Void, Never>?
    /// The Banner Alert Manager Service.
    private var bamService: BannerAlertManagerService?
    /// The Mission Store.
    private var missionsStore: MissionsStore?
    /// The Memory Pressure Monitor.
    private var memoryPressureMonitor: MemoryPressureMonitorService?
    /// The display tasks cancellation reason.
    private var displayTasksCancellationReason: DisplayTasksCancellationReason = .none

    // MARK: Constructors

    /// Prohibits the use of constructor without services injection.
    @available(swift, obsoleted: 1, message: "Use init with services in parameters.")
    override public init() {}

    /// Constructor.
    ///
    /// - Parameters:
    ///    - bamService: the banner alert manager service
    ///    - missionsStore: the mission store service
    ///    - flightPlanEditionService: the flight plan edition service
    ///    - flightPlanRunManager: the flight plan run manager service
    ///    - memoryPressureMonitor: the memory pressure monitor service
    public init(bamService: BannerAlertManagerService?,
                missionsStore: MissionsStore?,
                flightPlanEditionService: FlightPlanEditionService?,
                flightPlanRunManager: FlightPlanRunManager?,
                memoryPressureMonitor: MemoryPressureMonitorService?) {
        super.init()
        self.bamService = bamService
        self.missionsStore = missionsStore
        self.flightPlanEditionService = flightPlanEditionService
        self.flightPlanRunManager = flightPlanRunManager
        self.memoryPressureMonitor = memoryPressureMonitor
        listenMemoryPressure()
    }

    // MARK: - Deinit
    deinit {
        // Hide the alert when leaving the view.
        showFlightPlanTooBigAlert(false)
    }

    /// Listens to memory pressure `.critical` events to handle high consumption during graphics generation and display.
    private func listenMemoryPressure() {
        memoryPressureMonitor?.eventsPublisher
            .filter { $0 == .critical }
            .sink { [weak self] in
                ULog.w(.tag, "'\($0)' Memory Pressure: Please free up the memory!")
                self?.cancelDisplayTasks(for: .memoryPressure($0))
            }
            .store(in: &cancellables)
    }

    func refreshOverlay() {
        wayPoints.forEach { $0.setReduced(isMiniMap) }
        wayPointLines.forEach { $0.setReduced(isMiniMap) }
        wayPointArrows.forEach { $0.hideArrow(isMiniMap) }
    }

    /// Clears current Flight Plan course.
    public func clearFlightPlanCourse() {
        guard let lineGraphic = graphics.first(where: { $0 is FlightPlanCourseGraphic }) else { return }
        graphics.remove(lineGraphic)
        clearOriginGraphic()
    }

    /// Clears current Flight Plan origin.
    func clearOriginGraphic() {
        guard let originGraphic = graphics.first(where: { $0 is FlightPlanOriginGraphic }) else { return }
        graphics.remove(originGraphic)
    }

    public var flightPlan: FlightPlanModel? {
        didSet {
            let differentFlightPlan = oldValue?.uuid != flightPlan?.uuid
            let settingsChanged = flightPlanEditionService?.settingsChanged ?? []
            let reloadCamera = oldValue?.pictorModel.projectUuid != flightPlan?.pictorModel.projectUuid
            let firstOpen = oldValue == nil
            didUpdateFlightPlan(flightPlan,
                                differentFlightPlan: differentFlightPlan,
                                firstOpen: firstOpen,
                                settingsChanged: settingsChanged,
                                reloadCamera: reloadCamera)
            updateCenterState()
        }
    }

    /// Handles tap action in Flight Plan edition mode.
    ///
    /// - Parameters:
    ///    - geoView: the view on which the tap occured
    ///    - screenPoint: the screen point where the tap occured
    ///    - mapPoint: the corresponding map location
    func handleTap(mapPoint: AGSPoint, result: AGSIdentifyGraphicsOverlayResult?) {
            // Select the graphic tap by user and store it.
        guard let result = result else { return }
        if let selection = result.selectedFlightPlanObject {
            lastManuallySelectedGraphic = selection
            flightPlanEditionviewModel?.didTapGraphicalItem(selection)
        } else {
            // If user has select manually the graphic previously, it will be deselected.
            // else if it was programatically select add a new waypoint
            if let userSelection = lastManuallySelectedGraphic, userSelection.graphicIsSelected {
                flightPlanEditionviewModel?.didTapGraphicalItem(nil)
            } else {
                self.addWaypoint(atLocation: mapPoint)
                flightPlanEditionviewModel?.didChangeCourse()
            }
        }
    }

    /// Adds a waypoint to Flight Plan.
    ///
    /// - Parameters:
    ///    - location: waypoint location
    func addWaypoint(atLocation location: AGSPoint) {
        guard let flightPlanEditionService = flightPlanEditionService
        else { return }
        let lastWayPoint =
        flightPlanEditionService.currentFlightPlanValue?.dataSetting?.wayPoints.last
        let wayPoint = WayPoint(
            coordinate: location.toCLLocationCoordinate2D(),
            altitude: lastWayPoint?.altitude,
            yaw: Constants.defaultWayPointYaw,
            speed: lastWayPoint?.speed,
            shouldContinue:
                flightPlanEditionService.currentFlightPlanValue?.dataSetting?.shouldContinue ?? true,
            tilt: lastWayPoint?.tilt)

        let index = flightPlanEditionService.addWaypoint(wayPoint) - 1
        let wayPointGraphic = wayPoint.markerGraphic(index: index)
        graphics.add(wayPointGraphic)

        let angle = wayPoint.yaw ?? Constants.defaultWayPointYaw
        let arrowGraphic = FlightPlanWayPointArrowGraphic(wayPoint: wayPoint,
                                                          wayPointIndex: index,
                                                          angle: Float(angle))
        graphics.add(arrowGraphic)

        if let lineGraphic = flightPlanEditionService.currentFlightPlanValue?.dataSetting?.lastLineGraphic {
            self.graphics.add(lineGraphic)
        }

        let previousArrow = self.wayPointArrows.first(where: { $0.wayPointIndex == index - 1 })
        previousArrow?.refreshOrientation()

        flightPlanEditionviewModel?.didTapGraphicalItem(wayPointGraphic)
    }

    /// Adds a point of interest to Flight Plan.
    ///
    /// - Parameters:
    ///    - location: point of interest location
    func addPoiPoint(atLocation location: AGSPoint) {
        guard let flightPlanEditionService = flightPlanEditionService
        else { return }
        let poi = PoiPoint(coordinate: location.toCLLocationCoordinate2D(),
                           altitude: Constants.defaultPointAltitude,
                           color: 0)
        let index = flightPlanEditionService.addPoiPoint(poi) - 1
        poi.addIndex(index: index)
        let poiGraphic = poi.markerGraphic(index: index)
        graphics.add(poiGraphic)
        flightPlanEditionviewModel?.didChangePointOfView()
        flightPlanEditionviewModel?.didTapGraphicalItem(poiGraphic)
    }

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
            graphic.graphicIsSelected = isSelected
        }
    }

    /// Selects/deselects waypoint.
    ///
    /// - Parameters:
    ///    - wayPointGraphic: waypoint's graphic
    ///    - isSelected: whether waypoint should be selected.
    func updateWayPointSelection(_ wayPointGraphic: FlightPlanWayPointGraphic,
                                 isSelected: Bool) {

        wayPointGraphic.graphicIsSelected = isSelected

        // Update arrow selection if waypoint is not related to a point of interest.
        if let arrow = wayPointArrows.first(where: { $0.wayPointIndex == wayPointGraphic.wayPointIndex }) {
            arrow.graphicIsSelected = isSelected
            arrow.refreshOrientation()
        }
    }

    /// Selects/deselects point of interest.
    ///
    /// - Parameters:
    ///    - poiPointGraphic: point of interest's graphic
    ///    - isSelected: whether point of interest should be selected.
    func updatePoiPointSelection(_ poiPointGraphic: FlightPlanPoiPointGraphic,
                                 isSelected: Bool) {
        poiPointGraphic.graphicIsSelected = isSelected
        wayPointArrows
            .filter { $0.poiIndex == poiPointGraphic.poiIndex }
            .forEach {
                $0.graphicIsSelected = false
                $0.poiIsSelected = isSelected
                $0.refreshOrientation()
            }
        if isSelected {
            // Creates waypoint to point of interest lines.
            let poiLines = wayPoints
                .filter { $0.poiIndex == poiPointGraphic.poiIndex }
                .compactMap { wayPointGraphic in
                    FlightPlanWayPointToPoiLineGraphic(wayPointGraphic: wayPointGraphic,
                                                       poiPointGraphic: poiPointGraphic)
                }
            graphics.addObjects(from: poiLines)
        } else {
            // Removes waypoint to point of interest lines.
            removeAllLinesToPoi()
        }
    }

    // MARK: Deletion
    /// Removes waypoint at given index and updates related graphics.
    ///
    /// - Parameters:
    ///    - index: waypoint's index
    func removeWayPoint(at index: Int) {
        guard let wayPoint = wayPoints.first(where: { $0.wayPointIndex == index }) else { return }

        let wpLines = wayPointLines
        let lineBefore = wpLines.first { $0.wayPointIndex == index-1 }
        let lineAfter = wpLines.first { $0.wayPointIndex == index }
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
        lineBefore.map { graphics.remove($0) }
        lineAfter.map { graphics.remove($0) }
        poiLineForWayPoint(at: index).map { graphics.remove($0) }
        wayPointArrows.first(where: { $0.wayPointIndex == index }).map {
            graphics.remove($0)
        }
        // Decrement subsequent waypoints, waypoint lines
        // and waypoint to point of interest lines indexes.
        flightPlanGraphics
            .compactMap { $0 as? WayPointRelatedGraphic }
            .filter { $0.wayPointIndex ?? Constants.noIndex > index }
            .forEach { $0.decrementWayPointIndex() }

        // Refresh previous and next arrow.
        let previousArrow = wayPointArrows.first { $0.wayPointIndex == index - 1}
        let nextArrow = wayPointArrows.first { $0.wayPointIndex == index }
        previousArrow?.refreshOrientation()
        nextArrow?.refreshOrientation()
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
        let previousArrow = wayPointArrows.first { $0.wayPointIndex == index - 1 }
        let nextArrow = wayPointArrows.first { $0.wayPointIndex == index + 1 }
        previousArrow?.refreshOrientation()
        nextArrow?.refreshOrientation()

        // Remove existing line.
        graphics.remove(line)

        // Add new graphics.
        graphics.add(arrowGraphic)
        graphics.add(wayPointGraphic)
        graphics.add(lineBefore)
        graphics.add(lineAfter)

        return wayPointGraphic
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
    }

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
            .first { $0.wayPointIndex == index }?
            .updateAltitude(altitude)
        if let mapPoint = wpGraphic.mapPoint {
            lineBeforeWayPoint(at: index)?.updateEndPoint(mapPoint)
            lineAfterWayPoint(at: index)?.updateStartPoint(mapPoint)
        }
    }

    // MARK: Graphics Getters
    /// Returns point of interest graphic at given index.
    ///
    /// - Parameters:
    ///    - index: point of interest's index
    /// - Returns: point of interest's graphic, if it exists
    func poiPoint(at index: Int) -> FlightPlanPoiPointGraphic? {
        poiPoints.first { $0.poiIndex == index }
    }

    /// Returns waypoint line before waypoint at given index.
    ///
    /// - Parameters:
    ///    - index: waypoint's index
    /// - Returns: waypoint line, if it exists
    func lineBeforeWayPoint(at index: Int) -> FlightPlanWayPointLineGraphic? {
        wayPointLines.first { $0.wayPointIndex == index-1 }
    }

    /// Returns waypoint line after waypoint at given index.
    ///
    /// - Parameters:
    ///    - index: waypoint's index
    /// - Returns: waypoint line, if it exists
    func lineAfterWayPoint(at index: Int) -> FlightPlanWayPointLineGraphic? {
        wayPointLines.first { $0.wayPointIndex == index }
    }

    /// Returns point of interest line for waypoint at given index.
    ///
    /// - Parameters:
    ///    - index: waypoint's index
    /// - Returns: point of interest line, if it exists
    func poiLineForWayPoint(at index: Int) -> FlightPlanWayPointToPoiLineGraphic? {
        wayPointToPoiLines.first { $0.wayPointIndex == index }
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
    
    /// Removes all the lines between waypoints and points of interest.
    func removeAllLinesToPoi() {
        graphics.removeObjects(in: wayPointToPoiLines)
    }

    /// Selects/deselects waypoint line.
    ///
    /// - Parameters:
    ///    - wayPointLineGraphic: waypoint line's graphic
    ///    - isSelected: whether point of interest should be selected.
    func updateWayPointLineSelection(_ wayPointLineGraphic: FlightPlanWayPointLineGraphic,
                                     isSelected: Bool) {
        wayPointLineGraphic.graphicIsSelected = isSelected
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
            let previousArrow = wayPointArrows.first { $0.wayPointIndex == originIndex }
            let nextArrow = wayPointArrows.first { $0.wayPointIndex == originIndex + 1 }
            previousArrow?.graphicIsSelected = previousArrow?.poiIndex == nil ? isSelected : false
            nextArrow?.graphicIsSelected = nextArrow?.poiIndex == nil ? isSelected : false
        }
    }

    /// Move currently dragged graphic to location.
    ///
    /// - Parameters:
    ///    - mapPoint: location to move to
    ///    - editor: flight plan edition view controller
    ///    - isDragging: whether the map point is currencly been moved
    func updateDraggedGraphicLocation(_ mapPoint: AGSPoint, editor: FlightPlanEditionViewController?, isDragging: Bool = false) {
        guard let draggedGraphic = draggedGraphic,
              let altitude = draggedGraphic.altitude else {
            return
        }
        let newPoint = mapPoint.withAltitude(altitude)
        switch draggedGraphic {
        case let wayPointGraphic as FlightPlanWayPointGraphic:
            updateWayPointLocation(wayPointGraphic,
                                   location: newPoint, editor: editor, isDragging: isDragging)
        case let poiPointGraphic as FlightPlanPoiPointGraphic:
            updatePoiPointLocation(poiPointGraphic,
                                   location: newPoint, editor: editor, isDragging: isDragging)
        case let wayPointArrowGraphic as FlightPlanWayPointArrowGraphic:
            updateWayPointArrowRotation(wayPointArrowGraphic,
                                        location: newPoint, isDragging: isDragging)
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
    ///    - isDragging: whether the waypoint is currencly been moved
    func updateWayPointLocation(_ wayPointGraphic: FlightPlanWayPointGraphic,
                                location: AGSPoint, editor: FlightPlanEditionViewController?, isDragging: Bool) {
        guard let index = wayPointGraphic.wayPointIndex else { return }

        // Update Flight Plan.
        wayPointGraphic.wayPoint?.setCoordinate(location.toCLLocationCoordinate2D())
        wayPointGraphic.wayPoint?.updateTiltRelation()

        // refresh current interface if a wayPoint is selected
        if wayPointGraphic.graphicIsSelected, let tilt = wayPointGraphic.wayPoint?.tilt {
            editor?.updateSettingValue(for: TiltAngleSettingType().key, value: Int(tilt))
        }

        // Get all lines concerned by this waypoint.
        let lines = wayPointLines
        let lineBefore = lines.first { $0.wayPointIndex == index - 1 }
        let lineAfter = lines.first { $0.wayPointIndex == index }
        let poiLine = wayPointToPoiLines.first { $0.wayPointIndex == index }
        let arrow = wayPointArrows.first { $0.wayPointIndex == index }

        /// Update geometries.
        guard let wayPoint = wayPointGraphic.wayPoint else { return }
        lineBefore?.updateEndPoint(wayPoint.agsPoint)
        lineAfter?.updateStartPoint(wayPoint.agsPoint)
        if let addGraphic = currentInsertWayPointGraphic {
            if lineBefore?.graphicIsSelected == true {
                addGraphic.geometry = lineBefore?.middlePoint
            } else if lineAfter?.graphicIsSelected == true {
                addGraphic.geometry = lineAfter?.middlePoint
            }
        }
        poiLine?.updateWayPoint(location)
        arrow?.geometry = location
        arrow?.refreshOrientation()
        wayPointGraphic.geometry = location
        let previousArrow = wayPointArrows.first { $0.wayPointIndex == index - 1 }
        let nextArrow = wayPointArrows.first { $0.wayPointIndex == index + 1 }
        previousArrow?.refreshOrientation()
        nextArrow?.refreshOrientation()
    }

    /// Updates location of a point of interest.
    ///
    /// - Parameters:
    ///    - poiPointGraphic: point of interest's graphic
    ///    - location: new location
    ///    - editor: flight plan edition view controller
    ///    - isDragging: whether the poi is currencly been moved
    func updatePoiPointLocation(_ poiPointGraphic: FlightPlanPoiPointGraphic,
                                location: AGSPoint, editor: FlightPlanEditionViewController?, isDragging: Bool) {
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
            if wayPointGraphic.graphicIsSelected,
               let tilt = wayPointGraphic.wayPoint?.tilt {
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
    ///    - isDragging: whether the arrow is currencly been moved
    func updateWayPointArrowRotation(_ wayPointArrowGraphic: FlightPlanWayPointArrowGraphic,
                                     location: AGSPoint, isDragging: Bool) {
        guard let wayPointLocation = wayPointArrowGraphic.wayPoint?.agsPoint else { return }

        let newYaw = AGSGeometryEngine.standardGeodeticDistance(between: wayPointLocation,
                                                                and: location,
                                                                azimuthUnit: .degrees())?.azimuth1 ?? 0.0
        wayPointArrowGraphic.wayPoint?.setCustomYaw(newYaw.asPositiveDegrees)
        wayPointArrowGraphic.refreshOrientation()
    }

    private func clearGraphics() {
        graphics.removeAllObjects()
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
            return wayPoints.first { $0.graphicIsSelected }?.wayPointIndex
        case .poi:
            return poiPoints.first { $0.graphicIsSelected }?.poiIndex
        case .lineWayPoint:
            return wayPointLines.first { $0.graphicIsSelected }?.wayPointIndex
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
            return wayPoints.first { $0.wayPointIndex == index }
        case .poi:
            return poiPoints.first { $0.poiIndex == index }
        case .lineWayPoint:
            return wayPointLines.first { $0.wayPointIndex == index }
        case .insertWayPoint,
             .waypointArrow,
             .lineWayPointToPoi,
             .location,
             .none:
            return nil
        }
    }
}

// Display of flight plan
extension FlightPlanGraphicsOverlay {
    /// Did update flight plan
    /// - Parameters:
    ///    - flightPlan: flight plan
    ///    - differentFlightPlan: whether the updated flight plan is a different one. If false the
    ///    current flightplan was updated, if true the flight plan was replaced by a different one.
    ///    - firstOpen: whether this is the first flight plan of the controller
    ///    - settingsChanged: indicating whether the update contains a settings change
    ///    - reloadCamera: reload camera
    /// - Returns: FlightPlanEditionViewController
    public func didUpdateFlightPlan(_ flightPlan: FlightPlanModel?, differentFlightPlan: Bool,
                                    firstOpen: Bool, settingsChanged: [FlightPlanLightSetting],
                                    reloadCamera: Bool) {
        guard let newFlightPlan = flightPlan else {
            graphics.removeAllObjects()
            return
        }

        if differentFlightPlan {
            displayFlightPlan(newFlightPlan, shouldReloadCamera: reloadCamera)
        }
    }

    /// Sets up mission provider view model.
    public func setupMissionProviderViewModel() {
        missionProviderViewModel.state.valueChanged = { [weak self] state in
            self?.missionProviderDidChange(state)
        }
        // Set initial mission provider state.
        let state = missionProviderViewModel.state.value
        missionProviderDidChange(state)
    }

    /// Mission provider did change.
    ///
    /// - Parameters:
    ///    - missionMode: missionProviderState to set
    public func missionProviderDidChange(_ missionProviderState: MissionProviderState) {
        currentMissionProviderState = missionProviderState
    }

    /// Updates map with a flight plan.
    /// - Parameters:
    ///    - flightPlan: the updated flight plan
    public func update(with flightPlan: FlightPlanModel) {
        displayFlightPlan(flightPlan, shouldReloadCamera: false)
    }

    /// Called to display a flight plan.
    ///
    /// - Parameters:
    ///    - flightPlan: flight plan model
    ///    - shouldReloadCamera: whether scene's camera should be reloaded
    ///    - mapMode: the map mode
    ///    - degradedMode: whether the display is degraded (only trajectory)
    func displayFlightPlan(_ flightPlan: FlightPlanModel,
                           shouldReloadCamera: Bool = false,
                           mapMode: MapMode = .flightPlan,
                           degradedMode: Bool = false) {
        // Ensure no displaying task is ongoing.
        guard generationTask == nil,
              drawingTask == nil else {
            ULog.w(.tag, "Map update is already ongoing")
            var isDegradedMode = degradedMode
            // If there is already a cancelling due to a memory pressure,
            // force the degraded display mode.
            if case .memoryPressure = displayTasksCancellationReason {
                isDegradedMode = true
            }
            // Cancelling the current tasks for a `refreshNeeded` reason will trigger,
            // after cancellation handling, a new display call for the new flight plan.
            cancelDisplayTasks(for: .refreshNeeded(flightPlan: flightPlan,
                                                   shouldReloadCamera: shouldReloadCamera,
                                                   mapMode: mapMode,
                                                   degradedMode: isDegradedMode))
            return
        }

        // Hide, if needed, the FP too big alert.
        showFlightPlanTooBigAlert(false)
        // Remove old Flight Plan graphic overlay.
        graphics.removeAllObjects()
        // Get flight plan provider.
        let provider: FlightPlanProvider?
        if let mission = currentMissionProviderState?.mode {
            provider = mission.flightPlanProvider
        } else if let mission = missionsStore?.missionFor(flightPlan: flightPlan)?.mission {
            provider = mission.flightPlanProvider
        } else {
            return
        }

        guard let provider = provider else {
            ULog.e(.tag, "No Flight Plan provider found")
            return
        }

        generationTask = Task {
            ULog.i(.tag, "Start Graphics Generation. Degraded display: \(degradedMode)")
            // In any cases, refresh the map centering at the end of the process.
            defer {
                DispatchQueue.main.async {
                    if shouldReloadCamera { self.flightPlanViewModel.refreshViewPoint.value = true }
                }
            }
            // Generate all graphics.
            // In case of degraded display mode, only trajectory is generated.
            let generationResult = await provider.graphics(for: flightPlan,
                                                           mapMode: mapMode,
                                                           graphicsMode: degradedMode ? .onlyTrajectory : flightPlan.defaultGraphicsMode)
            if Task.isCancelled {
                ULog.e(.tag, "Generation task cancelled")
                generationTask = nil
                handleDisplayTasksCancellation(flightPlan,
                                               shouldReloadCamera: shouldReloadCamera,
                                               mapMode: mapMode,
                                               degradedMode: degradedMode)
                return
            }
            // Add generated graphics to the map.
            drawGraphics(generationResult.graphics)
            generationTask = nil
            // Inform user we are in degraded display mode.
            if degradedMode { await MainActor.run { showFlightPlanTooBigAlert(true) } }
        }
    }

    /// Update center state value
    func updateCenterState() {
        if let flightPlan = flightPlan, !flightPlan.isEmpty {
            flightPlanViewModel.centerState.value = .project
        } else {
            flightPlanViewModel.centerState.value = .none
        }
    }

    /// Adds the graphics to the map.
    ///
    /// - Parameter graphics: the ArcGis graphics
    func drawGraphics(_ graphics: [FlightPlanGraphic]) {
        drawingTask = Task { @MainActor [weak self] in
            for graphic in graphics {
                self?.graphics.add(graphic)
                if Task.isCancelled {
                    ULog.e(.tag, "Drawing task cancelled")
                    drawingTask = nil
                    handleDisplayTasksCancellation()
                    return
                }
            }
            drawingTask = nil
        }
    }

    /// Shows/hides the alert indicating the flight plan is too big to be drawn on the map.
    ///
    /// - Parameter show: whether the alert must be shown
    func showFlightPlanTooBigAlert(_ show: Bool) {
        bamService?.update(WarningBannerAlert.flightPlanTooBigToBeDisplayed, show: show)
    }

    /// Cancels the current display tasks.
    ///
    /// - Parameter reason: the cancellation reason
    private func cancelDisplayTasks(for reason: DisplayTasksCancellationReason) {
        ULog.i(.tag, "Cancelling current display tasks")
        displayTasksCancellationReason = reason
        generationTask?.cancel()
        drawingTask?.cancel()
    }

    /// Handles display tasks cancellation.
    ///
    /// - Parameters:
    ///   - flightPlan: the current flight plan to display
    ///   - shouldReloadCamera: whether scene's camera should be reloaded
    ///   - mapMode: the map mode
    ///   - degradedMode: whether the display is asked in degraded mode
    func handleDisplayTasksCancellation(_ flightPlan: FlightPlanModel? = nil,
                                        shouldReloadCamera: Bool = false,
                                        mapMode: MapMode = .flightPlan,
                                        degradedMode: Bool = false) {
        let reason = displayTasksCancellationReason
        // Reset cancellation reason.
        displayTasksCancellationReason = .none
        // Perform action according to cancellation reason.
        switch reason {
        case .memoryPressure:
            // Task has been cancelled by a low memory issue.
            // Try, if it's not already the case, the degraded display mode.
            // Show an alert about the degraded display mode otherwise.
            if !degradedMode,
               let flightPlan = flightPlan {
                ULog.i(.tag, "Restart in degraded mode after memory pressure")
                displayFlightPlan(flightPlan,
                                  shouldReloadCamera: shouldReloadCamera,
                                  mapMode: mapMode,
                                  degradedMode: true)
            } else {
                showFlightPlanTooBigAlert(true)
            }
        case .refreshNeeded(let flightPlan, let shouldReloadCamera, let mapMode, let degradedMode):
            // An up-to-date flight plan needs to be displayed.
            // Start a new display task with this flight plan.
            ULog.i(.tag, "Displaying the new flight plan")
            displayFlightPlan(flightPlan,
                              shouldReloadCamera: shouldReloadCamera,
                              mapMode: mapMode,
                              degradedMode: degradedMode)
        default:
            break
        }
    }
}
