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

import ArcGIS
import GroundSdk

/// `MapViewController` extension dedicated to Flight Plan's display.
public extension MapViewController {
    // MARK: - Public Properties
    /// Returns graphics overlay for Flight Plan symbols.
    var flightPlanOverlay: FlightPlanGraphicsOverlay? {
        return getGraphicOverlay(forKey: Constants.overlayKey) as? FlightPlanGraphicsOverlay
    }

    // MARK: - Private Enums
    private enum Constants {
        static let overlayKey: String = "flightPlanOverlayKey"
        // Do not follow Arcgis recommandations (22).
        // Otherwise waypoint orientation is not touchable.
        static let sceneViewIdentifyTolerance: Double = 0
        static let sceneViewIdentifyMaxResults: Int = 5
        static let defaultPointAltitude: Double = 5.0
        static let defaultWayPointYaw: Double = 0.0
    }

    // MARK: - Public Funcs
    /// Setup Flight Plan listener regarding mission mode.
    ///
    /// - Parameters:
    ///     - state: Mission Mode State
    func setupFlightPlanListener(for state: MissionProviderState) {
        flightEditionService = Services.hub.flightPlan.edition
        flightPlanManager = Services.hub.flightPlan.run
        if state.mode?.flightPlanProvider != nil {
            // Reset registration.
            flightEditionService?.currentFlightPlanPublisher
                .removeDuplicates()
                .sink(receiveValue: { [weak self] flightplan in
                    self?.flightPlan = flightplan
                })
                .store(in: &editionCancellables)
            // Update the map when an FP just setted up in the editor.
            flightEditionService?.flightPlanSettedUpPublisher
                .sink { [weak self] in self?.update(with: $0) }
                .store(in: &editionCancellables)
        } else {
            // Remove potential old Flight Plan first.
            flightEditionService?.resetFlightPlan()
            // Then, unregister flight plan listener (editionCancellable = nil has effet if map is registred).
            editionCancellables.removeAll()
        }
    }

    /// Called to display a flight plan.
    ///
    /// - Parameters:
    ///    - flightPlan: flight plan model
    ///    - shouldReloadCamera: whether scene's camera should be reloaded
    func displayFlightPlan(_ flightPlan: FlightPlanModel,
                           shouldReloadCamera: Bool = false) {
        // Remove old Flight Plan graphic overlay.
        removeFlightPlanGraphicOverlay()
        // Get flight plan provider.
        let provider: FlightPlanProvider?
        if let mission = currentMissionProviderState?.mode {
            provider = mission.flightPlanProvider
        } else if let mission = Services.hub.missionsStore.missionFor(flightPlan: flightPlan)?.mission {
            provider = mission.flightPlanProvider
        } else {
            return
        }

        // Create new overlays.
        let graphics = provider?.graphicsWithFlightPlan(flightPlan, mapMode: currentMapMode) ?? []

        let newOverlay = FlightPlanGraphicsOverlay(graphics: graphics)
        // Add overlays to scene only if not in miniature mode.
        if !isMiniMap {
            addGraphicOverlay(newOverlay, forKey: Constants.overlayKey, at: 0)
        }
        // Update type of map to get altitude.
        updateElevationVisibility()

        // Move user and drone graphic if necessary in flight plan overlay
        insertUserGraphic()
        insertDroneGraphic()

        // refresh orientaiton of origin graphic
        refreshOriginGraphic()

        // apply an altitude offset and update the map view point,
        // and do it again once map elevation data are loaded;
        // the cancellable is stored in a dedicated variable in order to cancel any pending adjustments
        adjustAltitudeAndCameraCancellable = viewModel.elevationSource.$elevationLoaded
            .filter { $0 }
            .sink { [weak self] elevationLoaded in
                guard elevationLoaded, let self = self else { return }
                self.adjustAltitudeAndCamera(overlay: newOverlay,
                                             flightPlan: flightPlan,
                                             shouldReloadCamera: shouldReloadCamera)
            }
    }

    /// Refresh orientation of origin graphic if map is drapedFlat.
    private func refreshOriginGraphic() {
        guard flightPlanOverlay?.sceneProperties?.surfacePlacement == .drapedFlat else { return }
        let camera = SceneSingleton.shared.sceneView.currentViewpointCamera()
        guard let originGraphic = (flightPlanOverlay?.graphics.first(where: { $0 is FlightPlanOriginGraphic }) as? FlightPlanOriginGraphic) else { return }
        originGraphic.update(heading: camera.heading)
    }

    /// Applies an altitude offset to graphics overlay, corresponding to altitude in AMSL of first waypoint and ajdusts map view point.
    ///
    /// Flight plan's altitudes are relative to first waypoint altitude.
    /// The flight plan overlay is drawn in absolute mode.
    /// So we apply first waypoint altitude as overlay altitude offset.
    ///
    /// - Parameters:
    ///    - overlay: graphics overlay that handles flight plan display
    ///    - flightPlan: displayed flight plan
    ///    - shouldReloadCamera: whether scene's camera should be reloaded
    func adjustAltitudeAndCamera(overlay: AGSGraphicsOverlay,
                                 flightPlan: FlightPlanModel,
                                 shouldReloadCamera: Bool) {
        guard !isMiniMap else { return }
        // get first waypoint
        guard let firstWayPoint = flightPlan.dataSetting?.wayPoints.first?.agsPoint else { return }

        ULog.d(.mapViewController, "Get elevation for FP at: \(firstWayPoint.x),\(firstWayPoint.y)")
        firstWpElevationRequest?.cancel()
        firstWpElevationRequest = nil
        firstWpElevationRequest = sceneView.scene?.baseSurface?.elevation(for: firstWayPoint) { [weak self] elevation, error in
            self?.firstWpElevationRequest = nil
            guard error == nil else {
                ULog.w(.mapViewController, "Failed to get elevation for FP: \(String(describing: error))")
                return
            }
            if flightPlan.isAMSL != true {
                ULog.d(.mapViewController, "Apply altitude offset to FP overlay: \(elevation)")
                overlay.sceneProperties?.altitudeOffset = elevation
            } else {
                ULog.d(.mapViewController, "Do not apply altitude offset to FP overlay (AMSL): \(elevation)")
            }
            if shouldReloadCamera {
                // Animate camera reloading, as only altitude has changed.
                self?.reloadCamera(flightPlan: flightPlan,
                                   altitudeOffset: elevation,
                                   animated: false)
            }
        }
    }

    /// Sets current view point based on a given FP model.
    ///
    /// - Parameters:
    ///    - flightPlan: the FP model to base the view point on
    ///    - altitudeOffset: the altitude offset to apply to view point, if any (nil by default)
    ///    - animated: whether the view point change should be animated
    func setViewPoint(for flightPlan: FlightPlanModel, altitudeOffset: Double? = nil, animated: Bool = false) {
        ULog.d(.mapViewController, "Set view point for FP, altitudeOffset \(altitudeOffset?.description ?? "nil")")
        guard let dataSetting = flightPlan.dataSetting else { return }

        let viewPoint = viewPoint(polyline: dataSetting.polyline,
                                  altitudeOffset: altitudeOffset)
        updateViewPoint(viewPoint, animated: animated)
        if altitudeOffset == nil, sceneView.scene?.baseSurface?.isEnabled == true {
            moveCameraByElevation(goUp: true)
        }
    }

    /// Moves the camera so when elevation is enabled/disabled the scene don't act like zooming when the ground approaches the camera.
    ///
    /// - Parameters:
    ///    - goUp: If true, the camera moves up by ground elevation from sealevel. A value false makes the camera move down by the same distance.
    func moveCameraByElevation(goUp: Bool) {
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

    /// Reloads the camera based on a given FP model.
    ///
    /// - Parameters:
    ///    - flightPlan: the FP model to base the camera on
    ///    - altitudeOffset: the altitude offset to apply to view point, if any (nil by default)
    ///    - animated: whether the view point change should be animated
    func reloadCamera(flightPlan: FlightPlanModel, altitudeOffset: Double, animated: Bool) {
        ULog.d(.mapViewController, "Reload camera for FP, altitudeOffset \(altitudeOffset)")
        setViewPoint(for: flightPlan,
                     altitudeOffset: shouldDisplayMapIn2D ? nil : altitudeOffset,
                     animated: animated)

        updateElevationVisibility()
        flightPlanOverlay?.update(heading: flightPlanOverlay?.cameraHeading ?? 0)
        // insert user and drone locations graphics to flight plan overlay
        insertUserGraphic()
        insertDroneGraphic()
        ULog.d(.mapViewController, "Camera reloaded for FP, altitudeOffset \(altitudeOffset)")
    }

    /// Remove currently loaded flight plan from display.
    func removeFlightPlanGraphicOverlay() {
        clearGraphics()
        // remove user and drone locations graphics from flight plan overlay
        flightPlanOverlay?.setUserGraphic(nil)
        flightPlanOverlay?.setDroneGraphic(nil)
        // remove flight plan overlay
        removeGraphicOverlay(forKey: Constants.overlayKey)
        // move user and drone locations graphics to dedicated overlay
        insertUserGraphic()
        insertDroneGraphic()
    }

    /// Shows or hides surface elevation and flight plan elevation, depending on state.
    ///
    /// Map and flight plan are displayed in 2D when `shouldDisplayMapIn2D` is `true`.
    /// Otherwise, they are displayed in 3D.
    func updateElevationVisibility() {
        if shouldDisplayMapIn2D {
            disableElevation()
        } else {
            enableElevation()
        }
    }

    /// Removes a waypoint to Flight Plan.
    ///
    /// - Parameters:
    ///    - index: waypoint index
    func removeWayPoint(at index: Int) {
        flightEditionService?.removeWaypoint(at: index)
        flightPlanOverlay?.removeWayPoint(at: index)
        flightDelegate?.didChangeCourse()
    }

    /// Removes a point of interest to Flight Plan.
    ///
    /// - Parameters:
    ///    - index: point of interest index
    func removePOI(at index: Int) {
        flightEditionService?.removePoiPoint(at: index)
        flightPlanOverlay?.removePoiPoint(at: index)
        flightDelegate?.didChangePointOfView()
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

}

// MARK: - Map Gestures
extension MapViewController {

    func identify(screenPoint: CGPoint, _ completion: @escaping (AGSIdentifyGraphicsOverlayResult?) -> Void) {
        guard let overlay = flightPlanOverlay else {
            completion(nil)
            return
        }
        sceneView.identify(overlay,
                            screenPoint: screenPoint,
                            tolerance: Constants.sceneViewIdentifyTolerance,
                            returnPopupsOnly: false,
                            maximumResults: Constants.sceneViewIdentifyMaxResults) { result in
            completion(result)
        }
    }

    /// Handles tap action in Flight Plan edition mode.
    ///
    /// - Parameters:
    ///    - geoView: the view on which the tap occured
    ///    - screenPoint: the screen point where the tap occured
    ///    - mapPoint: the corresponding map location
    func flightPlanHandleTap(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        identify(screenPoint: screenPoint) { [weak self] result in
            guard let result = result else { return }
            // Select the graphic tap by user and store it.
            if let selection = result.selectedFlightPlanObject {
                self?.flightPlanOverlay?.lastManuallySelectedGraphic = selection
                self?.flightDelegate?.didTapGraphicalItem(selection)
            } else {
                // If user has select manually the graphic previously, it will be deselected.
                // else if it was programatically select add a new waypoint
                if let userSelection = self?.flightPlanOverlay?.lastManuallySelectedGraphic, userSelection.isSelected {
                    self?.flightDelegate?.didTapGraphicalItem(nil)
                } else {
                    self?.addWaypoint(atLocation: mapPoint)
                    self?.flightDelegate?.didChangeCourse()
                }
            }
        }
    }

    /// Handles long press action in Flight Plan edition mode.
    ///
    /// - Parameters:
    ///    - geoView: the view on which the tap occured
    ///    - screenPoint: the screen point where the tap occured
    ///    - mapPoint: the corresponding map location
    func flightPlanHandleLongPress(_ geoView: AGSGeoView,
                                   didLongPressAtScreenPoint screenPoint: CGPoint,
                                   mapPoint: AGSPoint) {
        identify(screenPoint: screenPoint) { [weak self] result in
            guard let result = result else { return }
            if result.selectedFlightPlanObject == nil {
                self?.addPoiPoint(atLocation: mapPoint)
            }
        }
    }

    /// Handles touch down action in Flight Plan edition mode.
    ///
    /// - Parameters:
    ///    - geoView: the view on which the touch down occured
    ///    - screenPoint: the screen point where the touch down occured
    ///    - mapPoint: the corresponding map location
    ///    - completion: completion for `AGSGeoView` (will handle drag)
    func flightPlanHandleTouchDown(_ geoView: AGSGeoView,
                                   didTouchDownAtScreenPoint screenPoint: CGPoint,
                                   mapPoint: AGSPoint,
                                   completion: @escaping (Bool) -> Void) {
        guard let overlay = flightPlanOverlay else {
            completion(false)
            return
        }
        identify(screenPoint: screenPoint) { result in
            guard let result = result else { completion(false); return }
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
    }

    /// Handles touch drag action in Flight Plan edition mode.
    ///
    /// - Parameters:
    ///    - geoView: the view on which the drag occured
    ///    - screenPoint: the screen point where the drag occured
    ///    - mapPoint: the corresponding map location
    func flightPlanHandleTouchDrag(_ geoView: AGSGeoView,
                                   didTouchDragToScreenPoint screenPoint: CGPoint,
                                   mapPoint: AGSPoint) {
        // Drag should be ignored if it occurs before a certain duration (to avoid conflict with tap gesture).
        guard let dragTimeStamp = flightPlanOverlay?.startDragTimeStamp,
            ProcessInfo.processInfo.systemUptime > dragTimeStamp + Style.tapGestureDuration else {
                return
        }

        flightPlanOverlay?.updateDraggedGraphicLocation(mapPoint, editor: nil, isDragging: true)
    }

    /// Handles touch up action in Flight Plan edition mode.
    ///
    /// - Parameters:
    ///    - geoView: the view on which the touch up occured
    ///    - screenPoint: the screen point where the touch up occured
    ///    - mapPoint: the corresponding map location
    func flightPlanHandleTouchUp(_ geoView: AGSGeoView,
                                 didTouchUpAtScreenPoint screenPoint: CGPoint,
                                 mapPoint: AGSPoint) {
        // If touch up occurs before a certain duration, gesture is treated as a tap.
        guard let dragTimeStamp = flightPlanOverlay?.startDragTimeStamp,
            ProcessInfo.processInfo.systemUptime > dragTimeStamp + Style.tapGestureDuration else {
            flightPlanHandleTap(geoView, didTapAtScreenPoint: screenPoint, mapPoint: mapPoint)
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
}

// MARK: - Private Funcs
private extension MapViewController {
    /// Disables elevation and displays flight plan in `drapedFlat` mode.
    func disableElevation() {
        if flightPlanOverlay?.sceneProperties?.surfacePlacement != .drapedFlat {
            ULog.d(.mapViewController, "disableElevation surfacePlacement")
            flightPlanOverlay?.sceneProperties?.surfacePlacement = .drapedFlat
        }
        if sceneView.scene?.baseSurface?.isEnabled != false {
            ULog.d(.mapViewController, "disableElevation baseSurface")
            sceneView.scene?.baseSurface?.isEnabled = false
        }
    }

    /// Enables elevation and displays flight plan in `absolute` mode.
    func enableElevation() {
        if flightPlanOverlay?.sceneProperties?.surfacePlacement != .absolute {
            ULog.d(.mapViewController, "enableElevation surfacePlacement")
            flightPlanOverlay?.sceneProperties?.surfacePlacement = .absolute
        }
        if sceneView.scene?.baseSurface?.isEnabled != true {
            ULog.d(.mapViewController, "enableElevation baseSurface")
            sceneView.scene?.baseSurface?.isEnabled = true
        }
    }

    /// Adds a waypoint to Flight Plan.
    ///
    /// - Parameters:
    ///    - location: waypoint location
    func addWaypoint(atLocation location: AGSPoint) {
        guard let editionService = flightEditionService else { return }
        let lastWayPoint = editionService.currentFlightPlanValue?.dataSetting?.wayPoints.last
        let wayPoint = WayPoint(coordinate: CLLocationCoordinate2D(latitude: location.y,
                                                                   longitude: location.x),
                                altitude: lastWayPoint?.altitude,
                                yaw: Constants.defaultWayPointYaw,
                                speed: lastWayPoint?.speed,
                                shouldContinue: editionService.currentFlightPlanValue?.dataSetting?.shouldContinue ?? true,
                                tilt: lastWayPoint?.tilt)

        let index = editionService.addWaypoint(wayPoint) - 1
        let wayPointGraphic = wayPoint.markerGraphic(index: index)
        wayPointGraphic.update(heading: sceneView.currentViewpointCamera().heading)
        flightPlanOverlay?.graphics.add(wayPointGraphic)

        let angle = wayPoint.yaw ?? Constants.defaultWayPointYaw
        let arrowGraphic = FlightPlanWayPointArrowGraphic(wayPoint: wayPoint,
                                                          wayPointIndex: index,
                                                          angle: Float(angle))
        flightPlanOverlay?.graphics.add(arrowGraphic)

        if let lineGraphic = editionService.currentFlightPlanValue?.dataSetting?.lastLineGraphic {
            flightPlanOverlay?.graphics.add(lineGraphic)
        }

        let previousArrow = flightPlanOverlay?.wayPointArrows.first(where: { $0.wayPointIndex == index - 1 })
        previousArrow?.refreshOrientation()

        flightDelegate?.didTapGraphicalItem(wayPointGraphic)
    }

    /// Adds a point of interest to Flight Plan.
    ///
    /// - Parameters:
    ///    - location: point of interest location
    func addPoiPoint(atLocation location: AGSPoint) {
        guard let editionService = flightEditionService else { return }
        let poi = PoiPoint(coordinate: CLLocationCoordinate2D(latitude: location.y,
                                                              longitude: location.x),
                           altitude: Constants.defaultPointAltitude,
                           color: 0)
        let index = editionService.addPoiPoint(poi) - 1
        poi.addIndex(index: index)
        let poiGraphic = poi.markerGraphic(index: index)
        poiGraphic.update(heading: sceneView.currentViewpointCamera().heading)
        flightPlanOverlay?.graphics.add(poiGraphic)
        flightDelegate?.didChangePointOfView()
        flightDelegate?.didTapGraphicalItem(poiGraphic)
    }

    /// Resets currently dragged graphic on overlays.
    func resetDraggedGraphics() {
        flightPlanOverlay?.draggedGraphic = nil
        flightPlanOverlay?.startDragTimeStamp = 0.0
    }
}

// MARK: - EditionSettingsDelegate
extension MapViewController: EditionSettingsDelegate {
    public func updateMode(tag: Int) {
        updateFlightPlanType(tag: tag)
    }

    public func updateSettingValue(for key: String?, value: Int) {
        updateSetting(for: key, value: value)
    }

    public func updateChoiceSetting(for key: String?, value: Bool) {
        updateSetting(for: key, value: value == true ? 0 : 1)
    }

    public func isUpdatingSetting(for key: String?, isUpdating: Bool) {
        // nothing to do
    }

    public func didTapCloseButton() {}
    public func didTapDeleteButton() {}
    public func canUndo() -> Bool {
        return false
    }
}
