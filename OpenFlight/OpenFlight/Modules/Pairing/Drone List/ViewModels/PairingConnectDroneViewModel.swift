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
import Reachability

/// State for `PairingConnectDroneViewModel`.
final class PairingConnectDroneState: DevicesConnectionState {
    // MARK: - Internal Properties
    var isListUnavailable: Bool {
        return isListScanning == true ||
            discoveredDronesList?.isEmpty == true
    }

    // MARK: - Internal Properties
    /// List of discovered drones.
    fileprivate(set) var discoveredDronesList: [RemoteConnectDroneModel]?
    /// Check if the droneFinder list is scanning.
    fileprivate(set) var isListScanning: Bool?
    /// Check if the droneFinder list is scanning.
    fileprivate(set) var connectionState: PairingDroneConnectionState?
    /// Current unpair state.
    fileprivate(set) var unpairState: UnpairDroneState = .notStarted

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - droneConnectionState: drone connection state
    ///    - remoteControlConnectionState: remote control connection state
    ///    - discoveredDroneList: list of discovered drones
    ///    - isListScanning: list currently scanning
    ///    - connectionState: current pairing connection state
    ///    - unpairState: unpair process state
    init(droneConnectionState: DeviceConnectionState?,
         remoteControlConnectionState: DeviceConnectionState?,
         discoveredDroneList: [RemoteConnectDroneModel]?,
         isListScanning: Bool?,
         connectionState: PairingDroneConnectionState?,
         unpairState: UnpairDroneState) {
        super.init(droneConnectionState: droneConnectionState, remoteControlConnectionState: remoteControlConnectionState)
        self.discoveredDronesList = discoveredDroneList
        self.isListScanning = isListScanning
        self.connectionState = connectionState
        self.unpairState = unpairState
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DevicesConnectionState) -> Bool {
        guard let other = other as? PairingConnectDroneState else {
            return false
        }

        return super.isEqual(to: other)
            && self.isListScanning == other.isListScanning
            && self.connectionState == other.connectionState
            && self.discoveredDronesList == other.discoveredDronesList
            && self.unpairState == other.unpairState
    }

    override func copy() -> PairingConnectDroneState {
        let copy = PairingConnectDroneState(droneConnectionState: self.droneConnectionState,
                                            remoteControlConnectionState: self.remoteControlConnectionState,
                                            discoveredDroneList: self.discoveredDronesList,
                                            isListScanning: self.isListScanning,
                                            connectionState: self.connectionState,
                                            unpairState: self.unpairState)
        return copy
    }
}

/// ViewModel for PairingConnectDrone, notifies on remote/drone changement like list of discovered drones.
final class PairingConnectDroneViewModel: DevicesStateViewModel<PairingConnectDroneState> {
    // MARK: - Private Properties
    private let groundSdk = GroundSdk()
    private var droneFinderRef: Ref<DroneFinder>?
    private var droneStateRef: Ref<DeviceState>?
    private var droneConnectionStateRef: Ref<DeviceState>?
    private var timer: Timer?
    private var academyApiManager: AcademyApiManager = AcademyApiManager()

    // MARK: - Private Enums
    private enum Constants {
        static let timeInterval: Double = 5.0
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenDroneStateRef(for: drone)
    }

    override func listenRemoteControl(remoteControl: RemoteControl) {
        super.listenRemoteControl(remoteControl: remoteControl)

        refreshDroneFinder(remoteControl: remoteControl)
        listenDroneFinderRef(remoteControl: remoteControl)
    }

    override func droneConnectionStateDidChange() {
        super.droneConnectionStateDidChange()

        refreshDroneList()
    }

    // MARK: - Internal Funcs
    /// Refresh drone finder.
    func refreshDroneList() {
        guard let droneFinder = remoteControl?.getPeripheral(Peripherals.droneFinder) else { return }

        // Check if we are scanning available drones.
        if droneFinder.state == .idle {
            droneFinder.refresh()
        }

        stopTimer()
    }

    /// Setup the view for the cell.
    ///
    /// - Parameters:
    ///    - uid: Uid of the selected drone
    ///    - password: Password enter by user
    func connectDrone(uid: String, password: String?) {
        if let password = password {
            let copy = state.value.copy()
            guard WifiPasswordUtil.isValid(password),
                  let drone = droneFinderRef?.value?.discoveredDrones.first(where: { $0.uid == uid }),
                  remoteControl?.getPeripheral(Peripherals.droneFinder)?.connect(discoveredDrone: drone,
                                                                                 password: password) == true else {
                copy.connectionState = .incorrectPassword
                state.set(copy)

                return
            }

            copy.connectionState = .connecting
            state.set(copy)
        }

        listenDroneConnectionStateRef(uid: uid)
    }

    /// Connect the drone when we don't need a password.
    ///
    /// - Parameters:
    ///    - uid: Uid of the selected drone
    func connectDroneWithoutPassword(uid: String) {
        guard let drone = droneFinderRef?.value?.discoveredDrones.first(where: { $0.uid == uid }),
              (drone.connectionSecurity != .password || drone.known == true),
              remoteControl?.getPeripheral(Peripherals.droneFinder)?.connect(discoveredDrone: drone) == true else {
            return
        }

        let copy = state.value.copy()
        copy.connectionState = .connecting
        state.set(copy)
        listenDroneConnectionStateRef(uid: uid)
    }

    /// Check if the drone need a password.
    ///
    /// - Parameters:
    ///    - uid: Uid of the selected drone
    func needPassword(uid: String) -> Bool {
        guard let drone = droneFinderRef?.value?.discoveredDrones.first(where: { $0.uid == uid }),
              (drone.connectionSecurity != .password || drone.known == true) else {
            return true
        }

        return false
    }

    /// Reset the ref.
    func resetDroneConnectionStateRef() {
        droneConnectionStateRef = nil
    }

    /// Forgets the current drone.
    ///
    /// - Parameters:
    ///     - uid: current uid
    func forgetDrone(uid: String) {
        guard groundSdk.forgetDrone(uid: uid) else { return }

        // Cleans last connected drone.
        CurrentDroneStore.clearLastConnectedDroneIfNeeded(uid: uid)

        let reachability = try? Reachability()
        guard reachability?.isConnected == true else {
            self.updateUnpairStatus(with: .noInternet)
            return
        }

        // Unpairs potential 4G paired drone.
        state.value.discoveredDronesList?.forEach { drone in
            if drone.droneUid == uid,
               drone.isDronePaired {
                academyApiManager.unpairDrone(commonName: drone.commonName) { _, error in
                    guard error == nil else {
                        self.updateUnpairStatus(with: .forgetError(context: .discover))
                        return
                    }

                    self.updateUnpairStatus(with: .done)
                    self.removeFromPairedList(with: uid)
                }
            }
        }
        refreshDroneList()
    }
}

// MARK: - Private Funcs
private extension PairingConnectDroneViewModel {
    /// Starts watcher for drone finder.
    func listenDroneFinderRef(remoteControl: RemoteControl) {
        droneFinderRef = remoteControl.getPeripheral(Peripherals.droneFinder) { [weak self] droneFinder in
            guard let droneFinder = droneFinder else { return }

            self?.updateDroneList(droneFinder: droneFinder)
        }
    }

    /// Updates drone list.
    ///
    /// - Parameters:
    ///     - droneFinder
    func updateDroneList(droneFinder: DroneFinder) {
        let copy = state.value.copy()
        // Check if we are scanning available drones.
        if droneFinder.state == .idle {
            let discoveredDrones = droneFinder.discoveredDrones.sorted { (drone1, drone2) -> Bool in
                // Sort drone by rssi.
                return drone1.rssi > drone2.rssi
            }

            // Start a timer when drone list is empty.
            if discoveredDrones.isEmpty {
                startTimer()
            }

            // Fill the state with the discoveredDrones list returned by droneFinder.
            copy.discoveredDronesList = discoveredDrones.map { drone -> RemoteConnectDroneModel in
                return RemoteConnectDroneModel(droneUid: drone.uid,
                                               droneName: drone.name,
                                               isKnown: drone.known,
                                               rssiImage: drone.image,
                                               isDronePaired: false,
                                               isDroneConnected: isDroneConnected(uid: drone.uid),
                                               commonName: "")
            }

            academyApiManager.performPairedDroneListRequest { pairedDroneList in
                guard pairedDroneList != nil else {
                    copy.isListScanning = false
                    self.state.set(copy)

                    return
                }

                // Tuple of paired 4G drones.
                let paired4GDrones = pairedDroneList?.compactMap({
                    return $0.pairedFor4g ? (serial: $0.serial, commonName: $0.commonName) : nil
                })

                copy.discoveredDronesList?
                    .enumerated()
                    .forEach { (index, drone) in
                        if let pairedDrone = paired4GDrones?.first(where: { $0.serial == drone.droneUid }) {
                            copy.discoveredDronesList?[index].isDronePaired = true
                            copy.discoveredDronesList?[index].commonName = pairedDrone.commonName ?? ""
                        }
                    }
                copy.isListScanning = false
                self.state.set(copy)
            }
        } else {
            copy.isListScanning = true
            state.set(copy)
        }
    }

    /// Start a timer which will refresh the list.
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: Constants.timeInterval, repeats: false) { _ in
            self.refreshDroneList()
        }
    }

    /// Stop the timer when user want to refresh the list manually.
    func stopTimer() {
        timer?.invalidate()
    }

    /// Starts watcher for drone state.
    func listenDroneStateRef(for drone: Drone) {
        // We need to create a new Ref in order of listenning connection state.
        // It is due to drone connection state ref. This observer is listenning several states but it does not work for "connected" state.
        droneStateRef = drone.getState { [weak self] state in
            let copy = self?.state.value.copy()
            if state?.connectionState == .connected {
                copy?.connectionState = .connected
                self?.state.set(copy)
                self?.resetDroneConnectionStateRef()
            }
        }
    }

    /// Starts watcher for drone connection state.
    ///
    /// - Parameters:
    ///    - uid: Uid of the selected drone
    func listenDroneConnectionStateRef(uid: String) {
        droneConnectionStateRef = groundSdk.getDrone(uid: uid)?.getState { [weak self] state in
            let copy = self?.state.value.copy()
            switch state?.connectionState {
            case .connecting:
                copy?.connectionState = .connecting
            case .connected:
                copy?.connectionState = .connected
                self?.refreshDroneList()
            case .disconnected:
                if state?.connectionStateCause == DeviceState.ConnectionStateCause.badPassword {
                    copy?.connectionState = .incorrectPassword
                } else {
                    copy?.connectionState = .disconnected
                }
            default:
                break
            }
            self?.state.set(copy)
        }
    }

    /// Refresh drone finder in order to get the list of drones.
    ///
    /// - Parameters:
    ///    - remoteControl: Current Remote
    func refreshDroneFinder(remoteControl: RemoteControl) {
        guard let droneFinder = remoteControl.getPeripheral(Peripherals.droneFinder) else { return }

        // Check if we are scanning available drones.
        if droneFinder.state == .idle {
            droneFinder.refresh()
        }
    }

    /// Returns true if the drone is the connected one.
    ///
    /// - Parameters:
    ///     - uid: drone uid
    func isDroneConnected(uid: String) -> Bool {
        guard drone?.isConnected == true else { return false }

        return uid == drone?.uid
    }

    /// Update the reset status.
    ///
    /// - Parameters:
    ///     - unpairState: tells if drone unpair succeeded
    func updateUnpairStatus(with unpairState: UnpairDroneState) {
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
