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
import Pictor

// swiftlint:disable file_length type_body_length

/// View controller for flightplan map.
open class FlightPlanSceneViewController: SceneWithOverlaysViewController {

    // MARK: - Private Properties
    private var flightPlanViewModel = FlightPlanViewModel()
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    private var editionCancellables = Set<AnyCancellable>()
    private var userLocationOverlay: UserLocationGraphicsOverlay?
    private var returnHomeOverlay: ReturnHomeGraphicsOverlay?
    /// Elevation at the point of take off.
    var droneElevationTakeOff: Double?

    public var bamService: BannerAlertManagerService?
    public var missionsStore: MissionsStore?
    public var memoryPressureMonitor: MemoryPressureMonitorService?

    // MARK: - Public Properties
    public var flightPlanEditionViewController: FlightPlanEditionViewController?
    public var currentMissionProviderState: MissionProviderState?
    public var flightPlanEditionService: FlightPlanEditionService?
    public var flightPlanRunManager: FlightPlanRunManager?
    public weak var flightDelegate: FlightEditionDelegate?
    public weak var settingsDelegate: EditionSettingsDelegate?
    public var droneLocationOverlay: DroneLocationGraphicsOverlay?
    public var flightPlanOverlay: FlightPlanGraphicsOverlay?

    // Is flight plan in edition
    public var isInEdition = false {
        didSet {
            editionChanged()
        }
    }

    /// Request for elevation of 'isInside' in map tool box
    var droneElevationRequest: AGSCancelable? {
        willSet {
            if droneElevationRequest?.isCanceled() == false {
                droneElevationRequest?.cancel()
            }
        }
    }

    /// Currrent elevation request if any, `nil` otherwise.
    private var elevationRequest: AGSCancelable? {
        willSet {
            if elevationRequest?.isCanceled() == false {
                elevationRequest?.cancel()
            }
        }
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
            guard let flightPlan = flightPlan else { return }
            let isEmpty = flightPlanOverlay?.flightPlanGraphics.isEmpty ?? true
            if flightPlan.dataSetting?.polyline != oldValue?.dataSetting?.polyline || differentFlightPlan ||
                isEmpty {
                flightPlanOverlay?.displayFlightPlan(flightPlan, shouldReloadCamera: reloadCamera)
            }
        }
    }

    weak var mapDelegate: MapViewEditionControllerDelegate?
    /// Mission provider.
    private let missionProviderViewModel = MissionProviderViewModel()

    private var sceneLoadStatusObservation: NSKeyValueObservation?

    // MARK: - Setup
    /// Instantiates the view controller.
    ///
    /// - Parameters:
    ///    - bamService: the banner alert manager service
    ///    - missionsStore: the mission store service
    ///    - flightPlanEditionService: the flight plan edition service
    ///    - flightPlanRunManager: the flight plan run manager service
    ///    - memoryPressureMonitor: the memory pressure monitor service
    ///
    /// - Returns: the piloting map view controller
    public static func instantiate(bamService: BannerAlertManagerService,
                                   missionsStore: MissionsStore,
                                   flightPlanEditionService: FlightPlanEditionService,
                                   flightPlanRunManager: FlightPlanRunManager,
                                   memoryPressureMonitor: MemoryPressureMonitorService) -> FlightPlanSceneViewController {
        let viewController = StoryboardScene.FlightPlanScene.initialScene.instantiate()
        viewController.bamService = bamService
        viewController.missionsStore = missionsStore
        viewController.flightPlanEditionService = flightPlanEditionService
        viewController.flightPlanRunManager = flightPlanRunManager
        viewController.memoryPressureMonitor = memoryPressureMonitor
        return viewController
    }

    open func editionChanged() {
       updateOverlays()
        if isInEdition {
            mapViewModel.disableAutoScroll()
        } else {
            mapViewModel.enableAutoScroll(delegate: self)
        }
    }

    open override func updateOverlays() {
        if let baseSurface = sceneView.scene?.baseSurface, baseSurface.isEnabled {
            if let isAMSL = flightPlanEditionService?.currentFlightPlanValue?.isAMSL {
                flightPlanOverlay?.sceneProperties?.surfacePlacement = isAMSL ? .absolute : .relative
            } else {
                flightPlanOverlay?.sceneProperties?.surfacePlacement = .relative
            }
            droneLocationOverlay?.sceneProperties?.surfacePlacement = .absolute
            returnHomeOverlay?.sceneProperties?.surfacePlacement = .absolute
        } else {
            flightPlanOverlay?.sceneProperties?.surfacePlacement = .drapedFlat
            droneLocationOverlay?.sceneProperties?.surfacePlacement = .drapedFlat
            returnHomeOverlay?.sceneProperties?.surfacePlacement = .drapedFlat
        }

        userLocationOverlay?.sceneProperties?.surfacePlacement = .drapedFlat
    }

    // MARK: - Override Funcs
    open override func viewDidLoad() {
        super.viewDidLoad()
        settingsDelegate = self

        // Add overlays in order from bottom to top:
        // RTH, Home, User, FlightPlan, Drone
        returnHomeOverlay = addReturnHomeOverlay()
        addHomeOverlay()
        userLocationOverlay = addUserOverlay()
        addFlightPlanOverlay()
        droneLocationOverlay = addDroneOverlay()

        setupMissionProviderViewModel()
        mapViewModel.enableAutoScroll(delegate: self)

        flightPlanViewModel.centerStatePublisher.sink { [weak self] centerState in
            self?.splitControls?.updateCenterMapButtonStatus(state: centerState)

        }.store(in: &cancellables)

        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self, self.droneElevationTakeOff == nil else {
                timer.invalidate()
                return
            }
            self.getDroneElevation()
        }
    }

    public override func getDefaultZoom() -> Double? {
        if let flightPlan = flightPlan, flightPlan.isEmpty, isInEdition {
            return SceneConstants.defaultZoomAltitude
        }
        return nil
    }

    public override func getCenter(completion: @escaping(AGSViewpoint?) -> Void) {
        getCurrentViewPoint { viewPoint in
            completion(viewPoint)
        }
    }

    /// Get Current view point to center map.
    ///
    /// The view point is determined in this order :
    ///     1/ Drone is connected and flying
    ///     2/ A flight plan exists and is not empty
    ///     3/ Drone is connected
    ///     4/ User is connected
    ///
    /// - Returns: the current view point
    open func getCurrentViewPoint(completion: @escaping(AGSViewpoint?) -> Void) {
        var droneIsNotFlying = true
        if let drone = flightPlanViewModel.connectedDroneHolder.drone, drone.isFlying {
            droneIsNotFlying = false
        }

        if let currentFlightPlan = flightPlanEditionService?.currentFlightPlanValue, !currentFlightPlan.isEmpty,
           let dataSetting = currentFlightPlan.dataSetting, !mapViewModel.isMiniMap.value,
            droneIsNotFlying {
            if let amsl = currentFlightPlan.isAMSL, amsl {
                getFlightPlanAMSLViewPoint(dataSetting: dataSetting) { viewPoint in
                    completion(viewPoint)
                }
            } else {
                // Get elevation for project not in ATO
                if let coordinate = dataSetting.coordinate {
                    getFlightPlanATOViewPoint(coordinate: coordinate, dataSetting: dataSetting) { viewPoint in
                        completion(viewPoint)
                    }
                } else {
                    completion(nil)
                }
            }
        } else {
            if droneLocationOverlay?.isDroneConnected == true,
               droneLocationOverlay?.droneGpsFixed == true,
               droneLocationOverlay?.droneLocation?.coordinates != nil {
                getDroneViewPoint { viewPoint in
                    completion(viewPoint)
                }
            } else {
                getUserViewPoint { viewPoint in
                    completion(viewPoint)
                }
            }
        }
    }

    /// Get drone view point
    ///
    /// - Note: Calculation are based on altitude in ATO of the drone.
    ///
    /// - Returns: the view point
    private func getDroneViewPoint(completion: @escaping(AGSViewpoint?) -> Void) {
        if let coordinates =  droneLocationOverlay?.droneLocation?.coordinates {
            if sceneView.scene?.baseSurface?.isEnabled == true {
                let point = AGSPoint(clLocationCoordinate2D: coordinates.coordinate)
                elevationRequest = sceneView.scene?.baseSurface?.elevation(for: point) { altitude, _  in
                    completion(AGSViewpoint(center: AGSPoint(clLocationCoordinate2D: coordinates.coordinate),
                                            scale: altitude + coordinates.altitude + SceneConstants.defaultDistanceToCamera))
                }
            } else {
                completion(AGSViewpoint(center: AGSPoint(clLocationCoordinate2D: coordinates.coordinate),
                                        scale: coordinates.altitude + SceneConstants.defaultDistanceToCamera))
            }
        }
    }

    /// Get user view point
    ///
    /// - Returns: the view point
    private func getUserViewPoint(completion: @escaping(AGSViewpoint?) -> Void) {
        if let coordinate = userLocationOverlay?.userLocation?.coordinates?.coordinate {
            if sceneView.scene?.baseSurface?.isEnabled == true {
                let point = AGSPoint(clLocationCoordinate2D: coordinate)
                elevationRequest = sceneView.scene?.baseSurface?.elevation(for: point) { [weak self] altitude, _  in
                    guard let self = self else { return }
                    if let coordinate = self.userLocationOverlay?.userLocation?.coordinates?.coordinate {
                        completion(AGSViewpoint(center: AGSPoint(clLocationCoordinate2D: coordinate),
                                                scale: altitude + SceneConstants.defaultDistanceToCamera))
                    }
                }
            } else {
                completion(AGSViewpoint(center: AGSPoint(clLocationCoordinate2D: coordinate),
                                        scale: SceneConstants.defaultDistanceToCamera))
            }
        } else {
            // Put default location in case user refused to shared his position.
            let point = AGSPoint(clLocationCoordinate2D: CommonMapConstants.defaultLocation)
            if sceneView.scene?.baseSurface?.isEnabled == true {
                elevationRequest = sceneView.scene?.baseSurface?.elevation(for: point) { altitude, _  in
                    completion(AGSViewpoint(center: point, scale: altitude + SceneConstants.defaultDistanceToCamera))
                }
            } else {
                completion(AGSViewpoint(center: point, scale: SceneConstants.defaultDistanceToCamera))
            }
        }
    }

    /// Get flight plan in AMSL view point
    ///
    /// - Returns: the view point
    private func getFlightPlanAMSLViewPoint(dataSetting: FlightPlanDataSetting,
                                            completion: @escaping(AGSViewpoint?) -> Void) {
        if sceneView.scene?.baseSurface?.isEnabled == false {
            let envelope = dataSetting.flatPolyline
                .envelopeWithMargin(altitudeOffset: 0.0)
            completion(AGSViewpoint(targetExtent: envelope))
        } else {
            let envelope = dataSetting.polyline
                .envelopeWithMargin(ArcGISStyle.projectEnvelopeMarginFactor, altitudeOffset: nil)

            completion(AGSViewpoint(targetExtent: envelope))
        }
    }

    /// Get flight plan in ATO view point
    ///
    /// - Returns: the view point
    private func getFlightPlanATOViewPoint(coordinate: CLLocationCoordinate2D,
                                           dataSetting: FlightPlanDataSetting,
                                           completion: @escaping(AGSViewpoint?) -> Void) {
        let point = AGSPoint(clLocationCoordinate2D: coordinate)
        elevationRequest = nil
        if sceneView.scene?.baseSurface?.isEnabled == false {
            let envelope = dataSetting.flatPolyline
                .envelopeWithMargin(altitudeOffset: 0.0)
            completion(AGSViewpoint(targetExtent: envelope))
        } else {
            elevationRequest = sceneView.scene?.baseSurface?.elevation(for: point) { altitude, _  in
                let envelope = dataSetting.polyline
                    .envelopeWithMargin(ArcGISStyle.projectEnvelopeMarginFactor,
                                        altitudeOffset: altitude)
                completion(AGSViewpoint(targetExtent: envelope))
            }
        }
    }

    open override func identify(screenPoint: CGPoint, _ completion: @escaping (AGSIdentifyGraphicsOverlayResult?) -> Void) {

        guard let flightPlanOverlay = flightPlanOverlay else { return }

        self.sceneView.identify(flightPlanOverlay,
                              screenPoint: screenPoint,
                              tolerance: CommonMapConstants.viewIdentifyTolerance,
                              returnPopupsOnly: false,
                              maximumResults: CommonMapConstants.viewIdentifyMaxResults) { (result: AGSIdentifyGraphicsOverlayResult) in
            completion(result)
        }
    }

    // MARK: - Gestures Funcs
    open override func handleCustomMapTap(mapPoint: AGSPoint, screenPoint: CGPoint, identifyResult: AGSIdentifyGraphicsOverlayResult?) {
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

    open override func handleCustomMapLongPress(mapPoint: AGSPoint, identifyResult: AGSIdentifyGraphicsOverlayResult?) {
        guard isInEdition, let result = identifyResult else { return }
        if result.selectedFlightPlanObject == nil {
            flightPlanOverlay?.addPoiPoint(atLocation: mapPoint)
        }
    }

    open override func handleCustomMapTouchDown(mapPoint: AGSPoint, identifyResult: AGSIdentifyGraphicsOverlayResult?, completion: @escaping (Bool) -> Void) {
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

    open override func handleCustomMapDrag(mapPoint: AGSPoint) {
        guard isInEdition else { return }

        // Drag should be ignored if it occurs before a certain duration (to avoid conflict with tap gesture).
        guard let dragTimeStamp = flightPlanOverlay?.startDragTimeStamp,
            ProcessInfo.processInfo.systemUptime > dragTimeStamp + Style.tapGestureDuration else {
                return
        }

        flightPlanOverlay?.updateDraggedGraphicLocation(mapPoint, editor: nil, isDragging: true)
    }

    open override func handleCustomMapTouchUp(screenPoint: CGPoint, mapPoint: AGSPoint) {
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

    // MARK: - Private Funcs
    /// Add the flight plan location overlay
    private func addFlightPlanOverlay() {
        flightPlanOverlay = FlightPlanGraphicsOverlay(bamService: bamService,
                                                      missionsStore: missionsStore,
                                                      flightPlanEditionService: flightPlanEditionService,
                                                      flightPlanRunManager: flightPlanRunManager,
                                                      memoryPressureMonitor: memoryPressureMonitor)
        if let flightPlanOverlay = flightPlanOverlay {
            flightPlanOverlay.sceneProperties?.surfacePlacement = .drapedFlat
            sceneView.graphicsOverlays.add(flightPlanOverlay)
            flightPlanOverlay.setupMissionProviderViewModel()
            flightPlanOverlay.flightPlanViewModel.refreshViewPointPublisher.sink(receiveValue: { [weak self] refresh in
                guard let self = self else { return }
                if refresh {
                    self.mapViewModel.refreshViewPoint.value = true
                }
            }).store(in: &cancellables)
        }
    }

    /// Get drone elevation
    private func getDroneElevation() {
        guard let droneLocation = droneLocationOverlay?.droneLocation?.coordinates?.agsPoint,
              sceneView.scene?.baseSurface?.isEnabled == true,
              sceneView.scene?.loadStatus == .loaded,
              let baseSurface = sceneView.scene?.baseSurface,
              !baseSurface.elevationSources.isEmpty,
              droneElevationRequest == nil else { return }

        droneElevationRequest = sceneView.scene?.baseSurface?.elevation(for: droneLocation, completion: { [weak self] value, error in
            self?.droneElevationRequest = nil
            if error == nil {
                self?.droneElevationTakeOff = value
                self?.droneLocationOverlay?.elevationTakeOff = value
            }
        })
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

    open override func miniMapChanged(value: Bool) {
        super.miniMapChanged(value: value)
        flightPlanOverlay?.isMiniMap = value
        droneLocationOverlay?.viewModel.update(isMiniMap: value)
        userLocationOverlay?.viewModel.isMiniMap.value = value
        if let baseMapEnabled = sceneView.scene?.baseSurface?.isEnabled {
            droneLocationOverlay?.sceneProperties?.altitudeOffset = value && !baseMapEnabled ? Double(FlightPlanConstants.maxZIndex) : 0
        }
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
            sceneViewController: self,
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
                    self?.flightPlan = flightplan
                })
                .store(in: &editionCancellables)
        } else {
            // Remove potential old Flight Plan first.
            flightPlanEditionService?.resetFlightPlan()
            // Then, unregister flight plan listener (editionCancellable = nil has effet if map is registred).
            editionCancellables.removeAll()
        }
    }

    open func didUpdateFlightPlan(_ flightPlan: FlightPlanModel?,
                                  differentFlightPlan: Bool,
                                  firstOpen: Bool,
                                  settingsChanged: [FlightPlanLightSetting],
                                  reloadCamera: Bool) {

        updateOverlays()
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
                                flightPlanRepository: PictorFlightPlanRepository,
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
            flightPlanRepository: flightPlanRepository,
            topBarService: topBarService,
            backButtonPublisher: backButtonPublisher)
        return viewController
    }

    open func updateFlightPlanType(tag: Int) {
        // to override
    }

    open func updateSetting(for key: String?, value: Int) {
        // to override
    }

    open func didDeleteCorner() {
        // to override
    }

    open func didFinishCornerEdition() {
        // to override
    }

    open func editionViewClosed() {
        // to override
    }

    open func polygonPoints() -> [AGSPoint] {
        return []
    }

    /// Closes the item edition panel.
    public func closeEditionItemPanel() {
        flightPlanEditionViewController?.didTapCloseButton()
    }

    // MARK: - Helpers
    /// Restore selected item after a flight plan reload.
    ///
    /// - Parameters:
    ///     - graphic: graphic to select
    ///     - index: graphic index
    func restoreSelectedItem(_ graphic: FlightPlanGraphic, at index: Int?) {
        if let wpIndex = index,
           let newGraphic = flightPlanOverlay?.graphicForIndex(wpIndex, type: graphic.itemType) {
            flightDelegate?.didTapGraphicalItem(newGraphic)
        } else {
            flightDelegate?.didTapGraphicalItem(graphic)
        }
    }

    open override func shouldAutoScroll() -> Bool {
        guard super.shouldAutoScroll() else { return false }

        // FP + PGY
        if let playingFlightPlan = flightPlanRunManager?.playingFlightPlan,
           let point = nextExecutedWayPointGraphic(),
           !playingFlightPlan.hasReachedLastWayPoint,
           playingFlightPlan.hasReachedFirstWayPoint {
            let altitude = playingFlightPlan.isAMSL == true ? nil : droneElevationTakeOff
            if mapViewModel.isInside(point: point, safely: true, referenceToAmsl: altitude ?? 0.0) {
                return false
            }
        }

        return true
    }

    public override func shouldAutoScrollToCenter() -> Bool {
        if let playingFlightPlan = flightPlanRunManager?.playingFlightPlan,
           !playingFlightPlan.hasReachedFirstWayPoint {
            return true
        }
        return false
    }
}

extension FlightPlanSceneViewController: MapViewEditionControllerDelegate {
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
        editionViewClosed()
        flightPlanEditionViewController = nil
    }

    public func lastManuallySelectedGraphic() {
        flightPlanOverlay?.lastManuallySelectedGraphic = nil
    }

    public func deselectAllGraphics() {
        flightPlanOverlay?.deselectAllGraphics()
    }

    public func undoAction() {
        didTapOnUndo(action: nil)
    }

    public var polygonPointsValue: [AGSPoint] {
        return polygonPoints()
    }

    public func endEdition() {
        isInEdition = false
    }

    public func updateVisibility() {
    }

    public func didTapDeleteCorner() {
        didDeleteCorner()
    }

    public func updateChoiceSettings(for key: String?, value: Bool) {
        updateSetting(for: key, value: value == true ? 0 : 1)

    }
    public func updateModeSettings(tag: Int) {
        settingsDelegate?.updateMode(tag: tag)
    }

    public func updateSettingsValue(for key: String?, value: Int) {
        updateSetting(for: key, value: value)
    }

    public func didFinishCornerEditionMode() {
        didFinishCornerEdition()
    }
}

// MARK: - EditionSettingsDelegate
extension FlightPlanSceneViewController: EditionSettingsDelegate {

    public func updateMode(tag: Int) {
        updateFlightPlanType(tag: tag)
    }

    public func updateSettingValue(for key: String?, value: Int) {
        updateSetting(for: key, value: value)
    }

    public func updateChoiceSetting(for key: String?, value: Bool) {
        updateSetting(for: key, value: value == true ? 0 : 1)
    }

    public func didTapCloseButton() {}
    public func didTapDeleteButton() {}

    @objc
    open func didTapOnUndo(action: (() -> Void)?) {
        let selectedGraphic = flightPlanOverlay?.currentSelection
        let selectedIndex = flightPlanOverlay?.selectedGraphicIndex(for: selectedGraphic?.itemType ?? .none)
        flightPlanEditionService?.undo()
        action?()
        if let flightPlan = flightPlanEditionService?.currentFlightPlanValue {
            displayFlightPlan(flightPlan, shouldReloadCamera: false)
            if let selectedGraphic = selectedGraphic {
                restoreSelectedItem(selectedGraphic, at: selectedIndex)
            }
        }
    }
    public func canUndo() -> Bool {
        return false
    }
}
