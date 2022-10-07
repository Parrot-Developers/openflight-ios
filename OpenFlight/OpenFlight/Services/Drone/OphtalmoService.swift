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

typealias OpthalmoMissionCalibrationStatus = Parrot_Missions_Ophtalmo_Airsdk_Messages_CalibrationStatus
typealias OpthalmoMissionCalibrationStep = Parrot_Missions_Ophtalmo_Airsdk_Messages_CalibrationStep
private typealias OphtalmoMissionConfig = Parrot_Missions_Ophtalmo_Airsdk_Messages_Config
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

/// List of hand launch states for Ophtalmo.
enum OphtalmoHandLaunchState {
    case unavailable
    case available
    case ready

    public var subtitle: String? {
        switch self {
        case .available:
            return L10n.loveCalibrationHandLaunchState(L10n.commonAvailable)
        case .ready:
            return L10n.loveCalibrationHandLaunchState(L10n.commonReady)
        case .unavailable:
            return nil
        }
    }

    public var subtitleColor: UIColor {
        switch self {
        case .available:
            return ColorName.blueNavy.color
        case .ready:
            return ColorName.highlightColor.color
        case .unavailable:
            return ColorName.defaultTextColor.color
        }
    }

    public var isCalibrationButtonsHidden: Bool {
        switch self {
        case .ready:
            return true
        case .available, .unavailable:
            return false
        }
    }
}

protocol OphtalmoService: AnyObject {

    /// The calibration progress of the mission
    var calibrationPercentagePublisher: AnyPublisher<Float?, Never> { get }
    /// The current status of the mission
    var calibrationStatusPublisher: AnyPublisher<OpthalmoMissionCalibrationStatus?, Never> { get }
    /// The calibration ended state of the mission
    var calibrationEndedPublisher: AnyPublisher<CalibrationEndedState?, Never> { get }
    /// The current step of the calibration
    var calibrationStepPublisher: AnyPublisher<OpthalmoMissionCalibrationStep, Never> { get }
    /// Indicates if the drone is flying
    var isFlyingPublisher: AnyPublisher<Bool, Never> { get }
    /// Publicher of the current hand launch state
    var handLaunchStatePublisher: AnyPublisher<OphtalmoHandLaunchState, Never> { get }
    /// The current hand launch state
    var handLaunchState: OphtalmoHandLaunchState { get }
    /// Publisher of the current gps strength
    var gpsStrengthPublisher: AnyPublisher<GpsStrength, Never> { get }
    /// The current gps strength
    var gpsStrength: GpsStrength { get }
    /// The current ophtalmo error.
    var errorAlertPublisher: AnyPublisher<OphtalmoError?, Never> { get }
    /// Indicates if return home ending is set to landing
    var endLandingPublisher: AnyPublisher<Bool, Never> { get }
    /// The current handlanding state
    var isHandLandingPublisher: AnyPublisher<Bool, Never> { get }
    /// The current flying status
    var isFlying: Bool { get }
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
    private var connectedDroneHolder: ConnectedDroneHolder

    private var calibrationPercentage = CurrentValueSubject<Float?, Never>(nil)
    private var calibrationAltitude = CurrentValueSubject<Float?, Never>(nil)
    private var calibrationStatus = CurrentValueSubject<OpthalmoMissionCalibrationStatus?, Never>(nil)
    private var calibrationEnded = CurrentValueSubject<CalibrationEndedState?, Never>(nil)
    private var calibrationStep = CurrentValueSubject<OpthalmoMissionCalibrationStep, Never>(.idle)
    private var isFlyingSubject = CurrentValueSubject<Bool, Never>(false)
    private var handLaunchStateSubject = CurrentValueSubject<OphtalmoHandLaunchState, Never>(.unavailable)
    private var gpsStrengthSubject = CurrentValueSubject<GpsStrength, Never>(.none)
    private var errorAlert = CurrentValueSubject<OphtalmoError?, Never>(nil)
    private var endLandingSubject = CurrentValueSubject<Bool, Never>(false)
    private var ophtalmoMissionStateCurrentValue = CurrentValueSubject<MissionState?, Never>(nil)
    private var isHandLandingSubject = CurrentValueSubject<Bool, Never>(false)
    private var calibrationAltitudeAskSubject = CurrentValueSubject<Float?, Never>(nil)

    /// Reference to gps instrument.
    private var gpsRef: Ref<Gps>?
    /// Reference to flying indicators instrument.
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    /// Reference to return home piloting interface.
    private var returnHomePilotingRef: Ref<ReturnHomePilotingItf>?
    /// Reference to manual piloting interface.
    private var manualPilotingRef: Ref<ManualCopterPilotingItf>?

    private var cancellables = Set<AnyCancellable>()
    init(connectedDroneHolder: ConnectedDroneHolder,
         airSdkMissionManager: AirSdkMissionsManager,
         airsdkMissionsListener: AirSdkMissionsListener) {
        self.connectedDroneHolder = connectedDroneHolder
        self.airSdkMissionManager = airSdkMissionManager
        self.airsdkMissionsListener = airsdkMissionsListener

        connectedDroneHolder.dronePublisher
            .sink { [unowned self] drone in
                listenGps(drone: drone)
                listenFlyingState(drone: drone)
                listenStatus(drone: drone)
                listenReturnHome(drone: drone)
                listenManualPiloting(drone: drone)
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

    /// Starts watcher for gps instrument.
    ///
    /// - Parameters:
    ///    - drone: the current drone
    func listenGps(drone: Drone?) {
        guard let drone = drone else {
            gpsStrengthSubject.value = .none
            return
        }
        gpsRef = drone.getInstrument(Instruments.gps) { [unowned self] gps in
            gpsStrengthSubject.value = gps?.gpsStrength ?? .none
        }
    }

    /// Starts watcher for flying indicators instruments.
    /// Updates the flyingState published property.
    /// Updates the hand launch published property.
    ///
    /// - Parameter drone: The current drone
    func listenFlyingState(drone: Drone?) {
        guard let drone = drone else { return }

        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [unowned self] flyingIndicator in
            guard let flyingIndicator = flyingIndicator else {
                isFlyingSubject.value = false
                isHandLandingSubject.value = false
                return
            }
            isFlyingSubject.value = flyingIndicator.state != .landed
            isHandLandingSubject.value = flyingIndicator.isHandLanding
            updateHandLaunchStatus(drone: drone)

            if let calibrationAltitudeAsk = calibrationAltitudeAskSubject.value,
               flyingIndicator.flyingState == .waiting {
                calibrationAltitudeAskSubject.value = nil
                startCalibration(altitude: calibrationAltitudeAsk)
            }
        }
    }

    /// Starts watcher for manual piloting interface.
    /// Updates the hand launch published property.
    ///
    /// - Parameters:
    ///    - drone: the current drone
    func listenManualPiloting(drone: Drone?) {
        guard let drone = drone else { return }

        manualPilotingRef = drone.getPilotingItf(PilotingItfs.manualCopter) { [unowned self] _ in
            updateHandLaunchStatus(drone: drone)
        }
    }

    /// Starts watcher for mission manager peripheral.
    ///
    /// - Parameters:
    ///    - drone: the current drone
    func listenStatus(drone: Drone?) {
        guard let drone = drone else {
            ophtalmoMissionStateCurrentValue.value = nil
            return
        }
        let missionManager = drone.getPeripheral(Peripherals.missionManager)
        let missionOphtalmo = missionManager?.missions[signature.missionUID]
        ophtalmoMissionStateCurrentValue.value = missionOphtalmo?.state
    }

    /// Starts watcher for return home interface.
    ///
    /// - Parameters:
    ///    - drone: the current drone
    func listenReturnHome(drone: Drone?) {
        guard let drone = drone else { return }

        returnHomePilotingRef = drone.getPilotingItf(PilotingItfs.returnHome) { [weak self] returnHome in
            guard let self = self else { return }
            self.endLandingSubject.value = returnHome?.endingBehavior.behavior == .landing
        }
    }

    /// Updates hand launch status.
    ///
    /// - Parameters:
    ///    - drone: the current drone
    func updateHandLaunchStatus(drone: Drone?) {
        if drone?.isHandLaunchAvailable == true {
            handLaunchStateSubject.value = .available
        } else if drone?.isHandLaunchReady == true {
            handLaunchStateSubject.value = .ready
        } else {
            handLaunchStateSubject.value = .unavailable
        }
    }
}

extension OphtalmoServiceImpl: OphtalmoService {
    var altitude: Float {
        calibrationAltitudeAskSubject.value ?? (calibrationAltitude.value ?? 0)
    }

    var calibrationPercentagePublisher: AnyPublisher<Float?, Never> { calibrationPercentage.eraseToAnyPublisher() }

    var calibrationStatusPublisher: AnyPublisher<OpthalmoMissionCalibrationStatus?, Never> {
        calibrationStatus.eraseToAnyPublisher()
    }
    var handLaunchState: OphtalmoHandLaunchState {
        handLaunchStateSubject.value
    }
    var isFlying: Bool {
        isFlyingSubject.value
    }
    var gpsStrength: GpsStrength {
        gpsStrengthSubject.value
    }
    var ophtalmoMissionState: MissionState? { return ophtalmoMissionStateCurrentValue.value}

    var ophtalmoMissionStatePublisher: AnyPublisher<MissionState?, Never> {
        ophtalmoMissionStateCurrentValue.eraseToAnyPublisher()
    }
    var calibrationEndedPublisher: AnyPublisher<CalibrationEndedState?, Never> { calibrationEnded.eraseToAnyPublisher() }
    var calibrationStepPublisher: AnyPublisher<OpthalmoMissionCalibrationStep, Never> {
        calibrationStep.eraseToAnyPublisher()
    }
    var isFlyingPublisher: AnyPublisher<Bool, Never> { isFlyingSubject.eraseToAnyPublisher() }
    var handLaunchStatePublisher: AnyPublisher<OphtalmoHandLaunchState, Never> { handLaunchStateSubject.eraseToAnyPublisher() }
    var gpsStrengthPublisher: AnyPublisher<GpsStrength, Never> { gpsStrengthSubject.eraseToAnyPublisher() }
    var errorAlertPublisher: AnyPublisher<OphtalmoError?, Never> { errorAlert.eraseToAnyPublisher() }
    var endLandingPublisher: AnyPublisher<Bool, Never> { endLandingSubject.eraseToAnyPublisher() }
    var isHandLandingPublisher: AnyPublisher<Bool, Never> { isHandLandingSubject.eraseToAnyPublisher() }

    func listenMission() {
        listener = airsdkMissionsListener.register(
            for: signature,
            missionCallback: { [weak self] (state, message, _) in
                guard let self = self,
                      self.calibrationAltitudeAskSubject.value == nil else {
                    return
                }

                if let message = message {
                    do {
                        let event = try MissionEvent(serializedData: message.payload)
                        self.calibrationAltitude.value = event.state.config.altitude
                        self.calibrationPercentage.value = Float(event.state.completionPercent)
                        self.calibrationStep.value = event.state.calibrationStep
                        self.calibrationStatus.value = event.state.calibrationStatus
                    } catch {
                        // Nothing to do.
                    }
                }
            })

        isFlyingSubject
            .removeDuplicates()
            .combineLatest(calibrationAltitudeAskSubject.removeDuplicates())
            .sink { [unowned self] isFlying, calibrationAltitudeAsk in
                guard !isFlying || calibrationAltitudeAsk == nil else {
                    calibrationStatus.value = .inProgress
                    calibrationStep.value = .ascending
                    return
                }
            }
            .store(in: &cancellables)
    }

    func unregisterListener() {
        airsdkMissionsListener.unregister(listener)
    }

    func startMission() {
        airSdkMissionManager.activate(mission: signature)
    }

    func endMission() {}

    func startCalibration(altitude: Float) {
        guard let connectedDrone = connectedDroneHolder.drone else { return }
        if connectedDrone.isHandLaunchAvailable {
            if Services.hub.ui.criticalAlert.canTakeOff {
                calibrationAltitudeAskSubject.value = altitude
                connectedDrone.startHandLaunch()
            }
        } else {
            sendCalibrationCommand(altitude: altitude)
        }
    }

    func cancelCalibration() {
        var abortCommand = MissionCommand()
        abortCommand.id = .abort(MissionEmptyMessage())

        send(command: abortCommand)
    }

    func resetValue() {
        calibrationAltitudeAskSubject.value = nil
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

private extension OphtalmoServiceImpl {

    func sendCalibrationCommand(altitude: Float) {
        var config = OphtalmoMissionConfig()
        config.altitude = altitude
        var startCommand = MissionCommand()
        startCommand.id = .start(config)

        send(command: startCommand)
    }
}
