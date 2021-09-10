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
import Reachability
import SwiftyUserDefaults
import Combine

/// View model managing drone cellular information in drone details screen.
final class DroneDetailsCellularViewModel {
    // MARK: - Internal Properties
    /// Drone's cellular connection state.
    @Published private(set) var cellularStatus: DetailsCellularStatus = .noState
    /// Number of connected users.
    @Published private(set) var usersCount: Int = 0
    /// Name of the operator.
    @Published private(set) var operatorName: String?
    /// Current drone unpair state.
    @Published private(set) var unpairState: UnpairDroneState = .notStarted
    /// Connection state of the device.
    @Published private(set) var connectionState: DeviceState.ConnectionState = .disconnected

    // MARK: - Private Properties
    private var connectionStateRef: Ref<DeviceState>?
    private var academyApiService: AcademyApiService
    private var cancellables = Set<AnyCancellable>()
    private var currentDrone: CurrentDroneHolder
    private var pairingService: CellularPairingService

    init() {
        self.academyApiService = Services.hub.academyApiService
        self.currentDrone = Services.hub.currentDroneHolder
        self.pairingService = Services.hub.drone.cellularPairingService

        currentDrone.dronePublisher
            .sink { [unowned self] drone in
                listenConnectionState(drone: drone)
            }
            .store(in: &cancellables)

        pairingService.operatorNamePublisher
            .sink { [unowned self] operatorName in
                self.operatorName = operatorName
            }
            .store(in: &cancellables)

        pairingService.cellularStatusPublisher
            .sink { [unowned self] cellularStatus in
                self.cellularStatus = cellularStatus
            }
            .store(in: &cancellables)

        pairingService.unpairStatePublisher
            .sink { [unowned self] unpairState in
                self.unpairState = unpairState
            }
            .store(in: &cancellables)
    }
}

// MARK: - Internal functions
extension DroneDetailsCellularViewModel {

    /// Activates the cellular mode.
    func activateLTE() {
        currentDrone.drone.getPeripheral(Peripherals.cellular)?.mode.value = .data
    }

    /// Tells if the pin code modal should be displayed.
    func shouldDisplayPinCodeModal() -> Bool {
        guard let shouldDisplay = currentDrone.drone.getPeripheral(Peripherals.cellular)?.isPinCodeRequested else {
            return false
        }
        return shouldDisplay
    }

    func unpairAllUsers() {
        pairingService.startUnpairProcessRequest()
    }

    /// Updates number of paired users.
    func updatesPairedUsersCount() {
        academyApiService.performPairedDroneListRequest { pairedDroneList in
            let uid = self.currentDrone.drone.uid
            guard pairedDroneList != nil,
                  pairedDroneList?.isEmpty == false,
                  let commonName = pairedDroneList?.first(where: {
                    $0.serial == uid
                  })?.commonName else {
                return
            }

            self.academyApiService.pairedUsersCount(commonName: commonName) { number, error in
                DispatchQueue.main.async {
                    self.updateConnectedUser(usersCount: error == nil ? number : 0)
                }
            }
        }
    }
}

// MARK: - Private Funcs
private extension DroneDetailsCellularViewModel {

    /// Starts watcher for drone's connection state.
    ///
    /// - Parameter drone: the current drone
    func listenConnectionState(drone: Drone) {
        connectionStateRef = drone.getState { [weak self] state in
            self?.connectionState = state?.connectionState ?? .disconnected
        }
    }

    /// Updates drones paired list by removing element after unpairing process.
    ///
    /// - Parameters:
    ///     - uid: drone uid
    func removeFromPairedList(with uid: String) {
        var dronePairedListSet = Set(Defaults.cellularPairedDronesList)
        dronePairedListSet.remove(uid)
        Defaults.cellularPairedDronesList = Array(dronePairedListSet)
    }

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

// MARK: - State Update Funcs
/// Extension used to stores only atomic update funcs.
private extension DroneDetailsCellularViewModel {

    /// Updates operator name.
    ///
    /// - Parameters:
    ///     - operatorName: name of the operator
    func updateOperatorName(operatorName: String) {
        self.operatorName = operatorName
    }

    /// Updates connected users count.
    ///
    /// - Parameters:
    ///     - usersCount: number of paired users
    func updateConnectedUser(usersCount: Int?) {
        self.usersCount = usersCount ?? 0
    }
}
