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
    private var cellularRef: Ref<Cellular>?
    private var networkControlRef: Ref<NetworkControl>?
    private var connectionStateRef: Ref<DeviceState>?
    private var academyApiManager: AcademyApiManager = AcademyApiManager()
    private var cancellables = Set<AnyCancellable>()
    private var currentDrone = Services.hub.currentDroneHolder

    init() {
        Services.hub.currentDroneHolder.dronePublisher
            .sink { [unowned self] drone in
                listenCellular(drone)
                listenNetworkControl(drone)
                listenConnectionState(drone: drone)
                updateCellularState(drone: drone)
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

    /// Unpairs the current drone.
    func forgetDrone() {
        let reachability = try? Reachability()
        guard reachability?.isConnected == true else {
            self.updateResetStatus(with: .noInternet(context: .details))
            return
        }

        // Get the list of paired drone.
        academyApiManager.performPairedDroneListRequest { pairedDroneList in
            let uid = self.currentDrone.drone.uid

            // Academy calls are asynchronous update should be done on main thread
            DispatchQueue.main.async {
                guard pairedDroneList != nil,
                      pairedDroneList?.isEmpty == false
                else {
                    self.updateResetStatus(with: .forgetError(context: .details))
                    return
                }
            }

            pairedDroneList?
                .compactMap { $0.serial == uid ? $0.commonName : nil }
                .forEach { commonName in
                    // Unpair the drone.
                    self.academyApiManager.unpairDrone(commonName: commonName) { _, error in
                        // Academy calls are asynchronous update should be done on main thread
                        DispatchQueue.main.async {
                            guard error == nil else {
                                self.updateResetStatus(with: .forgetError(context: .details))
                                return
                            }

                            self.updateResetStatus(with: .done)
                            self.removeFromPairedList(with: uid)
                            self.resetPairingDroneListIfNeeded()
                            self.updateCellularStatus(with: .userNotPaired)
                        }
                    }
                }
        }
    }

    /// Updates number of paired users.
    func updatesPairedUsersCount() {
        academyApiManager.performPairedDroneListRequest { pairedDroneList in
            let uid = self.currentDrone.drone.uid
            guard pairedDroneList != nil,
                  pairedDroneList?.isEmpty == false,
                  let commonName = pairedDroneList?.first(where: {
                    $0.serial == uid
                  })?.commonName else {
                return
            }

            self.academyApiManager.pairedUsersCounts(commonName: commonName) { number, error in
                DispatchQueue.main.async {
                    self.updateConnectedUser(usersCount: error == nil ? number : 0)
                }
            }
        }
    }
}

// MARK: - Private Funcs
private extension DroneDetailsCellularViewModel {
    /// Starts watcher for drone cellular access state.
    func listenCellular(_ drone: Drone) {
        cellularRef = drone.getPeripheral(Peripherals.cellular) { [weak self] _ in
            self?.updateCellularState(drone: drone)
        }
    }

    /// Starts watcher for drone network control.
    func listenNetworkControl(_ drone: Drone) {
        networkControlRef = drone.getPeripheral(Peripherals.networkControl) { [weak self] _ in
            self?.updateCellularState(drone: drone)
        }
    }

    /// Starts watcher for drone's connection state.
    ///
    /// - Parameter drone: the current drone
    func listenConnectionState(drone: Drone) {
        connectionStateRef = drone.getState { [weak self] state in
            self?.connectionState = state?.connectionState ?? .disconnected
        }
    }

    /// Updates cellular state.
    func updateCellularState(drone: Drone) {
        var status: DetailsCellularStatus = .noState

        guard let cellular = drone.getPeripheral(Peripherals.cellular),
              drone.isConnected == true else {
            updateCellularStatus(with: status)
            return
        }

        // Update the current cellular state.
        let networkControl = drone.getPeripheral(Peripherals.networkControl)
        let cellularLink = networkControl?.links.first(where: { $0.type == .cellular })
        let isDronePaired: Bool = drone.isAlreadyPaired == true

        if cellularLink?.status == .running,
           isDronePaired {
            status = .cellularConnected
        } else if cellular.mode.value == .nodata {
            status = .noData
        } else if cellular.simStatus == .absent {
            status = .simNotDetected
        } else if cellular.simStatus == .unknown {
            status = .simNotRecognized
        } else if cellular.simStatus == .locked {
            if cellular.pinRemainingTries == 0 {
                status = .simBlocked
            } else {
                status = .simLocked
            }
        } else if !isDronePaired {
            status = .userNotPaired
        } else if cellularLink?.status == .error || cellularLink?.error != nil {
            status = .connectionFailed
        } else if cellular.modemStatus != .online {
            status = .modemStatusOff
        } else if cellular.registrationStatus == .notRegistered {
            status = .notRegistered
        } else if cellular.networkStatus == .error {
            status = .networkStatusError
        } else if cellular.networkStatus == .denied {
            status = .networkStatusDenied
        } else if cellular.isAvailable {
            status = .cellularConnecting
        } else {
            status = .noState
        }

        updateCellularStatus(with: status)
        updateOperatorName(operatorName: cellular.operator)
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

    /// Updates cellular status.
    ///
    /// - Parameters:
    ///     - cellularStatus: 4G status to update
    func updateCellularStatus(with cellularStatus: DetailsCellularStatus) {
        self.cellularStatus = cellularStatus
    }

    /// Updates the reset status.
    ///
    /// - Parameters:
    ///     - unpairState: current drone unpair state
    func updateResetStatus(with unpairState: UnpairDroneState) {
        self.unpairState = unpairState
    }
}
