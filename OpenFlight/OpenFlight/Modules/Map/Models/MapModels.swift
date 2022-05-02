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
import CoreLocation

// MARK: - Public Enums
/// Mode for `MapViewController`
public enum MapMode: Equatable {
    case standard
    case droneDetails
    case myFlights
    case flightPlan
    case flightPlanEdition
    case mapOnly

    /// Color for map selected items.
    var selectionColor: UIColor {
        return .clear
    }

    /// Returns true if mode is used for HUD.
    var isHudMode: Bool {
        switch self {
        case .droneDetails, .myFlights, .mapOnly:
            return false
        default:
            return true
        }
    }
}

extension MapMode {
    var isAllowingPitch: Bool {
        switch self {
        case .flightPlanEdition:
            return false
        default:
            return true
        }
    }

    /// Whether user and drone locations display is enabled in this mode.
    var userAndDroneLocationsEnabled: Bool {
        switch self {
        case .mapOnly, .myFlights:
            return false
        default:
            return true
        }
    }

    /// Whether auto scroll on user or drone location is supported in this mode.
    var autoScrollSupported: Bool {
        switch self {
        case .flightPlanEdition:
            return false
        default:
            return true
        }
    }
}

/// State for center location.
public enum MapCenterState {
    case drone
    case user
    case project
    case none

    /// Image for center button.
    var image: UIImage? {
        switch self {
        case .drone:
            return Asset.Map.centerOnDrone.image
        case .user, .project:
            return Asset.Map.centerOnUser.image
        case .none:
            return nil
        }
    }
}

// MARK: - Public Structs
/// Represents a location with a specific heading.
public struct OrientedLocation: Equatable {
    /// Coordinates of the location.
    public var coordinates: Location3D?
    /// Heading of the location.
    public var heading: CLLocationDirection = 0.0

    /// Returns true if current coordinates are valid.
    public var isValid: Bool {
        guard let coordinates = coordinates,
              CLLocationCoordinate2DIsValid(coordinates.coordinate)
            else {
                return false
        }
        return true
    }

    /// Returns coordinates only if they are valid.
    public var validCoordinates: Location3D? {
        return isValid ? coordinates : nil
    }
}
