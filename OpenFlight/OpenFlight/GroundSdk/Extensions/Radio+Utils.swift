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

// MARK: - Internal Enums
/// Enum describing Wifi strength.
enum WifiStrength: Int {
    case offline = -1
    case ko0On4 = 0
    case ok1On4 = 1
    case ok2On4 = 2
    case ok3On4 = 3
    case ok4On4 = 4

    // MARK: - Internal Properties
    /// Returns alert level for current wifi strength.
    var alertLevel: AlertLevel {
        switch self {
        case .offline:
            return .none
        case .ko0On4:
            return .critical
        case .ok1On4,
             .ok2On4:
            return .warning
        case .ok3On4,
             .ok4On4:
            return .ready
        }
    }
}

// MARK: - SignalStrength
extension WifiStrength: SignalStrength {
    var backgroundColor: ColorName {
        switch self {
        case .ok1On4:
            return .disabledWarningColor

        case .ok2On4,
             .ok3On4,
             .ok4On4:
            return .disabledHighlightColor

        default:
            return .clear
        }
    }

    var borderColor: ColorName {
        switch self {

        case .ok1On4:
            return .warningColor

        case .ok2On4,
             .ok3On4,
             .ok4On4:
            return .highlightColor
        default:
            return .clear
        }
    }

    func signalIcon(isLinkActive: Bool = false) -> UIImage {
        switch self {
        case .offline:
            return Asset.Wifi.icWifiOffline.image
        case .ko0On4:
            return isLinkActive
                ? Asset.Wifi.icWifiQuality1.image
                : Asset.Wifi.icWifiOffline.image
        case .ok1On4:
            return isLinkActive
                ? Asset.Wifi.icWifiQuality2.image
                : Asset.Wifi.icWifiOffline.image
        case .ok2On4:
            return isLinkActive
                ? Asset.Wifi.icWifiQuality3.image
                : Asset.Wifi.icWifiOffline.image
        case .ok3On4:
            return isLinkActive
                ? Asset.Wifi.icWifiQuality4.image
                : Asset.Wifi.icWifiOffline.image
        case .ok4On4:
            return isLinkActive
                ? Asset.Wifi.icWifiQuality5.image
                : Asset.Wifi.icWifiOffline.image
        }
    }
}
