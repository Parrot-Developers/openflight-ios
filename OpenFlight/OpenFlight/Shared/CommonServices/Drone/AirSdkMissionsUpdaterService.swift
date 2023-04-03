//    Copyright (C) 2023 Parrot Drones SAS
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
import Combine

private extension ULogTag {
    static let tag = ULogTag(name: "AirSdkMissionsUpdaterService")
}

// MARK: - Internal Enums
enum AirSdkMissionsGlobalUpdatingState {
    case ongoing
    case uploading
    case done
}

// MARK: - Private Enums
private enum Constants {
    static let defaultProgress: Int = -1
}

public struct MissionToUpdate {
    var data: AirSdkMissionToUpdateData
    var status: AirSdkMissionToUpdateStatus
    var currentProgress: Int = Constants.defaultProgress
    var cancellableTask: CancelableTaskCore?
}

public protocol AirSdkMissionsUpdaterService {
    /// Current updating state
    var currentUpdatingStatePublisher: AnyPublisher<MissionUpdaterUploadState?, Never> { get }
    /// Missions to update
    var missionsToUpdatePublisher: AnyPublisher<[MissionToUpdate], Never> { get }

    /// Prepares the list of missions to update accroding to the user's choice.
    /// - Parameter updateChoice: The user's selection of updates
    func prepareMissionsUpdates(updateChoice: FirmwareAndMissionUpdateChoice)

    /// Starts the mission updates.
    /// - Parameter postone: `true` to postpone the installation until next reboot
    func startMissionsUpdateProcess(postpone: Bool)

    /// Checks if a reboot is required after the process.
    /// - Returns: `true` if reboot is needed.
    func missionsUpdateProcessNeedAReboot() -> Bool

    /// Check if there was an error during the update process.
    /// - Returns: `true` if there is an error.
    func missionsUpdateProcessHasError() -> Bool

    /// Cancels missions updates.
    /// - Parameter removeData: `true` to also empty the mission update list.
    func cancelAllMissionsUpdates(removeData: Bool) -> Bool

    /// Triggers a reboot by sending a `complete` order to the mission updater.
    func triggerManualReboot()

    /// Forces the missions updater to browse the current mission list.
    func manuallyBrowse()
}

public class AirSdkMissionsUpdaterServiceImpl {
    // MARK: - Private Properties
    /// AirSdkMissionsManager
    private var airSdkMissionsManager: AirSdkMissionsManager
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    // groundSdk core cancellables
    private(set) var cancellableTasks: [String: CancelableCore] = [:]
    /// Reference to the missionsUpdater peripheral.
    private var missionsUpdaterRef: Ref<MissionUpdater>?
    /// Mission updater subject.
    private var missionUpdaterSubject = CurrentValueSubject<MissionUpdater?, Never>(nil)
    /// The subject for the list of missions to update.
    private var missionsToUpdateSubject = CurrentValueSubject<[MissionToUpdate], Never>([])
    /// The subject for the current updating state
    private var currentUpdatingStateSubject = CurrentValueSubject<MissionUpdaterUploadState?, Never>(nil)
    /// Whether mission installation should be postponed until next reboot.
    private var postpone: Bool = false
    /// Current mission index to update
    private var currentMissionIndex: Int?

    // MARK: init
    /// Constructor.
    ///
    /// - Parameters:
    ///   - currentDroneHolder: drone holder
    public init(
        connectedDroneHolder: ConnectedDroneHolder,
        airSdkMissionsManager: AirSdkMissionsManager
    ) {
        self.airSdkMissionsManager = airSdkMissionsManager
        // listen to drone changes
        listen(dronePublisher: connectedDroneHolder.dronePublisher)
    }
}

// MARK: Private functions
private extension AirSdkMissionsUpdaterServiceImpl {
    /// Listens for the current drone.
    ///
    /// - Parameter dronePublisher: the drone publisher
    func listen(dronePublisher: AnyPublisher<Drone?, Never>) {
        dronePublisher.sink { [unowned self] drone in
            guard let drone = drone else { return }
            listenAirSdkMissionsUpdater(drone)
        }
        .store(in: &cancellables)
    }

    /// Listens to the `MissionsUpdater` peripheral.
    /// - Parameter drone: The current drone
    func listenAirSdkMissionsUpdater(_ drone: Drone) {
        missionsUpdaterRef = drone.getPeripheral(Peripherals.missionsUpdater) { [weak self] missionsUpdater in
            guard let missionsUpdater = missionsUpdater,
                  let self = self
            else { return }
            // update current mission progress
            self.missionUpdaterSubject.value = missionsUpdater
            if let index = self.missionsToUpdateSubject.value.firstIndex(where: {
                missionsUpdater.currentFilePath?.hasSuffix($0.data.missionFilePath) ?? false
            }) {
                self.currentMissionIndex = index
                var mission = self.missionsToUpdateSubject.value[index]
                mission.currentProgress = missionsUpdater.currentProgress ?? Constants.defaultProgress
                mission.status = mission.status.nextStatus(
                    for: missionsUpdater.state,
                    newProgress: mission.currentProgress,
                    cancelableTask: mission.cancellableTask)
                self.missionsToUpdateSubject.value[index] = mission
            } else {
                // Set the status for the last uploaded mission
                if let currentMissionIndex = self.currentMissionIndex, self.missionsToUpdateSubject.value.count > currentMissionIndex {
                    var mission = self.missionsToUpdateSubject.value[currentMissionIndex]
                    mission.status = mission.status.nextStatus(
                        for: missionsUpdater.state,
                        newProgress: mission.currentProgress,
                        cancelableTask: mission.cancellableTask)
                    self.missionsToUpdateSubject.value[currentMissionIndex] = mission
                }
            }

            // trigger next upload
            self.triggerNewUploadIfNeeded(missionsUpdater.state)
        }
    }

    /// Finds and starts the next mission upload.
    func startNextMissionUpload() {
        guard let missionToUpload = missionsToUpdateSubject.value.first(where: { $0.status == .waitingForUpdate}) else {
            ULog.i(.tag, "No more missions to update")
            return
        }
        ULog.i(.tag, "Starting next mission upload: \(missionToUpload.data.missionFilePath)")
        upload(filePath: missionToUpload.data.missionFilePath, overwrite: true, postpone: postpone)
    }

    /// Tells if the given mission is already uploaded.
    ///
    /// - Parameter mission: the mission to check
    func isAlreadyUploaded(_ mission: AirSdkMissionToUpdateData) -> Bool {
        return missionUpdaterSubject.value?.missions[mission.missionUID]?.version == mission.missionVersion
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
        guard let missionUpdater = missionUpdaterSubject.value else { return }
        ULog.i(.tag, "Start upload mission \(filePath)")
        guard let filePathURL = airSdkMissionsManager.url(ofMissionFileName: filePath) else {
            ULog.e(.tag, "MissionFilePath in embedded_missions_updates.plist can not be found")
            currentUpdatingStateSubject.value = .failed(error: MissionUpdaterError.badMissionFile)
            return
        }
        cancellableTasks[filePathURL.absoluteString] = missionUpdater.upload(
            filePath: filePathURL,
            overwrite: overwrite,
            postpone: postpone)
    }

    func triggerNewUploadIfNeeded(_ state: MissionUpdaterUploadState?) {
        guard let state = state else { return }
        switch state {
        case .failed,
             .success:
            startNextMissionUpload()
        case .uploading:
            break
        }
    }
}

// MARK: AirSdkMissionsUpdaterService protocol conformance
extension AirSdkMissionsUpdaterServiceImpl: AirSdkMissionsUpdaterService {
    public var missionUpdater: MissionUpdater? {
        missionUpdaterSubject.value
    }

    public var currentUpdatingStatePublisher: AnyPublisher<MissionUpdaterUploadState?, Never> {
        currentUpdatingStateSubject.eraseToAnyPublisher()
    }

    public var missionsToUpdatePublisher: AnyPublisher<[MissionToUpdate], Never> {
        missionsToUpdateSubject.eraseToAnyPublisher()
    }
    public func prepareMissionsUpdates(updateChoice: FirmwareAndMissionUpdateChoice) {
        self.cancellableTasks = [:]
        self.missionsToUpdateSubject.value = updateChoice.missionsToUpdate
            .map { missionData in
                let status: AirSdkMissionToUpdateStatus = isAlreadyUploaded(missionData) ? .updateDone : .waitingForUpdate
                return MissionToUpdate(data: missionData, status: status)
            }
    }

    /// Starts the update process.
    ///
    /// - Parameter postpone: postpone the installation until next reboot.
    public func startMissionsUpdateProcess(postpone: Bool) {
        ULog.i(.tag, "Starting missions update process")
        self.postpone = postpone
        startNextMissionUpload()
    }

    /// Triggers manual reboot.
    public func triggerManualReboot() {
        ULog.i(.tag, "Missions manual reboot triggered")
        guard let missionUpdater = missionUpdater else { return }
        missionUpdater.complete()
    }

    /// Manually browse the missions on drone.
    public func manuallyBrowse() {
        guard let missionUpdater = missionUpdater else { return }
        missionUpdater.browse()
    }

    /// Returns true if the mission update process requires a reboot.
    ///
    /// - Returns: True if the mission update process requires a reboot.
    public func missionsUpdateProcessNeedAReboot() -> Bool {
        return missionsToUpdateSubject.value.contains(where: { $0.status == .updateDone })
    }

    /// Returns true if the mission update process has errors.
    ///
    /// - Returns: True if the mission update process has errors.
    public func missionsUpdateProcessHasError() -> Bool {
        return missionsToUpdateSubject.value.contains(where: { mission in
            switch mission.status {
            case .failed:
                return true
            case .notInUpdateList, .onGoingUpdate, .updateDone, .waitingForUpdate:
                return false
            }
        })
    }

    /// Cancels and cleans all potentials updates.
    ///
    /// - Parameters:
    ///    - removeData: set to`true` to also empty the mission update list.
    /// - Returns: `true` if the operation was successful.
    public func cancelAllMissionsUpdates(removeData: Bool) -> Bool {
        var canCancel = true
        missionsToUpdateSubject.value.forEach { mission in
            if case .onGoingUpdate(let missionUpdateTask) = mission.status {
                if let task = missionUpdateTask.task {
                    task.cancel()
                } else {
                    // Cancellation impossible.
                    canCancel = false
                }
            }
        }
        if canCancel && removeData {
            missionsToUpdateSubject.value.removeAll()
        }
        return canCancel
    }
}
