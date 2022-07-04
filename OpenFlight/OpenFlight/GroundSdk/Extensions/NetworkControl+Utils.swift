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
import UIKit

// MARK: - Private Enums
private enum Constants {
    /// Threshold for bad link signal quality.
    static let linkQualityThreshold: Int = 1
}

// MARK: - Protocols
protocol SignalStrength {
    // MARK: - Internal Properties
    /// Returns background color.
    var backgroundColor: ColorName { get }

    /// Returns border color.
    var borderColor: ColorName { get }

    /// Provides the signal icon.
    var signalIcon: UIImage { get }
}

// MARK: - Internal Enums
/// Describes cellular link strength.
enum CellularStrength: Int {
    case offline = -3
    case deactivated = -2
    case ko0On4 = -1
    case ok0On4 = 0
    case ok1On4 = 1
    case ok2On4 = 2
    case ok3On4 = 3
    case ok4On4 = 4
}

// MARK: - SignalStrength
extension CellularStrength: SignalStrength {
    // MARK: - Internal Properties
    var backgroundColor: ColorName {
        switch self {
        case .deactivated,
             .offline,
             .ko0On4:
            return .clear

        case .ok0On4,
             .ok1On4:
            return .disabledWarningColor

        case .ok2On4,
             .ok3On4,
             .ok4On4:
            return .disabledHighlightColor
        }
    }

    var borderColor: ColorName {
        switch self {
        case .deactivated,
             .offline,
             .ko0On4:
            return .clear

        case .ok0On4,
             .ok1On4:
            return .warningColor

        case .ok2On4,
             .ok3On4,
             .ok4On4:
            return .highlightColor
        }
    }

    var signalIcon: UIImage {
        switch self {
        case .deactivated:
            return Asset.Cellular.ic4GDeactivated.image
        case .offline:
            return Asset.Cellular.ic4GOffline.image
        case .ko0On4:
            return Asset.Cellular.ic4GQuality1.image
        case .ok0On4:
            return Asset.Cellular.ic4GQuality0.image
        case .ok1On4:
            return Asset.Cellular.ic4GQuality2.image
        case .ok2On4:
            return Asset.Cellular.ic4GQuality3.image
        case .ok3On4:
            return Asset.Cellular.ic4GQuality4.image
        case .ok4On4:
            return Asset.Cellular.ic4GQuality5.image
        }
    }
}

/// Utility extension for `NetworkControl`.
extension NetworkControl {
    // MARK: - Internal Properties
    /// Returns current Cellular strength.
    var cellularStrength: CellularStrength {
        let quality = links.filter({ $0.type == .cellular }).first?.quality
        return CellularStrength(rawValue: quality ?? CellularStrength.offline.rawValue) ?? .offline
    }

    /// Returns current Wifi strength.
    var wifiStrength: WifiStrength {
        let quality = links.filter({ $0.type == .wlan }).first?.quality
        return WifiStrength(rawValue: quality ?? WifiStrength.offline.rawValue) ?? .offline
    }

    /// Whether the Wifi quality is insufficient.
    var isWifiLowAndPerturbed: Bool {
        guard let quality = linkQuality else { return false }
        return quality <= Constants.linkQualityThreshold &&
        currentLink == .wlan
    }

    // [Banner Alerts] Legacy code is temporarily kept for validation purpose only.
    // TODO: Remove property.
    /// Returns current Wifi errors.
    var currentWifiAlerts: [HUDAlertType] {
        if let quality = linkQuality,
           quality <= Constants.linkQualityThreshold,
           currentLink == .wlan {
            return [HUDBannerWarningAlertType.lowAndPerturbedWifi]
        } else {
            return []
        }
    }
}
