//    Copyright (C) 2021 Parrot Drones SAS
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

import CoreLocation
import ArcGIS

/// `MapViewController` extension dedicated to Touch and Fly's display.
extension MapViewController {
    // MARK: - Private Enums
    private enum Constants {
        // Note: touch and fly uses Flight Plan's overlay and graphics
        // to benefit from its draped/relative graphics mechanics.
        static let overlayKey: String = "flightPlanOverlayKey"
    }

    /// Displays a waypoint at target location.
    ///
    /// - Parameters:
    ///    - location: waypoint's location
    ///    - droneLocation: drone's location
    func displayWayPoint(at location: Location3D, droneLocation: CLLocation) {
        // Create overlays if needed.
        if flightPlanOverlay == nil {
            createOverlays()
        }
        // Add or update waypoint line.
        let line = AGSPolyline(points: [droneLocation.agsPoint, location.agsPoint])
        if let lineGraphic = flightPlanOverlay?.touchAndFlyWayPointLineGraphic {
            lineGraphic.update(with: line)
        } else {
            let lineGraphic = TouchAndFlyDroneToPointLineGraphic(polyline: line, isWayPoint: true)
            flightPlanOverlay?.graphics.add(lineGraphic)
        }

        let camera = sceneView.currentViewpointCamera()
        // Add or update waypoint.
        if let wayPointGraphic = flightPlanOverlay?.touchAndFlyWayPointGraphic {
            wayPointGraphic.update(with: location.agsPoint)
            wayPointGraphic.update(heading: camera.heading)
        } else {
            let wpGraphic = FlightPlanWayPointGraphic(touchAndFlyLocation: location)
            wpGraphic.update(heading: camera.heading)
            flightPlanOverlay?.graphics.add(wpGraphic)
        }

        updateElevationVisibility()
    }

    /// Displays a point of interest at target location.
    ///
    /// - Parameters:
    ///    - location: point of interest's location
    func displayPoiPoint(at location: Location3D) {
        let currentPoiPoint = flightPlanOverlay?.touchAndFlyPoiPointGraphic?.geometry as? AGSPoint
        guard currentPoiPoint != location.agsPoint else {
            return
        }

        // Create overlays if needed.
        if flightPlanOverlay == nil {
            createOverlays()
        }

        // Add or update point of interest.
        let camera = sceneView.currentViewpointCamera()
        if let poiPointGraphic = flightPlanOverlay?.touchAndFlyPoiPointGraphic {
            poiPointGraphic.update(with: location.agsPoint)
            poiPointGraphic.update(heading: camera.heading)
        } else {
            let poiGraphic = FlightPlanPoiPointGraphic(touchAndFlyLocation: location)
            poiGraphic.update(heading: camera.heading)
            flightPlanOverlay?.graphics.add(poiGraphic)
        }

        updateElevationVisibility()
    }

    /// Removes Touch and Fly graphics from map.
    func clearTouchAndFly() {
        flightPlanOverlay?.clearTouchAndFlyGraphics()
    }
}

// MARK: - Private Funcs
private extension MapViewController {
    /// Creates graphic overlays.
    func createOverlays() {
        // Remove old overlays first.
        removeGraphicOverlay(forKey: Constants.overlayKey)
        // Create new overlays.
        let newOverlay = FlightPlanGraphicsOverlay(graphics: [])
        addGraphicOverlay(newOverlay, forKey: Constants.overlayKey, at: 0)

        getGraphicOverlay(forKey: MapConstants.locationsOverlayKey)?.sceneProperties?.surfacePlacement = .drapedFlat
    }
}
