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
import ArcGIS
import GroundSdk

// MARK: - Internal Funcs
/// MapViewController extension for MyFlights.
internal extension MapViewController {
    // MARK: - Private Enums
    private enum Constants {
        static let lineWidth: CGFloat = 2.0
        static let lineMediumWidth: CGFloat = 6.0
        static let lineColor: UIColor = ColorName.white.color
        static let overlayKey = "myFlightsOverlayKey"
    }

    // MARK: - Internal Funcs
    /// Displays flights trajectories and adjusts map viewpoint to show them.
    ///
    /// - Parameters:
    ///    - flightsPoints: flights trajectories
    ///    - hasAsmlAltitude: `true` if flights points have altitudes in ASML
    ///    - trajectoryState: the state of the trajectory
    ///    - adjustViewPoint: `true` to adjust map view point to display flights trajectories
    func displayFlightTrajectories(flightsPoints: [[TrajectoryPoint]],
                                   hasAsmlAltitude: Bool,
                                   trajectoryState: TrajectoryState = .none,
                                   adjustViewPoint: Bool) {
        removeGraphicOverlay(forKey: Constants.overlayKey)

        guard let firstPoint = flightsPoints.first?.first else { return }

        let customOverlay = AGSGraphicsOverlay()
        customOverlay.sceneProperties?.surfacePlacement = .absolute
        addGraphicOverlay(customOverlay, forKey: Constants.overlayKey, at: 0)

        // add polyline for each flight
        flightsPoints.forEach { flightPoints in
            let agsPoints = flightPoints.map { $0.point }
            let polyline = AGSPolyline(points: agsPoints)
            let width = (trajectoryState == .completed || trajectoryState == .interrupted) ? Constants.lineMediumWidth : Constants.lineWidth
            let polylineSymbol = AGSSimpleLineSymbol(style: .solid, color: trajectoryState.color, width: width)
            let polylineGraphic = AGSGraphic(geometry: polyline, symbol: polylineSymbol, attributes: nil)
            customOverlay.graphics.add(polylineGraphic)
        }

        // starting point marker
        if firstPoint.isFirstPoint {
            let homePicture = AGSPictureMarkerSymbol(image: Asset.MyFlights.mapRth.image)
            let homePoint = AGSGraphic(geometry: firstPoint.point, symbol: homePicture, attributes: nil)
            customOverlay.graphics.add(homePoint)
        }

        if adjustViewPoint {
            setViewPoint(for: flightsPoints)
        }

        // apply an altitude offset and update the map view point,
        // and do it again once map elevation data are loaded;
        // the cancellable is stored in a dedicated variable in order to cancel any pending adjustments
        elevationLoadedCancellable = viewModel.elevationSource.$elevationLoaded
            .prepend(true)
            .filter { $0 }
            .sink { [unowned self] _ in
                adjustAltitudeAndViewPoint(overlay: customOverlay,
                                           flightsPoints: flightsPoints,
                                           hasAsmlAltitude: hasAsmlAltitude,
                                           adjustViewPoint: adjustViewPoint)
            }
    }

    /// Applies an altitude offset to graphics overlay to ensure that first point is drawn above the ground and ajdusts map view point.
    ///
    /// If altitudes are in ASML, the overlay offset is applied only if first point in below the map ground.
    /// If altitudes are not in ASML, the overlay offset is always applied to draw the first point on the ground.
    /// This is the case for GUTMA files prior to Parrot version "1.0.1".
    ///
    /// - Parameters:
    ///    - overlay: graphics overlay that handles trajectory display
    ///    - flightsPoints: flights trajectories
    ///    - hasAsmlAltitude: `true` if altitudes are in ASML, `false` otherwise
    ///    - adjustViewPoint: `true` to adjust map view point to display flights trajectories
    func adjustAltitudeAndViewPoint(overlay: AGSGraphicsOverlay,
                                    flightsPoints: [[TrajectoryPoint]],
                                    hasAsmlAltitude: Bool,
                                    adjustViewPoint: Bool) {
        guard let firstPoint = flightsPoints.first?.first?.point else { return }

        ULog.d(.mapViewController, "Get elevation for flight at: \(firstPoint.x),\(firstPoint.y)")
        myFlightAlttudeRequest?.cancel()
        myFlightAlttudeRequest = nil
        myFlightAlttudeRequest = sceneView.scene?.baseSurface?.elevation(for: firstPoint) { [weak self] elevation, error in
            guard let self = self else { return }
            self.myFlightAlttudeRequest = nil
            guard error == nil else {
                ULog.w(.mapViewController, "Failed to get elevation for flight: \(error.debugDescription)")
                return
            }
            var altitudeOffset = elevation - firstPoint.z
            if !hasAsmlAltitude
                || altitudeOffset > 0 {
                ULog.d(.mapViewController, "Apply altitude offset to flight overlay: \(altitudeOffset)")
                overlay.sceneProperties?.altitudeOffset = altitudeOffset
            } else {
                altitudeOffset = 0
            }
            if adjustViewPoint {
                self.setViewPoint(for: flightsPoints, altitudeOffset: altitudeOffset)
            }
        }
    }

    /// Adjusts map view point to view trajectories points.
    ///
    /// - Parameters:
    ///    - for: trajectories points to display
    ///    - altitudeOffset: altitude offset to apply to trajectory points to compute zoom level
    func setViewPoint(for flightsPoints: [[TrajectoryPoint]], altitudeOffset: Double? = nil) {
        ULog.d(.mapViewController, "Set view point for flight, altitudeOffset \(altitudeOffset?.description ?? "nil")")
        let allPoints = flightsPoints.reduce([]) { $0 + $1.map {$0.point} }
        let polyline = AGSPolyline(points: allPoints)
        let bufferedExtent = polyline.envelopeWithMargin(altitudeOffset: altitudeOffset)
        let viewPoint = AGSViewpoint(targetExtent: bufferedExtent)
        updateViewPoint(viewPoint)
    }
}
