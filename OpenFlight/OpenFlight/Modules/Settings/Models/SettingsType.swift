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

import UIKit

/// Describes all settings.
/// Settings screen is split in multiple parts.
/// Each settings is identified by a SettingsType.
public enum SettingsType: Equatable {
    case quick
    case interface
    case controls
    case behaviour
    case geofence
    case rth
    case camera
    case network
    case developer
    case provider(SettingsSection, UIViewController)

    public static func == (lhs: SettingsType, rhs: SettingsType) -> Bool {
        switch (lhs, rhs) {
        case (.quick, .quick),
            (.interface, .interface),
            (.controls, .controls),
            (.behaviour, .behaviour),
            (.geofence, .geofence),
            (.rth, .rth),
            (.camera, .camera),
            (.network, .network),
            (.developer, .developer):
            return true
        case let (.provider(lhsSection, lhsController), .provider(rhsSection, rhsController)):
            return lhsSection == rhsSection && lhsController == rhsController
        default:
            return false
        }
    }
}

// MARK: - Internal functions

extension SettingsType {

    /// Defines default segment.
    static var defaultType: SettingsType {
        return .quick
    }

    /// Defines SettingsSection regarding SettingsType.
    var settingSection: SettingsSection {
        var section: SettingsSection
        switch self {
        case .interface:
            section = SettingsSection(title: L10n.settingsAdvancedCategoryInterface,
                                      icon: Asset.Settings.iconSettingsInterface.image.withRenderingMode(.alwaysTemplate))
        case .controls:
            section = SettingsSection(title: L10n.settingsCategoryControls,
                                      icon: UIImage()) // no image requied
        case .behaviour:
            section = SettingsSection(title: L10n.commonPresets,
                                      icon: Asset.Settings.iconSettingsBehaviour.image.withRenderingMode(.alwaysTemplate))
        case .geofence:
            section = SettingsSection(title: L10n.settingsAdvancedCategoryGeofence,
                                      icon: Asset.Settings.iconSettingsGeofence.image.withRenderingMode(.alwaysTemplate))
        case .rth:
            section = SettingsSection(title: L10n.settingsAdvancedCategoryRth,
                                      icon: Asset.Settings.iconSettingsRth.image.withRenderingMode(.alwaysTemplate))
        case .camera:
            section = SettingsSection(title: L10n.settingsAdvancedCategoryCamera,
                                      icon: Asset.Settings.iconSettingsCamera.image.withRenderingMode(.alwaysTemplate))
        case .network:
            section = SettingsSection(title: L10n.settingsAdvancedCategoryConnection,
                                      icon: Asset.Settings.iconSettingsNetwork.image.withRenderingMode(.alwaysTemplate))
        case .developer:
            section = SettingsSection(title: L10n.settingsAdvancedCategoryDeveloper,
                                      icon: Asset.Settings.iconSettingsDeveloper.image.withRenderingMode(.alwaysTemplate))
        case .quick:
            section = SettingsSection(title: L10n.settingsCategoryQuick,
                                      icon: UIImage()) // no image requied
        case .provider(let settingSection, _):
            section = settingSection
        }
        return section
    }
}

// MARK: - Helpers

/// Helper struct for display.
public struct SettingsSection: Equatable {
    let title: String
    let icon: UIImage

    public init(title: String, icon: UIImage) {
        self.title = title
        self.icon = icon
    }
}
