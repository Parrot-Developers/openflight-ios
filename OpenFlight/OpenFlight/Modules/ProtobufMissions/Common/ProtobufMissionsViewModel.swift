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

import GroundSdk
import SwiftProtobuf

// MARK: - ProtobufMissionsState
/// The states for `ProtobufMissionViewModel`.
final class ProtobufMissionsState: DeviceConnectionState {
    // MARK: - Private Properties
    fileprivate(set) var currentActiveMissionUID: String?
    fileprivate(set) var lastMessageReceived: ProtobufMissionMessageReceived?
    fileprivate(set) var suggestedActivationMissionUID: String?

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init the mission state.
    ///
    /// - Parameters:
    ///   - connectionState: The connection state
    ///   - currentActiveMissionUID: The mission UID
    ///   - lastMessageReceived: The last message received
    ///   - suggestedMissionActivation: Suggested mission activation
    init(connectionState: DeviceState.ConnectionState,
         currentActiveMissionUID: String?,
         lastMessageReceived: ProtobufMissionMessageReceived?,
         suggestedActivationMissionUID: String?) {
        super.init(connectionState: connectionState)

        self.currentActiveMissionUID = currentActiveMissionUID
        self.lastMessageReceived = lastMessageReceived
        self.suggestedActivationMissionUID = suggestedActivationMissionUID
    }

    // MARK: - EquatableState
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        // We want to be notifed of every single change in GroundSDK Mission manager,
        // even if they don't especially need to be monitored as "state" here.
        return false
    }

    // MARK: - Copying
    override func copy() -> ProtobufMissionsState {
        return ProtobufMissionsState(connectionState: self.connectionState,
                                     currentActiveMissionUID: self.currentActiveMissionUID,
                                     lastMessageReceived: self.lastMessageReceived,
                                     suggestedActivationMissionUID: self.suggestedActivationMissionUID
        )
    }
}

// MARK: - ProtobufMissionViewModel
/// The view model that handles protobuf missions. Don't use this model directly, use `ProtobufMissionsManager`.
final class ProtobufMissionsViewModel: DroneStateViewModel<ProtobufMissionsState> {
    // MARK: - Private Properties
    private var missionManagerRef: Ref<MissionManager>?
    private var missionManager: MissionManager?
    private let missionsToLoadAtDroneConnection: [ProtobufMissionSignature]

    // MARK: - Init
    /// Inits the view model.
    ///
    /// - Parameters:
    ///   - missionsToLoadAtDroneConnection: missions to load at the drone connection
    init(missionsToLoadAtDroneConnection: [ProtobufMissionSignature]) {
        self.missionsToLoadAtDroneConnection = missionsToLoadAtDroneConnection

        super.init()
    }

    // MARK: - Deinit
    deinit {
        self.missionManagerRef = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenProtobufMissions(drone: drone)
    }

    override func droneConnectionStateDidChange() {
        switch self.state.value.connectionState {
        case .connected:
            load(missions: missionsToLoadAtDroneConnection)
        case .connecting,
             .disconnecting,
             .disconnected:
            break
        }
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

        missionManager.packageNames.insert(mission.packageName)
        missionManager.activate(uid: mission.missionUID)
    }

    /// Deactivates the mission.
    ///
    /// - Parameters:
    ///     - mission: The mission to deactivate
    func deactivate(mission: ProtobufMissionSignature) {
        guard let missionManager = self.missionManager else { return }

        let missionState = state(for: mission)
        if state.value.currentActiveMissionUID != mission.missionUID ||
            missionState != .active {
            return
        }

        missionManager.packageNames.remove(mission.packageName)
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
        return self.state.value.suggestedActivationMissionUID == mission.missionUID
    }
}

// MARK: - Private Funcs
private extension ProtobufMissionsViewModel {
    /// Listens to the mission manager peripheral.
    ///
    /// - Parameters:
    ///     - drone: The drone
    func listenProtobufMissions(drone: Drone) {
        missionManagerRef = drone.getPeripheral(Peripherals.missionManager) { [unowned self] missionManager in
            guard let missionManager = missionManager else { return }

            self.updateCurrentActiveMissionUID(with: missionManager)
            self.update(lastMessageReceived: missionManager.latestMessage)
            self.update(suggestedActivation: missionManager.suggestedActivation)
            self.missionManager = missionManager
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
private extension ProtobufMissionsViewModel {
    /// Updates the state with the potiential current active mission.
    ///
    /// - Parameters:
    ///     - missionManager: The Mission Manager
    func updateCurrentActiveMissionUID(with missionManager: MissionManager) {
        let activeMission = missionManager.missions.first { (missionCouple) -> Bool in
            return missionCouple.value.state == .active
        }

        let copy = self.state.value.copy()
        copy.currentActiveMissionUID = activeMission?.key
        self.state.set(copy)
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

        let copy = self.state.value.copy()
        copy.lastMessageReceived = latestMessage
        self.state.set(copy)
    }

    /// Updates the state with the suggested mission to active.
    ///
    /// - Parameters:
    ///     - suggestedActivation: suggested activation mission UID
    func update(suggestedActivation: String?) {
        let copy = self.state.value.copy()
        copy.suggestedActivationMissionUID = suggestedActivation
        self.state.set(copy)
    }
}
