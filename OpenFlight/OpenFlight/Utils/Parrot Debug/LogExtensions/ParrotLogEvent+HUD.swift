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

import GroundSdk

// MARK: - Internals Enums
/// LogEvent for bottom bar in bottom bar in the HUD.
extension LogEvent {
    /// Enum which stores HUD top bar button keys for log message.
    enum LogKeyHUDTopBarButton {
        static let dashboard: String = "Dashboard"
        static let settings: String = "Settings"
        static let droneDetails: String = "DroneDetails"
        static let remoteControlDetails: String = "RemoteControlDetails"
    }

    /// Enum which stores HUD bottom bar button keys for log message.
    enum LogKeyHUDBottomBarButton {
        /// Bottom bar buttons.
        case cameraShutter
        case cameraMode
        case cameraWidget
        case missionLauncher
        case speedMode
        case imageMode
        /// Bottom bar capture settings buttons.
        case autoSetting
        case shutterSpeedSetting
        case cameraIsoSetting
        case whiteBalanceSetting
        case evCompensationSetting
        case dynamicRangeSetting
        case photoFormatSetting
        case photoResolutionSetting
        case videoResolutionSetting
        case framerateSetting
        case hyperlapseRatio
        /// Bottom bar photo mode buttons.
        case gpsLapse
        case timeLapse
        case timer
        case slowMotion
        case panorama
        case braketing

        /// Name of the button according to log key for log.
        var name: String {
            switch self {
            case .cameraShutter:
                return "CameraShutter"
            case .cameraMode:
                return "CameraMode"
            case .cameraWidget:
                return "CameraWidget"
            case .missionLauncher:
                return "MissionLauncher"
            case .speedMode:
                return "SpeedMode"
            case .imageMode:
                return "ImageMode"
            case .autoSetting:
                return "Auto"
            case .shutterSpeedSetting:
                return "ShutterSpeed"
            case .cameraIsoSetting:
                return "CameraIso"
            case .whiteBalanceSetting:
                return "WhiteBalance"
            case .evCompensationSetting:
                return "EvCompensation"
            case .dynamicRangeSetting:
                return "HDR"
            case .photoFormatSetting:
                return "PhotoFormat"
            case .photoResolutionSetting:
                return "PhotoResolution"
            case .videoResolutionSetting:
                return "VideoResolution"
            case .framerateSetting:
                return "FramerateSetting"
            case .hyperlapseRatio:
                return "HyperlapseRatio"
            case .gpsLapse:
                return "GPSLapse"
            case .timeLapse:
                return "TimeLapse"
            case .timer:
                return "Timer"
            case .slowMotion:
                return "SlowMotion"
            case .panorama:
                return "Panorama"
            case .braketing:
                return "Braketing"
            }
        }
    }

    /// Get log key according to bar item mode.
    ///
    /// - Parameters:
    ///     - mode: mode selected.
    /// - Returns: New formatted value of the mode.
    static func findLogKeyForCaptureMode(mode: BarItemMode?) -> String {
        switch mode {
        case is Camera2ShutterSpeed:
            return LogKeyHUDBottomBarButton.shutterSpeedSetting.name
        case is Camera2Iso:
            return LogKeyHUDBottomBarButton.cameraIsoSetting.name
        case is Camera2EvCompensation:
            return LogKeyHUDBottomBarButton.evCompensationSetting.name
        case is Camera2WhiteBalanceMode:
            return LogKeyHUDBottomBarButton.whiteBalanceSetting.name
        case is Camera2DynamicRange:
            return LogKeyHUDBottomBarButton.dynamicRangeSetting.name
        case is Camera2PhotoResolution:
            return LogKeyHUDBottomBarButton.photoResolutionSetting.name
        case is Camera2RecordingResolution:
            return LogKeyHUDBottomBarButton.videoResolutionSetting.name
        case is Camera2RecordingFramerate:
            return LogKeyHUDBottomBarButton.framerateSetting.name
        case is SettingsBehavioursMode:
            return LogKeyHUDBottomBarButton.speedMode.name
        default:
            return ""
        }
    }
}
