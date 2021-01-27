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

/// State for `CellularAvailableViewModel`.
final class CellularAvailableState: DeviceConnectionState {
    // MARK: - Internal Properties
    fileprivate(set) var isCellularAvailable: Bool = false
    fileprivate(set) var isUserConnected: Bool = false

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: drone connection state
    ///    - isCellularAvailable: tells if cellular feature is available
    ///    - isUserConnected: tells if user is connected to MyParrot
    init(connectionState: DeviceState.ConnectionState,
         isCellularAvailable: Bool,
         isUserConnected: Bool) {
        super.init(connectionState: connectionState)

        self.isCellularAvailable = isCellularAvailable
        self.isUserConnected = isUserConnected
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? CellularAvailableState else { return false }

        return super.isEqual(to: other)
            && self.isCellularAvailable == other.isCellularAvailable
            && self.isUserConnected == other.isUserConnected
    }

    override func copy() -> CellularAvailableState {
        let copy = CellularAvailableState(connectionState: connectionState,
                                          isCellularAvailable: self.isCellularAvailable,
                                          isUserConnected: self.isUserConnected)
        return copy
    }
}

/// Manages drone cellular pairing first screen.
final class CellularAvailableViewModel: DroneStateViewModel<CellularAvailableState> {
    // MARK: - Private Properties
    private var cellularRef: Ref<Cellular>?

    // MARK: - Init
    override init(stateDidUpdate: ((CellularAvailableState) -> Void)? = nil) {
        super.init(stateDidUpdate: stateDidUpdate)

        updateMyParrotState()
    }

    // MARK: - Deinit
    deinit {
        cellularRef = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenCellular(drone)
    }

    // MARK: - Internal Funcs
    /// Dismiss tha pairing process screen.
    func dismissPairingScreen() {
        addDroneInPairedProcessList()
    }
}

// MARK: - Private Funcs
private extension CellularAvailableViewModel {
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
        copy.isCellularAvailable = cellular?.simStatus.isCellularAvailable == true
        state.set(copy)
    }

    /// Updates connecting state of the user.
    func updateMyParrotState() {
        let copy = state.value.copy()
        copy.isUserConnected = Defaults.isUserConnected
        state.set(copy)
    }

    /// Add the current drone in the pairing process.
    func addDroneInPairedProcessList() {
        guard drone?.isConnected == true,
              state.value.isCellularAvailable,
              let uid = drone?.uid,
              !uid.isEmpty else {
            return
        }

        Defaults.dronesListPairingProcessHidden.append(uid)
    }
}
