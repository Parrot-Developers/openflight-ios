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

import GroundSdk

/// Utility extension for `Camera2ExposureMode`.
extension Camera2ExposureMode {
    // MARK: - Internal Properties
    /// Whether shutter speed and ISO sensitivity are automatic.
    var automaticIsoAndShutterSpeed: Bool {
        switch self {
        case .automatic, .automaticPreferShutterSpeed, .automaticPreferIsoSensitivity:
            return true
        default:
            return false
        }
    }

    /// Whether ISO sensitivity is automatic.
    var automaticIsoSensitivity: Bool {
        switch self {
        case .automatic, .automaticPreferShutterSpeed, .automaticPreferIsoSensitivity, .manualShutterSpeed:
            return true
        default:
            return false
        }
    }

    /// Whether shutter speed is automatic.
    var automaticShutterSpeed: Bool {
        switch self {
        case .automatic, .automaticPreferShutterSpeed, .automaticPreferIsoSensitivity, .manualIsoSensitivity:
            return true
        default:
            return false
        }
    }

    // MARK: - Internal Funcs
    /// Returns ISO sensitivity to be monitored manually.
    func toManualIsoSensitivity() -> Camera2ExposureMode {
        switch self {
        case .automatic, .automaticPreferIsoSensitivity, .automaticPreferShutterSpeed:
            return .manualIsoSensitivity
        case .manualShutterSpeed:
            return .manual
        default:
            return self
        }
    }

    /// Returns shutter speed to be monitored manually.
    func toManualShutterSpeed() -> Camera2ExposureMode {
        switch self {
        case .automatic, .automaticPreferIsoSensitivity, .automaticPreferShutterSpeed:
            return .manualShutterSpeed
        case .manualIsoSensitivity:
            return .manual
        default:
            return self
        }
    }

    /// Returns ISO sensitivity to be monitored automatically.
    func toAutomaticIsoSensitivity() -> Camera2ExposureMode {
        switch self {
        case .manual:
            return .manualShutterSpeed
        case .manualIsoSensitivity:
            return toAutomaticMode()
        default:
            return self
        }
    }

    /// Returns shutter speed to be monitored automatically.
    func toAutomaticShutterSpeed() -> Camera2ExposureMode {
        switch self {
        case .manual:
            return .manualIsoSensitivity
        case .manualShutterSpeed:
            return toAutomaticMode()
        default:
            return self
        }
    }

    /// Returns shutter speed and ISO sensitivity to be monitored automatically.
    func toAutomaticMode() -> Camera2ExposureMode {
        return SettingsBehavioursMode.current.cameraExposureAutomaticMode
    }

    /// Refreshes `CameraExposureMode` value. Should be called when updating behaviour.
    func refreshAutomaticModeIfNeeded() -> Camera2ExposureMode? {
        switch self {
        case .automatic, .automaticPreferShutterSpeed, .automaticPreferIsoSensitivity:
            return SettingsBehavioursMode.current.cameraExposureAutomaticMode
        default:
            return nil
        }
    }
}

/// Utility extension for `Camera2Enum`.
extension Camera2ImmutableParam where T == Camera2ExposureMode {
    // MARK: - Internal Properties
    /// Returns true if manual shutter speed monitoring is available.
    var manualShutterSpeedAvailable: Bool {
        return !currentSupportedValues.intersection([.manual, .manualShutterSpeed]).isEmpty
    }
}
