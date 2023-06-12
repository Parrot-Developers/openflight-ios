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

import GroundSdk

// MARK: - Internal enums
enum GeofencePreset {
    static let geofenceMode: GeofenceMode = .cylinder
    static let maxAltitude: Double = 150.0
    static let minAltitude: Double = 1.0
    static let defaultAltitude: Double = 100.0
    static let maxDistance: Double = 4000.0
    static let minDistance: Double = 10.0
    static let defaultDistance: Double = 100.0
}

/// SettingMode protocol helpers to SDK's GeofenceMode.

extension GeofenceMode: SettingMode {

    public var localized: String {
        switch self {
        case .altitude:
            return L10n.commonOff.capitalized
        case .cylinder:
            return L10n.commonOn.capitalized
        }
    }

    public var usedAsBool: Bool {
        return true
    }

    public var isGeofenceActive: Bool {
        return self == .cylinder
    }

    public var key: String {
        return description
    }

    public var image: UIImage? {
        switch self {
        case .altitude:
            return Asset.Settings.Quick.geofenceInactive.image
        case .cylinder:
            return Asset.Settings.Quick.geofenceActive.image
        }
    }

    static var allValues: [SettingMode] {
        return [GeofenceMode.altitude,
                GeofenceMode.cylinder]
    }
}
