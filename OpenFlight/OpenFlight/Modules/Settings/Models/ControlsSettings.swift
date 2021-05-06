// Copyright (C) 2020 Parrot Drones SAS
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
    static let controlMode = ControlsSettingsMode.defaultMode
    public static let thrownTakeOff = true
}

/// Piloting style settings control modes.

enum ControlsSettingsMode {
    /// !isSpecialMode && jogsInversed
    case mode1(PilotingStyle)
    /// !isSpecialMode && !jogsInversed
    case mode2(PilotingStyle)
    /// isSpecialMode && jogsInversed
    case mode3(PilotingStyle)
    /// isSpecialMode && !jogsInversed
    case mode4(PilotingStyle)
}

/// ControlsSettingsMode model helpers.

extension ControlsSettingsMode: Equatable {
    init?(value: String, mode: PilotingStyle = ControlsSettingsMode.defaultPilotingMode) {
        switch value {
        case "mode1":
            self = .mode1(mode)
        case "mode2":
            self = .mode2(mode)
        case "mode3":
            self = .mode3(mode)
        case "mode4":
            self = .mode4(mode)
        default:
            return nil
        }
    }

    static var defaultMode: ControlsSettingsMode {
        return .mode2(ControlsSettingsMode.defaultPilotingMode)
    }

    static func defaultMode(for type: PilotingStyle) -> ControlsSettingsMode {
        return .mode2(type)
    }

    static var defaultPilotingMode: PilotingStyle {
        return .classical
    }

    var pilotingStyle: PilotingStyle {
        switch self {
        case let .mode1(mode),
             let .mode2(mode),
             let .mode3(mode),
             let .mode4(mode):
            return mode
        }
    }

    var value: String {
        switch self {
        case .mode1:
            return "mode1"
        case .mode2:
            return "mode2"
        case .mode3:
            return "mode3"
        case .mode4:
            return "mode4"
        }
    }

    var joystickImage: UIImage {
        switch self {
        case .mode1:
            return Asset.Settings.Controls.controlMode1.image
        case .mode2:
            return Asset.Settings.Controls.controlMode2.image
        case .mode3:
            return Asset.Settings.Controls.controlMode3.image
        case .mode4:
            return Asset.Settings.Controls.controlMode4.image
        }
    }

    var jogsInversed: Bool {
        switch self {
        case .mode1:
            return false
        case .mode2:
            return false
        case .mode3:
            return true
        case .mode4:
            return true
        }
    }

    var isSpecialMode: Bool {
        switch self {
        case .mode1:
            return true
        case .mode2:
            return false
        case .mode3:
            return false
        case .mode4:
            return true
        }
    }

    var controllerLeftJoystickText: String {
        switch self {
        case let .mode1(mode):
            if mode == .classical {
                return L10n.settingsControlsMappingAccelerationRotation
            } else {
                return L10n.settingsControlsMappingAccelerationRotation
            }
        case let .mode2(mode):
            if mode == .classical {
                return L10n.settingsControlsMappingElevationRotation
            } else {
                return L10n.settingsControlsMappingCameraRotation
            }
        case .mode3:
            return L10n.settingsControlsMappingDirections
        case let .mode4(mode):
            if mode == .classical {
                return L10n.settingsControlsMappingElevationLateral
            } else {
                return L10n.settingsControlsMappingCameraLateral
            }
        }
    }

    var controllerRightJoystickText: String {
        switch self {
        case let .mode1(mode):
            if mode == .classical {
                return L10n.settingsControlsMappingElevationLateral
            } else {
                return L10n.settingsControlsMappingCameraLateral
            }
        case let .mode2(mode):
            if mode == .classical {
                return L10n.settingsControlsMappingDirections
            } else {
                return L10n.settingsControlsMappingDirections
            }
        case let .mode3(mode):
            if mode == .classical {
                return L10n.settingsControlsMappingElevationRotation
            } else {
                return L10n.settingsControlsMappingCameraRotation
            }
        case let .mode4(mode):
            if mode == .classical {
                return L10n.settingsControlsMappingAccelerationRotation
            } else {
                return L10n.settingsControlsMappingAccelerationRotation
            }
        }
    }

    var hudLeftJoystickText: String {
        switch self {
        case .mode1:
            return L10n.settingsControlsMappingAccelerationRotation
        case .mode2:
            return L10n.settingsControlsMappingElevationRotation
        case .mode3:
            return L10n.settingsControlsMappingDirections
        case .mode4:
            return L10n.settingsControlsMappingElevationLateral
        }
    }

    var hudRightJoystickText: String {
        switch self {
        case .mode1:
            return L10n.settingsControlsMappingElevationLateral
        case .mode2:
            return L10n.settingsControlsMappingDirections
        case .mode3:
            return L10n.settingsControlsMappingElevationRotation
        case .mode4:
            return L10n.settingsControlsMappingAccelerationRotation
        }
    }

    var controllerCameraText: String {
        switch self {
        case let .mode1(mode),
             let .mode2(mode),
             let .mode3(mode),
             let .mode4(mode):
            if mode == .arcade {
                return L10n.settingsControlsMappingElevation
            } else {
                return L10n.settingsControlsMappingCamera
            }
        }
    }
}

/// Piloting style settings modes.

enum PilotingStyle: String, SettingMode, BarItemMode {
    case classical
    case arcade

    var localized: String {
        return title.uppercased()
    }

    var key: String {
        return rawValue
    }

    var isAvailable: Bool {
        return true
    }

    var allValues: [BarItemMode] {
        return [PilotingStyle.classical,
                PilotingStyle.arcade]
    }

    var title: String {
        switch self {
        case .classical:
            return L10n.settingsControlsPilotingStyleClassic
        case .arcade:
            return L10n.settingsControlsPilotingStyleArcade
        }
    }

    static var allValues: [BarItemMode] {
        return [PilotingStyle.classical, PilotingStyle.classical]
    }

    var subModes: [BarItemSubMode]? {
        return nil
    }

    // TODO: Waiting for spec.
    var logKey: String {
        return ""
    }
}

/// Arcade unavailability issues defines why arcade mode cannot be activated.

enum ArcadeUnavailabilityIssues {
    case remoteDisconnected
    case droneDisconnected
    case droneLanded
    case droneTakingOff
    case droneLanding
    case rthInProgress

    var unavailabilityHelpText: String? {
        switch self {
        case .remoteDisconnected:
            return L10n.settingsControlsArcadeHelpRemoteNeeded
        case .droneLanded:
            return L10n.settingsControlsArcadeHelpTakeoffNeeded
        default:
            return nil
        }
    }
}
