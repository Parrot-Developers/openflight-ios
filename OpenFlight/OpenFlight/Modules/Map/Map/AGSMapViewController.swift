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
open class AGSMapViewController: CommonMapViewController {
    @IBOutlet public weak var mapView: AGSMapView!
    @IBOutlet weak var centerButton: UIButton!

    /// Key observer for map loading status.
    private var mapLoadStatusObservation: NSKeyValueObservation?
    /// Current view point saved before a reset of the scene view.
    private var currentViewPointSaved: AGSViewpoint?

    /// Whether Centering is in progress.
    open var centering = false

    override var geoView: AGSGeoView {
        return mapView
    }

    override open func setBaseMap() {
        guard currentMapType != SettingsMapDisplayType.current else { return }

        currentMapType = SettingsMapDisplayType.current
        if mapView.map == nil {
            mapView.map = AGSMap(basemapStyle: SettingsMapDisplayType.current.agsBasemapStyle)
            if let currentViewPointSaved = currentViewPointSaved {
                mapView.setViewpoint(currentViewPointSaved)
            } else {
                centerMapWithoutAnyChanges()
            }
        } else {
            mapView.map?.basemap =  SettingsMapDisplayType.current.agsBasemap
        }

        mapView.isAttributionTextVisible = false
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        // Do not remove set Base map, it will remove the white bottom bar displayed by default by
        // ArcGIS if there is no connection.
        setBaseMap()
        setCameraHandler()
        mapView.interactionOptions.isMagnifierEnabled = false
        mapView.touchDelegate = self
        mapView.isHidden = true
    }

    /// Resets base map to reload it.
    open override func resetBaseMap() {
        let currentViewPoint = mapView.currentViewpoint(with: .centerAndScale)
        currentViewPointSaved = currentViewPoint
        mapView.map = nil
        currentMapType = nil
        setBaseMap()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setBaseMap()
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if applyDefaultCentering {
            getCenter { [weak self] viewPoint in
                guard let self = self else { return }
                self.ignoreCameraAdjustments = true
                if let center = viewPoint {
                    self.mapView.setViewpoint(center)
                    self.ignoreCameraAdjustments = false
                    self.mapView.isHidden = false
                    self.defaultCenteringDone()
                } else {
                    let agspoint = AGSPoint(clLocationCoordinate2D: CommonMapConstants.defaultLocation)
                    self.mapView.setViewpointCenter(agspoint, scale: CommonMapConstants.cameraDistanceToCenterLocation) { [weak self] _ in
                        guard let self = self else { return }
                        self.ignoreCameraAdjustments = false
                        self.mapView.isHidden = false
                        self.defaultCenteringDone()
                    }
                }
                self.applyDefaultCentering = false
            }
        }

    }

    /// Adds home graphic overlay to map view.
    ///
    /// - Parameter zIndex: the z index of the home graphic to add
    public func addHomeOverlay(at zIndex: Int) {
        // TODO: Injection.
        let homeLocationOverlay = HomeLocationGraphicsOverlay(rthService: Services.hub.drone.rthService,
                                                              mapViewModel: mapViewModel)
        mapView.graphicsOverlays.insert(homeLocationOverlay, at: zIndex)
    }

    /// Sets camera handler.
    private func setCameraHandler() {
        mapView.viewpointChangedHandler = { [weak self] in
        }
    }

    public override func centerMap() {
        getCenter { [weak self] viewPoint in
            guard let self = self else { return }
            self.ignoreCameraAdjustments = true
            if let center = viewPoint {
                self.centering = true
                let scale = self.mapView.mapScale
                if let agspoint = center.targetGeometry as? AGSPoint {
                    self.mapView.setViewpointCenter(agspoint, scale: scale) { [weak self] _ in
                        self?.centering = false
                    }
                } else if let envelope = center.targetGeometry as? AGSEnvelope {
                    self.mapView.setViewpointCenter(envelope.center, scale: scale) { [weak self] _ in
                        self?.centering = false
                    }
                }
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
                self.mapView.setViewpoint(center)
                self.ignoreCameraAdjustments = false
                self.centering = false
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
}
