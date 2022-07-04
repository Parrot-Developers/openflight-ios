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

import SwiftyUserDefaults
import GroundSdk

/// Defines settings camera presets.

enum CameraPreset {
    static let autoRecord: Camera2AutoRecordMode = .recordFlight
    static let velocityQuality: Camera2ZoomVelocityControlQualityMode = .allowDegrading
    static let antiflickerMode: AntiflickerMode = .off
    static let overexposure = SettingsOverexposure.preset
    static let videoencoding: Camera2VideoCodec = .h265
    static let dynamicHdrRange: Camera2DynamicRange = .hdr10
    static let startAudio: Camera2AudioRecordingMode = .drone
    static let photoSignature: Camera2DigitalSignature = .none
}

/// SDK's AntiflickerMode helpers as SettingMode.

extension AntiflickerMode: SettingMode {

    var localized: String {
        switch self {
        case .off:
            return L10n.commonOff
        case .auto:
            return L10n.settingsCameraAntiFlickeringAuto
        case .mode50Hz:
            return L10n.settingsCameraAntiFlickeringHz50
        case .mode60Hz:
            return L10n.settingsCameraAntiFlickeringHz60
        }
    }

    var key: String {
        return description
    }

    static var allValues: [SettingMode] {
        return [AntiflickerMode.off,
                AntiflickerMode.auto,
                AntiflickerMode.mode50Hz,
                AntiflickerMode.mode60Hz]
    }
}

/// `Camera2ZoomVelocityControlQualityMode` extension for Settings.
extension Camera2ZoomVelocityControlQualityMode: SettingMode {
    var localized: String {
        switch self {
        case .allowDegrading:
            return L10n.commonNo
        case .stopBeforeDegrading:
            return L10n.commonYes
        }
    }

    var key: String {
        return description
    }

    static var allValues: [SettingMode] {
        return [Camera2ZoomVelocityControlQualityMode.allowDegrading,
                Camera2ZoomVelocityControlQualityMode.stopBeforeDegrading]
    }

    var image: UIImage? {
        switch self {
        case .allowDegrading:
            return Asset.Settings.Quick.losslessZoomInactive.image
        case .stopBeforeDegrading:
            return Asset.Settings.Quick.losslessZoomActive.image
        }
    }

    var usedAsBool: Bool {
        return true
    }
}

/// `Camera2AutoRecordMode` extension for Settings.
extension Camera2AutoRecordMode: SettingMode {
    var localized: String {
        switch self {
        case .disabled:
            return L10n.commonNo
        case .recordFlight:
            return L10n.commonYes
        }
    }

    var key: String {
        return description
    }

    static var allValues: [SettingMode] {
        return [Camera2AutoRecordMode.disabled,
                Camera2AutoRecordMode.recordFlight]
    }

    var image: UIImage? {
        switch self {
        case .disabled:
            return Asset.Settings.Quick.autorecordInactive.image
        case .recordFlight:
            return Asset.Settings.Quick.autorecordActive.image
        }
    }

    var usedAsBool: Bool {
        return true
    }
}

/// Defines settings Overexposure type.

enum SettingsOverexposure: String, SettingEnum {
    case noOverexposure
    case yes

    static var allValues: [SettingEnum] {
        return [SettingsOverexposure.noOverexposure,
                SettingsOverexposure.yes]
    }

    static var current: SettingsOverexposure {
        return allValues[selectedIndex] as? SettingsOverexposure ?? .preset
    }

    static var defaultKey: DefaultsKey<String?> {
        return DefaultsKeys.overexposureSettingKey
    }

    var localized: String {
        switch self {
        case .noOverexposure:
            return L10n.commonNo
        case .yes:
            return L10n.commonYes
        }
    }

    var boolValue: Bool {
        switch self {
        case .noOverexposure:
            return false
        case .yes:
            return true
        }
    }

    static var preset: SettingsOverexposure {
        return SettingsOverexposure.noOverexposure
    }
}

/// `Camera2AudioRecordingMode` extension for Settings.
extension Camera2AudioRecordingMode: SettingMode {
    var localized: String {
        switch self {
        case .mute:
            return L10n.settingsQuickAudioOff
        case .drone:
            return L10n.settingsQuickAudioOn
        }
    }

    var key: String {
        return description
    }

    static var allValues: [SettingMode] {
        return [Camera2AudioRecordingMode.mute,
                Camera2AudioRecordingMode.drone]
    }

    var image: UIImage? {
        switch self {
        case .mute:
            return Asset.Settings.Quick.icStopAudio.image
        case .drone:
            return Asset.Settings.Quick.icStartAudio.image
        }
    }

    var usedAsBool: Bool {
        return true
    }
}

/// Defines settings video encoding mode.
/// `Camera2VideoCodec` extension for Settings.
extension Camera2VideoCodec: SettingMode {
    var localized: String {
        switch self {
        case .h264:
            return L10n.settingsCameraH264
        case .h265:
            return L10n.settingsCameraH265
        }
    }

    var key: String {
        return description
    }

    static var allValues: [SettingMode] {
        return [Camera2VideoCodec.h264,
                Camera2VideoCodec.h265]
    }
}

/// Defines settings video HDR mode.
/// `Camera2DynamicRange` extension for Settings.
extension Camera2DynamicRange: SettingMode {
    var localized: String {
        switch self {
        case .hdr8:
            return L10n.settingsCameraHdr8
        case .hdr10:
            return L10n.settingsCameraHdr10
        default:
            return ""
        }
    }

    static var usedValues: [SettingMode] {
        return [Camera2DynamicRange.hdr8,
                Camera2DynamicRange.hdr10]
    }
}

/// Defines settings photo signature.
/// `Camera2DigitalSignature` extension for Settings.
extension Camera2DigitalSignature: SettingMode {
    var localized: String {
        switch self {
        case .none:
            return L10n.commonNo
        case .drone:
            return L10n.commonYes
        }
    }

    var key: String {
        return description
    }

    static var allValues: [SettingMode] {
        return [Camera2DigitalSignature.none,
                Camera2DigitalSignature.drone]
    }
}
