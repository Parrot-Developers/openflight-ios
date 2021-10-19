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

public protocol ProtobufMissionsListener: AnyObject {

    func unregister(_ listener: ProtobufMissionListener?)
    func register(for mission: ProtobufMissionSignature,
                  missionCallback: @escaping ProtobufMissionClosure) -> ProtobufMissionListener
}

class ProtobufMissionListenerImpl: ProtobufMissionsListener {

    // MARK: - Private Properties
    /// The current listeners.
    var listeners: Set<ProtobufMissionListener> = []
    private var cancellables = Set<AnyCancellable>()

    private var protobufMissionsManager: ProtobufMissionsManager
    private var currentMissionManager: CurrentMissionManager

    init(currentMissionManager: CurrentMissionManager, protobufMissionManager: ProtobufMissionsManager) {
        self.currentMissionManager = currentMissionManager
        self.protobufMissionsManager = protobufMissionManager

        protobufMissionsManager.currentActiveMissionUID
            .removeDuplicates()
            .combineLatest(protobufMissionsManager.lastMessageReceived.removeDuplicates(),
                           protobufMissionsManager.suggestedActivationMissionUID.removeDuplicates())
            .sink { [unowned self] (currentActiveMissionUID, lastMessageReceived, suggestedActivationMissionUID) in
                if let activeMissionUid = currentActiveMissionUID {
                    currentMissionManager.updateActiveMissionIfNeeded(activeMissionUid: activeMissionUid)
                }

                guard let lastMessageReceived = lastMessageReceived else {
                    // In case we don't have a last message receive, let's notify each listener about its mission state.
                    listeners.forEach {
                        let missionState = protobufMissionsManager.state(for: $0.mission)
                        let isActivationSuggested = suggestedActivationMissionUID == $0.mission.missionUID
                        $0.missionCallback(missionState, nil, isActivationSuggested)
                    }
                    return
                }

                // In case we have a last message receive, let's notify each listener about its mission state
                // AND find the mission that needs to receive the message.
                let lastMessageReceivedMissionUID = lastMessageReceived.missionUid
                listeners.forEach {
                    let missionState = protobufMissionsManager.state(for: $0.mission)
                    let isActivationSuggested = suggestedActivationMissionUID == $0.mission.missionUID
                    if $0.mission.missionUID == lastMessageReceivedMissionUID {
                        $0.missionCallback(missionState, lastMessageReceived, isActivationSuggested)
                    } else {
                        $0.missionCallback(missionState, nil, isActivationSuggested)
                    }
                }

            }
            .store(in: &cancellables)
    }
}

/// Utils for listener management.
extension ProtobufMissionListenerImpl {
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
        let missionState = protobufMissionsManager.state(for: listener.mission)
        let isActivationSuggested = protobufMissionsManager.isActivationSuggested(listener.mission)
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
