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

import Foundation
import Combine
import CoreLocation
import ArcGIS

/// View controller for flightplan map.
open class FlightPlanMapViewController: AGSMapViewController {

    // MARK: - Private Properties
    private var flightPlanViewModel = FlightPlanViewModel()

    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    private var editionCancellables = Set<AnyCancellable>()

    private var userLocationOverlay: UserLocationGraphicsOverlay?
    private var droneLocationOverlay: DroneLocationGraphicsOverlay?
    private var returnHomeOverlay: ReturnHomeGraphicsOverlay?
    private var flightPlanOverlay: FlightPlanGraphicsOverlay?
    private var oldDroneLocation: Location3D?
    private var canUpdateDroneLocation = true

    private var bamService: BannerAlertManagerService?
    private var missionsStore: MissionsStore?
    private var rthService: RthService?
    private var memoryPressureMonitor: MemoryPressureMonitorService?

    // MARK: - Internal Properties
    public var flightPlanEditionViewController: FlightPlanEditionViewController?
    public var currentMissionProviderState: MissionProviderState?
    public var flightPlanEditionService: FlightPlanEditionService?
    public var flightPlanRunManager: FlightPlanRunManager?
    public weak var flightDelegate: FlightEditionDelegate?
    // Is flight plan in edition
    public var isInEdition = false
    weak var mapDelegate: MapViewEditionControllerDelegate?
    /// Mission provider.
    private let missionProviderViewModel = MissionProviderViewModel()

    private enum OverlayOrder: Int, Comparable {

        case rthPath
        case home
        case user
        case flightPlan
        case drone // must always be last in mapView. This is only for information.

        static func < (lhs: FlightPlanMapViewController.OverlayOrder, rhs: FlightPlanMapViewController.OverlayOrder) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }

        /// Set containing all possible overlays.
        public static let allCases: Set<OverlayOrder> = [
            .rthPath, .home, .user, .flightPlan, .drone]
    }

    // MARK: - Setup
    /// Instantiates the view controller.
    ///
    /// - Parameters:
    ///    - bamService: the banner alert manager service
    ///    - missionsStore: the mission store service
    ///    - flightPlanEditionService: the flight plan edition service
    ///    - flightPlanRunManager: the flight plan run manager service
    ///    - rthService: the rth service
    ///    - memoryPressureMonitor: the memory pressure monitor service
    ///
    /// - Returns: the piloting map view controller
    public static func instantiate(bamService: BannerAlertManagerService,
                                   missionsStore: MissionsStore,
                                   flightPlanEditionService: FlightPlanEditionService,
                                   flightPlanRunManager: FlightPlanRunManager,
                                   rthService: RthService,
                                   memoryPressureMonitor: MemoryPressureMonitorService) -> FlightPlanMapViewController {
        let viewController = StoryboardScene.FlightPlanMap.initialScene.instantiate()
        viewController.bamService = bamService
        viewController.missionsStore = missionsStore
        viewController.flightPlanEditionService = flightPlanEditionService
        viewController.flightPlanRunManager = flightPlanRunManager
        viewController.rthService = rthService
        viewController.memoryPressureMonitor = memoryPressureMonitor
        return viewController
    }

    // MARK: - Override Funcs
    open override func viewDidLoad() {
        super.viewDidLoad()

        // Add overlays according to their `OverlayOrder`, as `mapView.graphicsOverlays` is
        // an empty array at load time (which means that inserting `.user` and then `.home`
        // whould lead to an incorrect [.user, .home] array).
        addReturnHomeOverlay()
        addHomeOverlay(at: OverlayOrder.home.rawValue)
        addUserOverlay()
        addFlightPlanOverlay()
        addDroneOverlay()

        setupMissionProviderViewModel()

        droneLocationOverlay?.viewModel.droneLocationPublisher
            .sink(receiveValue: { [weak self] location in
            if let coordinates = location.coordinates {
                self?.updateDroneLocationGraphic(location: coordinates)
            }
        }).store(in: &cancellables)

        flightPlanViewModel.centerStatePublisher.sink { [weak self] centerState in
            self?.splitControls?.updateCenterMapButtonStatus(state: centerState)

        }.store(in: &cancellables)
    }

    public override func getCenter(completion: @escaping(AGSViewpoint?) -> Void) {
         completion(getCurrentViewPoint())
    }

    override func identify(screenPoint: CGPoint, _ completion: @escaping (AGSIdentifyGraphicsOverlayResult?) -> Void) {

        guard let flightPlanOverlay = flightPlanOverlay else { return }

        self.mapView.identify(flightPlanOverlay,
                              screenPoint: screenPoint,
                              tolerance: CommonMapConstants.viewIdentifyTolerance,
                              returnPopupsOnly: false,
                              maximumResults: CommonMapConstants.viewIdentifyMaxResults) { (result: AGSIdentifyGraphicsOverlayResult) in
            completion(result)
        }
    }

    // MARK: - Gestures Funcs
    override func handleCustomMapTap(mapPoint: AGSPoint, screenPoint: CGPoint, identifyResult: AGSIdentifyGraphicsOverlayResult?) {
        guard isInEdition, let result = identifyResult else { return }
        // Select the graphic tap by user and store it.
        if let selection = result.selectedFlightPlanObject {
            flightPlanOverlay?.lastManuallySelectedGraphic = selection
            flightDelegate?.didTapGraphicalItem(selection)
        } else {
            // If user has select manually the graphic previously, it will be deselected.
            // else if it was programatically select add a new waypoint
            if let userSelection = flightPlanOverlay?.lastManuallySelectedGraphic, userSelection.isSelected {
                flightDelegate?.didTapGraphicalItem(nil)
            } else {
                flightPlanOverlay?.addWaypoint(atLocation: mapPoint)
                flightDelegate?.didChangeCourse()
            }
        }
    }

    override func handleCustomMapLongPress(mapPoint: AGSPoint, identifyResult: AGSIdentifyGraphicsOverlayResult?) {
        guard isInEdition, let result = identifyResult else { return }
        if result.selectedFlightPlanObject == nil {
            flightPlanOverlay?.addPoiPoint(atLocation: mapPoint)
        }
    }

    override func handleCustomMapTouchDown(mapPoint: AGSPoint, identifyResult: AGSIdentifyGraphicsOverlayResult?, completion: @escaping (Bool) -> Void) {
        guard isInEdition, let overlay = flightPlanOverlay, let result = identifyResult else {
            completion(false)
            return
        }
        guard let selection = result.selectedFlightPlanObject as? FlightPlanPointGraphic,
              selection.itemType.draggable,
              result.error == nil else {
            completion(false)
            return
        }

        if let arrowGraphic = selection as? FlightPlanWayPointArrowGraphic,
           !arrowGraphic.isOrientationEditionAllowed(mapPoint) {
            completion(false)
            return
        }

        if (selection as? WayPointRelatedGraphic)?.wayPointIndex == nil,
           (selection as? PoiPointRelatedGraphic)?.poiIndex == nil {
            completion(false)
            return
        }

        overlay.draggedGraphic = selection
        overlay.startDragTimeStamp = ProcessInfo.processInfo.systemUptime
        completion(true)
    }

    override func handleCustomMapDrag(mapPoint: AGSPoint) {
        guard isInEdition else { return }

        // Drag should be ignored if it occurs before a certain duration (to avoid conflict with tap gesture).
        guard let dragTimeStamp = flightPlanOverlay?.startDragTimeStamp,
            ProcessInfo.processInfo.systemUptime > dragTimeStamp + Style.tapGestureDuration else {
                return
        }

        flightPlanOverlay?.updateDraggedGraphicLocation(mapPoint, editor: nil, isDragging: true)
    }

    override func handleCustomMapTouchUp(screenPoint: CGPoint, mapPoint: AGSPoint) {
        guard isInEdition else { return }

        // If touch up occurs before a certain duration, gesture is treated as a tap.
        guard let dragTimeStamp = flightPlanOverlay?.startDragTimeStamp,
            ProcessInfo.processInfo.systemUptime > dragTimeStamp + Style.tapGestureDuration else {
            identify(screenPoint: screenPoint) { [weak self] result in
                self?.handleCustomMapTap(mapPoint: mapPoint, screenPoint: screenPoint, identifyResult: result)
            }
            resetDraggedGraphics()
            return
        }
        flightPlanOverlay?.updateDraggedGraphicLocation(mapPoint, editor: flightPlanEditionViewController)

        // Update graphics.
        if flightPlanOverlay?.draggedGraphic is FlightPlanWayPointGraphic {
            flightDelegate?.didChangeCourse()
        } else if flightPlanOverlay?.draggedGraphic is FlightPlanPoiPointGraphic {
            flightDelegate?.didChangePointOfView()
        } else if flightPlanOverlay?.draggedGraphic is FlightPlanWayPointArrowGraphic {
            flightDelegate?.didChangePointOfView()
        }

        resetDraggedGraphics()
    }

    /// Resets currently dragged graphic on overlays.
    func resetDraggedGraphics() {
        flightPlanOverlay?.draggedGraphic = nil
        flightPlanOverlay?.startDragTimeStamp = 0.0
    }

    public override func miniMapChanged(value: Bool) {
        super.miniMapChanged(value: value)
        flightPlanOverlay?.isMiniMap = value
        droneLocationOverlay?.viewModel.update(isMiniMap: value)
        userLocationOverlay?.viewModel.isMiniMap.value = value
    }

    // MARK: - Editions Funcs
    /// Returns flight plan edition screen with a selected edition mode.
    ///
    /// - Parameters:
    ///     - panelCoordinator: flight plan panel coordinator
    ///     - flightPlanServices: flight plan services
    /// - Returns: FlightPlanEditionViewController
    open func editionProvider(panelCoordinator: FlightPlanPanelCoordinator,
                              flightPlanServices: FlightPlanServices,
                              navigationStack: NavigationStackService) -> FlightPlanEditionViewController {
        let flightPlanProvider = currentMissionProviderState?.mode?.flightPlanProvider
        let backButtonPublisher = backButton.tapGesturePublisher
            .map { _ in () }
            .eraseToAnyPublisher()
        let viewController = FlightPlanEditionViewController.instantiate(
            panelCoordinator: panelCoordinator,
            flightPlanServices: flightPlanServices,
            mapViewController: self,
            flightPlanProvider: flightPlanProvider,
            navigationStack: navigationStack,
            backButtonPublisher: backButtonPublisher)
        flightPlanEditionViewController = viewController
        flightPlanOverlay?.flightPlanEditionviewModel = flightPlanEditionViewController?.viewModel
        return viewController
    }

    /// Sets up mission provider view model.
    func setupMissionProviderViewModel() {
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
    open func missionProviderDidChange(_ missionProviderState: MissionProviderState) {
        currentMissionProviderState = missionProviderState
        setupFlightPlanListener(for: missionProviderState)
    }

    // MARK: - Public Funcs
    /// Setup Flight Plan listener regarding mission mode.
    ///
    /// - Parameters:
    ///     - state: Mission Mode State
    func setupFlightPlanListener(for state: MissionProviderState) {
        if state.mode?.flightPlanProvider != nil {
            // Unregister potential existing listeners
            editionCancellables.removeAll()
            // Reset registration.
            flightPlanEditionService?.currentFlightPlanPublisher
                .removeDuplicates()
                .sink(receiveValue: { [weak self] flightplan in
                    self?.flightPlanOverlay?.flightPlan = flightplan
                })
                .store(in: &editionCancellables)
            // Update the map when an FP just setted up in the editor.
            flightPlanEditionService?.flightPlanSettedUpPublisher
                .sink { [weak self] in self?.update(with: $0) }
                .store(in: &editionCancellables)
        } else {
            // Remove potential old Flight Plan first.
            flightPlanEditionService?.resetFlightPlan()
            // Then, unregister flight plan listener (editionCancellable = nil has effet if map is registred).
            editionCancellables.removeAll()
        }
    }

    /// Updates map with a flight plan.
    /// - Parameters:
    ///    - flightPlan: the updated flight plan
    open func update(with flightPlan: FlightPlanModel) {
        flightPlanOverlay?.displayFlightPlan(flightPlan, shouldReloadCamera: false)
    }

    /// Returns an executions list view controller with map's back button publisher.
    ///
    /// - Parameters:
    ///    - delegate: the executions list delegate
    ///    - flightPlanHandler: the filght plan handler
    ///    - projectManager: the project manager
    ///    - projectModel: the project model
    ///    - flightService: the flight service
    ///    - topBarService: the top bar service
    /// - Returns: the executions list view controller
    func executionsListProvider(delegate: ExecutionsListDelegate?,
                                flightPlanHandler: FlightPlanManager,
                                projectManager: ProjectManager,
                                projectModel: ProjectModel,
                                flightService: FlightService,
                                flightPlanRepo: FlightPlanRepository,
                                topBarService: HudTopBarService) -> ExecutionsListViewController {
        let backButtonPublisher = backButton.tapGesturePublisher
            .map { _ in () }
            .eraseToAnyPublisher()
        let viewController = ExecutionsListViewController.instantiate(
            delegate: delegate,
            flightPlanHandler: flightPlanHandler,
            projectManager: projectManager,
            projectModel: projectModel,
            flightService: flightService,
            flightPlanRepo: flightPlanRepo,
            topBarService: topBarService,
            backButtonPublisher: backButtonPublisher)
        return viewController
    }
}

extension FlightPlanMapViewController {
    // MARK: - Private Funcs

    /// Get Current view point to center map.
    ///
    /// The view point is determined in this order :
    ///     1/ Drone is connected and flying
    ///     2/ A flight plan exists and is not empty
    ///     3/ Drone is connected
    ///     4/ User is connected
    ///
    /// - Returns: the current view point
    private func getCurrentViewPoint() -> AGSViewpoint? {
        var droneIsNotFlying = true
        if let drone = flightPlanViewModel.connectedDroneHolder.drone, drone.isFlying {
            droneIsNotFlying = false
        }

        if flightPlanOverlay?.flightPlanViewModel.centerState.value == .project, let dataSetting = flightPlanOverlay?.flightPlan?.dataSetting,
           let flightPlan = flightPlanOverlay?.flightPlan, !flightPlan.isEmpty, !mapViewModel.isMiniMap.value,
           droneIsNotFlying {
            let envelope = dataSetting.polyline.envelopeWithMargin(ArcGISStyle.projectEnvelopeMarginFactor,
                                                       altitudeOffset: 0)
            return AGSViewpoint(targetExtent: envelope)
        } else {
            if let value = droneLocationOverlay?.isActive.value, value, let coordinate = droneLocationOverlay?.viewModel.droneLocation.coordinates?.coordinate {
                    return AGSViewpoint(center: AGSPoint(clLocationCoordinate2D: coordinate), scale: CommonMapConstants.cameraDistanceToCenterLocation)
            } else {
                if let coordinate = userLocationOverlay?.viewModel.userLocation?.coordinates?.coordinate {
                    return AGSViewpoint(center: AGSPoint(clLocationCoordinate2D: coordinate), scale: CommonMapConstants.cameraDistanceToCenterLocation)
                }
            }
        }
        return nil
    }

    /// Add the user location overlay
    private func addUserOverlay() {
        userLocationOverlay = UserLocationGraphicsOverlay()
        userLocationOverlay?.sceneProperties?.surfacePlacement = .drapedFlat
        if let userLocationOverlay = userLocationOverlay {
            self.mapView.graphicsOverlays.insert(userLocationOverlay, at: OverlayOrder.user.rawValue)
            self.checkOrderAndInsertOverlay()
        }
    }

    /// Add the drone location overlay
    private func addDroneOverlay() {
        droneLocationOverlay = DroneLocationGraphicsOverlay()
        droneLocationOverlay?.sceneProperties?.surfacePlacement = .drapedFlat

        droneLocationOverlay?.isActivePublisher
            .sink { [weak self] isActive in
                guard let self = self, let droneLocationOverlay = self.droneLocationOverlay else { return }
                if isActive {
                    self.mapView.graphicsOverlays.insert(droneLocationOverlay, at: OverlayOrder.drone.rawValue)
                    self.checkOrderAndInsertOverlay()
                } else {
                    self.mapView.graphicsOverlays.remove(droneLocationOverlay)
                }
        }.store(in: &cancellables)
    }

    /// Add the return home location overlay
    private func addReturnHomeOverlay() {
        returnHomeOverlay = ReturnHomeGraphicsOverlay()
        returnHomeOverlay?.sceneProperties?.surfacePlacement = .drapedFlat

        returnHomeOverlay?.isActivePublisher
            .sink { [weak self] isActive in
                guard let self = self, let returnHomeOverlay = self.returnHomeOverlay else { return }
                if isActive {
                    self.mapView.graphicsOverlays.insert(returnHomeOverlay, at: OverlayOrder.rthPath.rawValue)
                    self.checkOrderAndInsertOverlay()
                } else {
                    self.mapView.graphicsOverlays.remove(returnHomeOverlay)
                }
        }.store(in: &cancellables)
    }

    /// Add the flight plan location overlay
    private func addFlightPlanOverlay() {
        flightPlanOverlay = FlightPlanGraphicsOverlay(bamService: bamService,
                                                      missionsStore: missionsStore,
                                                      flightPlanEditionService: flightPlanEditionService,
                                                      flightPlanRunManager: flightPlanRunManager,
                                                      memoryPressureMonitor: memoryPressureMonitor)
        flightPlanOverlay?.sceneProperties?.surfacePlacement = .drapedFlat

        flightPlanOverlay?.isActivePublisher
            .sink { [weak self] isActive in
                guard let self = self, let flightPlanOverlay = self.flightPlanOverlay else { return }
                if isActive {
                    self.mapView.graphicsOverlays.insert(flightPlanOverlay, at: OverlayOrder.flightPlan.rawValue)
                    self.checkOrderAndInsertOverlay()
                } else {
                    self.mapView.graphicsOverlays.remove(flightPlanOverlay)
                }
        }.store(in: &cancellables)

        flightPlanOverlay?.setupMissionProviderViewModel()
        flightPlanOverlay?.flightPlanViewModel.refreshCenterPublisher.sink(receiveValue: { [weak self] refresh in
            guard let self = self else { return }
            if refresh {
                self.flightPlanOverlay?.flightPlanViewModel.refreshCenter.value = false
                if let viewPoint = self.getCurrentViewPoint() {
                    self.mapView.setViewpoint(viewPoint)
                }
            }
        }).store(in: &cancellables)
    }

    /// Check overlays order and insert them if necessary
    private func checkOrderAndInsertOverlay() {
        OverlayOrder.allCases.sorted().forEach { overlay in
            switch overlay {
            case .rthPath:
                if let returnHomeOverlay = returnHomeOverlay, returnHomeOverlay.isActive.value,
                   self.mapView.graphicsOverlays.index(of: returnHomeOverlay) != OverlayOrder.rthPath.rawValue {
                    self.mapView.graphicsOverlays.remove(returnHomeOverlay)
                    self.mapView.graphicsOverlays.add(returnHomeOverlay)
                }
            case .user:
                if let userLocationOverlay = userLocationOverlay,
                   self.mapView.graphicsOverlays.index(of: userLocationOverlay) != OverlayOrder.user.rawValue {
                    self.mapView.graphicsOverlays.remove(userLocationOverlay)
                    self.mapView.graphicsOverlays.add(userLocationOverlay)
                }
            case .drone:
                if let droneLocationOverlay = droneLocationOverlay, droneLocationOverlay.isActive.value,
                   self.mapView.graphicsOverlays.index(of: droneLocationOverlay) != OverlayOrder.drone.rawValue {
                    self.mapView.graphicsOverlays.remove(droneLocationOverlay)
                    self.mapView.graphicsOverlays.add(droneLocationOverlay)
                }
            case .flightPlan:
                if let flightPlanOverlay = flightPlanOverlay, flightPlanOverlay.isActive.value,
                   self.mapView.graphicsOverlays.index(of: flightPlanOverlay) != OverlayOrder.flightPlan.rawValue {
                    self.mapView.graphicsOverlays.remove(flightPlanOverlay)
                    self.mapView.graphicsOverlays.add(flightPlanOverlay)
                }
            default: break
            }
        }
    }

    /// Updates drone location graphic.
    ///
    /// - Parameters:
    ///    - location: new drone location
    ///    - heading: new drone heading
    private func updateDroneLocationGraphic(location: Location3D) {
        // TODO: put all calculations in viewModel
        if !mapView.isNavigating, canUpdateDroneLocation {
            if let coordinate = calculateOffset(location: location) {
                if let centerMap = mapView.visibleArea?.extent.center.toCLLocationCoordinate2D() {
                    let newLocation = CLLocationCoordinate2D(
                        latitude: centerMap.latitude + coordinate.latitude,
                        longitude: centerMap.longitude + coordinate.longitude)

                    canUpdateDroneLocation = false
                    mapView.setViewpointCenter(AGSPoint(clLocationCoordinate2D: newLocation), scale: mapView.mapScale) { [weak self]_ in
                        guard let self = self else { return }
                        self.canUpdateDroneLocation = true
                    }
                }
            }
            if isInside(point: location.agsPoint) {
                oldDroneLocation = location
            }
        }
    }

    /// Calculates the autoscroll offset
    ///
    /// - Parameter location: new drone location
    /// - Returns: the coordinate offset
    private func calculateOffset(location: Location3D) -> CLLocationCoordinate2D? {
        // Do not autoscroll if drone is not flying, and if in edition.
        // Check if it is possible to autoscroll.
        guard !isInEdition, let drone = flightPlanViewModel.connectedDroneHolder.drone, drone.isFlying else { return nil }

        guard canUpdateDroneLocation, let oldDroneLocation = oldDroneLocation,
              isVisible(), isInside(point: oldDroneLocation.agsPoint), !centering else {
            return nil
        }
        var scrollToTarget = true

        // FP + PGY
        if let playingFlightPlan = flightPlanRunManager?.playingFlightPlan {
            if let point = nextExecutedWayPointGraphic(), !playingFlightPlan.hasReachedLastWayPoint {
                if self.isInside(point: point) {
                    scrollToTarget = false
                }
            } else if let location = flightPlanViewModel.locationsTracker.returnHomeLocation,
                self.isInside(point: AGSPoint(clLocationCoordinate2D: location)) {
                scrollToTarget = false
            }
        }
        // RTH
        if Services.hub.drone.rthService.isActive,
           let rthLocation = flightPlanViewModel.locationsTracker.returnHomeLocation,
           isInside(point: AGSPoint(clLocationCoordinate2D: rthLocation)) {
            scrollToTarget = false
        }

        // When the drone is leaving the screen and we scroll just enough to keep it on the screen, sometimes it happens that in the next iteration
        // the drone is seen as off screen in the oldDroneLocation and we stop autoscrolling.
        // The variable scrollFurther is meant to move the drone from the border
        // with a bigger offset.
        var scrollFurther = false
        if !isInside(point: location.agsPoint) {
            scrollFurther = true
            scrollToTarget = true
        }

        guard scrollToTarget else { return nil }

        let offSetLongitude = (location.coordinate.longitude - oldDroneLocation.coordinate.longitude) * (scrollFurther ? 1.3 : 1.0)
        let offSetLatitude = (location.coordinate.latitude - oldDroneLocation.coordinate.latitude) * (scrollFurther ? 1.3 : 1.0)

        guard offSetLatitude != 0 || offSetLongitude != 0 else { return nil }
        return CLLocationCoordinate2D(latitude: offSetLatitude, longitude: offSetLongitude)
    }

    /// Next executed waypoint graphic
    public func nextExecutedWayPointGraphic() -> AGSPoint? {
        if let trajectoryPoint = getPointFromTrajectory() {
            return trajectoryPoint
        } else {
            return getPointFromFlightPlan()
        }
    }

    /// Gets next waypoint when playing it from a normal flight plan.
    private func getPointFromFlightPlan() -> AGSPoint? {
        guard let graphics = flightPlanOverlay?.wayPoints else { return nil}
        guard let reachedFirstWayPoint = flightPlanRunManager?.playingFlightPlan?.hasReachedFirstWayPoint,
              reachedFirstWayPoint else {
            return graphics.first?.wayPoint?.agsPoint
        }
        let index = Int(flightPlanRunManager?.playingFlightPlan?.lastPassedWayPointIndex ?? 0) + 1
        if index < graphics.count {
            let graphic = graphics[index]
            return graphic.wayPoint?.agsPoint
        }
        return nil
    }

    /// Gets next waypoint when playing it from a trajectory.
    private func getPointFromTrajectory() -> AGSPoint? {
        guard let graphics = flightPlanOverlay?.flightPlanGraphics else {
            return nil
        }
        for graphic in graphics where graphic is FlightPlanCourseGraphic {
            guard let graphicsWaypoints = (graphic as? FlightPlanCourseGraphic)?.wayPoints else { return nil}
            guard let reachedFirstWayPoint = flightPlanRunManager?.playingFlightPlan?.hasReachedFirstWayPoint,
                  reachedFirstWayPoint else {
                return graphicsWaypoints.first?.agsPoint
            }
            let index = Int(flightPlanRunManager?.playingFlightPlan?.lastPassedWayPointIndex ?? 0) + 1
            if index < graphicsWaypoints.count {
                let graphic = graphicsWaypoints[index]
                return graphic.agsPoint
            }
            return nil
        }
        return nil
    }
}

extension FlightPlanMapViewController: MapViewEditionControllerDelegate {
    public func updateGraphicSelection(_ graphic: FlightPlanGraphic, isSelected: Bool) {
        flightPlanOverlay?.updateGraphicSelection(graphic,
                                                  isSelected: isSelected)
    }

    public func displayFlightPlan(_ flightPlan: FlightPlanModel, shouldReloadCamera: Bool) {
        flightPlanOverlay?.displayFlightPlan(flightPlan, shouldReloadCamera: shouldReloadCamera)
    }

    public func insertWayPoint(_ wayPoint: WayPoint, index: Int) -> FlightPlanWayPointGraphic? {
        flightPlanOverlay?.insertWayPoint(wayPoint, at: index)
    }

    public func toggleRelation(between wayPointGraphic: FlightPlanWayPointGraphic,
                               and selectedPoiPointGraphic: FlightPlanPoiPointGraphic) {
        flightPlanOverlay?.toggleRelation(between: wayPointGraphic, and: selectedPoiPointGraphic)
    }

    public func updatePoiPointAltitude(at index: Int, altitude: Double) {
        flightPlanOverlay?.updatePoiPointAltitude(at: index, altitude: altitude)
    }

    public func updateWayPointAltitude(at index: Int, altitude: Double) {
        flightPlanOverlay?.updateWayPointAltitude(at: index, altitude: altitude)
    }

    public func removeWayPoint(at index: Int) {
        flightPlanEditionService?.removeWaypoint(at: index)
        flightPlanOverlay?.removeWayPoint(at: index)
        flightDelegate?.didChangeCourse()
    }

    public func removePOI(at index: Int) {
        flightPlanEditionService?.removePoiPoint(at: index)
        flightPlanOverlay?.removePoiPoint(at: index)
        flightDelegate?.didChangePointOfView()
    }

    public func restoreMapToOriginalContainer() {
        isInEdition = false
        flightPlanEditionViewController = nil
    }

    public func lastManuallySelectedGraphic() {
        flightPlanOverlay?.lastManuallySelectedGraphic = nil
    }

    public func deselectAllGraphics() {
        flightPlanOverlay?.deselectAllGraphics()
    }

    public func undoAction() {
        let selectedGraphic = flightPlanOverlay?.currentSelection
        let selectedIndex = flightPlanOverlay?.selectedGraphicIndex(for: selectedGraphic?.itemType ?? .none)
        flightPlanEditionService?.undo()
        if let flightPlan = flightPlanOverlay?.flightPlan {
            displayFlightPlan(flightPlan, shouldReloadCamera: false)
            if let selectedGraphic = selectedGraphic {
                if let wpIndex = selectedIndex,
                   let newGraphic = flightPlanOverlay?.graphicForIndex(wpIndex, type: selectedGraphic.itemType) {
                    flightDelegate?.didTapGraphicalItem(newGraphic)
                } else {
                    flightDelegate?.didTapGraphicalItem(selectedGraphic)
                }
            }
        }
    }

    public func endEdition() {
        isInEdition = false
    }

    public var polygonPointsValue: [AGSPoint] { return [] }
    public func updateVisibility() {}
    public func didTapDeleteCorner() {}
    public func updateChoiceSettings(for key: String?, value: Bool) {}
    public func updateModeSettings(tag: Int) {}
    public func updateSettingsValue(for key: String?, value: Int) {}
    public func didFinishCornerEditionMode() {}
}
