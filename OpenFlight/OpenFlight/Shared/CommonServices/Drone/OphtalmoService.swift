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

private extension ULogTag {
    static let tag = ULogTag(name: "OphtalmoService")
}

protocol OphtalmoService: AnyObject {

    /// The calibration progress of the mission
    var calibrationPercentagePublisher: AnyPublisher<Float?, Never> { get }
    /// The current status of the mission
    var calibrationStatusPublisher: AnyPublisher<OpthalmoMissionCalibrationStatus, Never> { get }
    /// The current step of the calibration
    var calibrationStepPublisher: AnyPublisher<OpthalmoMissionCalibrationStep, Never> { get }
    /// The current altitude asked.
    var calibrationAltitudeAskPublisher: AnyPublisher<Float?, Never> { get }
    /// Indicates if the drone is flying
    var isFlyingPublisher: AnyPublisher<Bool, Never> { get }
    /// Publisher of the current gps strength
    var gpsStrengthPublisher: AnyPublisher<GpsStrength, Never> { get }
    /// The current gps strength
    var gpsStrength: GpsStrength { get }
    /// The current handlanding state
    var isHandLandingPublisher: AnyPublisher<Bool, Never> { get }
    /// The current calibration status
    var calibrationStatus: OpthalmoMissionCalibrationStatus? { get }
    /// The current flying status
    var isFlying: Bool { get }
    /// The last state of the mission publisher.
    var ophtalmoLastMissionStatePublisher: AnyPublisher<MissionState?, Never> { get }
    /// The last state of the mission value.
    var ophtalmoLastMissionState: MissionState? { get }
    /// Whether hand calibration can be start.
    var canStartHandCalibration: Bool { get }
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
    /// Starts the ophtalmo mission with hand launch
    func startHandCalibration()
    /// Stops the calibration
    func cancelCalibration()
    /// Resets the calibration
    func resetCalibration()
    /// Reset all the values of the ophtalmo service
    func resetValue()
    /// Reset active mission
    func resetActiveMission()
    /// Lands the drone.
    func landDrone()
}

final class OphtalmoServiceImpl {

    private var airSdkMissionManager: AirSdkMissionsManager
    private var airsdkMissionsListener: AirSdkMissionsListener
    private var listener: AirSdkMissionListener?
    private let signature = OFMissionSignatures.ophtalmo
    private var messageUidGenerator = AirSdkMissionMessageToSend.UidGenerator(0)
    private var connectedDroneHolder: ConnectedDroneHolder
    private var handLaunchService: HandLaunchService

    private var calibrationPercentageSubject = CurrentValueSubject<Float?, Never>(nil)
    private var calibrationAltitudeSubject = CurrentValueSubject<Float?, Never>(nil)
    private var calibrationStatusSubject = CurrentValueSubject<OpthalmoMissionCalibrationStatus?, Never>(nil)
    private var calibrationStepSubject = CurrentValueSubject<OpthalmoMissionCalibrationStep?, Never>(nil)
    private var isFlyingSubject = CurrentValueSubject<Bool, Never>(false)
    private var gpsStrengthSubject = CurrentValueSubject<GpsStrength, Never>(.none)
    private var ophtalmoLastMissionStateSubject = CurrentValueSubject<MissionState?, Never>(nil)
    private var isHandLandingSubject = CurrentValueSubject<Bool, Never>(false)
    private var calibrationAltitudeAskSubject = CurrentValueSubject<Float?, Never>(nil)

    /// Reference to gps instrument.
    private var gpsRef: Ref<Gps>?
    /// Reference to flying indicators instrument.
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    /// Reference to return home piloting interface.
    private var returnHomePilotingRef: Ref<ReturnHomePilotingItf>?

    private var cancellables = Set<AnyCancellable>()
    init(connectedDroneHolder: ConnectedDroneHolder,
         handLaunchService: HandLaunchService,
         airSdkMissionManager: AirSdkMissionsManager,
         airsdkMissionsListener: AirSdkMissionsListener) {
        self.connectedDroneHolder = connectedDroneHolder
        self.handLaunchService = handLaunchService
        self.airSdkMissionManager = airSdkMissionManager
        self.airsdkMissionsListener = airsdkMissionsListener

        connectedDroneHolder.dronePublisher
            .sink { [unowned self] drone in
                listenGps(drone: drone)
                listenFlyingState(drone: drone)
                listenStatus(drone: drone)
            }
            .store(in: &cancellables)

        handLaunchService.isDisabledByUserPublisher
            .removeDuplicates()
            .sink { [unowned self] isDisabledByUser in
                // Clears pending calibration if user disables hand launch.
                if isDisabledByUser {
                    ULog.i(.tag, "Clears pending calibration (reason: disabled by user)")
                    calibrationAltitudeAskSubject.value = nil
                }
            }
            .store(in: &cancellables)

        handLaunchService.canStartPublisher
            .removeDuplicates()
            .sink { [unowned self] canStart in
                if !canStart,
                   connectedDroneHolder.drone?.getPilotingItf(PilotingItfs.manualCopter)?.smartTakeOffLandAction == .takeOff {
                    ULog.i(.tag, "Clears pending calibration (reason: land drone manually)")
                    calibrationAltitudeAskSubject.value = nil
                }
            }
            .store(in: &cancellables)

        isFlyingPublisher
            .removeDuplicates()
            .combineLatest(calibrationAltitudeAskPublisher.removeDuplicates())
            .sink { [unowned self] isFlying, altitudeAsk in
                guard isFlying, altitudeAsk != nil else { return }
                ULog.i(.tag, "Clears pending calibration (reason: drone launched)")
                calibrationAltitudeAskSubject.value = nil
            }
            .store(in: &cancellables)

        isHandLandingPublisher
            .removeDuplicates()
            .sink { isHandLanding in
                ULog.i(.tag, "isHandLanding : \(isHandLanding)")
            }
            .store(in: &cancellables)

        calibrationAltitudeAskPublisher
            .removeDuplicates()
            .sink { altitudeAsk in
                ULog.i(.tag, "altitudeAsk : \(String(describing: altitudeAsk))")
            }
            .store(in: &cancellables)

        ophtalmoLastMissionStatePublisher
            .removeDuplicates()
            .sink { lastMissionState in
                ULog.i(.tag, "lastMissionState : \(String(describing: lastMissionState))")
            }
            .store(in: &cancellables)

        calibrationStatusPublisher
            .removeDuplicates()
            .sink { calibrationStatus in
                ULog.i(.tag, "calibrationStatus : \(calibrationStatus)")
            }
            .store(in: &cancellables)

        calibrationStepPublisher
            .removeDuplicates()
            .sink { calibrationStep in
                ULog.i(.tag, "calibrationStep : \(calibrationStep)")
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
        }
    }

    /// Starts watcher for mission manager peripheral.
    ///
    /// - Parameters:
    ///    - drone: the current drone
    func listenStatus(drone: Drone?) {
        guard let drone = drone else {
            ophtalmoLastMissionStateSubject.value = nil
            return
        }
        ophtalmoLastMissionStateSubject.value = getMissionState(drone: drone)
    }
}

extension OphtalmoServiceImpl: OphtalmoService {
    var altitude: Float {
        calibrationAltitudeAskSubject.value ?? (calibrationAltitudeSubject.value ?? 0)
    }
    var calibrationPercentagePublisher: AnyPublisher<Float?, Never> {
        calibrationPercentageSubject.eraseToAnyPublisher()
    }
    var calibrationStatusPublisher: AnyPublisher<OpthalmoMissionCalibrationStatus, Never> {
        calibrationStatusSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    var calibrationStatus: OpthalmoMissionCalibrationStatus? {
        calibrationStatusSubject.value
    }
    var isFlying: Bool {
        isFlyingSubject.value
    }
    var gpsStrength: GpsStrength {
        gpsStrengthSubject.value
    }

    var ophtalmoLastMissionStatePublisher: AnyPublisher<MissionState?, Never> {
        ophtalmoLastMissionStateSubject.eraseToAnyPublisher()
    }
    var calibrationStepPublisher: AnyPublisher<OpthalmoMissionCalibrationStep, Never> {
        calibrationStepSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    var calibrationAltitudeAskPublisher: AnyPublisher<Float?, Never> {
        calibrationAltitudeAskSubject.eraseToAnyPublisher()
    }
    var isFlyingPublisher: AnyPublisher<Bool, Never> { isFlyingSubject.eraseToAnyPublisher() }
    var gpsStrengthPublisher: AnyPublisher<GpsStrength, Never> { gpsStrengthSubject.eraseToAnyPublisher() }
    var isHandLandingPublisher: AnyPublisher<Bool, Never> { isHandLandingSubject.eraseToAnyPublisher() }

    var ophtalmoLastMissionState: MissionState? { ophtalmoLastMissionStateSubject.value }

    var canStartHandCalibration: Bool {
        getMissionState(drone: connectedDroneHolder.drone) == .active
            && calibrationAltitudeAskSubject.value != nil
    }

    func listenMission() {
        listener = airsdkMissionsListener.register(
            for: signature,
            missionCallback: { [weak self] (_, message, _) in
                guard let self = self,
                      let message = message else { return }

                do {
                    let event = try MissionEvent(serializedData: message.payload)
                    guard self.calibrationAltitudeAskSubject.value == nil || event.state.calibrationStatus != .aborted else {
                        self.resetCalibration()
                        return
                    }
                    self.calibrationAltitudeSubject.value = event.state.config.altitude
                    self.calibrationStepSubject.value = event.state.calibrationStep
                    self.calibrationStatusSubject.value = event.state.calibrationStatus
                    self.calibrationPercentageSubject.value = Float(event.state.completionPercent)
                } catch {
                    // Nothing to do.
                }
            })
    }

    func unregisterListener() {
        airsdkMissionsListener.unregister(listener)
    }

    func startMission() {
        airSdkMissionManager.activate(mission: signature)
    }

    func endMission() {
        airSdkMissionManager.deactivate(mission: signature)
    }

    func startCalibration(altitude: Float) {
        if handLaunchService.canStart {
            calibrationAltitudeAskSubject.value = altitude
        } else {
            calibrationAltitudeAskSubject.value = nil
            sendCalibrationCommand(altitude: altitude)
        }
    }

    func startHandCalibration() {
        guard let altitude = calibrationAltitudeAskSubject.value else {
            return
        }
        sendCalibrationCommand(altitude: altitude, isHand: true)
    }

    func cancelCalibration() {
        var abortCommand = MissionCommand()
        abortCommand.id = .abort(MissionEmptyMessage())

        send(command: abortCommand)
    }

    func resetCalibration() {
        var resetCommand = MissionCommand()
        resetCommand.id = .resetStatus(MissionEmptyMessage())

        send(command: resetCommand)
    }

    func resetValue() {
        calibrationAltitudeAskSubject.value = nil
        calibrationPercentageSubject.value = nil
        calibrationStatusSubject.value = nil
        calibrationStepSubject.value = nil
    }

    func resetActiveMission() {
        ophtalmoLastMissionStateSubject.value = nil
    }

    func landDrone() {
        guard let manualPiloting = connectedDroneHolder.drone?.getPilotingItf(PilotingItfs.manualCopter) else { return }
        manualPiloting.land()
    }
}

private extension OphtalmoServiceImpl {

    func sendCalibrationCommand(altitude: Float, isHand: Bool = false) {
        var config = OphtalmoMissionConfig()
        config.altitude = altitude
        var startCommand = MissionCommand()
        startCommand.id = isHand ? .startHand(config) : .start(config)

        send(command: startCommand)
    }

    func getMissionState(drone: Drone?) -> MissionState? {
        let missionManager = drone?.getPeripheral(Peripherals.missionManager)
        let missionOphtalmo = missionManager?.missions[signature.missionUID]
        return missionOphtalmo?.state
    }
}
