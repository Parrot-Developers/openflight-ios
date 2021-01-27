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

// MARK: - Internal Enums
/// Stores states which occurs during drone unpairing.
enum UnpairDroneState: Equatable {
    case notStarted
    case noInternet
    case forgetError(context: UnpairDroneStateContext)
    case done

    /// Title of the state.
    var title: String? {
        switch self {
        case .noInternet:
            return L10n.commonNoInternetConnection
        case .forgetError(.details):
            return L10n.cellularPairingDetailsForgotError
        case .forgetError(.discover):
            return L10n.cellularPairingDiscoveryForgotError
        default:
            return nil
        }
    }

    /// Returns true if an error needs to be displayed.
    var shouldShowError: Bool {
        switch self {
        case .noInternet,
             .forgetError:
            return true
        default:
            return false
        }
    }
}

/// Specify context of drone unpairing.
enum UnpairDroneStateContext {
    case details
    case discover
}

/// State for `DroneDetailsCellularViewModel`.
final class DroneDetailsCellularState: DeviceConnectionState {
    // MARK: - Internal Properties
    /// Drone's cellular connection state.
    fileprivate(set) var cellularState: CellularSimStatus = .unknown
    /// Number of connected user.
    fileprivate(set) var userNumber: Int = 0
    /// Name of the operator.
    fileprivate(set) var operatorName: String?
    /// Tells if we can show cellular. If card is blocked we can't enter Pin Code anymore.
    fileprivate(set) var canShowCellular: Bool = false
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
    ///    - cellularState: drone's cellular state
    ///    - userNumber: connected user number
    ///    - operatorName: name of the operator when network is ready
    ///    - canShowCellular:  Tells if we can show cellular screen
    ///    - unpairState: drone unpair process state
    init(connectionState: DeviceState.ConnectionState,
         cellularState: CellularSimStatus,
         userNumber: Int,
         operatorName: String?,
         canShowCellular: Bool,
         unpairState: UnpairDroneState) {
        super.init(connectionState: connectionState)

        self.cellularState = cellularState
        self.userNumber = userNumber
        self.operatorName = operatorName
        self.canShowCellular = canShowCellular
        self.canShowCellular = canShowCellular
        self.unpairState = unpairState
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? DroneDetailsCellularState else { return false }

        return super.isEqual(to: other)
            && self.cellularState == other.cellularState
            && self.userNumber == other.userNumber
            && self.operatorName == other.operatorName
            && self.canShowCellular == other.canShowCellular
            && self.unpairState == other.unpairState
    }

    override func copy() -> DroneDetailsCellularState {
        return DroneDetailsCellularState(connectionState: self.connectionState,
                                         cellularState: self.cellularState,
                                         userNumber: self.userNumber,
                                         operatorName: self.operatorName,
                                         canShowCellular: self.canShowCellular,
                                         unpairState: self.unpairState)
    }
}

/// View model managing drone cellular information in drone details screen.
final class DroneDetailsCellularViewModel: DroneStateViewModel<DroneDetailsCellularState> {
    // MARK: - Private Properties
    private var cellularRef: Ref<Cellular>?
    private var academyApiManager: AcademyApiManager = AcademyApiManager()

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenDroneCellularAccess(drone)
    }

    // MARK: - Internal Funcs
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
    func listenDroneCellularAccess(_ drone: Drone) {
        cellularRef = drone.getPeripheral(Peripherals.cellular) { [weak self] _ in
            self?.updateCellularState()
        }
        updateCellularState()
    }

    /// Updates cellular state.
    func updateCellularState() {
        let cellular = cellularRef?.value
        let copy = state.value.copy()
        guard let status = cellular?.simStatus else {
            copy.cellularState = .unknown
            state.set(copy)
            return
        }

        copy.canShowCellular = cellular?.simStatus == .locked
            && cellular?.pinRemainingTries != 0
            && cellular?.isPinCodeRequested == true
        copy.cellularState = status
        copy.operatorName = cellular?.operator
        copy.userNumber = cellular?.simStatus == .ready ? 1 : 0 // TODO: Wait info from SDK
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

    /// Update drones paired list by removing element after unpair process.
    ///
    /// - Parameters:
    ///     - uid: drone uid
    func removeFromPairedList(with uid: String) {
        var dronePairedListSet = Set(Defaults.cellularPairedDronesList)
        dronePairedListSet.remove(uid)
        Defaults.cellularPairedDronesList = Array(dronePairedListSet)
    }
}
