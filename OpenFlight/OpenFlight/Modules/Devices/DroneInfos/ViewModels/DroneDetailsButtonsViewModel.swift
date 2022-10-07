//    Copyright (C) 2020 Parrot Drones SAS
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

    /// Whether drone is landed and no hand launch is started, `nil` if flying state is unknown (meaning drone is not connected).
    @Published private var landed: Bool?
    /// Whether a gimbal calibration is needed.
    @Published private(set) var isGimbalCalibrationNeeded: Bool = false
    /// Whether a gimbal front stereo vision calibration is needed.
    @Published private(set) var isGimbalFrontStereoCalibrationNeeded: Bool = false
    /// Whether magnetometer calibration is needed.
    @Published private(set) var isMagnetometerCalibrationNeeded: Bool = false
    /// Whether magnetometer calibration is recommended.
    @Published private(set) var isMagnetometerCalibrationRecommended: Bool = false
    /// Whether a stereo vision sensor calibration is needed.
    @Published private(set) var isStereoVisionSensorCalibrationNeeded: Bool = false
    /// Drone's last known position.
    @Published private(set) var lastKnownPosition: CLLocation?
    /// Drone's cellular connection status.
    @Published private(set) var cellularStatus: DetailsCellularStatus = .noState
    /// Drone's connection state.
    @Published private(set) var connectionState: DeviceState.ConnectionState = .disconnected
    /// Remote's connection state.
    @Published private(set) var remoteConnectionState: DeviceState.ConnectionState = .disconnected
    /// Tells if we can display the cellular modal.
    @Published private(set) var mapThumbnail: UIImage? = Asset.MyFlights.poi.image
    /// Tells the health of the battery
    @Published private(set) var batteryHealth: String? = Style.dash
    /// Tells if the battery button is available
    @Published private(set) var batteryButtonAvailable: Bool = false
    /// Publishes the color for the battery subtitle
    @Published private(set) var batterySubtitleColor: ColorName = .defaultTextColor

    // MARK: - Private Properties
    private var gpsRef: Ref<Gps>?
    private var gimbalRef: Ref<Gimbal>?
    private var stereoVisionSensorRef: Ref<StereoVisionSensor>?
    private var magnetometerRef: Ref<MagnetometerWith3StepCalibration>?
    private var frontStereoGimbalRef: Ref<FrontStereoGimbal>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var connectionStateRef: Ref<DeviceState>?
    private var remoteConnectionStateRef: Ref<DeviceState>?
    private var batteryRef: Ref<BatteryInfo>?
    private var cancellables = Set<AnyCancellable>()
    private var currentDrone = Services.hub.currentDroneHolder
    private var cellularService = Services.hub.drone.cellularService
    private var currentRemote = Services.hub.currentRemoteControlHolder
    private var locationsTracker = Services.hub.locationsTracker

    // MARK: - Init

    init() {
        currentDrone.dronePublisher
            .sink { [unowned self] drone in
                listenGimbal(drone)
                listenStereoVisionSensor(drone)
                listenFrontStereoGimbal(drone)
                listenMagnetometer(drone)
                listenFlyingIndicators(drone: drone)
                listenConnectionState(drone: drone)
                listenBatteryInfo(drone)
            }
            .store(in: &cancellables)

        currentRemote.remoteControlPublisher
            .sink { [weak self] remote in
                guard let self = self else { return }
                self.listenRemoteConnectionState(remote: remote)
            }
            .store(in: &cancellables)

        cellularService.cellularStatusPublisher
            .sink { [unowned self] cellularStatus in
                updateCellularState(cellularStatus: cellularStatus)
            }
            .store(in: &cancellables)

        locationsTracker.droneLocationPublisher
            .removeDuplicates()
            .sink { [weak self] location in
                guard let self = self else { return }
                if let coordinate = location.validCoordinates {
                    // Only latitude and longitude are used for the generation of the thumbnail.
                    let location = CLLocation(latitude: coordinate.coordinate.latitude,
                                              longitude: coordinate.coordinate.longitude)
                    if self.lastKnownPosition?.coordinate != location.coordinate {
                        self.lastKnownPosition = location
                        self.generateThumbnail(self.lastKnownPosition)
                    }
                }
            }
            .store(in: &cancellables)

        updateCellularState(cellularStatus: cellularStatus)

    }

    // MARK: Helpers
    /// Subtitle to display on calibration button.
    var calibrationSubtitle: AnyPublisher<String?, Never> {
        $connectionState
            .combineLatest($isGimbalCalibrationNeeded,
                           $isMagnetometerCalibrationNeeded,
                           $isMagnetometerCalibrationRecommended)
            .combineLatest($isGimbalFrontStereoCalibrationNeeded,
                           $isStereoVisionSensorCalibrationNeeded)
            .map { (arg0, isGimbalFrontNeeded, isStereoNeeded) in
                let (connectionState, isGimbalNeeded, isMagnetometerNeeded, isMagnetometerRecommended) = arg0
                if connectionState != .connected {
                    return Style.dash
                } else if isMagnetometerNeeded {
                    return L10n.droneDetailsCalibrationRequired
                } else if isStereoNeeded {
                    return L10n.droneDetailsCalibrationLoveRequired
                } else if isGimbalFrontNeeded || isGimbalNeeded {
                    return L10n.droneDetailsCalibrationGimbalRequired
                } else if isMagnetometerRecommended {
                    return L10n.droneDetailsCalibrationAdvised
                } else {
                    return L10n.droneDetailsCalibrationOk
                }
            }
            .eraseToAnyPublisher()
    }

    /// Tells if a calibration is needed.
    var isCalibrationNeeded: AnyPublisher<Bool, Never> {
        $isMagnetometerCalibrationNeeded
            .combineLatest($isStereoVisionSensorCalibrationNeeded,
                           $isGimbalFrontStereoCalibrationNeeded,
                           $isGimbalCalibrationNeeded)
            .map { $0 || $1 || $2 || $3 }
            .eraseToAnyPublisher()
    }

    /// Tells if a calibration is recommended.
    var isCalibrationRecommended: AnyPublisher<Bool, Never> {
        $isMagnetometerCalibrationRecommended
            .eraseToAnyPublisher()
    }

    /// Tells if calibration button is available.
    var isCalibrationButtonAvailable: AnyPublisher<Bool, Never> {
        $landed
            .map { $0 == true }
            .eraseToAnyPublisher()
    }

    /// Title color for calibration.
    var calibrationTitleColor: AnyPublisher<ColorName?, Never> {
        $connectionState
            .combineLatest(isCalibrationNeeded,
                           isCalibrationRecommended)
            .map { [unowned self] (connectionState, isCalibrationNeeded, isCalibrationRecommended) in
                if connectionState != .connected {
                    return .defaultTextColor
                } else if isCalibrationNeeded || isCalibrationRecommended {
                    return .white
                } else {
                    return currentDrone.drone.getPeripheral(Peripherals.gimbal)?.titleColor ?? .defaultTextColor
                }
            }
            .eraseToAnyPublisher()
    }

    /// Background for calibration cell.
    var calibrationBackgroundColor: AnyPublisher<ColorName?, Never> {
        $connectionState
            .combineLatest(isCalibrationNeeded,
                           isCalibrationRecommended)
            .map { [unowned self] (connectionState, isCalibrationNeeded, isCalibrationRecommended) in
                if connectionState != .connected {
                    return .white
                } else if isCalibrationNeeded {
                    return .errorColor
                } else if isCalibrationRecommended {
                    return .warningColor
                } else {
                    return currentDrone.drone.getPeripheral(Peripherals.gimbal)?.backgroundColor ?? .white
                }
            }
            .eraseToAnyPublisher()
    }

    /// Color for calibration text cell.
    var calibrationSubtitleColor: AnyPublisher<ColorName?, Never> {
        $connectionState
            .combineLatest(isCalibrationNeeded,
                           isCalibrationRecommended)
            .map { [unowned self] (connectionState, isCalibrationNeeded, isCalibrationRecommended) in
                if connectionState != .connected {
                    return .defaultTextColor
                } else if isCalibrationNeeded || isCalibrationRecommended {
                    return .white
                } else {
                    return currentDrone.drone.getPeripheral(Peripherals.gimbal)?.subtitleColor ?? .highlightColor
                }
            }
            .eraseToAnyPublisher()
    }

    var cellularButtonSubtitlePublisher: AnyPublisher<String, Never> {
        $cellularStatus
            .combineLatest($connectionState, $remoteConnectionState.removeDuplicates())
            .map { [unowned self] (cellularStatus, connectionState, remoteConnectionState) in
                if connectionState == .disconnected {
                    return Style.dash
                }

                if remoteConnectionState == .disconnected {
                    return L10n.controllerNotConnected
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
        }
    }

    /// Starts watcher for remote's connection state.
    ///
    /// - Parameter remote: the current remote controller
    func listenRemoteConnectionState(remote: RemoteControl?) {
        remoteConnectionStateRef = remote?.getState { [weak self] state in
            guard let self = self else { return }
            self.remoteConnectionState = state?.connectionState ?? .disconnected
        }
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
            self?.updateGimbal(gimbal: gimbal)
        }
    }

    /// Starts watcher for stereo vision sensor.
    func listenStereoVisionSensor(_ drone: Drone) {
        stereoVisionSensorRef = drone.getPeripheral(Peripherals.stereoVisionSensor) { [weak self] stereoVisionSensor in
            self?.updateStereoVisionSensorCalibrationState(stereoVisionSensor: stereoVisionSensor)
        }
    }

    /// Starts watcher for flying indicators.
    func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [unowned self] flyingIndicators in
            guard let flyingIndicators = flyingIndicators else {
                // flying state in unknown when drone is not connected
                landed = nil
                return
            }
            landed = (flyingIndicators.state == .landed && flyingIndicators.landedState != .waitingUserAction)
            || (flyingIndicators.state == .emergency)
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

    /// Starts watcher for battery infos
    func listenBatteryInfo(_ drone: Drone?) {
        batteryRef = drone?.getInstrument(Instruments.batteryInfo) { [weak self] batteryInfos in
            guard let self = self else { return }
            self.updateBatteryInfo(batteryInfos: batteryInfos)
        }
    }

    /// Updates battery infos
    func updateBatteryInfo(batteryInfos: BatteryInfo?) {
        guard let batteryInfos = batteryInfos,
             !batteryInfos.cellVoltages.isEmpty else {
            batteryHealth = Style.dash
            batterySubtitleColor = .defaultTextColor
            batteryButtonAvailable = false
            return
        }
        batteryButtonAvailable = true
        batterySubtitleColor = .highlightColor
        batteryHealth = batteryInfos.batteryHealth.flatMap { L10n.batteryHealth + ": " + String($0) + "%" }
    }

    /// Updates front stereo gimbal calibration state.
    func updateFrontStereoGimbal(frontStereoGimbal: FrontStereoGimbal?) {
        isGimbalFrontStereoCalibrationNeeded = frontStereoGimbal?.state == .needed
    }

    /// Updates gimbal calibration state.
    func updateGimbal(gimbal: Gimbal?) {
        isGimbalCalibrationNeeded = gimbal?.state == .needed
    }

    /// Updates stereo vision sensor calibration state.
    func updateStereoVisionSensorCalibrationState(stereoVisionSensor: StereoVisionSensor?) {
        isStereoVisionSensorCalibrationNeeded = stereoVisionSensor?.state == .needed
    }

    /// Updates magnetometer calibration state.
    func updateMagnetometerCalibrationState(magnetometer: MagnetometerWith3StepCalibration?) {
        isMagnetometerCalibrationNeeded = magnetometer?.calibrationState == .required
        isMagnetometerCalibrationRecommended = magnetometer?.calibrationState == .recommended
    }

    /// Updates cellular state.
    func updateCellularState(cellularStatus: DetailsCellularStatus) {
        self.cellularStatus = cellularStatus
    }
}
