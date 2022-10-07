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

private extension ULogTag {
    static let tag = ULogTag(name: "RthGraphicsOverlay")
}

/// Graphics overlay for Flight Plan.
public final class RthGraphicsOverlay: AGSGraphicsOverlay {

    // MARK: - Private Enums
    private enum Constants {
        static let defaultColor: UIColor = ColorName.blueDodger.color
        static let lineWidth: CGFloat = 2.0
    }

    private var initialLocation: CLLocationCoordinate2D
    private var initialDistance: Double
    private var computedAltitude: Double

    /// Graphic for the polyline of the drone trajectory.
    private var droneToPointLineGraphic: AGSGraphic?
    /// Graphic for the home point.
    private var homePointGraphic: HomePointGraphic?

    // MARK: init

    /// Constructor.
    ///
    /// - Parameters:
    ///    - droneLocation: location of the drone
    ///    - homeLocation: location of the home point
    ///    - minAltitude: minimum RTH altitude
    init(droneLocation: Location3D, homeLocation: CLLocationCoordinate2D, minAltitude: Double) {
        // Remember the initial distance and location for this RTH session.
        initialDistance = homeLocation.distance(from: droneLocation.coordinate)
        initialLocation = droneLocation.coordinate
        // Compute the reference altitude that will be used for the drone trajectory.
        // If initial distance is more than 100m, use the RTH altitude setting.
        // Between 10 and 100m, use distance/2 if it is below the RTH altitude setting.
        // if the drone is closer than 10m, use 5m.
        computedAltitude = droneLocation.altitude
        switch initialDistance {
        case 100...:
            computedAltitude = minAltitude
        case 10..<100:
            computedAltitude = min(minAltitude, initialDistance/2.0)
        default:
            computedAltitude = 5
        }
        ULog.d(.tag,
            """
            Starting RTH.
            Initial Location: (lat: \(initialLocation.latitude), long: \(initialLocation.longitude)),
            Home Location: (lat: \(homeLocation.latitude), long: \(homeLocation.longitude)),
            Initial distance: \(initialDistance),
            Altitude Settings: \(minAltitude),
            computedAltitude: \(computedAltitude)
            """)
        super.init()
    }

    /// Updates the graphics or the RTH overlay.
    ///
    /// - Parameters:
    ///    - homeLocation: location of the home point
    ///    - droneLocation: location of the drone
    func update(homeLocation: Location3D, droneLocation: Location3D) {
        // Update drone to home line.
        // In 3D, the line is made of 2 or 3 segments.
        // The drone moves vertically to the RTH altitude, then horizontally to home,
        // then down to hovering or landing.
        var minAltitude = computedAltitude
        var points = [droneLocation.agsPoint]
        let homeDistance  = homeLocation.coordinate.distance(from: droneLocation.coordinate)
        if homeDistance > 3 {
            // If the drone is not over the home point, add segments.
            if droneLocation.altitude < computedAltitude {
                // If the drone is too low, it first reaches the min RTH altitude.
                let firstAltitudePoint = droneLocation.agsPoint.withAltitude(minAltitude)
                points.append(firstAltitudePoint)
            } else {
                // if the drone is higher than minAltitude,
                // it will move horizontally at the same altitude to the home location.
                minAltitude = droneLocation.altitude
            }
            let secondAltitudePoint = homeLocation.agsPoint.withAltitude(minAltitude)
            points.append(secondAltitudePoint)
            ULog.d(.tag, "trajectory altitude: \(minAltitude), drone altitude: \(droneLocation.altitude)")
        }
        if homeDistance > 3 || droneLocation.altitude > 3 {
            // Only display trajectory if the drone is more than 5m away.
            points.append(homeLocation.agsPoint)
        }
        let line = AGSPolyline(points: points)
        if let lineGraphics = droneToPointLineGraphic {
            lineGraphics.geometry = line
        } else {
            let symbol = AGSSimpleLineSymbol(style: .dot,
                                             color: Constants.defaultColor,
                                             width: Constants.lineWidth)
            let lineGraphics = AGSGraphic(geometry: line, symbol: symbol)
            graphics.add(lineGraphics)
            droneToPointLineGraphic = lineGraphics
        }

        // Display the home icon.
        if let homePointGraphic = homePointGraphic {
            homePointGraphic.geometry = homeLocation.agsPoint
        } else {
            let homePointGraphic = HomePointGraphic(homeLocation: homeLocation.agsPoint)
            graphics.add(homePointGraphic)
            self.homePointGraphic = homePointGraphic
        }
    }

    /// Clears the vehicle tracking overlay.
    func clearGraphics() {
        graphics.removeAllObjects()
        droneToPointLineGraphic = nil
        homePointGraphic = nil
    }
}
