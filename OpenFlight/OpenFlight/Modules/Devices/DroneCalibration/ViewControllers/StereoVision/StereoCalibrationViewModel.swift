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

enum CalibrationEndedState {
    case noError
    case error
    case aborted
}

final class StereoCalibrationViewModel {

    // MARK: - Published Properties

    // Stereo calibration controller publishers

    @Published private(set) var calibrationEnded: CalibrationEndedState?
    @Published private(set) var calibrationButtonIsEnable: Bool = false
    @Published private(set) var warningText: String?

    // Progress view publishers

    @Published private(set) var shouldHideProgressView: Bool = false
    @Published private(set) var calibrationTitle: String?
    @Published private(set) var stopButtonHidden: Bool = false
    @Published private(set) var finishedButtonHidden: Bool = true
    @Published private(set) var missionStateHidden: Bool = false
    @Published private(set) var calibrationCompleteImageHidden: Bool = true
    @Published private(set) var calibrationTitleColor: UIColor = ColorName.defaultTextColor.color
    @Published private(set) var landingButtonHidden: Bool = true
    @Published private(set) var calibrationMessageColor: UIColor = ColorName.emerald.color

    var calibrationPercentage: AnyPublisher<Float?, Never> { ophtalmoService.calibrationPercentagePublisher }
    var calibrationStatus: AnyPublisher<Parrot_Missions_Ophtalmo_Airsdk_Messages_CalibrationStatus?, Never> {
        ophtalmoService.calibrationStatusPublisher
    }
    var calibrationStateMessage: AnyPublisher<String?, Never> {
        ophtalmoService.calibrationStepPublisher
            .combineLatest(ophtalmoService.calibrationStatusPublisher,
                           ophtalmoService.isFlyingPublisher)
            .map { [unowned self] (calibrationStep, calibrationStatus, isFlying) in
                if calibrationStatus == .aborted {
                    if isFlying {
                        calibrationMessageColor = ColorName.defaultTextColor.color
                        return L10n.loveCalibrationDone
                    }
                }

                if calibrationStatus == .ko {
                    if isFlying {
                        calibrationMessageColor = ColorName.defaultTextColor.color
                        return L10n.loveCalibrationDone
                    }
                    return L10n.loveCalibrationKoAdvice
                }

                if calibrationStatus == .ok {
                    if isFlying {
                        calibrationMessageColor = ColorName.defaultTextColor.color
                        return L10n.loveCalibrationDone
                    }
                }

                 return changeMissionLabel(state: calibrationStep)
            }
            .eraseToAnyPublisher()
    }

    var isFlying: AnyPublisher<Bool, Never> { ophtalmoService.isFlyingPublisher }
    var isLanded: AnyPublisher<Bool, Never> { ophtalmoService.isLandedPublisher }

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private weak var coordinator: DroneCalibrationCoordinator?
    private var connectedDroneHolder = Services.hub.connectedDroneHolder
    private var calibrationAltitude: Int = 0
    private let ophtalmoService: OphtalmoService

    init(coordinator: DroneCalibrationCoordinator, ophtalmoService: OphtalmoService) {
        self.coordinator = coordinator
        self.ophtalmoService = ophtalmoService

        // Keep this line
        ophtalmoService.listenMission()

        updateShouldGoBack()
        updateWithCalibrationStatus()
        updateWarningText()
    }

    // MARK: - Deinit
    deinit {
        ophtalmoService.resetValue()
        ophtalmoService.unregisterListener()
    }
}

// MARK: - Internal Funcs

extension StereoCalibrationViewModel {

    /// Updates the calibration altitude choosen by the user
    func updateCalibrationWith(altitude: Int) {
        calibrationAltitude = altitude
    }

    /// Lands the drone
    func landDrone() {
        guard let manualPiloting = connectedDroneHolder.drone?.getPilotingItf(PilotingItfs.manualCopter) else { return }

        manualPiloting.land()
    }

    /// Listens the ophtalmo service to update if the calibration screen should be dismissed
    func updateShouldGoBack() {
        ophtalmoService
            .calibrationEndedPublisher
            .compactMap { $0 }
            .removeDuplicates()
            .combineLatest(ophtalmoService.isLandedPublisher.removeDuplicates())
            .sink { [unowned self] (calibrationEnded, isLanded) in
                if calibrationEnded == .aborted {
                    shouldHideProgressView = true
                    if isLanded == true {
                       back()
                    }
                }
            }
            .store(in: &cancellables)
    }

    /// Listens the calibration status to update the different publishers
    func updateWithCalibrationStatus() {
        ophtalmoService
            .calibrationStatusPublisher
            .compactMap { $0 }
            .removeDuplicates()
            .combineLatest(ophtalmoService.isFlyingPublisher.removeDuplicates(),
                           ophtalmoService.isLandedPublisher.removeDuplicates())
            .sink { [unowned self] (status, isFlying, isLanded) in
                switch status {
                case .ok:
                    shouldHideProgressView = true
                    calibrationTitle = L10n.loveCalibrationOk
                    calibrationCompleteImageHidden = false
                    stopButtonHidden = true
                    if isFlying == true {
                        landingButtonHidden = false
                    }

                    if isLanded == true {
                        landingButtonHidden = true
                        finishedButtonHidden = false
                        missionStateHidden = true
                    }

                case .ko:
                    shouldHideProgressView = true
                    calibrationTitle = L10n.loveCalibrationKo
                    calibrationTitleColor = ColorName.errorColor.color
                    calibrationMessageColor = ColorName.defaultTextColor.color
                    stopButtonHidden = true

                    if isFlying {
                        landingButtonHidden = false
                    }

                    if isLanded == true {
                        landingButtonHidden = true
                        finishedButtonHidden = false
                        calibrationCompleteImageHidden = true
                    }

                case .aborted:
                    shouldHideProgressView = true
                    stopButtonHidden = true
                    if isFlying == true {
                        calibrationTitleColor = ColorName.defaultTextColor.color
                        calibrationTitle = L10n.loveCalibrationAborted
                    }
                    if isLanded == true {
                        back()
                    }

                default:
                    return
                }
            }
            .store(in: &cancellables)

    }

    /// Listens the opthalmo service to update the warning text
    func updateWarningText() {
        ophtalmoService
            .isFlyingPublisher
            .combineLatest(ophtalmoService.gpsStrengthPublisher)
            .sink { [unowned self] (isFlying, gpsStrength) in
                warningTextWith(isFlying: isFlying, gpsStrength: gpsStrength)
            }
            .store(in: &cancellables)
    }

    // MARK: - Mission

    /// Starts the ophtalmo mission.
    func startMission() {
        ophtalmoService.startMission()
    }

    /// Ends the ophtalmo mission.
    func endMission() {
        ophtalmoService.endMission()
    }

    /// Starts the stereo vision sensor calibration.
    ///
    /// - Parameter altitude: The altitude the drone will fly up to
    func startCalibration(altitude: Float = 0) {
        ophtalmoService.startCalibration(altitude: altitude)
    }

    /// Cancels the stereo vision sensor calibration.
    func cancelCalibration() {
        ophtalmoService.cancelCalibration()
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

    /// Updates the warning message.
    /// - Parameters:
    ///   - isFlying: The drone flying state.
    ///   - gpsStrength: The drone gps strength.
    func warningTextWith(isFlying: Bool, gpsStrength: GpsStrength) {
        if isFlying == true {
            calibrationButtonIsEnable = false
            warningText = L10n.loveCalibrationFlying
        }

        if gpsStrength == .notFixed || gpsStrength == .none || gpsStrength == .fixed1on5 {
            calibrationButtonIsEnable = false
            warningText = L10n.loveCalibrationGps
        }

        calibrationButtonIsEnable = true
        warningText = L10n.loveCalibrationReady
    }

    /// Changes the label to match the corresponding step.
    ///
    /// - Parameter state: the current state of the calibration
    /// - Returns : A string representing the current state of the mission
    func changeMissionLabel(state: Parrot_Missions_Ophtalmo_Airsdk_Messages_CalibrationStep) -> String? {
        switch state {
        case .idle:
            break
        case .takeoff, .takeoffDone:
            return L10n.loveCalibrationTakeoff
        case .ascending, .ascendingDone:
            return L10n.loveCalibrationAscending(calibrationAltitude)
        case .turning, .turningDone:
            return L10n.loveCalibrationTurning
        case .descending:
            return L10n.loveCalibrationDescending
        case .descendingDone:
            shouldHideProgressView = true
        case .landing:
            return L10n.commonLanding
        case .landingDone:
            return "Drone landed"
        case .UNRECOGNIZED:
            break
        }
        return nil
    }
}
