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

import Foundation
import GroundSdk

// MARK: - Internal Enums
enum SettingsNetworkPreset {
    static let defaultWifiRange: SettingsWifiRange = .auto
    static let defaultDriMode: Bool = true
}

/// Setting network model.
enum SettingsWifiRange: String, SettingMode, CaseIterable {
    case manual
    case auto

    static let allValues = SettingsWifiRange.allCases

    var key: String {
        return rawValue
    }

    var localized: String {
        switch self {
        case .auto:
            return L10n.commonAuto
        case .manual:
            return L10n.commonManual
        }
    }
}

/// Model for cellular availability setting.
enum SettingsCellularAvailability: String, SettingMode, CaseIterable {
    case cellularOff
    case cellularOn

    var localized: String {
        switch self {
        case .cellularOff:
            return L10n.commonOff.capitalized
        case .cellularOn:
            return L10n.commonOn.capitalized
        }
    }

    var key: String {
        return rawValue
    }

    static var allValues: [SettingMode] {
        return SettingsCellularAvailability.allCases
    }
}

/// Model for cellular selection setting.
enum SettingsCellularSelection: String, SettingMode, CaseIterable {
    case manual
    case auto

    var localized: String {
        switch self {
        case .auto:
            return L10n.commonAuto.capitalized
        case .manual:
            return L10n.commonManual.capitalized
        }
    }

    var key: String {
        return rawValue
    }

    static var allValues: [SettingMode] {
        return SettingsCellularSelection.allCases
    }
}

/// Setting related to broadcast DRI.
enum BroadcastDRISettings: String, SettingMode, CaseIterable {
    case driOff
    case driOn

    static let allValues = BroadcastDRISettings.allCases

    var key: String {
        return rawValue
    }

    var localized: String {
        switch self {
        case .driOn:
            return L10n.commonYes
        case .driOff:
            return L10n.commonNo
        }
    }
}

// MARK: - Cellular
/// Utility extension used for cellular availability in settings.
extension Cellular {
    /// Returns current cellular availability state.
    var cellularAvailability: SettingsCellularAvailability {
        switch mode.value {
        case .data:
            return .cellularOn
        default:
            return .cellularOff
        }
    }
}

// MARK: - NetworkControlRoutingPolicy
/// NetworkControlRoutingPolicy mode extension for network priority. It can be auto, wifi or 4G.
extension NetworkControlRoutingPolicy: SettingMode {
    var localized: String {
        switch self {
        case .cellular:
            return L10n.settingsConnection4gLabel
        case .wlan:
            return L10n.settingsConnectionWifiLabel
        case .automatic:
            return L10n.commonAuto
        default:
            return ""
        }
    }

    var key: String {
        return description
    }

    static var allValues: [SettingMode] {
        return [NetworkControlRoutingPolicy.cellular,
                NetworkControlRoutingPolicy.wlan,
                NetworkControlRoutingPolicy.automatic]
    }
}
