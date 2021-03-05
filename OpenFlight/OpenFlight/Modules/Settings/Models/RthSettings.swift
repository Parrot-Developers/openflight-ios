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

import SwiftyUserDefaults
import GroundSdk

// MARK: - Internal Enums
enum RthPreset {
    static let rthType: ReturnHomeTarget = .takeOffPosition
    static let maxAltitude: Double = 150.0
    static let minAltitude: Double = 20.0
    static let defaultAltitude: Double = 30.0
    static let defaultHoveringAltitude: Double = 2.0
    static let defaultEndingBehavior: ReturnHomeEndingBehavior = .hovering
}

/// `ReturnHomeTarget` extension used in Settings.
extension ReturnHomeTarget: SettingMode {
    var localized: String {
        switch self {
        case .controllerPosition:
            return L10n.settingsRthTypePilot
        case .takeOffPosition:
            return L10n.settingsRthTypeTakeOff
        default:
            return ""
        }
    }

    var key: String {
        return description
    }

    static var allValues: [SettingMode] {
        return [ReturnHomeTarget.takeOffPosition,
                ReturnHomeTarget.controllerPosition]
    }

    /// Returns true if current setting value is take off or controller position.
    var isHomeAvailable: Bool {
        return self == .takeOffPosition || self == .controllerPosition
    }
}

// MARK: - ReturnHomeEndingBehavior
/// `ReturnHomeEndingBehavior` extension used in Settings.
extension ReturnHomeEndingBehavior: SettingMode {
    var localized: String {
        switch self {
        case .hovering:
            return L10n.commonHovering
        case .landing:
            return L10n.commonLanding
        }
    }

    var key: String {
        return description
    }

    static var allValues: [SettingMode] {
        return [ReturnHomeEndingBehavior.hovering,
                ReturnHomeEndingBehavior.landing]
    }
}
