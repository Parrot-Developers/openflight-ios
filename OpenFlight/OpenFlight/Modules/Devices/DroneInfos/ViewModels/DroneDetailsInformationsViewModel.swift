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

/// State for `DroneDetailsInformationsViewModel`.

final class DroneDetailsInformationsState: DeviceConnectionState {
    // MARK: - Internal Properties
    /// Drone's name.
    fileprivate(set) var name: String?
    /// Drone's IMEI.
    fileprivate(set) var imei: String?
    /// Current drone model.
    fileprivate(set) var model: String?
    /// Software version.
    fileprivate(set) var softwareVersion: String?
    /// Hardware version.
    fileprivate(set) var hardwareVersion: String?
    /// Drone serial number.
    fileprivate(set) var serialNumber: String?
    /// Number of flights.
    fileprivate(set) var flightsNumber: String?
    /// Duration of flights.
    fileprivate(set) var totalFlightsDuration: String?
    /// Drone need an update.
    fileprivate(set) var needUpdate: Bool?

    /// Returns a list of items for collection display.
    var items: [DroneDetailsCollectionViewCellModel] {
        return [DroneDetailsCollectionViewCellModel(title: L10n.droneDetailsProductType,
                                                    value: model),
                DroneDetailsCollectionViewCellModel(title: L10n.droneDetailsNumberFlights,
                                                    value: flightsNumber),
                DroneDetailsCollectionViewCellModel(title: L10n.remoteDetailsSerialNumber,
                                                    value: serialNumber),
                DroneDetailsCollectionViewCellModel(title: L10n.droneDetailsTotalFlightTime,
                                                    value: totalFlightsDuration),
                DroneDetailsCollectionViewCellModel(title: L10n.droneDetailsHardwareVersion,
                                                    value: hardwareVersion),
                DroneDetailsCollectionViewCellModel(title: L10n.droneDetailsSoftwareVersion,
                                                    value: softwareVersion,
                                                    valueImage: needUpdate == false
                                                        ? Asset.Common.Checks.iconCheck.image
                                                        : nil)]
    }

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: drone connection state
    ///    - name: drone's name
    ///    - imei: drone's IMEI
    ///    - model: current drone model
    ///    - hardwareVersion: hardware version
    ///    - softwareVersion: software version
    ///    - serialNumber: drone serial number
    ///    - flightsNumber: number of flights
    ///    - totalFlightsDuration: duration of flights
    ///    - needUpdate: tells if the drone need an update
    init(connectionState: DeviceState.ConnectionState,
         name: String?,
         imei: String?,
         model: String?,
         softwareVersion: String?,
         hardwareVersion: String?,
         serialNumber: String?,
         flightsNumber: String?,
         totalFlightsDuration: String?,
         needUpdate: Bool?) {
        super.init(connectionState: connectionState)
        self.name = name
        self.imei = imei
        self.model = model
        self.softwareVersion = softwareVersion
        self.hardwareVersion = hardwareVersion
        self.serialNumber = serialNumber
        self.flightsNumber = flightsNumber
        self.totalFlightsDuration = totalFlightsDuration
        self.needUpdate = needUpdate
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? DroneDetailsInformationsState else {
            return false
        }
        return super.isEqual(to: other)
            && self.name == other.name
            && self.imei == other.imei
            && self.model == other.model
            && self.softwareVersion == other.softwareVersion
            && self.hardwareVersion == other.hardwareVersion
            && self.serialNumber == other.serialNumber
            && self.flightsNumber == other.flightsNumber
            && self.totalFlightsDuration == other.totalFlightsDuration
            && self.needUpdate == other.needUpdate
    }

    override func copy() -> DroneDetailsInformationsState {
        let copy = DroneDetailsInformationsState(connectionState: connectionState,
                                                 name: name,
                                                 imei: imei,
                                                 model: model,
                                                 softwareVersion: softwareVersion,
                                                 hardwareVersion: hardwareVersion,
                                                 serialNumber: serialNumber,
                                                 flightsNumber: flightsNumber,
                                                 totalFlightsDuration: totalFlightsDuration,
                                                 needUpdate: needUpdate)
        return copy
    }
}

/// View Model for the list of drone's infos in the details screen.

final class DroneDetailsInformationsViewModel: DroneStateViewModel<DroneDetailsInformationsState> {
    // MARK: - Private Properties
    private var droneNameRef: Ref<String>?
    private var systemInfoRef: Ref<SystemInfo>?
    private var updaterRef: Ref<Updater>?
    private var flightMeterRef: Ref<FlightMeter>?
    private let groundSdk: GroundSdk = GroundSdk()

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)
        listenDroneName(drone)
        listenFlightsData(drone)
        listenUpdate(drone)
        listenDroneInfos(drone)
        // TODO: Add an observer for IMEI when available.
        updateDroneModel(drone)
    }

    // MARK: - Internal Funcs
    /// Reset the drone to factory state.
    func resetDrone() {
        _ = drone?.getPeripheral(Peripherals.systemInfo)?.factoryReset()
    }
}

// MARK: - Private Funcs
private extension DroneDetailsInformationsViewModel {
    /// Starts watcher for flight data.
    func listenFlightsData(_ drone: Drone) {
        flightMeterRef = drone.getInstrument(Instruments.flightMeter) { [weak self] flightMeter in
            guard let flightMeter = flightMeter else {
                return
            }
            let copy = self?.state.value.copy()
            copy?.flightsNumber = String(flightMeter.totalFlights)
            copy?.totalFlightsDuration = flightMeter.flightDurationFormatted
            self?.state.set(copy)
        }
    }

    /// Starts watcher for drone's name.
    func listenDroneName(_ drone: Drone) {
        droneNameRef = drone.getName { [weak self] name in
            let copy = self?.state.value.copy()
            copy?.name = name
            self?.state.set(copy)
        }
    }

    /// Starts watcher for drone system infos.
    func listenDroneInfos(_ drone: Drone) {
        systemInfoRef = drone.getPeripheral(Peripherals.systemInfo) { [weak self] systemInfo in
            let copy = self?.state.value.copy()
            copy?.serialNumber = systemInfo?.serial
            copy?.hardwareVersion = systemInfo?.hardwareVersion
            copy?.softwareVersion = systemInfo?.firmwareVersion
            self?.state.set(copy)
        }
    }

    /// Starts watcher for drone update status.
    func listenUpdate(_ drone: Drone) {
        updaterRef = drone.getPeripheral(Peripherals.updater) { [weak self] updater in
            let copy = self?.state.value.copy()
            copy?.needUpdate = updater?.isUpToDate == false
            self?.state.set(copy)
        }
    }

    /// Update drone model.
    func updateDroneModel(_ drone: Drone) {
        let copy = state.value.copy()
        copy.model = drone.model.publicName
        state.set(copy)
    }
}
