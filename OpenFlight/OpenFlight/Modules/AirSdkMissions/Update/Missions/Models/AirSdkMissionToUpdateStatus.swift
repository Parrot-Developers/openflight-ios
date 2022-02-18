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

// MARK: - Internal Enums
/// An enum to represent the status of a AirSdk mission that will be updated.
enum AirSdkMissionToUpdateStatus: Equatable {
    case notInUpdateList
    case waitingForUpdate
    case onGoingUpdate(AirSdkMissionToUpdateTask)
    case updateDone
    case failed(MissionUpdaterError)

    // MARK: - Equatable
    public static func == (lhs: AirSdkMissionToUpdateStatus,
                           rhs: AirSdkMissionToUpdateStatus) -> Bool {
        switch (lhs, rhs) {
        case (.notInUpdateList, notInUpdateList):
            return true
        case (.waitingForUpdate, waitingForUpdate):
            return true
        case (.onGoingUpdate(let lhsTask), onGoingUpdate(let rhsTask)):
            return lhsTask == rhsTask
        case (.updateDone, updateDone):
            return true
        case (.failed, failed):
            return true
        default:
            return false
        }
    }
}

// MARK: - Internal Funcs
extension AirSdkMissionToUpdateStatus {
    /// Returns the next `AirSdkMissionToUpdateStatus` for a given progress, a cancelable task, and  a given mission state.
    ///
    /// - Parameters:
    ///     - newMissionState: The state given by `AirSdkMissionsUpdaterWrapper`
    ///     - newProgress: The progress given by `AirSdkMissionsUpdaterWrapper`
    ///     - cancelableTask: a CancelableCore object given by `AirSdkMissionsUpdaterWrapper`.
    /// - Returns: The new `AirSdkMissionToUpdateStatus`.
    func nextStatus(for newMissionState: MissionUpdaterUploadState?,
                    newProgress: Int,
                    cancelableTask: CancelableCore?) -> AirSdkMissionToUpdateStatus {
        guard let newMissionState = newMissionState else { return self }

        switch newMissionState {
        case let .failed(error: error):
            return .failed(error)
        case .success:
            return .updateDone
        case .uploading:
            return .onGoingUpdate(AirSdkMissionToUpdateTask(task: cancelableTask,
                                                            progress: newProgress))
        }
    }

    /// The `CurrentUpdatingStep` for this `AirSdkMissionToUpdateStatus`.
    var updatingCase: CurrentUpdatingStep {
        return CurrentUpdatingStep(missionStatus: self)
    }
}
