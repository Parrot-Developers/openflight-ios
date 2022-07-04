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

import UIKit
import CoreLocation
import ArcGIS
import SwiftyUserDefaults
import Combine
import GroundSdk

// swiftlint:disable file_length
// swiftlint:disable type_body_length

extension ULogTag {
    static let mapViewController = ULogTag(name: "MapViewController")
}

/// View controller for map display.
open class MapViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet weak var navBarView: HudTopBarGradientView!
    @IBOutlet private weak var navBarStackView: UIStackView!
    @IBOutlet private weak var backButton: MainBackButton!
    @IBOutlet private weak var viewContainer: UIView!

    // MARK: - Public Properties
    public var flightEditionService: FlightPlanEditionService?
    public var flightPlanManager: FlightPlanRunManager?
    public weak var flightDelegate: FlightEditionDelegate?
    public weak var settingsDelegate: EditionSettingsDelegate?
    public var currentMissionProviderState: MissionProviderState?
    public var listGraphicOverlay = [AGSGraphicsOverlay]()
    public let sceneView = SceneSingleton.shared.sceneView

    /// Drone offset longitude
    private var offSetLongitude: Double = 0.0
    /// Drone offset latitude
    private var offSetLatitude: Double = 0.0
    /// Previous drone location
    private var oldDroneLocation: Location3D?
    /// Can update drone location
    private var canUpdateDroneLocation = true
    /// First display of this map view controller
    private var firstTime: Bool = true

    /// Current map mode subject.
    private var currentMapModeSubject = CurrentValueSubject<MapMode, Never>(.standard)
    /// Current map mode publisher.
    private var currentMapModePublisher: AnyPublisher<MapMode, Never> { currentMapModeSubject.eraseToAnyPublisher() }
    /// Current map mode.
    public var currentMapMode: MapMode {
        get {
            currentMapModeSubject.value
        }
        set {
            currentMapModeSubject.value = newValue
            updateElevationVisibility()
        }
    }
    /// Previous map mode, nil once it was used.
    public var previousMapMode: MapMode?
    /// Whether the map is in miniature mode (needed for filtered information display).
    public var isMiniMap = false

    public var lastValidPoints: (screen: CGPoint?, map: AGSPoint?)

    private var droneLocation3D: Location3D?
    private var userLocation2D: CLLocationCoordinate2D?
    open var flightPlan: FlightPlanModel? {
        didSet {
            let differentFlightPlan = oldValue?.uuid != flightPlan?.uuid
            let settingsChanged = flightEditionService?.settingsChanged ?? []
            let reloadCamera = oldValue?.projectUuid != flightPlan?.projectUuid
            let firstOpen = oldValue == nil
            didUpdateFlightPlan(flightPlan,
                                differentFlightPlan: differentFlightPlan,
                                firstOpen: firstOpen,
                                settingsChanged: settingsChanged,
                                reloadCamera: reloadCamera)
        }
    }

    /// Whether keyboard is hidden.
    public var keyboardIsHidden = true

    /// Tells whether map and flight plan should be displayed in 2D,
    open var shouldDisplayMapIn2D: Bool {
        switch currentMapMode {
        case .standard,
             .droneDetails,
             .flightPlan,
             .flightPlanEdition:
            return true
        default:
            return false
        }
    }

    // MARK: - Internal Properties
    internal weak var customControls: CustomHUDControls?
    internal weak var splitControls: SplitControls?

    // MARK: - Private Properties
    /// Combine cancellables.
    var cancellables = Set<AnyCancellable>()
    /// Combine cancellable for current edited flight plan.
    var editionCancellable: AnyCancellable?
    /// Combine cancellable for elevation availability for flight course display.
    var elevationLoadedCancellable: AnyCancellable?
    /// Combine cancellable used to adjust flight plan overlay altitude and map view point.
    var adjustAltitudeAndCameraCancellable: AnyCancellable?
    /// Request for elevation of flight plan first waypoint.
    var firstWpElevationRequest: AGSCancelable?
    /// Request for elevation of 'my flight' first point.
    var myFlightAlttudeRequest: AGSCancelable?
    /// Uuid used to identify overlay with this mapViewController.
    var uuidOverlay = UUID().uuidString

    // TODO: Wrong injection
    public var viewModel = MapViewModel(locationsTracker: Services.hub.locationsTracker,
                                        connectedDroneHolder: Services.hub.connectedDroneHolder,
                                        networkService: Services.hub.systemServices.networkService,
                                        flightPlanEdition: Services.hub.flightPlan.edition)
    /// Current map display setting (road, satellite, hybrid).
    private var currentMapType: SettingsMapDisplayType?
    /// Mission provider.
    private let missionProviderViewModel = MissionProviderViewModel()
    /// Graphic for drone location.
    public var droneLocationGraphic: FlightPlanLocationGraphic?
    /// Graphic for user location.
    private var userLocationGraphic: FlightPlanLocationGraphic?
    private var ignoreCameraAdjustments: Bool = false
    private var droneIsInLocationOverlay: Bool = false
    private var userIsInLocationOverlay: Bool = false
    var isNavigatingObserver: NSKeyValueObservation?

    private let defaultCamera = AGSCamera(latitude: MapConstants.defaultLocation.latitude,
                                          longitude: MapConstants.defaultLocation.longitude,
                                          altitude: MapConstants.cameraDistanceToCenterLocation,
                                          heading: 0.0,
                                          pitch: 0.0,
                                          roll: 0.0)

    // MARK: - Internal Properties
    public var flightPlanEditionViewController: FlightPlanEditionViewController?

    // MARK: - Private Enums
    public enum MapConstants {
        static let minZoomLevel: Double = 30.0
        static let maxZoomLevel: Double = 2000000.0
        static let cameraDistanceToCenterLocation: Double = 1000.0
        static let maxPitchValue: Double = 90.0
        static let pitchPrecision: Int = 2
        static let typeKey = "type"
        static let locationsOverlayKey = "locationsOverlayKey"
        static let userLocationValue = "userLocation"
        static let droneLocationValue = "droneLocation"
        static let altitudeKey = "altitude"
        static let defaultLocation = CLLocationCoordinate2D(latitude: 48.879, longitude: 2.3673)
        static let mapBorderVertical: Double = 0.1
        static let mapBorderHorizontal: Double = 0.1
        static let defaultZoomAltitude: Double = 150.0
        /// Rotation factor to fix graphics orientation in draped flat mode.
        static let drapedFlatRotationFactor: Float = -1
        /// Default rotation factor for graphics orientation.
        static let defaultRotationFactor: Float = 1
    }

    // MARK: - Setup
    /// Instantiates the view controller.
    ///
    /// - Parameters:
    ///    - mapMode: initial mode for map
    ///    - isMiniMap: whether the map is in miniature mode
    /// - Returns: the map view controller
    public static func instantiate(mapMode: MapMode = .standard,
                                   isMiniMap: Bool = false) -> MapViewController {
        let viewController = StoryboardScene.Map.initialScene.instantiate()
        viewController.currentMapMode = mapMode
        SceneSingleton.shared.isMiniMap = isMiniMap
        viewController.isMiniMap = isMiniMap

        return viewController
    }

    deinit {
        unplug()
        for overlay in listGraphicOverlay {
            if let overlay = sceneView.graphicOverlay(forKey: overlay.overlayID) {
                sceneView.graphicsOverlays.remove(overlay)
            }
        }
        listGraphicOverlay.removeAll()
        isNavigatingObserver?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Override Funcs
    override open func viewDidLoad() {
        super.viewDidLoad()
        viewModel.listenCenterState(currentMapModePublisher: currentMapModePublisher)

        configureMapView()
        setupNavBar()
        listenNetwork()
        setupViewModel()
        if currentMapMode.isHudMode {
            setupMissionProviderViewModel()
        } else if !isMiniMap {
            configureMapOptions()
        }

        if !isMiniMap {
            centerMapOnDroneOrUserIfNeeded()
            if let flightPlan = flightPlan,
               let flightPlanOverlay = flightPlanOverlay {
                adjustAltitudeAndCamera(overlay: flightPlanOverlay,
                                        flightPlan: flightPlan,
                                        shouldReloadCamera: true)
            } else {
                centerMapOnDroneOrUserIfNeeded()
            }
        }
    }

    @objc private func keyboardWillAppear() {
        keyboardIsHidden = false
    }

    @objc private func keyboardWillDisappear() {
        keyboardIsHidden = true
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
        guard let reachedFirstWayPoint = flightPlanManager?.playingFlightPlan?.hasReachedFirstWayPoint,
              reachedFirstWayPoint else {
            return graphics.first?.wayPoint?.agsPoint
        }
        let index = Int(flightPlanManager?.playingFlightPlan?.lastPassedWayPointIndex ?? 0) + 1
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
            guard let reachedFirstWayPoint = flightPlanManager?.playingFlightPlan?.hasReachedFirstWayPoint,
                  reachedFirstWayPoint else {
                return graphicsWaypoints.first?.agsPoint
            }
            let index = Int(flightPlanManager?.playingFlightPlan?.lastPassedWayPointIndex ?? 0) + 1
            if index < graphicsWaypoints.count {
                let graphic = graphicsWaypoints[index]
                return graphic.agsPoint
            }
            return nil
        }
        return nil
    }

    /// Calculates drone offset.
    private func calculateOffset() {
        guard currentMapMode.userAndDroneLocationsEnabled,
              currentMapMode.autoScrollSupported,
              let droneLocation3D = droneLocation3D,
              let oldDroneLocation = oldDroneLocation else {
            offSetLongitude = 0
            offSetLatitude = 0
            return
        }
        if currentMapMode != .mapOnly,
           !isInside(point: oldDroneLocation.agsPoint) {
            return
        }

        var scrollToTarget = true

        // FP + PGY
        if let playingFlightPlan = flightPlanManager?.playingFlightPlan {
            if let point = nextExecutedWayPointGraphic(), !playingFlightPlan.hasReachedLastWayPoint {
                if self.isInside(point: point) {
                    scrollToTarget = false
                }
            } else if let location = viewModel.returnHomeLocation, self.isInside(location: location) {
                scrollToTarget = false
            }
        }
        // T&F
        if let waypoints = flightPlanOverlay?.wayPoints,
           waypoints.count == 1,
           let waypoint = waypoints.first,
           let agsPoint = waypoint.location?.agsPoint,
           isInside(point: agsPoint) {
            scrollToTarget = false
        }
        // RTH
        if Services.hub.drone.rthService.isActive,
           let rthLocation = viewModel.returnHomeLocation,
           isInside(location: rthLocation) {
            scrollToTarget = false
        }

        if !isInside(point: droneLocation3D.agsPoint) {
            scrollToTarget = true
        }

        if scrollToTarget {
            offSetLongitude = droneLocation3D.coordinate.longitude - oldDroneLocation.coordinate.longitude
            offSetLatitude = droneLocation3D.coordinate.latitude - oldDroneLocation.coordinate.latitude
        }
    }

    override open func viewWillAppear(_ animated: Bool) {
        setCameraHandler()
        navBarStackView.directionalLayoutMargins = .init(top: 0,
                                                         leading: Layout.hudTopBarInnerMargins(isRegularSizeClass).leading,
                                                         bottom: 0,
                                                         trailing: Layout.hudTopBarInnerMargins(isRegularSizeClass).trailing)

        configureUserInteraction()
        updateMapType(SettingsMapDisplayType.current)

        if !viewContainer.contains(sceneView) {
            viewContainer.addWithConstraints(subview: sceneView)
        }

        // Center if this is the first time showing this map view controller and not in minimap
        // Center automaticaly if we are coming back from dashboard
        // if there was a specific change in the map type (coming back from droneDetails & myFlights)
        if firstTime && !isMiniMap
            || !SceneSingleton.shared.isMiniMap
            && (SceneSingleton.shared.mapMode == .myFlights || SceneSingleton.shared.mapMode == .droneDetails)
            && currentMapMode != .myFlights && currentMapMode != .droneDetails {
            SceneSingleton.shared.mapMode = currentMapMode
            if let flightPlan = flightPlan,
                let flightPlanOverlay = flightPlanOverlay {
                adjustAltitudeAndCamera(overlay: flightPlanOverlay, flightPlan: flightPlan,
                                        shouldReloadCamera: true)
            } else {
                centerMapOnDroneOrUserIfNeeded()
            }
        }
        sceneView.touchDelegate = self
        // Add keyboard observer to block or not touch on the map.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        firstTime = false
        SceneSingleton.shared.isMiniMap = isMiniMap
        super.viewWillAppear(animated)
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        for overlay in listGraphicOverlay {
            if !sceneView.graphicsOverlays.contains(overlay) {
                sceneView.graphicsOverlays.add(overlay)
            }
        }
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        previousMapMode = nil
        for overlay in listGraphicOverlay where sceneView.graphicsOverlays.contains(overlay) {
            sceneView.graphicsOverlays.remove(overlay)
        }
        viewContainer.removeSubViews()
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    override public var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    /// Mission provider did change.
    ///
    /// - Parameters:
    ///    - missionMode: missionProviderState to set
    open func missionProviderDidChange(_ missionProviderState: MissionProviderState) {
        currentMissionProviderState = missionProviderState
        setMapMode(missionProviderState.mode?.mapMode ?? .standard)
        setupFlightPlanListener(for: missionProviderState)
    }

    /// User navigating state on map
    ///
    /// - Parameters:
    ///    - state: user navigating state
    /// - Note: Called each time user is starting or stopping the navigation on map.
    open func userNavigating(state: Bool) {
        // To be override.
    }

    /// Camera pitch changed.
    ///
    /// - Parameters:
    ///    - pitch: Camera pitch
    open func pitchChanged(_ pitch: Double) {
        // To be override.
    }

    /// Returns a list of points to draw a polygon.
    ///
    /// - Returns: List of points
    open func polygonPoints() -> [AGSPoint] {
        // To be override.
        return []
    }

    /// Refreshes flight plan.
    open func refreshFlightPlan() {
        // adjust map view to flight plan

        if let flightPlan = flightPlan,
           let flightPlanOverlay = flightPlanOverlay {
            adjustAltitudeAndCamera(overlay: flightPlanOverlay,
                                    flightPlan: flightPlan,
                                    shouldReloadCamera: true)
        }
    }

    /// Edition view closed.
    open func editionViewClosed() {
    }

    // MARK: - Public Funcs
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
        return viewController
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

    /// Did update flight plan
    ///
    /// - Parameters:
    ///    - flightPlan: flight plan
    ///    - differentFlightPlan: whether the updated flight plan is a different one. If false the
    ///    current flightplan was updated, if true the flight plan was replaced by a different one.
    ///    - firstOpen: whether this is the first flight plan of the controller
    ///    - settingsChanged: indicating whether the update contains a settings change
    ///    - reloadCamera: reload camera
    /// - Returns: FlightPlanEditionViewController
    open func didUpdateFlightPlan(_ flightPlan: FlightPlanModel?,
                                  differentFlightPlan: Bool,
                                  firstOpen: Bool,
                                  settingsChanged: [FlightPlanLightSetting],
                                  reloadCamera: Bool) {
        guard let newFlightPlan = flightPlan else {
            // Future value is nil: remove Flight Plan graphic overlay.
            removeFlightPlanGraphicOverlay()
            return
        }

        if differentFlightPlan {
            // Init FP's view point in order to ensure correct location is shown
            // while retrieving elevation.
            if reloadCamera {
                setViewPoint(for: newFlightPlan)
            }

            // Future value is a new FP view model: update graphic overlay.
            displayFlightPlan(newFlightPlan, shouldReloadCamera: reloadCamera)
            if newFlightPlan.isEmpty {
                centerMapOnDroneOrUser()
            }
        }
    }

    /// Updates the type of the current Flight plan.
    open func updateFlightPlanType(tag: Int) {
        // To be override.
    }

    /// Updates a setting with a specific value for the current Flight plan.
    open func updateSetting(for key: String?, value: Int? = nil) {
        // To be override.
    }

    /// User touched undo button in edition screen.
    open func didTapOnUndo(action: (() -> Void)?) {
        let selectedGraphic = flightPlanOverlay?.currentSelection
        let selectedIndex = flightPlanOverlay?.selectedGraphicIndex(for: selectedGraphic?.itemType ?? .none)
        flightEditionService?.undo()
        action?()
        if let flightPlan = flightPlan {
            displayFlightPlan(flightPlan, shouldReloadCamera: false)
            if let selectedGraphic = selectedGraphic {
                restoreSelectedItem(selectedGraphic, at: selectedIndex)
            }
        }
    }

    /// Deletes an item in edition screen.
    open func didDeleteCorner() {
        // To be override.
    }

    /// Exits the edition screen.
    open func didFinishCornerEdition() {
        // To be override.
    }

    /// Sets map mode for current map instance.
    ///
    /// - Parameters:
    ///    - mode: new map mode
    open func setMapMode(_ mode: MapMode) {

        ULog.d(.mapViewController, "Set map mode: \(mode)")
        previousMapMode = currentMapMode
        let needRefreshFlightplan: Bool = mode != currentMapMode

        currentMapMode = mode
        guard isViewLoaded else {
            return
        }
        if !isMiniMap {
            configureMapOptions()
        }

        if needRefreshFlightplan {
            refreshFlightPlan()
        }
    }

    /// Updates current view point.
    ///
    /// - Parameters:
    ///    - viewPoint: new view point
    ///    - animated: whether wiew point change should be animated
    func updateViewPoint(_ viewPoint: AGSViewpoint, animated: Bool = false) {
        guard !isMiniMap else { return }
        if animated {
            ignoreCameraAdjustments = true
            sceneView.setViewpoint(viewPoint,
                                   duration: Style.fastAnimationDuration) { [weak self] _ in
                self?.ignoreCameraAdjustments = false
            }
        } else {
            sceneView.setViewpoint(viewPoint)
        }
        previousMapMode = nil
    }

    /// Adds overlay.
    ///
    /// - Parameters:
    ///    - overlay: graphics overlay
    ///    - key: overlay key
    ///    - index: preferred index where the overlay should be added
    public func addGraphicOverlay(_ overlay: AGSGraphicsOverlay,
                                  forKey key: String,
                                  at index: Int? = nil) {
        overlay.overlayID = getOverlayFullKey(key: key)

        if let index = index,
           index < sceneView.graphicsOverlays.count {
            if !isMiniMap && isVisible() || key == MapConstants.locationsOverlayKey {
                sceneView.graphicsOverlays.insert(overlay, at: index)
            }
            listGraphicOverlay.insert(overlay, at: index)
        } else {
            if !isMiniMap && isVisible() || key == MapConstants.locationsOverlayKey {
                sceneView.graphicsOverlays.add(overlay)
            }
            listGraphicOverlay.append(overlay)
        }
    }

    /// Gets overlay associated with given key.
    ///
    /// - Parameters:
    ///    - key: overlay key
    public func getGraphicOverlay(forKey key: String) -> AGSGraphicsOverlay? {
        let fullKey = getOverlayFullKey(key: key)
        return listGraphicOverlay
            .compactMap { $0 }
            .first(where: { $0.overlayID == fullKey })
    }

    /// Removes previously added overlay.
    ///
    /// - Parameters:
    ///    - key: overlay key
    public func removeGraphicOverlay(forKey key: String) {
        let fullKey = getOverlayFullKey(key: key)
        if let overlay = sceneView.graphicOverlay(forKey: fullKey) {
            sceneView.graphicsOverlays.remove(overlay)
        }
        for overlay in listGraphicOverlay where overlay.overlayID == fullKey {
            if let index = listGraphicOverlay.firstIndex(of: overlay) {
                listGraphicOverlay.remove(at: index)
            }
        }
    }

    /// Get overlay key with UUID
    ///
    /// - Parameters:
    ///    - key: overlay key
    /// - Returns: overlay full key
    private func getOverlayFullKey(key: String) -> String {
        return key + "-" + uuidOverlay
    }

    /// Shows the item edition panel.
    ///
    /// - Parameters:
    ///    - graphic: graphic to display in edition
    public func showEditionItemPanel(_ graphic: EditableAGSGraphic) {
        flightPlanEditionViewController?.showCustomGraphicEdition(graphic)
    }

    /// Closes the item edition panel.
    public func closeEditionItemPanel() {
        flightPlanEditionViewController?.didTapCloseButton()
    }

    /// Returns max camera pitch as Double.
    open func maxCameraPitch() -> Double {
        (currentMapMode.isAllowingPitch && !shouldDisplayMapIn2D) ? MapConstants.maxPitchValue : 0.0
    }

    /// Updates origin graphic if needed.
    ///
    /// - Parameters:
    ///    - camera: current camera
    public func updateOriginGraphicIfNeeded(camera: AGSCamera) {
        guard let originGraphic = (flightPlanOverlay?.graphics.first(where: { $0 is FlightPlanOriginGraphic }) as? FlightPlanOriginGraphic) else { return }

        let zoom = camera.location.z

        let rotationFactor = flightPlanOverlay?.sceneProperties?.surfacePlacement == .drapedFlat ?
        MapConstants.drapedFlatRotationFactor : MapConstants.defaultRotationFactor
        originGraphic.update(rotationFactor: rotationFactor)

        let originAltitude = originGraphic.originWayPoint?.altitude ?? 0
        let minimalZoom: Double = 1500

        // remove origin if zoom is too high
        let hide = zoom >= minimalZoom + originAltitude
        originGraphic.hidden(hide)

        // refresh graphic
        flightPlanOverlay?.graphics.remove(originGraphic)
        flightPlanOverlay?.graphics.add(originGraphic)
    }

    /// Updates current camera if needed.
    ///
    /// - Parameters:
    ///    - camera: current camera
    ///    - removePitch: force remove pitch
    public func updateCameraIfNeeded(camera: AGSCamera, removePitch: Bool = false) {
        guard !ignoreCameraAdjustments else {
            return
        }
        var shouldReloadCamera = false

        // Update pitch if more than max value.
        var pitch = camera.pitch
        let maxPitch = maxCameraPitch()
        if pitch.rounded(toPlaces: MapConstants.pitchPrecision) > maxPitch {
            pitch = maxPitch
            shouldReloadCamera = true
        }
        pitchChanged(pitch)

        // Update zoom if below min value or above max one.
        var zoom = camera.location.z
        if zoom < MapConstants.minZoomLevel {
            zoom = MapConstants.minZoomLevel
            shouldReloadCamera = true
        } else if zoom > MapConstants.maxZoomLevel {
            zoom = MapConstants.maxZoomLevel
            shouldReloadCamera = true
        }
        flightPlanOverlay?.update(heading: camera.heading)
        droneLocationGraphic?.update(cameraHeading: camera.heading)
        userLocationGraphic?.update(cameraHeading: camera.heading)
        // Reload camera if needed.
        if shouldReloadCamera {
            if !removePitch {
                let newCamera = AGSCamera(latitude: camera.location.y,
                                          longitude: camera.location.x,
                                          altitude: zoom,
                                          heading: camera.heading,
                                          pitch: pitch,
                                          roll: camera.roll)
                sceneView.setViewpointCamera(newCamera)
            } else {
                removeCameraPitchAnimated(camera: camera)
            }
        }

        updateOriginGraphicIfNeeded(camera: camera)
    }

    /// Disables auto center.
    ///
    /// - Parameters:
    ///    - isDisabled: whether autocenter should be disabled
    public func disableAutoCenter(_ isDisabled: Bool) {
        viewModel.disableAutoCenter(isDisabled)
        if !isDisabled {
            centerMapOnDroneOrUser()
        }
    }

    open func unplug() {
        cancellables.forEach { $0.cancel() }
        editionCancellable?.cancel()
        adjustAltitudeAndCameraCancellable?.cancel()
        firstWpElevationRequest?.cancel()
        firstWpElevationRequest = nil
        myFlightAlttudeRequest?.cancel()
        myFlightAlttudeRequest = nil
    }

    /// Centers map on drone or user.
    open func centerMapOnDroneOrUser() {
        let currentCamera = sceneView.currentViewpointCamera()
        var camera = currentCamera.hasValidLocation ? currentCamera : defaultCamera
        if let currentCenterCoordinates = viewModel.currentCenterCoordinates {
            camera = AGSCamera(lookAt: AGSPoint(clLocationCoordinate2D: currentCenterCoordinates),
                               distance: camera.location.z,
                               heading: camera.heading,
                               pitch: 0,
                               roll: camera.roll)
        }
        sceneView.setViewpointCamera(camera)
    }

    /// Checks if a given map point has valid coordinates by ensuring neither its latitude or longitude is 0.
    ///
    /// - Parameters:
    ///    - mapPoint: the map point to check
    /// - Returns: `true` if the coordinates are valid, `false` otherwise
    public func isValidMapPoint(_ mapPoint: AGSPoint?) -> Bool {
        guard let mapPoint = mapPoint else { return false }

        let coordinate2D = mapPoint.toCLLocationCoordinate2D()
        return coordinate2D.latitude != 0 || coordinate2D.longitude != 0
    }
}

// MARK: - Internal Funcs
extension MapViewController {

    /// Inserts user location graphic into locations overlay or flight plan overlay, depending on map mode.
    func insertUserGraphic() {
        if let flightPlanOverlay = flightPlanOverlay, shouldDisplayMapIn2D {
            // if flight plan overlay is present,
            // remove user location from location overlay
            removeUserGraphic()
            // insert user location into flight plan overlay
            flightPlanOverlay.setUserGraphic(userLocationGraphic)
        } else if let graphic = userLocationGraphic {
            userIsInLocationOverlay = true
            // if flight plan overlay is not present,
            // insert user location into location overlay
            graphic.graphicsOverlay?.graphics.remove(graphic)
            getGraphicOverlay(forKey: MapConstants.locationsOverlayKey)?
                .graphics.add(graphic)
            sortGraphicsInLocationsOverlay()
        }
    }

    /// Inserts drone location graphic into locations overlay or flight plan overlay, depending on map mode.
    func insertDroneGraphic() {
        if let flightPlanOverlay = flightPlanOverlay, shouldDisplayMapIn2D {
            // if flight plan overlay is present,
            // remove drone location from location overlay
            removeDroneGraphic()
            // if drone is connected
            // insert drone location into flight plan overlay
            guard viewModel.droneConnectionState else { return }
            flightPlanOverlay.setDroneGraphic(droneLocationGraphic)
        } else if let graphic = droneLocationGraphic {
            // if flight plan overlay is not present and drone is connected,
            // insert drone location into location overlay
            guard viewModel.droneConnectionState || currentMapMode == .droneDetails else { return }
            droneIsInLocationOverlay = true
            graphic.graphicsOverlay?.graphics.remove(graphic)
            getGraphicOverlay(forKey: MapConstants.locationsOverlayKey)?
                .graphics.add(graphic)
            sortGraphicsInLocationsOverlay()
        }
    }

    /// Sorts displayed graphics.
    ///
    /// When using `AGSSceneView` and overlays configured in `drapedFlat` mode,
    /// graphics are render in the order of `graphics` array.
    /// This method arranges the order of graphics elements, in order to control
    /// in what order they are renderer.
    func sortGraphicsInLocationsOverlay() {
        guard let graphicsMutableArray = getGraphicOverlay(forKey: MapConstants.locationsOverlayKey)?.graphics,
              let graphics = graphicsMutableArray as? [AGSGraphic]
        else { return }

        var sortedGraphics = graphics.filter {
            $0 !== userLocationGraphic && $0 !== droneLocationGraphic
        }
        if let userLocationGraphic = userLocationGraphic,
            userIsInLocationOverlay {
            sortedGraphics.append(userLocationGraphic)
        }
        if let droneLocationGraphic = droneLocationGraphic,
            droneIsInLocationOverlay {
            sortedGraphics.append(droneLocationGraphic)
        }
        graphicsMutableArray.removeAllObjects()
        graphicsMutableArray.addObjects(from: sortedGraphics)
    }
}

// MARK: - Private Funcs - Configure map
private extension MapViewController {
    /// Sets up the navigation bar (only contains back button).
    func setupNavBar() {
        navBarStackView.isLayoutMarginsRelativeArrangement = true
    }

    /// Initialize map view.
    func configureMapView() {
        setArcGISLicense()
        addLocationsOverlay()
        addDefaultCamera()
        sceneView.touchDelegate = self
        sceneView.isAttributionTextVisible = false
        setupMapElevation()
        isNavigatingObserver = sceneView.observe(\AGSSceneView.isNavigating, changeHandler: { [ weak self ] (sceneView, _) in
            // NOTE: this closure can be called from a background thread so always dispatch to main
            DispatchQueue.main.async {
                self?.userNavigating(state: sceneView.isNavigating)
            }
        })
    }

    /// Sets up map elevation (extrusion).
    func setupMapElevation() {
        sceneView.scene?.baseSurface?.elevationSources.removeAll()
        sceneView.scene?.baseSurface?.elevationSources.append(viewModel.elevationSource)
        sceneView.scene?.baseSurface?.isEnabled = true
    }

    /// Sets up view model.
    func setupViewModel() {
        viewModel.hideCenterButtonPublisher
            .combineLatest(viewModel.centerStatePublisher)
            .sink { [unowned self] in
                let (_, centerState) = $0
                splitControls?.updateCenterMapButtonStatus(image: centerState.image)
            }
            .store(in: &cancellables)
        viewModel.droneLocationPublisher
            .combineLatest(viewModel.userLocationPublisher, viewModel.autoCenterDisabledPublisher, viewModel.centerStatePublisher)
            .sink { [unowned self] in
                let (droneLocation, userLocation, _, _) = $0
                locationsDidChange(userLocation: userLocation, droneLocation: droneLocation)
            }
            .store(in: &cancellables)
        viewModel.droneConnectedPublisher
            .sink { [unowned self] connected in
                if connected || currentMapMode == .droneDetails {
                    insertDroneGraphic()
                } else {
                    removeDroneGraphic()
                }
            }
            .store(in: &cancellables)
        viewModel.$droneIcon
            .sink { [weak self] image in
                self?.droneLocationGraphic?.update(image: image)
            }
            .store(in: &cancellables)
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

    /// Configures ArcGIS license.
    func setArcGISLicense() {
        do {
            try AGSArcGISRuntimeEnvironment.setLicenseKey(ServicesConstants.arcGisLicenseKey)
        } catch {
            ULog.e(.mapViewController, "ArcGIS License error !")
        }
    }

    /// Removes user location graphic
    func removeUserGraphic() {
        if let graphic = userLocationGraphic {
            getGraphicOverlay(forKey: MapConstants.locationsOverlayKey)?
                .graphics.remove(graphic)
        }
        userIsInLocationOverlay = false
    }

    /// Removes drone location graphic.
    func removeDroneGraphic() {
        if let flightPlanOverlay = flightPlanOverlay {
            flightPlanOverlay.removeDroneGraphic()
        }
        if let graphic = droneLocationGraphic {
            getGraphicOverlay(forKey: MapConstants.locationsOverlayKey)?
                .graphics.remove(graphic)
        }
        droneIsInLocationOverlay = false
    }

    /// Adds locations (drone and user) overlay to sceneView.
    func addLocationsOverlay() {
        let locationsOverlay = AGSGraphicsOverlay()
        locationsOverlay.sceneProperties?.surfacePlacement = shouldDisplayMapIn2D ? .drapedFlat : .relative
        addGraphicOverlay(locationsOverlay, forKey: MapConstants.locationsOverlayKey)
    }

    /// Configures default camera.
    func addDefaultCamera() {
        if !isMiniMap {
            sceneView.setViewpointCamera(defaultCamera)
        }
    }

    /// Sets camera handler.
    func setCameraHandler() {
        sceneView.viewpointChangedHandler = { [weak self] in
            guard let camera = self?.sceneView.currentViewpointCamera(),
                  self?.sceneView.cameraController is AGSGlobeCameraController else {
                return
            }

            self?.updateElevationVisibility()
            self?.updateCameraIfNeeded(camera: camera)
        }
    }

    /// Listens network reachability changes.
    func listenNetwork() {
        var cancellable: AnyCancellable?
        cancellable = viewModel.networkReachablePublisher
            .removeDuplicates()
            .sink { [weak self] reachable in
                guard let self = self else { return }
                if reachable {
                    self.sceneView.scene?.basemap = self.currentMapType?.agsBasemap
                    cancellable?.cancel()
                }
            }
    }

    /// Updates map background with given setting.
    ///
    /// - Parameters:
    ///    - mapType: new map type
    func updateMapType(_ mapType: SettingsMapDisplayType) {
        guard mapType != currentMapType else {
            return
        }
        currentMapType = mapType
        sceneView.scene?.basemap = currentMapType?.agsBasemap
    }

    /// Configures user interaction.
    func configureUserInteraction() {
        switch currentMapMode {
        case .myFlights:
            sceneView.isUserInteractionEnabled = true
        case .standard:
            sceneView.isUserInteractionEnabled = !isMiniMap
        case .droneDetails:
            sceneView.isUserInteractionEnabled = true
        case .flightPlan:
            sceneView.isUserInteractionEnabled = !isMiniMap
        case .flightPlanEdition:
            sceneView.isUserInteractionEnabled = true
        case .mapOnly:
            sceneView.isUserInteractionEnabled = false
        }
    }

    /// Configures map options depending current map mode.
    func configureMapOptions() {
        sceneView.selectionProperties.color = currentMapMode.selectionColor
        updateMapType(SettingsMapDisplayType.current)
        switch currentMapMode {
        case .myFlights:
            sceneView.isUserInteractionEnabled = true
            disableLocations()
            viewModel.disableAutoCenter(true)
        case .standard:
            sceneView.isUserInteractionEnabled = !isMiniMap
            viewModel.forceHideCenterButton(false)
            viewModel.disableAutoCenter(false)
            centerMapOnDroneOrUserIfNeeded()
        case .droneDetails:
            sceneView.isUserInteractionEnabled = true
            viewModel.forceHideCenterButton(true)
            viewModel.alwaysCenterOnDroneLocation(true)
            centerMapOnDroneOrUserIfNeeded()
        case .flightPlan:
            sceneView.isUserInteractionEnabled = !isMiniMap
            viewModel.disableAutoCenter(!isMiniMap)
        case .flightPlanEdition:
            sceneView.isUserInteractionEnabled = true
            removeCameraPitchAnimated(camera: sceneView.currentViewpointCamera())
        case .mapOnly:
            sceneView.isUserInteractionEnabled = false
            viewModel.forceHideCenterButton(true)
            viewModel.alwaysCenterOnDroneLocation(true)
            centerMapOnDroneOrUserIfNeeded()
        }
    }

    /// Removes camera pitch, with animation.
    ///
    /// - Parameters:
    ///    - camera: current camera
    func removeCameraPitchAnimated(camera: AGSCamera) {
        guard let viewPoint = sceneView.currentViewpoint(with: .centerAndScale)?.targetGeometry as? AGSPoint
            else { return }
        var distance = camera.location.distanceToPoint(viewPoint)
        if let flightPlan = flightPlan, flightPlan.isEmpty, currentMapMode == .flightPlanEdition {
            distance = MapConstants.defaultZoomAltitude
        }

        let newCamera = AGSCamera(lookAt: viewPoint,
                                  distance: distance,
                                  heading: camera.heading,
                                  pitch: 0.0,
                                  roll: camera.roll)
        ignoreCameraAdjustments = true

        sceneView.setViewpointCamera(newCamera,
                                     duration: Style.mediumAnimationDuration) { [weak self] _ in
            self?.ignoreCameraAdjustments = false
        }
    }
}

// MARK: - Private Funcs - Map locations update
private extension MapViewController {
    /// Disables user and drone locations.
    func disableLocations() {
        removeGraphicOverlay(forKey: MapConstants.locationsOverlayKey)
    }

    /// Handles locations changes.
    ///
    /// - Parameters:
    ///    - userLocation: new user location
    ///    - droneLocation: new drone location
    func locationsDidChange(userLocation: OrientedLocation, droneLocation: OrientedLocation) {
        if let droneLocationCoordinates = droneLocation.validCoordinates {
            updateDroneLocationGraphic(location: droneLocationCoordinates, heading: droneLocation.heading)
        }

        if let userLocationCoordinates = userLocation.validCoordinates {
            updateUserLocationGraphic(location: userLocationCoordinates.coordinate, heading: userLocation.heading)
        }
    }

    /// Updates user location graphic.
    ///
    /// - Parameters:
    ///    - location: new user location
    ///    - heading: new user heading
    func updateUserLocationGraphic(location: CLLocationCoordinate2D,
                                   heading: CLLocationDegrees) {
        let geometry = AGSPoint(clLocationCoordinate2D: location)
        userLocation2D = location

        // check that current mode supports user and drone locations display
        guard currentMapMode.userAndDroneLocationsEnabled else {
            removeUserGraphic()
            return
        }
        var applyCameraHeading: Bool = true
        if userIsInLocationOverlay {
            if getGraphicOverlay(forKey: MapConstants.locationsOverlayKey)?.sceneProperties?.surfacePlacement == .drapedFlat {
                applyCameraHeading = false
            }
        } else if flightPlanOverlay?.sceneProperties?.surfacePlacement == .drapedFlat {
            applyCameraHeading = false
        }
        if let userLocationGraphic = userLocationGraphic {
            userLocationGraphic.geometry = geometry
            userLocationGraphic.update(angle: Float(heading))

            userLocationGraphic.update(applyCameraHeading: applyCameraHeading)
        } else {
            // create graphic for user location, if it does not exist
            let attributes = [MapConstants.typeKey: MapConstants.userLocationValue]

            userLocationGraphic = FlightPlanLocationGraphic(geometry: geometry,
                                                            heading: Float(heading),
                                                            attributes: attributes,
                                                            image: Asset.Map.user.image)
            userLocationGraphic?.update(applyCameraHeading: applyCameraHeading)
            insertUserGraphic()
            updateUserLocationGraphic(location: location, heading: heading)
        }
    }

    /// Updates drone location graphic.
    ///
    /// - Parameters:
    ///    - location: new drone location
    ///    - heading: new drone heading
    func updateDroneLocationGraphic(location: Location3D,
                                    heading: CLLocationDegrees) {
        var geometry = location.agsPoint
        if shouldDisplayMapIn2D {
            geometry = AGSPoint(x: geometry.x, y: geometry.y, spatialReference: .wgs84())
        }
        droneLocation3D = location

        var applyCameraHeading: Bool = true
        if droneIsInLocationOverlay {
            if getGraphicOverlay(forKey: MapConstants.locationsOverlayKey)?.sceneProperties?.surfacePlacement == .drapedFlat {
                applyCameraHeading = false
            }
        } else if flightPlanOverlay?.sceneProperties?.surfacePlacement == .drapedFlat {
            applyCameraHeading = false
        }

        if let oldDroneLocation = oldDroneLocation {
            if location.altitude == oldDroneLocation.altitude && location.coordinate.latitude == oldDroneLocation.coordinate.latitude &&
                location.coordinate.longitude == oldDroneLocation.coordinate.longitude {
                droneLocationGraphic?.update(applyCameraHeading: applyCameraHeading)
                return
            }
        }

        // user stopped navigating in map.
        if !sceneView.isNavigating, canUpdateDroneLocation {
            canUpdateDroneLocation = false
            calculateOffset()
            if offSetLatitude != 0 && offSetLongitude != 0 {
                let tempOffSetLat = offSetLatitude
                let tempOffSetLong = offSetLongitude
                offSetLatitude = 0
                offSetLongitude = 0
                let camera = sceneView.currentViewpointCamera()
                let newCamera = AGSCamera(latitude: camera.location.toCLLocationCoordinate2D().latitude + tempOffSetLat,
                                          longitude: camera.location.toCLLocationCoordinate2D().longitude + tempOffSetLong,
                                          altitude: camera.location.z,
                                          heading: camera.heading,
                                          pitch: camera.pitch,
                                          roll: camera.roll)
                sceneView.setViewpointCamera(newCamera, duration: Style.mediumAnimationDuration)
            }
            canUpdateDroneLocation = true
            oldDroneLocation = location
        }

        // check that current mode supports user and drone locations display
        guard currentMapMode.userAndDroneLocationsEnabled  else {
            removeDroneGraphic()
            return
        }

        if let droneLocationGraphic = droneLocationGraphic {
            droneLocationGraphic.geometry = geometry
            droneLocationGraphic.update(angle: Float(heading))
            droneLocationGraphic.update(applyCameraHeading: applyCameraHeading)
        } else {
            let attributes = [MapConstants.typeKey: MapConstants.droneLocationValue]
            droneLocationGraphic = FlightPlanLocationGraphic(geometry: geometry,
                                                             heading: Float(heading),
                                                             attributes: attributes,
                                                             image: viewModel.droneIcon)
            droneLocationGraphic?.update(applyCameraHeading: applyCameraHeading)

            insertDroneGraphic()
            updateDroneLocationGraphic(location: location, heading: heading)
        }

    }
}

// MARK: - Private Funcs - Center map
private extension MapViewController {
    /// Centers map to drone location. If drone location is unavailable, use the user's location instead (if available).
    func centerMapOnDroneOrUserIfNeeded() {
        guard !viewModel.autoCenterDisabled else {
            return
        }
        centerMapOnDroneOrUser()
    }
}

extension MapViewController: MapViewEditionControllerDelegate {
    public var polygonPointsValue: [AGSPoint] {
        polygonPoints()
    }

    public func insertWayPoint(_ wayPoint: WayPoint, index: Int) -> FlightPlanWayPointGraphic? {
        flightPlanOverlay?.insertWayPoint(wayPoint, at: index)
    }

    public func toggleRelation(between wayPointGraphic: FlightPlanWayPointGraphic,
                               and selectedPoiPointGraphic: FlightPlanPoiPointGraphic) {
        flightPlanOverlay?.toggleRelation(between: wayPointGraphic, and: selectedPoiPointGraphic)
    }

    public func updateVisibility() {
        updateElevationVisibility()
    }

    public func updateGraphicSelection(_ graphic: FlightPlanGraphic, isSelected: Bool) {
        flightPlanOverlay?.updateGraphicSelection(graphic,
                                                  isSelected: isSelected)
    }

    public func updatePoiPointAltitude(at index: Int, altitude: Double) {
        flightPlanOverlay?.updatePoiPointAltitude(at: index, altitude: altitude)
    }

    public func updateWayPointAltitude(at index: Int, altitude: Double) {
        flightPlanOverlay?.updateWayPointAltitude(at: index, altitude: altitude)
    }

    public func updateModeSettings(tag: Int) {
        settingsDelegate?.updateMode(tag: tag)
    }

    public func didFinishCornerEditionMode() {
        didFinishCornerEdition()
    }

    public func removeWayPointAt(_ index: Int) {
        removeWayPoint(at: index)
    }

    public func removePOIAt(_ index: Int) {
        removePOI(at: index)
    }

    public func didTapDeleteCorner() {
        didDeleteCorner()
    }

    public func updateChoiceSettings(for key: String?, value: Bool) {
        updateChoiceSetting(for: key, value: value)
    }

    public func updateSettingsValue(for key: String?, value: Int) {
        updateSettingValue(for: key, value: value)
    }

    public func restoreMapToOriginalContainer() {
        setMapMode(.flightPlan)
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

    public func endEdition() {
        setMapMode(.flightPlan)
    }

    /// Clears graphics from the map.
    public func clearGraphics() {
        flightPlanOverlay?.graphics.removeAllObjects()
    }
}
