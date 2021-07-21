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
import CoreLocation
import SwiftyUserDefaults
import Combine

/// View model for drone details buttons.
final class DroneDetailsButtonsViewModel {

    // MARK: - Published Properties

    /// Gimbal state.
    @Published private(set) var gimbalState: CalibratableGimbalState?
    /// Drone's cellular network state.
    @Published private(set) var cellularStateDescription: String?
    /// Drone's flying state.
    @Published private(set) var flyingState: FlyingIndicatorsState?
    /// Whether a gimbal front stereo vision calibration is needed.
    @Published private(set) var isGimbalFrontStereoCalibrationNeeded: Bool = false
    /// Whether magnetometer calibration is needed.
    @Published private(set) var isMagnetometerCalibrationNeeded: Bool = false
    /// Whether a stereo vision sensor calibration is needed.
    @Published private(set) var isStereoVisionSensorCalibrationNeeded: Bool = false
    /// Drone's last known position.
    @Published private(set) var lastKnownPosition: CLLocation?
    /// Drone's cellular connection status.
    @Published private(set) var cellularStatus: DetailsCellularStatus = .noState
    /// Drone's connection state.
    @Published private(set) var connectionState: DeviceState.ConnectionState = .disconnected
    /// Tells if we can display the cellular modal.
    @Published private(set) var canShowCellular: Bool = false

    // MARK: - Private Properties

    private var gpsRef: Ref<Gps>?
    private var gimbalRef: Ref<Gimbal>?
    private var stereoVisionSensorRef: Ref<StereoVisionSensor>?
    private var magnetometerRef: Ref<MagnetometerWith3StepCalibration>?
    private var frontStereoGimbalRef: Ref<FrontStereoGimbal>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var connectionStateRef: Ref<DeviceState>?
    private let cellularViewModel = DroneDetailsCellularViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var currentDrone = Services.hub.currentDroneHolder

    // MARK: - Init

    init() {
        currentDrone.dronePublisher
            .sink { [unowned self] drone in
                listenGps(drone)
                listenGimbal(drone)
                listenStereoVisionSensor(drone)
                listenMagnetometer(drone)
                listenFrontStereoGimbal(drone)
                listenFlyingIndicators(drone: drone)
                listenConnectionState(drone: drone)
            }
            .store(in: &cancellables)

        cellularViewModel.$cellularStatus
            .sink { [unowned self] cellularStatus in updateCellularState(cellularStatus: cellularStatus) }
            .store(in: &cancellables)

        updateCellularState(cellularStatus: cellularStatus)

        cellularViewModel.$connectionState
            .removeDuplicates()
            .combineLatest($cellularStatus)
            .sink { [unowned self] (connectionState, cellularStatus) in
                canShowCellular = cellularStatus != .noState && connectionState == .connected
            }
            .store(in: &cancellables)
    }

    // MARK: Helpers

    /// Message to display if a calibration is needed.
    var calibrationMessage: AnyPublisher<String?, Never> {
        $connectionState
            .combineLatest($flyingState)
            .map { [unowned self] (connectionState, flyingState) in
                if !(connectionState == .connected) || flyingState == .flying {
                    return Style.dash
                } else if isMagnetometerCalibrationNeeded {
                    return L10n.droneDetailsCalibrationRequired
                } else if isStereoVisionSensorCalibrationNeeded {
                    return L10n.droneDetailsCalibrationLoveRequired
                } else if isGimbalFrontStereoCalibrationNeeded {
                    return L10n.droneDetailsCalibrationGimbalRequired
                } else {
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }

    /// Message to display on calibration button.
    var calibrationText: AnyPublisher<String?, Never> {
        calibrationMessage.map { [unowned self] (calibrationMessage: String?) in
            if calibrationMessage != nil {
                return calibrationMessage
            } else {
                guard let gimbal = currentDrone.drone.getPeripheral(Peripherals.gimbal) else {
                    return L10n.droneDetailsCalibrationOk
                }

                switch gimbal.state {
                case .calibrated,
                     .unavailable:
                    return L10n.droneDetailsCalibrationOk
                case .needed,
                     .error:
                    return L10n.droneDetailsCalibrationGimbalRequired
                case .recommended:
                    return L10n.droneDetailsCalibrationGimbalRecommended
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Tells if a calibration is needed.
    var isCalibrationNeeded: Bool {
        return isMagnetometerCalibrationNeeded
            || isStereoVisionSensorCalibrationNeeded
            || isGimbalFrontStereoCalibrationNeeded
    }

    /// Tells if calibration button is available.
    var isCalibrationButtonAvailable: AnyPublisher<Bool, Never> {
        $connectionState
            .combineLatest($flyingState)
            .map { (connectionState, flyingState) in
                return (connectionState == .connected) && flyingState == .landed
            }
            .eraseToAnyPublisher()
    }

    /// Background for calibration text cell.
    var calibrationBackgroundCellColor: AnyPublisher<ColorName?, Never> {
        $connectionState
            .combineLatest($flyingState)
            .map { [unowned self] (connectionState, flyingState) in
                if !(connectionState == .connected) || flyingState == .flying {
                    return .white10
                } else if isCalibrationNeeded {
                    return .redTorch25
                } else {
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }

    /// Color for calibration text cell.
    var calibrationMessageColor: AnyPublisher<ColorName?, Never> {
        $connectionState
            .combineLatest($flyingState)
            .map { [unowned self] (connectionState, flyingState) in
                if !(connectionState == .connected) || flyingState == .flying {
                    return .white50
                } else if isCalibrationNeeded {
                    return .redTorch
                } else {
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }

    /// Returns custom cellular button subtitle.
    var cellularButtonSubtitle: String {
        var subtitle: String = cellularStatus.droneDetailsTileDescription ?? ""

        if cellularStatus == .cellularConnected,
           let provider = currentDrone.drone.getPeripheral(Peripherals.cellular)?.operator {
            subtitle.append(Style.colon + Style.whiteSpace + provider)
        }
        return subtitle
    }

    /// Calibration description color.
    var calibrationTextColor: AnyPublisher<ColorName?, Never> {
        calibrationMessage.combineLatest(calibrationMessageColor)
            .map { [unowned self] (calibrationMessage, calibrationMessageColor) in
                if calibrationMessage != nil {
                    return calibrationMessageColor
                } else {
                    return currentDrone.drone.getPeripheral(Peripherals.gimbal)?.subtextColor ?? .white10
                }
            }
            .eraseToAnyPublisher()
    }

    /// Background color for calibration cell.
    var calibrationTextBackgroundColor: AnyPublisher<ColorName?, Never> {
        calibrationBackgroundCellColor.map { [unowned self] (calibrationBackgroundCellColor: ColorName?) -> ColorName? in
            if calibrationBackgroundCellColor != nil {
                return calibrationBackgroundCellColor
            } else {
                guard let gimbal = currentDrone.drone.getPeripheral(Peripherals.gimbal) else {
                    return .white10
                }

                return gimbal.backgroundColor
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Internal Funcs

    /// Removes current drone uid in the dismissed pairing list.
    /// The pairing process for the current drone could be displayed again in the HUD.
    func resetPairingDroneListIfNeeded() {
        let uid = currentDrone.drone.uid
        guard Defaults.dronesListPairingProcessHidden.contains(uid),
              currentDrone.drone.isAlreadyPaired == false else {
            return
        }

        Defaults.dronesListPairingProcessHidden.removeAll(where: { $0 == uid })
    }
}

// MARK: - Private Funcs

private extension DroneDetailsButtonsViewModel {

    /// Starts watcher for drone's connection state.
    ///
    /// - Parameter drone: the current drone
    func listenConnectionState(drone: Drone) {
        connectionStateRef = drone.getState { [weak self] state in
            self?.connectionState = state?.connectionState ?? .disconnected
        }
    }

    /// Starts watcher for gps.
    func listenGps(_ drone: Drone) {
        gpsRef = drone.getInstrument(Instruments.gps) { [weak self] gps in
            self?.lastKnownPosition = gps?.lastKnownLocation
        }
    }

    /// Starts watcher for gimbal.
    func listenGimbal(_ drone: Drone) {
        gimbalRef = drone.getPeripheral(Peripherals.gimbal) { [weak self] gimbal in
            self?.gimbalState = gimbal?.state
        }
    }

    /// Starts watcher for stereo vision sensor.
    func listenStereoVisionSensor(_ drone: Drone) {
        stereoVisionSensorRef = drone.getPeripheral(Peripherals.stereoVisionSensor) { [weak self] stereoVisionSensor in
            self?.updateStereoVisionSensorCalibrationState(stereoVisionSensors: stereoVisionSensor)
        }
    }

    /// Starts watcher for flying indicators.
    func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] flyingIndicators in
            guard let flyingState = flyingIndicators?.state else { return }
            self?.flyingState = flyingState
        }
    }

    /// Starts watcher for magnetometer.
    func listenMagnetometer(_ drone: Drone) {
        magnetometerRef = drone.getPeripheral(Peripherals.magnetometerWith3StepCalibration) { [weak self] magnetometer in
            self?.updateMagnetometerCalibrationState(magnetometer: magnetometer)
        }
    }

    /// Starts watcher for front stereo gimbal.
    func listenFrontStereoGimbal(_ drone: Drone) {
        frontStereoGimbalRef = drone.getPeripheral(Peripherals.frontStereoGimbal) { [weak self] frontStereoGimbal in
            self?.updateFrontStereoGimbal(frontStereoGimbal: frontStereoGimbal)
        }
    }

    /// Updates front stereo gimbal calibration state.
    func updateFrontStereoGimbal(frontStereoGimbal: FrontStereoGimbal?) {
        guard let frontStereoGimbal = frontStereoGimbal else {
            isGimbalFrontStereoCalibrationNeeded = false
            return
        }

        switch (frontStereoGimbal.calibrated, frontStereoGimbal.currentErrors.isEmpty) {
        case (false, true),
             (true, false):
            isGimbalFrontStereoCalibrationNeeded = true
        default:
            isGimbalFrontStereoCalibrationNeeded = false
        }
    }

    /// Updates stereo vision sensor calibration state.
    func updateStereoVisionSensorCalibrationState(stereoVisionSensors: StereoVisionSensor?) {
        guard let stereoVisionSensor = stereoVisionSensors else {
            isStereoVisionSensorCalibrationNeeded = false
            return
        }

        isStereoVisionSensorCalibrationNeeded = !stereoVisionSensor.isCalibrated
    }

    /// Updates magnetometer calibration state.
    func updateMagnetometerCalibrationState(magnetometer: MagnetometerWith3StepCalibration?) {
       guard let magnetometer = magnetometer else {
            isMagnetometerCalibrationNeeded = false
            return
        }

        switch magnetometer.calibrationState {
        case .calibrated:
            isMagnetometerCalibrationNeeded = false
        case .required,
             .recommended:
            isMagnetometerCalibrationNeeded = true
        }
    }

    /// Updates cellular state.
    func updateCellularState(cellularStatus: DetailsCellularStatus) {
        self.cellularStatus = cellularStatus
    }
}
