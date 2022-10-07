//    Copyright (C) 2022 Parrot Drones SAS
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

// MARK: - Critical

public enum CriticalBannerAlert: Int, BannerAlert, Equatable {

    case motorCutout
    case motorCutoutTemperature
    case motorCutoutPowerSupply
    case forceLandingLowBattery
    case forceLandingBatteryTooCold
    case forceLandingBatteryTooHot
    case forceLandingIcedPropeller
    case wontReachHome
    case batteryGaugeUpdateRequired
    case batteryIdentification
    case noGpsTooDark
    case noGpsTooHigh
    case noGps
    case headingLockedKoPerturbationMagnetic
    case headingLockedKoEarthMagnetic
    case tooMuchWind
    case strongImuVibration
    case sdError
    case sdTooSlow
    case internalMemoryError
    case geofence
    case obstacleAvoidanceTooDark
    case obstacleAvoidanceSensorsFailure
    case obstacleAvoidanceGimbalFailure
    case obstacleAvoidanceSensorsNotCalibrated
    case obstacleAvoidanceDeteriorated
    case obstacleAvoidanceStrongWind
    case obstacleAvoidanceComputationalError
    case cameraError
    case needCalibration
    case stereoCameraDecalibrated
    case rthIcedPropeller
    case rthPoorBatteryConnection

    public var severity: BannerAlertSeverity { .critical }

    public var content: BannerAlertContent { .init(icon: icon, title: title) }

    public var priority: Int { rawValue }

    private var icon: UIImage? {
        switch self {
        case .motorCutout,
                .motorCutoutTemperature,
                .motorCutoutPowerSupply,
                .strongImuVibration:
            return Asset.Common.Icons.icDroneSmall.image
        case .forceLandingLowBattery,
                .forceLandingBatteryTooCold,
                .forceLandingBatteryTooHot,
                .forceLandingIcedPropeller:
            return Asset.Common.Icons.icWarningWhite.image
        case .tooMuchWind,
                .obstacleAvoidanceStrongWind:
            return Asset.Common.Icons.icWind.image
        case .sdError,
                .sdTooSlow:
            return Asset.Gallery.droneSd.image
        case .internalMemoryError:
            return Asset.Gallery.droneInternalMemory.image
        case .geofence:
            return Asset.Telemetry.icGeofence.image
        case .cameraError:
            return Asset.Common.Icons.iconCamera.image
        case .rthIcedPropeller:
            return Asset.Common.Icons.icDroneSmall.image
        default:
            return nil
        }
    }

    private var title: String {
        switch self {
        case .motorCutout:
            return L10n.alertMotorCutout
        case .motorCutoutTemperature:
            return L10n.alertMotorCutoutTemperature
        case .motorCutoutPowerSupply:
            return L10n.alertMotorCutoutPowerSupply
        case .forceLandingLowBattery:
            return L10n.alertAutolandingBatteryTooLow
        case .forceLandingBatteryTooCold:
            return L10n.alertAutolandingBatteryTooCold
        case .forceLandingBatteryTooHot:
            return L10n.alertAutolandingBatteryTooHot
        case .forceLandingIcedPropeller:
            return L10n.alertAutolandingPropellerFault
        case .wontReachHome:
            return L10n.alertReturnHomeWontReachHome
        case .batteryGaugeUpdateRequired:
            return L10n.alertBatteryGaugeUpdateRequired
        case .batteryIdentification:
            return L10n.alertBatteryIdentificationFailed
        case .noGpsTooDark:
            return L10n.alertNoGpsTooDark
        case .noGpsTooHigh:
            return L10n.alertNoGpsTooHigh
        case .noGps:
            return L10n.alertNoGps
        case .headingLockedKoPerturbationMagnetic:
            return L10n.alertHeadingLockKoPerturbationMagnetic
        case .headingLockedKoEarthMagnetic:
            return L10n.alertHeadingLockKoEarthMagnetic
        case .tooMuchWind:
            return L10n.alertTooMuchWind
        case .strongImuVibration:
            return L10n.alertStrongImuVibrations
        case .sdError:
            return L10n.alertSdError
        case .internalMemoryError:
            return L10n.alertInternalMemoryError
        case .sdTooSlow:
            return L10n.alertSdcardTooSlow
        case .geofence:
            return L10n.alertGeofenceReached
        case .obstacleAvoidanceTooDark:
            return L10n.alertNoAvoidanceTooDark
        case .obstacleAvoidanceSensorsFailure:
            return L10n.alertNoAvoidanceSensorsFailure
        case .obstacleAvoidanceGimbalFailure:
            return L10n.alertNoAvoidanceGimbalFailure
        case .obstacleAvoidanceSensorsNotCalibrated:
            return L10n.alertNoAvoidanceSensorsNotCalibrated
        case .obstacleAvoidanceDeteriorated:
            return L10n.alertAvoidanceDeteriorated
        case .obstacleAvoidanceStrongWind:
            return L10n.alertDeterioratedAvoidanceStrongWinds
        case .obstacleAvoidanceComputationalError:
            return L10n.alertObstacleAvoidanceComputationalError
        case .cameraError:
            return L10n.alertCameraError
        case .needCalibration:
            return L10n.droneDetailsCalibrationRequired
        case .stereoCameraDecalibrated:
            return L10n.alertStereoSensorsNotCalibrated
        case .rthIcedPropeller:
            return L10n.alertPropellerFault
        case .rthPoorBatteryConnection:
            return L10n.alertPoorBatteryConnection
        }
    }
}

// MARK: - Warning

public enum WarningBannerAlert: Int, BannerAlert, Equatable {

    case lowAndPerturbedWifi
    case obstacleAvoidanceDroneStucked
    case obstacleAvoidanceBlindMotionDirection
    case imuVibration
    case targetLost
    case droneGpsKo
    case userDeviceGpsKo
    case unauthorizedFlightZone
    case unauthorizedFlightZoneWithMission
    case highDeviation

    public var severity: BannerAlertSeverity { .warning }

    public var content: BannerAlertContent { .init(icon: icon, title: title) }

    public var behavior: BannerAlertBehavior {
        switch self {
        case .obstacleAvoidanceDroneStucked,
                .obstacleAvoidanceBlindMotionDirection:
            // Specific case: use severity's default behavior without any 'on' or 'snooze' duration.
            return BannerAlertBehavior(feedbackType: severity.feedbackType,
                                       systemSoundId: severity.systemSoundId)
        default:
            // Use severity's default behavior.
            return severity.behavior
        }
    }

    public var priority: Int { rawValue }

    private var icon: UIImage? {
        switch self {
        case .lowAndPerturbedWifi:
            return Asset.Common.Icons.icWifi.image
        case .imuVibration:
            return Asset.Common.Icons.icDroneSmall.image
        case .droneGpsKo,
                .userDeviceGpsKo:
            return Asset.Gps.Controller.icGpsKo.image.withRenderingMode(.alwaysTemplate)
        default:
            return nil
        }
    }

    private var title: String {
        switch self {
        case .lowAndPerturbedWifi:
            return L10n.alertLowAndPerturbedWifi
        case .obstacleAvoidanceDroneStucked:
            return L10n.alertDroneStuck
        case .imuVibration:
            return L10n.alertImuVibrations
        case .targetLost:
            return L10n.alertTargetLost
        case .droneGpsKo,
                .userDeviceGpsKo:
            return L10n.alertGpsKo
        case .unauthorizedFlightZone,
                .unauthorizedFlightZoneWithMission:
            return L10n.alertUnauthorizedFlightZone
        case .highDeviation:
            return L10n.alertHighDeviation
        case .obstacleAvoidanceBlindMotionDirection:
            return L10n.alertObstacleAvoidanceBlindDirection
        }
    }
}

// MARK: - Advice

public enum AdviceBannerAlert: Int, BannerAlert, Equatable {

    case takeOff

    public var severity: BannerAlertSeverity { .advice }

    public var content: BannerAlertContent { .init(title: title) }

    public var priority: Int { rawValue }

    private var title: String {
        switch self {
        case .takeOff:
            return L10n.alertTakeOff
        }
    }
}

// MARK: - Home

public enum HomeAlert: Int, BannerAlert, Equatable {

    case homePositionSet
    case preciseRthInProgress
    case preciseLandingInProgress

    public var severity: BannerAlertSeverity { .advice }

    public var content: BannerAlertContent { .init(icon: icon, title: title) }

    public var style: BannerAlertStyle {
        .init(titleColor: UIColor.black,
              backgroundColor: ColorName.highlightColor.color)
    }

    public var behavior: BannerAlertBehavior {
        switch self {
        case .homePositionSet:
            return .init(onDuration: BannerAlertConstants.defaultOnDuration)
        case .preciseRthInProgress,
                .preciseLandingInProgress:
            return .init()
        }
    }

    private var icon: UIImage? { Asset.Common.Icons.iconHome.image }

    private var title: String {
        switch self {
        case .homePositionSet:
            return L10n.rthPositionSet
        case .preciseRthInProgress:
            return L10n.preciseRth
        case .preciseLandingInProgress:
            return L10n.preciseLanding
        }
    }
}

// MARK: - Exposure

public enum ExposureAlert: Int, BannerAlert, Equatable {

    case lockAe
    case hdrOn

    public var severity: BannerAlertSeverity { .mandatory }

    public var content: BannerAlertContent { .init(icon: icon, title: title) }

    public var style: BannerAlertStyle {
        .init(titleColor: UIColor.black,
              backgroundColor: ColorName.yellowSea.color)
    }

    public var behavior: BannerAlertBehavior {
        switch self {
        case .lockAe:
            return .init()
        case .hdrOn:
            return .init()
        }
    }

    public var priority: Int { rawValue }

    private var icon: UIImage? {
        switch self {
        case .lockAe:
            return Asset.Common.Icons.iconLock.image
        case .hdrOn:
            return nil
        }
    }

    private var title: String {
        switch self {
        case .lockAe:
            return L10n.lockAe
        case .hdrOn:
            return L10n.cameraHdr
        }
    }
}

public extension AnyBannerAlert {
    static var takeoffChecklistAlerts: [CriticalBannerAlert] {
        [.batteryIdentification, .batteryGaugeUpdateRequired, .needCalibration]
    }

    static var copterMotorAlerts: [CriticalBannerAlert] {
        [.motorCutout, .motorCutoutTemperature, .motorCutoutTemperature]
    }

    static var alarmsAlerts: [BannerAlert] {
        copterMotorAlerts +
        conditionsAlerts +
        obstacleAvoidanceAlerts +
        geofenceAlerts +
        autoLandingAlerts
    }

    private static var conditionsAlerts: [BannerAlert] {
        [
            CriticalBannerAlert.forceLandingIcedPropeller,
            CriticalBannerAlert.noGpsTooDark,
            CriticalBannerAlert.noGpsTooHigh,
            CriticalBannerAlert.headingLockedKoPerturbationMagnetic,
            CriticalBannerAlert.headingLockedKoEarthMagnetic,
            CriticalBannerAlert.tooMuchWind,
            CriticalBannerAlert.stereoCameraDecalibrated,
            CriticalBannerAlert.rthIcedPropeller
        ]
    }

    private static var obstacleAvoidanceAlerts: [BannerAlert] {
        [
            CriticalBannerAlert.obstacleAvoidanceSensorsFailure,
            CriticalBannerAlert.obstacleAvoidanceGimbalFailure,
            CriticalBannerAlert.obstacleAvoidanceSensorsNotCalibrated,
            CriticalBannerAlert.obstacleAvoidanceTooDark,
            CriticalBannerAlert.obstacleAvoidanceDeteriorated,
            CriticalBannerAlert.obstacleAvoidanceStrongWind,
            CriticalBannerAlert.obstacleAvoidanceComputationalError,
            WarningBannerAlert.obstacleAvoidanceBlindMotionDirection,
            WarningBannerAlert.highDeviation,
            WarningBannerAlert.obstacleAvoidanceDroneStucked
        ]
    }

    private static var geofenceAlerts: [CriticalBannerAlert] {
        [.geofence]
    }

    private static var autoLandingAlerts: [CriticalBannerAlert] {
        [
            .forceLandingBatteryTooCold,
            .forceLandingBatteryTooHot,
            .forceLandingLowBattery,
            .forceLandingIcedPropeller
        ]
    }
}
