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

public final class StereoCalibrationViewModel {

    private enum Constants {
        static let timerTolerance: TimeInterval = 0.2
        static let timerValue: TimeInterval = 10.0
    }

    // MARK: - Published Properties

    // Stereo calibration controller publishers

    @Published private(set) var calibrationStateText: String?
    @Published private(set) var calibrationStateColor: UIColor = ColorName.defaultTextColor80.color
    @Published private(set) var calibrationStateHidden: Bool = true
    @Published private(set) var isCalibrationButtonEnabled: Bool = false
    @Published private(set) var warningText: String?
    @Published private(set) var calibrationMessage: String = L10n.loveCalibrationSetupMessage

    var shouldHideProgressViewPublisher: AnyPublisher<Bool, Never> {
        ophtalmoService.calibrationStatusPublisher
            .combineLatest(connectedDroneHolder.dronePublisher)
            .map { status, drone in
                status == .idle || drone == nil
            }
            .eraseToAnyPublisher()
    }

    // Progress view publishers

    @Published private(set) var shouldHideCircleProgressView: Bool = false
    @Published private(set) var stopButtonHidden: Bool = false
    @Published private(set) var finishedButtonHidden: Bool = true
    @Published private(set) var finishedButtonStyle: ActionButtonStyle = .validate
    @Published private(set) var missionStateHidden: Bool = false
    @Published private(set) var calibrationCompleteImage: UIImage = Asset.Common.Checks.icFillChecked.image
    @Published private(set) var calibrationCompleteImageHidden: Bool = true
    @Published private(set) var landingButtonHidden: Bool = true
    @Published private(set) var calibrationMessageColor: UIColor = ColorName.highlightColor.color
    @Published private(set) var calibrationErrorText: String?
    @Published private(set) var calibrationErrorHidden: Bool = true
    @Published private(set) var shouldHideMessageLabel: Bool = false
    @Published private(set) var alertMessage: String?

    private var alertTimer: Timer?

    var calibrationPercentagePublisher: AnyPublisher<Float?, Never> { ophtalmoService.calibrationPercentagePublisher }
    var calibrationStateMessage: AnyPublisher<String?, Never> {
        ophtalmoService.calibrationStepPublisher
            .removeDuplicates()
            .map { [unowned self] calibrationStep in
                 return getMissionLabel(state: calibrationStep)
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private var coordinator: DroneCalibrationCoordinator?
    private weak var ophtalmoCoordinator: OphtalmoCoordinator?
    private var connectedDroneHolder: ConnectedDroneHolder
    unowned let ophtalmoService: OphtalmoService
    private let handLaunchService: HandLaunchService
    /// Reference to drone state information.
    private var droneStateRef: Ref<DeviceState>?

    init(coordinator: DroneCalibrationCoordinator?,
         connectedDroneHolder: ConnectedDroneHolder,
         ophtalmoService: OphtalmoService,
         handLaunchService: HandLaunchService) {
        self.coordinator = coordinator
        self.connectedDroneHolder = connectedDroneHolder
        self.ophtalmoService = ophtalmoService
        self.handLaunchService = handLaunchService

        commonInit()
    }

    init(coordinator: OphtalmoCoordinator?,
         connectedDroneHolder: ConnectedDroneHolder,
         ophtalmoService: OphtalmoService,
         handLaunchService: HandLaunchService) {
        self.ophtalmoCoordinator = coordinator
        self.connectedDroneHolder = connectedDroneHolder
        self.ophtalmoService = ophtalmoService
        self.handLaunchService = handLaunchService

        commonInit()
    }

    // MARK: - Deinit
    deinit {
        ophtalmoService.unregisterListener()
        ophtalmoService.resetValue()
        alertTimer?.invalidate()
        alertTimer = nil
        droneStateRef = nil
    }
}

// MARK: - Internal Funcs

extension StereoCalibrationViewModel {

    /// Lands the drone
    func landDrone() {
        ophtalmoService.landDrone()
    }

    // MARK: - Mission

    /// Starts the ophtalmo mission.
    func startMission() {
        ophtalmoService.startMission()
    }

    /// Starts the stereo vision sensor calibration.
    ///
    /// - Parameter altitude: the altitude the drone will fly up to
    func startCalibration(altitude: Float = 0) {
        ophtalmoService.startCalibration(altitude: altitude)
    }

    /// Cancels the stereo vision sensor calibration.
    func cancelCalibration() {
        ophtalmoService.cancelCalibration()
    }

    /// Finishes the stereo vision sensor calibration.
    func finishCalibration() {
        switch ophtalmoService.calibrationStatus {
        case .aborted, .ko:
            ophtalmoService.resetCalibration()
        default:
            askingForBack()
        }
    }

    // MARK: - Navigation

    /// Dismisses the view.
    func back() {
        Services.hub.currentMissionManager.provider.mission.defaultMode.missionActivationModel.startMission()
        coordinator?.back()
        ophtalmoCoordinator?.dismissCoordinatorWithAnimator()
    }

    /// User asked for the back action.
    func askingForBack() {
        if ophtalmoService.isFlying {
            if alertTimer == nil {
                alertMessage = L10n.ophtalmoStopLand
                alertTimer = Timer.scheduledTimer(withTimeInterval: Constants.timerValue, repeats: false) { [weak self] _ in
                    guard let self = self else { return }
                    self.alertMessage = nil
                    self.alertTimer = nil
                }
                alertTimer?.tolerance = Constants.timerTolerance
            }
        } else {
            back()
            ophtalmoService.resetActiveMission()
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

    /// Stops the hand launch.
    func stopHandLaunch() {
        landDrone()
    }
}

// MARK: - Private Funcs

private extension StereoCalibrationViewModel {

    /// Common init
    func commonInit() {
        // Keep this line
        ophtalmoService.listenMission()

        updateWithCalibrationStatus()
        updateWarningText()
    }

    /// Listens the calibration status to update the different publishers
    func updateWithCalibrationStatus() {
        ophtalmoService.calibrationStatusPublisher
            .removeDuplicates()
            .combineLatest(connectedDroneHolder.dronePublisher)
            .sink { [unowned self] status, drone in
                let isDroneConnected = drone != nil
                switch status {
                case .ok:
                    calibrationStateText = L10n.loveCalibrationOk.uppercased()
                    calibrationStateHidden = !isDroneConnected
                    calibrationStateColor = ColorName.highlightColor.color
                    calibrationCompleteImage = Asset.Common.Checks.icFillChecked.image
                    finishedButtonStyle = .validate

                case .ko:
                    calibrationStateText = L10n.loveCalibrationKo.uppercased()
                    calibrationStateHidden = !isDroneConnected
                    calibrationStateColor = ColorName.errorColor.color
                    calibrationCompleteImage = Asset.Common.Icons.icFillCross.image
                    finishedButtonStyle = .destructive
                    calibrationErrorText = L10n.loveCalibrationKoAdvice

                case .aborted:
                    calibrationStateText = L10n.loveCalibrationInterrupted.uppercased()
                    calibrationStateHidden = !isDroneConnected
                    calibrationStateColor = ColorName.errorColor.color
                    calibrationCompleteImage = Asset.Common.Icons.icFillCross.image
                    finishedButtonStyle = .destructive

                case .inProgress:
                    calibrationStateText = L10n.loveCalibrationInProgress.uppercased()
                    calibrationStateHidden = !isDroneConnected
                    calibrationStateColor = ColorName.defaultTextColor80.color

                case .idle:
                    calibrationStateText = nil
                    calibrationStateHidden = true
                    calibrationStateColor = ColorName.defaultTextColor80.color

                default:
                    break
                }
            }
            .store(in: &cancellables)

        ophtalmoService.calibrationStatusPublisher
            .removeDuplicates()
            .combineLatest(ophtalmoService.calibrationStepPublisher.removeDuplicates(),
                           ophtalmoService.isFlyingPublisher.removeDuplicates())
            .sink { [unowned self] status, step, isFlying in
                switch (step, status) {
                case (.idle, .ok):
                    calibrationCompleteImageHidden = isFlying
                    landingButtonHidden = !isFlying
                    finishedButtonHidden = isFlying
                    calibrationErrorHidden = true
                    shouldHideCircleProgressView = true
                    stopButtonHidden = true

                case (.idle, .ko):
                    calibrationCompleteImageHidden = isFlying
                    landingButtonHidden = !isFlying
                    finishedButtonHidden = isFlying
                    calibrationErrorHidden = isFlying
                    shouldHideCircleProgressView = true
                    stopButtonHidden = true

                case (.idle, .aborted):
                    calibrationCompleteImageHidden = isFlying
                    landingButtonHidden = !isFlying
                    finishedButtonHidden = isFlying
                    calibrationErrorHidden = true
                    shouldHideCircleProgressView = true
                    stopButtonHidden = true

                case (.idle, _):
                    calibrationCompleteImageHidden = true
                    landingButtonHidden = true
                    finishedButtonHidden = true
                    calibrationErrorHidden = true
                    shouldHideCircleProgressView = true
                    stopButtonHidden = true

                case (_, _):
                    calibrationCompleteImageHidden = true
                    landingButtonHidden = true
                    finishedButtonHidden = true
                    calibrationErrorHidden = true
                    shouldHideCircleProgressView = false
                    stopButtonHidden = false
                }
            }
            .store(in: &cancellables)
    }

    /// Listens the opthalmo service to update the warning text
    func updateWarningText() {
        ophtalmoService.isFlyingPublisher
            .removeDuplicates()
            .combineLatest(handLaunchService.canStartPublisher.removeDuplicates())
            .sink { [unowned self] isFlying, canStart in
                calibrationMessage = isFlying || canStart ? L10n.loveCalibrationSetupMessageInflight : L10n.loveCalibrationSetupMessage
            }
            .store(in: &cancellables)

        ophtalmoService.isFlyingPublisher
            .combineLatest(connectedDroneHolder.dronePublisher, ophtalmoService.gpsStrengthPublisher)
            .sink { [unowned self] _, drone, gpsStrength in
                updateView(isDroneConnected: drone != nil, gpsStrength: gpsStrength)
            }
            .store(in: &cancellables)
    }

    // MARK: - Message Configuration

    /// Updates view.
    ///
    /// - Parameters:
    ///   - isDroneConnected: `true`if the drone is connected, `false` otherwise
    ///   - gpsStrength: the drone gps strength
    func updateView(isDroneConnected: Bool, gpsStrength: GpsStrength) {
        if !isDroneConnected {
            isCalibrationButtonEnabled = false
            warningText = L10n.commonDroneNotConnected
            shouldHideMessageLabel = true
            return
        }

        if gpsStrength == .notFixed || gpsStrength == .none || gpsStrength == .fixed1on5 {
            isCalibrationButtonEnabled = false
            warningText = L10n.loveCalibrationGps
            shouldHideMessageLabel = true
            return
        }

        isCalibrationButtonEnabled = true
        warningText = nil
        shouldHideMessageLabel = false
    }

    /// Gets the label to match the corresponding step.
    ///
    /// - Parameter state: the current state of the calibration
    /// - Returns : A string representing the current state of the mission
    func getMissionLabel(state: OpthalmoMissionCalibrationStep) -> String? {
        switch state {
        case .idle:
            break
        case .takeoff, .takeoffDone:
            return L10n.loveCalibrationTakeoff
        case .ascending, .ascendingDone:
            return L10n.loveCalibrationAscending(Int(ophtalmoService.altitude))
        case .turning, .turningDone:
            return L10n.loveCalibrationTurning
        case .descending, .descendingDone:
            return L10n.loveCalibrationDescending
        case .landing, .landingDone:
            return L10n.commonLanding
        case .UNRECOGNIZED:
            break
        }
        return nil
    }
}
