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

import Foundation
import GroundSdk

// MARK: - Internal Enums
/// Enum describing UserLocation gps strength/state.
enum UserLocationGpsStrength {
    case unavailable
    case gpsKo
    case gpsWeak
    case gpsFixed

    var image: UIImage {
        switch self {
        case .unavailable:
            return Asset.Gps.Controller.icGpsNone.image
        case .gpsKo:
            return Asset.Gps.Controller.icGpsKo.image
        case .gpsWeak:
            return Asset.Gps.Controller.icGpsWeak.image
        case .gpsFixed:
            return Asset.Gps.Controller.icGpsOK.image
        }
    }
}

// MARK: - Private Enums
private enum Constants {
    /// Duration for which a fixed/weak UserLocation is considered as valid.
    static let validityTime: TimeInterval = 15.0
    /// Max horizontal accuracy for which a UserLocation is considered as fixed.
    static let horizontalAccuracyMax: Double = 20.0
}

/// Utility extension for `UserLocation`.
extension UserLocation {
    // MARK: - Internal Properties
    /// Returns current user gps strength.
    var gpsStrength: UserLocationGpsStrength {
        guard authorized else {
            return .unavailable
        }
        guard let location = location else {
            return .gpsKo
        }
        switch (location.horizontalAccuracy, abs(location.timestamp.timeIntervalSinceNow) < Constants.validityTime) {
        case (0...Constants.horizontalAccuracyMax, true):
            return .gpsFixed
        case (Constants.horizontalAccuracyMax..., true):
            return .gpsWeak
        default:
            return .gpsKo
        }
    }

    /// Returns true if gps is currently active.
    /// Either with a fixed or a weak signal.
    public var isGpsActive: Bool {
        let strength = gpsStrength
        switch strength {
        case .gpsWeak, .gpsFixed:
            return true
        case .unavailable, .gpsKo:
            return false
        }
    }

    /// Returns remaining time for which current UserLocation is valid, nil otherwise.
    var remainingFixedTime: TimeInterval? {
        guard let location = location,
            authorized,
            isGpsActive
            else {
                return nil
        }
        return Constants.validityTime - abs(location.timestamp.timeIntervalSinceNow)
    }
}
