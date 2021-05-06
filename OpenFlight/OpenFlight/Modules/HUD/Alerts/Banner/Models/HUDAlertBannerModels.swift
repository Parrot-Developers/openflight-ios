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

import UIKit

// MARK: - Internal Enums
/// List of critical alerts for HUD banner.
public enum HUDBannerCriticalAlertType: String, HUDAlertType {
    case motorCutout
    case motorCutoutTemperature
    case motorCutoutPowerSupply
    case forceLandingFlyAway
    case forceLandingLowBattery
    case forceLandingTemperature
    case veryLowBatteryLanding
    case veryLowBattery
    case noGpsTooDark
    case noGpsTooHigh
    case noGps
    case headingLockedKo
    case noGpsLapse
    case tooMuchWind
    case strongImuVibration
    case internalMemoryFull
    case sdError
    case sdFull
    case sdTooSlow
    case geofenceAltitudeAndDistance
    case geofenceAltitude
    case geofenceDistance
    case obstacleAvoidanceDroneStucked
    case obstacleAvoidanceNoGpsTooHigh
    case obstacleAvoidanceNoGpsTooDark
    case obstacleAvoidanceTooDark
    case obstacleAvoidanceSensorsFailure
    case obstacleAvoidanceSensorsNotCalibrated
    case obstacleAvoidanceDeteriorated

    public var level: HUDAlertLevel {
        return .critical
    }

    public var category: AlertCategoryType {
        switch self {
        case .motorCutout,
             .motorCutoutTemperature,
             .motorCutoutPowerSupply:
            return .componentsMotor
        case .forceLandingFlyAway,
             .forceLandingLowBattery,
             .forceLandingTemperature,
             .veryLowBatteryLanding,
             .veryLowBattery:
            return .autoLanding
        case .noGpsTooDark,
             .noGpsTooHigh,
             .noGps,
             .noGpsLapse,
             .headingLockedKo:
            return .conditions
        case .tooMuchWind:
            return .conditionsWind
        case .strongImuVibration:
            return .componentsImu
        case .internalMemoryFull,
             .sdError,
             .sdFull,
             .sdTooSlow:
            return .sdCard
        case .geofenceAltitudeAndDistance,
             .geofenceAltitude,
             .geofenceDistance:
            return .geofence
        case .obstacleAvoidanceDroneStucked,
             .obstacleAvoidanceNoGpsTooHigh,
             .obstacleAvoidanceNoGpsTooDark,
             .obstacleAvoidanceTooDark,
             .obstacleAvoidanceSensorsFailure,
             .obstacleAvoidanceSensorsNotCalibrated,
             .obstacleAvoidanceDeteriorated:
            return .obstacleAvoidance
        }
    }

    public var priority: String {
        return rawValue
    }

    public var label: String {
        switch self {
        case .motorCutout:
            return L10n.alertMotorCutout
        case .motorCutoutTemperature:
            return L10n.alertMotorCutoutTemperature
        case .motorCutoutPowerSupply:
            return L10n.alertMotorCutoutPowerSupply
        case .forceLandingFlyAway,
             .forceLandingLowBattery,
             .forceLandingTemperature,
             .veryLowBatteryLanding:
            return L10n.alertAutoLanding
        case .veryLowBattery:
            return L10n.alertVeryLowBattery
        case .noGpsTooDark:
            return L10n.alertNoGpsTooDark
        case .noGpsTooHigh:
            return L10n.alertNoGpsTooHigh
        case .noGps:
            return L10n.alertNoGps
        case .headingLockedKo:
            return L10n.alertHeadingLockKo
        case .noGpsLapse:
            return L10n.alertNoGpsGpslapse
        case .tooMuchWind:
            return L10n.alertTooMuchWind
        case .strongImuVibration:
            return L10n.alertStrongImuVibrations
        case .internalMemoryFull:
            return L10n.alertInternalMemoryFull
        case .sdError:
            return L10n.alertSdErrorSwitchingInternal
        case .sdFull:
            return L10n.alertSdFullSwitchingInternal
        case .sdTooSlow:
            return L10n.alertSdcardTooSlow
        case .geofenceAltitudeAndDistance,
             .geofenceAltitude,
             .geofenceDistance:
            return L10n.alertGeofenceReached
        case .obstacleAvoidanceDroneStucked:
            return L10n.alertDroneStuck
        case .obstacleAvoidanceNoGpsTooHigh,
             .obstacleAvoidanceNoGpsTooDark:
            return L10n.alertNoAvoidanceNoGps
        case .obstacleAvoidanceTooDark:
            return L10n.alertNoAvoidanceTooDark
        case .obstacleAvoidanceSensorsFailure:
            return L10n.alertNoAvoidanceSensorsFailure
        case .obstacleAvoidanceSensorsNotCalibrated:
            return L10n.alertNoAvoidanceSensorsNotCalibrated
        case .obstacleAvoidanceDeteriorated:
            return L10n.alertAvoidanceDeteriorated
        }
    }

    public var icon: UIImage? {
        switch self {
        case .motorCutout,
             .motorCutoutTemperature,
             .motorCutoutPowerSupply,
             .strongImuVibration:
            return Asset.Common.Icons.icDroneSmall.image
        case .forceLandingFlyAway,
             .forceLandingLowBattery,
             .forceLandingTemperature,
             .veryLowBatteryLanding,
             .veryLowBattery:
            return Asset.Common.Icons.icWarningWhite.image
        case .tooMuchWind:
            return Asset.Common.Icons.icWind.image
        case .internalMemoryFull:
            return Asset.Common.Icons.icSdSmall.image
        case .sdError,
             .sdFull,
             .sdTooSlow:
            return Asset.Gallery.droneInternalMemory.image
        case .geofenceAltitudeAndDistance:
            return Asset.Telemetry.icDistance.image
        case .geofenceAltitude:
            return Asset.Telemetry.icAltitude.image
        case .geofenceDistance:
            return Asset.Telemetry.icDistance.image
        default:
            return nil
        }
    }

    public var actionType: AlertActionType? {
        switch self {
        case .veryLowBatteryLanding:
            return .landing
        default:
            return nil
        }
    }

    public var vibrationDelay: TimeInterval {
        switch self {
        case .veryLowBatteryLanding,
             .veryLowBattery:
            return 0.0
        default:
            return HUDAlertConstants.defaultVibrationDelay
        }
    }
}

/// List of warning alerts for HUD banner.
public enum HUDBannerWarningAlertType: String, HUDAlertType {
    case cameraError
    case lowAndPerturbedWifi
    case obstacleAvoidanceDroneStucked
    case imuVibration
    case targetLost
    case droneGpsKo
    case userDeviceGpsKo
    case unauthorizedFlightZone
    case unauthorizedFlightZoneWithMission

    public var level: HUDAlertLevel {
        return .warning
    }

    public var category: AlertCategoryType {
        switch self {
        case .cameraError:
            return .componentsCamera
        case .lowAndPerturbedWifi:
            return .wifi
        case .obstacleAvoidanceDroneStucked:
            return .obstacleAvoidance
        case .imuVibration:
            return .componentsImu
        case .targetLost,
             .droneGpsKo,
             .userDeviceGpsKo:
            return .animations
        case .unauthorizedFlightZone,
             .unauthorizedFlightZoneWithMission:
            return .flightZone
        }
    }

    public var priority: String {
        return rawValue
    }

    public var label: String {
        switch self {
        case .cameraError:
            return L10n.alertCameraError
        case .lowAndPerturbedWifi:
            return L10n.alertLowAndPerturbedWifi
        case .obstacleAvoidanceDroneStucked:
            return L10n.alertDroneStuck
        case .imuVibration:
            return L10n.alertImuVibrations
        case .targetLost:
            // TODO: To move in FF in a warning enum (string + alert)
            return L10n.alertTargetLost
        case .droneGpsKo,
             .userDeviceGpsKo:
            return L10n.alertGpsKo
        case .unauthorizedFlightZone,
             .unauthorizedFlightZoneWithMission:
            return L10n.alertUnauthorizedFlightZone
        }
    }

    public var icon: UIImage? {
        switch self {
        case .cameraError:
            return Asset.Common.Icons.iconCamera.image
        case .lowAndPerturbedWifi:
            return Asset.Common.Icons.icWifi.image
        case .imuVibration:
            return Asset.Common.Icons.icDroneSmall.image
        case .droneGpsKo, .userDeviceGpsKo:
            return Asset.Gps.Controller.icGpsKo.image.withRenderingMode(.alwaysTemplate)
        default:
            return nil
        }
    }

    public var actionType: AlertActionType? {
        return nil
    }

    public var vibrationDelay: TimeInterval {
        switch self {
        case .targetLost, .droneGpsKo, .userDeviceGpsKo:
            return 0.0
        default:
            return HUDAlertConstants.defaultVibrationDelay
        }
    }
}

/// List of tutorial alerts for HUD banner.
public enum HUDBannerTutorialAlertType: String, HUDAlertType {
    case takeOff
    case takeOffWaypoint
    case takeOffPoi
    case selectSubject

    public var level: HUDAlertLevel {
        return .tutorial
    }

    public var category: AlertCategoryType {
        return .animations
    }

    public var priority: String {
        return rawValue
    }

    public var label: String {
        switch self {
        case .takeOff:
            return L10n.alertTakeOff
        case .takeOffWaypoint:
            return L10n.alertTakeOffWaypoint
        case .takeOffPoi:
            return L10n.alertTakeOffPoi
        case .selectSubject:
            return L10n.alertSelectSubject
        }
    }

    public var icon: UIImage? {
        return nil
    }

    public var actionType: AlertActionType? {
        return nil
    }

    public var vibrationDelay: TimeInterval {
        return 0.0
    }
}
