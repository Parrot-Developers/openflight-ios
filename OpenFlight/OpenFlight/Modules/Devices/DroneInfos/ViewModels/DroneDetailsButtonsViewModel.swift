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

/// State for `DroneDetailsButtonsViewModel`.
final class DroneDetailsButtonsState: DeviceConnectionState {
    // MARK: - Internal Properties
    // MARK: State Properties
    /// Drone's last known position.
    fileprivate(set) var lastKnownPosition: CLLocation?
    // TODO: replace with state for every possible calibration needed.
    /// Whether a calibration is needed.
    fileprivate(set) var calibrationNeeded: Bool = false
    /// Whether a stereo vision sensor calibration is needed.
    fileprivate(set) var stereoVisionSensorCalibrationNeeded: Bool = false
    /// Drone's cellular network state.
    fileprivate(set) var cellularStateDescription: String?
    /// Drone's cellular connection status.
    fileprivate(set) var cellularStatus: DetailsCellularStatus = .noState
    /// Drone's flying state.
    fileprivate(set) var flyingState: FlyingIndicatorsState?

    // MARK: Helpers
    /// Message to display on calibration button.
    var calibrationText: String {
        // TODO: add message for all calibration cases.
        if !isConnected() || flyingState == .flying {
            return Style.dash
        } else if stereoVisionSensorCalibrationNeeded {
            return L10n.droneObstacleDetectionTitle + Style.whiteSpace + L10n.loveCalibrationRequired
        } else if calibrationNeeded {
            return L10n.droneCalibrationRequired
        } else {
            return L10n.droneDetailsCalibrationOk
        }
    }

    /// Tells if we can display the cellular modal.
    var canShowCellular: Bool {
        return cellularStatus != .noState && isConnected()
    }

    /// Tells if calibration button is available.
    var isCalibrationButtonAvailable: Bool {
        return isConnected() && flyingState == .landed
    }

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: drone's connection state
    ///    - lastKnownPosition: drone's last known position
    ///    - calibrationNeeded: wheter a calibration is needed
    ///    - stereoVisionSensorCalibrationNeeded: wheter a stereo vision sensor calibration is needed
    ///    - cellularStateDescription: cellular description state
    ///    - cellularStatus: current cellular status
    ///    - flyingState: flying state of the drone.
    init(connectionState: DeviceState.ConnectionState,
         lastKnownPosition: CLLocation?,
         calibrationNeeded: Bool,
         stereoVisionSensorCalibrationNeeded: Bool,
         cellularStateDescription: String?,
         cellularStatus: DetailsCellularStatus,
         flyingState: FlyingIndicatorsState?) {
        super.init(connectionState: connectionState)

        self.lastKnownPosition = lastKnownPosition
        self.calibrationNeeded = calibrationNeeded
        self.stereoVisionSensorCalibrationNeeded = stereoVisionSensorCalibrationNeeded
        self.cellularStateDescription = cellularStateDescription
        self.cellularStatus = cellularStatus
        self.flyingState = flyingState
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? DroneDetailsButtonsState else { return false }

        return super.isEqual(to: other)
            && self.lastKnownPosition == other.lastKnownPosition
            && self.calibrationNeeded == other.calibrationNeeded
            && self.stereoVisionSensorCalibrationNeeded == other.stereoVisionSensorCalibrationNeeded
            && self.cellularStateDescription == other.cellularStateDescription
            && self.cellularStatus == other.cellularStatus
            && self.flyingState == other.flyingState
    }

    override func copy() -> DroneDetailsButtonsState {
        return DroneDetailsButtonsState(connectionState: self.connectionState,
                                        lastKnownPosition: self.lastKnownPosition,
                                        calibrationNeeded: self.calibrationNeeded,
                                        stereoVisionSensorCalibrationNeeded: self.stereoVisionSensorCalibrationNeeded,
                                        cellularStateDescription: self.cellularStateDescription,
                                        cellularStatus: self.cellularStatus,
                                        flyingState: self.flyingState)
    }
}

/// View model for drone details buttons.
final class DroneDetailsButtonsViewModel: DroneStateViewModel<DroneDetailsButtonsState> {
    // MARK: - Internal Properties
    /// Returns true if the drone is already paired to MyParrot.
    var isDronePaired: Bool? {
        guard let uid = drone?.uid else { return false }

        return Defaults.cellularPairedDronesList.contains(uid)
    }

    // MARK: - Private Properties
    private var gpsRef: Ref<Gps>?
    private var gimbalRef: Ref<Gimbal>?
    private var stereoVisionSensorRef: Ref<StereoVisionSensor>?
    private var magnetometerRef: Ref<Magnetometer>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var cellularViewModel: DroneDetailsCellularViewModel?

    // MARK: - Init
    override init(stateDidUpdate: ((DroneDetailsButtonsState) -> Void)? = nil) {
        super.init(stateDidUpdate: stateDidUpdate)

        cellularViewModel = DroneDetailsCellularViewModel(stateDidUpdate: { [weak self] _ in
            self?.updateCellularState()
        })
        updateCellularState()
    }

    // MARK: - Deinit
    deinit {
        cellularViewModel = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenGps(drone)
        listenGimbal(drone)
        listenStereoVisionSensor(drone)
        listenMagnetometer(drone)
        listenFlyingIndicators(drone: drone)
    }

    // MARK: - Internal Funcs
    /// Removes current drone uid in the dismissed pairing list.
    /// The pairing process for the current drone could be displayed again in the HUD.
    func resetPairingDroneListIfNeeded() {
        guard let uid = self.drone?.uid,
              Defaults.dronesListPairingProcessHidden.contains(uid),
              !Defaults.cellularPairedDronesList.contains(uid) else {
            return
        }

        Defaults.dronesListPairingProcessHidden.removeAll(where: { $0 == uid })
    }
}

// MARK: - Private Funcs
private extension DroneDetailsButtonsViewModel {
    /// Starts watcher for gps.
    func listenGps(_ drone: Drone) {
        gpsRef = drone.getInstrument(Instruments.gps) { [weak self] gps in
            let copy = self?.state.value.copy()
            copy?.lastKnownPosition = gps?.lastKnownLocation
            self?.state.set(copy)
        }
    }

    /// Starts watcher for gimbal.
    func listenGimbal(_ drone: Drone) {
        gimbalRef = drone.getPeripheral(Peripherals.gimbal) { [weak self] _ in
            self?.updateCalibrationState()
        }
    }

    /// Starts watcher for stereo vision sensor.
    func listenStereoVisionSensor(_ drone: Drone) {
        stereoVisionSensorRef = drone.getPeripheral(Peripherals.stereoVisionSensor) { [weak self] _ in
            self?.updateStereoVisionSensorCalibrationState()
        }
    }

    /// Starts watcher for flying indicators.
    func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] flyingIndicators in
            guard let flyingState = flyingIndicators?.state else { return }

            let copy = self?.state.value.copy()
            copy?.flyingState = flyingState
            self?.state.set(copy)
        }
    }

    /// Starts watcher for magnetometer.
    func listenMagnetometer(_ drone: Drone) {
        magnetometerRef = drone.getPeripheral(Peripherals.magnetometer) { [weak self] _ in
            self?.updateCalibrationState()
        }
    }

    /// Updates stereo vision sensor calibration state.
    func updateStereoVisionSensorCalibrationState() {
        guard let drone = drone,
              let stereoVisionSensor = drone.getPeripheral(Peripherals.stereoVisionSensor) else {
            return
        }

        let copy = self.state.value.copy()
        copy.stereoVisionSensorCalibrationNeeded = !stereoVisionSensor.isCalibrated
        self.state.set(copy)
    }

    /// Updates calibration state.
    func updateCalibrationState() {
        guard let drone = drone,
              let gimbal = drone.getPeripheral(Peripherals.gimbal),
              let magnetometer = drone.getPeripheral(Peripherals.magnetometer) else {
            return
        }

        let copy = self.state.value.copy()
        copy.calibrationNeeded = !gimbal.calibrated || magnetometer.calibrationState == .required
        self.state.set(copy)
    }

    /// Updates cellular state.
    func updateCellularState() {
        let copy = state.value.copy()
        copy.cellularStatus = cellularViewModel?.state.value.cellularStatus ?? .noState
        state.set(copy)
    }
}
