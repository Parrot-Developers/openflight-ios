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

/// State for `DroneDetailsInformationsViewModel`.
final class DroneDetailsInformationsState: DeviceConnectionState {
    // MARK: - Internal Properties
    /// Drone's serial number.
    fileprivate(set) var serialNumber: String = Style.dash
    /// Current drone imei.
    fileprivate(set) var imei: String = Style.dash
    /// Hardware version.
    fileprivate(set) var hardwareVersion: String = Style.dash
    /// Firmware version.
    fileprivate(set) var firmwareVersion: String = Style.dash

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: drone connection state
    ///    - imei: drone's IMEI
    ///    - hardwareVersion: hardware version
    ///    - serialNumber: drone serial number
    init(connectionState: DeviceState.ConnectionState,
         imei: String,
         hardwareVersion: String,
         serialNumber: String,
         firmwareVersion: String) {
        super.init(connectionState: connectionState)

        self.hardwareVersion = hardwareVersion
        self.serialNumber = serialNumber
        self.firmwareVersion = firmwareVersion
        self.imei = imei
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? DroneDetailsInformationsState else { return false }

        return super.isEqual(to: other)
            && self.serialNumber == other.serialNumber
            && self.imei == other.imei
            && self.hardwareVersion == other.hardwareVersion
            && self.firmwareVersion == other.firmwareVersion
    }

    override func copy() -> DroneDetailsInformationsState {
        let copy = DroneDetailsInformationsState(connectionState: connectionState,
                                                 imei: imei,
                                                 hardwareVersion: hardwareVersion,
                                                 serialNumber: serialNumber,
                                                 firmwareVersion: firmwareVersion)
        return copy
    }
}

/// View Model for the list of drone's infos in the details screen.
final class DroneDetailsInformationsViewModel: DroneStateViewModel<DroneDetailsInformationsState> {
    // MARK: - Private Properties
    private var systemInfoRef: Ref<SystemInfo>?
    private var cellularRef: Ref<Cellular>?

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenDroneInfos(drone)
        listenCellular(drone)
    }

    // MARK: - Internal Funcs
    /// Resets the drone to factory state.
    func resetDrone() {
        if let uid = self.drone?.uid {
            Defaults.dronesListPairingProcessHidden.removeAll(where: { $0 == uid })
        }

        _ = drone?.getPeripheral(Peripherals.systemInfo)?.factoryReset()
    }
}

// MARK: - Private Funcs
/// Drone's Listeners.
private extension DroneDetailsInformationsViewModel {
    /// Starts watcher for drone system infos.
    func listenDroneInfos(_ drone: Drone) {
        systemInfoRef = drone.getPeripheral(Peripherals.systemInfo) { [weak self] _ in
            self?.updateSystemInfo()
        }
        updateSystemInfo()
    }

    /// Starts watcher for drone cellular.
    func listenCellular(_ drone: Drone) {
        cellularRef = drone.getPeripheral(Peripherals.cellular) { [weak self] _ in
            self?.updateCellularInfo()
        }
        updateCellularInfo()
    }
}

/// State update functions.
private extension DroneDetailsInformationsViewModel {
    /// Updates system informations.
    func updateSystemInfo() {
        guard let drone = drone else { return }
        let systemInfo = drone.getPeripheral(Peripherals.systemInfo)
        let copy = state.value.copy()
        copy.hardwareVersion = systemInfo?.hardwareVersion ?? Style.dash
        copy.serialNumber = systemInfo?.serial ?? Style.dash
        copy.firmwareVersion = hasLastConnectedDrone
                                ? systemInfo?.firmwareVersion ?? Style.dash
                                : Style.dash
        state.set(copy)
    }

    /// Updates cellular info.
    func updateCellularInfo() {
        guard let drone = drone else { return }
        let cellular = drone.getPeripheral(Peripherals.cellular)
        let copy = state.value.copy()
        copy.imei = hasLastConnectedDrone
                    ? cellular?.imei ?? Style.dash
                    : Style.dash
        state.set(copy)
    }
}
