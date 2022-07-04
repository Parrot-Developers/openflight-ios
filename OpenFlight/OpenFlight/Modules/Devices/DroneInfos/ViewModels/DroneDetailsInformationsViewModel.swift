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
import SwiftyUserDefaults
import Combine

/// View Model for the list of drone's infos in the details screen.
final class DroneDetailsInformationsViewModel {

    // MARK: - Published Properties
    /// Drone's serial number.
    @Published private(set) var serialNumber: String = Style.dash
    /// Current drone imei.
    @Published private(set) var imei: String = Style.dash
    /// Hardware version.
    @Published private(set) var hardwareVersion: String = Style.dash
    /// Firmware version.
    @Published private(set) var firmwareVersion: String = Style.dash
    /// Drone's flying state
    private var isFlying = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Private Properties
    private let currentDroneHolder: CurrentDroneHolder
    private let connectedDroneHolder: ConnectedDroneHolder
    private var systemInfoRef: Ref<SystemInfo>?
    private var cellularRef: Ref<Cellular>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var cancellables = Set<AnyCancellable>()

    var resetButtonEnabled: AnyPublisher<Bool, Never> {
        connectedDroneHolder.dronePublisher
            .combineLatest(isFlying)
            .map { [weak self] (drone, isFlying) in
                guard self != nil else { return false }
                guard let drone = drone else { return false }
                return drone.isConnected && !isFlying
            }
            .eraseToAnyPublisher()
    }

    init(currentDroneHolder: CurrentDroneHolder, connectedDroneHolder: ConnectedDroneHolder) {
        self.currentDroneHolder = currentDroneHolder
        self.connectedDroneHolder = connectedDroneHolder

        currentDroneHolder.dronePublisher
            .sink { [weak self] drone in
                guard let self = self else { return }
                self.listenDroneInfos(drone)
                self.listenCellular(drone)
                self.listenFlyingState(drone)
            }
            .store(in: &cancellables)
    }

    // MARK: - Internal Funcs
    /// Resets the drone to factory state.
    func resetDrone() {
        let uid = currentDroneHolder.drone.uid
        Defaults.dronesListPairingProcessHidden.removeAll(where: { $0 == uid })

        _ = currentDroneHolder.drone.getPeripheral(Peripherals.systemInfo)?.factoryReset()
    }
}

// MARK: - Private Funcs
/// Drone's Listeners.
private extension DroneDetailsInformationsViewModel {
    /// Starts watcher for drone system infos.
    func listenDroneInfos(_ drone: Drone) {
        systemInfoRef = drone.getPeripheral(Peripherals.systemInfo) { [weak self] systemInfo in
            self?.updateSystemInfo(systemInfo: systemInfo)
        }
    }

    /// Starts watcher for drone cellular.
    func listenCellular(_ drone: Drone) {
        cellularRef = drone.getPeripheral(Peripherals.cellular) { [weak self] cellular in
            self?.updateCellularInfo(cellular: cellular)
        }
    }

    /// Listen flying indicators instrument.
    ///
    /// - Parameter drone: the current drone
    func listenFlyingState(_ drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [unowned self] flyingIndicator in
            guard let flyingIndicator = flyingIndicator?.state else { return }
            updateFlyingIndicators(flyingIndicatorState: flyingIndicator)
        }
    }
}

/// State update functions.
private extension DroneDetailsInformationsViewModel {
    /// Updates system informations.
    func updateSystemInfo(systemInfo: SystemInfo?) {
        hardwareVersion = systemInfo?.hardwareVersion ?? Style.dash
        serialNumber = systemInfo?.serial ?? Style.dash
        firmwareVersion = currentDroneHolder.hasLastConnectedDrone
                                ? systemInfo?.firmwareVersion ?? Style.dash
                                : Style.dash
    }

    /// Updates cellular info.
    func updateCellularInfo(cellular: Cellular?) {
        imei = currentDroneHolder.hasLastConnectedDrone
                    ? cellular?.imei ?? Style.dash
                    : Style.dash
    }

    /// Updates flying state info
    func updateFlyingIndicators(flyingIndicatorState: FlyingIndicatorsState) {
        isFlying.value = flyingIndicatorState != .landed
    }
}
