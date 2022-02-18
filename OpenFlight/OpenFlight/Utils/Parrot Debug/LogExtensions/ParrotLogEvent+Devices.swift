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

/// LogEvent for drone details screens.
extension LogEvent {
    /// Enum which stores button key for log message.
    enum LogKeyDroneDetailsButtons {
        static let map: String = "Map"
        static let calibration: String = "Calibration"
        static let firmwareUpdate: String = "FirmwareUpdate"
        static let cellularAccess: String = "CellularAccess"
        static let informations: String = "Informations"
    }

    /// Enum which stores button keys for log message.
    enum LogKeyDroneDetailsCalibrationButton {
        static let gimbalCalibration: String = "GimbalCalibration"
        static let magnetometerCalibration: String = "DroneMagnometerCalibration"
        static let sensorCalibrationTutorial: String = "SensorCalibration/Tutorial"
        static let gimbalCalibrationStart: String = "GimbalCalibrationStart"
        static let magnetometerCalibrationCalibrate: String = "MagnetometerCalibrationCalibrate"
        static let obstacleAvoidanceCalibrationReady: String = "ObstacleAvoidanceCalibrationReady"
    }

    /// Enum which stores button keys for log message.
    enum LogKeyDroneDetailsInformationsButton {
        static let resetDroneInformations: String = "UpdateDrone"
    }

    /// Enum which stores button keys for log message.
    enum LogKeyDroneDetailsFirmwareUpdate {
        static let update: String = "Update"
    }

    /// Enum which stores drone details cellular keys for log messages.
    enum LogKeyDroneDetailsCellular {
        static let enterPinCode: String = "EnterPinCode"
        static let reinitialize: String = "Reinitialize"
        static let pairDevice: String = "pairDevice"
    }
}

/// LogEvent for remote infos screen.
extension LogEvent {
    /// Enum which stores button keys for log message.
    enum LogKeyRemoteInfosButton {
        case remoteConnectToDrone
        case remoteReset
        case remoteCalibration
        case updateRemote
        case cancelRemoteUpdate
        case okRemoteCalibration

        /// Name of the button according to log key for log.
        var name: String {
            switch self {
            case .remoteConnectToDrone:
                return "RemoteConnectToDrone"
            case .remoteCalibration:
                return "RemoteCalibration"
            case .updateRemote:
                return "RemoteUpdate"
            case .cancelRemoteUpdate:
                return "CancelRemoteUpdate"
            case .remoteReset:
                return "RemoteReset"
            case .okRemoteCalibration:
                return "OkRemoteCalibration"
            }
        }
    }
}

/// LogEvent for pairing remote to drone.
extension LogEvent {
    /// Enum which stores button keys for log message.
    enum LogKeyPairingButton {
        case refreshDroneList
        case connectToDronePasswordNeeded
        case connectToDroneWithoutPassword
        case connectToDroneUsingPassword

        /// Name of the button according to log key for log.
        var name: String {
            switch self {
            case .refreshDroneList:
                return "RefreshList"
            case .connectToDronePasswordNeeded:
                return "ConnectToDronePasswordNeeded"
            case .connectToDroneWithoutPassword:
                return "ConnectToDroneWhitoutPassword"
            case .connectToDroneUsingPassword:
                return "ConnectToDroneUsingPassword"
            }
        }
    }
}
