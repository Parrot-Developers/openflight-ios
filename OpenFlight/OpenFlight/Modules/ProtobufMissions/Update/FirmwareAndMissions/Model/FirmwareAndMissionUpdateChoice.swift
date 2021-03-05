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

// MARK: - Internal Enums
/// Represents the choice of the user for an update process.
enum FirmwareAndMissionUpdateChoice: Comparable {
    case firmwareAndProtobufMissions(firmware: FirmwareToUpdateData,
                                     missions: [ProtobufMissionToUpdateData])
    case protobufMission(ProtobufMissionToUpdateData,
                         existOnDrone: ProtobufMissionExistOnDrone)
    case upToDateProtobufMission(ProtobufMissionBasicInformation)
    case firmware(FirmwareToUpdateData)

    // MARK: - Comparable
    static func == (lhs: FirmwareAndMissionUpdateChoice,
                    rhs: FirmwareAndMissionUpdateChoice) -> Bool {
        switch (lhs, rhs) {
        case (.firmwareAndProtobufMissions, .firmwareAndProtobufMissions):
            return true
        case (.firmware, .firmware):
            return true
        case (let .protobufMission(mission1, existOnDrone: _),
              let .protobufMission(mission2, existOnDrone: _)):
            return mission1.missionUID == mission2.missionUID
        default:
            return false
        }
    }

    static func < (lhs: FirmwareAndMissionUpdateChoice,
                   rhs: FirmwareAndMissionUpdateChoice) -> Bool {
        switch (lhs, rhs) {
        case (.firmwareAndProtobufMissions, _):
            return true
        case (.firmware, .protobufMission):
            return true
        case (let .protobufMission(mission1, existOnDrone: _),
              let .protobufMission(mission2, existOnDrone: _)):
            return mission1.missionName < mission2.missionName
        default:
            return false
        }
    }
}

/// Represents the functional choice of the user for an update process.
enum FirmwareAndMissionUpdateFunctionalChoice {
    case firmwareAndProtobufMissions
    case firmware
    case protobufMissions
}

/// An util enum to store if a mission exists on the drone and its potential version on the drone.
enum ProtobufMissionExistOnDrone {
    case doesNotExist
    case exist(missionVersion: String)
}

// MARK: - Internal Properties
extension FirmwareAndMissionUpdateChoice {
    /// Returns the `FirmwareToUpdateData` for this choice.
    var firmwareToUpdate: FirmwareToUpdateData? {
        switch self {
        case let .firmware(firmwareToUpdate):
            return firmwareToUpdate
        case let .firmwareAndProtobufMissions(firmware: firmwareToUpdate, missions: _):
            return firmwareToUpdate
        case .upToDateProtobufMission:
            return nil
        case .protobufMission:
            return nil
        }
    }

    /// Returns the `ProtobufMissionToUpdateData` array  for this choice.
    var missionsToUpdate: [ProtobufMissionToUpdateData] {
        switch self {
        case .firmware:
            return []
        case let .firmwareAndProtobufMissions(firmware: _, missions: missionsToUpdate):
            return missionsToUpdate
        case .upToDateProtobufMission:
            return []
        case let .protobufMission(mission, existOnDrone: _):
            return [mission]
        }
    }

    /// Returns true if the Firmware needs to be updated for this choice.
    var needToUpdateFirmware: Bool {
        switch self {
        case .firmware,
             .firmwareAndProtobufMissions:
            return true
        case .upToDateProtobufMission,
             .protobufMission:
            return false
        }
    }

    /// Title font.
    var titleFont: UIFont {
        switch self {
        case .firmwareAndProtobufMissions:
            return ParrotFontStyle.small.font
        case .firmware:
            return ParrotFontStyle.regular.font
        case .protobufMission:
            return ParrotFontStyle.regular.font
        case .upToDateProtobufMission:
            return ParrotFontStyle.regular.font
        }
    }

    /// Title color.
    var titleColor: UIColor {
        switch self {
        case .firmwareAndProtobufMissions:
            return ColorName.white50.color
        case .firmware:
            return ColorName.white.color
        case .protobufMission:
            return ColorName.white.color
        case .upToDateProtobufMission:
            return ColorName.white.color
        }
    }

    /// Button border color.
    var buttonBorderColor: UIColor {
        switch self {
        case .firmwareAndProtobufMissions:
            return .clear
        case .firmware:
            return ColorName.white.color
        case .protobufMission:
            return ColorName.white.color
        case .upToDateProtobufMission:
            return .clear
        }
    }

    /// Button tint color.
    var buttonTintColor: UIColor {
        switch self {
        case .firmwareAndProtobufMissions:
            return ColorName.greenSpring.color
        case .firmware:
            return ColorName.white.color
        case .protobufMission:
            return ColorName.white.color
        case .upToDateProtobufMission:
            return .clear
        }
    }

    /// Button background color.
    var buttonBackgroundColor: UIColor {
        switch self {
        case .firmwareAndProtobufMissions:
            return ColorName.greenPea50.color
        case .firmware:
            return ColorName.greyShark.color
        case .protobufMission:
            return ColorName.greyShark.color
        case .upToDateProtobufMission:
            return .clear
        }
    }
}
