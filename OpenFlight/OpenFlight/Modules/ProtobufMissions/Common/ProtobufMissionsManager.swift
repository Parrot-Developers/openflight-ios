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

// MARK: - ProtobufMissionsManager
/// This manager manages all protobuf missions.
public final class ProtobufMissionsManager {
    // MARK: - Public Properties
    /// This manager is a singleton.
    public static let shared = ProtobufMissionsManager()

    // MARK: - Private Properties
    /// The current listeners.
    private var listeners: Set<ProtobufMissionListener> = []
    private let missionLauncher = MissionLauncherViewModel()

    /// Missions to load at the drone connection.
    public var missionsToLoadAtDroneConnection: [ProtobufMissionSignature] = [
        OFMissionSignatures.helloWorld
    ]

    /// The model that gets notified to GroundSDK Mission Manager updates.
    private lazy var protobufMissionViewModel: ProtobufMissionsViewModel = {
        let viewModel = ProtobufMissionsViewModel(missionsToLoadAtDroneConnection: self.missionsToLoadAtDroneConnection)
        viewModel.state.valueChanged = { (protobufMissionListState) in
            self.protobufMissionCallback(protobufMissionState: protobufMissionListState)
        }

        return viewModel
    }()

    // MARK: - Init
    private init() {}
}

// MARK: - Public Funcs
public extension ProtobufMissionsManager {
    /// Call this function once in the life cycle of the application to start to listen to GroundSDK Mission Manager.
    func setup(with missionsToLoadAtDroneConnection: [ProtobufMissionSignature]) {
        self.missionsToLoadAtDroneConnection =  missionsToLoadAtDroneConnection
        _ = protobufMissionViewModel
    }

    /// Loads a mission.
    ///
    /// - Parameters:
    ///     - mission: The mission to load
    func load(mission: ProtobufMissionSignature) {
        protobufMissionViewModel.load(mission: mission)
    }

    /// Unloads a mission.
    ///
    /// - Parameters:
    ///     - mission: The mission to unload
    func unload(mission: ProtobufMissionSignature) {
        protobufMissionViewModel.unload(mission: mission)
    }

    /// Activates a mission.
    ///
    /// - Parameters:
    ///     - mission: The mission to activate
    func activate(mission: ProtobufMissionSignature) {
        protobufMissionViewModel.activate(mission: mission)
    }

    /// Deactivate a mission.
    ///
    /// - Parameters:
    ///     - mission: The mission to deactivate
    func deactivate(mission: ProtobufMissionSignature) {
        protobufMissionViewModel.deactivate(mission: mission)
    }

    /// Sends a message to the Drone.
    ///
    /// - Parameters:
    ///     - message: The essage to send
    func send(message: ProtobufMissionMessageToSend) {
        protobufMissionViewModel.sendMessage(message: message)
    }

    /// Returns the state of a given mission.
    ///
    /// - Parameters:
    ///     - mission: The mission
    /// - Returns: The state of the mission.
    func state(for mission: ProtobufMissionSignature) -> MissionState {
        return protobufMissionViewModel.state(for: mission)
    }

    /// Returns true if a mission is suggested to be activated.
    ///
    /// - Parameters:
    ///     - mission: The mission
    /// - Returns: true if the mission activation is suggested.
    func isActivationSuggested(_ mission: ProtobufMissionSignature) -> Bool {
        return protobufMissionViewModel.isActivationSuggested(mission)
    }
}

/// Utils for listener management.
public extension ProtobufMissionsManager {
    /// Registers a listener for a specific mission.
    ///
    /// - Parameters:
    ///   - mission: The mission to listen to
    ///   - missionCallback: The callback triggered for any event related to the mission
    /// - Returns: The listener.
    func register(for mission: ProtobufMissionSignature,
                  missionCallback: @escaping ProtobufMissionClosure) -> ProtobufMissionListener {
        let listener = ProtobufMissionListener(mission: mission,
                                               missionCallback: missionCallback)
        listeners.insert(listener)
        let missionState = state(for: listener.mission)
        let isActivationSuggested = self.isActivationSuggested(listener.mission)
        listener.missionCallback(missionState, nil, isActivationSuggested)

        return listener
    }

    /// Unregisters a listener.
    ///
    /// - Parameters:
    ///     - listener: The listener to unregister
    func unregister(_ listener: ProtobufMissionListener?) {
        if let listener = listener {
            listeners.remove(listener)
        }
    }
}

// MARK: - Private Funcs
private extension ProtobufMissionsManager {
    /// Triggers all listeners callbacks.
    ///
    /// - Parameters:
    ///     - protobufMissionState: The state given by `ProtobufMissionViewModel`
    func protobufMissionCallback(protobufMissionState: ProtobufMissionsState) {
        // Check if drone would activate de mission on launch.
        if let activeMissionUid = protobufMissionState.currentActiveMissionUID,
           activeMissionUid != DefaultMissionSignature().missionUID {
            missionLauncher.updateActiveMissionIfNeeded(activeMissionUid: activeMissionUid)
        }

        guard let lastMessageReceived = protobufMissionState.lastMessageReceived else {
            // In case we don't have a last message receive, let's notify each listener about its mission state.
            listeners.forEach {
                let missionState = state(for: $0.mission)
                let isActivationSuggested = protobufMissionState.suggestedActivationMissionUID == $0.mission.missionUID
                $0.missionCallback(missionState, nil, isActivationSuggested)
            }
            return
        }

        // In case we have a last message receive, let's notify each listener about its mission state AND find the mission that needs to receive the message.
        let lastMessageReceivedMissionUID = lastMessageReceived.uid
        listeners.forEach {
            let missionState = state(for: $0.mission)
            let isActivationSuggested = protobufMissionState.suggestedActivationMissionUID == $0.mission.missionUID
            if $0.mission.missionUID == lastMessageReceivedMissionUID {
                $0.missionCallback(missionState, lastMessageReceived, isActivationSuggested)
            } else {
                $0.missionCallback(missionState, nil, isActivationSuggested)
            }
        }
    }
}
