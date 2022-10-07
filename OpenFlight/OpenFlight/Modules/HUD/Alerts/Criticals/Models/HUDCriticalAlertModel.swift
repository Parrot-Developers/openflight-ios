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

import UIKit
import GroundSdk

// MARK: - Protocols
/// Stores major/critical alert fields.
protocol CriticalAlertModel {
    /// Alert panel top title.
    var topTitle: String? { get }
    /// Alert panel top title color.
    var topTitleColor: ColorName? { get }
    /// Alert panel top title's icon.
    var topIcon: UIImage? { get }
    /// Alert panel top title's icon color.
    var topIconTintColor: ColorName? { get }
    /// Alert panel top background color.
    var topBackgroundColor: ColorName? { get }
    /// Main alert image.
    var mainImage: UIImage? { get }
    /// Alert description.
    var mainDescription: String? { get }
    /// Tells if cancel button need to be shown.
    var showCancelButton: Bool? { get }
    /// Action button shadow.
    var addCancelButtonShadow: Bool? { get }
    /// Action button title.
    var actionButtonTitle: String? { get }
    /// Action button title color.
    var actionButtonTitleColor: ColorName? { get }
    /// Action button background color.
    var actionButtonBackgroundColor: ColorName? { get }
    /// Action button shadow.
    var addActionButtonShadow: Bool? { get }
}

// MARK: - Internal Enums
/// Model used to store each major/critical alert.
public enum HUDCriticalAlertType: Comparable {
    case sensorFailure([TakeoffAlarm.Kind])
    case droneAndRemoteUpdateRequired
    case droneUpdateRequired
    case remoteUpdateRequired
    case droneCalibrationRequired
    case droneInclination
    case updateOngoing
    case batteryLevel
    case highTemperature
    case lowTemperature
    case batteryPoorConnection
    case obstacleAvoidanceFreeze
    case batteryUsbPortConnection
    case cellularModemFirmwareUpdate
    case insufficientStorageSpace
    case insufficientStorageSpeed
    case sdCardNotDetected
    case sdCardNeedsFormat
    case droneAndVehicleGpsKo
    case droneGpsKo
    case vehicleGpsKo
    case droneTooFar(Float)

    var isSensorAlarm: Bool {
        switch self {
        case .sensorFailure:
            return true
        default:
            return false
        }
    }

    var isUpdateRequired: Bool {
        return self == .droneUpdateRequired || self == .remoteUpdateRequired || self == .droneAndRemoteUpdateRequired
    }

    var priority: Int {
        switch self {
        case .sensorFailure:                return 1
        case .droneAndRemoteUpdateRequired: return 2
        case .droneUpdateRequired:          return 3
        case .remoteUpdateRequired:         return 4
        case .droneCalibrationRequired:     return 5
        case .droneInclination:             return 6
        case .updateOngoing:                return 7
        case .batteryLevel:                 return 8
        case .highTemperature:              return 9
        case .lowTemperature:               return 10
        case .batteryPoorConnection:        return 11
        case .batteryUsbPortConnection:     return 12
        case .obstacleAvoidanceFreeze:      return 13
        case .cellularModemFirmwareUpdate:  return 14
        case .insufficientStorageSpace:     return 15
        case .insufficientStorageSpeed:     return 16
        case .sdCardNeedsFormat:            return 17
        case .sdCardNotDetected:            return 18
        case .droneAndVehicleGpsKo:         return 19
        case .droneGpsKo:                   return 20
        case .vehicleGpsKo:                 return 21
        case .droneTooFar:                  return 22
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.priority < rhs.priority
    }

    public static func from(_ kind: TakeoffAlarm.Kind) -> HUDCriticalAlertType? {
        switch kind {
        case .baro,
             .gps,
             .gyro,
             .magneto,
             .ultrasound,
             .vcam,
             .verticalTof:
            return .sensorFailure([kind])
        case .batteryGaugeUpdateRequired:
            return nil
        case .batteryIdentification:
            return nil
        case .batteryLevel:
            return batteryLevel
        case .batteryTooCold:
            return lowTemperature
        case .batteryTooHot:
            return highTemperature
        case .batteryPoorConnection:
            return .batteryPoorConnection
        case .batteryUsbPortConnection:
            return batteryUsbPortConnection
        case .cellularModemFirmwareUpdate:
            return cellularModemFirmwareUpdate
        case .droneInclination:
            return droneInclination
        case .magnetoCalibration:
            return droneCalibrationRequired
        case .updateOngoing:
            return updateOngoing
        }
    }
}

extension HUDCriticalAlertType: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .sensorFailure(let kind):
            hasher.combine(kind)
        default:
            break
        }
    }
}

// MARK: - CriticalAlertModel
extension HUDCriticalAlertType: CriticalAlertModel {
    var topTitle: String? {
        switch self {
        case let .sensorFailure(kinds):
            let sensors = kinds.map { (kind) -> String in
                switch kind {
                case .baro:         return L10n.takeoffAlertSensorBarometer
                case .gps:          return L10n.takeoffAlertSensorGps
                case .gyro:         return L10n.takeoffAlertSensorImu
                case .magneto:      return L10n.takeoffAlertSensorMagnetometer
                case .ultrasound:   return L10n.takeoffAlertSensorUltrasound
                case .vcam:         return L10n.takeoffAlertSensorVcam
                case .verticalTof:  return L10n.takeoffAlertSensorVtof
                default:            return ""
                }
            }
            .joined(separator: ", ")
            return L10n.takeoffAlertSensorTitle(sensors)
        case .droneAndRemoteUpdateRequired:
            return L10n.takeoffAlertDroneRemoteUpdateTitle
        case .droneUpdateRequired:
            return L10n.takeoffAlertDroneUpdateTitle
        case .remoteUpdateRequired:
            return L10n.takeoffAlertRemoteUpdateTitle
        case .droneCalibrationRequired:
            return L10n.droneDetailsCalibrationRequired
        case .droneInclination:
            return L10n.takeoffAlertInclinationTitle
        case .updateOngoing:
            return L10n.takeoffAlertUpdatingTitle
        case .batteryLevel:
            return L10n.takeoffAlertBatteryLevelTitle
        case .highTemperature:
            return L10n.takeoffAlertHighTemperatureTitle
        case .lowTemperature:
            return L10n.takeoffAlertLowTemperatureTitle
        case .batteryPoorConnection:
            return L10n.takeoffAlertPoorBatteryConnectionTitle
        case .obstacleAvoidanceFreeze:
            return L10n.alertOaFreezeTitle
        case .batteryUsbPortConnection:
            return L10n.takeoffAlertUsbConnectionTitle
        case .cellularModemFirmwareUpdate:
            return L10n.takeoffAlertModemUpdatingTitle
        case .insufficientStorageSpace:
            return L10n.alertMemoryFullTitle
        case .insufficientStorageSpeed:
            return L10n.alertSdcardErrorTitle
        case .sdCardNotDetected:
            return L10n.alertNoSdcardErrorTitle
        case .sdCardNeedsFormat:
            return L10n.alertSdcardFormatErrorTitle
        case .droneAndVehicleGpsKo:
            return L10n.takeoffAlertDroneControllerGpsUnavailableTitle
        case .droneGpsKo:
            return L10n.takeoffAlertDroneGpsUnavailableTitle
        case .vehicleGpsKo:
            return L10n.takeoffAlertControllerGpsUnavailableTitle
        case .droneTooFar:
            return L10n.takeoffAlertDroneTooFarTitle
        }
    }

    var topIcon: UIImage? {
        switch self {
        case .droneUpdateRequired,
             .remoteUpdateRequired,
             .droneAndRemoteUpdateRequired:
            return Asset.Alertes.TakeOff.icDownloadAlert.image
        case .droneCalibrationRequired:
            return Asset.Alertes.TakeOff.icRefreshAlert.image
        case .batteryLevel,
             .highTemperature,
             .lowTemperature,
             .batteryPoorConnection,
             .batteryUsbPortConnection:
            return Asset.Common.Icons.icBattery.image
        case .insufficientStorageSpace:
            return Asset.Gallery.droneSd.image
        case .insufficientStorageSpeed,
             .sdCardNotDetected,
             .sdCardNeedsFormat:
            return Asset.Common.Icons.icSdCardErrorSmall.image
        case .droneAndVehicleGpsKo,
                .droneGpsKo,
                .vehicleGpsKo:
            return Asset.Drone.icSatellite.image
        default:
            return nil
        }
    }

    var topIconTintColor: ColorName? {
        switch self {
        case .droneUpdateRequired,
             .remoteUpdateRequired,
             .droneAndRemoteUpdateRequired:
            return .defaultTextColor
        case .droneCalibrationRequired:
            return .warningColor
        case .batteryLevel,
             .highTemperature,
             .lowTemperature,
             .batteryPoorConnection,
             .batteryUsbPortConnection,
             .insufficientStorageSpace,
             .insufficientStorageSpeed,
             .sdCardNotDetected,
             .sdCardNeedsFormat,
             .droneAndVehicleGpsKo,
             .droneGpsKo,
             .vehicleGpsKo:
            return .white
        default:
            return nil
        }
    }

    var topTitleColor: ColorName? {
        switch self {
        case .droneUpdateRequired,
             .remoteUpdateRequired,
             .droneAndRemoteUpdateRequired,
             .droneCalibrationRequired:
            return .defaultTextColor
        default:
            return .white
        }
    }

    var topBackgroundColor: ColorName? {
        switch self {
        case .droneUpdateRequired,
             .remoteUpdateRequired,
             .droneAndRemoteUpdateRequired,
             .droneCalibrationRequired:
            return .white
        default:
            return .errorColor
        }
    }

    var mainImage: UIImage? {
        switch self {
        case .sensorFailure:
            return Asset.Alertes.TakeOff.icDroneSensorAlert.image
        case .droneUpdateRequired:
            return Asset.Alertes.TakeOff.icDroneUpdateAlert.image
        case .remoteUpdateRequired:
            return Asset.Alertes.TakeOff.icRemoteUpdateAlert.image
        case .droneAndRemoteUpdateRequired:
            return Asset.Alertes.TakeOff.icDroneRemoteUpdateAlert.image
        case .droneCalibrationRequired:
            return Asset.Alertes.TakeOff.icDroneCalibrationNeeded.image
        case .droneInclination:
            return nil
        case .updateOngoing:
            return Asset.Alertes.TakeOff.icDroneUpdating.image
        case .batteryLevel:
            return Asset.Alertes.TakeOff.icDroneLowBattery.image
        case .highTemperature:
            return Asset.Alertes.TakeOff.icHighTemperatureAlert.image
        case .lowTemperature:
            return Asset.Alertes.TakeOff.icLowTemperatureAlert.image
        case .batteryPoorConnection:
            return Asset.Alertes.TakeOff.icBatteryPoorConnectionAlert.image
        case .obstacleAvoidanceFreeze:
            return Asset.ObstacleAvoidance.icOADisabled.image
        case .batteryUsbPortConnection:
            return Asset.Alertes.TakeOff.icDroneUSB.image
        case .cellularModemFirmwareUpdate:
            return Asset.Alertes.TakeOff.icModemInitializing.image
        case .insufficientStorageSpace:
            return Asset.Drone.icDroneStorageFull.image
        case .insufficientStorageSpeed,
             .sdCardNotDetected,
             .sdCardNeedsFormat:
            return Asset.Common.Icons.icSdCardError.image
        case .droneAndVehicleGpsKo:
            return Asset.Alertes.TakeOff.icGpsDroneKoRemoteKo.image
        case .droneGpsKo:
            return Asset.Alertes.TakeOff.icGpsDroneKoRemoteOk.image
        case .vehicleGpsKo:
            return Asset.Alertes.TakeOff.icGpsDroneOkRemoteKo.image
        case .droneTooFar:
            return Asset.Alertes.TakeOff.icDroneTooFar.image
        }
    }

    var mainDescription: String? {
        switch self {
        case .sensorFailure:
            return L10n.takeoffAlertSensorDescription
        case .droneUpdateRequired:
            return L10n.takeoffAlertDroneUpdateDescription
        case .remoteUpdateRequired:
            return L10n.takeoffAlertRemoteUpdateDescription
        case .droneAndRemoteUpdateRequired:
            return L10n.takeoffAlertDroneRemoteUpdateDescription
        case .droneCalibrationRequired:
            return L10n.takeoffAlertCalibrationDescription
        case .droneInclination:
            return L10n.takeoffAlertInclinationDescription
        case .updateOngoing:
            return L10n.takeoffAlertUpdatingDescription
        case .batteryLevel:
            return L10n.takeoffAlertBatteryLevelDescription
        case .highTemperature:
            return L10n.takeoffAlertHighTemperatureDescription
        case .lowTemperature:
            return L10n.takeoffAlertLowTemperatureDescription
        case .batteryPoorConnection:
            return L10n.takeoffAlertPoorBatteryConnectionDescription
        case .obstacleAvoidanceFreeze:
            return L10n.alertOaFreezeDescription
        case .batteryUsbPortConnection:
            return L10n.takeoffAlertUsbConnectionDescription
        case .cellularModemFirmwareUpdate:
            return L10n.takeoffAlertModemUpdatingDescription
        case .insufficientStorageSpace:
            return L10n.alertMemoryFullDescription
        case .insufficientStorageSpeed:
            return L10n.alertSdcardInsufficientSpeedErrorDesc
        case .sdCardNotDetected:
            return L10n.alertNoSdcardErrorDesc
        case .sdCardNeedsFormat:
            return L10n.alertSdcardFormatErrorDesc
        case .droneAndVehicleGpsKo,
                .droneGpsKo,
                .vehicleGpsKo:
            return L10n.takeoffAlertGpsUnavailableDescription
        case .droneTooFar(let maxDistance):
            return L10n.takeoffAlertDroneTooFarDescription(UnitHelper.stringDistanceWithDouble(Double(maxDistance)))
       }
    }

    var showCancelButton: Bool? {
        switch self {
        case .droneUpdateRequired,
             .remoteUpdateRequired,
             .droneAndRemoteUpdateRequired,
             .droneCalibrationRequired:
            return true
        default:
            return false
        }
    }

    var addCancelButtonShadow: Bool? {
        return false
    }

    var actionButtonTitle: String? {
        switch self {
        case .droneUpdateRequired,
             .remoteUpdateRequired,
             .droneAndRemoteUpdateRequired:
            return L10n.dashboardUpdate
        case .droneCalibrationRequired:
            return L10n.remoteCalibrationCalibrate
        default:
            return L10n.ok
        }
    }

    var actionButtonTitleColor: ColorName? {
        switch self {
        case .obstacleAvoidanceFreeze,
             .droneInclination,
             .updateOngoing,
             .batteryUsbPortConnection,
             .cellularModemFirmwareUpdate,
             .insufficientStorageSpace,
             .insufficientStorageSpeed,
             .sdCardNotDetected,
             .sdCardNeedsFormat:
            return .defaultTextColor
        default:
            return .white
        }
    }

    var actionButtonBackgroundColor: ColorName? {
        switch self {
        case .sensorFailure,
             .batteryLevel,
             .highTemperature,
             .lowTemperature,
             .batteryPoorConnection,
             .droneAndVehicleGpsKo,
             .droneGpsKo,
             .vehicleGpsKo,
             .droneTooFar:
            return .warningColor
        case .droneInclination,
             .updateOngoing,
             .batteryUsbPortConnection,
             .cellularModemFirmwareUpdate:
            return .whiteAlbescent
        case .droneUpdateRequired,
             .remoteUpdateRequired,
             .droneAndRemoteUpdateRequired,
             .droneCalibrationRequired:
            return .highlightColor
        case .obstacleAvoidanceFreeze,
             .insufficientStorageSpace,
             .insufficientStorageSpeed,
             .sdCardNotDetected,
             .sdCardNeedsFormat:
            return .defaultBgcolor
        }
    }

    var addActionButtonShadow: Bool? {
        switch self {
        case .insufficientStorageSpace,
             .insufficientStorageSpeed:
            return true
        default:
            return false
        }
    }
}

/// Stores constants related to critical alerts on the HUD.
enum HUDCriticalAlertConstants {
    static let takeOffRequestedNotificationKey: String = "takeOffRequested"
}
