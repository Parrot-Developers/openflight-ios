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

import SwiftyUserDefaults
import ArcGIS

/// Defines settings interface presets.

enum InterfacePreset {
    static let miniMapType = SettingsMapDisplayType.hybrid
    static let secondaryScreenType = SecondaryScreenType.map
    static let measurementSystem = UserMeasurementSetting.auto
}

/// Defines settings map display type.

enum SettingsMapDisplayType: String, SettingEnum, CaseIterable {
    case roadmap
    case satellite
    case hybrid

    static var allValues: [SettingEnum] {
        return SettingsMapDisplayType.allCases
    }

    static var defaultKey: DefaultsKey<String?> {
        return DefaultsKeys.userMiniMapTypeSettingKey
    }

    static var current: SettingsMapDisplayType {
        guard let defaultValue = Defaults.userMiniMapTypeSetting,
            let type = SettingsMapDisplayType(rawValue: defaultValue) else {
                return .hybrid
        }
        return type
    }

    var localized: String {
        switch self {
        case .roadmap:
            return L10n.settingsInterfaceTypeRoadmap
        case .satellite:
            return L10n.settingsInterfaceTypeSatellite
        case .hybrid:
            return L10n.settingsInterfaceTypeHybrid
        }
    }

    /// Returns associated ArcGIS basemap.
    var agsBasemap: AGSBasemap {
        switch self {
        case .roadmap:
            return AGSBasemap.streets()
        case .satellite:
            return AGSBasemap.imagery()
        case .hybrid:
            return AGSBasemap.imageryWithLabels()
        }
    }
}

/// Defines settings for secondary screen type.

enum SecondaryScreenType: String, SettingEnum, CaseIterable {
    case map
    case threeDimensions

    static var allValues: [SettingEnum] {
        return SecondaryScreenType.allCases
    }

    static var current: SecondaryScreenType {
        return SecondaryScreenType.allCases[selectedIndex]
    }

    static var defaultKey: DefaultsKey<String?> {
        return DefaultsKeys.secondaryScreenSettingKey
    }

    var localized: String {
        switch self {
        case .map:
            return L10n.settingsInterfaceSecondaryScreenMap
        case .threeDimensions:
            return L10n.settingsInterfaceSecondaryScreen3dView
        }
    }

    var image: UIImage? {
        switch self {
        case .map:
            return Asset.Settings.Quick.iconMapMinimap.image
        case .threeDimensions:
            return Asset.Settings.Quick.iconView3D.image
        }
    }
}

/// Defines user measurement settings type.

enum UserMeasurementSetting: String, SettingEnum, CaseIterable {
    case auto
    case metric
    case imperial

    static var allValues: [SettingEnum] {
        return UserMeasurementSetting.allCases
    }

    static var defaultKey: DefaultsKey<String?> {
        return DefaultsKeys.userMeasurementSettingKey
    }

    var localized: String {
        switch self {
        case .auto:
            return L10n.settingsInterfaceMeasurementsSystemAuto
        case .metric:
            return L10n.settingsInterfaceMeasurementSystemMetric
        case .imperial:
            return L10n.settingsInterfaceMeasurementSystemImperial
        }
    }
}
