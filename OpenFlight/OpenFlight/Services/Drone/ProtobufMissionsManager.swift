//
//  Copyright (C) 2021 Parrot Drones SAS.
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

public protocol ProtobufMissionsManager: AnyObject {

    var currentActiveMissionUID: AnyPublisher<String?, Never> { get }
    var lastMessageReceived: AnyPublisher<ProtobufMissionMessageReceived?, Never> { get }
    var suggestedActivationMissionUID: AnyPublisher<String?, Never> { get }

    func load(mission: ProtobufMissionSignature)
    func unload(mission: ProtobufMissionSignature)
    func activate(mission: ProtobufMissionSignature)
    func deactivate(mission: ProtobufMissionSignature)
    func sendMessage(message: ProtobufMissionMessageToSend)
    func state(for mission: ProtobufMissionSignature) -> MissionState
    func isActivationSuggested(_ mission: ProtobufMissionSignature) -> Bool
    func getMissionToLoadAtStart() -> [ProtobufMissionSignature]

}

final class ProtobufMissionsManagerImpl {

    // MARK: - Published Properties

    var currentActiveMissionUIDSubject = CurrentValueSubject<String?, Never>(nil)
    var lastMessageReceivedSubject = CurrentValueSubject<ProtobufMissionMessageReceived?, Never>(nil)
    var suggestedActivationMissionUIDSubject = CurrentValueSubject<String?, Never>(nil)

    // MARK: - Private properties

    private var connectedDroneHolder: ConnectedDroneHolder
    private var cancellables = Set<AnyCancellable>()
    private var missionManagerRef: Ref<MissionManager>?
    private var missionManager: MissionManager?
    private let missionsToLoadAtDroneConnection: [ProtobufMissionSignature]

    init(connectedDroneHolder: ConnectedDroneHolder, missionsToLoadAtDroneConnection: [ProtobufMissionSignature]) {
        self.connectedDroneHolder = connectedDroneHolder
        self.missionsToLoadAtDroneConnection = missionsToLoadAtDroneConnection

        connectedDroneHolder.dronePublisher
            .removeDuplicates()
            .sink { [unowned self] drone in
                if let drone = drone {
                    listenProtobufMissions(drone: drone)
                    load(missions: missionsToLoadAtDroneConnection)
                }
            }
            .store(in: &cancellables)
    }

    /// Loads the mission.
    ///
    /// - Parameters:
    ///     - mission: The mission to load
    func load(mission: ProtobufMissionSignature) {
        guard let missionManager = self.missionManager else { return }

        missionManager.load(uid: mission.missionUID)
    }

    /// Unloads the mission.
    ///
    /// - Parameters:
    ///     - mission: The mission to unload
    func unload(mission: ProtobufMissionSignature) {
        guard let missionManager = self.missionManager else { return }

        missionManager.unload(uid: mission.missionUID)
    }

    /// Activates the mission.
    /// The mission must be in idle state to be activated.
    ///
    /// - Parameters:
    ///     - mission: The mission to activate
    func activate(mission: ProtobufMissionSignature) {
        guard let missionManager = self.missionManager,
              let missionState = missionManager.missions
                .first(where: { $0.value.uid == mission.missionUID })?
                .value.state,
              missionState == .idle else {
            return
        }

        missionManager.activate(uid: mission.missionUID)
    }

    /// Deactivates the mission.
    ///
    /// - Parameters:
    ///     - mission: The mission to deactivate
    func deactivate(mission: ProtobufMissionSignature) {
        guard let missionManager = self.missionManager else { return }

        let missionState = state(for: mission)
        if currentActiveMissionUIDSubject.value != mission.missionUID ||
            missionState != .active {
            return
        }

        missionManager.deactivate()
    }

    /// Sends a protobuf message to the drone.
    ///
    /// - Parameters:
    ///     - message: The message to send
    func sendMessage(message: ProtobufMissionMessageToSend) {
        guard let missionManager = self.missionManager else { return }

        missionManager.send(message: message)
    }

    /// Returns a state of a given mission.
    ///
    /// - Parameters:
    ///     - mission: The mission
    /// - Returns: The state of the given mission.
    func state(for mission: ProtobufMissionSignature) -> MissionState {
        guard let missionManager = self.missionManager else { return .unavailable }

        return missionManager.missions[mission.missionUID]?.state ?? .unavailable
    }

    /// Returns true if a mission is suggested to be activated.
    ///
    /// - Parameters:
    ///     - mission: The mission
    /// - Returns: true if the mission activation is suggested.
    func isActivationSuggested(_ mission: ProtobufMissionSignature) -> Bool {
        return suggestedActivationMissionUIDSubject.value == mission.missionUID
    }
}

// MARK: - Private Funcs
private extension ProtobufMissionsManagerImpl {
    /// Listens to the mission manager peripheral.
    ///
    /// - Parameters:
    ///     - drone: The drone
    func listenProtobufMissions(drone: Drone) {
        missionManagerRef = drone.getPeripheral(Peripherals.missionManager) { [unowned self] manager in
            self.missionManager = manager
            guard let missionManager = manager else {
                return
            }
            updateCurrentActiveMissionUID(with: missionManager)
            update(lastMessageReceived: missionManager.latestMessage)
            update(suggestedActivation: missionManager.suggestedActivation)
        }
    }

    /// Loads the missions.
    ///
    /// - Parameters:
    ///     - missions: The missions to load
    func load(missions: [ProtobufMissionSignature]) {
        missions.forEach({ load(mission: $0) })
    }

    /// Unloads the missions.
    ///
    /// - Parameters:
    ///     - missions: The missions to unload
    func unload(missions: [ProtobufMissionSignature]) {
        missions.forEach({ unload(mission: $0) })
    }
}

/// Utils for updating states of `ProtobufMissionsState`.
private extension ProtobufMissionsManagerImpl {
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
        var latestMessage: ProtobufMissionMessageReceived?
        if let missionMessage = lastMessageReceived {
            latestMessage = ProtobufMissionMessageReceived(missionMessage: missionMessage)
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
}

extension ProtobufMissionsManagerImpl: ProtobufMissionsManager {
    func getMissionToLoadAtStart() -> [ProtobufMissionSignature] {
        return missionsToLoadAtDroneConnection
    }

    var currentActiveMissionUID: AnyPublisher<String?, Never> { currentActiveMissionUIDSubject.eraseToAnyPublisher()}
    var lastMessageReceived: AnyPublisher<ProtobufMissionMessageReceived?, Never> { lastMessageReceivedSubject.eraseToAnyPublisher() }
    var suggestedActivationMissionUID: AnyPublisher<String?, Never> { suggestedActivationMissionUIDSubject.eraseToAnyPublisher() }
}
