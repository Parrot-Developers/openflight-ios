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

// MARK: - Protocols
/// Stores major/critical alert fields.
protocol CriticalAlertModel {
    /// Alert panel top title.
    var topTitle: String? { get }
    /// Alert panel top title's icon.
    var topIcon: UIImage? { get }
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
enum HUDCriticalAlertType: Sortable {
    case verticalCameraFailure
    case droneUpdateRequired
    case droneAndRemoteUpdateRequired
    case droneCalibrationRequired
    case highTemperature
    case lowTemperature
    case tooMuchAngle

    /// Returns the sorted list of alerts ordered by priority.
    static var sortedCases: [HUDCriticalAlertType] = [.verticalCameraFailure,
                                                      .droneAndRemoteUpdateRequired,
                                                      .droneUpdateRequired,
                                                      .droneCalibrationRequired,
                                                      .highTemperature,
                                                      .lowTemperature,
                                                      .tooMuchAngle]
}

// MARK: - CriticalAlertModel
extension HUDCriticalAlertType: CriticalAlertModel {
    var topTitle: String? {
        switch self {
        case .verticalCameraFailure:
            return L10n.takeoffAlertVerticalCameraTitle
        case .droneUpdateRequired:
            return L10n.takeoffAlertDroneUpdateTitle
        case .droneAndRemoteUpdateRequired:
            return L10n.takeoffAlertDroneRemoteUpdateTitle
        case .droneCalibrationRequired:
            return L10n.droneDetailsCalibrationRequired
        case .highTemperature:
            return L10n.takeoffAlertHighTemperatureTitle
        case .lowTemperature:
            return L10n.takeoffAlertLowTemperatureTitle
        case .tooMuchAngle:
            return L10n.alertTooMuchAngle
        }
    }

    var topIcon: UIImage? {
        switch self {
        case .verticalCameraFailure,
             .tooMuchAngle:
            return nil
        case .droneUpdateRequired,
             .droneAndRemoteUpdateRequired:
            return Asset.Alertes.TakeOff.icDownloadAlert.image
        case .droneCalibrationRequired:
            return Asset.Alertes.TakeOff.icRefreshAlert.image
        case .highTemperature,
             .lowTemperature:
            return Asset.Common.Icons.icBattery.image
        }
    }

    var topBackgroundColor: ColorName? {
        switch self {
        case .verticalCameraFailure,
             .highTemperature,
             .tooMuchAngle,
             .lowTemperature:
            return .redTorch
        case .droneUpdateRequired,
             .droneAndRemoteUpdateRequired,
             .droneCalibrationRequired:
            return .black
        }
    }

    var mainImage: UIImage? {
        switch self {
        case .verticalCameraFailure:
            return Asset.Alertes.TakeOff.icDroneCalibrationAlert.image
        case .droneUpdateRequired:
            return Asset.Alertes.TakeOff.icDroneUpdateAlert.image
        case .droneAndRemoteUpdateRequired:
            return Asset.Alertes.TakeOff.icDroneRemoteUpdateAlert.image
        case .droneCalibrationRequired:
            return Asset.Alertes.TakeOff.icDroneCalibrationNeeded.image
        case .highTemperature:
            return Asset.Alertes.TakeOff.icHighTemperatureAlert.image
        case .lowTemperature:
            return Asset.Alertes.TakeOff.icLowTemperatureAlert.image
        case .tooMuchAngle:
            return Asset.Alertes.TooMuchAngle.icDroneOpenYourDrone.image
        }
    }

    var mainDescription: String? {
        switch self {
        case .verticalCameraFailure:
            return L10n.takeoffAlertVerticalCameraDescription
        case .droneUpdateRequired:
            return L10n.takeoffAlertDroneUpdateDescription
        case .droneAndRemoteUpdateRequired:
            return L10n.takeoffAlertDroneRemoteUpdateDescription
        case .droneCalibrationRequired:
            return L10n.takeoffAlertCalibrationDescription
        case .highTemperature:
            return L10n.takeoffAlertHighTemperatureDescription
        case .lowTemperature:
            return L10n.takeoffAlertLowTemperatureDescription
        case .tooMuchAngle:
            return L10n.alertTooMuchAngleDescription
        }
    }

    var showCancelButton: Bool? {
        switch self {
        case .highTemperature,
             .lowTemperature,
             .verticalCameraFailure,
             .tooMuchAngle:
            return false
        default:
            return true
        }
    }

    var actionButtonTitle: String? {
        switch self {
        case .droneUpdateRequired,
             .droneAndRemoteUpdateRequired:
            return L10n.dashboardUpdate
        case .droneCalibrationRequired:
            return L10n.remoteCalibrationCalibrate
        case .highTemperature,
             .lowTemperature,
             .verticalCameraFailure,
             .tooMuchAngle:
            return L10n.ok
        }
    }

    var actionButtonTitleColor: ColorName? {
        switch self {
        case .verticalCameraFailure,
             .highTemperature,
             .tooMuchAngle,
             .lowTemperature:
            return .black
        case .droneUpdateRequired,
             .droneAndRemoteUpdateRequired,
             .droneCalibrationRequired:
            return .white
        }
    }

    var actionButtonBackgroundColor: ColorName? {
        switch self {
        case .verticalCameraFailure,
             .highTemperature,
             .tooMuchAngle,
             .lowTemperature:
            return .white
        case .droneUpdateRequired,
             .droneAndRemoteUpdateRequired,
             .droneCalibrationRequired:
            return .greenPea
        }
    }
}

/// Stores constants related to critical alerts on the HUD.
enum HUDCriticalAlertConstants {
    static let takeOffRequestedNotificationKey: String = "takeOffRequested"
}
