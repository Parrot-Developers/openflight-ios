// Copyright (C) 2020 Parrot Drones SAS
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
import Reachability
import Combine

/// View controller for map display.
open class MapViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet public weak var sceneView: AGSSceneView!
    @IBOutlet private weak var leadingMapConstraint: NSLayoutConstraint!

    // MARK: - Public Properties
    public var flightEditionService: FlightPlanEditionService?
    public weak var flightDelegate: FlightEditionDelegate?
    public weak var editionDelegate: FlightPlanEditionViewControllerDelegate?
    public weak var settingsDelegate: EditionSettingsDelegate?
    public var currentMissionProviderState: MissionProviderState?
    /// Arcgis magic value to fix heading orientationn.
    public let arcgisMagicValueToFixHeading: Float = -1
    public var currentMapAltitude: Double = 0.0
    public var errorMapAltitude: Bool = false

    public var currentMapMode: MapMode = .standard {
        didSet {
            updateElevationVisibility()
        }
    }

    /// Whether elevation is enabled.
    public var isElevationEnabled: Bool {
        sceneView?.scene?.baseSurface?.isEnabled == true
    }

    open var flightPlan: FlightPlanModel? {
        didSet {
            let fileChanged = oldValue?.uuid != flightPlan?.uuid
            didUpdateFlightPlan(flightPlan, fileChanged)
        }
    }

    /// Tells whether map and flight plan should be displayed in 2D,
    open var shouldDisplayMapIn2D: Bool {
        currentMapMode == .flightPlanEdition || currentMapMode == .flightPlan
    }

    // MARK: - Internal Properties
    internal weak var customControls: CustomHUDControls?
    internal weak var splitControls: SplitControls?

    // MARK: - Private Properties
    var cancellables = Set<AnyCancellable>()
    var editionCancellable: AnyCancellable?
    // TODO: Wrong injection
    public var viewModel = MapViewModel(locationsTracker: Services.hub.locationsTracker)
    private var currentMapType: SettingsMapDisplayType?
    private let missionProviderViewModel = MissionProviderViewModel()
    public var droneLocationGraphic: AGSGraphic?
    private var userLocationGraphic: AGSGraphic?
    private var ignoreCameraAdjustments: Bool = false
    private var droneIsInLocationOverlay: Bool = false
    private var userIsInLocationOverlay: Bool = false
    private var defaultCamera: AGSCamera {
        return AGSCamera(latitude: MapConstants.defaultLocation.latitude,
                         longitude: MapConstants.defaultLocation.longitude,
                         altitude: MapConstants.cameraDistanceToCenterLocation,
                         heading: 0.0,
                         pitch: 0.0,
                         roll: 0.0)
    }
    private var reachability: Reachability?

    // MARK: - Internal Properties
    var shouldUpdateMapType: Bool = true
    public var flightPlanEditionViewController: FlightPlanEditionViewController?

    // MARK: - Private Enums
    private enum Constants {
        static let mapBoundsPadding: CGFloat = 10.0
        static let zoomValue = 14.0
        static let splitToFullscreenAnimationDuration: TimeInterval = 0.8 + 0.3 // SplitView delay + animation time
    }
    private enum MapConstants {
        static let sceneLayerURL = "https://tiles.arcgis.com/tiles/P3ePLMYs2RVChkJx/arcgis/rest/services/Buildings_Brest/SceneServer/layers/0"
        static let elevationURL = "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer"
        static let minZoomLevel: Double = 30.0
        static let maxZoomLevel: Double = 2000000.0
        static let cameraDistanceToCenterLocation: Double = 1000.0
        static let maxPitchValue: Double = 50.0
        static let pitchPrecision: Int = 2
        static let typeKey = "type"
        static let locationsOverlayKey = "locationsOverlayKey"
        static let userLocationValue = "userLocation"
        static let droneLocationValue = "droneLocation"
        static let altitudeKey = "altitude"
        static let sceneTolerance: Double = 1.0
        static let maxNbOfBuildingResults: Int = 1
        static let defaultLocation = CLLocationCoordinate2D(latitude: 48.879, longitude: 2.3673)
        static let extrusionExpression = "[HEIGHT]"
    }

    enum LocationGraphicType: Int {
        case user
        case drone
    }

    // MARK: - Setup
    /// Instantiate.
    ///
    /// - Parameters:
    ///    - mapMode: initial mode for map
    static func instantiate(mapMode: MapMode = .standard) -> MapViewController {
        let viewController = StoryboardScene.Map.initialScene.instantiate()
        viewController.currentMapMode = mapMode

        return viewController
    }

    // MARK: - Override Funcs
    override open func viewDidLoad() {
        super.viewDidLoad()
        configureMapView()
        viewModel.hideCenterButtonPublisher
            .combineLatest(viewModel.centerStatePublisher)
            .sink { [unowned self] in
                let (hide, centerState) = $0
                splitControls?.updateCenterMapButtonStatus(hide: hide, image: centerState.image)
            }
            .store(in: &cancellables)
        viewModel.droneLocationPublisher
            .combineLatest(viewModel.userLocationPublisher, viewModel.autoCenterDisabledPublisher, viewModel.centerStatePublisher)
            .sink { [unowned self] in
                let (droneLocation, userLocation, _, _) = $0
                locationsDidChange(userLocation: userLocation, droneLocation: droneLocation)
            }
            .store(in: &cancellables)
        if currentMapMode.isHudMode {
            setupMissionProviderViewModel()
        }
        setCameraHandler()
        configureMapOptions()
        setupReachability()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if shouldUpdateMapType {
            updateMapType(SettingsMapDisplayType.current)
        }
    }

    override public func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        /// Remove safe area right value to avoid maps desync on newest devices (when maps are not on full screen).
        if view.safeAreaInsets.right > 0 {
            leadingMapConstraint.constant = view.safeAreaInsets.left - view.safeAreaInsets.right
        }
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
        setMapMode(.standard)
        setupFlightPlanListener(for: missionProviderState)
    }

    /// Camera viewpoint changed.
    ///
    /// - Note: Called on every camera viewpoint change.
    open func viewpointChanged() {
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

    /// Refresh flight plan.
    open func refreshFlightPlan() {
        // To be override.
    }

    /// Edition view closed.
    open func editionViewClosed() {
        flightEditionService?.resetUndoStack()
    }

    // MARK: - Public Funcs
    /// Returns flight plan edition screen with a selected edition mode.
    ///
    /// - Parameters:
    ///     - coordinator: flight plan edition coordinator
    ///     - panelCoordinator: flight plan panel coordinator
    ///     - mapViewRestorer: protocol in charge of restoring MapViewController
    /// - Returns: FlightPlanEditionViewController
    open func editionProvider(coordinator: FlightPlanEditionCoordinator,
                              panelCoordinator: FlightPlanPanelCoordinator,
                              flightPlanServices: FlightPlanServices,
                              mapViewRestorer: MapViewRestorer?) -> FlightPlanEditionViewController {
        let flightPlanProvider = currentMissionProviderState?.mode?.flightPlanProvider
        let viewController = FlightPlanEditionViewController.instantiate(
            coordinator: coordinator,
            panelCoordinator: panelCoordinator,
            flightPlanServices: flightPlanServices,
            mapViewController: self,
            mapViewRestorer: mapViewRestorer,
            flightPlanProvider: flightPlanProvider)
        flightPlanEditionViewController = viewController
        return viewController
    }

    open func didUpdateFlightPlan(_ flightPlan: FlightPlanModel?, _ fileChanged: Bool) {
        guard let newFlightPlan = flightPlan else {
                // Future value is nil: remove Flight Plan graphic overlay.
                self.removeFlightPlanGraphicOverlay()
                return
        }

        if fileChanged {
            // Future value is a new FP view model: update graphic overlay.
            self.displayFlightPlan(newFlightPlan, shouldReloadCamera: true)
            if newFlightPlan.isEmpty {
                self.centerMapOnDroneOrUser()
            }
        }
    }

    /// Update the type of the current Flight plan.
    open func updateFlightPlanType(tag: Int) {
        // To be override.
    }

    /// Update a setting with a specific value for the current Flight plan.
    open func updateSetting(for key: String?, value: Int? = nil) {
        // To be override.
    }

    /// User touched undo button in edition screen.
    open func didTapOnUndo() {
        let selectedGraphic = self.flightPlanOverlay?.currentSelection
        let selectedIndex = self.flightPlanOverlay?.selectedGraphicIndex(for: selectedGraphic?.itemType ?? .none)
        flightEditionService?.undo()
        if let flightPlan = flightPlan {
            self.displayFlightPlan(flightPlan, shouldReloadCamera: false)
            if let selectedGraphic = selectedGraphic {
                self.restoreSelectedItem(selectedGraphic,
                                         at: selectedIndex)
            }
        }
    }

    /// Delete an item in edition screen.
    open func didDeleteCorner() {
        // To be override.
    }

    /// Exit the edition screen.
    open func didFinishCornerEdition() {
        // To be override.
    }

    /// Enable/disable user interactions and hide/show center button when maps is small on the HUD.
    ///
    /// - Parameters:
    ///    - isDisabled: True if user interaction should be disabled and center button hidden
    func disableUserInteraction(_ isDisabled: Bool) {
        sceneView.isUserInteractionEnabled = !isDisabled
        viewModel.forceHideCenterButton(isDisabled)
        // Map with disabled interaction always autocenters on drone/user location.
        if isDisabled {
            viewModel.disableAutoCenter(false)
        }
    }

    /// Set map mode for current Map instance.
    ///
    /// - Parameters:
    ///    - mode: MapMode to set.
    func setMapMode(_ mode: MapMode) {
        let needRefreshFlightplan: Bool = mode != currentMapMode

        currentMapMode = mode
        guard self.isViewLoaded else {
            return
        }

        configureMapOptions()

        if needRefreshFlightplan {
            self.refreshFlightPlan()
        }
    }

    /// Update current view point.
    ///
    /// - Parameters:
    ///    - viewPoint: View point
    ///    - animated: whether wiew point change should be animated
    func updateViewPoint(_ viewPoint: AGSViewpoint, animated: Bool = false) {
        if animated {
            self.ignoreCameraAdjustments = true
            self.sceneView.setViewpoint(viewPoint,
                                        duration: Style.mediumAnimationDuration) { [weak self] _ in
                                            self?.ignoreCameraAdjustments = false
            }
        } else {
            self.sceneView.setViewpoint(viewPoint)
        }
    }

    /// Add overlay.
    ///
    /// - Parameters:
    ///    - overlay: graphics overlay
    ///    - key: overlay key
    ///    - index: preferred index where the overlay should be added
    public func addGraphicOverlay(_ overlay: AGSGraphicsOverlay,
                                  forKey key: String,
                                  at index: Int? = nil) {
        overlay.overlayID = key

        if let index = index,
           index < sceneView.graphicsOverlays.count {
            sceneView.graphicsOverlays.insert(overlay, at: index)
        } else {
            sceneView.graphicsOverlays.add(overlay)
        }
    }

    /// Get overlay associated with given key.
    ///
    /// - Parameters:
    ///    - key: overlay key
    public func getGraphicOverlay(forKey key: String) -> AGSGraphicsOverlay? {
        return sceneView?.graphicOverlay(forKey: key)
    }

    /// Remove previously added overlay.
    ///
    /// - Parameters:
    ///    - key: overlay key
    public func removeGraphicOverlay(forKey key: String) {
        if let overlay = sceneView.graphicOverlay(forKey: key) {
            sceneView.graphicsOverlays.remove(overlay)
        }
    }

    /// Show the item edition panel.
    ///
    /// - Parameters:
    ///    - graphic: graphic to display in edition
    public func showEditionItemPanel(_ graphic: EditableAGSGraphic) {
        flightPlanEditionViewController?.showCustomGraphicEdition(graphic)
    }

    /// Returns max camera pitch as Double.
    open func maxCameraPitch() -> Double {
        return currentMapMode.isAllowingPitch ? MapConstants.maxPitchValue : 0.0
    }

    /// Updates origin graphic if needed
    ///
    /// - Parameters:
    ///    - camera: current camera
    public func updateOriginGraphicIfNeeded(camera: AGSCamera) {
        guard let originGraphic = (flightPlanOverlay?.graphics.first(where: { $0 is FlightPlanOriginGraphic }) as? FlightPlanOriginGraphic) else { return }

        let zoom = camera.location.z

        originGraphic.update(magicNumber:
            flightPlanOverlay?.sceneProperties?.surfacePlacement == .drapedFlat ? arcgisMagicValueToFixHeading : 1)

        let originAltitude = originGraphic.originWayPoint?.altitude ?? 0
        let minimalZoom: Double = 1500

        // remove origin if zoom is too high
        if errorMapAltitude {
            // 8849 meters max altitude possible
            if zoom < minimalZoom + 8849 + originAltitude {
                originGraphic.hidden(false)
            } else {
                originGraphic.hidden(true)
            }
        } else {
            if zoom < minimalZoom + currentMapAltitude + originAltitude {
                originGraphic.hidden(false)
            } else {
                originGraphic.hidden(true)
            }
        }

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
        guard !(shouldDisplayMapIn2D && camera.pitch > 0.001) else {
            // force camera pitch to zero
            removeCameraPitch(camera: camera)
            return
        }
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
    }

    open func unplug() {
        cancellables.forEach { $0.cancel() }
        editionCancellable?.cancel()
    }
}

// MARK: - Internal Funcs
extension MapViewController {
    /// Center Map on Drone or User.
    func centerMapOnDroneOrUser() {
        let currentCamera = sceneView.currentViewpointCamera()
        var camera = currentCamera.hasValidLocation ? currentCamera : defaultCamera
        if let currentCenterCoordinates = viewModel.currentCenterCoordinates {
            camera = AGSCamera(lookAt: AGSPoint(clLocationCoordinate2D: currentCenterCoordinates),
                               distance: MapConstants.cameraDistanceToCenterLocation,
                               heading: camera.heading,
                               pitch: camera.pitch,
                               roll: camera.roll)
        }
        sceneView.setViewpointCamera(camera)
    }

    /// Inserts user location graphic into locations overlay or flight plan overlay, depending on map mode.
    func insertUserGraphic() {
        userIsInLocationOverlay = true
        if let flightPlanOverlay = flightPlanOverlay {
            // if flight plan overlay is present,
            // remove user location from location overlay
            if let graphic = userLocationGraphic {
                getGraphicOverlay(forKey: MapConstants.locationsOverlayKey)?
                    .graphics.remove(graphic)
                userIsInLocationOverlay = false
            }
            // insert user location into flight plan overlay
            flightPlanOverlay.setUserGraphic(userLocationGraphic)
        } else if let graphic = userLocationGraphic {
            // if flight plan overlay is not present,
            // insert user location into location overlay
            getGraphicOverlay(forKey: MapConstants.locationsOverlayKey)?
                .graphics.add(graphic)
        }
    }

    /// Inserts drone location graphic into locations overlay or flight plan overlay, depending on map mode.
    func insertDroneGraphic() {
        droneIsInLocationOverlay = true
        if let flightPlanOverlay = flightPlanOverlay {
            // if flight plan overlay is present,
            // remove drone location from location overlay
            if let graphic = droneLocationGraphic {
                getGraphicOverlay(forKey: MapConstants.locationsOverlayKey)?
                    .graphics.remove(graphic)
            }
            // insert drone location into flight plan overlay
            flightPlanOverlay.setDroneGraphic(droneLocationGraphic)
            droneIsInLocationOverlay = false
        } else if let graphic = droneLocationGraphic {
            // if flight plan overlay is not present,
            // insert drone location into location overlay
            getGraphicOverlay(forKey: MapConstants.locationsOverlayKey)?
                .graphics.add(graphic)
        }
    }
}

// MARK: - Private Funcs - Configure map
private extension MapViewController {
    /// Initialize map view.
    func configureMapView() {
        setArcGISLicense()
        sceneView.scene = AGSScene()
        addSceneLayer()
        addLocationsOverlay()
        addDefaultCamera()
        sceneView.touchDelegate = self
        sceneView.isAttributionTextVisible = false
        setupMapElevation()
    }

    /// Sets up map elevation (extrusion).
    func setupMapElevation() {
        guard let elevationUrl = URL(string: MapConstants.elevationURL) else { return }

        let elevationSource = AGSArcGISTiledElevationSource(url: elevationUrl)
        sceneView.scene?.baseSurface?.elevationSources.append(elevationSource)
        sceneView.scene?.baseSurface?.isEnabled = true
    }

    /// Sets up mission provider view model.
    func setupMissionProviderViewModel() {
        missionProviderViewModel.state.valueChanged = { [weak self] state in
            self?.missionProviderDidChange(state)
        }
        // Set initial mission provider state.
        let state = missionProviderViewModel.state.value
        self.missionProviderDidChange(state)
    }

    /// Configure ArcGIS license.
    func setArcGISLicense() {
        do {
            try AGSArcGISRuntimeEnvironment.setLicenseKey(ServicesConstants.arcGisLicenseKey)
        } catch {
            print("ArcGIS License error !")
        }
    }

    /// Add sceneLayer to sceneView.
    func addSceneLayer() {
        if let sceneLayerURL = URL(string: MapConstants.sceneLayerURL) {
            let sceneLayer = AGSArcGISSceneLayer(url: sceneLayerURL)
            sceneView.scene?.operationalLayers.add(sceneLayer)
        }
    }

    /// Add locations (drone and user) overlay to sceneView.
    func addLocationsOverlay() {
        let locationsOverlay = AGSGraphicsOverlay()
        locationsOverlay.sceneProperties?.surfacePlacement = .relative
        addGraphicOverlay(locationsOverlay, forKey: MapConstants.locationsOverlayKey)
    }

    /// Configure default camera.
    func addDefaultCamera() {
        sceneView.setViewpointCamera(defaultCamera)
    }

    /// Set camera handler.
    func setCameraHandler() {
        sceneView.viewpointChangedHandler = { [weak self] in
            guard let camera = self?.sceneView.currentViewpointCamera(),
                  self?.sceneView.cameraController is AGSGlobeCameraController else {
                return
            }

            self?.updateElevationVisibility()
            self?.updateCameraIfNeeded(camera: camera)

            // Update content for viewpoint change.
            self?.viewpointChanged()
        }
    }

    /// Sets up reachability notifier.
    func setupReachability() {
        do {
            try reachability = Reachability()
            try reachability?.startNotifier()
        } catch {
            // Unable to start reachability.
        }

        reachability?.whenReachable = { [weak self] _ in
            // Refresh basemap when network is reachable.
            self?.sceneView.scene?.basemap = self?.currentMapType?.agsBasemap

            // Remove reachability notifier, since it should
            // be enough to setup basemap once while being online.
            self?.reachability?.stopNotifier()
            self?.reachability = nil
        }
    }

    /// Update map background with given setting.
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

    /// Configure map options depending current map mode.
    func configureMapOptions() {
        sceneView.selectionProperties.color = currentMapMode.selectionColor
        switch currentMapMode {
        case .myFlights:
            shouldUpdateMapType = false
            disableLocations()
            updateMapType(.hybrid)
            viewModel.disableAutoCenter(true)
        case .standard:
            viewModel.forceHideCenterButton(false)
            centerMapOnDroneOrUserIfNeeded()
        case .droneDetails:
            shouldUpdateMapType = false
            viewModel.forceHideCenterButton(true)
            viewModel.alwaysCenterOnDroneLocation(true)
            updateMapType(.satellite)
        case .flightPlan:
            viewModel.disableAutoCenter(true)
        case .flightPlanEdition:
            removeCameraPitchAnimated(camera: self.sceneView.currentViewpointCamera())
        }
    }

    /// Removes camera pitch, with animation.
    ///
    /// - Parameters:
    ///    - camera: current camera
    func removeCameraPitchAnimated(camera: AGSCamera) {
        guard let viewPoint = sceneView.currentViewpoint(with: .centerAndScale)?.targetGeometry as? AGSPoint
            else { return }

        let newCamera = AGSCamera(lookAt: viewPoint,
                                  distance: camera.location.distanceToPoint(viewPoint),
                                  heading: camera.heading,
                                  pitch: 0.0,
                                  roll: camera.roll)
        ignoreCameraAdjustments = true
        sceneView.setViewpointCamera(newCamera,
                                     duration: Style.mediumAnimationDuration) { [weak self] _ in
                                        self?.ignoreCameraAdjustments = false
        }
    }

    /// Removes camera pitch.
    ///
    /// - Parameters:
    ///    - camera: current camera
    func removeCameraPitch(camera: AGSCamera) {
        guard let viewPoint = sceneView.currentViewpoint(with: .centerAndScale)?.targetGeometry as? AGSPoint
            else { return }

        let newCamera = AGSCamera(lookAt: viewPoint,
                                  distance: camera.location.distanceToPoint(viewPoint),
                                  heading: camera.heading,
                                  pitch: 0.0,
                                  roll: camera.roll)
        sceneView.setViewpointCamera(newCamera)
    }
}

// MARK: - Private Funcs - Map locations update
private extension MapViewController {
    /// Completely disable user & drone locations.
    func disableLocations() {
        removeGraphicOverlay(forKey: MapConstants.locationsOverlayKey)
    }

    /// Handles locations state changes.
    ///
    /// - Parameters:
    ///    - locationsState: new locations state
    func locationsDidChange(userLocation: OrientedLocation, droneLocation: OrientedLocation) {
        if let droneLocationCoordinates = droneLocation.validCoordinates {
            updateDroneLocationGraphic(location: droneLocationCoordinates, heading: droneLocation.heading)
        }

        if let userLocationCoordinates = userLocation.validCoordinates {
            updateUserLocationGraphic(location: userLocationCoordinates.coordinate, heading: userLocation.heading)
        }
        centerMapOnDroneOrUserIfNeeded()
    }

    /// Update user location graphic.
    ///
    /// - Parameters:
    ///    - location: New location to set
    ///    - heading: Updated heading
    func updateUserLocationGraphic(location: CLLocationCoordinate2D,
                                   heading: CLLocationDegrees) {
        let geometry = AGSPoint(clLocationCoordinate2D: location)
        var headingWithMapOrientation = Float(heading)
        if userIsInLocationOverlay {
            if getGraphicOverlay(forKey: MapConstants.locationsOverlayKey)?.sceneProperties?.surfacePlacement == .drapedFlat {
                headingWithMapOrientation *= arcgisMagicValueToFixHeading
            }
        } else if flightPlanOverlay?.sceneProperties?.surfacePlacement == .drapedFlat {
            headingWithMapOrientation *= arcgisMagicValueToFixHeading
        }
        if let userLocationGraphic = userLocationGraphic {
            // create graphic for user location
            userLocationGraphic.geometry = geometry
            (userLocationGraphic.symbol as? AGSPictureMarkerSymbol)?.angle = headingWithMapOrientation
        } else {
            // create graphic for user location, if it does not exist
            let symbol = AGSPictureMarkerSymbol(image: Asset.Map.user.image)
            symbol.angle = headingWithMapOrientation
            let attributes = [MapConstants.typeKey: MapConstants.userLocationValue]
            let graphic = AGSGraphic(geometry: geometry, symbol: symbol, attributes: attributes)
            userLocationGraphic = graphic
            insertUserGraphic()
            updateUserLocationGraphic(location: location, heading: heading)
        }
    }

    /// Update drone location graphic.
    ///
    /// - Parameters:
    ///    - location: New location to set
    ///    - heading: Updated heading
    func updateDroneLocationGraphic(location: Location3D,
                                    heading: CLLocationDegrees) {
        let geometry = location.agsPoint
        var headingWithMapOrientation = Float(heading)

        if droneIsInLocationOverlay {
            if getGraphicOverlay(forKey: MapConstants.locationsOverlayKey)?.sceneProperties?.surfacePlacement == .drapedFlat {
                headingWithMapOrientation *= arcgisMagicValueToFixHeading
            }
        } else if flightPlanOverlay?.sceneProperties?.surfacePlacement == .drapedFlat {
            headingWithMapOrientation *= arcgisMagicValueToFixHeading
        }
        if let droneLocationGraphic = droneLocationGraphic {
            // create graphic for drone location
            droneLocationGraphic.geometry = geometry
            (droneLocationGraphic.symbol as? AGSPictureMarkerSymbol)?.angle = headingWithMapOrientation
        } else {
            // create graphic for drone location, if it does not exist
            let symbol = AGSPictureMarkerSymbol(image: Asset.Map.mapDrone.image)
            symbol.angle = headingWithMapOrientation
            let attributes = [MapConstants.typeKey: MapConstants.droneLocationValue]
            let graphic = AGSGraphic(geometry: geometry, symbol: symbol, attributes: attributes)
            droneLocationGraphic = graphic
            insertDroneGraphic()
            updateDroneLocationGraphic(location: location, heading: heading)
        }
    }
}

// MARK: - Private Funcs - Center map
private extension MapViewController {
    /// Center map to drone location. If drone location is unavailable, use the user's location instead (if available).
    func centerMapOnDroneOrUserIfNeeded() {
        guard !viewModel.autoCenterDisabled else {
            return
        }
        centerMapOnDroneOrUser()
    }
}

// MARK: - AGSGeoViewTouchDelegate
extension MapViewController: AGSGeoViewTouchDelegate {
    open func geoView(_ geoView: AGSGeoView,
                      didTapAtScreenPoint screenPoint: CGPoint,
                      mapPoint: AGSPoint) {
        // Filter out invalid screen touches returned by AGSGeoView.
        guard !screenPoint.isOriginPoint else { return }

        switch currentMapMode {
        case .flightPlanEdition:
            flightPlanHandleTap(geoView, didTapAtScreenPoint: screenPoint, mapPoint: mapPoint)
        case .standard where customControls?.available == true:
            customControls?.handleCustomMapTap(geoView,
                                               didTapAtScreenPoint: screenPoint,
                                               mapPoint: mapPoint)
        default:
            break
        }
    }

    open func geoView(_ geoView: AGSGeoView, didLongPressAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Filter out invalid screen touches returned by AGSGeoView.
        guard !screenPoint.isOriginPoint else { return }

        if currentMapMode == .flightPlanEdition {
            flightPlanHandleLongPress(geoView, didLongPressAtScreenPoint: screenPoint, mapPoint: mapPoint)
        }
    }

    open func geoView(_ geoView: AGSGeoView,
                      didTouchDownAtScreenPoint screenPoint: CGPoint,
                      mapPoint: AGSPoint,
                      completion: @escaping (Bool) -> Void) {
        // Filter out invalid screen touches returned by AGSGeoView.
        guard !screenPoint.isOriginPoint else { return }

        viewModel.disableAutoCenter(true)
        if currentMapMode == .flightPlanEdition {
            flightPlanHandleTouchDown(geoView,
                                      didTouchDownAtScreenPoint: screenPoint,
                                      mapPoint: mapPoint,
                                      completion: completion)
        } else {
            completion(false)
        }
    }

    open func geoView(_ geoView: AGSGeoView, didTouchDragToScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Filter out invalid screen touches returned by AGSGeoView.
        guard !screenPoint.isOriginPoint else { return }

        if currentMapMode == .flightPlanEdition {
            flightPlanHandleTouchDrag(geoView, didTouchDragToScreenPoint: screenPoint, mapPoint: mapPoint)
        }
    }

    open func geoView(_ geoView: AGSGeoView, didTouchUpAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Filter out invalid screen touches returned by AGSGeoView.
        guard !screenPoint.isOriginPoint else { return }

        if currentMapMode == .flightPlanEdition {
            flightPlanHandleTouchUp(geoView, didTouchUpAtScreenPoint: screenPoint, mapPoint: mapPoint)
        }
    }
}

extension MapViewController: MapViewEditionControllerDelegate {
    public var polygonPointsValue: [AGSPoint] {
        return polygonPoints()
    }

    public func insertWayPoint(_ wayPoint: WayPoint, index: Int) -> FlightPlanWayPointGraphic? {
        return flightPlanOverlay?.insertWayPoint(wayPoint,
                                                 at: index)
    }

    public func toggleRelation(between wayPointGraphic: FlightPlanWayPointGraphic,
                               and selectedPoiPointGraphic: FlightPlanPoiPointGraphic) {
        flightPlanOverlay?.toggleRelation(between: wayPointGraphic,
                                          and: selectedPoiPointGraphic)
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

    public func restoreMapToOrigianlContainer() {
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
        didTapOnUndo()
    }

    public func endEdition() {
        setMapMode(.flightPlan)
    }
}
