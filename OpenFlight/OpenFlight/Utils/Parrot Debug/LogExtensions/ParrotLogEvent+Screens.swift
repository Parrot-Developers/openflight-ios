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

/// LogEvent for all screen in the app.
public extension LogEvent {
    /// Enum which stores all screen name for log message.
    enum Screen {
        /// Settings screens.
        static let settings: String = "Settings"
        static let quick: String = "Settings/Quick"
        static let controls: String = "Settings/Controls"
        static let advanced: String = "Settings/Advanced"
        /// Wifi setting password edition.
        static let wifiPasswordEdition: String = "Settings/Advanced/WifiPasswordEdition"
        /// Drone infos screens.
        static let gimbal: String = "GimbalCalibration"
        static let correctHorizon: String = "CorrectHorizonCalibration"
        static let magnetometerCalibration: String = "DroneMagnetometerCalibration"
        static let obstacleAvoidance: String = "ObstacleAvoidance"
        static let confirmUpdate: String = "ConfirmUpdate"
        static let droneInformations: String = "DroneInformations"
        static let droneCalibration: String = "DroneCalibration"
        static let droneCellular: String = "DroneInformations/Cellular"
        /// Remote infos screens.
        static let remoteControlDetails: String = "RemoteControlDetails"
        static let remoteCalibration: String = "RemoteCalibration"
        static let pairingDroneFinderList: String = "Pairing/DroneFinder/List"
        static let connectToDrone: String = "Pairing/DroneFinder/List/Connection"
        /// Data confidentiality screens.
        static let dashboard: String = "Dashboard"
        static let myParrotDataConfidentiality: String = "MyParrot/DataConfidentiality"
        /// HUD.
        static let bottomBarHUD: String = "HUD/BottomBar"
        /// Cellular access.
        static let cellularAccessPinDialog: String = "Pairing/4G/PinDialog"
        /// Others.
        static let debugLogs: String = "Debug/Logs"
        static let pairing4gPinDialog: String = "Pairing/4G/PinDialog"
        static let gallery: String = "Gallery"
        static let galleryViewer: String = "Gallery/Viewer"
        static let sensorCalibrationTutorial: String = "SensorCalibration/Tutorial"
        static let sensorCalibration: String = "SensorCalibration"
        static let sensorCalibrationSuccess: String = "SensorCalibrationSuccess"
        static let sensorCalibrationFailure: String = "SensorCalibrationFailure"
        static let gimbalCalibration: String = "GimbalCalibration"
        static let pairingHowToConnectPhoneToDrone: String = "Pairing/HowToConnect/PhoneToDrone"
        static let pairing: String = "Pairing"
        static let pairingHowToConnectDroneTurnOn: String = "Pairing/HowToConnect/DroneTurnOn"
        static let pairingDroneFinderConnection: String = "Pairing/DroneFinder/Connection"
        static let myFlightsFlightList: String = "MyFlights/FlightList"
        static let myFlightsPlans: String = "MyFlights/Plans"
        static let settingsBankedTurnInfo: String = "Settings/BankedTurnInfo"
        static let settingsHorizonLineInfo: String = "Settings/HorizonLineInfo"
        static let hud: String = "HUD"
        static let pairingHowToConnectRemoteToPhone: String = "Pairing/HowToConnect/RemoteToPhone"
        // TODO: Use provider for this.
        static let flightPlanList: String = "FlightPlanList"
        static let flightDetails: String = "FlightDetails"
        static let droneDetails: String = "DroneDetails"
        static let firmwareUpdate: String = "FirmwareUpdate"
        static let flightPlanManageDialog: String = "FlightPlan/ManageDialog"
        static let flightPlanEditor: String = "FlightPlan/Editor"
    }

    /// Enum which stores some button keys for log message.
    enum KeyForScreenLogger {
        case data
        case parrot
        case pilot
    }
}
