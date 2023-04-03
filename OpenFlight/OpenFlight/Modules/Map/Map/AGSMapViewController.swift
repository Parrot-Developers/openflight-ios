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

/// View controller for map display.
open class AGSMapViewController: CommonMapViewController, MapAutoScrollDelegate {
    @IBOutlet public weak var mapView: AGSMapView!
    @IBOutlet weak var centerButton: UIButton!

    /// Key observer for map loading status.
    private var mapLoadStatusObservation: NSKeyValueObservation?

    override var geoView: AGSGeoView {
        return mapView
    }

    private var viewPointThatShouldBeApplied: AGSViewpoint?

    open override func viewDidLoad() {
        super.viewDidLoad()
        setBaseMap()
        mapView.interactionOptions.isMagnifierEnabled = false
        mapView.touchDelegate = self
        mapView.isHidden = true
        mapView.insetsContentInsetFromSafeArea = false
        mapView.isAttributionTextVisible = false
        setCameraHandler()
        isNavigatingObserver = mapView.observe(\AGSMapView.isNavigating, changeHandler: { [ weak self ] (mapView, _) in
            // NOTE: this closure can be called from a background thread so always dispatch to main
            DispatchQueue.main.async {
                self?.userNavigationDidChange(state: mapView.isNavigating)
            }
        })
    }

    override open func setBaseMap() {
        if mapView.map != nil, !mapViewModel.networkService.networkIsReachable { return }
        let currentViewPointSaved = mapView.currentViewpoint(with: .centerAndScale)
        mapView.map = AGSMap(basemapStyle: SettingsMapDisplayType.current.agsBasemapStyle)
        if let currentViewPointSaved = currentViewPointSaved {
            mapView.setViewpoint(currentViewPointSaved)
        }
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if applyDefaultCentering {
            getCenter { [weak self] viewPoint in
                guard let self = self else { return }
                self.ignoreCameraAdjustments = true
                if let center = viewPoint {
                    self.viewPointThatShouldBeApplied = (center.targetGeometry as? AGSPoint) != nil ? center : nil
                    self.mapView.setViewpoint(center)
                    self.ignoreCameraAdjustments = false
                    self.mapView.isHidden = false
                    self.defaultCenteringDone()
                } else {
                    self.centerOnDefaultPosition()

                }
                self.applyDefaultCentering = false
            }
        }
    }

    // Center map on default position
    private func centerOnDefaultPosition() {
        let agspoint = AGSPoint(clLocationCoordinate2D: CommonMapConstants.defaultLocation)
        self.viewPointThatShouldBeApplied = AGSViewpoint(center: agspoint, scale: CommonMapConstants.cameraDistanceToCenterLocation)
        self.mapView.setViewpointCenter(agspoint, scale: CommonMapConstants.cameraDistanceToCenterLocation) { [weak self] _ in
            guard let self = self else { return }
            self.ignoreCameraAdjustments = false
            self.mapView.isHidden = false
            self.defaultCenteringDone()
        }
    }

    public override func centerMap() {
        getCenter { [weak self] viewPoint in
            guard let self = self else { return }
            self.ignoreCameraAdjustments = true
            if let center = viewPoint {
                let scale = self.mapView.mapScale
                if let agspoint = center.targetGeometry as? AGSPoint {
                    self.mapView.setViewpointCenter(agspoint, scale: scale)
                } else if let envelope = center.targetGeometry as? AGSEnvelope {
                    self.mapView.setViewpointCenter(envelope.center, scale: scale)
                }
            }
        }
    }

    /// Sets camera handler.
    func setCameraHandler() {
        mapView.viewpointChangedHandler = { [weak self] in

            guard let self = self, let viewPointThatShouldBeApplied = self.viewPointThatShouldBeApplied,
                  !self.mapView.isNavigating else {
                return
            }
            // Reapply mapScale if necessary. Sometimes the AGSMap refused the scale of the viewPoint.
            if self.mapView.mapScale != viewPointThatShouldBeApplied.targetScale || self.hasBeenReset {
                guard self.mapView.mapScale != viewPointThatShouldBeApplied.targetScale else {
                    self.hasBeenReset = false
                    return
                }
                self.hasBeenReset = true
                self.mapView.setViewpoint(viewPointThatShouldBeApplied)
            }
        }
    }

    /// User navigating state on map
    ///
    /// - Parameters:
    ///    - state: user navigating state
    /// - Note: Called each time user is starting or stopping the navigation on map.
    open func userNavigationDidChange(state: Bool) {
        if !state {
            if let viewPointThatShouldBeApplied = viewPointThatShouldBeApplied {
                if mapView.mapScale != viewPointThatShouldBeApplied.targetScale {
                    self.mapView.setViewpoint(viewPointThatShouldBeApplied)
                }
            }
        } else {
            self.viewPointThatShouldBeApplied = nil
        }
    }

    /// Centers map on view point and applies it without any changes.
    public func centerMapWithoutAnyChanges() {
        getCenter { [weak self] viewPoint in
            guard let self = self else { return }
            self.ignoreCameraAdjustments = true
            self.viewPointThatShouldBeApplied = nil
            if let center = viewPoint {
                self.viewPointThatShouldBeApplied = (center.targetGeometry as? AGSPoint) != nil ? center : nil
                self.mapView.setViewpoint(center)
                self.ignoreCameraAdjustments = false
            } else {
                self.centerOnDefaultPosition()
            }
        }
    }

    private func blockZoomIfNecessary(viewPoint: AGSViewpoint) {
        // FIXME : issue with zoom
        var shouldReloadCamera = false
        var zoom = viewPoint.targetScale
        if zoom < CommonMapConstants.minZoomLevel {
            zoom = CommonMapConstants.minZoomLevel
            shouldReloadCamera = true
        } else if zoom > CommonMapConstants.maxZoomLevel {
            zoom = CommonMapConstants.maxZoomLevel
            shouldReloadCamera = true
        }
        if shouldReloadCamera {
            ignoreCameraAdjustments = true
            mapView.setViewpointScale(zoom) { [weak self] _ in
                self?.ignoreCameraAdjustments = false
            }
        }
    }

// MARK: - Auto scroll
    public func geoViewForAutoScroll() -> AGSGeoView {
        mapView
    }

    public func shouldAutoScroll() -> Bool {
        true
    }

    public func shouldAutoScrollToCenter() -> Bool {
        false
    }

    public func getCenter() -> CLLocationCoordinate2D? {
        guard let mapCenterRaw = mapView.currentViewpoint(with: .centerAndScale)?.targetGeometry as? AGSPoint else {
            return nil
        }
        return (AGSGeometryEngine.projectGeometry(mapCenterRaw, to: .wgs84()) as? AGSPoint)?.toCLLocationCoordinate2D()
    }

    public func setCenter(coordinates: CLLocationCoordinate2D) {
        mapView.setViewpoint(AGSViewpoint(center: AGSPoint(clLocationCoordinate2D: coordinates), scale: mapView.mapScale))
    }

    public func locationToScreen(_ location: AGSPoint) -> CGPoint {
        mapView.location(toScreen: location)
    }
}
