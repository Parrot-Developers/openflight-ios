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

/// Defines defaultKeys to store in UserDefaults.
public extension DefaultsKeys {
    // MARK: - Stored IDs
    var lastConnectedDroneUID: DefaultsKey<String?> { .init("key_lastConnectedDroneUID") }
    var lastConnectedRcUID: DefaultsKey<String?> { .init("key_lastConnectedRcUID") }
    // DRI
    var lastDriId: DefaultsKey<String?> { .init("key_lastDriId") }

    // MARK: - User Settings

    // Safety settings
    var maxAltitudeSetting: DefaultsKey<Double?> { .init("key_maxAltitudeSetting") }
    // Behaviour settings
    var userPilotingPreset: DefaultsKey<String?> { .init("key_userPilotingPreset") }
    var filmMaxPitchRoll: DefaultsKey<Double?> { DefaultsKeys.filmMaxPitchRollKey }
    var filmMaxPitchRollVelocity: DefaultsKey<Double?> { DefaultsKeys.filmMaxPitchRollVelocityKey }
    var filmMaxVerticalSpeed: DefaultsKey<Double?> { DefaultsKeys.filmMaxVerticalSpeedKey }
    var filmMaxYawRotationSpeed: DefaultsKey<Double?> { DefaultsKeys.filmMaxYawRotationSpeedKey }
    var filmBankedTurnMode: DefaultsKey<Bool?> { DefaultsKeys.filmBankedTurnModeKey }
    var filmInclinedRollMode: DefaultsKey<Bool?> { DefaultsKeys.filmInclinedRollModeKey }
    var filmCameraTilt: DefaultsKey<Double?> { DefaultsKeys.filmCameraTiltKey }
    var sportMaxPitchRoll: DefaultsKey<Double?> { DefaultsKeys.sportMaxPitchRollKey }
    var sportMaxPitchRollVelocity: DefaultsKey<Double?> { DefaultsKeys.sportMaxPitchRollVelocityKey }
    var sportMaxVerticalSpeed: DefaultsKey<Double?> { DefaultsKeys.sportMaxVerticalSpeedKey }
    var sportMaxYawRotationSpeed: DefaultsKey<Double?> { DefaultsKeys.sportMaxYawRotationSpeedKey }
    var sportBankedTurnMode: DefaultsKey<Bool?> { DefaultsKeys.sportBankedTurnModeKey }
    var sportInclinedRollMode: DefaultsKey<Bool?> { DefaultsKeys.sportInclinedRollModeKey }
    var sportCameraTilt: DefaultsKey<Double?> { DefaultsKeys.sportCameraTiltKey }
    var cinematicMaxPitchRoll: DefaultsKey<Double?> { .init("key_cinematicMaxPitchRoll") }
    var cinematicMaxPitchRollVelocity: DefaultsKey<Double?> { .init("key_cinematicMaxPitchRollVelocity") }
    var cinematicMaxVerticalSpeed: DefaultsKey<Double?> { .init("key_cinematicMaxVerticalSpeed") }
    var cinematicMaxYawRotationSpeed: DefaultsKey<Double?> { .init("key_cinematicMaxYawRotationSpeed") }
    var cinematicBankedTurnMode: DefaultsKey<Bool?> { .init("key_cinematicBankedTurnMode") }
    var cinematicInclinedRollMode: DefaultsKey<Bool?> { .init("key_cinematicInclinedRollMode") }
    var cinematicCameraTilt: DefaultsKey<Double?> { .init("key_cinematicCameraTilt") }
    var racingMaxPitchRoll: DefaultsKey<Double?> { .init("key_racingMaxPitchRoll") }
    var racingMaxPitchRollVelocity: DefaultsKey<Double?> { .init("key_racingMaxPitchRollVelocity") }
    var racingMaxVerticalSpeed: DefaultsKey<Double?> { .init("key_racingMaxVerticalSpeed") }
    var racingMaxYawRotationSpeed: DefaultsKey<Double?> { .init("key_racingMaxYawRotationSpeed") }
    var racingBankedTurnMode: DefaultsKey<Bool?> { .init("key_racingBankedTurnMode") }
    var racingInclinedRollMode: DefaultsKey<Bool?> { .init("key_racingInclinedRollMode") }
    var racingCameraTilt: DefaultsKey<Double?> { .init("key_racingCameraTilt") }

    // Interface settings
    var userMeasurementSetting: DefaultsKey<String?> { DefaultsKeys.userMeasurementSettingKey }
    var secondaryScreenSetting: DefaultsKey<String?> { DefaultsKeys.secondaryScreenSettingKey }
    var userMiniMapTypeSetting: DefaultsKey<String?> { DefaultsKeys.userMiniMapTypeSettingKey }

    // Controls settings
    var userControlModeSetting: DefaultsKey<String?> { .init("key_userControlModeSetting") }
    var userControlModeArcadeSetting: DefaultsKey<String?> { .init("key_userControlModeArcadeSetting") }
    var arcadeTiltReversedSetting: DefaultsKey<Bool> { .init("key_arcadeTiltReversedSetting", defaultValue: false) }
    var evTriggerSetting: DefaultsKey<Bool> { .init("key_evTriggerSetting", defaultValue: false) }
    var userShowMiniMapSetting: DefaultsKey<String?> { .init("key_userShowMiniMapSetting") }

    // MARK: - Camera
    var overexposureSetting: DefaultsKey<String?> { DefaultsKeys.overexposureSettingKey }
    var hdrModeSetting: DefaultsKey<String?> { .init("key_hdrModeSetting") }
    var isPanoramaModeActivated: DefaultsKey<Bool> { .init("key_isPanoramaModeActivated", defaultValue: false) }
    var userPanoramaSetting: DefaultsKey<String> { DefaultsKeys.userPanoramaSettingKey }
    var isImagingAutoModeActive: DefaultsKey<Bool> { .init("key_isImagingAutoModeActive", defaultValue: true) }
    var lastShutterSpeedValue: DefaultsKey<String?> { .init("key_lastShutterSpeedValue") }
    var lastCameraIsoValue: DefaultsKey<String?> { .init("key_lastCameraIsoValue") }
    var highDynamicRangeSetting: DefaultsKey<String?> { .init("key_highDynamicRangeSetting") }

    // MARK: - Last sync dates
    var profileLastSyncDate: DefaultsKey<Date?> { DefaultsKeys.profileLastSyncDateKey }
    var academyProfileLastSyncDate: DefaultsKey<Date?> { DefaultsKeys.academyProfileLastSyncDateKey }
    var personalDataLastSyncDate: DefaultsKey<Date?> { DefaultsKeys.personalDataLastSyncDateKey }
    var flightsAndFlightPlansLastSyncDate: DefaultsKey<Date?> { DefaultsKeys.flightsAndFlightPlansLastSyncDateKey }

    // Needs to set share old data (login)
    var needsShareOldDataAnswer: DefaultsKey<Bool> { .init("key_needsShareOldDataAnswer", defaultValue: false) }
    // is User Connected to My Parrot
    var isUserConnected: DefaultsKey<Bool> { .init("key_isUserConnected", defaultValue: false) }

    // MARK: - Mission
    var userMissionProvider: DefaultsKey<String> { .init("key_userMissionProvider", defaultValue: String(describing: ClassicMission.self)) }
    var userMissionMode: DefaultsKey<String> { .init("key_userMissionMode", defaultValue: MissionConstants.classicMissionManualKey) }

    // MARK: - My Flights
    var flightPlanLastSyncDate: DefaultsKey<Date?> { .init("key_flightPlanLastSyncDate") }

    // MARK: - Drone
    var lastDroneLocation: DefaultsKey<Data?> { DefaultsKeys.lastDroneLocationKey }
    var lastDroneHeading: DefaultsKey<Double?> { DefaultsKeys.lastDroneHeadingKey }

    // MARK: - Parrot Debug
    var activatedLog: DefaultsKey<Bool> { .init("key_activatedLog", defaultValue: false) }
    var debugC: DefaultsKey<Bool> { .init("key_checkC", defaultValue: false) }

    // MARK: - Gallery
    var localMediaCounts: DefaultsKey<[String: Any]?> { .init("key_localMediaCounts") }
    var mediasDatesGallery: DefaultsKey<[String: Any]?> { .init("key_mediasDates") }
    var mediasRunUidGallery: DefaultsKey<[String: Any]?> { .init("key_mediasRunUid") }

    // MARK: - Cellular Access
    var networkUsername: DefaultsKey<String?> { DefaultsKeys.networkUsernameKey }
    var networkPassword: DefaultsKey<String?> { DefaultsKeys.networkPasswordKey }
    var networkUrl: DefaultsKey<String?> { DefaultsKeys.networkUrlKey }
    var isManualApnRequested: DefaultsKey<Bool?> { .init("key_isManualApnRequested") }
    /// Defines a drone PI list used for cellular pairing process visibilty.
    /// The user can show or dismiss the process for the connected drone.
    var dronesListPairingProcessHidden: DefaultsKey<[String]> { .init("key_dronesListPairingProcessHidden", defaultValue: []) }
    /// List of already paired drones.
    var cellularPairedDronesList: DefaultsKey<[String]> { .init("key_dronePairedList", defaultValue: []) }
}

/// Define keys as static let for cases which need direct access to the key, not the defaultKey.
public extension DefaultsKeys {
    // MARK: - User Settings
    // Behaviour settings
    static let filmMaxPitchRollKey: DefaultsKey<Double?> = DefaultsKey<Double?>("key_filmMaxPitchRoll")
    static let filmMaxPitchRollVelocityKey: DefaultsKey<Double?> = DefaultsKey<Double?>("key_filmMaxPitchRollVelocity")
    static let filmMaxVerticalSpeedKey: DefaultsKey<Double?> = DefaultsKey<Double?>("key_filmMaxVerticalSpeed")
    static let filmMaxYawRotationSpeedKey: DefaultsKey<Double?> = DefaultsKey<Double?>("key_filmMaxYawRotationSpeed")
    static let filmBankedTurnModeKey: DefaultsKey<Bool?> = DefaultsKey<Bool?>("key_filmBankedTurnMode")
    static let filmInclinedRollModeKey: DefaultsKey<Bool?> = DefaultsKey<Bool?>("key_filmInclinedRollMode")
    static let filmCameraTiltKey: DefaultsKey<Double?> = DefaultsKey<Double?>("key_filmCameraTilt")
    static let sportMaxPitchRollKey: DefaultsKey<Double?> = DefaultsKey<Double?>("key_sportMaxPitchRoll")
    static let sportMaxPitchRollVelocityKey: DefaultsKey<Double?> = DefaultsKey<Double?>("key_sportMaxPitchRollVelocity")
    static let sportMaxVerticalSpeedKey: DefaultsKey<Double?> = DefaultsKey<Double?>("key_sportMaxVerticalSpeed")
    static let sportMaxYawRotationSpeedKey: DefaultsKey<Double?> = DefaultsKey<Double?>("key_sportMaxYawRotationSpeed")
    static let sportBankedTurnModeKey: DefaultsKey<Bool?> = DefaultsKey<Bool?>("key_sportBankedTurnMode")
    static let sportInclinedRollModeKey: DefaultsKey<Bool?> = DefaultsKey<Bool?>("key_sportInclinedRoll")
    static let sportCameraTiltKey: DefaultsKey<Double?> = DefaultsKey<Double?>("key_sportCameraTilt")

    // Interface settings
    static let userMeasurementSettingKey: DefaultsKey<String?> = DefaultsKey<String?>("key_userMeasurementSetting")
    static let secondaryScreenSettingKey: DefaultsKey<String?> = DefaultsKey<String?>("key_secondaryScreenSettingKey",
                                                                                      defaultValue: String(describing: SecondaryScreenType.map.rawValue))
    static let userMiniMapTypeSettingKey: DefaultsKey<String?> = DefaultsKey<String?>("key_userMiniMapTypeSetting",
                                                                                      defaultValue: String(describing: SettingsMapDisplayType.hybrid.rawValue))

    // MARK: - Camera
    static let overexposureSettingKey: DefaultsKey<String?> = DefaultsKey<String?>("key_overexposureSetting")
    static let userPanoramaSettingKey: DefaultsKey<String> = DefaultsKey<String>("key_userPanoramaSetting", defaultValue: PanoramaMode.vertical.rawValue)

    // MARK: - Last sync dates
    static let profileLastSyncDateKey: DefaultsKey<Date?> = DefaultsKey<Date?>("key_profileLastSyncDate")
    static let academyProfileLastSyncDateKey: DefaultsKey<Date?> = DefaultsKey<Date?>("key_academyProfileLastSyncDate")
    static let personalDataLastSyncDateKey: DefaultsKey<Date?> = DefaultsKey<Date?>("key_personalDataLastSyncDate")
    static let flightsAndFlightPlansLastSyncDateKey: DefaultsKey<Date?> = DefaultsKey<Date?>("key_flightsAndFlightPlansLastSyncDate")

    // MARK: - Drone
    static let lastDroneLocationKey: DefaultsKey<Data?> = DefaultsKey<Data?>("key_lastDroneLocation")
    static let lastDroneHeadingKey: DefaultsKey<Double?> = DefaultsKey<Double?>("key_lastDroneHeading")

    // MARK: - Cellular Access
    static let networkUsernameKey: DefaultsKey<String?> = DefaultsKey<String?>("key_networkUsername")
    static let networkPasswordKey: DefaultsKey<String?> = DefaultsKey<String?>("key_networkPassword")
    static let networkUrlKey: DefaultsKey<String?> = DefaultsKey<String?>("key_networkUrl")
}
