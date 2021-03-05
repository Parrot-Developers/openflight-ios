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

import Foundation
import UIKit
import GroundSdk

// MARK: - Internal Enums
/// A model for firmware and missions update used in multiple views in the application.
enum FirmwareAndMissionToUpdateModel {
    case upToDate(firmwareVersion: String)
    case firmware(currentVersion: String, versionToUpdate: String)
    case singleMission(missionName: String)
    case missions
    case notInitialized

    // MARK: - Init
    /// Inits.
    ///
    /// - Parameters:
    ///   - firmwareToUpdateData: a `FirmwareToUpdateData`
    ///   - firmwareAndMissionsDataSource: a `ProtobufMissionsUpdateDataSource`
    init(firmwareToUpdateData: FirmwareToUpdateData,
         firmwareAndMissionsDataSource: ProtobufMissionsUpdateDataSource) {
        if !firmwareToUpdateData.allOperationsNeeded.isEmpty {
            self = .firmware(currentVersion: firmwareToUpdateData.firmwareVersion,
                             versionToUpdate: firmwareToUpdateData.firmwareIdealVersion)
        } else if firmwareAndMissionsDataSource.allPotentialMissionsToUpdate.isEmpty {
            self = .upToDate(firmwareVersion: firmwareToUpdateData.firmwareVersion)
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
    /// `DroneDetailsButtonView` subtilte.
    var subtitle: String {
        switch self {
        case let .upToDate(firmwareVersion: firmwareVersion):
            return firmwareVersion
        case let .firmware(currentVersion: currentVersion, versionToUpdate: _):
            return currentVersion
        case let .singleMission(missionName: missionName):
            return missionName
        case .missions:
            return L10n.firmwareMissionUpdateMissions
        case .notInitialized:
            return ""
        }
    }

    /// `DroneDetailsButtonView` complementarySubtitle.
    var complementarySubtitle: String? {
        switch self {
        case .upToDate:
            return nil
        case let .firmware(currentVersion: _, versionToUpdate: versionToUpdate):
            return String(format: "%@%@", Style.arrow, versionToUpdate)
        case .singleMission:
            return nil
        case .missions:
            return nil
        case .notInitialized:
            return nil
        }
    }

    /// `DroneDetailsButtonView` subImage.
    var subImage: UIImage {
        switch self {
        case .upToDate:
            return Asset.Common.Checks.iconCheck.image
        case .firmware:
            return Asset.Dashboard.icupdate.image
        case .singleMission:
            return Asset.Dashboard.icupdate.image
        case .missions:
            return Asset.Dashboard.icupdate.image
        case .notInitialized:
            return Asset.Common.Checks.iconCheck.image
        }
    }

    /// `DroneDetailsButtonView` backgroundColor.
    var backgroundColor: ColorName {
        switch self {
        case .upToDate:
            return .white10
        case .firmware:
            return .greenSpring20
        case .singleMission:
            return .greenSpring20
        case .missions:
            return .greenSpring20
        case .notInitialized:
            return .white10
        }
    }
}

// MARK: - Internal Funcs
extension FirmwareAndMissionToUpdateModel {
    /// `DashboardDeviceCell` stateDeviceLabel text
    func stateDeviceLabelText(deviceConnectionState: DeviceState.ConnectionState) -> String {
        switch self {
        case .upToDate:
            return deviceConnectionState == .disconnected ?
                deviceConnectionState.title : ""
        case let .firmware(currentVersion: _, versionToUpdate: versionToUpdate):
            return versionToUpdate
        case let .singleMission(missionName: missionName):
            return missionName
        case .missions:
            return L10n.firmwareMissionUpdateMissions
        case .notInitialized:
            return ""
        }
    }

    /// `DashboardDeviceCell` stateDeviceLabel textColor.
    func stateDeviceLabelTextColor(deviceConnectionState: DeviceState.ConnectionState) -> UIColor {
        switch self {
        case .upToDate:
            return deviceConnectionState == .disconnected ?
                ColorName.white50.color : ColorName.greenSpring.color
        case .firmware:
            return ColorName.greenSpring20.color
        case .singleMission:
            return ColorName.greenSpring20.color
        case .missions:
            return ColorName.greenSpring20.color
        case .notInitialized:
            return ColorName.white50.color
        }
    }
}
