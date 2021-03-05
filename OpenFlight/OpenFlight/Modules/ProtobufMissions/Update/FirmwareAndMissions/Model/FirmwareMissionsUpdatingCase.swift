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
import Reusable

// MARK: - Internal Enums
/// All cases for a `ProtobufMissionUpdatingTableViewCell` configuration.
enum FirmwareMissionsUpdatingCase: Equatable {
    case mission(CurrentUpdatingStep, ProtobufMissionToUpdateData)
    case downloadingFirmware(CurrentUpdatingStep)
    case updatingFirmware(CurrentUpdatingStep)
    case reboot(CurrentUpdatingStep)

    // MARK: - Equatable
    public static func == (lhs: FirmwareMissionsUpdatingCase,
                           rhs: FirmwareMissionsUpdatingCase) -> Bool {
        switch (lhs, rhs) {
        case (let .mission(lhsUpdatingStep, lhsMissionToUpdate),
              let .mission(rhsUpdatingStep, rhsMissionToUpdate)):
            return lhsUpdatingStep == rhsUpdatingStep
                && lhsMissionToUpdate == rhsMissionToUpdate
        case (let .downloadingFirmware(lhsUpdatingStep),
              let .downloadingFirmware(rhsUpdatingStep)):
            return lhsUpdatingStep == rhsUpdatingStep
        case (let .updatingFirmware(lhsUpdatingStep),
              let .updatingFirmware(rhsUpdatingStep)):
            return lhsUpdatingStep == rhsUpdatingStep
        case (let .reboot(lhsUpdatingStep), let .reboot(rhsUpdatingStep)):
            return lhsUpdatingStep == rhsUpdatingStep
        default:
            return false
        }
    }
}

// MARK: - Internal Properties
extension FirmwareMissionsUpdatingCase {
    /// The updating label text.
    var missionUpdatingLabelText: String {
        switch self {
        case let .mission(_, mission):
            return L10n.firmwareMissionUpdateUpdatingMission(mission.missionName)
        case .downloadingFirmware:
            return L10n.firmwareMissionUpdateDownloadingFirmware
        case .updatingFirmware:
            return L10n.firmwareMissionUpdateSendingToDrone
        case .reboot:
            return L10n.firmwareMissionUpdateRebootAndUpdate
        }
    }
}
