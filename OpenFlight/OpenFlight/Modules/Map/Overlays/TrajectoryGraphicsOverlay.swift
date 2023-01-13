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

import ArcGIS
import GroundSdk
import CoreLocation
import Combine


private extension ULogTag {
    static let tag = ULogTag(name: "TrajectoryGraphicsOverlay")
}

public class TrajectoryGraphicsOverlay: CommonGraphicsOverlay {

    // MARK: - Private Enums
    private enum Constants {
        static let lineWidth: CGFloat = 2.0
        static let lineMediumWidth: CGFloat = 6.0
        static let lineColor: UIColor = ColorName.white.color
        static let overlayKey = "TrajectoryGraphicsOverlayKey"
    }
    
    // MARK: - Public properties
    public var flightsPoints = CurrentValueSubject<[[TrajectoryPoint]]?, Never>(nil)
    public var flightsPointsPublisher: AnyPublisher<[[TrajectoryPoint]]?, Never> { flightsPoints.eraseToAnyPublisher()
    }
    public var hasAmslAltitude = false
    public var adjustViewPoint = false

    // MARK: - Internal Funcs
    /// Displays flights trajectories and adjusts map viewpoint to show them.
    ///
    /// - Parameters:
    ///    - flightsPoints: flights trajectories
    ///    - hasAmslAltitude: `true` if flights points have altitudes in AMSL
    ///    - trajectoryState: the state of the trajectory
    ///    - adjustViewPoint: `true` to adjust map view point to display flights trajectories
    public func displayFlightTrajectories(flightsPoints: [[TrajectoryPoint]],
                                          hasAmslAltitude: Bool,
                                          trajectoryState: TrajectoryState = .none,
                                          adjustViewPoint: Bool) {
        guard let firstPoint = flightsPoints.first?.first else { return }
        sceneProperties?.surfacePlacement = .absolute
        // add polyline for each flight
        flightsPoints.forEach { flightPoints in
            let agsPoints = flightPoints.map { $0.point }
            let polyline = AGSPolyline(points: agsPoints)
            let width = (trajectoryState == .completed || trajectoryState == .interrupted) ? Constants.lineMediumWidth : Constants.lineWidth
            let polylineSymbol = AGSSimpleLineSymbol(style: .solid, color: trajectoryState.color, width: width)
            let polylineGraphic = AGSGraphic(geometry: polyline, symbol: polylineSymbol, attributes: nil)
            graphics.add(polylineGraphic)
        }

        // starting point marker
        if firstPoint.isFirstPoint {
            let homePicture = AGSPictureMarkerSymbol(image: Asset.MyFlights.mapRth.image)
            let homePoint = AGSGraphic(geometry: firstPoint.point, symbol: homePicture, attributes: nil)
            graphics.add(homePoint)
        }

        self.adjustViewPoint = adjustViewPoint
        self.hasAmslAltitude = hasAmslAltitude
        self.flightsPoints.value = flightsPoints
        isActive.value = self.flightsPoints.value != nil
    }
}
