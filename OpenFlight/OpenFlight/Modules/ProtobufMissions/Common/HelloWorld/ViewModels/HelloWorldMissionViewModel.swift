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

// MARK: - HelloWorldMissionState
/// The states for `HelloWorldMissionViewModel`
final class HelloWorldMissionState: ViewModelState, Copying, EquatableState {
    // MARK: - Private Properties
    fileprivate(set) var missionState: MissionState = .unavailable
    fileprivate(set) var lastMessageReceived: ProtobufMissionMessageReceived?
    fileprivate(set) var protobufMessageReceivedCount = 0

    // MARK: - Init
    required init() {}

    /// Init the mission states.
    ///
    /// - Parameters:
    ///   - missionState: The mission state
    ///   - lastMessageReceived: The last message receive
    ///   - protobufMessageReceivedCount: The count of messages received
    init(missionState: MissionState,
         lastMessageReceived: ProtobufMissionMessageReceived?,
         protobufMessageReceivedCount: Int) {
        self.missionState = missionState
        self.lastMessageReceived = lastMessageReceived
        self.protobufMessageReceivedCount = protobufMessageReceivedCount
    }

    // MARK: - EquatableState
    func isEqual(to other: HelloWorldMissionState) -> Bool {
        return self.missionState == other.missionState
            && self.lastMessageReceived == other.lastMessageReceived
            && self.protobufMessageReceivedCount == other.protobufMessageReceivedCount
    }

    // MARK: - Copying
    func copy() -> HelloWorldMissionState {
        return HelloWorldMissionState(missionState: self.missionState,
                                      lastMessageReceived: self.lastMessageReceived,
                                      protobufMessageReceivedCount: self.protobufMessageReceivedCount
        )
    }
}

// MARK: - HelloWorldMissionViewModel
/// The view model that handles Hello World protobuf mission.
final class HelloWorldMissionViewModel: BaseViewModel<HelloWorldMissionState> {
    // MARK: - Private Properties
    private var protobufManager = ProtobufMissionsManager.shared
    private var listener: ProtobufMissionListener?
    private var helloWorldMissionSignature = HelloWorldMissionSignature()

    // MARK: - Init
    init() {
        super.init()
        listenMission()
    }

    // MARK: - Deinit
    deinit {
        protobufManager.unregister(listener)
    }

    // MARK: - Internal Functions
    /// Loads the Hello World mission.
    func loadHelloWorld() {
        protobufManager.load(mission: helloWorldMissionSignature)
    }

    /// Unloads the Hello World mission.
    func unloadHelloWorld() {
        protobufManager.unload(mission: helloWorldMissionSignature)
    }

    /// Sends a protobuf message to the drone.
    func sendMessage() {
        var helloCommand = Parrot_Missions_Samples_Hello_Airsdk_Command()
        helloCommand.id = .say(Google_Protobuf_Empty())

        guard let payload = try? helloCommand.serializedData() else { return }

        let helloWorldMessage = ProtobufMissionMessageToSend(mission: helloWorldMissionSignature,
                                                             payload: payload)
        update(protobufMessageReceivedCount: 0)
        protobufManager.send(message: helloWorldMessage)
    }

    /// Returns a potential message to display.
    ///
    /// - Returns: A potential message to display.
    func messageToDisplay() -> String? {
        let randomMessage = HelloWorldMessageToDisplay.randomMessage()
        let messageCount = state.value.protobufMessageReceivedCount

        return messageCount == 0 ? nil : randomMessage
    }

    /// Triggers an action for a state.
    func toggleState() {
        switch state.value.missionState {
        case .active:
            sendMessage()
        case .idle:
            startMission()
        case .unavailable:
            loadHelloWorld()
        case .unloaded:
            loadHelloWorld()
        }
    }
}

// MARK: - MissionActivationModel
extension HelloWorldMissionViewModel: MissionActivationModel {
    /// Activates the mission.
    func startMission() {
        protobufManager.activate(mission: helloWorldMissionSignature)
    }

    /// Deactivates the mission.
    func stopMissionIfNeeded() {
        protobufManager.deactivate(mission: helloWorldMissionSignature)
    }
}

// MARK: - Private Functions
private extension HelloWorldMissionViewModel {
    /// Listen to the Hello World mission.
    func listenMission() {
        listener = protobufManager.register(
            for: helloWorldMissionSignature,
            missionCallback: { [weak self] (state, message, _) in
                self?.update(missionState: state)
                guard let lastMessageReceived = message else {
                    self?.update(lastMessageReceived: nil)
                    return
                }

                self?.update(lastMessageReceived: lastMessageReceived)
                self?.treat(lastMessageReceived: lastMessageReceived)
            })
    }

    /// Treats a protobuf message received from the drone.
    ///
    /// - Parameters:
    ///     - lastMessageReceived: The protobuf message received from the drone
    func treat(lastMessageReceived: ProtobufMissionMessageReceived) {
        do {
            let decodeInfo = try Parrot_Missions_Samples_Hello_Airsdk_Event(serializedData: lastMessageReceived.payload)
            update(protobufMessageReceivedCount: Int(decodeInfo.count))
        } catch {
            // Nothing to do.
        }
    }
}

/// Utils for updating states of `HelloWorldMissionState`.
private extension HelloWorldMissionViewModel {
    /// Updates the state.
    ///
    /// - Parameters:
    ///     - missionState: The mission state
    func update(missionState: MissionState) {
        let copy = self.state.value.copy()
        copy.missionState = missionState
        self.state.set(copy)
    }

    /// Updates the state.
    ///
    /// - Parameters:
    ///     - lastMessageReceived: The last message received
    func update(lastMessageReceived: ProtobufMissionMessageReceived?) {
        let copy = self.state.value.copy()
        copy.lastMessageReceived = lastMessageReceived
        self.state.set(copy)
    }

    /// Updates the state.
    ///
    /// - Parameters:
    ///     - protobufMessageReceivedCount: The messages received count
    func update(protobufMessageReceivedCount: Int) {
        let copy = self.state.value.copy()
        copy.protobufMessageReceivedCount = protobufMessageReceivedCount
        self.state.set(copy)
    }
}
