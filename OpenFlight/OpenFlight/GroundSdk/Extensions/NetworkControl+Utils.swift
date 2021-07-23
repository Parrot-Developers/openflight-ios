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
    static let linkQualityThreshold: Int = 1
}

// MARK: - Protocols
protocol SignalStrength {
    // MARK: - Internal Properties
    /// Returns background color.
    var backgroundColor: ColorName { get }

    /// Returns border color.
    var borderColor: ColorName { get }

    // MARK: - Internal Funcs
    /// Provides the signal icon.
    ///
    /// - Parameters:
    ///     - isLinkActive: tells if link is active
    /// - Returns: The signal image with quality.
    func signalIcon(isLinkActive: Bool) -> UIImage
}

// MARK: - Internal Enums
/// Describes cellular link strength.
enum CellularStrength: Int {
    case offline = -2
    case deactivated = -1
    case ko0On4 = 0
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
        case .ok1On4,
             .ok2On4,
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
        case .ok1On4,
             .ok2On4,
             .ok3On4,
             .ok4On4:
            return .highlightColor
        }
    }

    func signalIcon(isLinkActive: Bool = false) -> UIImage {
        switch self {
        case .deactivated:
            return Asset.Cellular.ic4GDeactivated.image
        case .offline:
            return Asset.Cellular.icon4GOffline.image
        case .ko0On4:
            return isLinkActive
                ? Asset.Cellular.ic4GQuality1.image
                : Asset.Cellular.icon4GOffline.image
        case .ok1On4:
            return isLinkActive
                ? Asset.Cellular.ic4GQuality2.image
                : Asset.Cellular.icon4GOffline.image
        case .ok2On4:
            return isLinkActive
                ? Asset.Cellular.ic4GQuality3.image
                : Asset.Cellular.icon4GOffline.image
        case .ok3On4:
            return isLinkActive
                ? Asset.Cellular.ic4GQuality4.image
                : Asset.Cellular.icon4GOffline.image
        case .ok4On4:
            return isLinkActive
                ? Asset.Cellular.ic4GQuality5.image
                : Asset.Cellular.icon4GOffline.image
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
