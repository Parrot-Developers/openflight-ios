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
import GroundSdk

// MARK: - ProtobufMissionsUpdaterManager
/// This manager manages all protobuf missions updates.
final class ProtobufMissionsUpdaterManager {
    // MARK: - Internal Properties
    /// This manager is a singleton.
    static let shared = ProtobufMissionsUpdaterManager()
    /// The list of missions to update.
    let missionsToUpdateList = ProtobufMissionsToUpdateList()

    // MARK: - Private Properties
    /// The global listener.
    private var globalListener: ProtobufAllMissionsUpdaterListener?
    /// The current listeners.
    private var listeners: Set<ProtobufMissionUpdaterListener> = []
    /// The model that gets notified to GroundSDK `MissionUpdater` updates.
    private lazy var protobufMissionsUpdaterWrapper: ProtobufMissionsUpdaterWrapper = {
        let wrapper = ProtobufMissionsUpdaterWrapper()
        wrapper.state.valueChanged = { (protobufMissionUpdateState) in
            self.protobufMissionUpdateCallback(protobufMissionUpdateState: protobufMissionUpdateState)
        }

        return wrapper
    }()

    // MARK: - Init
    private init() {}
}

// MARK: - Internal Funcs
extension ProtobufMissionsUpdaterManager {
    /// Call this function once in the life cycle of the application to start to listen to GroundSDK `MissionUpdater`.
    func setup() {
        _ = protobufMissionsUpdaterWrapper
    }

    /// Prepare the updates.
    ///
    /// - Parameters:
    ///    - updateChoice:The current update choice
    func prepareMissionsUpdates(updateChoice: FirmwareAndMissionUpdateChoice) {
        protobufMissionsUpdaterWrapper.resetMissionsUpdater()

        updateChoice.missionsToUpdate.forEach { (mission) in
            let missionToUpdateViewModel = ProtobufMissionUpdateViewModel(missionToUpdateData: mission)
            addToWaitingList(mission: missionToUpdateViewModel)
        }
    }

    /// Starts the update process.
    func startMissionsUpdateProcess() {
        return startNextMissionUpload()
    }

    /// Triggers manual reboot.
    func triggerManualReboot() {
        protobufMissionsUpdaterWrapper.triggerManualReboot()
    }

    /// Returns true if the mission update process requires a reboot.
    ///
    /// - Returns: True if the mission update process requires a reboot.
    func missionsUpdateProcessNeedAReboot() -> Bool {
        return missionsToUpdateList.missionsUpdateProcessNeedAReboot()
    }

    /// Returns true if the mission update process has errors.
    ///
    /// - Returns: True if the mission update process has errors.
    func missionsUpdateProcessHasError() -> Bool {
        return missionsToUpdateList.missionsUpdateProcessHasError()
    }

    /// Cancels and cleans all potentials updates.
    ///
    /// - Parameters:
    ///    - removeData:A boolean to indication if we remove data.
    /// - Returns: True if the operation was successful.
    func cancelAllMissionsUpdates(removeData: Bool) -> Bool {
        let success = missionsToUpdateList.cancelAllUpdates()
        if success && removeData {
            missionsToUpdateList.removeAll()
        }

        return success
    }

    /// Adds a mission to the list of missions to update.
    ///
    /// - Parameters:
    ///    - mission: The `ProtobufMissionUpdateViewModel` to add to the list of updates
    func addToWaitingList(mission: ProtobufMissionUpdateViewModel) {
        missionsToUpdateList.add(missionToAdd: mission)

        for listener in listeners
        where listener.missionToUpdateData == mission.missionToUpdateData {
            listener.missionToUpdateCallback(.waitingForUpdate)
        }
    }

    /// Deletes a mission.
    ///
    /// - Parameters:
    ///    - mission: The mission to delete
    ///    - success: true if the deletion was successfull, else false
    func delete(mission: ProtobufMissionSignature,
                success: @escaping (Bool) -> Void) {
        protobufMissionsUpdaterWrapper.delete(mission: mission,
                                              success: success)
    }

    /// Manually browse the missions on drone.
    func manuallyBrowse() {
        protobufMissionsUpdaterWrapper.manuallyBrowse()
    }
}

/// Utils for listener management.
extension ProtobufMissionsUpdaterManager {
    /// Registers a listener for a specific mission.
    ///
    /// - Parameters:
    ///   - missionToUpdate: The mission to listen to
    ///   - missionToUpdateCallback: The callback triggered for any event related to the mission's update
    /// - Returns: The listener.
    func register(for missionToUpdateData: ProtobufMissionToUpdateData,
                  missionToUpdateCallback: @escaping ProtobufMissionUpdaterClosure) -> ProtobufMissionUpdaterListener {
        let listener = ProtobufMissionUpdaterListener(missionToUpdateData: missionToUpdateData,
                                                      missionToUpdateCallback: missionToUpdateCallback)
        listeners.insert(listener)

        if let missionToUpdate = missionsToUpdateList.associatedMission(for: missionToUpdateData) {
            listener.missionToUpdateCallback(missionToUpdate.state.value.missionToUpdateStatus)
        } else {
            listener.missionToUpdateCallback(.notInUpdateList)
        }

        return listener
    }

    /// Unregisters a listener.
    ///
    /// - Parameters:
    ///     - listener: The listener to unregister
    func unregister(_ listener: ProtobufMissionUpdaterListener?) {
        if let listener = listener {
            listeners.remove(listener)
        }
    }

    /// Registers a listener for all missions.
    ///
    /// - Parameters:
    ///   - allMissionToUpdateCallback: The callback that will be trigger when a change occurs during  all the missions upload.
    /// - Returns: The listener.
    func registerGlobalListener(allMissionToUpdateCallback: @escaping ProtobufAllMissionsUpdaterClosure) {
        globalListener = ProtobufAllMissionsUpdaterListener(allMissionToUpdateCallback: allMissionToUpdateCallback)
        globalListener?.allMissionToUpdateCallback(missionsToUpdateList.protobufMissionsGlobalState())
    }

    /// Unregisters a listener.
    func unregisterGlobalListener() {
        globalListener = nil
    }
}

// MARK: - Private Funcs
private extension ProtobufMissionsUpdaterManager {
    /// Triggers all listeners callbacks.
    ///
    /// - Parameters:
    ///     - protobufMissionUpdateState: The state given by `ProtobufMissionsUpdaterWrapper`
    func protobufMissionUpdateCallback(protobufMissionUpdateState: ProtobufMissionsUpdaterState) {

        for listener in listeners {
            guard let missionToUpdate = missionsToUpdateList.associatedMission(for: listener.missionToUpdateData) else {
                // Case one: The listener's mission is not in the update list.
                continue
            }

            let currentUpdatingFilePath = protobufMissionUpdateState.currentUpdatingFilePath
            guard listener.missionToUpdateData.missionFilePathAsInGroundSDKMissionUpdater == currentUpdatingFilePath else {
                // Case two: The listener's mission is not the one being proceeded.
                continue
            }

            // Case three: The listener's mission is the one being proceeded.
            let currentProgress = protobufMissionUpdateState.currentUpdatingProgress
            let currentUpdatingState = protobufMissionUpdateState.currentUpdatingState
            let currentMissionToUpdateStatus = missionToUpdate.state.value.missionToUpdateStatus
            let currentCancelableTask: CancelableCore?
            if let currentUpdatingFilePath = currentUpdatingFilePath {
                currentCancelableTask = protobufMissionsUpdaterWrapper.cancelableTasks[currentUpdatingFilePath]
            } else {
                currentCancelableTask = nil
            }

            let newMissionToUpdateStatus = currentMissionToUpdateStatus.nextStatus(
                for: currentUpdatingState,
                newProgress: currentProgress,
                cancelableTask: currentCancelableTask)

            listener.missionToUpdateCallback(newMissionToUpdateStatus)
        }

        triggerNewUploadIfNeed(for: protobufMissionUpdateState.currentUpdatingState)
        globalListener?.allMissionToUpdateCallback(missionsToUpdateList.protobufMissionsGlobalState())
    }

    /// Triggers a new upload if the current upload is done.
    ///
    /// - Parameters:
    ///   - currentUpdatingState: The state of the current upload
    func triggerNewUploadIfNeed(for currentUpdatingState: MissionUpdaterUploadState?) {
        guard let currentUpdatingState = currentUpdatingState else { return }

        switch currentUpdatingState {
        case .failed,
             .success:
            startNextMissionUpload()
        case .uploading:
            break
        }
    }

    /// Finds and starts the next download.
    func startNextMissionUpload() {
        guard let missionToUpdate = missionsToUpdateList.nextMissionToUpdate() else {
            globalListener?.allMissionToUpdateCallback(missionsToUpdateList.protobufMissionsGlobalState())
            return
        }

        protobufMissionsUpdaterWrapper.upload(
            filePath: missionToUpdate.missionToUpdateData.missionFilePath,
            overwrite: true)
    }
}
