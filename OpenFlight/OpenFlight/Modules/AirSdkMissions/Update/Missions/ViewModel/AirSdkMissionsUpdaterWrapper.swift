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

import GroundSdk
import SwiftProtobuf

// MARK: - Private Enums
private enum Constants {
    static let defaultProgress: Int = -1
}

// MARK: - AirSdkMissionsUpdaterState
/// The states for `AirSdkMissionsUpdaterWrapper`.
final class AirSdkMissionsUpdaterState: DeviceConnectionState {
    // MARK: - Private Properties
    fileprivate(set) var currentUpdatingProgress: Int = Constants.defaultProgress
    fileprivate(set) var currentUpdatingState: MissionUpdaterUploadState?
    fileprivate(set) var currentUpdatingFilePath: String?
    fileprivate(set) var allMissionsOnDrone: [AirSdkMissionBasicInformation] = []

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init the states.
    ///
    /// - Parameters:
    ///   - connectionState: The connection state
    ///   - currentUpdatingProgress: The current progress
    ///   - currentUpdatingFilePath: The current updating file's path
    ///   - currentUpdatingState: The current updating state
    ///   - allMissionsOnDrone: All missions on drone
    init(connectionState: DeviceState.ConnectionState,
         currentUpdatingProgress: Int,
         currentUpdatingFilePath: String?,
         currentUpdatingState: MissionUpdaterUploadState?,
         allMissionsOnDrone: [AirSdkMissionBasicInformation]) {
        super.init(connectionState: connectionState)

        self.currentUpdatingProgress = currentUpdatingProgress
        self.currentUpdatingFilePath = currentUpdatingFilePath
        self.currentUpdatingState = currentUpdatingState
        self.allMissionsOnDrone = allMissionsOnDrone
    }

    // MARK: - EquatableState
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? AirSdkMissionsUpdaterState else { return false }

        return super.isEqual(to: other)
            && self.currentUpdatingProgress == other.currentUpdatingProgress
            && self.currentUpdatingFilePath == other.currentUpdatingFilePath
            && self.currentUpdatingState == other.currentUpdatingState
            && self.allMissionsOnDrone == other.allMissionsOnDrone
    }

    // MARK: - Copying
    override func copy() -> AirSdkMissionsUpdaterState {
        return AirSdkMissionsUpdaterState(connectionState: self.connectionState,
                                          currentUpdatingProgress: self.currentUpdatingProgress,
                                          currentUpdatingFilePath: self.currentUpdatingFilePath,
                                          currentUpdatingState: self.currentUpdatingState,
                                          allMissionsOnDrone: self.allMissionsOnDrone)
    }
}

// MARK: - AirSdkMissionsUpdaterWrapper
/// The view model that handles AirSdk missions updates. Don't use this model directly, use `AirSdkMissionsUpdaterManager`.
final class AirSdkMissionsUpdaterWrapper: DroneStateViewModel<AirSdkMissionsUpdaterState> {
    // MARK: - Internal Properties
    private(set) var cancelableTasks: [String: CancelableCore] = [:]

    // MARK: - Private Properties
    private var missionManagerRef: Ref<MissionManager>?
    private var missionsUpdaterRef: Ref<MissionUpdater>?
    private var missionsUpdater: MissionUpdater?
    private var isFirstTimeListeningToMissionUpdater = true

    // MARK: - Deinit
    deinit {
        self.missionsUpdaterRef = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenAirSdkMissionsManager(drone: drone)
        listenAirSdkMissionsUpdater(drone: drone)
    }

    override func droneConnectionStateDidChange() {
        super.droneConnectionStateDidChange()
        reinitFirstTimeListeningToMissionUpdater()
    }

    func reinitFirstTimeListeningToMissionUpdater() {
        if drone?.isConnected == false {
            isFirstTimeListeningToMissionUpdater = true
        }
    }

    /// Resets the missions updater
    func resetMissionsUpdater() {
        self.cancelableTasks = [:]
        resetState()
    }

    /// Triggers manual reboot.
    func triggerManualReboot() {
        ULog.d(.missionUpdateTag, "Missions manual reboot triggered")
        guard let missionsUpdater = self.missionsUpdater else { return }

        missionsUpdater.complete()
    }

    /// Tells if the given mission is already uploaded.
    ///
    /// - Parameter mission: the mission to check
    func isAlreadyUploaded(_ mission: AirSdkMissionToUpdateData) -> Bool {
        return missionsUpdater?.missions[mission.missionUID]?.version == mission.missionVersion
    }

    /// Uploads a mission to the server.
    ///
    /// - Parameters:
    ///    - filePath: The file path of the mission to upload
    ///    - overwrite: overwrite the mission if it is present on drone
    ///    - postpone: postpone the installation until next reboot
    func upload(filePath: String,
                overwrite: Bool,
                postpone: Bool) {
        guard let missionsUpdater = self.missionsUpdater else { return }
        ULog.d(.missionUpdateTag, "Start upload mission \(filePath)")

        guard let filePathURL = AirSdkMissionsToUploadFinder.url(ofMissionFileName: filePath) else {
            ULog.e(.missionUpdateTag, "MissionFilePath in embedded_missions_updates.plist can not be found")
            update(currentUpdatingState: .failed(error: MissionUpdaterError.badMissionFile),
                   currentUpdatingFilePath: filePath)
            return
        }

        cancelableTasks[filePathURL.absoluteString] = missionsUpdater.upload(filePath: filePathURL,
                                                                             overwrite: overwrite,
                                                                             postpone: postpone)
    }

    /// Manually browse the missions on drone.
    func manuallyBrowse() {
        guard let missionsUpdater = self.missionsUpdater else {
            return
        }

        missionsUpdater.browse()
    }

    /// Deletes a mission.
    ///
    /// - Parameters:
    ///    - mission:The mission to delete
    ///    - success:callback: returns true if the delete was successfull, else false
    func delete(mission: AirSdkMissionSignature,
                success: @escaping (Bool) -> Void) {
        guard let missionsUpdater = self.missionsUpdater else {
            success(false)
            return
        }

        missionsUpdater.delete(uid: mission.missionUID) { (result) in
            // Just a secure browse if the GroundSDK does not do it itself after a successful deletion.
            missionsUpdater.browse()
            success(result)
        }
    }
}

// MARK: - Private Funcs
private extension AirSdkMissionsUpdaterWrapper {
    /// Listens to the `MissionsManager` peripheral.
    func listenAirSdkMissionsManager(drone: Drone) {
        missionManagerRef = drone.getPeripheral(Peripherals.missionManager) { [weak self] missionManager in
            guard let self = self,
                  let missionManager = missionManager else {
                      return
                  }
            self.updateAllMissions(missionManager: missionManager)
        }
    }

    /// Listens to the `MissionsUpdater` peripheral.
    func listenAirSdkMissionsUpdater(drone: Drone) {
        missionsUpdaterRef = drone.getPeripheral(Peripherals.missionsUpdater) { [weak self] missionsUpdater in
            guard let missionsUpdater = missionsUpdater,
                  let strongSelf = self
            else {
                return
            }

            self?.missionsUpdater = missionsUpdater
            strongSelf.initMissionsInMissionUpdater()
            strongSelf.updateAllStates(missionUpdater: missionsUpdater)
        }
    }

    /// Inits the `missions` property in the GroundSDK `MissionsUpdater`.
    func initMissionsInMissionUpdater() {
        guard let missionsUpdater = missionsUpdater else { return }

        if isFirstTimeListeningToMissionUpdater {
            missionsUpdater.browse()
            isFirstTimeListeningToMissionUpdater = false
        }
    }
}

/// Utils for updating states of `AirSdkMissionsUpdaterState`.
private extension AirSdkMissionsUpdaterWrapper {
    /// Updates all missions on drone.
    ///
    /// - Note: we want to get all missions that are fully installed and activable, so we use `MissionManager` instead
    ///         of `MissionUpdater` which reports missions uploaded on the drone but not necessarily fully installed.
    ///
    /// - Parameters:
    ///     - missionManager: The `MissionManager`
    func updateAllMissions(missionManager: MissionManager) {
        let copy = self.state.value.copy()
        copy.allMissionsOnDrone = missionManager.missions.values
            .filter { $0.uid != OFMissionSignatures.defaultMission.missionUID }
            .map { (mission) -> AirSdkMissionBasicInformation in
                return AirSdkMissionBasicInformation(missionUID: mission.uid,
                                                     missionVersion: mission.version)
            }
        self.state.set(copy)
    }

    /// Updates all the states.
    ///
    /// - Parameters:
    ///     - missionUpdater: The `MissionUpdater`
    func updateAllStates(missionUpdater: MissionUpdater) {
        let copy = self.state.value.copy()

        copy.currentUpdatingState = missionUpdater.state
        copy.currentUpdatingProgress = missionUpdater.currentProgress ?? -1

        if let currentUpdatingFilePath = missionUpdater.currentFilePath,
           !currentUpdatingFilePath.isEmptyOrWhitespace {
            copy.currentUpdatingFilePath = currentUpdatingFilePath
        }

        self.state.set(copy)
        let stateValue = String(describing: state.value.currentUpdatingState)
        let progressValue = state.value.currentUpdatingProgress
        let pathValue = String(describing: state.value.currentUpdatingFilePath)
        ULog.d(.missionUpdateTag, "Missions update state: \(stateValue), progress: \(progressValue), file path: \(pathValue)")
    }

    /// Updates the state.
    ///
    /// - Parameters:
    ///     - currentUpdatingState: The current updating state
    ///     - currentUpdatingFilePath: The current updating file path
    func update(currentUpdatingState: MissionUpdaterUploadState,
                currentUpdatingFilePath: String) {
        let copy = self.state.value.copy()
        copy.currentUpdatingState = currentUpdatingState
        copy.currentUpdatingFilePath = currentUpdatingFilePath
        self.state.set(copy)
    }

    /// Resets the updater state.
    func resetState() {
        let copy = self.state.value.copy()
        copy.currentUpdatingProgress = Constants.defaultProgress
        copy.currentUpdatingState = nil
        copy.currentUpdatingFilePath = nil
        copy.allMissionsOnDrone = []
        self.state.set(copy)
    }
}
