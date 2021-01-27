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

/// View controller for map display.
open class MapViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet public weak var sceneView: AGSSceneView!
    @IBOutlet private weak var leadingMapConstraint: NSLayoutConstraint!
    @IBOutlet private weak var centerButton: UIButton! {
        didSet {
            self.centerButton.setImage(Asset.Map.centerOnUser.image, for: .normal)
            self.centerButton.applyHUDRoundButtonStyle()
        }
    }

    // MARK: - Public Properties
    public weak var editionDelegate: FlightPlanEditionViewControllerDelegate?
    public var currentMissionProviderState: MissionProviderState?
    public var currentMapMode: MapMode = .standard
    open var flightPlanViewModel: FlightPlanViewModel? {
        didSet {
            let fileChanged = oldValue?.state.value.uuid != flightPlanViewModel?.state.value.uuid
            self.didUpdateFlightPlan(flightPlanViewModel, fileChanged)
        }
    }
    public var droneLocation: CLLocationCoordinate2D? {
        return locationsViewModel?.state.value.droneLocation.coordinates
    }

    // MARK: - Internal Properties
    internal var flightPlanListener: FlightPlanListener?
    internal var commandLimiter = CommandLimiter(limit: Constants.commandLimiterDefaultLimit)
    internal weak var customControls: CustomHUDControls?

    // MARK: - Private Properties
    private var currentMapType: SettingsMapDisplayType?
    private var locationsViewModel: MapLocationsViewModel? = MapLocationsViewModel()
    private var missionProviderViewModel: MissionProviderViewModel?
    public var droneLocationGraphic: AGSGraphic?
    private var userLocationGraphic: AGSGraphic?
    private var ignoreCameraAdjustments: Bool = false
    private var defaultCamera: AGSCamera {
        return AGSCamera(latitude: MapConstants.defaultLocation.latitude,
                         longitude: MapConstants.defaultLocation.longitude,
                         altitude: MapConstants.cameraDistanceToCenterLocation,
                         heading: 0.0,
                         pitch: 0.0,
                         roll: 0.0)
    }

    // MARK: - Internal Properties
    var shouldUpdateMapType: Bool = true
    var flightPlanEditionViewController: FlightPlanEditionViewController?

    // MARK: - Private Enums
    private enum Constants {
        static let mapBoundsPadding: CGFloat = 10.0
        static let zoomValue = 14.0
        static let splitToFullscreenAnimationDuration: TimeInterval = 0.8 + 0.3 // SplitView delay + animation time
        static let commandLimiterDefaultLimit: TimeInterval = 0.05
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
        static let headingOrientationCorrection: Double = 90.0
        static let sceneTolerance: Double = 1.0
        static let maxNbOfBuildingResults: Int = 1
        static let defaultLocation = CLLocationCoordinate2D(latitude: 48.879, longitude: 2.3673)
        static let extrusionExpression = "[HEIGHT]"
    }
    fileprivate enum LocationGraphicType: Int {
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

    // MARK: - Deinit
    deinit {
        FlightPlanManager.shared.unregister(flightPlanListener)
    }

    // MARK: - Override Funcs
    override open func viewDidLoad() {
        super.viewDidLoad()

        configureMapView()
        locationsViewModel?.state.valueChanged = { [weak self] state in
            self?.locationsDidChange(state)
            self?.updateCenterButtonStatus(state)
        }
        if currentMapMode.isHudMode {
            setupMissionProviderViewModel()
        }
        updateCenterButtonStatus(locationsViewModel?.state.value)
        setCameraHandler()
        configureMapOptions()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if shouldUpdateMapType {
            updateMapType(SettingsMapDisplayType.current)
        }

        flightPlanLabelsOverlay?.refreshLabels()
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
        // To be override.
    }

    // MARK: - Public Funcs
    /// Returns flight plan edition screen with a selected edition mode.
    ///
    /// - Parameters:
    ///     - coordinator: flight plan coordinator
    ///     - mapViewRestorer: protocol in charge of restoring MapViewController
    /// - Returns: FlightPlanEditionViewController
    open func editionProvider(coordinator: FlightPlanEditionCoordinator,
                              mapViewRestorer: MapViewRestorer?) -> FlightPlanEditionViewController {
        let flightPlanProvider = currentMissionProviderState?.mode?.flightPlanProvider
        let viewController = FlightPlanEditionViewController.instantiate(coordinator: coordinator,
                                                                         mapViewController: self,
                                                                         mapViewRestorer: mapViewRestorer,
                                                                         flightPlanProvider: flightPlanProvider)
        flightPlanEditionViewController = viewController
        return viewController
    }

    open func didUpdateFlightPlan(_ flightPlan: FlightPlanViewModel?, _ fileChanged: Bool) {
        guard let newFlightPlanViewModel = flightPlan else {
                // Future value is nil: remove Flight Plan graphic overlay.
                self.removeFlightPlanGraphicOverlay()
                return
        }

        if fileChanged {
            // Future value is a new FP view model: update graphic overlay.
            self.displayFlightPlan(newFlightPlanViewModel, shouldReloadCamera: true)
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
        // To be override.
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
        locationsViewModel?.forceHideCenterButton(isDisabled)
    }

    /// Set map mode for current Map instance.
    ///
    /// - Parameters:
    ///    - mode: MapMode to set.
    func setMapMode(_ mode: MapMode) {
        let needRefreshFlightplan: Bool = mode == .flightPlanEdition
            || currentMapMode == .flightPlanEdition && mode == .standard

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
    public func addGraphicOverlay(_ overlay: AGSGraphicsOverlay, forKey key: String) {
        overlay.overlayID = key
        sceneView.graphicsOverlays.add(overlay)
    }

    /// Get overlay associated with given key.
    ///
    /// - Parameters:
    ///    - key: overlay key
    public func getGraphicOverlay(forKey key: String) -> AGSGraphicsOverlay? {
        return sceneView.graphicOverlay(forKey: key)
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
    public func showEditionItemPanel() {
        flightPlanEditionViewController?.showCornerEdition()
    }

    /// Returns max camera pitch as Double.
    open func maxCameraPitch() -> Double {
        return currentMapMode.isAllowingPitch ? MapConstants.maxPitchValue : 0.0
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
                removeCameraPitch(camera: camera)
            }
        }
    }
}

// MARK: - Actions
private extension MapViewController {
    @IBAction func centerButtonTouchedUpInside(_ sender: AnyObject) {
        locationsViewModel?.disableAutoCenter(false)
    }
}

// MARK: - Internal Funcs
extension MapViewController {
    /// Center Map on Drone or User.
    func centerMapOnDroneOrUser() {
        guard let locationsViewModel = locationsViewModel else {
            return
        }
        let currentCamera = sceneView.currentViewpointCamera()
        let camera = currentCamera.hasValidLocation ? currentCamera : defaultCamera

        sceneView.setViewpointCamera(locationsViewModel.updateCenteredCamera(camera, distance: MapConstants.cameraDistanceToCenterLocation))
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
    }

    /// Sets up mission provider view model.
    func setupMissionProviderViewModel() {
        missionProviderViewModel = MissionProviderViewModel(stateDidUpdate: { [weak self] state in
            self?.missionProviderDidChange(state)
        })
        // Set initial mission provider state.
        if let state = missionProviderViewModel?.state.value {
            self.missionProviderDidChange(state)
        }
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
            guard let camera = self?.sceneView.currentViewpointCamera() else {
                return
            }

            self?.updateFlightPlanOverlaysIfNeeded(withCameraPitch: camera.pitch)
            self?.updateCameraIfNeeded(camera: camera)

            // Update content for viewpoint change.
            self?.viewpointChanged()
        }
    }

    /// Update centerButton status.
    func updateCenterButtonStatus(_ state: MapLocationsState?) {
        centerButton.isHidden = state?.shouldHideCenterButton != false
        centerButton.setImage(state?.centerState.image, for: .normal)
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
        case .standard:
            locationsViewModel?.forceHideCenterButton(false)
            centerMapOnDroneOrUserIfNeeded()
        case .droneDetails:
            shouldUpdateMapType = false
            locationsViewModel?.forceHideCenterButton(true)
            locationsViewModel?.alwaysCenterOnDroneLocation(true)
            updateMapType(.satellite)
        case .flightPlan:
            locationsViewModel?.forceHideCenterButton(true)
            locationsViewModel?.disableAutoCenter(true)
        case .flightPlanEdition:
            locationsViewModel?.forceHideCenterButton(true)
            locationsViewModel?.disableAutoCenter(true)
            self.removeCameraPitch(camera: self.sceneView.currentViewpointCamera())
        }
    }

    /// Remove camera pitch.
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
        ignoreCameraAdjustments = true
        sceneView.setViewpointCamera(newCamera,
                                     duration: Style.mediumAnimationDuration) { [weak self] _ in
                                        self?.ignoreCameraAdjustments = false
        }
    }
}

// MARK: - Private Funcs - Map locations update
private extension MapViewController {
    /// Completely disable user & drone locations.
    func disableLocations() {
        locationsViewModel = nil
        removeGraphicOverlay(forKey: MapConstants.locationsOverlayKey)
    }

    /// Handles locations state changes.
    ///
    /// - Parameters:
    ///    - locationsState: new locations state
    func locationsDidChange(_ locationsState: MapLocationsState) {
        if let droneLocationCoordinates = locationsState.droneLocation.validCoordinates {
            updateLocationGraphic(type: .drone,
                                  location: droneLocationCoordinates,
                                  heading: locationsState.droneLocation.heading)
        }

        if let userLocationCoordinates = locationsState.userOrientedLocation.validCoordinates {
            updateLocationGraphic(type: .user,
                                  location: userLocationCoordinates,
                                  heading: locationsState.userOrientedLocation.heading)
        }

        centerMapOnDroneOrUserIfNeeded()
    }

    /// Update location graphic.
    ///
    /// - Parameters:
    ///    - type: Graphic type
    ///    - location: New location to set
    ///    - heading: Updated heading
    func updateLocationGraphic(type: LocationGraphicType, location: CLLocationCoordinate2D, heading: CLLocationDegrees) {
        let geometry = AGSPoint(clLocationCoordinate2D: location)

        switch type {
        case .user:
            // Fix heading depending device orientation
            let correctedHeading = UIApplication.shared.statusBarOrientation == .landscapeLeft
                ? heading-MapConstants.headingOrientationCorrection
                : heading+MapConstants.headingOrientationCorrection

            if userLocationGraphic == nil {
                // If it doesn't exist, create graphic.
                let symbol = AGSPictureMarkerSymbol(image: Asset.Map.user.image)
                symbol.angle = Float(correctedHeading)
                let attributes = [MapConstants.typeKey: MapConstants.userLocationValue]
                let graphic = AGSGraphic(geometry: geometry, symbol: symbol, attributes: attributes)
                self.userLocationGraphic = graphic
                getGraphicOverlay(forKey: MapConstants.locationsOverlayKey)?.graphics.add(graphic)
            } else {
                // Otherwise update it.
                self.userLocationGraphic?.geometry = geometry
                (self.userLocationGraphic?.symbol as? AGSPictureMarkerSymbol)?.angle = Float(correctedHeading)
            }
        case .drone where self.droneLocationGraphic != nil:
            self.droneLocationGraphic?.geometry = geometry
            (self.droneLocationGraphic?.symbol as? AGSPictureMarkerSymbol)?.angle = Float(heading)
        case .drone where self.droneLocationGraphic == nil:
            let symbol = AGSPictureMarkerSymbol(image: Asset.Map.mapDrone.image)
            symbol.angle = Float(heading)
            let attributes = [MapConstants.typeKey: MapConstants.droneLocationValue]
            let graphic = AGSGraphic(geometry: geometry, symbol: symbol, attributes: attributes)
            self.droneLocationGraphic = graphic
            getGraphicOverlay(forKey: MapConstants.locationsOverlayKey)?.graphics.add(graphic)
        default:
            break
        }
    }
}

// MARK: - Private Funcs - Center map
private extension MapViewController {
    /// Center map to drone location. If drone location is unavailable, use the user's location instead (if available).
    func centerMapOnDroneOrUserIfNeeded() {
        guard locationsViewModel?.state.value.disabledAutoCenter == false else {
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
        if currentMapMode == .flightPlanEdition {
            flightPlanHandleLongPress(geoView, didLongPressAtScreenPoint: screenPoint, mapPoint: mapPoint)
        }
    }

    open func geoView(_ geoView: AGSGeoView,
                      didTouchDownAtScreenPoint screenPoint: CGPoint,
                      mapPoint: AGSPoint,
                      completion: @escaping (Bool) -> Void) {
        locationsViewModel?.disableAutoCenter(true)
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
        if currentMapMode == .flightPlanEdition {
            flightPlanHandleTouchDrag(geoView, didTouchDragToScreenPoint: screenPoint, mapPoint: mapPoint)
        }
    }

    open func geoView(_ geoView: AGSGeoView, didTouchUpAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if currentMapMode == .flightPlanEdition {
            flightPlanHandleTouchUp(geoView, didTouchUpAtScreenPoint: screenPoint, mapPoint: mapPoint)
        }
    }
}

// MARK: - FlightPlanEditionViewControllerDelegate
extension MapViewController: FlightPlanEditionViewControllerDelegate {
    public func startFlightPlanEdition() {}
    public func startNewFlightPlan(flightPlanProvider: FlightPlanProvider, creationCompletion: (_ createNewFp: Bool) -> Void) {}

    public func updateMode(tag: Int) {
        self.updateFlightPlanType(tag: tag)
    }

    public func updateSettingValue(for key: String?, value: Int) {
        self.updateSetting(for: key, value: value)
    }

    public func updateChoiceSetting(for key: String?, value: Bool) {
        self.updateSetting(for: key, value: value == true ? 0 : 1)
    }

    public func didTapCloseButton() {}
    public func didTapDeleteButton() {}
}
