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
enum HUDBannerCriticalAlertType: Int, HUDAlertType {
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
    case noGpsLapse
    case tooMuchWind
    case strongImuVibration
    case internalMemoryFull
    case sdFull
    case sdError
    case geofenceAltitudeAndDistance
    case geofenceAltitude
    case geofenceDistance
    case droneTooFar
    case droneTooLow
    case droneTooClose

    var level: HUDAlertLevel {
        return .critical
    }

    var category: AlertCategoryType {
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
             .noGpsLapse:
            return .conditions
        case .tooMuchWind:
            return .conditionsWind
        case .strongImuVibration:
            return .componentsImu
        case .internalMemoryFull,
             .sdFull,
             .sdError:
            return .sdCard
        case .geofenceAltitudeAndDistance,
             .geofenceAltitude,
             .geofenceDistance:
            return .geofence
        case .droneTooClose,
             .droneTooFar,
             .droneTooLow:
            return .followMe
        }
    }

    var priority: Int {
        return rawValue
    }

    var label: String {
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
        case .noGpsLapse:
            return L10n.alertNoGpsGpslapse
        case .tooMuchWind:
            return L10n.alertTooMuchWind
        case .strongImuVibration:
            return L10n.alertStrongImuVibrations
        case .internalMemoryFull:
            return L10n.alertInternalMemoryFull
        case .sdFull:
            return L10n.alertSdFullSwitchingInternal
        case .sdError:
            return L10n.alertSdErrorSwitchingInternal
        case .geofenceAltitudeAndDistance,
             .geofenceAltitude,
             .geofenceDistance:
            return L10n.alertGeofenceReached
        case .droneTooFar:
            return L10n.followMeDroneTooFarAway
        case .droneTooLow:
            return L10n.followMeDroneTooLow
        case .droneTooClose:
            return L10n.followMeSubjectTooClose
        }
    }

    var icon: UIImage? {
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
        case .sdFull,
             .sdError:
            // TODO: replace with internal memory icon when available.
            return Asset.Common.Icons.icSdSmall.image
        case .geofenceAltitudeAndDistance:
            return Asset.Telemetry.icDistance.image
        case .geofenceAltitude:
            return Asset.Telemetry.icAltitude.image
        case .geofenceDistance:
            return Asset.Telemetry.icDistance.image
        case .droneTooLow:
            return Asset.Telemetry.icAltitude.image
        default:
            return nil
        }
    }

    var actionType: AlertActionType? {
        switch self {
        case .veryLowBatteryLanding:
            return .landing
        default:
            return nil
        }
    }

    var vibrationDelay: TimeInterval {
        switch self {
        case .veryLowBatteryLanding,
             .veryLowBattery:
            return 0.0
        default:
            return Constants.defaultVibrationDelay
        }
    }
}

/// List of warning alerts for HUD banner.
enum HUDBannerWarningAlertType: Int, HUDAlertType {
    case cameraError
    case lowAndPerturbedWifi
    case noAvoidanceStereoVisionKo
    case noAvoidanceStereoVisionNotCalibrated
    case noAvoidanceTooDark
    case noAvoidanceNoData
    case droneStuck
    case imuVibration
    case targetLost
    case droneGpsKo
    case userDeviceGpsKo
    case unauthorizedFlightZone
    case unauthorizedFlightZoneWithMission

    var level: HUDAlertLevel {
        return .warning
    }

    var category: AlertCategoryType {
        switch self {
        case .cameraError:
            return .componentsCamera
        case .lowAndPerturbedWifi:
            return .wifi
        case .noAvoidanceStereoVisionKo,
             .noAvoidanceStereoVisionNotCalibrated,
             .noAvoidanceTooDark,
             .noAvoidanceNoData,
             .droneStuck:
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

    var priority: Int {
        return rawValue
    }

    var label: String {
        switch self {
        case .cameraError:
            return L10n.alertCameraError
        case .lowAndPerturbedWifi:
            return L10n.alertLowAndPerturbedWifi
        case .noAvoidanceStereoVisionKo:
            return L10n.alertNoAvoidanceLoveKo
        case .noAvoidanceStereoVisionNotCalibrated:
            return L10n.alertNoAvoidanceLoveNotCalibrated
        case .noAvoidanceTooDark:
            return L10n.alertNoAvoidanceTooDark
        case .noAvoidanceNoData:
            return L10n.alertNoAvoidanceNoData
        case .droneStuck:
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
        }
    }

    var icon: UIImage? {
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

    var actionType: AlertActionType? {
        return nil
    }

    var vibrationDelay: TimeInterval {
        switch self {
        case .targetLost, .droneGpsKo, .userDeviceGpsKo:
            return 0.0
        default:
            return Constants.defaultVibrationDelay
        }
    }
}

/// List of tutorial alerts for HUD banner.
enum HUDBannerTutorialAlertType: Int, HUDAlertType {
    case takeOff
    case takeOffWaypoint
    case takeOffPoi
    case selectSubject

    var level: HUDAlertLevel {
        return .tutorial
    }

    var category: AlertCategoryType {
        return .animations
    }

    var priority: Int {
        return rawValue
    }

    var label: String {
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

    var icon: UIImage? {
        return nil
    }

    var actionType: AlertActionType? {
        return nil
    }

    var vibrationDelay: TimeInterval {
        return 0.0
    }
}

// MARK: - Private Enums
private enum Constants {
    static let defaultVibrationDelay: TimeInterval = 90.0
}
