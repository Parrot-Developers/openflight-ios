//    Copyright (C) 2021 Parrot Drones SAS
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
import Combine
import GroundSdk
import SwiftProtobuf

public protocol AirSdkMissionsManager: AnyObject {
    var currentActiveMissionUID: AnyPublisher<String?, Never> { get }
    var lastMessageReceived: AnyPublisher<AirSdkMissionMessageReceived?, Never> { get }
    var suggestedActivationMissionUID: AnyPublisher<String?, Never> { get }
    var allMissionsOnDronePublisher: AnyPublisher<[AirSdkMissionBasicInformation], Never> { get }
    var allPotentialMissionsToUpdatePublisher: AnyPublisher<[AirSdkMissionToUpdateData], Never> { get }
    func load(mission: AirSdkMissionSignature)
    func unload(mission: AirSdkMissionSignature)
    func activate(mission: AirSdkMissionSignature)
    func deactivate(mission: AirSdkMissionSignature)
    func sendMessage(message: AirSdkMissionMessageToSend)
    func state(for mission: AirSdkMissionSignature) -> MissionState
    func unavailabilityReason(for missionUid: String) -> MissionUnavailabilityReason
    func isActivationSuggested(_ mission: AirSdkMissionSignature) -> Bool
    func url(ofMissionFileName missionFileName: String) -> URL?
    func allAirSdkMissionsOnFiles() -> [AirSdkMissionToUpdateData]
    func getMissionToLoadAtStart() -> [AirSdkMissionSignature]
    func getMissionName(uid: String) -> String?
    func getLocalizedMissionName(uid: String) -> String?
    func isPresentable(_ missionProvider: MissionProvider) -> Bool
    func isSelectable(_ missionProvider: MissionProvider) -> Bool
}

final class AirSdkMissionsManagerImpl {

    private enum Constants {
        static let airSdkMissionsPlistName: String = "embedded_missions_updates"
        static let airSdkMissionsPlistExtension: String = "plist"
        static let airSdkMissionsPlistDirectory: String = "embedded_missions"
    }

    // MARK: - Internal Properties
    var currentActiveMissionUIDSubject = CurrentValueSubject<String?, Never>(nil)
    var lastMessageReceivedSubject = CurrentValueSubject<AirSdkMissionMessageReceived?, Never>(nil)
    var suggestedActivationMissionUIDSubject = CurrentValueSubject<String?, Never>(nil)
    var allMissionsOnDroneSubject = CurrentValueSubject<[AirSdkMissionBasicInformation], Never>([])
    var allPotentialMissionsToUpdateSubject = CurrentValueSubject<[AirSdkMissionToUpdateData], Never>([])

    // MARK: - Private properties
    private var connectedDroneHolder: ConnectedDroneHolder
    private var cancellables = Set<AnyCancellable>()
    private var missionManagerRef: Ref<MissionManager>?
    private var systemInfoRef: Ref<SystemInfo>?
    private var missionManager: MissionManager?
    private let missionsToLoadAtDroneConnection: [AirSdkMissionSignature]
    private var missionToActivate: String?
    private var firmwareVersion: String?

    init(connectedDroneHolder: ConnectedDroneHolder, missionsToLoadAtDroneConnection: [AirSdkMissionSignature]) {
        self.connectedDroneHolder = connectedDroneHolder
        self.missionsToLoadAtDroneConnection = missionsToLoadAtDroneConnection

        connectedDroneHolder.dronePublisher
            .removeDuplicates()
            .sink { [unowned self] drone in
                guard let drone = drone else { return }
                listenSystemInfo(drone)
                listenAirSdkMissions(drone)
            }
            .store(in: &cancellables)
    }

    /// Loads the mission.
    ///
    /// - Parameters:
    ///     - mission: The mission to load
    func load(mission: AirSdkMissionSignature) {
        guard let missionManager = self.missionManager else { return }

        missionManager.load(uid: mission.missionUID)
    }

    /// Unloads the mission.
    ///
    /// - Parameters:
    ///     - mission: The mission to unload
    func unload(mission: AirSdkMissionSignature) {
        guard let missionManager = self.missionManager else { return }

        missionManager.unload(uid: mission.missionUID)
    }

    /// Activates the mission.
    /// The mission must be in idle state to be activated.
    ///
    /// - Parameters:
    ///     - mission: The mission to activate
    func activate(mission: AirSdkMissionSignature) {
        guard let missionManager = self.missionManager else { return }

        let missionState = missionManager.missions
                .first(where: { $0.value.uid == mission.missionUID })?
                .value.state
        guard missionState == .idle else {
            if missionState == .unloaded {
                missionToActivate =  mission.missionUID
             }
            return
        }

        missionToActivate = nil
        missionManager.activate(uid: mission.missionUID)
    }

    /// Deactivates the mission.
    ///
    /// - Parameters:
    ///     - mission: The mission to deactivate
    func deactivate(mission: AirSdkMissionSignature) {
        guard let missionManager = self.missionManager else { return }

        let missionState = state(for: mission)
        if currentActiveMissionUIDSubject.value != mission.missionUID ||
            missionState != .active {
            return
        }

        missionManager.deactivate()
    }

    /// Sends a airsdk message to the drone.
    ///
    /// - Parameters:
    ///     - message: The message to send
    func sendMessage(message: AirSdkMissionMessageToSend) {
        guard let missionManager = self.missionManager else { return }

        missionManager.send(message: message)
    }

    /// Returns a state of a given mission.
    ///
    /// - Parameters:
    ///     - mission: The mission
    /// - Returns: The state of the given mission.
    func state(for mission: AirSdkMissionSignature) -> MissionState {
        guard let drone = connectedDroneHolder.drone,
              let missionManager = drone.getPeripheral(Peripherals.missionManager),
              let mission = missionManager.missions[mission.missionUID]
        else { return .unavailable }
        return mission.state
    }

    /// Returns the unavailability reason of a given mission.
    ///
    /// - Parameters:
    ///     - missionUid: The mission UID
    /// - Returns: The unavailability reason of the specified mission.
    func unavailabilityReason(for missionUid: String) -> MissionUnavailabilityReason {
        return missionManager?.missions[missionUid]?.unavailabilityReason ?? .none
    }

    /// Returns true if a mission is suggested to be activated.
    ///
    /// - Parameters:
    ///     - mission: The mission
    /// - Returns: true if the mission activation is suggested.
    func isActivationSuggested(_ mission: AirSdkMissionSignature) -> Bool {
        return suggestedActivationMissionUIDSubject.value == mission.missionUID
    }

    /// Returns true if a mission can be displayed.
    ///
    /// - Parameters:
    ///     - missionProvider: The mission provider
    /// - Returns: true if the mission can be displayed.
    func isPresentable(_ missionProvider: MissionProvider) -> Bool {
        // when not connected to drone the mission should be available
        guard let drone = connectedDroneHolder.drone,
              drone.isConnected else { return true }

        // when connected to the drone the mission should be presentable only if installed and its
        // installation is required.
        return missionProvider.mission.defaultMode.isInstallationRequired
        ? isInstalled(mission: missionProvider.signature)
        : true
    }

    /// Returns true if a mission can be selected.
    ///
    /// - Parameters:
    ///     - missionProvider: The mission provider
    /// - Returns: true if the mission can be selected.
    func isSelectable(_ missionProvider: MissionProvider) -> Bool {
        // when not connected to drone the mission should be selectable
        guard let drone = connectedDroneHolder.drone,
              drone.isConnected else { return true }

        // when connected to the drone the mission should be selectable only if loaded or active and
        // its installation is required.
        guard missionProvider.mission.defaultMode.isInstallationRequired else { return true }
        switch state(for: missionProvider.signature) {
        case .unavailable,
             .unloaded:
            return false
        case .idle,
             .activating,
             .active:
            return true
        }
    }
}

// MARK: - Private Funcs
private extension AirSdkMissionsManagerImpl {

    /// Listens to the `SystemInfo` peripheral.
    /// - Parameter drone: The drone
    func listenSystemInfo(_ drone: Drone) {
        systemInfoRef = drone.getPeripheral(Peripherals.systemInfo) { [unowned self] systemInfo in
            firmwareVersion = systemInfo?.firmwareVersion
        }
    }

    /// Listens to the mission manager peripheral.
    /// - Parameter drone: The drone
    func listenAirSdkMissions(_ drone: Drone) {
        missionManagerRef = drone.getPeripheral(Peripherals.missionManager) { [unowned self] manager in
            self.missionManager = manager
            guard let missionManager = manager else {
                return
            }
            load(missions: missionsToLoadAtDroneConnection)
            updateCurrentActiveMissionUID(with: missionManager)
            update(lastMessageReceived: missionManager.latestMessage)
            update(suggestedActivation: missionManager.suggestedActivation)
            updateMissionsOnDrone(missionManager: missionManager)
            updatePotentialMissionUpdates(missionManager: missionManager)
            activateMissionAskedIfNecessary(with: missionManager)
        }
    }

    /// Loads the missions.
    ///
    /// - Parameters:
    ///     - missions: The missions to load
    func load(missions: [AirSdkMissionSignature]) {
        guard let missionManager = missionManager else { return }
        missions.forEach({
            if missionManager.missions[$0.missionUID] != nil && missionManager.missions[$0.missionUID]?.state == .unloaded {
                load(mission: $0)
            }
        })
    }

    /// Unloads the missions.
    ///
    /// - Parameters:
    ///     - missions: The missions to unload
    func unload(missions: [AirSdkMissionSignature]) {
        missions.forEach({ unload(mission: $0) })
    }
}

/// Utils for updating states of airsdk missions.
private extension AirSdkMissionsManagerImpl {
    /// Updates the state with the potiential current active mission.
    ///
    /// - Parameters:
    ///     - missionManager: The Mission Manager
    func updateCurrentActiveMissionUID(with missionManager: MissionManager) {
        let activeMission = missionManager.missions.first { (missionCouple) -> Bool in
            return missionCouple.value.state == .active
        }

        currentActiveMissionUIDSubject.value = activeMission?.key
    }

    /// Updates the state with the potiential last message received.
    ///
    /// - Parameters:
    ///     - lastMessageReceived: The last message received
    func update(lastMessageReceived: MissionMessage?) {
        var latestMessage: AirSdkMissionMessageReceived?
        if let missionMessage = lastMessageReceived {
            latestMessage = AirSdkMissionMessageReceived(missionMessage: missionMessage)
        }

        lastMessageReceivedSubject.value = latestMessage
    }

    /// Updates the state with the suggested mission to active.
    ///
    /// - Parameters:
    ///     - suggestedActivation: suggested activation mission UID
    func update(suggestedActivation: String?) {
        suggestedActivationMissionUIDSubject.value = suggestedActivation
    }

    /// Updates the allMissionsOnDrone value
    ///
    /// - Parameters:
    ///     - missionManager: the current mission manager
    func updateMissionsOnDrone(missionManager: MissionManager) {
        allMissionsOnDroneSubject.value = missionManager.missions.values
            .filter { $0.uid != OFMissionSignatures.defaultMission.missionUID }
            .map { (mission) -> AirSdkMissionBasicInformation in
                let isBuiltIn = missionsToLoadAtDroneConnection
                    .first(where: { $0.missionUID == mission.uid })?
                    .isBuiltIn ?? false
                let isCompatible = unavailabilityReason(for: mission.uid) != .broken
                let localizedName = getLocalizedMissionName(uid: mission.uid) ?? mission.name
                return AirSdkMissionBasicInformation(missionUID: mission.uid,
                                                     missionName: localizedName,
                                                     missionVersion: mission.version,
                                                     isBuiltIn: isBuiltIn,
                                                     isCompatible: isCompatible)
            }
    }

    func updatePotentialMissionUpdates(missionManager: MissionManager) {
        guard let firmwareVersion = firmwareVersion else { return }
        let allMissionsOnFile = allAirSdkMissionsOnFiles()
        var temporaryAllPotentialMissionsToUpdate: [AirSdkMissionToUpdateData] = []
        // Step one: apppend missions to update and missions up to date that are present on the drone.
        for missionOnDrone in allMissionsOnDroneSubject.value {
            let missionOnFile = allMissionsOnFile.first(where: { $0.isSameAndGreaterVersion(of: missionOnDrone) })
            let compatibility = missionOnFile?.compatibility(with: firmwareVersion)
            if let missionOnFile = missionOnFile,
               let compatibility = compatibility,
               compatibility != .tooRecent {
                temporaryAllPotentialMissionsToUpdate.append(missionOnFile)
            }
        }
        // Step two: Fill temporaryElements with missions to update that are not present on the drone.
        for missionOnFile in allMissionsOnFile {
            let compatibility = missionOnFile.compatibility(with: firmwareVersion)

            if !allMissionsOnDroneSubject.value.contains(where: { $0.missionUID == missionOnFile.missionUID }) &&
                compatibility != .tooRecent {
                temporaryAllPotentialMissionsToUpdate.append(missionOnFile)
            }
        }
        allPotentialMissionsToUpdateSubject.value = temporaryAllPotentialMissionsToUpdate
    }

    /// Activate last mission asked if it is necessary.
    ///
    /// - Parameters:
    ///     - missionManager: The Mission Manager
    func activateMissionAskedIfNecessary(with missionManager: MissionManager) {
        if let missionToActivate = missionToActivate,
           let missionState = missionManager.missions
            .first(where: { $0.value.uid == missionToActivate })?.value.state,
           missionState == .idle {
            self.missionToActivate = nil
            missionManager.activate(uid: missionToActivate)
        }
    }

    /// Returns true if a mission is installed.
    ///
    /// - Parameters:
    ///     - mission: The mission
    /// - Returns: true if the mission is installed.
    func isInstalled(mission: AirSdkMissionSignature) -> Bool {
        guard let drone = connectedDroneHolder.drone,
              let missionManager = drone.getPeripheral(Peripherals.missionManager) else { return true }
        return missionManager.missions.contains { $0.value.uid == mission.missionUID }
    }
}

extension AirSdkMissionsManagerImpl: AirSdkMissionsManager {
    var currentActiveMissionUID: AnyPublisher<String?, Never> { currentActiveMissionUIDSubject.eraseToAnyPublisher()}
    var lastMessageReceived: AnyPublisher<AirSdkMissionMessageReceived?, Never> { lastMessageReceivedSubject.eraseToAnyPublisher() }
    var suggestedActivationMissionUID: AnyPublisher<String?, Never> { suggestedActivationMissionUIDSubject.eraseToAnyPublisher() }
    var allMissionsOnDronePublisher: AnyPublisher<[AirSdkMissionBasicInformation], Never> {
        allMissionsOnDroneSubject.eraseToAnyPublisher()
    }
    var allPotentialMissionsToUpdatePublisher: AnyPublisher<[AirSdkMissionToUpdateData], Never> {
        allPotentialMissionsToUpdateSubject.eraseToAnyPublisher()
    }

    /// Fetchs the name of a mission
    ///
    /// - Parameters:
    ///     - uid: The mission uid
    /// - Returns: The mission name
    func getMissionName(uid: String) -> String? {
        return missionManager?.missions[uid]?.name
    }

    /// Fetchs the localized name of a mission if available.
    ///
    /// - Parameters:
    ///     - uid: The mission uid
    /// - Returns: The localized mission name if available
    func getLocalizedMissionName(uid: String) -> String? {
        missionsToLoadAtDroneConnection.first(
            where: { $0.missionUID == uid }
        )?.name
    }

    func getMissionToLoadAtStart() -> [AirSdkMissionSignature] {
        return missionsToLoadAtDroneConnection
    }

    /// Returns an URL pointing in the main bundle for a given file name.
    ///
    /// - Parameters:
    ///    - missionFilePath: The mission file name, prefixed by the containing folder and suffixed
    ///      by the file name extension.
    /// - Returns: An URL pointing in the main bundle for the given file name or `nil` if the
    ///   requested file name can not be found in the main bundle.
    func url(ofMissionFileName missionFileName: String) -> URL? {
        // The extension is included in the missionFileName.
        guard let url = Bundle.main.url(forResource: missionFileName, withExtension: nil) else {
            return nil
        }

        return url
    }

    /// Returns all AirSdk missions on the file system.
    ///
    /// - Returns: The list of  all AirSdk missions to update.
    func allAirSdkMissionsOnFiles() -> [AirSdkMissionToUpdateData] {
        guard let url = Bundle.main.url(forResource: Constants.airSdkMissionsPlistName,
                                        withExtension: Constants.airSdkMissionsPlistExtension,
                                        subdirectory: Constants.airSdkMissionsPlistDirectory) else {
            ULog.e(.missionUpdateTag,
                   "Missing \(Constants.airSdkMissionsPlistDirectory)/"
                    + "\(Constants.airSdkMissionsPlistName)."
                    + "\(Constants.airSdkMissionsPlistExtension) in main bundle.")
            assert(false)
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = PropertyListDecoder()
            do {
                var missions = try decoder.decode([AirSdkMissionToUpdateData].self, from: data)
                missions = missions.map {  mission in
                    var newMission = mission
                        newMission.missionName = getLocalizedMissionName(uid: mission.missionUID)
                    return newMission
                }
                return missions
            } catch {
                ULog.e(.missionUpdateTag,
                       "Decoding \(Constants.airSdkMissionsPlistDirectory)/"
                        + "\(Constants.airSdkMissionsPlistName)."
                        + "\(Constants.airSdkMissionsPlistExtension) failed: \(error).")
                assert(false)
            }
        } catch {
            ULog.e(.missionUpdateTag,
                   "Reading \(Constants.airSdkMissionsPlistDirectory)/"
                    + "\(Constants.airSdkMissionsPlistName)."
                    + "\(Constants.airSdkMissionsPlistExtension) failed: \(error)")
            assert(false)
        }
        return []
    }
}
