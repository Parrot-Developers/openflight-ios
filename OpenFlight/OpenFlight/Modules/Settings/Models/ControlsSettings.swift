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
import GroundSdk

/// Piloting presets.

public enum PilotingPreset {
    public static let thrownTakeOff = true
}

/// Piloting style settings control modes.

public enum ControlsSettingsMode {
    /// !isSpecialMode && !jogsInversed
    case mode1
    /// !isSpecialMode && jogsInversed
    case mode1Inversed
    /// isSpecialMode && !jogsInversed
    case mode2
    /// isSpecialMode && jogsInversed
    case mode2Inversed
}

/// ControlsSettingsMode model helpers.

extension ControlsSettingsMode: Equatable {
    init?(value: String) {
        switch value {
        case "mode1":
            self = .mode1
        case "mode1Inversed":
            self = .mode1Inversed
        case "mode2":
            self = .mode2
        case "mode2Inversed":
            self = .mode2Inversed
        default:
            return nil
        }
    }

    static var defaultMode: ControlsSettingsMode {
        return .mode2
    }

    var value: String {
        switch self {
        case .mode1:
            return "mode1"
        case .mode1Inversed:
            return "mode1Inversed"
        case .mode2:
            return "mode2"
        case .mode2Inversed:
            return "mode2Inversed"
        }
    }

    func getJoystickImage(isRegularSizeClass: Bool = false) -> UIImage {
        switch self {
        case .mode1:
            return isRegularSizeClass
                ? Asset.Settings.Controls.iPadControlMode1.image
                : Asset.Settings.Controls.iphoneControlMode1.image
        case .mode1Inversed:
            return isRegularSizeClass
                ? Asset.Settings.Controls.ipadControlMode1Inversed.image
                : Asset.Settings.Controls.iphoneControlMode1Inversed.image
        case .mode2:
            return isRegularSizeClass
                ? Asset.Settings.Controls.iPadControlMode2.image
                : Asset.Settings.Controls.iphoneControlMode2.image
        case .mode2Inversed:
            return isRegularSizeClass
                ? Asset.Settings.Controls.iPadControlMode2Inversed.image
                : Asset.Settings.Controls.iphoneControlMode2Inversed.image
        }
    }

    var isJogsInversed: Bool {
        switch self {
        case .mode1, .mode2:
            return false
        case .mode1Inversed, .mode2Inversed:
            return true
        }
    }

    var isSpecialMode: Bool {
        switch self {
        case .mode1, .mode1Inversed:
            return false
        case .mode2, .mode2Inversed:
            return true
        }
    }

    var leftJoystickText: String {
        switch self {
        case .mode1:
            return L10n.settingsControlsMappingAccelerationRotation
        case .mode1Inversed:
            return L10n.settingsControlsMappingElevationLateral
        case .mode2:
            return L10n.settingsControlsMappingElevationRotation
        case .mode2Inversed:
            return L10n.settingsControlsMappingDirections
        }
    }

    var rightJoystickText: String {
        switch self {
        case .mode1:
            return L10n.settingsControlsMappingElevationLateral
        case .mode1Inversed:
            return L10n.settingsControlsMappingAccelerationRotation
        case .mode2:
            return L10n.settingsControlsMappingDirections
        case .mode2Inversed:
            return L10n.settingsControlsMappingElevationRotation
        }
    }

    var controllerCameraText: String {
        return L10n.settingsControlsMappingCamera
    }
}
