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

import GroundSdk

// MARK: - Private Enums
private enum Constants {
    /// Threshold for bad link signal quality.
    static let linkSignalQualityThreshold: Int = 1
}

/// Enum describing Wifi strength.
enum WifiStrength: Int {
    case none = -1
    case ko0On4 = 0
    case ok1On4 = 1
    case ok2On4 = 2
    case ok3On4 = 3
    case ok4On4 = 4

    // MARK: - Internal Properties
    /// Returns an image corresponding to current Wifi strength.
    var image: UIImage {
        switch self {
        case .none, .ko0On4:
            return Asset.Wifi.icWifi04.image
        case .ok1On4:
            return Asset.Wifi.icWifi14.image
        case .ok2On4:
            return Asset.Wifi.icWifi24.image
        case .ok3On4:
            return Asset.Wifi.icWifi34.image
        case .ok4On4:
            return Asset.Wifi.icWifi44.image
        }
    }

    /// Returns alert level for current wifi strength.
    var alertLevel: AlertLevel {
        switch self {
        case .none:
            return .none
        case .ko0On4:
            return .critical
        case .ok1On4, .ok2On4:
            return .warning
        case .ok3On4, .ok4On4:
            return .ready
        }
    }
}

/// Utility extension for `Radio`.

extension Radio {
    // MARK: - Internal Properties
    /// Returns current Wifi strength.
    var wifiStrength: WifiStrength {
        return WifiStrength(rawValue: linkSignalQuality ?? WifiStrength.none.rawValue) ?? .none
    }

    /// Returns current Wifi errors.
    var currentAlerts: [HUDAlertType] {
        if let quality = linkSignalQuality, quality <= Constants.linkSignalQualityThreshold {
            return [HUDBannerWarningAlertType.lowAndPerturbedWifi]
        } else {
            return []
        }
    }
}
