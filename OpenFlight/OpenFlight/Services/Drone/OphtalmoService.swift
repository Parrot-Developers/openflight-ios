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

typealias OpthamoMissionCalibrationStatus = Parrot_Missions_Ophtalmo_Airsdk_Messages_CalibrationStatus
typealias OpthamoMissionCalibrationStep = Parrot_Missions_Ophtalmo_Airsdk_Messages_CalibrationStep
private typealias OpthamoMissionConfig = Parrot_Missions_Ophtalmo_Airsdk_Messages_Config
private typealias MissionCommand = Parrot_Missions_Ophtalmo_Airsdk_Messages_Command
private typealias MissionEvent = Parrot_Missions_Ophtalmo_Airsdk_Messages_Event
private typealias MissionEmptyMessage = SwiftProtobuf.Google_Protobuf_Empty

// MARK: - Internal Enums
/// List of alerts for Ophtalmo
enum OphtalmoError: String {
    case cannotStop

    var label: String {
        switch self {
        case .cannotStop:
            return L10n.ophtalmoStopLand
        }
    }
}

protocol OphtalmoService: AnyObject {

    /// The calibration progress of the mission
    var calibrationPercentagePublisher: AnyPublisher<Float?, Never> { get }
    /// The current status of the mission
    var calibrationStatusPublisher: AnyPublisher<OpthamoMissionCalibrationStatus?, Never> { get }
    /// The calibration ended state of the mission
    var calibrationEndedPublisher: AnyPublisher<CalibrationEndedState?, Never> { get }
    /// The current step of the calibration
    var calibrationStepPublisher: AnyPublisher<OpthamoMissionCalibrationStep, Never> { get }
    /// Indicates if the drone is flying
    var isFlyingPublisher: AnyPublisher<Bool, Never> { get }
    /// The current gps strength
    var gpsStrengthPublisher: AnyPublisher<GpsStrength, Never> { get }
    /// The current ophtalmo error.
    var errorAlertPublisher: AnyPublisher<OphtalmoError?, Never> { get }
    /// Indicates if return home ending is set to landing
    var endLandingPublisher: AnyPublisher<Bool, Never> { get }
    /// The current flying status
    var isFlyingValue: Bool { get }
    /// The current state of the mission publisher.
    var ophtalmoMissionStatePublisher: AnyPublisher<MissionState?, Never> { get }
    /// The current state of the mission value.
    var ophtalmoMissionState: MissionState? { get }
    /// Listens the ophtalmo mission
    func listenMission()
    /// Stops listening the ophtalmo mission
    func unregisterListener()
    /// Starts the mission
    func startMission()
    /// Stop the mission
    func endMission()

    var altitude: Float { get }

    /// Starts the ophtalmo mission
    /// - Parameter altitude: The altitude the drone will fly up to
    func startCalibration(altitude: Float)
    /// Stops the calibration
    func cancelCalibration()
    /// Reset all the values of the ophtalmo service
    func resetValue()
    /// Reset active mission
    func resetActiveMission()
    /// Updates error alert for ophtalmo mission.
    func updateErrorAlert(_ message: OphtalmoError?)

}

final class OphtalmoServiceImpl {

    private var airSdkMissionManager: AirSdkMissionsManager
    private var airsdkMissionsListener: AirSdkMissionsListener
    private var listener: AirSdkMissionListener?
    private let signature = OFMissionSignatures.ophtalmo
    private var messageUidGenerator = AirSdkMissionMessageToSend.UidGenerator(0)

    private var calibrationPercentage = CurrentValueSubject<Float?, Never>(nil)
    private var calibrationAltitude = CurrentValueSubject<Float?, Never>(nil)
    private var calibrationStatus = CurrentValueSubject<OpthamoMissionCalibrationStatus?, Never>(nil)
    private var calibrationEnded = CurrentValueSubject<CalibrationEndedState?, Never>(nil)
    private var calibrationStep = CurrentValueSubject<OpthamoMissionCalibrationStep, Never>(.idle)
    private var isFlying = CurrentValueSubject<Bool, Never>(false)
    private var gpsStrength = CurrentValueSubject<GpsStrength, Never>(.none)
    private var errorAlert = CurrentValueSubject<OphtalmoError?, Never>(nil)
    private var endLanding = CurrentValueSubject<Bool, Never>(false)
    private var ophtalmoMissionStateCurrentValue = CurrentValueSubject<MissionState?, Never>(nil)

    private var gpsRef: Ref<Gps>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var returnHomePilotingRef: Ref<ReturnHomePilotingItf>?
    private var cancellables = Set<AnyCancellable>()

    init(connectedDroneHolder: ConnectedDroneHolder,
         airSdkMissionManager: AirSdkMissionsManager,
         airsdkMissionsListener: AirSdkMissionsListener) {

        self.airSdkMissionManager = airSdkMissionManager
        self.airsdkMissionsListener = airsdkMissionsListener

        connectedDroneHolder.dronePublisher
            .sink { [unowned self] drone in
                listenGps(drone: drone)
                listenFlyingState(drone: drone)
                listenStatus(drone: drone)
                listenReturnHome(drone: drone)
            }
            .store(in: &cancellables)
    }
}

private extension OphtalmoServiceImpl {

    /// Sends the airsdk command.
    func send(command: MissionCommand) {
        guard let payload = try? command.serializedData() else { return }

        let message = AirSdkMissionMessageToSend(mission: signature,
                                                 payload: payload,
                                                 messageUidGenerator: &messageUidGenerator)
        airSdkMissionManager.sendMessage(message: message)
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
            guard let flyingIndicator = flyingIndicator else {
                isFlying.value = false
                return
            }
            isFlying.value = flyingIndicator.state != .landed
        }
    }

    func listenStatus(drone: Drone?) {
        guard let drone = drone else {
            ophtalmoMissionStateCurrentValue.value = nil
            return
        }
        let missionManager = drone.getPeripheral(Peripherals.missionManager)
        let missionOphtalmo = missionManager?.missions[signature.missionUID]
        ophtalmoMissionStateCurrentValue.value = missionOphtalmo?.state
    }

    func listenReturnHome(drone: Drone?) {
        guard let drone = drone else { return }

        returnHomePilotingRef = drone.getPilotingItf(PilotingItfs.returnHome) { [weak self] returnHome in
            guard let self = self else { return }
            self.endLanding.value = returnHome?.endingBehavior.behavior == .landing
        }
    }
}

extension OphtalmoServiceImpl: OphtalmoService {

    var altitude: Float {
        calibrationAltitude.value ?? 0
    }

    var calibrationPercentagePublisher: AnyPublisher<Float?, Never> { calibrationPercentage.eraseToAnyPublisher() }

    var calibrationStatusPublisher: AnyPublisher<OpthamoMissionCalibrationStatus?, Never> {
        calibrationStatus.eraseToAnyPublisher()
    }
    var isFlyingValue: Bool {
        return isFlying.value
    }
    var ophtalmoMissionState: MissionState? { return ophtalmoMissionStateCurrentValue.value}

    var ophtalmoMissionStatePublisher: AnyPublisher<MissionState?, Never> {
        ophtalmoMissionStateCurrentValue.eraseToAnyPublisher()
    }
    var calibrationEndedPublisher: AnyPublisher<CalibrationEndedState?, Never> { calibrationEnded.eraseToAnyPublisher() }
    var calibrationStepPublisher: AnyPublisher<OpthamoMissionCalibrationStep, Never> {
        calibrationStep.eraseToAnyPublisher()
    }
    var isFlyingPublisher: AnyPublisher<Bool, Never> { isFlying.eraseToAnyPublisher() }
    var gpsStrengthPublisher: AnyPublisher<GpsStrength, Never> { gpsStrength.eraseToAnyPublisher() }
    var errorAlertPublisher: AnyPublisher<OphtalmoError?, Never> { errorAlert.eraseToAnyPublisher() }
    var endLandingPublisher: AnyPublisher<Bool, Never> { endLanding.eraseToAnyPublisher() }

    func listenMission() {
        listener = airsdkMissionsListener.register(
            for: signature,
            missionCallback: { [weak self] (state, message, _) in
                if let message = message {
                    do {
                        let event = try MissionEvent(serializedData: message.payload)
                        self?.calibrationAltitude.value = event.state.config.altitude
                        self?.calibrationPercentage.value = Float(event.state.completionPercent)
                        self?.calibrationStep.value = event.state.calibrationStep
                        self?.calibrationStatus.value = event.state.calibrationStatus
                    } catch {
                        // Nothing to do.
                    }
                }
            })
    }

    func unregisterListener() {
        airsdkMissionsListener.unregister(listener)
    }

    func startMission() {
        airSdkMissionManager.activate(mission: signature)
    }

    func endMission() {}

    func startCalibration(altitude: Float) {
        var config = OpthamoMissionConfig()
        config.altitude = altitude
        var startCommand = MissionCommand()
        startCommand.id = .start(config)

        send(command: startCommand)
    }

    func cancelCalibration() {
        var abortCommand = MissionCommand()
        abortCommand.id = .abort(MissionEmptyMessage())

        send(command: abortCommand)
    }

    func resetValue() {
        calibrationPercentage.value = nil
        calibrationStatus.value = nil
        calibrationEnded.value = nil
        calibrationStep.value = .idle
    }

    func updateErrorAlert(_ message: OphtalmoError?) {
        errorAlert.value = message
    }

    func resetActiveMission() {
        ophtalmoMissionStateCurrentValue.value = nil
    }
}
