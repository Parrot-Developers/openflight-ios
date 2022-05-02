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

/// Defines defaultKeys to store in UserDefaults.
public extension DefaultsKeys {

    // MARK: - User Settings

    // Safety settings
    var maxAltitudeSetting: DefaultsKey<Double?> { .init("key_maxAltitudeSetting") }
    // Behaviour settings
    var userPilotingPreset: DefaultsKey<String?> { .init("key_userPilotingPreset") }

    // Interface settings
    var userMeasurementSetting: DefaultsKey<String?> { DefaultsKeys.userMeasurementSettingKey }
    var secondaryScreenSetting: DefaultsKey<String?> { DefaultsKeys.secondaryScreenSettingKey }
    var userMiniMapTypeSetting: DefaultsKey<String?> { DefaultsKeys.userMiniMapTypeSettingKey }

    // Controls settings
    var userControlModeSetting: DefaultsKey<String?> { .init("key_userControlModeSetting") }
    var evTriggerSetting: DefaultsKey<Bool> { .init("key_evTriggerSetting", defaultValue: false) }

    // MARK: - Camera
    var overexposureSetting: DefaultsKey<String?> { DefaultsKeys.overexposureSettingKey }
    var isPanoramaModeActivated: DefaultsKey<Bool> { .init("key_isPanoramaModeActivated", defaultValue: false) }
    var userPanoramaSetting: DefaultsKey<String> { DefaultsKeys.userPanoramaSettingKey }
    var lastShutterSpeedValue: DefaultsKey<String?> { .init("key_lastShutterSpeedValue") }
    var lastCameraIsoValue: DefaultsKey<String?> { .init("key_lastCameraIsoValue") }
    var highDynamicRangeSetting: DefaultsKey<String?> { .init("key_highDynamicRangeSetting") }

    // MARK: - Parrot Debug
    var activatedLog: DefaultsKey<Bool> { .init("key_activatedLog", defaultValue: false) }
    var debugC: DefaultsKey<Bool> { .init("key_checkC", defaultValue: false) }

    // MARK: - Gallery
    var localMediaCounts: DefaultsKey<[String: Any]?> { .init("key_localMediaCounts") }
    var mediasDatesGallery: DefaultsKey<[String: Any]?> { .init("key_mediasDates") }
    var mediasRunUidGallery: DefaultsKey<[String: Any]?> { .init("key_mediasRunUid") }

    // MARK: - Cellular Access
    /// Defines a drone PI list used for cellular pairing process visibilty.
    /// The user can show or dismiss the process for the connected drone.
    var dronesListPairingProcessHidden: DefaultsKey<[String]> { .init("key_dronesListPairingProcessHidden", defaultValue: []) }
    /// List of already paired drones.
    var cellularPairedDronesList: DefaultsKey<[String]> { .init("key_dronePairedList", defaultValue: []) }

    // MARK: - Projects
    var isFlightPlanProjectType: DefaultsKey<Bool> { .init("key_isFlightPlanProjectType", defaultValue: true) }
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
    static let lastSyncProcessErrorDate: DefaultsKey<Date?> = DefaultsKey<Date?>("key_lastSyncProcessErrorDate")
    static let isSyncProcessError: DefaultsKey<Bool> = DefaultsKey<Bool>("key_isSyncProcessError", defaultValue: false)

    // MARK: - Terms Of Use
    /// Bool which indicates if terms of use are accepted.
    static let areOFTermsOfUseAccepted: DefaultsKey<Bool> = DefaultsKey<Bool>("key_areOFTermsOfUseAccepted",
                                                                              defaultValue: false)
}

// MARK: - Synchro Service
public extension DefaultsKeys {
    // - Multi Session
    var latestTriedSynchroMultiSessionDate: DefaultsKey<Date?> {
        DefaultsKey<Date?>.init("cloudSync.service.latestTriedMultiSession")
    }
    var latestSuccessfulSynchroMultiSessionDate: DefaultsKey<Date?> {
        DefaultsKey<Date?>.init("cloudSync.service.latestSuccessfulMultiSession")
    }

    // - Incremental
    var shouldLaunchSynchroIncremental: DefaultsKey<Bool> {
        .init("cloudSync.service.shouldLaunchSynchroIncremental", defaultValue: true)
    }
}

// MARK: - Cloud Multi-Session Sync.
public extension DefaultsKeys {
    var latestGutmaSynchroDate: DefaultsKey<Date> {
        .init("cloudSync.multisession.latestGutmaSynchroDate", defaultValue: Date.distantPast)
    }
    var latestFlightPlanSynchroDate: DefaultsKey<Date> {
        .init("cloudSync.multisession.latestFlightPlanSynchroDate", defaultValue: Date.distantPast)
    }
    var latestProjectSynchroDate: DefaultsKey<Date> {
        .init("cloudSync.multisession.latestProjectSynchroDate", defaultValue: Date.distantPast)
    }

    var latestGutmaCloudDeletionDate: DefaultsKey<Date> {
        .init("cloudSync.multisession.latestGutmaCloudDeletionDate", defaultValue: Date.distantPast)
    }
    var latestFlightPlanCloudDeletionDate: DefaultsKey<Date> {
        .init("cloudSync.multisession.latestFlightPlanCloudDeletionDate", defaultValue: Date.distantPast)
    }
    var latestProjectCloudDeletionDate: DefaultsKey<Date> {
        .init("cloudSync.multisession.latestProjectCloudDeletionDate", defaultValue: Date.distantPast)
    }
}
