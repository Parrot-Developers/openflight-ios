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

// MARK: - Internal Funcs
/// MapViewController extension for MyFlights.
internal extension MapViewController {
    // MARK: - Private Enums
    private enum Constants {
        static let lineWidth: CGFloat = 3.0
        static let lineColor: UIColor = ColorName.white.color
        static let overlayKey = "myFlightsOverlayKey"
    }

    // MARK: - Internal Funcs
    /// Displays flights trajectories and adjusts map viewpoint to show them.
    ///
    /// - Parameters:
    ///    - flightsPoints: flights trajectories
    ///    - hasAsmlAltitude: `true` if flights points have altitudes in ASML
    func displayFlightCourse(flightsPoints: [[TrajectoryPoint]],
                             hasAsmlAltitude: Bool) {
        removeGraphicOverlay(forKey: Constants.overlayKey)

        guard let firstPoint = flightsPoints.first?.first else { return }

        let customOverlay = AGSGraphicsOverlay()
        customOverlay.sceneProperties?.surfacePlacement = .absolute
        addGraphicOverlay(customOverlay, forKey: Constants.overlayKey, at: 0)

        // add polyline for each flight
        flightsPoints.forEach { flightPoints in
            let agsPoints = flightPoints.map { $0.point }
            let polyline = AGSPolyline(points: agsPoints)
            let polylineSymbol = AGSSimpleLineSymbol(style: .solid, color: Constants.lineColor, width: Constants.lineWidth)
            let polylineGraphic = AGSGraphic(geometry: polyline, symbol: polylineSymbol, attributes: nil)
            customOverlay.graphics.add(polylineGraphic)
        }

        // starting point marker
        if firstPoint.isFirstPoint {
            let homePicture = AGSPictureMarkerSymbol(image: Asset.MyFlights.mapRth.image)
            let homePoint = AGSGraphic(geometry: firstPoint.point, symbol: homePicture, attributes: nil)
            customOverlay.graphics.add(homePoint)
        }

        let allPoints = flightsPoints.reduce([]) { $0 + $1.map {$0.point} }
        let polyline = AGSPolyline(points: allPoints)
        let bufferedExtent = polyline.envelopeWithMargin()
        let viewPoint = AGSViewpoint(targetExtent: bufferedExtent)
        updateViewPoint(viewPoint)

        // wait for elevation data to be ready before applying an altitude offset
        elevationLoadedCancellable = viewModel.elevationSource.$elevationLoaded
            .filter { $0 }
            .removeDuplicates()
            .sink { [unowned self] _ in
                adjustAltitude(overlay: customOverlay,
                               firstPoint: firstPoint.point,
                               hasAsmlAltitude: hasAsmlAltitude)
            }
    }

    /// Applies an altitude offset to graphics overlay to ensure that first point is drawn above the ground.
    ///
    /// If altitudes are in ASML, the overlay offset is applied only if first point in below the map ground.
    /// If altitudes are not in ASML, the overlay offset is always applied to draw the first point on the ground.
    /// This is the case for GUTMA files prior to Parrot version "1.0.1".
    ///
    /// - Parameters:
    ///   - overlay: graphics overlay that handles trajectory display
    ///   - firstPoint: first trajectory point
    ///   - hasAsmlAltitude: `true` if altitudes are in ASML, `false` otherwise
    func adjustAltitude(overlay: AGSGraphicsOverlay, firstPoint: AGSPoint, hasAsmlAltitude: Bool) {
        sceneView.scene?.baseSurface?.elevation(for: firstPoint) { elevation, error in
            guard error == nil else { return }
            let altitudeOffset = elevation - firstPoint.z
            if !hasAsmlAltitude
                || altitudeOffset > 0 {
                overlay.sceneProperties?.altitudeOffset = altitudeOffset
            }
        }
    }
}
