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
    /// Action button title.
    var actionButtonTitle: String? { get }
    /// Action button title color.
    var actionButtonTitleColor: ColorName? { get }
    /// Action button background color.
    var actionButtonBackgroundColor: ColorName? { get }
}

// MARK: - Internal Enums
/// Model used to store each major/critical alert.
enum HUDCriticalAlertType: Comparable {
    case sensorFailure([TakeoffAlarm.Kind])
    case droneAndRemoteUpdateRequired
    case droneUpdateRequired
    case droneCalibrationRequired
    case droneInclination
    case updateOngoing
    case batteryLevel
    case highTemperature
    case lowTemperature
    case batteryUsbPortConnection
    case cellularModemFirmwareUpdate

    var isSensorAlarm: Bool {
        switch self {
        case .sensorFailure:
            return true
        default:
            return false
        }
    }

    var isUpdateRequired: Bool {
        return self == .droneUpdateRequired || self == .droneAndRemoteUpdateRequired
    }

    var priority: Int {
        switch self {
        case .sensorFailure:                return 1
        case .droneAndRemoteUpdateRequired: return 2
        case .droneUpdateRequired:          return 3
        case .droneCalibrationRequired:     return 4
        case .droneInclination:             return 5
        case .updateOngoing:                return 6
        case .batteryLevel:                 return 7
        case .highTemperature:              return 8
        case .lowTemperature:               return 9
        case .batteryUsbPortConnection:     return 10
        case .cellularModemFirmwareUpdate:  return 11
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
    func hash(into hasher: inout Hasher) {
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
        case .batteryUsbPortConnection:
            return L10n.takeoffAlertUsbConnectionTitle
        case .cellularModemFirmwareUpdate:
            return L10n.takeoffAlertModemUpdatingTitle
        }
    }

    var topIcon: UIImage? {
        switch self {
        case .droneUpdateRequired,
             .droneAndRemoteUpdateRequired:
            return Asset.Alertes.TakeOff.icDownloadAlert.image
        case .droneCalibrationRequired:
            return Asset.Alertes.TakeOff.icRefreshAlert.image
        case .batteryLevel,
             .highTemperature,
             .lowTemperature,
             .batteryUsbPortConnection:
            return Asset.Common.Icons.icBattery.image
        default:
            return nil
        }
    }

    var topIconTintColor: ColorName? {
        switch self {
        case .droneUpdateRequired,
             .droneAndRemoteUpdateRequired:
            return .defaultTextColor
        case .droneCalibrationRequired:
            return .warningColor
        case .batteryLevel,
             .highTemperature,
             .lowTemperature,
             .batteryUsbPortConnection:
            return .white
        default:
            return nil
        }
    }

    var topTitleColor: ColorName? {
        switch self {
        case .droneUpdateRequired,
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
        case .droneAndRemoteUpdateRequired:
            return Asset.Alertes.TakeOff.icDroneRemoteUpdateAlert.image
        case .droneCalibrationRequired:
            return Asset.Alertes.TakeOff.icDroneCalibrationNeeded.image
        case .droneInclination:
            return Asset.Alertes.TooMuchAngle.icDroneOpenYourDrone.image
        case .updateOngoing:
            return Asset.Alertes.TakeOff.icDroneUpdating.image
        case .batteryLevel:
            return Asset.Alertes.TakeOff.icDroneLowBattery.image
        case .highTemperature:
            return Asset.Alertes.TakeOff.icHighTemperatureAlert.image
        case .lowTemperature:
            return Asset.Alertes.TakeOff.icLowTemperatureAlert.image
        case .batteryUsbPortConnection:
            return Asset.Alertes.TakeOff.icDroneUSB.image
        case .cellularModemFirmwareUpdate:
            return Asset.Alertes.TakeOff.icModemInitializing.image
        }
    }

    var mainDescription: String? {
        switch self {
        case .sensorFailure:
            return L10n.takeoffAlertSensorDescription
        case .droneUpdateRequired:
            return L10n.takeoffAlertDroneUpdateDescription
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
        case .batteryUsbPortConnection:
            return L10n.takeoffAlertUsbConnectionDescription
        case .cellularModemFirmwareUpdate:
            return L10n.takeoffAlertModemUpdatingDescription
        }
    }

    var showCancelButton: Bool? {
        switch self {
        case .droneUpdateRequired,
             .droneAndRemoteUpdateRequired,
             .droneCalibrationRequired:
            return true
        default:
            return false
        }
    }

    var actionButtonTitle: String? {
        switch self {
        case .droneUpdateRequired,
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
        case .droneInclination,
             .updateOngoing,
             .batteryUsbPortConnection,
             .cellularModemFirmwareUpdate:
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
             .lowTemperature:
            return .warningColor
        case .droneInclination,
             .updateOngoing,
             .batteryUsbPortConnection,
             .cellularModemFirmwareUpdate:
            return .whiteAlbescent
        case .droneUpdateRequired,
             .droneAndRemoteUpdateRequired,
             .droneCalibrationRequired:
            return .highlightColor
        }
    }
}

/// Stores constants related to critical alerts on the HUD.
enum HUDCriticalAlertConstants {
    static let takeOffRequestedNotificationKey: String = "takeOffRequested"
}
