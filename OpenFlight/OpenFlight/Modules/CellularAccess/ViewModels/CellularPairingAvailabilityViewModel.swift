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
import SwiftyUserDefaults

/// State for `CellularPairingAvailabilityViewModel`.
final class CellularPairingAvailabilityState: DeviceConnectionState {
    // MARK: - Internal Properties
    fileprivate(set) var isCellularAvailable: Bool = false
    fileprivate(set) var isPairingProcessDismissed: Bool = false
    fileprivate(set) var isDroneAlreadyPaired: Bool = false

    /// Tells if we can show the cellular pairing process modal in the HUD.
    var canShowModal: Bool {
        return isCellularAvailable
            && connectionState == .connected
            && !isPairingProcessDismissed
            && !isDroneAlreadyPaired
    }

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: drone connection state
    ///    - isCellularAvailable: tells if cellular feature is available
    ///    - isPairingProcessDismissed: tells if pairing modal has been dismissed
    ///    - isDroneAlreadyPaired: tells if the drone is already paired
    init(connectionState: DeviceState.ConnectionState,
         isCellularAvailable: Bool,
         isPairingProcessDismissed: Bool,
         isDroneAlreadyPaired: Bool) {
        super.init(connectionState: connectionState)

        self.isCellularAvailable = isCellularAvailable
        self.isPairingProcessDismissed = isPairingProcessDismissed
        self.isDroneAlreadyPaired = isDroneAlreadyPaired
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? CellularPairingAvailabilityState else { return false }

        return super.isEqual(to: other)
            && self.isCellularAvailable == other.isCellularAvailable
            && self.isPairingProcessDismissed == other.isPairingProcessDismissed
            && self.isDroneAlreadyPaired == other.isDroneAlreadyPaired
    }

    override func copy() -> CellularPairingAvailabilityState {
        let copy = CellularPairingAvailabilityState(connectionState: connectionState,
                                                    isCellularAvailable: self.isCellularAvailable,
                                                    isPairingProcessDismissed: self.isPairingProcessDismissed,
                                                    isDroneAlreadyPaired: self.isDroneAlreadyPaired)

        return copy
    }
}

/// Manages drone cellular pairing visibility.
final class CellularPairingAvailabilityViewModel: DroneStateViewModel<CellularPairingAvailabilityState> {
    // MARK: - Private Properties
    private var cellularRef: Ref<Cellular>?
    private var pairingModalObserver: DefaultsDisposable?
    private var academyApiManager: AcademyApiManager = AcademyApiManager()
    private var dronesPairedObserver: DefaultsDisposable?

    // MARK: - Init
    override init() {
        super.init()

        listenPairingModalDefaults()
        updatePairedDronesIfNeeded()
        listenDronesPairedList()
    }

    // MARK: - Deinit
    deinit {
        cellularRef = nil
        pairingModalObserver?.dispose()
        pairingModalObserver = nil
        dronesPairedObserver?.dispose()
        dronesPairedObserver = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenCellular(drone)
    }

    override func droneConnectionStateDidChange() {
        super.droneConnectionStateDidChange()

        if drone?.isConnected == true {
            updatePairedDronesIfNeeded()
        }
    }

    // MARK: - Internal Funcs
    /// Updates cellular pairing process availability state.
    func updateAvailabilityState() {
        updateCellularAvailability(with: drone?.getPeripheral(Peripherals.cellular))
        updateDronePairingState()
    }
}

// MARK: - Private Funcs
private extension CellularPairingAvailabilityViewModel {
    /// Starts watcher for Cellular.
    func listenCellular(_ drone: Drone) {
        cellularRef = drone.getPeripheral(Peripherals.cellular) { [weak self] cellular in
            self?.updateCellularAvailability(with: cellular)
        }
        updateCellularAvailability(with: drone.getPeripheral(Peripherals.cellular))
    }

    /// Updates cellular availability state.
    ///
    /// - Parameters:
    ///     - cellular: current cellular reference's value
    func updateCellularAvailability(with cellular: Cellular?) {
        let copy = state.value.copy()
        copy.isCellularAvailable = cellular?.isSimCardInserted == true
        state.set(copy)
    }

    /// Observes default to checks if the pairing modal has been already dismissed.
    func listenPairingModalDefaults() {
        pairingModalObserver = Defaults.observe(\.dronesListPairingProcessHidden) { [weak self] _ in
            DispatchQueue.userDefaults.async {
                self?.updateVisibilityState()
            }
        }
        updateVisibilityState()
    }

    /// Updates visibility of the process according to drone list.
    func updateVisibilityState() {
        guard let uid = drone?.uid else { return }

        let copy = state.value.copy()
        copy.isPairingProcessDismissed = Defaults.dronesListPairingProcessHidden.contains(uid)
        state.set(copy)
    }

    /// Update local paired drone list with Academy call.
    func updatePairedDronesIfNeeded() {
        academyApiManager.performPairedDroneListRequest { cellularPairedDronesList in
            guard cellularPairedDronesList != nil else {
                self.updateDronePairingState()
                return
            }

            let pairedList = cellularPairedDronesList?
                .filter({ $0.pairedFor4g == true })
                .compactMap { return $0.serial } ?? []

            Defaults.cellularPairedDronesList = pairedList
            self.updateDronePairingState()

            // User account update should be done on the main Thread.
            DispatchQueue.main.async {
                guard let jsonString: String = ParserUtils.jsonString(cellularPairedDronesList),
                      let userAccount = GroundSdk().getFacility(Facilities.userAccount) else {
                    return
                }

                // Updates UserAccount paired drones list.
                userAccount.set(droneList: jsonString)
            }
        }
    }

    /// Checks if the drone is already paired.
    func updateDronePairingState() {
        let copy = state.value.copy()
        copy.isDroneAlreadyPaired = drone?.isAlreadyPaired == true
        state.set(copy)
    }

    /// Starts watcher for drones already paired list.
    func listenDronesPairedList() {
        dronesPairedObserver = Defaults.observe(\.cellularPairedDronesList) { [weak self] _ in
            DispatchQueue.userDefaults.async {
                self?.updateDronePairingState()
            }
        }
    }
}
