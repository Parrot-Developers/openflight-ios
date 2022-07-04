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
import Combine

// MARK: - HelloWorldMissionViewModel
/// The view model that handles Hello World AirSdk mission.
final class HelloWorldMissionViewModel {
    typealias Command = Parrot_Missions_Samples_Hello_Airsdk_Messages_Command
    typealias Event = Parrot_Missions_Samples_Hello_Airsdk_Messages_Event
    typealias Empty = Google_Protobuf_Empty

    @Published private(set) var missionState: MissionState = .unavailable
    @Published private(set) var lastMessageReceived: AirSdkMissionMessageReceived?
    @Published private(set) var messageReceivedCount = 1
    @Published private(set) var depthMean: Float = 0.0
    @Published private(set) var isSayingHello: Bool = true

    // MARK: - Private Properties
    private var airSdkManager = Services.hub.drone.airsdkMissionsManager
    private var airSdkListener = Services.hub.drone.airsdkMissionsListener
    private var listener: AirSdkMissionListener?
    private var helloWorldMissionSignature = HelloWorldMissionSignature()
    private var messageUidGenerator = AirSdkMissionMessageToSend.UidGenerator(0)

    // MARK: - Init
    init() {
        listenMission()
    }

    // MARK: - Deinit
    deinit {
        airSdkListener.unregister(listener)
    }

    // MARK: - Internal Functions
    /// Loads the Hello World mission.
    func loadHelloWorld() {
        airSdkManager.load(mission: helloWorldMissionSignature)
    }

    /// Unloads the Hello World mission.
    func unloadHelloWorld() {
        airSdkManager.unload(mission: helloWorldMissionSignature)
    }

    /// Sends a AirSdk message to the drone.
    func sendMessage() {
        var helloCommand = Command()

        helloCommand.id = isSayingHello ? .hold(Empty()) : .say(Empty())
        send(command: helloCommand)
    }

    func send(command: Command) {
        guard let payload = try? command.serializedData() else { return }

        let helloWorldMessage = AirSdkMissionMessageToSend(mission: helloWorldMissionSignature,
                                                           payload: payload,
                                                           messageUidGenerator: &messageUidGenerator)
        update(messageReceivedCount: 0)
        update(isSayingHello: !isSayingHello)
        airSdkManager.sendMessage(message: helloWorldMessage)
    }

    /// Returns a potential message to display.
    ///
    /// - Returns: A potential message to display.
    func messageToDisplay() -> String? {
        let randomMessage = HelloWorldMessageToDisplay.randomMessage()
        let messageCount = messageReceivedCount

        return messageCount == 0 ? nil : randomMessage
    }

    /// Triggers an action for a state.
    func toggleState() {
        switch missionState {
        case .active:
            sendMessage()
        case .idle:
            startMission()
        case .unloaded:
            loadHelloWorld()
        default:
            break
        }
    }
}

// MARK: - MissionActivationModel
extension HelloWorldMissionViewModel: MissionActivationModel {

    /// Whether the mission can be stop.
    func canStopMission() -> Bool {
        return true
    }

    /// Whether the mission can be start.
    func canStartMission() -> Bool {
        return true
    }

    func showFailedActivationMessage() {
        // Nothing to do
    }

    func showFailedDectivationMessage() {
        // Nothing to do
    }

    /// Activates the mission.
    func startMission() {
        airSdkManager.activate(mission: helloWorldMissionSignature)
    }

    /// Deactivates the mission.
    func stopMissionIfNeeded() {}

    func isActive() -> Bool {
        let missionManager = Services.hub.connectedDroneHolder.drone?.getPeripheral(Peripherals.missionManager)
        guard let missionManager = missionManager, let mission = missionManager.missions[ OFMissionSignatures.helloWorld.missionUID] else { return false }
        return mission.state == .active
    }

    func getPriority() -> MissionPriority {
        .middle
    }
}

// MARK: - Private Functions
private extension HelloWorldMissionViewModel {
    /// Listen to the Hello World mission.
    func listenMission() {
        listener = airSdkListener.register(
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

    /// Treats a AirSdk message received from the drone.
    ///
    /// - Parameters:
    ///     - lastMessageReceived: The AirSdk message received from the drone
    func treat(lastMessageReceived: AirSdkMissionMessageReceived) {
        do {
            let helloEvent = try Event(serializedData: lastMessageReceived.payload)
            switch helloEvent.id {
            case .depthMean(let depth):
                update(depthMean: depth)

            case .count(let count):
                update(messageReceivedCount: Int(count))

            default:
                break
            }

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
        self.missionState = missionState
    }

    /// Updates the state.
    ///
    /// - Parameters:
    ///     - lastMessageReceived: The last message received
    func update(lastMessageReceived: AirSdkMissionMessageReceived?) {
        self.lastMessageReceived = lastMessageReceived
    }

    /// Updates the state.
    ///
    /// - Parameters:
    ///     - messageReceivedCount: The messages received count
    func update(messageReceivedCount: Int) {
        self.messageReceivedCount = messageReceivedCount
    }

    func update(depthMean: Float) {
        self.depthMean = depthMean
    }

    func update(isSayingHello: Bool) {
        self.isSayingHello = isSayingHello
    }
}
