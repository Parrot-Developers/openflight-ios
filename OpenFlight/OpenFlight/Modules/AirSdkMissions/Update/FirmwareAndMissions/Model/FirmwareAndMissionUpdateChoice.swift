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

// MARK: - Internal Enums
/// Represents the choice of the user for an update process.
enum FirmwareAndMissionUpdateChoice: Comparable {
    case firmwareAndAirSdkMissions(firmware: FirmwareToUpdateData,
                                   missions: [AirSdkMissionToUpdateData])
    case airSdkMission(AirSdkMissionToUpdateData,
                       missionOnDrone: AirSdkMissionBasicInformation?,
                       compatibility: FirmwareCompatibility)
    case upToDateAirSdkMission(AirSdkMissionBasicInformation,
                               isLastBuiltIn: Bool = false)
    case firmware(FirmwareToUpdateData)

    // MARK: - Comparable
    static func == (lhs: FirmwareAndMissionUpdateChoice,
                    rhs: FirmwareAndMissionUpdateChoice) -> Bool {
        switch (lhs, rhs) {
        case (.firmwareAndAirSdkMissions, .firmwareAndAirSdkMissions):
            return true
        case (.firmware, .firmware):
            return true
        case (let .airSdkMission(mission1, missionOnDrone: _, compatibility: _),
              let .airSdkMission(mission2, missionOnDrone: _, compatibility: _)):
            return mission1.missionUID == mission2.missionUID
        default:
            return false
        }
    }

    static func < (lhs: FirmwareAndMissionUpdateChoice,
                   rhs: FirmwareAndMissionUpdateChoice) -> Bool {
        switch (lhs, rhs) {
        case (.firmwareAndAirSdkMissions, _):
            return true
        case (_, .firmwareAndAirSdkMissions):
            return false
        case (.firmware, _):
            return true
        case (_, .firmware):
            return false
        case (.upToDateAirSdkMission, .airSdkMission):
            return true
        case (.airSdkMission, .upToDateAirSdkMission):
            return false
        case (let .upToDateAirSdkMission(mission1, _), let .upToDateAirSdkMission(mission2, _)):
            if mission1.isBuiltIn != mission2.isBuiltIn {
                return mission1.isBuiltIn
            } else {
                return mission1.missionUID < mission2.missionUID
            }
        case (let .airSdkMission(mission1, missionOnDrone: _, compatibility: _),
              let .airSdkMission(mission2, missionOnDrone: _, compatibility: _)):
            return mission1.missionUID < mission2.missionUID
        default:
            return false
        }
    }
}

/// Represents the functional choice of the user for an update process.
enum FirmwareAndMissionUpdateFunctionalChoice {
    case firmwareAndAirSdkMissions
    case firmware
    case airSdkMissions
}

// MARK: - Internal Properties
extension FirmwareAndMissionUpdateChoice {
    /// Returns the `FirmwareToUpdateData` for this choice.
    var firmwareToUpdate: FirmwareToUpdateData? {
        switch self {
        case let .firmware(firmwareToUpdate):
            return firmwareToUpdate
        case let .firmwareAndAirSdkMissions(firmware: firmwareToUpdate, missions: _):
            return firmwareToUpdate
        case .upToDateAirSdkMission:
            return nil
        case .airSdkMission:
            return nil
        }
    }

    /// Returns the `AirSdkMissionToUpdateData` array for this choice.
    var missionsToUpdate: [AirSdkMissionToUpdateData] {
        switch self {
        case .firmware:
            return []
        case let .firmwareAndAirSdkMissions(firmware: _, missions: missionsToUpdate):
            return missionsToUpdate
        case .upToDateAirSdkMission:
            return []
        case let .airSdkMission(mission, missionOnDrone: _, compatibility: _):
            return [mission]
        }
    }

    /// Returns true if the Firmware needs to be updated for this choice.
    var needToUpdateFirmware: Bool {
        switch self {
        case .firmware,
             .firmwareAndAirSdkMissions:
            return true
        case .upToDateAirSdkMission,
             .airSdkMission:
            return false
        }
    }

    /// Title font.
    var titleFont: UIFont {
        switch self {
        case .firmwareAndAirSdkMissions:
            return ParrotFontStyle.small.font
        case .firmware,
             .airSdkMission,
             .upToDateAirSdkMission:
            return ParrotFontStyle.large.font
        }
    }

    /// Title color.
    var titleColor: UIColor {
        switch self {
        case .firmwareAndAirSdkMissions:
            return ColorName.defaultTextColor80.color
        case .firmware:
            return ColorName.defaultTextColor.color
        case let .airSdkMission(_, missionOnDrone, _):
            return missionOnDrone?.isCompatible != false ?
                ColorName.defaultTextColor.color : ColorName.disabledTextColor.color
        case let .upToDateAirSdkMission(missionOnDrone, _):
            return missionOnDrone.isCompatible ? ColorName.defaultTextColor.color : ColorName.disabledTextColor.color
        }
    }
}
