//
//  Copyright (C) 2020 Parrot Drones SAS.
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
    /// Displays a line for current flight course and moves the map towards its location.
    ///
    /// - Parameters:
    ///    - viewModel: view model for the flight
    func displayFlightCourse(viewModel: FlightDataViewModel?) {
        removeGraphicOverlay(forKey: Constants.overlayKey)

        let customOverlay = AGSGraphicsOverlay()
        customOverlay.sceneProperties?.surfacePlacement = .drapedFlat
        addGraphicOverlay(customOverlay, forKey: Constants.overlayKey, at: 0)

        guard let flightPoints = viewModel?.gutma?.points,
            let firstPoint = flightPoints.first
            else {
                return
        }
        let polyline = AGSPolyline(points: flightPoints)
        let polylineSymbol = AGSSimpleLineSymbol(style: .solid, color: Constants.lineColor, width: Constants.lineWidth)
        let polylineGraphic = AGSGraphic(geometry: polyline, symbol: polylineSymbol, attributes: nil)
        customOverlay.graphics.add(polylineGraphic)

        let homePicture = AGSPictureMarkerSymbol(image: Asset.MyFlights.mapRth.image)
        let homePoint = AGSGraphic(geometry: firstPoint, symbol: homePicture, attributes: nil)
        customOverlay.graphics.add(homePoint)

        let bufferedExtent = polyline.envelopeWithMargin()
        let viewPoint = AGSViewpoint(targetExtent: bufferedExtent)
        self.updateViewPoint(viewPoint)
    }
}
