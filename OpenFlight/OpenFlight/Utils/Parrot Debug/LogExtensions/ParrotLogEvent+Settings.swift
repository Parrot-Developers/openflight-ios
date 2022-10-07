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

// MARK: - Internals Enums
/// LogEvent for settings
extension LogEvent {
    /// Enum which stores quick settings keys for log messages.
    enum LogKeyQuickSettings {
        static let geofence: String = "Geofence"
        static let obstacleAvoidance: String = "ObstacleAvoidance"
        static let audio: String = "Audio"
        static let extraZoom: String = "ExtraZoom"
        static let interfaceGrid: String = "InterfaceGrid"
        static let streamType: String = "StreamType"
    }

    /// Enum which stores controls settings keys for log messages.
    enum LogKeyControlsSettings {
        static let evTrigger: String = "EvTrigger"
        static let special: String = "Special"
        static let inverseJoys: String = "InverseJoys"
        static let resetControlSettings: String = "ResetControlSettings"
    }

    /// Enum which stores advanced settings keys for log messages.
    enum LogKeyAdvancedSettings {
        static let filmMode: String = "FilmMode"
        static let sportMode: String = "SportMode"
        static let horizon: String = "Horizon"
        static let cameraTiltSpeed: String = "CameraTiltSpeed"
        static let bankedTurn: String = "BankedTurn"
        static let inclination: String = "Inclination"
        static let verticalSpeed: String = "VerticalSpeed"
        static let rotationSpeed: String = "RotationSpeed"
        static let mapType: String = "MapType"
        static let secondaryScreenType: String = "SecondaryScreen"
        static let measurementSystem: String = "MeasurementSystem"
        static let geofence: String = "Geofence"
        static let returnHome: String = "ReturnHome"
        static let extraZoom: String = "ExtraZoom"
        static let displayOverexposure: String = "DisplayOverexposure"
        static let signPictures: String = "SignPictures"
        static let videoEncoding: String = "VideoEncoding"
        static let videoHDR: String = "VideoHDR"
        static let antiFlickering: String = "AntiFlickering"
        static let wifiBand: String = "WifiBand"
        static let resetFilmSettings: String = "ResetFilmSettings"
        static let resetSportSettings: String = "ResetSportSettings"
        static let resetInterfaceSettings: String = "ResetInterfaceSettings"
        static let resetGeofenceSettings: String = "ResetGeofenceSettings"
        static let resetRTHSettings: String = "ResetRTHSettings"
        static let resetRecordingSettings: String = "ResetRecordingSettings"
        static let resetNetworkSettings: String = "ResetNetworkSettings"
        static let resetDevelopperSettings: String = "ResetDevelopperSettings"
        static let networkPassword: String = "Password"
        static let cellularAccess: String = "CellularAccess"
        static let networkPreferences: String = "NetworkPreferences"
        static let driSetting: String = "DRI"
        static let directConnectionSetting: String = "DirectConnectionSettings"
        static let shellAccessSetting: String = "ShellAccessSettings"
        static let missionLogsSetting: String = "MissionLogsSettings"
    }

    /// Enum which stores password edition button key for log message.
    enum LogKeyWifiPasswordEdition {
        static let changePassword = "ChangePassword"
    }
}
