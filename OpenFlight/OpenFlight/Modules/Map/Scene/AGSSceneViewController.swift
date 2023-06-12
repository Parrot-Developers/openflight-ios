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
import ArcGIS
import Combine
import GroundSdk

private extension ULogTag {
    static let tag = ULogTag(name: "AGSSceneViewController")
}

/// View controller for map display.
open class AGSSceneViewController: CommonMapViewController, MapAutoScrollDelegate {
    @IBOutlet public weak var viewContainer: UIView!

    /// KVO for scene loading status.
    private var isSceneLoadingObserver: NSKeyValueObservation?
    private var isAllowingPitch = true
    /// Save camera position on view will disappear.
    private var savedCamera: AGSCamera?
    /// Key observer for scene loading status.
    private var sceneLoadStatusObservation: NSKeyValueObservation?
    private var cancellables = Set<AnyCancellable>()
    private var locationZThatShouldBeApplied: Double?
    private var cameraThatShouldBeApplied: AGSCamera?
    /// Whether the elevation of the map is loaded
    public var elevationLoaded = false {
        didSet {
            updateAltitudeOffSet()
        }
    }

    /// Request for elevation of 'my flight' first point.
    private var altitudeRequest: AGSCancelable? {
        willSet {
            if altitudeRequest?.isCanceled() == false {
                altitudeRequest?.cancel()
            }
        }
    }

    public enum SceneConstants {
        public static let maxPitchValue: Double = 90.0
        static let pitchPrecision: Int = 2
        static let pitchAnimationNeeded: Double = 10.0
        public static let defaultZoomAltitude: Double = 150.0
        static let defaultCameraValueToIgnore: Double = 1000000.0
        static let defaultDistanceToCamera = 200.0
    }

    public let sceneView = AGSSceneView()

    override var geoView: AGSGeoView {
        return sceneView
    }
    /// Combine cancellable for elevation availability for flight course display.
    open var elevationLoadedCancellable: AnyCancellable?
    open var elevationSource: MapElevationSource = MapElevationSource(networkService: Services.hub.systemServices.networkService)

    private let defaultCamera = AGSCamera(latitude: CommonMapConstants.defaultLocation.latitude,
                                          longitude: CommonMapConstants.defaultLocation.longitude,
                                          altitude: 1000,
                                          heading: 0.0,
                                          pitch: 0.0,
                                          roll: 0.0)

    override open func viewDidLoad() {
        super.viewDidLoad()
        setBaseMap()
        sceneView.graphicsOverlays.removeAllObjects()
        setupMapElevation()
        setCameraHandler()
        sceneView.touchDelegate = self
        sceneView.isAttributionTextVisible = false
        listenElevation()
        isNavigatingObserver = sceneView.observe(\AGSSceneView.isNavigating, changeHandler: { [ weak self ] (sceneView, _) in
            // NOTE: this closure can be called from a background thread so always dispatch to main
            DispatchQueue.main.async {
                self?.userNavigationDidChange(state: sceneView.isNavigating)
            }
        })
        centerMapWithoutAnyChanges()
        mapViewModel.refreshViewPointPublisher.sink(receiveValue: { [weak self] refresh in
            guard let self = self else { return }
            if refresh {
                if self.sceneView.scene?.baseSurface?.loadStatus == .loaded {
                    self.mapViewModel.refreshViewPoint.value = false
                    self.centerMapWithoutAnyChanges()
                }
            }
        }).store(in: &cancellables)
    }

    open func centerMapWithoutAnyChanges() {
        getCenter { [weak self] viewPoint in
            guard let self = self else { return }
            if let viewPoint = viewPoint {
                if viewPoint.viewpointType == .centerAndScale, let point = viewPoint.targetGeometry as? AGSPoint {
                    if self.sceneView.scene?.baseSurface?.isEnabled == true {
                        let newCamera = AGSCamera(lookAt: point, distance: viewPoint.targetScale, heading: 0, pitch: 0, roll: 0)
                        self.locationZThatShouldBeApplied = viewPoint.targetScale
                        self.sceneView.setViewpointCamera(newCamera)
                    } else {
                        let newCamera = AGSCamera(latitude: point.y, longitude: point.x, altitude: viewPoint.targetScale, heading: 0, pitch: 0, roll: 0)
                        self.locationZThatShouldBeApplied = viewPoint.targetScale
                        self.sceneView.setViewpointCamera(newCamera)
                    }
                } else {
                    if let envelope = viewPoint.targetGeometry as? AGSEnvelope {
                        let locationCenter = envelope.center.toCLLocationCoordinate2D()
                        let envelopeTopLeft = CLLocationCoordinate2D(
                            latitude: envelope.center.y - envelope.height / 2.0,
                            longitude: envelope.center.x  - envelope.width / 2.0)

                        let envelopeBottomRight = CLLocationCoordinate2D(
                            latitude: envelope.center.y + envelope.height / 2.0,
                            longitude: envelope.center.x + envelope.width / 2.0)

                        let distanceToLocationTopLeft = locationCenter.distance(from: envelopeTopLeft)
                        let distanceToLocationBottomRight = locationCenter.distance(from: envelopeBottomRight)

                        let opp = abs(max(distanceToLocationTopLeft, distanceToLocationBottomRight) / tan((self.sceneView.fieldOfView / 2.0 * 1.0).toRadians()))
                        self.locationZThatShouldBeApplied = nil

                        if self.sceneView.scene?.baseSurface?.isEnabled == true {
                            self.sceneView.setViewpoint(viewPoint)
                        } else {
                            let newCamera = AGSCamera(lookAt: envelope.center, distance: opp, heading: 0, pitch: 0, roll: 0)
                            self.locationZThatShouldBeApplied = opp
                            self.sceneView.setViewpointCamera(newCamera)
                        }
                    }
                }
            } else {
                let agsPoint = AGSPoint(clLocationCoordinate2D: CommonMapConstants.defaultLocation)
                let newCamera = AGSCamera(lookAt: agsPoint, distance: SceneConstants.defaultDistanceToCamera,
                                          heading: 0, pitch: 0, roll: 0)

                self.cameraThatShouldBeApplied = newCamera
                self.locationZThatShouldBeApplied = SceneConstants.defaultDistanceToCamera
                self.sceneView.setViewpointCamera(newCamera)
            }
        }
    }

    /// Called when load status of scene has changed.
    private func sceneLoadStatusChanged() {
        guard sceneView.scene?.loadStatus == .loaded else { return }
        sceneView.fadeIn()
        if mapViewModel.refreshViewPoint.value == true {
            mapViewModel.refreshViewPoint.value = false
            centerMapWithoutAnyChanges()
        }
    }

    /// Listen elevation of the ags scene view
    private func listenElevation() {
        self.elevationLoadedCancellable = self.elevationSource.$elevationLoaded
            .prepend(true)
            .filter { $0 }
            .sink { [weak self] loadStatus in
            guard loadStatus, let self = self else { return }
            self.elevationLoaded = loadStatus
        }
    }

    /// Refresh altitude offSet
    func updateAltitudeOffSet() {
        guard elevationLoaded  else { return }
        altitudeRequest = nil
        mapViewModel.refreshViewPoint.value = true
    }

    /// Sets up map elevation (extrusion).
    func setupMapElevation() {
        sceneView.scene?.baseSurface?.elevationSources.append(elevationSource)
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !viewContainer.contains(sceneView) {
            viewContainer.addWithConstraints(subview: sceneView)
        }
    }

    /// Set base surface of scene view
    ///
    /// - Parameters:
    ///     - enabled: Wheter the base surface is enabled or not
    public func setBaseSurface(enabled: Bool) {
        if sceneView.scene?.baseSurface?.isEnabled != enabled {
            sceneView.scene?.baseSurface?.isEnabled = enabled
            mapViewModel.refreshViewPoint.value = true
            updateOverlays()
        }
    }

    open func updateOverlays() {
        // to override
    }

    override open func setBaseMap() {
        var currentCameraSaved: AGSCamera?
        if sceneView.scene != nil {
            guard mapViewModel.networkService.networkIsReachable else { return }
            let currentCameraSavedTemp = sceneView.currentViewpointCamera()
            currentCameraSaved = AGSCamera(latitude: currentCameraSavedTemp.location.y,
                                                   longitude: currentCameraSavedTemp.location.x,
                                                   altitude: currentCameraSavedTemp.location.z,
                                                   heading: currentCameraSavedTemp.heading,
                                                   pitch: currentCameraSavedTemp.pitch,
                                                   roll: currentCameraSavedTemp.roll)
            self.locationZThatShouldBeApplied = currentCameraSavedTemp.location.z
        }
        sceneView.scene = AGSScene(basemapStyle: SettingsMapDisplayType.current.agsBasemapStyle)
        sceneView.alpha = 0
        if let currentCameraSaved = currentCameraSaved {
           sceneView.setViewpointCamera(currentCameraSaved)
        } else {
            if !applyDefaultCentering {
                centerMapWithoutAnyChanges()
            }
        }
        sceneLoadStatusObservation = sceneView.scene?.observe(\.loadStatus, options: .initial) { [weak self] (_, _) in
            DispatchQueue.main.async {
                self?.sceneLoadStatusChanged()
            }
        }
        setupMapElevation()
        sceneView.isAttributionTextVisible = false
    }

    /// Center map but do not change zoom level
    ///
    /// PS : this is only used when selecting centerMap button.
    /// Do not use for anything else.
    public override func centerMap() {
        getCenter { [weak self] viewPoint in
            guard let self = self else { return }
            self.ignoreCameraAdjustments = true
            if let center = viewPoint {
                var currentCamera = self.sceneView.currentViewpointCamera()
                let camera = currentCamera.hasValidLocation ? currentCamera : self.defaultCamera

                self.sceneView.setViewpoint(center)
                currentCamera = self.sceneView.currentViewpointCamera()
                let newCamera = AGSCamera(latitude: currentCamera.location.y,
                                          longitude: currentCamera.location.x,
                                          altitude: camera.location.z,
                                          heading: currentCamera.heading,
                                          pitch: self.mapViewModel.isMiniMap.value ? 0 : currentCamera.pitch,
                                          roll: currentCamera.roll)
                self.sceneView.setViewpointCamera(newCamera)
                self.ignoreCameraAdjustments = false
            }
        }
    }

    /// Sets camera handler.
    func setCameraHandler() {
        sceneView.viewpointChangedHandler = { [weak self] in
            guard let self = self else { return }

            self.addOtherCameraHandler()

            guard self.sceneView.cameraController is AGSGlobeCameraController else {
                return
            }

            let camera = self.sceneView.currentViewpointCamera()

            if !self.sceneView.isNavigating {
                guard camera.hasValidLocation else {
                    if let cameraThatShouldBeApplied = self.cameraThatShouldBeApplied {
                        self.sceneView.setViewpointCamera(cameraThatShouldBeApplied)
                    }
                    return
                }
                self.cameraThatShouldBeApplied = nil
                guard let locationZThatShouldBeApplied = self.locationZThatShouldBeApplied,
                      camera.location.z != SceneConstants.defaultCameraValueToIgnore else {
                    return
                }

                // Reapply camera if necessary. Sometimes the AGSScene refused the altitude of the camera.
                if camera.location.z != locationZThatShouldBeApplied || self.hasBeenReset {
                    guard camera.location.z != locationZThatShouldBeApplied else {
                        self.hasBeenReset = false
                        return
                    }
                    self.hasBeenReset = true
                    let newCamera = AGSCamera(latitude: camera.location.y,
                                              longitude: camera.location.x,
                                              altitude: locationZThatShouldBeApplied,
                                              heading: camera.heading, pitch: camera.pitch, roll: camera.roll)
                    self.sceneView.setViewpointCamera(newCamera)
                }
            } else {
                self.updateCameraIfNeeded()
            }
        }
    }

    @objc open dynamic func addOtherCameraHandler() {
        // do nothing by default
    }

    /// Returns max camera pitch as Double.
    open func maxCameraPitch() -> Double {
        isAllowingPitch ? SceneConstants.maxPitchValue : 0.0
    }

    /// Updates current camera if needed.
    ///
    /// - Parameters:
    ///    - camera: current camera
    ///    - removePitch: force remove pitch
    public func updateCameraIfNeeded() {
        let camera = sceneView.currentViewpointCamera()
        savedCamera = camera
        guard !ignoreCameraAdjustments else {
            return
        }
        var shouldReloadCamera = false

        // Update pitch if more than max value.
        var pitch = camera.pitch
        let maxPitch = maxCameraPitch()
        if pitch.rounded(toPlaces: SceneConstants.pitchPrecision) > maxPitch {
            pitch = maxPitch
            shouldReloadCamera = true
        }
        pitchChanged(pitch)

        // Update zoom if below min value or above max one.
        var zoom = camera.location.z
        if zoom < CommonMapConstants.minZoomLevel {
            zoom = CommonMapConstants.minZoomLevel
            shouldReloadCamera = true
        } else if zoom > CommonMapConstants.maxZoomLevel {
            zoom = CommonMapConstants.maxZoomLevel
            shouldReloadCamera = true
        }

        // Reload camera if needed.
        if shouldReloadCamera {
            let newCamera = AGSCamera(latitude: camera.location.y,
                                      longitude: camera.location.x,
                                      altitude: zoom,
                                      heading: camera.heading,
                                      pitch: pitch,
                                      roll: camera.roll)
            if abs(pitch - camera.pitch) > SceneConstants.pitchAnimationNeeded {
                removeCameraPitchAnimated(camera: newCamera)
            } else {
                sceneView.setViewpointCamera(newCamera)
            }
        }
    }

    /// Camera pitch changed.
    ///
    /// - Parameters:
    ///    - pitch: Camera pitch
    open func pitchChanged(_ pitch: Double) {
        // To be override.
    }

    /// Get default zoom
    ///
    /// - Returns: default zoom
    open func getDefaultZoom() -> Double? {
        // to be override
        return nil
    }

    /// Removes camera pitch, with animation.
    ///
    /// - Parameters:
    ///    - camera: current camera
    func removeCameraPitchAnimated(camera: AGSCamera) {
        guard let viewPoint = sceneView.currentViewpoint(with: .centerAndScale)?.targetGeometry as? AGSPoint
            else { return }

        var distance = camera.location.distanceToPoint(viewPoint)
        if let defaultZoom = getDefaultZoom() {
            distance = defaultZoom
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

    /// User navigating state on map
    ///
    /// - Parameters:
    ///    - state: user navigating state
    /// - Note: Called each time user is starting or stopping the navigation on map.
    open func userNavigationDidChange(state: Bool) {
        if !state {
            let camera = self.sceneView.currentViewpointCamera()
            if let locationZThatShouldBeApplied = locationZThatShouldBeApplied {
                if camera.location.z != locationZThatShouldBeApplied {
                    let newCamera = AGSCamera(latitude: camera.location.y,
                                              longitude: camera.location.x,
                                              altitude: locationZThatShouldBeApplied,
                                              heading: camera.heading, pitch: camera.pitch, roll: camera.roll)
                    self.sceneView.setViewpointCamera(newCamera)
                }
            }
        } else {
            self.locationZThatShouldBeApplied = nil
        }

    }

    /// Gets AMSL elevation for a coordiante point.
    ///
    /// - Parameters:
    ///   - coordinate: the coordinate point
    ///   - completion: the completion callback
    ///     - altitude: the AMSL altitude for the given point
    /// - Returns: a cancelable that permits to cancel the request.
    open func requestElevation(coordinate: AGSPoint, completion: @escaping (_ altitude: Double?) -> Void) -> AGSCancelable? {
        guard (sceneView.scene?.baseSurface) != nil else {
            completion(nil)
            return nil
        }
        return sceneView.scene?.baseSurface?.elevation(for: coordinate) { altitude, error in
            guard error == nil else {
                ULog.w(.tag, "Failed to get elevation for PGY: \(String(describing: error))")
                completion(nil)
                return
            }
            completion(altitude)
        }
    }

    // MARK: - Auto scroll
    public func geoViewForAutoScroll() -> AGSGeoView {
        sceneView
    }

    public func shouldAutoScroll() -> Bool {
        true
    }

    public func shouldAutoScrollToCenter() -> Bool {
        false
    }

    public func getCenter() -> CLLocationCoordinate2D? {
        sceneView.currentViewpointCamera().location.toCLLocationCoordinate2D()
    }

    public func setCenter(coordinates: CLLocationCoordinate2D) {
        let camera = sceneView.currentViewpointCamera()
        let newCamera = AGSCamera(latitude: coordinates.latitude,
                                  longitude: coordinates.longitude,
                                  altitude: camera.location.z,
                                  heading: camera.heading,
                                  pitch: camera.pitch,
                                  roll: camera.roll)
        sceneView.setViewpointCamera(newCamera)
    }

    public func locationToScreen(_ location: AGSPoint) -> CGPoint {
        sceneView.location(toScreen: location).screenPoint
    }
}
