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

import ArcGIS

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
        static let cameraPitchThreshold: Double = 15.0
        static let flightPlanEnvelopeMarginFactor: Double = 1.4
        static let sceneViewIdentifyTolerance: Double = 0.0
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
        if state.mode?.isFlightPlanPanelRequired ?? false {
            // Reset registration.
            FlightPlanManager.shared.unregister(flightPlanListener)
            self.setMapMode(.flightPlan)
            flightPlanListener = FlightPlanManager.shared.register(didChange: { [weak self] flightPlan in
                self?.flightPlanViewModel = flightPlan
            })
            // Load last edited Flight Plan.
            FlightPlanManager.shared.loadLastOpenedFlightPlan(state: state)
        } else {
            // Remove potential old Flight Plan first.
            FlightPlanManager.shared.currentFlightPlanViewModel = nil
            // Then, unregister flight plan listener (currentFlightPlanViewModel = nil has effet if map is registred).
            FlightPlanManager.shared.unregister(flightPlanListener)
        }
    }

    /// Called to display a flight plan.
    ///
    /// - Parameters:
    ///    - flightPlanViewModel: flight plan view model
    ///    - shouldReloadCamera: whether scene's camera should be reloaded
    ///    - animated: whether camera reload should be animated
    func displayFlightPlan(_ flightPlanViewModel: FlightPlanViewModel,
                           shouldReloadCamera: Bool = false,
                           animated: Bool = false) {
        // Remove old Flight Plan graphic overlay.
        self.removeFlightPlanGraphicOverlay()

        guard let plan = flightPlanViewModel.flightPlan?.plan
            else { return }
        // Create new overlays.
        let provider = currentMissionProviderState?.mode?.flightPlanProvider
        let graphics = provider?.graphicsWithFlightPlan(plan) ?? []
        let newOverlay = FlightPlanGraphicsOverlay(graphics: graphics)
        // Add overlays to scene.
        addGraphicOverlay(newOverlay, forKey: Constants.overlayKey, at: 0)
        if shouldReloadCamera {
            // Move view point of scene.
            let bufferedExtent = plan.polyline
                .envelopeWithMargin(Constants.flightPlanEnvelopeMarginFactor)
            let viewPoint = AGSViewpoint(targetExtent: bufferedExtent)
            self.updateViewPoint(viewPoint, animated: animated)
        }
        // Update graphics for current camera.
        updateElevationVisibility()
        flightPlanOverlay?.update(heading: flightPlanOverlay?.cameraHeading ?? 0)
        // insert user and drone locations graphics to flight plan overlay
        insertUserGraphic()
        insertDroneGraphic()
    }

    /// Remove currently loaded flight plan from display.
    func removeFlightPlanGraphicOverlay() {
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
    /// Map and flight plan are displayed in 3D when `allowElevationHiding` returns `true`
    /// and flight plan is in edition mode. Otherwise, they are displayed in 2D.
    func updateElevationVisibility() {
        if shouldDisplayMapIn2D {
            if !isFlightPlanDraped {
                setFlightPlanDraped()
            }
        } else if isFlightPlanDraped {
            setFlightPlanRelative()
        }
    }

    /// Removes a waypoint to Flight Plan.
    ///
    /// - Parameters:
    ///    - index: waypoint index
    func removeWayPoint(at index: Int) {
        flightPlanViewModel?.flightPlan?.plan.removeWaypoint(at: index)
        flightPlanOverlay?.removeWayPoint(at: index)
        flightPlanViewModel?.didChangeCourse()
    }

    /// Removes a point of interest to Flight Plan.
    ///
    /// - Parameters:
    ///    - index: point of interest index
    func removePOI(at index: Int) {
        flightPlanViewModel?.flightPlan?.plan.removePoiPoint(at: index)
        flightPlanOverlay?.removePoiPoint(at: index)
        flightPlanViewModel?.didChangePointOfView()
    }

    // MARK: - Helpers
    /// Restore selected item after a flight plan reload.
    ///
    /// - Parameters:
    ///     - graphic: graphic to select
    ///     - index: graphic index
    func restoreSelectedItem(_ graphic: FlightPlanGraphic, at index: Int?) {
        if let wpIndex = index,
           let newGraphic = self.flightPlanOverlay?.graphicForIndex(wpIndex, type: graphic.itemType) {
            flightPlanViewModel?.didTapGraphicalItem(newGraphic)
        } else {
            flightPlanViewModel?.didTapGraphicalItem(graphic)
        }
    }

}

// MARK: - Map Gestures
extension MapViewController {

    /// Handles tap action in Flight Plan edition mode.
    ///
    /// - Parameters:
    ///    - geoView: the view on which the tap occured
    ///    - screenPoint: the screen point where the tap occured
    ///    - mapPoint: the corresponding map location
    func flightPlanHandleTap(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        guard let overlay = flightPlanOverlay else {
            return
        }
        sceneView?.identify(overlay,
                            screenPoint: screenPoint,
                            tolerance: Constants.sceneViewIdentifyTolerance,
                            returnPopupsOnly: false,
                            maximumResults: Constants.sceneViewIdentifyMaxResults) { [weak self] result in
            // Select the graphic tap by user and store it.
            if let selection = result.selectedFlightPlanObject {
                self?.flightPlanOverlay?.lastManuallySelectedGraphic = selection
                self?.flightPlanViewModel?.didTapGraphicalItem(selection)
            } else {
                // If user has select manually the graphic previously, it will be deselected.
                // else if it was programatically select add a new waypoint
                if let userSelection = self?.flightPlanOverlay?.lastManuallySelectedGraphic, userSelection.isSelected {
                    self?.flightPlanViewModel?.didTapGraphicalItem(nil)
                } else {
                    self?.addWaypoint(atLocation: mapPoint)
                    self?.flightPlanViewModel?.didChangeCourse()
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
        guard let overlay = flightPlanOverlay else {
            return
        }
        sceneView?.identify(overlay,
                            screenPoint: screenPoint,
                            tolerance: Constants.sceneViewIdentifyTolerance,
                            returnPopupsOnly: false) { [weak self] result in
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
        sceneView?.identify(overlay,
                            screenPoint: screenPoint,
                            tolerance: Constants.sceneViewIdentifyTolerance,
                            returnPopupsOnly: false,
                            maximumResults: Constants.sceneViewIdentifyMaxResults) { [weak self] result in
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

            let index: Int
            if let wayPointGraphic = selection as? WayPointRelatedGraphic,
               let wayPointIndex = wayPointGraphic.wayPointIndex {
                index = wayPointIndex
            } else if let poiPointGraphic = selection as? PoiPointRelatedGraphic,
                      let poiPointIndex = poiPointGraphic.poiIndex {
                index = poiPointIndex
            } else {
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

        flightPlanOverlay?.updateDraggedGraphicLocation(mapPoint, editor: nil)
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
                self.flightPlanViewModel?.stopWayPointOrientationEdition()
                resetDraggedGraphics()
                return
        }
        flightPlanOverlay?.updateDraggedGraphicLocation(mapPoint, editor: flightPlanEditionViewController)

        // Check if WP orientation is selected.
        if flightPlanOverlay?.hasSelection == true,
           self.flightPlanViewModel?.state.value.wayPointOrientationEditionObservable.value == true {

            if let wpIndex = self.flightPlanOverlay?.selectedWayPointIndex {
                let wayPointLocation = self.flightPlanViewModel?.flightPlan?.plan.wayPoints.elementAt(index: wpIndex)?.agsPoint
                let touchLocation = self.sceneView.screen(toBaseSurface: screenPoint)

                if let wpLoc = wayPointLocation {
                    let newYaw = AGSGeometryEngine.standardGeodeticDistance(between: wpLoc,
                                                                            and: touchLocation,
                                                                            azimuthUnit: .degrees())?.azimuth1 ?? 0.0
                    self.flightPlanViewModel?.flightPlan?.plan.wayPoints.elementAt(index: wpIndex)?.setCustomYaw(newYaw.asPositiveDegrees)
                    updateElevationVisibility()
                }

                self.flightPlanViewModel?.stopWayPointOrientationEdition()
            }
        } else {
            // Update graphics.

            if flightPlanOverlay?.draggedGraphic is FlightPlanWayPointGraphic {
                flightPlanViewModel?.didChangeCourse()
            } else if flightPlanOverlay?.draggedGraphic is FlightPlanPoiPointGraphic {
                flightPlanViewModel?.didChangePointOfView()
            } else if flightPlanOverlay?.draggedGraphic is FlightPlanWayPointArrowGraphic {
                flightPlanViewModel?.didChangePointOfView()
            }

            resetDraggedGraphics()
        }
    }
}

// MARK: - Private Funcs
private extension MapViewController {
    /// Draps current flight plan to the ground.
    func setFlightPlanDraped() {
        flightPlanOverlay?.sceneProperties?.surfacePlacement = .drapedFlat
        sceneView?.scene?.baseSurface?.isEnabled = false
    }

    /// Updates flight plan so its points are set
    /// at their actual altitude in the 3D scene.
    func setFlightPlanRelative() {
        flightPlanOverlay?.sceneProperties?.surfacePlacement = .relative
        sceneView?.scene?.baseSurface?.isEnabled = true
    }

    /// Adds a waypoint to Flight Plan.
    ///
    /// - Parameters:
    ///    - location: waypoint location
    func addWaypoint(atLocation location: AGSPoint) {
        guard let flightPlan = flightPlanViewModel?.flightPlan else {
            return
        }
        let lastWayPoint = flightPlan.plan.wayPoints.last
        let wayPoint = WayPoint(coordinate: CLLocationCoordinate2D(latitude: location.y,
                                                                   longitude: location.x),
                                altitude: lastWayPoint?.altitude,
                                yaw: Constants.defaultWayPointYaw,
                                speed: lastWayPoint?.speed,
                                shouldContinue: flightPlan.plan.shouldContinue ?? true,
                                tilt: lastWayPoint?.tilt)

        flightPlan.plan.addWaypoint(wayPoint)
        let index = flightPlan.plan.wayPoints.count - 1
        let wayPointGraphic = wayPoint.markerGraphic(index: index)
        wayPointGraphic.update(heading: flightPlanOverlay?.cameraHeading ?? 0)
        flightPlanOverlay?.graphics.add(wayPointGraphic)

        let angle = wayPoint.yaw ?? Constants.defaultWayPointYaw
        let arrowGraphic = FlightPlanWayPointArrowGraphic(wayPoint: wayPoint,
                                                          wayPointIndex: index,
                                                          angle: Float(angle))
        flightPlanOverlay?.graphics.add(arrowGraphic)

        if let lineGraphic = flightPlan.plan.lastLineGraphic {
            flightPlanOverlay?.graphics.add(lineGraphic)
        }

        let previousArrow = flightPlanOverlay?.wayPointArrows.first(where: { $0.wayPointIndex == index - 1 })
        previousArrow?.refreshOrientation()

        flightPlanViewModel?.didTapGraphicalItem(wayPointGraphic)
    }

    /// Adds a point of interest to Flight Plan.
    ///
    /// - Parameters:
    ///    - location: point of interest location
    func addPoiPoint(atLocation location: AGSPoint) {
        guard let flightPlan = flightPlanViewModel?.flightPlan else {
            return
        }
        let poi = PoiPoint(coordinate: CLLocationCoordinate2D(latitude: location.y,
                                                              longitude: location.x),
                           altitude: Constants.defaultPointAltitude,
                           color: 0)
        flightPlan.plan.addPoiPoint(poi)
        let index = flightPlan.plan.pois.count - 1
        poi.addIndex(index: index)
        let poiGraphic = poi.markerGraphic(index: index)
        poiGraphic.update(heading: flightPlanOverlay?.cameraHeading ?? 0)
        flightPlanOverlay?.graphics.add(poiGraphic)
        flightPlanViewModel?.didChangePointOfView()
        flightPlanViewModel?.didTapGraphicalItem(poiGraphic)
    }

    /// Resets currently dragged graphic on overlays.
    func resetDraggedGraphics() {
        flightPlanOverlay?.draggedGraphic = nil
        flightPlanOverlay?.startDragTimeStamp = 0.0
    }
}

// MARK: - FlightPlanEditionViewControllerDelegate
extension MapViewController: EditionSettingsDelegate {
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
