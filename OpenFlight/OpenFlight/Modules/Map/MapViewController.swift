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

private extension ULogTag {
    static let tag = ULogTag(name: "MapViewController")
}

/// View controller for map display.
open class MapViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet public weak var sceneView: AGSSceneView!

    // MARK: - Public Properties
    public var flightEditionService: FlightPlanEditionService?
    public weak var flightDelegate: FlightEditionDelegate?
    public weak var settingsDelegate: EditionSettingsDelegate?
    public var currentMissionProviderState: MissionProviderState?
    /// Arcgis magic value to fix heading orientationn.
    public let arcgisMagicValueToFixHeading: Float = -1
    public var currentMapAltitude: Double = 0.0
    public var errorMapAltitude: Bool = false
    /// Drone offset longitude
    private var offSetLongitude: Double = 0.0
    /// Drone offset latitude
    private var offSetLatitude: Double = 0.0
    /// Previous drone location
    private var oldDroneLocation: Location3D?
    /// Can update drone location
    private var canUpdateDroneLocation = true

    public var currentMapMode: MapMode = .standard(force2D: false) {
        didSet {
            updateElevationVisibility()
        }
    }

    private var droneLocation2D: CLLocationCoordinate2D?
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

    /// Tells whether map and flight plan should be displayed in 2D,
    open var shouldDisplayMapIn2D: Bool {
        currentMapMode == .flightPlanEdition || currentMapMode == .flightPlan || currentMapMode == .standard(force2D: true)
    }

    // MARK: - Internal Properties
    internal weak var customControls: CustomHUDControls?
    internal weak var splitControls: SplitControls?

    // MARK: - Private Properties
    var cancellables = Set<AnyCancellable>()
    var editionCancellable: AnyCancellable?
    var elevationLoadedCancellable: AnyCancellable?
    // TODO: Wrong injection
    public var viewModel = MapViewModel(locationsTracker: Services.hub.locationsTracker,
                                        connectedDroneHolder: Services.hub.connectedDroneHolder,
                                        networkService: Services.hub.systemServices.networkService)
    private var currentMapType: SettingsMapDisplayType?
    private let missionProviderViewModel = MissionProviderViewModel()
    private var droneLocationGraphic: FlightPlanLocationGraphic?
    private var userLocationGraphic: FlightPlanLocationGraphic?
    private var ignoreCameraAdjustments: Bool = false
    private var droneIsInLocationOverlay: Bool = false
    private var userIsInLocationOverlay: Bool = false

    var isNavigatingObserver: NSKeyValueObservation?

    private var defaultCamera: AGSCamera {
        return AGSCamera(latitude: MapConstants.defaultLocation.latitude,
                         longitude: MapConstants.defaultLocation.longitude,
                         altitude: MapConstants.cameraDistanceToCenterLocation,
                         heading: 0.0,
                         pitch: 0.0,
                         roll: 0.0)
    }
    private var sizeDrone = Asset.Map.mapDrone.image.size

    // MARK: - Internal Properties
    var shouldUpdateMapType: Bool = true
    public var flightPlanEditionViewController: FlightPlanEditionViewController?
    public var flightPlanEditionViewControllerBackButton: UIButton = InsetHitAreaButton(type: .custom)

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
    }

    // MARK: - Setup
    /// Instantiate.
    ///
    /// - Parameters:
    ///    - mapMode: initial mode for map
    public static func instantiate(mapMode: MapMode = .standard(force2D: false)) -> MapViewController {
        let viewController = StoryboardScene.Map.initialScene.instantiate()
        viewController.currentMapMode = mapMode

        return viewController
    }

    deinit {
        isNavigatingObserver?.invalidate()
    }

    // MARK: - Override Funcs
    override open func viewDidLoad() {
        super.viewDidLoad()

        configureMapView()
        setCameraHandler()
        listenNetwork()
        setupViewModel()
        if currentMapMode.isHudMode {
            setupMissionProviderViewModel()
        } else {
            configureMapOptions()
        }
    }

    /// Calculate drone offSet.
    private func calculateOffset() {
        guard currentMapMode.userAndDroneLocationsEnabled else {
            offSetLongitude = 0
            offSetLatitude = 0
            return
        }
        if let droneLocation3D = droneLocation2D, let oldDroneLocation = oldDroneLocation {
            let point = sceneView.location(toScreen: AGSPoint(clLocationCoordinate2D: droneLocation3D)).screenPoint
            if currentMapMode != .mapOnly {
                let sceneViewFrame = sceneView.frame
                if point.x - sizeDrone.width / 2.0 < sceneViewFrame.origin.x
                    || point.y - sizeDrone.height / 2.0 < sceneViewFrame.origin.y
                    || point.x - sizeDrone.width / 2.0 > sceneViewFrame.maxX
                    || point.y - sizeDrone.height / 2.0 > sceneViewFrame.maxY {
                    return
                }
            }

            offSetLongitude = droneLocation3D.longitude - oldDroneLocation.coordinate.longitude
            offSetLatitude = droneLocation3D.latitude - oldDroneLocation.coordinate.latitude
        }
    }

    override open func viewWillAppear(_ animated: Bool) {
        if shouldUpdateMapType {
            updateMapType(SettingsMapDisplayType.current)
        }

        // Ensure map is correctly centered on appear.
        // (user location info can be unavailable at first VC instantiation.)
        centerMapOnDroneOrUserIfNeeded()

        super.viewWillAppear(animated)
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
        setMapMode(missionProviderState.mode?.mapMode ?? .standard(force2D: false))
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

    /// Refresh flight plan.
    open func refreshFlightPlan() {
        // To be override.
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
                              flightPlanServices: FlightPlanServices) -> FlightPlanEditionViewController {
        let flightPlanProvider = currentMissionProviderState?.mode?.flightPlanProvider
        let backButtonPublisher = flightPlanEditionViewControllerBackButton.tapGesturePublisher
            .map { _ in () }
            .eraseToAnyPublisher()
        let viewController = FlightPlanEditionViewController.instantiate(
            panelCoordinator: panelCoordinator,
            flightPlanServices: flightPlanServices,
            mapViewController: self,
            flightPlanProvider: flightPlanProvider,
            backButtonPublisher: backButtonPublisher)
        flightPlanEditionViewController = viewController
        return viewController
    }

    /// Did update flight plan
    ///
    /// - Parameters:
    ///     - flightPlan: flight plan
    ///     - differentFlightPlan: whether the updated flight plan is a different one. If false the
    ///       current flightplan was updated, if true the flight plan was replaced by a different one.
    ///     - firstOpen: whether this is the first flight plan of the controller
    ///     - settingsChanged: indicating whether the update contains a settings change
    ///     - reloadCamera: reload camera
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
            // Future value is a new FP view model: update graphic overlay.
            displayFlightPlan(newFlightPlan, shouldReloadCamera: reloadCamera)
            if newFlightPlan.isEmpty {
                centerMapOnDroneOrUser()
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
    open func setMapMode(_ mode: MapMode) {
        ULog.d(.tag, "Set map mode: \(mode)")
        let needRefreshFlightplan: Bool = mode != currentMapMode

        currentMapMode = mode
        guard isViewLoaded else {
            return
        }

        configureMapOptions()

        if needRefreshFlightplan {
            refreshFlightPlan()
        }
    }

    /// Update current view point.
    ///
    /// - Parameters:
    ///    - viewPoint: View point
    ///    - animated: whether wiew point change should be animated
    func updateViewPoint(_ viewPoint: AGSViewpoint, animated: Bool = false) {
        if animated {
            ignoreCameraAdjustments = true
            sceneView.setViewpoint(viewPoint,
                                   duration: Style.mediumAnimationDuration) { [weak self] _ in
                self?.ignoreCameraAdjustments = false
            }
        } else {
            sceneView.setViewpoint(viewPoint)
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
        (currentMapMode.isAllowingPitch && !shouldDisplayMapIn2D) ? MapConstants.maxPitchValue : 0.0
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
    }

    /// Center Map on Drone or User.
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
}

// MARK: - Internal Funcs
extension MapViewController {

    /// Inserts user location graphic into locations overlay or flight plan overlay, depending on map mode.
    func insertUserGraphic() {
        userIsInLocationOverlay = true
        if let flightPlanOverlay = flightPlanOverlay {
            // if flight plan overlay is present,
            // remove user location from location overlay
            removeUserGraphic()
            // insert user location into flight plan overlay
            flightPlanOverlay.setUserGraphic(userLocationGraphic)
        } else if let graphic = userLocationGraphic {
            // if flight plan overlay is not present,
            // insert user location into location overlay
            graphic.graphicsOverlay?.graphics.remove(graphic)
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
            removeDroneGraphic()
            // insert drone location into flight plan overlay
            flightPlanOverlay.setDroneGraphic(droneLocationGraphic)
        } else if let graphic = droneLocationGraphic {
            // if flight plan overlay is not present,
            // insert drone location into location overlay
            graphic.graphicsOverlay?.graphics.remove(graphic)
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
        //
        flightPlanEditionViewControllerBackButton.setImage(Asset.Common.Icons.icBack.image,
                                                           for: .normal)
        flightPlanEditionViewControllerBackButton.contentMode = .center
        flightPlanEditionViewControllerBackButton.tintColor = ColorName.white.color
        flightPlanEditionViewControllerBackButton.isHidden = true
        view.addSubview(flightPlanEditionViewControllerBackButton)
        flightPlanEditionViewControllerBackButton.translatesAutoresizingMaskIntoConstraints = false
        // same as dashboardButton in HUDTopBarViewController
        let leftConstant: CGFloat = UIDevice.current.userInterfaceIdiom == .pad
        ? 27
        : isRegularSizeClass ? 12 : 27
        let width: CGFloat = 21
        let height: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 56 : 40 
        view.addConstraints([
            flightPlanEditionViewControllerBackButton.widthAnchor
                .constraint(equalToConstant: width),
            flightPlanEditionViewControllerBackButton.heightAnchor
                .constraint(equalToConstant: height),
            flightPlanEditionViewControllerBackButton.topAnchor
                .constraint(equalTo: view.topAnchor, constant: 0),
            flightPlanEditionViewControllerBackButton.leftAnchor.constraint(equalTo: view.leftAnchor,
                                                                            constant: leftConstant)
        ])
    }

    /// Sets up map elevation (extrusion).
    func setupMapElevation() {
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
            droneLocationGraphic?.update(image: connected ? Asset.Map.mapDrone.image : Asset.Map.mapDroneDisconnected.image)
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

    /// Configure ArcGIS license.
    func setArcGISLicense() {
        do {
            try AGSArcGISRuntimeEnvironment.setLicenseKey(ServicesConstants.arcGisLicenseKey)
        } catch {
            ULog.e(.tag, "ArcGIS License error !")
        }
    }

    /// Removes user location graphic
    func removeUserGraphic() {
        if let graphic = userLocationGraphic {
            getGraphicOverlay(forKey: MapConstants.locationsOverlayKey)?
                .graphics.remove(graphic)
            userIsInLocationOverlay = false
        }
    }

    /// Removes drone location graphic.
    func removeDroneGraphic() {
        if let graphic = droneLocationGraphic {
            getGraphicOverlay(forKey: MapConstants.locationsOverlayKey)?
                .graphics.remove(graphic)
        }
        droneIsInLocationOverlay = false
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
        }
    }

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
            viewModel.disableAutoCenter(false)
            centerMapOnDroneOrUserIfNeeded()
        case .droneDetails:
            shouldUpdateMapType = false
            viewModel.forceHideCenterButton(true)
            viewModel.alwaysCenterOnDroneLocation(true)
            centerMapOnDroneOrUserIfNeeded()
            updateMapType(.satellite)
        case .flightPlan:
            viewModel.disableAutoCenter(true)
        case .flightPlanEdition:
            removeCameraPitchAnimated(camera: sceneView.currentViewpointCamera())
        case .mapOnly:
            shouldUpdateMapType = false
            sceneView.isUserInteractionEnabled = false
            viewModel.forceHideCenterButton(true)
            viewModel.alwaysCenterOnDroneLocation(true)
            centerMapOnDroneOrUserIfNeeded()
            updateMapType(.satellite)
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
    }

    /// Update user location graphic.
    ///
    /// - Parameters:
    ///    - location: New location to set
    ///    - heading: Updated heading
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

    /// Update drone location graphic.
    ///
    /// - Parameters:
    ///    - location: New location to set
    ///    - heading: Updated heading
    func updateDroneLocationGraphic(location: Location3D,
                                    heading: CLLocationDegrees) {
        let geometry = location.agsPoint
        droneLocation2D = location.coordinate

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
                sceneView.setViewpointCamera(newCamera)
                canUpdateDroneLocation = true
                oldDroneLocation = location
            } else {
                canUpdateDroneLocation = true
                oldDroneLocation = location
            }
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
                                                             image: Asset.Map.mapDrone.image)
            droneLocationGraphic?.update(applyCameraHeading: applyCameraHeading)

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

    /// Clear graphics from the map.
    public func clearGraphics() {
        flightPlanOverlay?.graphics.removeAllObjects()
    }
}
