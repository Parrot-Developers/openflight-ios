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

public enum CalibrationEndedState {
    case noError
    case error
    case aborted
}

public final class StereoCalibrationViewModel {

    private enum Constants {
        static let timerTolerance: TimeInterval = 0.2
        static let timerValue: TimeInterval = 10.0
        static let countDownDuration: Int = 3
        static let countDownInterval: TimeInterval = 1.0
    }

    // MARK: - Published Properties

    // Stereo calibration controller publishers

    @Published private(set) var calibrationEnded: CalibrationEndedState?
    @Published private(set) var isCalibrationButtonEnabled: Bool = false
    @Published private(set) var warningText: String?
    @Published private(set) var calibrationMessage: String = L10n.loveCalibrationSetupMessage
    @Published private(set) var subtitle: String?
    @Published private(set) var subtitleColor: UIColor = ColorName.defaultTextColor.color
    @Published private(set) var isCalibrationButtonHidden: Bool = false
    @Published private(set) var animationImages: [UIImage]?
    @Published private(set) var countdownMessage: String?

    // Progress view publishers

    @Published private(set) var shouldHideProgressView: Bool = false
    @Published private(set) var calibrationTitle: String?
    @Published private(set) var stopButtonHidden: Bool = false
    @Published private(set) var finishedButtonHidden: Bool = true
    @Published private(set) var finishedButtonHighlighted: Bool = true
    @Published private(set) var calibrationTitleHidden: Bool = false
    @Published private(set) var missionStateHidden: Bool = false
    @Published private(set) var calibrationHandLandingImageHidden: Bool = true
    @Published private(set) var calibrationCompleteImageHidden: Bool = true
    @Published private(set) var calibrationTitleColor: UIColor = ColorName.defaultTextColor.color
    @Published private(set) var landingButtonHidden: Bool = true
    @Published private(set) var calibrationMessageColor: UIColor = ColorName.highlightColor.color
    @Published private(set) var calibrationResultText: String?
    @Published private(set) var calibrationResultColor: UIColor = ColorName.errorColor.color
    @Published private(set) var calibrationResultHidden: Bool = true
    @Published private(set) var calibrationErrorText: String?
    @Published private(set) var calibrationErrorHidden: Bool = true
    @Published private(set) var shouldHideMessageLabel: Bool = false

    private var alertTimer: Timer?
    private var countdown: Int?

    var calibrationPercentage: AnyPublisher<Float?, Never> { ophtalmoService.calibrationPercentagePublisher }
    var calibrationStatus: AnyPublisher<OpthalmoMissionCalibrationStatus?, Never> {
        ophtalmoService.calibrationStatusPublisher
    }
    var calibrationStateMessage: AnyPublisher<String?, Never> {
        ophtalmoService.calibrationStepPublisher
            .removeDuplicates()
            .combineLatest(ophtalmoService.calibrationStatusPublisher.removeDuplicates(),
                           ophtalmoService.isFlyingPublisher.removeDuplicates())
            .map { [unowned self] (calibrationStep, _, _) in
                 return changeMissionLabel(state: calibrationStep)
            }
            .eraseToAnyPublisher()
    }

    var errorMessage: AnyPublisher<OphtalmoError?, Never> { ophtalmoService.errorAlertPublisher }
    var isFlying: AnyPublisher<Bool, Never> { ophtalmoService.isFlyingPublisher }

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private var coordinator: DroneCalibrationCoordinator?
    private weak var ophtalmoCoordinator: OphtalmoCoordinator?
    private var connectedDroneHolder = Services.hub.connectedDroneHolder
    private var calibrationAltitude: Float = 0
    unowned let ophtalmoService: OphtalmoService
    private var droneStateRef: Ref<DeviceState>?
    private var timer: Timer?

    init(coordinator: DroneCalibrationCoordinator?, ophtalmoService: OphtalmoService) {
        self.coordinator = coordinator
        self.ophtalmoService = ophtalmoService

        // Keep this line
        ophtalmoService.listenMission()

        updateShouldGoBack()
        updateWithCalibrationStatus()
        updateWarningText()
        listenDroneState()
    }

    init(coordinator: OphtalmoCoordinator?, ophtalmoService: OphtalmoService) {
        self.ophtalmoCoordinator = coordinator
        self.ophtalmoService = ophtalmoService

        // Keep this line
        ophtalmoService.listenMission()

        updateShouldGoBack()
        updateWithCalibrationStatus()
        updateWarningText()
        listenDroneState()
    }

    // MARK: - Deinit
    deinit {
        ophtalmoService.resetValue()
        ophtalmoService.unregisterListener()
        alertTimer?.invalidate()
        alertTimer = nil
        timer?.invalidate()
        timer = nil
        droneStateRef = nil
    }
}

// MARK: - Internal Funcs

extension StereoCalibrationViewModel {

    /// Updates the calibration altitude choosen by the user
    func updateCalibrationWith(altitude: Float) {
        calibrationAltitude = altitude
    }

    /// Lands the drone
    func landDrone() {
        guard let manualPiloting = connectedDroneHolder.drone?.getPilotingItf(PilotingItfs.manualCopter) else { return }

        manualPiloting.land()
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
    /// - Parameter altitude: the altitude the drone will fly up to
    func startCalibration(altitude: Float = 0) {
        calibrationAltitude = altitude
        ophtalmoService.startCalibration(altitude: altitude)
    }

    /// Cancels the stereo vision sensor calibration.
    func cancelCalibration() {
        ophtalmoService.cancelCalibration()
        shouldHideProgressView = true
    }

    // MARK: - Navigation

    /// Dismisses the view.
    func back() {
        Services.hub.currentMissionManager.provider.mission.defaultMode.missionActivationModel.startMission()
        coordinator?.back()
        ophtalmoCoordinator?.dismiss()
    }

    /// User asked for the back action.
    func askingForBack() {
        if ophtalmoService.isFlying {
            if alertTimer == nil {
                ophtalmoService.updateErrorAlert(.cannotStop)
                alertTimer = Timer.scheduledTimer(withTimeInterval: Constants.timerValue, repeats: false) { [weak self] _ in
                    self?.ophtalmoService.updateErrorAlert(nil)
                    self?.alertTimer = nil
                }
            }
            alertTimer?.tolerance = Constants.timerTolerance
        } else {
            back()
            ophtalmoService.resetActiveMission()
            dismissProgressView(endState: .noError)
        }
    }

    /// Opens settings view.
    ///
    /// - Parameters:
    ///     - type: settings type
    func openSettings(_ type: SettingsType?) {
        coordinator?.startSettings(type)
        ophtalmoCoordinator?.startSettings(type)
    }

    /// Opens remote infos view.
    func openRemoteControlInfos() {
        coordinator?.startRemoteInformation()
    }

    /// Opens drone infos view.
    func openDroneInfos() {
        coordinator?.startDroneInformation()
    }

    /// Dismisses the progress view.
    /// Changing the calibrationEndedState triggers an action in the parent view controller.
    ///
    /// - Parameter endState: the ended state of the calibration
    func dismissProgressView(endState: CalibrationEndedState) {
        calibrationEnded = endState
    }

    /// Stops the hand launch.
    func stop() {
        guard ophtalmoService.handLaunchState == .ready else { return }
        landDrone()
    }
}

// MARK: - Private Funcs

private extension StereoCalibrationViewModel {

    /// Starts watcher for drone state.
    func listenDroneState() {
        droneStateRef = connectedDroneHolder.drone?.getState { [unowned self] droneState in
            if droneState?.connectionState == .disconnected {
                askingForBack()
            }
        }
    }

    /// Listens the ophtalmo service to update if the calibration screen should be dismissed
    func updateShouldGoBack() {
        ophtalmoService
            .calibrationEndedPublisher
            .compactMap { $0 }
            .removeDuplicates()
            .combineLatest(ophtalmoService.isFlyingPublisher.removeDuplicates())
            .sink { [unowned self] (calibrationEnded, isFlying) in
                if calibrationEnded == .aborted {
                    shouldHideProgressView = true
                    if !isFlying {
                       askingForBack()
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
                           ophtalmoService.endLandingPublisher.removeDuplicates(),
                           ophtalmoService.isHandLandingPublisher.removeDuplicates())
            .sink { [unowned self] (status, isFlying, endIsLanding, isHandLanding) in
                switch status {
                case .ok:
                    calibrationTitleHidden = true
                    calibrationResultText = isHandLanding ? L10n.alertHandLandLanding : L10n.loveCalibrationOk
                    calibrationResultHidden = false
                    calibrationResultColor = ColorName.highlightColor.color
                    shouldHideProgressView = true
                    stopButtonHidden = true
                    finishedButtonHighlighted = true
                    missionStateHidden = true
                    if isFlying {
                        if endIsLanding {
                            landingButtonHidden = true
                        } else {
                            landingButtonHidden = isHandLanding
                            calibrationCompleteImageHidden = true
                        }
                        calibrationHandLandingImageHidden = !isHandLanding
                    } else {
                        landingButtonHidden = true
                        calibrationCompleteImageHidden = false
                        calibrationHandLandingImageHidden = true
                        finishedButtonHidden = false
                    }

                case .ko:
                    calibrationTitleHidden = true
                    calibrationResultText = isHandLanding ? L10n.alertHandLandLanding : L10n.loveCalibrationKo
                    calibrationResultHidden = false
                    calibrationResultColor = isHandLanding ? ColorName.highlightColor.color : ColorName.errorColor.color
                    shouldHideProgressView = true
                    stopButtonHidden = true
                    finishedButtonHighlighted = false
                    missionStateHidden = true

                    if isFlying {
                        landingButtonHidden = false
                        calibrationHandLandingImageHidden = !isHandLanding
                    } else {
                        landingButtonHidden = true
                        finishedButtonHidden = false
                        calibrationCompleteImageHidden = true
                        calibrationErrorHidden = false
                        calibrationErrorText = L10n.loveCalibrationKoAdvice
                    }

                case .aborted:
                    calibrationTitleHidden = false
                    shouldHideProgressView = true
                    stopButtonHidden = true
                    missionStateHidden = true
                    calibrationResultText = isHandLanding ? L10n.alertHandLandLanding : nil
                    calibrationResultHidden = !isHandLanding
                    calibrationResultColor = ColorName.highlightColor.color
                    calibrationErrorHidden = false
                    calibrationErrorText = L10n.loveCalibrationDone

                    if isFlying {
                        calibrationTitleColor = ColorName.defaultTextColor.color
                        calibrationTitle = L10n.loveCalibrationAborted
                        calibrationHandLandingImageHidden = !isHandLanding
                    } else {
                        askingForBack()
                    }

                case .inProgress:
                    calibrationTitleHidden = true

                default:
                    return
                }
            }
            .store(in: &cancellables)

    }

    /// Listens the opthalmo service to update the warning text
    func updateWarningText() {
        ophtalmoService.isFlyingPublisher
            .removeDuplicates()
            .sink { [unowned self] in
                calibrationMessage = $0 ? L10n.loveCalibrationSetupMessageInflight : L10n.loveCalibrationSetupMessage
            }
            .store(in: &cancellables)

        ophtalmoService
            .isFlyingPublisher
            .combineLatest(ophtalmoService.handLaunchStatePublisher,
                           ophtalmoService.gpsStrengthPublisher)
            .sink { [unowned self] (_, handLaunchState, gpsStrength) in
                updateView(handLaunchState: handLaunchState,
                           gpsStrength: gpsStrength)
            }
            .store(in: &cancellables)

        ophtalmoService.handLaunchStatePublisher
            .removeDuplicates()
            .sink { [unowned self] handLaunchState in
                switch handLaunchState {
                case .unavailable, .available:
                    resetCountdown()
                case .ready:
                    startCountdown()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Message Configuration

    /// Updates view.
    ///
    /// - Parameters:
    ///   - handLaunchState: the hand launch state
    ///   - gpsStrength: the drone gps strength
    func updateView(handLaunchState: OphtalmoHandLaunchState, gpsStrength: GpsStrength) {
        if gpsStrength == .notFixed || gpsStrength == .none || gpsStrength == .fixed1on5 {
            isCalibrationButtonEnabled = false
            warningText = L10n.loveCalibrationGps
            shouldHideMessageLabel = true
            updateHandLaunchView(.unavailable)
            return
        }

        isCalibrationButtonEnabled = true
        warningText = nil
        updateHandLaunchView(handLaunchState)
        shouldHideMessageLabel = isCalibrationButtonHidden
    }

    /// Changes the label to match the corresponding step.
    ///
    /// - Parameter state: the current state of the calibration
    /// - Returns : A string representing the current state of the mission
    func changeMissionLabel(state: OpthalmoMissionCalibrationStep) -> String? {
        switch state {
        case .idle:
            break
        case .takeoff, .takeoffDone:
            return L10n.loveCalibrationTakeoff
        case .ascending, .ascendingDone:
            return L10n.loveCalibrationAscending(Int(calibrationAltitude))
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

    /// Update screen from hand launch state.
    ///
    /// - Parameter handLaunchState: the current state of the hand launch
    func updateHandLaunchView(_ handLaunchState: OphtalmoHandLaunchState) {
        subtitle = handLaunchState.subtitle
        subtitleColor = handLaunchState.subtitleColor
        isCalibrationButtonHidden = handLaunchState.isCalibrationButtonsHidden
        let isAnimationVisible = handLaunchState.isCalibrationButtonsHidden && countdown == 0
        animationImages = isAnimationVisible ? Asset.Alertes.HandLaunch.Animation.allValues.compactMap { $0.image } : nil
        countdownMessage = countdown == 0 ? L10n.alertHandLaunchLaunch : countdown?.description
    }

    /// Resets countdown.
    func resetCountdown() {
        countdown = nil
        timer?.invalidate()
        timer = nil
        updateView(handLaunchState: ophtalmoService.handLaunchState,
                   gpsStrength: ophtalmoService.gpsStrength)
    }

    /// Starts countdown.
    func startCountdown() {
        guard timer == nil else { return }

        countdown = Constants.countDownDuration
        updateView(handLaunchState: ophtalmoService.handLaunchState,
                   gpsStrength: ophtalmoService.gpsStrength)
        timer = Timer.scheduledTimer(withTimeInterval: Constants.countDownInterval, repeats: true, block: { [weak self] _ in
            guard let self = self else { return }
            if let lastCountdown = self.countdown, lastCountdown > 0 {
                self.countdown = lastCountdown - Int(Constants.countDownInterval)
            } else {
                self.countdown = 0
                self.timer?.invalidate()
                self.timer = nil
            }
            self.updateView(handLaunchState: self.ophtalmoService.handLaunchState,
                            gpsStrength: self.ophtalmoService.gpsStrength)
        })
    }
}
