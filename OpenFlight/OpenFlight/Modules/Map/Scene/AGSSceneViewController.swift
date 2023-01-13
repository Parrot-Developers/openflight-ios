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
open class AGSSceneViewController: CommonMapViewController {
    @IBOutlet public weak var viewContainer: UIView!

    /// KVO for scene loading status.
    private var isSceneLoadingObserver: NSKeyValueObservation?
    private var isNavigatingObserver: NSKeyValueObservation?
    private var isAllowingPitch = true
    /// Save camera position on view will disappear.
    private var savedCamera: AGSCamera?
    /// Key observer for scene loading status.
    private var sceneLoadStatusObservation: NSKeyValueObservation?
    /// Current camera saved before a reset of the scene view.
    private var currentCameraSaved: AGSCamera?

    public enum SceneConstants {
        public static let maxPitchValue: Double = 90.0
        static let pitchPrecision: Int = 2
        static let pitchAnimationNeeded: Double = 10.0
        public static let defaultZoomAltitude: Double = 150.0
    }

    /// Whether Centering is in progress.
    open var centering = false

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
        // Scene need to be instantiate before calling super.
        sceneView.scene = AGSScene()
        sceneView.alpha = 0
        centerMapWithoutAnyChanges()
        sceneLoadStatusObservation = sceneView.scene?.observe(\.loadStatus, options: .initial) { [weak self] (_, _) in
            DispatchQueue.main.async {
                if self?.sceneView.scene?.loadStatus == .loaded {
                    self?.sceneView.fadeIn()
                }
            }
        }
        super.viewDidLoad()
        sceneView.graphicsOverlays.removeAllObjects()
        setupMapElevation()
        setCameraHandler()
        sceneView.touchDelegate = self
        sceneView.isAttributionTextVisible = false
        sceneView.setViewpointCamera(defaultCamera)
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
        sceneView.scene?.baseSurface?.elevationSources.append(elevationSource)
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !viewContainer.contains(sceneView) {
            viewContainer.addWithConstraints(subview: sceneView)
        }
        setBaseMap()
    }

    public func setBaseSurface(enabled: Bool) {
        sceneView.scene?.baseSurface?.isEnabled = enabled
        updateOverlays()
    }

    open func updateOverlays() {
        // to override
    }

    /// Updates camera zoom level and camera position
    ///
    /// - Parameters:
    ///     - cameraZoomLevel: new camera zoom level
    ///     - position: new position of camera
    open func update(cameraZoomLevel: Int, position: AGSPoint) {
        // to override
    }

    /// Adds home graphic overlay to scene view.
    ///
    /// - Parameter zIndex: the z index of the home graphic to add
    public func addHomeOverlay(at zIndex: Int = 0) {
        // TODO: Injection.
        let homeLocationOverlay = HomeLocationGraphicsOverlay(rthService: Services.hub.drone.rthService,
                                                              mapViewModel: mapViewModel)
        sceneView.graphicsOverlays.insert(homeLocationOverlay, at: zIndex)
    }

    override open func setBaseMap() {
        guard currentMapType != SettingsMapDisplayType.current else { return }
        currentMapType = SettingsMapDisplayType.current
        if sceneView.scene == nil {
            sceneView.scene = AGSScene(basemapStyle: SettingsMapDisplayType.current.agsBasemapStyle)
            sceneView.alpha = 0
            if let currentCameraSaved = currentCameraSaved {
                sceneView.setViewpointCamera(currentCameraSaved)
            } else {
                centerMapWithoutAnyChanges()
            }
            sceneLoadStatusObservation = sceneView.scene?.observe(\.loadStatus, options: .initial) { [weak self] (_, _) in
                DispatchQueue.main.async {
                    if self?.sceneView.scene?.loadStatus == .loaded {
                        self?.sceneView.fadeIn()
                    }
                }
            }
            setupMapElevation()
        } else {
            sceneView.scene?.basemap = SettingsMapDisplayType.current.agsBasemap
        }
        sceneView.isAttributionTextVisible = false
    }

    /// Resets base map to reload it.
    open override func resetBaseMap() {
        let currentCameraSavedTemp = sceneView.currentViewpointCamera()
        currentCameraSaved = AGSCamera(latitude: currentCameraSavedTemp.location.y,
                                       longitude: currentCameraSavedTemp.location.x,
                                       altitude: currentCameraSavedTemp.location.z,
                                       heading: currentCameraSavedTemp.heading,
                                       pitch: currentCameraSavedTemp.pitch,
                                       roll: currentCameraSavedTemp.roll)
        sceneView.scene = nil
        currentMapType = nil
        setBaseMap()
    }

    /// Center map but do not change zoom level
    public override func centerMap() {
        getCenter { [weak self] viewPoint in
            guard let self = self else { return }
            self.ignoreCameraAdjustments = true
            if let center = viewPoint {
                self.centering = true
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
                self.sceneView.setViewpointCamera(newCamera, duration: 0) { [weak self] _ in
                    self?.centering = false
                }

                self.ignoreCameraAdjustments = false
            }
        }
    }

    /// Centers map on view point and applies it without any changes.
    public override func centerMapWithoutAnyChanges() {
        getCenter { [weak self] viewPoint in
            guard let self = self else { return }
            self.ignoreCameraAdjustments = true
            if let center = viewPoint {
                self.centering = true
                self.sceneView.setViewpoint(center)
                self.ignoreCameraAdjustments = false
                self.centering = false
            }
        }
    }

    /// Sets camera handler.
    func setCameraHandler() {
        sceneView.viewpointChangedHandler = { [weak self] in
            guard self?.sceneView.cameraController is AGSGlobeCameraController else {
                return
            }
            self?.updateCameraIfNeeded()
        }
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

        update(cameraZoomLevel: Int(zoom), position: camera.location)
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

    /// Moves the camera so when elevation is enabled/disabled the scene don't act like zooming when the ground approaches the camera.
    ///
    /// - Parameters:
    ///    - goUp: If true, the camera moves up by ground elevation from sealevel. A value false makes the camera move down by the same distance.
    open func moveCameraByElevation(goUp: Bool) {
        guard !ignoreCameraAdjustments else { return }
        let originalLocation = self.sceneView.currentViewpointCamera().location
        self.sceneView.scene?.baseSurface?.elevation(for: originalLocation, completion: { elevation, _ in
            guard self.sceneView.scene?.baseSurface?.isEnabled == goUp,
                  originalLocation == self.sceneView.currentViewpointCamera().location else {
                return
            }
            let oldCamera = self.sceneView.currentViewpointCamera()
            let oldLocation = oldCamera.location
            let newElevation = oldLocation.z + (elevation * (goUp ? 1 : -1))
            let newPoint = AGSPoint(x: oldLocation.x, y: oldLocation.y, z: newElevation, spatialReference: .wgs84())
            let newCamera = AGSCamera(location: newPoint, heading: oldCamera.heading, pitch: oldCamera.pitch, roll: oldCamera.roll)
            self.sceneView.setViewpointCamera(newCamera)
        })
    }

    func checkZoom(camera: AGSCamera) {
        var shouldReloadCamera = false
        var zoom = camera.location.z
        if zoom < CommonMapConstants.minZoomLevel {
            zoom = CommonMapConstants.minZoomLevel
            shouldReloadCamera = true
        } else if zoom > CommonMapConstants.maxZoomLevel {
            zoom = CommonMapConstants.maxZoomLevel
            shouldReloadCamera = true
        }
        if shouldReloadCamera {
            let newCamera = AGSCamera(latitude: camera.location.y,
                                      longitude: camera.location.x,
                                      altitude: zoom,
                                      heading: camera.heading,
                                      pitch: camera.pitch,
                                      roll: camera.roll)
            sceneView.setViewpointCamera(newCamera)
        }
    }

    func getCamera() {
        // to override
    }

    /// User navigating state on map
    ///
    /// - Parameters:
    ///    - state: user navigating state
    /// - Note: Called each time user is starting or stopping the navigation on map.
    open func userNavigating(state: Bool) {
       // To override.
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
}
