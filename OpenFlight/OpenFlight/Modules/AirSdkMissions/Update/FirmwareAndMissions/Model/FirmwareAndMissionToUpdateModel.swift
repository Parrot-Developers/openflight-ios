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

import Foundation
import UIKit
import GroundSdk

// MARK: - Internal Enums
/// A model for firmware and missions update used in multiple views in the application.
enum FirmwareAndMissionToUpdateModel {
    case upToDate(firmwareVersion: String, isDroneConnected: Bool)
    case firmware(currentVersion: String, versionToUpdate: String, updateState: UpdateState)
    case singleMission(missionName: String)
    case missions
    case notInitialized

    /// Tells if any update is needed.
    var needUpdate: Bool {
        switch self {
        case .firmware,
             .singleMission,
             .missions:
            return true
        default:
            return false
        }
    }

    var updateRequired: Bool {
        switch self {
        case let .firmware(_, _, updateState):
            return updateState == .required
        default:
            return false
        }
    }

    // MARK: - Init
    /// Inits.
    ///
    /// - Parameters:
    ///   - firmwareToUpdateData: a `FirmwareToUpdateData`
    ///   - firmwareAndMissionsDataSource: a `DroneFirmwaresDataSource`
    ///   - isDroneConnected: a boolean to indicate if the drone is connected
    init(firmwareToUpdateData: FirmwareToUpdateData,
         firmwareAndMissionsDataSource: DroneFirmwaresDataSource,
         isDroneConnected: Bool) {
        if !firmwareToUpdateData.allOperationsNeeded.isEmpty {
            let needDownload = firmwareToUpdateData.allOperationsNeeded.contains(.download)
            if needDownload || isDroneConnected {
                self = .firmware(currentVersion: firmwareToUpdateData.firmwareVersion,
                                 versionToUpdate: firmwareToUpdateData.firmwareIdealVersion,
                                 updateState: firmwareToUpdateData.updateState)
            } else {
                self = .notInitialized
            }
        } else if !isDroneConnected {
            self = .notInitialized
        } else if firmwareAndMissionsDataSource.allPotentialMissionsToUpdate.isEmpty {
            self = .upToDate(firmwareVersion: firmwareToUpdateData.firmwareVersion, isDroneConnected: isDroneConnected)
        } else if firmwareAndMissionsDataSource.allPotentialMissionsToUpdate.count == 1,
                  let mission = firmwareAndMissionsDataSource.allPotentialMissionsToUpdate.first {
            self = .singleMission(missionName: mission.missionName)
        } else if firmwareAndMissionsDataSource.allPotentialMissionsToUpdate.count > 1 {
            self = .missions
        } else {
            self = .notInitialized
        }
    }
}

// MARK: - Internal Funcs
extension FirmwareAndMissionToUpdateModel {
    /// `DeviceDetailsButtonView` subtilte.
    var subtitle: String {
        switch self {
        case let .firmware(currentVersion, versionToUpdate, _):
            return String(format: "%@%@%@", currentVersion, Style.arrow, versionToUpdate)
        case let .singleMission(missionName: missionName):
            return missionName
        case .missions:
            return L10n.firmwareMissionUpdateMissions
        case let .upToDate(firmwareVersion, isDroneConnected):
            guard !isDroneConnected else { return firmwareVersion }
            fallthrough
        case .notInitialized:
            return Style.dash
        }
    }

    /// `DeviceDetailsButtonView` subImage.
    var subImage: UIImage? {
        switch self {
        case .upToDate(_, let isDroneConnected):
            guard !isDroneConnected else { return Asset.Common.Checks.icCheckedSmall.image }
            fallthrough
        default:
            return nil
        }
    }

    /// `DeviceDetailsButtonView` titleColor.
    var titleColor: ColorName {
        switch self {
        case .upToDate,
             .notInitialized:
            return .defaultTextColor
        case .firmware,
             .missions,
             .singleMission:
            return .white
        }
    }

    /// `DeviceDetailsButtonView` subimage tint color.
    var subImageTintColor: ColorName {
        switch self {
        case .upToDate(_, let isDroneConnected):
            guard !isDroneConnected else { return .highlightColor }
            fallthrough
        case .firmware,
             .missions,
             .singleMission,
             .notInitialized:
            return .white
        }
    }

    /// `DeviceDetailsButtonView` backgroundColor.
    var backgroundColor: ColorName {
        switch self {
        case .upToDate,
             .notInitialized:
            return .white
        case let .firmware(_, _, updateState):
            guard updateState == .recommended else { return .errorColor }
            fallthrough
        case .missions,
             .singleMission:
            return .warningColor
        }
    }

    /// `DeviceDetailsButtonView` isEnabled state
    var isEnabled: Bool {
        switch self {
        case .notInitialized:
            return false
        case let .upToDate(_, isDroneConnected):
            guard isDroneConnected else { return false }
            fallthrough
        default:
            return true
        }
    }
}

// MARK: - Internal Funcs
extension FirmwareAndMissionToUpdateModel {
    /// `DashboardDeviceCell` deviceStateButton title
    var stateButtonTitle: String {
        switch self {
        case .upToDate,
             .notInitialized:
            return ""
        case let .firmware(_, versionToUpdate, _):
            return versionToUpdate
        case let .singleMission(missionName: missionName):
            return missionName
        case .missions:
            return L10n.firmwareMissionUpdateMissions
        }
    }
}
