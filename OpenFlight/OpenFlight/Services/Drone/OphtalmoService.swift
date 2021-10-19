// Copyright (C) 2021 Parrot Drones SAS
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

protocol OphtalmoService: AnyObject {

    /// The calibration progress of the mission
    var calibrationPercentagePublisher: AnyPublisher<Float?, Never> { get }
    /// The current status of the mission
    var calibrationStatusPublisher: AnyPublisher<Parrot_Missions_Ophtalmo_Airsdk_Messages_CalibrationStatus?, Never> { get }
    /// The calibration ended state of the mission
    var calibrationEndedPublisher: AnyPublisher<CalibrationEndedState?, Never> { get }
    /// The current step of the calibration
    var calibrationStepPublisher: AnyPublisher<Parrot_Missions_Ophtalmo_Airsdk_Messages_CalibrationStep, Never> { get }
    /// Indicates if the drone is flying
    var isFlyingPublisher: AnyPublisher<Bool, Never> { get }
    /// Indicates if the drone is landed
    var isLandedPublisher: AnyPublisher<Bool, Never> { get }
    /// The current gps strength
    var gpsStrengthPublisher: AnyPublisher<GpsStrength, Never> { get }

    /// Listens the ophtalmo mission
    func listenMission()
    /// Stops listening the ophtalmo mission
    func unregisterListener()
    /// Starts the mission
    func startMission()
    /// Stop the mission
    func endMission()

    /// Starts the ophtalmo mission
    /// - Parameter altitude: The altitude the drone will fly up to
    func startCalibration(altitude: Float)
    /// Stops the calibration
    func cancelCalibration()
    /// Reset all the values of the ophtalmo service
    func resetValue()

}

final class OphtalmoServiceImpl {

    private var protobufMissionManager: ProtobufMissionsManager
    private var protobufMissionsListener: ProtobufMissionsListener
    private var listener: ProtobufMissionListener?
    private let signature = OFMissionSignatures.ophtalmo
    private var messageUidGenerator = ProtobufMissionMessageToSend.UidGenerator(0)

    private var calibrationPercentage = CurrentValueSubject<Float?, Never>(nil)
    private var calibrationStatus = CurrentValueSubject<Parrot_Missions_Ophtalmo_Airsdk_Messages_CalibrationStatus?, Never>(nil)
    private var calibrationEnded = CurrentValueSubject<CalibrationEndedState?, Never>(nil)
    private var calibrationStep = CurrentValueSubject<Parrot_Missions_Ophtalmo_Airsdk_Messages_CalibrationStep, Never>(.idle)
    private var isFlying = CurrentValueSubject<Bool, Never>(false)
    private var isLanded = CurrentValueSubject<Bool, Never>(true)
    private var gpsStrength = CurrentValueSubject<GpsStrength, Never>(.none)

    private var gpsRef: Ref<Gps>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var cancellables = Set<AnyCancellable>()

    init(connectedDroneHolder: ConnectedDroneHolder,
         protobufMissionManager: ProtobufMissionsManager,
         protobufMissionsListener: ProtobufMissionsListener) {

        self.protobufMissionManager = protobufMissionManager
        self.protobufMissionsListener = protobufMissionsListener

        connectedDroneHolder.dronePublisher
            .sink { [unowned self] drone in
                listenGps(drone: drone)
                listenFlyingState(drone: drone)
            }
            .store(in: &cancellables)
    }
}

private extension OphtalmoServiceImpl {

    /// Sends the protobuf command.
    func send(command: Parrot_Missions_Ophtalmo_Airsdk_Messages_Command) {
        guard let payload = try? command.serializedData() else { return }

        let message = ProtobufMissionMessageToSend(mission: signature,
                                                   payload: payload,
                                                   messageUidGenerator: &messageUidGenerator)
        protobufMissionManager.sendMessage(message: message)
    }

    func listenGps(drone: Drone?) {
        guard let drone = drone else {
            gpsStrength.value = .none
            return
        }
        gpsRef = drone.getInstrument(Instruments.gps) { [unowned self] gps in
            gpsStrength.value = gps?.gpsStrength ?? .none
        }
    }

    /// Starts observing changes for flying indicators and updates the flyingState published property.
    ///
    /// - Parameter drone: The current drone
    func listenFlyingState(drone: Drone?) {
        guard let drone = drone else { return }

        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [unowned self] flyingIndicator in
            if flyingIndicator?.flyingState == .flying || flyingIndicator?.flyingState == .waiting {
                isFlying.value = true
                isLanded.value = false
            } else if flyingIndicator?.state == .landed {
                isLanded.value = true
                isFlying.value = false
            }
        }
    }
}

extension OphtalmoServiceImpl: OphtalmoService {

    var calibrationPercentagePublisher: AnyPublisher<Float?, Never> { calibrationPercentage.eraseToAnyPublisher() }

    var calibrationStatusPublisher: AnyPublisher<Parrot_Missions_Ophtalmo_Airsdk_Messages_CalibrationStatus?, Never> {
        calibrationStatus.eraseToAnyPublisher()
    }

    var calibrationEndedPublisher: AnyPublisher<CalibrationEndedState?, Never> { calibrationEnded.eraseToAnyPublisher() }
    var calibrationStepPublisher: AnyPublisher<Parrot_Missions_Ophtalmo_Airsdk_Messages_CalibrationStep, Never> {
        calibrationStep.eraseToAnyPublisher()
    }
    var isFlyingPublisher: AnyPublisher<Bool, Never> { isFlying.eraseToAnyPublisher() }
    var isLandedPublisher: AnyPublisher<Bool, Never> { isLanded.eraseToAnyPublisher() }
    var gpsStrengthPublisher: AnyPublisher<GpsStrength, Never> { gpsStrength.eraseToAnyPublisher() }

    func listenMission() {
        listener = protobufMissionsListener.register(
            for: signature,
            missionCallback: { [weak self] (state, message, _) in
                if let message = message {
                    do {
                        let event = try Parrot_Missions_Ophtalmo_Airsdk_Messages_Event(serializedData: message.payload)
                        self?.calibrationStatus.value = event.state.calibrationStatus
                        self?.calibrationPercentage.value = Float(event.state.completionPercent)
                        self?.calibrationStep.value = event.state.calibrationStep
                    } catch {
                        // Nothing to do.
                    }
                }
            })
    }

    func unregisterListener() {
        protobufMissionsListener.unregister(listener)
    }

    func startMission() {
        protobufMissionManager.activate(mission: signature)
    }

    func endMission() {
        protobufMissionManager.deactivate(mission: signature)
    }

    func startCalibration(altitude: Float) {
        var config = Parrot_Missions_Ophtalmo_Airsdk_Messages_Config()
        config.altitude = altitude
        var startCommand = Parrot_Missions_Ophtalmo_Airsdk_Messages_Command()
        startCommand.id = .start(config)

        send(command: startCommand)
    }

    func cancelCalibration() {
        var abortCommand = Parrot_Missions_Ophtalmo_Airsdk_Messages_Command()
        abortCommand.id = .abort(Google_Protobuf_Empty())

        send(command: abortCommand)
    }

    func resetValue() {
        calibrationPercentage.value = nil
        calibrationStatus.value = nil
        calibrationEnded.value = nil
        calibrationStep.value = .idle
    }
}
