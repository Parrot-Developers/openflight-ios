//    Copyright (C) 2022 Parrot Drones SAS
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
/// Developer preset.
enum DeveloperPreset {
    static let defaultDirectConnection: SettingsDirectConnection = .disabled
    static let defaultShellAccess: SettingsShellAccess = .shellAccessOff
    static let defaultMissionLog: SettingsMissionLog = .missionLogOff
}

/// Model for direct connection setting.
enum SettingsDirectConnection: String, SettingMode, CaseIterable {
    case disabled
    case enabled

    var localized: String {
        switch self {
        case .disabled:
            return L10n.commonNo
        case .enabled:
            return L10n.commonYes
        }
    }

    var key: String {
        return rawValue
    }

    var mode: NetworkDirectConnectionMode {
        switch self {
        case .enabled:
            return .legacy
        default:
            return .secure
        }
    }

    static func from(_ mode: NetworkDirectConnectionMode?) -> SettingsDirectConnection {
        switch mode {
        case .legacy:
            return .enabled
        default:
            return .disabled
        }
    }

    static var allValues: [SettingMode] {
        return SettingsDirectConnection.allCases
    }
}

/// Model for shell access setting.
enum SettingsShellAccess: String, SettingMode, CaseIterable {
    case shellAccessOff
    case shellAccessOn

    static let allValues = SettingsShellAccess.allCases

    var key: String {
        return rawValue
    }

    var localized: String {
        switch self {
        case .shellAccessOn:
            return L10n.commonYes
        case .shellAccessOff:
            return L10n.commonNo
        }
    }

    func toState(publicKey: String?) -> DebugShellState {
        switch self {
        case .shellAccessOn:
            guard let publicKey = publicKey else {
                return .disabled
            }
            return .enabled(publicKey: publicKey)
        case .shellAccessOff:
            return .disabled
        }
    }
}

/// Model for mission logs setting.
enum SettingsMissionLog: String, SettingMode, CaseIterable {
    case missionLogOff
    case missionLogOn

    static let allValues = SettingsMissionLog.allCases

    var key: String {
        return rawValue
    }

    var localized: String {
        switch self {
        case .missionLogOn:
            return L10n.commonYes
        case .missionLogOff:
            return L10n.commonNo
        }
    }
}
