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

/// Describes all settings panels.
/// Settings screen is split in 3 parts.
/// Each parts is identified by a SettingsPanelType.
enum SettingsPanelType: Int, CaseIterable {
    case quick
    case controls
    case advanced
}

// MARK: - Instance variables
extension SettingsPanelType {

    /// Provides panel index.
    var index: Int {
        return SettingsPanelType.allCases.lastIndex(of: self) ?? 0
    }

    ///  Provides panel name.
    var title: String {
        switch self {
        case .quick:
            return SettingsType.quick.settingSection.title
        case .controls:
            return SettingsType.controls.settingSection.title
        case .advanced:
            return L10n.settingsCategoryAdvanced
        }
    }

    /// Provides default SettingsType (first one).
    var defaultSettings: SettingsType {
        switch self {
        case .quick:
            return .quick
        case .controls:
            return .controls
        case .advanced:
            return .behaviour
        }
    }

    /// Defines SettingsType array regarding panel.
    func getSettingsTypes(from provider: SettingsProvider?) -> [SettingsType] {
        switch self {
        case .quick:
            return [.quick]
        case .controls:
            return [.controls]
        case .advanced:
            var settingsTypes: [SettingsType] = [.behaviour,
                                                 .interface,
                                                 .geofence,
                                                 .rth,
                                                 .camera,
                                                 .network]
            settingsTypes.append(contentsOf: provider?.advancedSettingsTypes ?? [])
            settingsTypes.append(.developer)
            return settingsTypes
        }
    }
}

// MARK: - Helpers

extension SettingsPanelType {

    /// Defines default panel.
    static var defaultPanel: SettingsPanelType {
        return .quick
    }

    /// Gives panel regarding index.
    static func type(at index: Int) -> SettingsPanelType {
        guard index >= 0, index < SettingsPanelType.allCases.count
            else { return SettingsPanelType.defaultPanel }
        return SettingsPanelType.allCases[index]
    }

    /// Gives panel regarding SettingsType.
    static func type(for setting: SettingsType) -> SettingsPanelType {
        switch setting {
        case .quick:
            return .quick
        case .controls:
            return .controls
        default:
            return .advanced
        }
    }
}
