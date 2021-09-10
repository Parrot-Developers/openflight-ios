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

private extension ULogTag {
     static let tag = ULogTag(name: "StereoMissionReceivedValue")
}

enum CalibrationEndedState {
    case noError
    case error
    case aborted
}

final class StereoCalibrationViewModel {

    // MARK: - Published Properties

    @Published private(set) var missionState: MissionState?
    @Published private(set) var missionDescriptionMessage: NSAttributedString?
    @Published private(set) var calibrationStateMessage: String?
    @Published private(set) var calibrationPercentage: Float?
    @Published private(set) var calibrationStatus: Parrot_Missions_Ophtalmo_Airsdk_Messages_CalibrationStatus?
    @Published private(set) var calibrationEnded: CalibrationEndedState?
    @Published private(set) var calibrationButtonIsEnable: Bool = false
    @Published private(set) var isFlying: Bool = false
    @Published private(set) var gpsStrength: GpsStrength = .none
    @Published private(set) var satelliteCount: Int?

    // MARK: - Private Properties

    private let manager = ProtobufMissionsManager.shared
    private var listener: ProtobufMissionListener?
    private let signature = OFMissionSignatures.ophtalmo
    private var currentDrone = Services.hub.currentDroneHolder
    private var cancellables = Set<AnyCancellable>()
    private weak var coordinator: DroneCalibrationCoordinator?
    private var gpsRef: Ref<Gps>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?

    init(coordinator: DroneCalibrationCoordinator) {
        self.coordinator = coordinator
        descriptionTitle()

        currentDrone.dronePublisher
            .sink { [unowned self] drone in
                listenMission()
                listenGps(drone: drone)
                listenFlyingState(drone: drone)
            }
            .store(in: &cancellables)
    }

    private func listenMission() {
        listener = manager.register(
            for: signature,
            missionCallback: { [weak self] (state, message, _) in
                self?.missionState = state
                if let message = message {
                    do {
                        let event = try Parrot_Missions_Ophtalmo_Airsdk_Messages_Event(serializedData: message.payload)
                        ULog.i(.tag, "calibration status : \(event.state.calibrationStatus),"
                               + "\n calibration percent : \(event.state.completionPercent)"
                               + " \n calibration step \(event.state.calibrationStep)")
                        self?.calibrationStatus = event.state.calibrationStatus
                        self?.calibrationPercentage = Float(event.state.completionPercent)
                        self?.changeMissionLabel(state: event.state.calibrationStep)
                    } catch {
                        // Nothing to do.
                    }
                }
            })
    }

    /// Starts observing changes for gps strength and updates the gps Strength published property.
    ///
    /// - Parameter drone: The current drone
    func listenGps(drone: Drone?) {
        guard let drone = drone else {
            gpsStrength = .none
            satelliteCount = nil
            return
        }
        gpsRef = drone.getInstrument(Instruments.gps) { [weak self] gps in
            self?.gpsStrength = gps?.gpsStrength ?? .none
            self?.satelliteCount = gps?.satelliteCount
        }
    }

    /// Starts observing changes for flying indicators and updates the flyingState published property.
    ///
    /// - Parameter drone: The current drone
    func listenFlyingState(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] flyingIndicator in
            if flyingIndicator?.flyingState == .flying || flyingIndicator?.flyingState == .waiting {
                self?.isFlying = true
            } else {
                self?.isFlying = false
            }
        }
    }
}

// MARK: - Internal Funcs

extension StereoCalibrationViewModel {

    // MARK: - Mission

    /// Starts the ophtalmo mission.
    func startMission() {
        ULog.i(.tag, "Activate opthalmo mission")
        manager.activate(mission: signature)
    }

    /// Ends the ophtalmo mission.
    func endMission() {
        manager.deactivate(mission: signature)
    }

    /// Starts the stereo vision sensor calibration.
    ///
    /// - Parameter altitude: The altitude the drone will fly up to
    func startCalibration(altitude: Float = 0) {
        var config = Parrot_Missions_Ophtalmo_Airsdk_Messages_Config()
        config.altitude = altitude
        var startCommand = Parrot_Missions_Ophtalmo_Airsdk_Messages_Command()
        startCommand.id = .start(config)

        send(command: startCommand)
    }

    /// Cancels the stereo vision sensor calibration.
    func cancelCalibration() {
        var abortCommand = Parrot_Missions_Ophtalmo_Airsdk_Messages_Command()
        abortCommand.id = .abort(Google_Protobuf_Empty())

        send(command: abortCommand)
    }

    // MARK: - Navigation

    /// Dissmisses the view
    func back() {
        coordinator?.back()
    }

    /// Dismisses the progress view.
    /// - Parameter endState: The ended state of the calibration
    ///
    /// Changing the calibrationEndedState triggers an action in the parent view controller.
    func dismissProgressView(endState: CalibrationEndedState) {
        calibrationEnded = endState
    }

    // MARK: - Message Configuration

    /// Updates the description message with the altitude received.
    ///
    /// - Parameter altitude: The altitude the drone will fly up to
    func descriptionTitle(altitude: Int = 0) {
        let attributedText = NSMutableAttributedString(string: L10n.loveCalibrationSetupMessage)
        let myAttributes = [NSAttributedString.Key.font: UIFont(name: "Rajdhani-Semibold", size: 16.0) ?? UIFont.systemFont(ofSize: 10)]
        let attributedText2 = NSAttributedString(string: "\(altitude) m", attributes: myAttributes)

        attributedText.append(attributedText2)

        missionDescriptionMessage = attributedText
    }

    /// Updates the warning message.
    /// - Parameters:
    ///   - isFlying: The drone flying state.
    ///   - gpsStrength: The drone gps strength
    /// - Returns: The warning text the will be used.
    func warningText(isFlying: Bool, gpsStrength: GpsStrength) -> String {
        if isFlying == true {
            calibrationButtonIsEnable = false
            return L10n.loveCalibrationFlying
        }

        if gpsStrength == .notFixed || gpsStrength == .none || gpsStrength == .fixed1on5 {
            calibrationButtonIsEnable = false
            return L10n.loveCalibrationGps
        }

        calibrationButtonIsEnable = true
        return L10n.loveCalibrationReady
    }
}

private extension StereoCalibrationViewModel {

    /// Sends the protobuf command.
    func send(command: Parrot_Missions_Ophtalmo_Airsdk_Messages_Command) {
        guard let payload = try? command.serializedData() else {
            ULog.i(.tag, "Command ophtalmo not sent")
            return
        }

        let message = ProtobufMissionMessageToSend(mission: signature, payload: payload)
        manager.send(message: message)
    }

    /// Changes the label to match the corresponding step.
    ///
    /// - Parameter state: the current state of the calibration
    func changeMissionLabel(state: Parrot_Missions_Ophtalmo_Airsdk_Messages_CalibrationStep) {
        switch state {
        case .idle:
            calibrationStateMessage = L10n.loveCalibrationIdle
        case .takeoff, .takeoffDone:
            calibrationStateMessage = L10n.loveCalibrationTakeoff
        case .ascending, .ascendingDone:
            calibrationStateMessage = L10n.loveCalibrationAscending(120)
        case .turning, .turningDone:
            calibrationStateMessage = L10n.loveCalibrationTurning
        case .descending:
            calibrationStateMessage = L10n.loveCalibrationDescending
        case .descendingDone:
            calibrationStateMessage = "You can land the drone to end the calibration"
        case .landing:
            calibrationStateMessage = L10n.commonLanding
        case .landingDone:
            calibrationStateMessage = "Drone landed"
        case .UNRECOGNIZED(_):
            break
        }
    }
}
