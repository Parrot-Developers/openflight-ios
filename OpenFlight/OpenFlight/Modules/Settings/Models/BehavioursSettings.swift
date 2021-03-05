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
import GroundSdk

// MARK: - Protocols

/// This protocol force to have a preset setting.
protocol HasPreset where Self: BarItemMode {
    static var preset: Self { get }
}

// MARK: - Internal Structs
/// Defines behaviours settings preset struct.

struct BehavioursPreset {
    var horizontalSpeed: Double = 0.0
    var horizontalAcceleration: Double = 0.0 // Percentage between 0.01 and 1
    var verticalSpeed: Double = 0.0
    var rotationSpeed: Double = 0.0
    var cameraTilt: Double = 0.0
    var bankedTurn: Bool = false
    var inclinedRoll: Bool = false
}

// MARK: - Internal Enums

/// Settings Behaviours mode presets.
enum SettingsBehavioursMode: String, BarItemMode, HasPreset {
    case video
    case sport

    static var allValues: [BarItemMode] {
        return [SettingsBehavioursMode.video,
                SettingsBehavioursMode.sport]
    }

    var subModes: [BarItemSubMode]? {
        return nil
    }

    static var preset: SettingsBehavioursMode {
        return SettingsBehavioursMode.video
    }

    static var current: SettingsBehavioursMode {
        if let storedPreset = Defaults.userPilotingPreset,
            let mode = SettingsBehavioursMode(rawValue: storedPreset) {
            return mode
        } else {
            return SettingsBehavioursMode.preset
        }
    }

    var title: String {
        switch self {
        case .video:
            return L10n.settingsBehaviourVideo
        case .sport:
            return L10n.settingsBehaviourSport
        }
    }

    var image: UIImage? {
        switch self {
        case .video:
            return Asset.Settings.Advanced.presetFilm.image
        case .sport:
            return Asset.Settings.Advanced.presetSport.image
        }
    }

    var key: String {
        return rawValue
    }

    var maxPitchRollKey: DefaultsKey<Double?> {
        switch self {
        case .video:
            return DefaultsKeys.filmMaxPitchRollKey
        case .sport:
            return DefaultsKeys.sportMaxPitchRollKey
        }
    }

    var maxPitchRollVelocityKey: DefaultsKey<Double?> {
        switch self {
        case .video:
            return DefaultsKeys.filmMaxPitchRollVelocityKey
        case .sport:
            return DefaultsKeys.sportMaxPitchRollVelocityKey
        }
    }

    var maxVerticalSpeedKey: DefaultsKey<Double?> {
        switch self {
        case .video:
            return DefaultsKeys.filmMaxVerticalSpeedKey
        case .sport:
            return DefaultsKeys.sportMaxVerticalSpeedKey
        }
    }

    var maxYawRotationSpeedKey: DefaultsKey<Double?> {
        switch self {
        case .video:
            return DefaultsKeys.filmMaxYawRotationSpeedKey
        case .sport:
            return DefaultsKeys.sportMaxYawRotationSpeedKey
        }
    }

    var bankedTurnModeKey: DefaultsKey<Bool?> {
        switch self {
        case .video:
            return DefaultsKeys.filmBankedTurnModeKey
        case .sport:
            return DefaultsKeys.sportBankedTurnModeKey
        }
    }

    var inclinedRollModeKey: DefaultsKey<Bool?> {
        switch self {
        case .video:
            return DefaultsKeys.filmInclinedRollModeKey
        case .sport:
            return DefaultsKeys.sportInclinedRollModeKey
        }
    }

    var cameraTiltKey: DefaultsKey<Double?> {
        switch self {
        case .video:
            return DefaultsKeys.filmCameraTiltKey
        case .sport:
            return DefaultsKeys.sportCameraTiltKey
        }
    }

    var defaultValues: BehavioursPreset {
        switch self {
        case .video:
            return BehavioursPreset(horizontalSpeed: 10.0,
                                    horizontalAcceleration: 0.15,
                                    verticalSpeed: 1.0,
                                    rotationSpeed: 10.0,
                                    cameraTilt: 10.0,
                                    bankedTurn: true,
                                    inclinedRoll: false)
        case .sport:
            return BehavioursPreset(horizontalSpeed: 25.0,
                                    horizontalAcceleration: 0.2,
                                    verticalSpeed: 2.0,
                                    rotationSpeed: 20.0,
                                    cameraTilt: 20.0,
                                    bankedTurn: false,
                                    inclinedRoll: false)
        }
    }

    var maxRecommandedValues: BehavioursPreset? {
        switch self {
        case .video:
            return BehavioursPreset(horizontalSpeed: 15.0,
                                    horizontalAcceleration: 0.2,
                                    verticalSpeed: 1.5,
                                    rotationSpeed: 15.0,
                                    cameraTilt: 0.0,
                                    bankedTurn: true,
                                    inclinedRoll: false)
        default:
            return nil
        }
    }

    /// Returns recommended `Camera2ExposureMode` for current mode.
    var cameraExposureAutomaticMode: Camera2ExposureMode {
        switch self {
        case .video:
            return .automaticPreferShutterSpeed
        case .sport:
            return .automaticPreferIsoSensitivity
        }
    }

    var logKey: String {
        return LogEvent.LogKeyAdvancedSettings.behavior
    }
}

/// Defines inclined roll settings type.

enum InclinedRoll: String, SettingMode {

    case locked
    case relative

    var localized: String {
        switch self {
        case .locked:
            return L10n.settingsBehaviourCameraStabilizationLocked
        case .relative:
            return L10n.settingsBehaviourCameraStabilizationRelative
        }
    }

    var key: String {
        return rawValue
    }

    var boolValue: Bool {
        switch self {
        case .locked:
            return true
        case .relative:
            return false
        }
    }

    static var allValues: [InclinedRoll] {
        return [InclinedRoll.locked,
                InclinedRoll.relative]
    }

    static func value(from bool: BoolSetting?) -> InclinedRoll {
        switch bool?.value {
        case true?:
            return .locked
        default:
            return .relative
        }
    }

    var title: String {
        return localized
    }
}

/// Defines banked turn settings type.

enum BankedTurn: String, SettingMode {

    case enabled
    case disabled

    var localized: String {
        switch self {
        case .enabled:
            return L10n.commonYes
        case .disabled:
            return L10n.commonNo
        }
    }

    var key: String {
        return rawValue
    }

    var boolValue: Bool {
        switch self {
        case .enabled:
            return true
        case .disabled:
            return false
        }
    }

    static var allValues: [BankedTurn] {
        return [BankedTurn.disabled,
                BankedTurn.enabled]
    }

    static func value(from bool: BoolSetting?) -> BankedTurn {
        switch bool?.value {
        case true?:
            return .enabled
        default:
            return .disabled
        }
    }
}
