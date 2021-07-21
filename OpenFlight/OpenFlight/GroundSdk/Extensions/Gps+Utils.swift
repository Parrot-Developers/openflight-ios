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

import GroundSdk

/// Enum describing Gps strength.

enum GpsStrength {
    case none
    case notFixed
    case fixed1on5
    case fixed2on5
    case fixed3on5
    case fixed4on5
    case fixed5on5

    // MARK: - Internal Properties
    /// Returns an image corresponding to current Gps strength.
    var image: UIImage {
        switch self {
        case .none:
            return Asset.Gps.Drone.icGpsDisabled.image
        case .notFixed:
            return Asset.Gps.Drone.icGpsQuality1.image
        case .fixed1on5:
            return Asset.Gps.Drone.icGpsQuality2.image
        case .fixed2on5:
            return Asset.Gps.Drone.icGpsQuality3.image
        case .fixed3on5:
            return Asset.Gps.Drone.icGpsQuality4.image
        case .fixed4on5:
            return Asset.Gps.Drone.icGpsQuality5.image
        case .fixed5on5:
            return Asset.Gps.Drone.icGpsQuality6.image
        }
    }
}

/// Utility extension for `Gps`.
extension Gps {
    // MARK: - Internal Properties
    /// Returns current Gps strength.
    var gpsStrength: GpsStrength {
        switch (satelliteCount, fixed) {
        case (_, false):
            return .notFixed
        case (..<10, _):
            return .fixed1on5
        case (..<14, _):
            return .fixed2on5
        case (..<18, _):
            return .fixed3on5
        case (..<21, _):
            return .fixed4on5
        default:
            return .fixed5on5
        }
    }
}
