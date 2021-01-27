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

import CoreLocation
import UIKit

// MARK: - Private Enums
private enum Constants {
    static let earthRadius: Double = 6371000.0
}

/// Utilities to manage location/geometry computations.

final class GeometryUtils {
    // MARK: - Internal Funcs
    /// Computes delta yaw between two locations.
    ///
    /// - Parameters:
    ///    - fromLocation: origin location
    ///    - toLocation: second location
    ///    - withHeading: heading of observer
    /// - Returns: the computed angle, in radians
    static func deltaYaw(fromLocation origin: CLLocationCoordinate2D,
                         toLocation location: CLLocationCoordinate2D,
                         withHeading heading: Double) -> Double {
        let idealYaw = yawToDegrees(yaw(fromLocation: origin, toLocation: location))
        let currentDeltaYaw = idealYaw.toRadians() - wrapToPi(heading)
        return wrapToPi(currentDeltaYaw.toDegrees())
    }

    /// Computes yaw between two locations.
    ///
    /// - Parameters:
    ///    - fromLocation: origin location
    ///    - toLocation: second location
    /// - Returns: the computed angle, in radians
    static func yaw(fromLocation origin: CLLocationCoordinate2D,
                    toLocation location: CLLocationCoordinate2D) -> Double {
        let diffX = wrapToPi(location.latitude - origin.latitude) * Constants.earthRadius
        let diffY = wrapToPi(location.longitude - origin.longitude) * Constants.earthRadius * cos(origin.latitude.toRadians())

        let yaw = atan2(diffY, diffX)
        return yaw < 0.0 ? -yaw : 2.0 * .pi - yaw
    }

    /// Wraps current degree value to [-π, π].
    ///
    /// - Parameters:
    ///    - angle: angle, in degrees.
    /// - Returns: the computed angle, in radians
    static func wrapToPi(_ angle: Double) -> Double {
        let rad = angle.toRadians()
        return rad > .pi ? rad - 2.0 * .pi : rad
    }

    /// Converts current yaw value (radians) to [0, 360].
    ///
    /// - Parameters:
    ///    - yaw: yaw value, in radians
    /// - Returns: the computed yaw, in degrees
    static func yawToDegrees(_ yaw: Double) -> Double {
        return 360.0 - yaw.toDegrees()
    }

    /// Computes and returns angle between two screen points.
    ///
    /// - Parameters:
    ///    - originPoint: the origin point
    ///    - destinationPoint: the destination point
    /// - Returns: computed angle, in degrees
    static func angleBetween(_ originPoint: CGPoint, and destinationPoint: CGPoint) -> CGFloat {
        let diffX = destinationPoint.x - originPoint.x
        let diffY = destinationPoint.y - originPoint.y
        let angle = atan2(diffY, diffX)
        var degrees = angle.toDegrees
        degrees = (degrees > 0.0 ? degrees : 360.0 + degrees)
        return degrees
    }
}
