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
    /// Whether a gimbal calibration is needed.
    @Published private(set) var isGimbalCalibrationNeeded: Bool = false
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
    /// Tells if we can display the cellular modal.
    @Published private(set) var mapThumbnail: UIImage? = Asset.MyFlights.poi.image

    // MARK: - Private Properties
    private var gpsRef: Ref<Gps>?
    private var gimbalRef: Ref<Gimbal>?
    private var stereoVisionSensorRef: Ref<StereoVisionSensor>?
    private var magnetometerRef: Ref<MagnetometerWith3StepCalibration>?
    private var frontStereoGimbalRef: Ref<FrontStereoGimbal>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var connectionStateRef: Ref<DeviceState>?
    private var cancellables = Set<AnyCancellable>()
    private var currentDrone = Services.hub.currentDroneHolder
    private var pairingService = Services.hub.drone.cellularPairingService
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

        pairingService.cellularStatusPublisher
            .sink { [unowned self] cellularStatus in updateCellularState(cellularStatus: cellularStatus) }
            .store(in: &cancellables)

        updateCellularState(cellularStatus: cellularStatus)

        $connectionState
            .removeDuplicates()
            .combineLatest(pairingService.cellularStatusPublisher)
            .sink { [unowned self] (connectionState, cellularStatus) in
                canShowCellular = cellularStatus != .noState && connectionState == .connected
            }
            .store(in: &cancellables)
    }

    // MARK: Helpers
    /// Subtitle to display on calibration button.
    var calibrationSubtitle: AnyPublisher<String?, Never> {
        $connectionState
            .combineLatest($flyingState)
            .combineLatest($isMagnetometerCalibrationNeeded,
                           $isGimbalFrontStereoCalibrationNeeded,
                           $isStereoVisionSensorCalibrationNeeded)
            .map { [unowned self] (arg0, isMagnetometerNeeded, isGimbalFrontNeeded, isStereoNeeded) in
                let (connectionState, flyingState) = arg0
                if !(connectionState == .connected) || flyingState == .flying {
                    return L10n.droneDetailsCalibrationOk
                } else if isMagnetometerNeeded {
                    return L10n.droneDetailsCalibrationRequired
                } else if isStereoNeeded {
                    return L10n.droneDetailsCalibrationLoveRequired
                } else if isGimbalFrontNeeded {
                    return L10n.droneDetailsCalibrationGimbalRequired
                } else {
                    let gimbalState = currentDrone.drone.getPeripheral(Peripherals.gimbal)?.state
                    switch gimbalState {
                    case .needed,
                         .error:
                        return L10n.droneDetailsCalibrationGimbalRequired
                    case .recommended:
                        return L10n.droneDetailsCalibrationGimbalRecommended
                    default:
                        return L10n.droneDetailsCalibrationOk
                    }
                }
            }
            .eraseToAnyPublisher()
    }

    /// Tells if a calibration is needed.
    var isCalibrationNeeded: AnyPublisher<Bool, Never> {
        $isMagnetometerCalibrationNeeded
            .combineLatest($isStereoVisionSensorCalibrationNeeded,
                           $isGimbalFrontStereoCalibrationNeeded)
            .map { $0 || $1 || $2 }
            .eraseToAnyPublisher()
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

    /// Title color for calibration.
    var calibrationTitleColor: AnyPublisher<ColorName?, Never> {
        $connectionState
            .combineLatest($flyingState,
                           isCalibrationNeeded)
            .map { [unowned self] (connectionState, flyingState, isCalibrationNeeded) in
                if !(connectionState == .connected) || flyingState == .flying {
                    return .defaultTextColor
                } else if isCalibrationNeeded {
                    return .white
                } else {
                    return currentDrone.drone.getPeripheral(Peripherals.gimbal)?.titleColor ?? .white
                }
            }
            .eraseToAnyPublisher()
    }

    /// Background for calibration cell.
    var calibrationBackgroundColor: AnyPublisher<ColorName?, Never> {
        $connectionState
            .combineLatest($flyingState,
                           isCalibrationNeeded)
            .map { [unowned self] (connectionState, flyingState, isCalibrationNeeded) in
                if !(connectionState == .connected) || flyingState == .flying {
                    return .white
                } else if isCalibrationNeeded {
                    return .errorColor
                } else {
                    return currentDrone.drone.getPeripheral(Peripherals.gimbal)?.backgroundColor ?? .white
                }
            }
            .eraseToAnyPublisher()
    }

    /// Color for calibration text cell.
    var calibrationSubtitleColor: AnyPublisher<ColorName?, Never> {
        $connectionState
            .combineLatest($flyingState,
                           isCalibrationNeeded)
            .map { [unowned self] (connectionState, flyingState, isCalibrationNeeded) in
                if !(connectionState == .connected) || flyingState == .flying {
                    return .defaultTextColor
                } else if isCalibrationNeeded {
                    return .white
                } else {
                    return currentDrone.drone.getPeripheral(Peripherals.gimbal)?.subtitleColor ?? .highlightColor
                }
            }
            .eraseToAnyPublisher()
    }

    var cellularButtonSubtitlePublisher: AnyPublisher<String, Never> {
        $cellularStatus
            .combineLatest($connectionState)
            .map { [unowned self] (cellularStatus, connectionState) in
                if connectionState == .disconnected {
                    return Style.dash
                }

                var subtitle = cellularStatus.droneDetailsTileDescription ?? ""
                if cellularStatus == .cellularConnected,
                   let provider = currentDrone.drone.getPeripheral(Peripherals.cellular)?.operator {
                    subtitle.append(Style.colon + Style.whiteSpace + provider)
                }
                return subtitle
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
            self?.generateThumbnail(drone.getInstrument(Instruments.gps)?.lastKnownLocation)
        }
    }

    /// Starts watcher for gps.
    func listenGps(_ drone: Drone) {
        gpsRef = drone.getInstrument(Instruments.gps) { [weak self] gps in
            self?.lastKnownPosition = gps?.lastKnownLocation
            self?.generateThumbnail(self?.lastKnownPosition)
        }
        generateThumbnail(drone.getInstrument(Instruments.gps)?.lastKnownLocation)
    }

    /// Generates thumbnail from the center of the location.
    func generateThumbnail(_ location: CLLocation?) {
        guard let location = location else {
            mapThumbnail = Asset.MyFlights.poi.image
            return
        }

        switch connectionState {
        case .disconnected:
            ThumbnailUtils.generateMapThumbnail(location: location) { [weak self] image in
                guard let image = image else {
                    return
                }
                self?.mapThumbnail = image
            }
        default:
            mapThumbnail = nil
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
