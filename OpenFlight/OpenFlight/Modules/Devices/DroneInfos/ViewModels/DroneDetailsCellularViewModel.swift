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

/// State for `DroneDetailsCellularViewModel`.
final class DroneDetailsCellularState: DeviceConnectionState {
    // MARK: - Internal Properties
    /// Drone's cellular connection state.
    fileprivate(set) var cellularStatus: DetailsCellularStatus = .noState
    /// Number of connected user.
    fileprivate(set) var userNumber: Int = 0
    /// Name of the operator.
    fileprivate(set) var operatorName: String?
    /// Current drone unpair state.
    fileprivate(set) var unpairState: UnpairDroneState = .notStarted

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: drone's connection state
    ///    - cellularStatus: drone's cellular state
    ///    - userNumber: connected user number
    ///    - operatorName: name of the operator when network is ready
    ///    - unpairState: drone unpair process state
    init(connectionState: DeviceState.ConnectionState,
         cellularStatus: DetailsCellularStatus,
         userNumber: Int,
         operatorName: String?,
         unpairState: UnpairDroneState) {
        super.init(connectionState: connectionState)

        self.cellularStatus = cellularStatus
        self.userNumber = userNumber
        self.operatorName = operatorName
        self.unpairState = unpairState
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? DroneDetailsCellularState else { return false }

        return super.isEqual(to: other)
            && self.cellularStatus == other.cellularStatus
            && self.userNumber == other.userNumber
            && self.operatorName == other.operatorName
            && self.unpairState == other.unpairState
    }

    override func copy() -> DroneDetailsCellularState {
        return DroneDetailsCellularState(connectionState: self.connectionState,
                                         cellularStatus: self.cellularStatus,
                                         userNumber: self.userNumber,
                                         operatorName: self.operatorName,
                                         unpairState: self.unpairState)
    }
}

/// View model managing drone cellular information in drone details screen.
final class DroneDetailsCellularViewModel: DroneStateViewModel<DroneDetailsCellularState> {
    // MARK: - Private Properties
    private var cellularRef: Ref<Cellular>?
    private var networkControlRef: Ref<NetworkControl>?
    private var academyApiManager: AcademyApiManager = AcademyApiManager()

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenCellular(drone)
        listenNetworkControl(drone)
        updateCellularStatus()
    }

    override func droneConnectionStateDidChange() {
        super.droneConnectionStateDidChange()

        updateCellularStatus()
    }
}

// MARK: - Internal Funcs
extension DroneDetailsCellularViewModel {
    /// Unpair the current drone.
    func forgetDrone() {
        let reachability = try? Reachability()
        guard reachability?.isConnected == true else {
            self.updateResetStatus(with: .noInternet)
            return
        }

        // Get the list of paired drone.
        academyApiManager.performPairedDroneListRequest { pairedDroneList in
            guard pairedDroneList != nil,
                  pairedDroneList?.isEmpty == false,
                  let uid = self.drone?.uid else {
                self.updateResetStatus(with: .forgetError(context: .details))
                return
            }

            pairedDroneList?
                .compactMap { $0.serial == uid ? $0.commonName : nil }
                .forEach { commonName in
                    // Unpair the drone.
                    self.academyApiManager.unpairDrone(commonName: commonName) { _, error in
                        guard error == nil else {
                            self.updateResetStatus(with: .forgetError(context: .details))
                            return
                        }

                        self.updateResetStatus(with: .done)
                        self.removeFromPairedList(with: uid)
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
            self?.updateCellularStatus()
        }
    }

    /// Starts watcher for drone network control.
    func listenNetworkControl(_ drone: Drone) {
        networkControlRef = drone.getPeripheral(Peripherals.networkControl) { [weak self] _ in
            self?.updateCellularStatus()
        }
    }

    /// Updates cellular status.
    func updateCellularStatus() {
        var status: DetailsCellularStatus = .noState

        guard let cellular = drone?.getPeripheral(Peripherals.cellular),
              drone?.isConnected == true else {
            updateCellularStatus(with: status)
            return
        }

        // Update the current cellular state.
        let networkControl = drone?.getPeripheral(Peripherals.networkControl)
        let cellularLink = networkControl?.links.first(where: { $0.type == .cellular })
        let isReady = cellular.registrationStatus == .registeredHome
            || cellular.registrationStatus == .registeredRoaming
            || cellular.networkStatus == .activated
            || cellular.simStatus == .ready
            || cellularLink?.status == .up
        if cellularLink?.status == .running {
            status = .cellularConnected
        } else if isReady {
            status = .cellularConnecting
        } else if cellularLink?.status == .error || cellularLink?.error != nil {
            status = .connectionFailed
        } else {
            if cellular.modemStatus != .online {
                status = .modemStatusOff
            } else if cellular.mode.value == .nodata {
                status = .noData
            } else if cellular.simStatus == .absent {
                status = .simNotDetected
            } else if cellular.simStatus == .unknown {
                status = .simNotRecognized
            } else if cellular.simStatus == .locked
                        && cellular.pinRemainingTries == 0 {
                status = .simBlocked
            } else if cellular.registrationStatus == .notRegistered {
                status = .notRegistered
            } else if cellular.networkStatus == .error {
                status = .networkStatusError
            } else if cellular.networkStatus == .denied {
                status = .networkStatusDenied
            } else {
                status = .noState
            }
        }

        updateCellularStatus(with: status)
        updateOperatorName(operatorName: cellular.operator)
        updateConnectedUser(simStatus: cellular.simStatus)
    }

    /// Update drones paired list by removing element after unpairing process.
    ///
    /// - Parameters:
    ///     - uid: drone uid
    func removeFromPairedList(with uid: String) {
        var dronePairedListSet = Set(Defaults.cellularPairedDronesList)
        dronePairedListSet.remove(uid)
        Defaults.cellularPairedDronesList = Array(dronePairedListSet)
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
        let copy = state.value.copy()
        copy.operatorName = operatorName
        state.set(copy)
    }

    /// Updates connected user.
    ///
    /// - Parameters:
    ///     - simStatus: Cellular sim status
    func updateConnectedUser(simStatus: CellularSimStatus) {
        // TODO: Will be done later with API call to get paired users number.
        let copy = state.value.copy()
        copy.userNumber = simStatus == .ready ? 1 : 0
        state.set(copy)
    }

    /// Updates cellular status.
    ///
    /// - Parameters:
    ///     - cellularStatus: 4G status to update
    func updateCellularStatus(with cellularStatus: DetailsCellularStatus) {
        let copy = state.value.copy()
        copy.cellularStatus = cellularStatus
        state.set(copy)
    }

    /// Update the reset status.
    ///
    /// - Parameters:
    ///     - unpairState: current drone unpair state
    func updateResetStatus(with unpairState: UnpairDroneState) {
        let copy = state.value.copy()
        copy.unpairState = unpairState
        state.set(copy)
    }
}
