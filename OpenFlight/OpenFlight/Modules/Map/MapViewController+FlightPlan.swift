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
    /// Returns graphics overlay for Flight Plan labels.
    var flightPlanLabelsOverlay: FlightPlanLabelsGraphicsOverlay? {
        return getGraphicOverlay(forKey: Constants.overlayLabelsKey) as? FlightPlanLabelsGraphicsOverlay
    }

    // MARK: - Private Properties
    /// Returns true if flight plan is currently draped.
    private var isFlightPlanDraped: Bool {
        return flightPlanOverlay?.sceneProperties?.surfacePlacement == .drapedBillboarded
    }

    // MARK: - Private Enums
    private enum Constants {
        static let overlayKey: String = "flightPlanOverlayKey"
        static let overlayLabelsKey: String = "flightPlanLabelsOverlayKey"
        static let cameraPitchThreshold: Double = 15.0
        static let flightPlanEnvelopeMarginFactor: Double = 1.4
        static let sceneViewIdentifyTolerance: Double = 0.0
        static let sceneViewIdentifyMaxResults: Int = 5
        static let defaultPointAltitude: Double = 5.0
        static let defaultWayPointYaw: Double = 0.0
        static let defaultWayPointSpeed: Double = 2.0
    }

    // MARK: - Public Funcs
    /// Setup Flight Plan listener regarding mission mode.
    ///
    /// - Parameters:
    ///     - state: Mission Mode State
    func setupFlightPlanListener(for state: MissionProviderState) {
        // Load last edited Flight Plan
        if state.mode?.isFlightPlanPanelRequired ?? false {
            self.setMapMode(.flightPlan)
            flightPlanListener = FlightPlanManager.shared.register(didChange: { [weak self] flightPlan in
                self?.flightPlanViewModel = flightPlan
            })
            FlightPlanManager.shared.loadLastOpenedFlightPlan(state: state)
        } else {
            // Remove potential old Flight Plan first.
            FlightPlanManager.shared.currentFlightPlanViewModel = nil
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
        let graphicsLabels = provider?.graphicsLabelsWithFlightPlan(plan) ?? []
        let newOverlay = FlightPlanGraphicsOverlay(graphics: graphics)
        let newLabelOverlay = FlightPlanLabelsGraphicsOverlay(graphics: graphicsLabels)
        // Add overlays to scene.
        addGraphicOverlay(newOverlay, forKey: Constants.overlayKey)
        addGraphicOverlay(newLabelOverlay, forKey: Constants.overlayLabelsKey)
        if shouldReloadCamera {
            // Move view point of scene.
            let bufferedExtent = plan.polyline
                .envelopeWithMargin(Constants.flightPlanEnvelopeMarginFactor)
            let viewPoint = AGSViewpoint(targetExtent: bufferedExtent)
            self.updateViewPoint(viewPoint, animated: animated)
        }
        // Update graphics for current camera.
        updateFlightPlanOverlaysIfNeeded()
    }

    /// Remove currently loaded flight plan from display.
    func removeFlightPlanGraphicOverlay() {
        removeGraphicOverlay(forKey: Constants.overlayKey)
        removeGraphicOverlay(forKey: Constants.overlayLabelsKey)
        commandLimiter.flush()
    }

    /// Updates flight plan display for given camera pitch.
    ///
    /// - Parameters:
    ///    - pitch: current camera pitch
    func updateFlightPlanOverlaysIfNeeded(withCameraPitch pitch: Double? = nil) {
        let cameraPitch = pitch ?? sceneView.currentViewpointCamera().pitch
        if cameraPitch < Constants.cameraPitchThreshold && !isFlightPlanDraped {
            setFlightPlanDraped()
        } else if cameraPitch >= Constants.cameraPitchThreshold && isFlightPlanDraped {
            setFlightPlanRelative()
        }
        // Command is limited to avoid too much CPU charge.
        commandLimiter.execute { [weak self] in
            self?.updateArrows()
        }
    }

    /// Updates waypoints' arrows positions.
    func updateArrows() {
        flightPlanOverlay?.wayPointArrows
            .forEach { [weak self] arrow in
                let targetPoint = arrow.poiPoint?.agsPoint ?? arrow.wayPoint?.target

                if let wayPointLocation = arrow.mapPoint,
                    let angle = self?.getScreenAngleBetween(wayPointLocation, and: targetPoint),
                    !angle.isNaN {
                    DispatchQueue.main.async {
                        arrow.angle = Float(angle)
                    }
                }
        }
    }

    // MARK: - Helpers
    /// Computes screen angle between two map points.
    ///
    /// - Parameters:
    ///    - originPoint: the origin point
    ///    - destinationPoint: the destination point
    /// - Returns: computed angle, in degrees
    func getScreenAngleBetween(_ originPoint: AGSPoint?, and destinationPoint: AGSPoint?) -> CGFloat? {
        guard let originPoint = originPoint,
            let destinationPoint = destinationPoint
            else {
                return nil
        }
        let origin = self.isFlightPlanDraped ? originPoint.withAltitude(0.0) : originPoint
        let destination = self.isFlightPlanDraped ? destinationPoint.withAltitude(0.0) : destinationPoint
        let polyline = AGSPolyline(points: [origin,
                                            destination])
        let originPointScreenPosition = self.sceneView.location(toScreen: origin).screenPoint
        var percent = 1.0
        var destinationScreenPoint = CGPoint()
        // Step by which percent should be reduced to compute a closer point along polyline.
        let step = 0.1
        // If the destination point is not visible on screen, tries to find a point along
        // the line towards destination (until percent is too small) to determine angle.
        while destinationScreenPoint.isOriginPoint && percent > step {
            if let point = polyline.pointAt(percent: percent) {
                destinationScreenPoint = self.sceneView.location(toScreen: point).screenPoint
                percent -= step
            }
        }
        // Origin point is tested because `AGSSceneView` returns it
        // if it can't find a screen location for given point
        if !destinationScreenPoint.isOriginPoint && !originPointScreenPosition.isOriginPoint {
            let angle = GeometryUtils.angleBetween(originPointScreenPosition,
                                                   and: destinationScreenPoint)
            return angle
        } else {
            return nil
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
            if let selection = result.selectedFlightPlanObject {
                self?.flightPlanViewModel?.didTapGraphicalItem(selection)
            } else if self?.flightPlanOverlay?.hasSelection == false {
                self?.addWaypoint(atLocation: mapPoint)
                self?.updateArrows()
                self?.flightPlanViewModel?.didChangeCourse()
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
                  let index = selection.itemIndex,
                  result.error == nil else {
                completion(false)
                return
            }

            if let arrowGraphic = selection as? FlightPlanWayPointArrowGraphic,
               !arrowGraphic.isOrientationEditionAllowed(mapPoint) {
                completion(false)
                return
            }

            let labelGraphic = self?.flightPlanLabelsOverlay?.labelGraphic(at: index,
                                                                           itemType: selection.itemType)
            self?.flightPlanLabelsOverlay?.draggedGraphic = labelGraphic
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

        flightPlanOverlay?.updateDraggedGraphicLocation(mapPoint)
        flightPlanLabelsOverlay?.updateDraggedGraphicLocation(mapPoint)

        // Command is limited to avoid too much CPU charge.
        commandLimiter.execute { [weak self] in
            self?.updateArrows()
        }
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
        // If something is selected, items shouldn't be dragged.
        if flightPlanOverlay?.hasSelection == true {
            if self.flightPlanViewModel?.state.value.wayPointOrientationEditionObservable.value == true,
                let wpIndex = self.flightPlanOverlay?.selectedWayPointIndex {
                let wayPointLocation = self.flightPlanViewModel?.flightPlan?.plan.wayPoints.elementAt(index: wpIndex)?.coordinate
                let touchLocation = self.sceneView.screen(toBaseSurface: screenPoint).toCLLocationCoordinate2D()

                if let wpLoc = wayPointLocation {
                    let newYaw = GeometryUtils.yaw(fromLocation: wpLoc,
                                                   toLocation: touchLocation).toBoundedDegrees()
                    self.flightPlanViewModel?.flightPlan?.plan.wayPoints.elementAt(index: wpIndex)?.setCustomYaw(newYaw)
                    self.updateFlightPlanOverlaysIfNeeded()
                }

                self.flightPlanViewModel?.stopWayPointOrientationEdition()
            }
        } else {
            // Update graphics.
            flightPlanOverlay?.updateDraggedGraphicLocation(mapPoint)
            flightPlanLabelsOverlay?.updateDraggedGraphicLocation(mapPoint)

            if flightPlanOverlay?.draggedGraphic is FlightPlanWayPointGraphic {
                flightPlanViewModel?.didChangeCourse()
            }

            resetDraggedGraphics()
        }

        // Command is not limited here because touch up is the last action of the drag.
        updateArrows()
    }
}

// MARK: - Private Funcs
private extension MapViewController {
    /// Draps current flight plan to the ground.
    func setFlightPlanDraped() {
        flightPlanOverlay?.sceneProperties?.surfacePlacement = .drapedBillboarded
        flightPlanLabelsOverlay?.updateSurfacePlacement(isDraped: true)
    }

    /// Updates flight plan so its points are set
    /// at their actual altitude in the 3D scene.
    func setFlightPlanRelative() {
        flightPlanOverlay?.sceneProperties?.surfacePlacement = .relative
        flightPlanLabelsOverlay?.updateSurfacePlacement(isDraped: false)
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
                                altitude: lastWayPoint?.altitude ?? Constants.defaultPointAltitude,
                                yaw: Constants.defaultWayPointYaw,
                                speed: lastWayPoint?.speed ?? Constants.defaultWayPointSpeed,
                                shouldContinue: true,
                                shouldFollowPOI: false,
                                poiIndex: nil,
                                actions: nil)
        flightPlan.plan.addWaypoint(wayPoint)
        let index = flightPlan.plan.wayPoints.count - 1
        let graphics = wayPoint.markerGraphic(index: index)
        let labelGraphics = wayPoint.labelsGraphic(index: index)
        flightPlanOverlay?.graphics.add(graphics)
        flightPlanLabelsOverlay?.graphics.add(labelGraphics)
        if let angle = getScreenAngleBetween(wayPoint.agsPoint,
                                             and: wayPoint.target) {
            let arrowGraphic = FlightPlanWayPointArrowGraphic(wayPoint: wayPoint,
                                                              wayPointIndex: index,
                                                              angle: Float(angle))
            flightPlanOverlay?.graphics.add(arrowGraphic)
        }
        if let lineGraphic = flightPlan.plan.lastLineGraphic {
            flightPlanOverlay?.graphics.add(lineGraphic)
        }
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
        let graphic = poi.markerGraphic(index: index)
        let labelGraphic = poi.labelGraphic(index: index)
        flightPlanOverlay?.graphics.add(graphic)
        flightPlanLabelsOverlay?.graphics.add(labelGraphic)
    }

    /// Resets currently dragged graphic on overlays.
    func resetDraggedGraphics() {
        flightPlanOverlay?.draggedGraphic = nil
        flightPlanOverlay?.startDragTimeStamp = 0.0
        flightPlanLabelsOverlay?.draggedGraphic = nil
    }
}
