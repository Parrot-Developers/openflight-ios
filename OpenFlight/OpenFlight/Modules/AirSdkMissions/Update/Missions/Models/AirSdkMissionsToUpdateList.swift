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
import GroundSdk

/// The list that contains the on going updates of AirSdk mission.
final class AirSdkMissionsToUpdateList {
    // MARK: - Internal Properties
    private(set) var missionsToUpdateArray: [AirSdkMissionUpdateViewModel] = []
}

// MARK: - Internal Funcs
extension AirSdkMissionsToUpdateList {
    /// Adds a mission to the list.
    ///
    /// - Parameters:
    ///    - missionToAdd: The `AirSdkMissionUpdateViewModel`to add to the list
    func add(missionToAdd: AirSdkMissionUpdateViewModel) {
        if missionsToUpdateArray.contains(missionToAdd) { return }
        missionsToUpdateArray.append(missionToAdd)
    }

    /// Removes all missions from the list.
    func removeAll() {
        missionsToUpdateArray.removeAll()
    }

    /// Finds  a AirSdk mission in the list.
    ///
    /// - Parameters:
    ///    - missionToUpdateData: The `AirSdkMissionToUpdateData` to find in the list
    /// - Returns: The associated `AirSdkMissionUpdateViewModel`.
    func associatedMission(for missionToUpdateData: AirSdkMissionToUpdateData) -> AirSdkMissionUpdateViewModel? {
        return missionsToUpdateArray.first { (missionToUpdate) -> Bool in
            missionToUpdate.missionToUpdateData == missionToUpdateData
        }
    }

    /// Finds the next AirSdk mission to update.
    ///
    /// - Returns: The associated `AirSdkMissionUpdateViewModel`.
    func nextMissionToUpdate() -> AirSdkMissionUpdateViewModel? {
        return missionsToUpdateArray.first { (missionToUpdate) -> Bool in
            switch missionToUpdate.state.value.missionToUpdateStatus {
            case .waitingForUpdate:
                return true
            case .notInUpdateList,
                 .updateDone,
                 .failed,
                 .onGoingUpdate:
                return false
            }
        }
    }

    /// Cancels all potentials updates.
    ///
    /// - Returns: True if the operation was successful.
    func cancelAllUpdates() -> Bool {
        var success = true
        let missions = missionsToUpdateArray
        for mission in missions {
            success = success && mission.cancelAirSdkMissionUpdate()
        }

        return success
    }

    /// Returns the number of elements in the list.
    ///
    /// - Returns: the number of elements in the list.
    func count() -> Int {
        return missionsToUpdateArray.count
    }

    /// Returns true if the list is empty.
    ///
    /// - Returns: True if the list is empty.
    func isEmpty() -> Bool {
        return missionsToUpdateArray.isEmpty
    }

    /// Returns true if a mission was updated.
    ///
    /// - Returns: True if a mission was updated.
    func missionsUpdateProcessNeedAReboot() -> Bool {
        return missionsToUpdateArray.contains { (missionToUpdate) -> Bool in
            switch missionToUpdate.state.value.missionToUpdateStatus {
            case .updateDone:
                return true
            case .notInUpdateList,
                 .waitingForUpdate,
                 .failed,
                 .onGoingUpdate:
                return false
            }
        }
    }

    /// Returns the global state for the current list.
    ///
    /// - Returns: The global state for the current list.
    func airSdkMissionsGlobalState() -> AirSdkMissionsGlobalUpdatingState {
        let globalState: AirSdkMissionsGlobalUpdatingState
        let uploading = missionsToUpdateArray.contains {
            switch $0.state.value.missionToUpdateStatus {
            case .onGoingUpdate:
                return true
            default:
                return false
            }
        }

        if uploading {
            globalState = .uploading
        } else {
            let waiting = missionsToUpdateArray.contains { $0.state.value.missionToUpdateStatus == .waitingForUpdate }
            globalState = waiting ? .ongoing : .done
        }
        ULog.d(.missionUpdateTag, "Missions global state: \(globalState)")

        return globalState
    }

    /// Returns true if the list contains errors.
    ///
    /// - Returns: True if the list contains errors.
    func missionsUpdateProcessHasError() -> Bool {
        return missionsToUpdateArray.contains { (missionToUpdate) -> Bool in
            switch missionToUpdate.state.value.missionToUpdateStatus {
            case .waitingForUpdate,
                 .onGoingUpdate,
                 .notInUpdateList,
                 .updateDone:
                return false
            case .failed:
                return true
            }
        }
    }
}
