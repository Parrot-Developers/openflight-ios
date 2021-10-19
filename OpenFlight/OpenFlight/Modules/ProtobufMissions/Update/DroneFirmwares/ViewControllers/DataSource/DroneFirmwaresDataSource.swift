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

/// The data source of `DroneFirmwaresViewController` table view.
final class DroneFirmwaresDataSource {
    // MARK: - Internal Properties
    let elements: [FirmwareAndMissionUpdateChoice]
    let allPotentialMissionsToUpdate: [ProtobufMissionToUpdateData]
    let firmwareUpdateNeeded: Bool
    let isDroneConnected: Bool

    // MARK: - Init
    init() {
        elements = []
        allPotentialMissionsToUpdate = []
        firmwareUpdateNeeded = false
        isDroneConnected = false
    }

    /// Inits.
    ///
    /// - Parameters:
    ///     - firmwareToUpdateData: The firmware to update data
    ///     - allMissionsOnDrone: All missions on drone
    ///     - allMissionsOnFile: All missions on file
    ///     - isDroneConnected: a boolean to indicate if the drone is connected
    init(firmwareToUpdateData: FirmwareToUpdateData,
         allMissionsOnDrone: [ProtobufMissionBasicInformation],
         allMissionsOnFile: [ProtobufMissionToUpdateData],
         isDroneConnected: Bool) {

        var temporaryElements: [FirmwareAndMissionUpdateChoice] = [.firmware(firmwareToUpdateData)]
        var temporaryAllPotentialMissionsToUpdate: [ProtobufMissionToUpdateData] = []

        // Step one: Fill temporaryElements with missions to update and missions up to date that are present on the drone.
        for missionOnDrone in allMissionsOnDrone {
            guard let missionOnFile = allMissionsOnFile
                    .first(where: { $0.isSameAndGreaterVersion(of: missionOnDrone) }) else {
                temporaryElements.append(.upToDateProtobufMission(missionOnDrone))
                continue
            }

            temporaryElements.append(.protobufMission(missionOnFile,
                                                      existOnDrone: .exist(missionVersion: missionOnDrone.missionVersion),
                                                      isCompatible: missionOnFile.isCompatible(
                                                        with: firmwareToUpdateData.firmwareVersion)))
            temporaryAllPotentialMissionsToUpdate.append(missionOnFile)
        }

        // Step two: Fill temporaryElements with missions to update that are not present on the drone.
        for missionOnFile in allMissionsOnFile {
            if !allMissionsOnDrone.contains(where: { $0.missionUID == missionOnFile.missionUID }) {
                temporaryElements.append(.protobufMission(missionOnFile,
                                                          existOnDrone: .doesNotExist,
                                                          isCompatible: missionOnFile.isCompatible(
                                                            with: firmwareToUpdateData.firmwareVersion)))
                temporaryAllPotentialMissionsToUpdate.append(missionOnFile)
            }
        }

        temporaryElements.insert(
            .firmwareAndProtobufMissions(firmware: firmwareToUpdateData,
                                         missions: temporaryAllPotentialMissionsToUpdate),
            at: 0)

        temporaryElements.sort { $0 < $1 }
        elements = temporaryElements
        allPotentialMissionsToUpdate = temporaryAllPotentialMissionsToUpdate
        firmwareUpdateNeeded = !firmwareToUpdateData.allOperationsNeeded.isEmpty
        self.isDroneConnected = isDroneConnected
    }
}
