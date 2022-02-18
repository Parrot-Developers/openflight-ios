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

private extension ULogTag {
    static let tag = ULogTag(name: "PairingConnectDroneViewModel")
}

/// ViewModel for PairingConnectDrone, notifies on remote/drone changement like list of discovered drones.
final class PairingConnectDroneViewModel {
    // MARK: - Internal Properties
    /// List of discovered drones.
    @Published private(set) var discoveredDronesList: [RemoteConnectDroneModel]?
    /// Check if the droneFinder list is scanning.
    @Published private(set) var isListScanning: Bool = false
    /// Current pairing connection state.
    @Published private(set) var pairingConnectionState: PairingDroneConnectionState = .disconnected
    /// Current unpair state.
    @Published private(set) var unpairState: UnpairDroneState = .notStarted
    /// Drone connection state.
    @Published private(set) var droneConnectionState: DeviceState.ConnectionState = .disconnected
    /// Remote control connection state.
    @Published private(set) var remoteControlConnectionState: DeviceState.ConnectionState = .disconnected

    /// Check if the list of the discovered drone is unavailable
    var isListUnavailable: AnyPublisher<Bool, Never> {
        $isListScanning.combineLatest($discoveredDronesList)
            .map { (isListScanning, discoveredDronesList) in
                return isListScanning == true || discoveredDronesList?.isEmpty == true
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private Properties
    private let groundSdk = GroundSdk()
    private var droneFinderRef: Ref<DroneFinder>?
    private var droneStateRef: Ref<DeviceState>?
    private var remoteControlStateRef: Ref<DeviceState>?
    private var timer: Timer?
    private var academyApiService: AcademyApiService = Services.hub.academyApiService
    private var networkService: NetworkService = Services.hub.systemServices.networkService
    private var currentDroneHolder: CurrentDroneHolder = Services.hub.currentDroneHolder
    private var currentRemoteControlHolder: CurrentRemoteControlHolder = Services.hub.currentRemoteControlHolder
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Private Enums
    private enum Constants {
        static let timeInterval: Double = 5.0
    }

    // MARK: - Init
    init() {
        currentDroneHolder.dronePublisher
            .compactMap { $0 }
            .sink { [unowned self] drone in
                listenDroneConnectionState(uid: drone.uid)
            }
            .store(in: &cancellables)

        currentRemoteControlHolder.remoteControlPublisher
            .compactMap { $0 }
            .sink { [unowned self] remoteControl in
                listenRemoteControlConnectionState(remoteControl: remoteControl)
                listenDroneFinderRef(remoteControl: remoteControl)
            }
            .store(in: &cancellables)
    }

    // MARK: - Internal Funcs
    /// Refresh drone finder.
    func refreshDroneList() {
        guard let droneFinder = currentRemoteControlHolder.remoteControl?.getPeripheral(Peripherals.droneFinder) else { return }

        // Check if we are scanning available drones.
        if droneFinder.state == .idle {
            droneFinder.refresh()
        }

        stopTimer()
    }

    /// Connect the drone when we don't need a password.
    ///
    /// - Parameters:
    ///    - uid: Uid of the selected drone
    func connectDroneWithoutPassword(uid: String) {
        let droneFinder = currentRemoteControlHolder.remoteControl?.getPeripheral(Peripherals.droneFinder)
        guard let drone = droneFinder?.discoveredDrones.first(where: { $0.uid == uid }),
              (drone.connectionSecurity != .password || drone.known == true),
              droneFinder?.connect(discoveredDrone: drone) == true else {
                  return
              }
        pairingConnectionState = .connecting
        listenDroneConnectionState(uid: uid)
    }

    /// Check if the drone need a password.
    ///
    /// - Parameters:
    ///    - uid: Uid of the selected drone
    func needPassword(uid: String) -> Bool {
        let droneFinder = currentRemoteControlHolder.remoteControl?.getPeripheral(Peripherals.droneFinder)
        guard let drone = droneFinder?.discoveredDrones.first(where: { $0.uid == uid }),
              (drone.connectionSecurity != .password || drone.known == true) else {
                  return true
              }

        return false
    }

    /// Forgets the current drone.
    ///
    /// - Parameters:
    ///     - uid: current uid
    func forgetDrone(uid: String) {
        // Cleans last connected drone.
        // TODO inject
        Services.hub.currentDroneHolder.clearCurrentDroneOnMatch(uid: uid)
        guard let drone = discoveredDronesList?.first(where: { $0.droneUid == uid }) else {
            return
        }

        guard drone.isDronePaired else {
            _ = groundSdk.forgetDrone(uid: uid)
            refreshDroneList()
            return
        }

        if !networkService.networkIsReachable {
            updateUnpairStatus(with: .noInternet(context: .discover))
            refreshDroneList()
            return
        }

        academyApiService.unpairDrone(commonName: drone.commonName) { [weak self] _, error in
            guard error == nil else {
                self?.updateUnpairStatus(with: .forgetError(context: .discover))
                self?.refreshDroneList()
                return
            }

            self?.updateUnpairStatus(with: .done)
            self?.removeFromPairedList(with: uid)
            self?.resetPairingDroneListIfNeeded()

            DispatchQueue.main.async { [weak self] in
                _ = self?.groundSdk.forgetDrone(uid: drone.droneUid)
                self?.refreshDroneList()
            }
        }
    }
}

// MARK: - Private Funcs
private extension PairingConnectDroneViewModel {
    /// Starts watcher for drone finder.
    ///
    /// - Parameters:
    ///    - remoteControl: the remote control
    func listenDroneFinderRef(remoteControl: RemoteControl) {
        droneFinderRef = remoteControl.getPeripheral(Peripherals.droneFinder) { [unowned self] droneFinder in
            guard let droneFinder = droneFinder else { return }

            updateDroneList(droneFinder: droneFinder)
        }
    }

    /// Starts watcher for remote control connection state.
    ///
    /// - Parameters:
    ///    - remoteControl: the remote control
    func listenRemoteControlConnectionState(remoteControl: RemoteControl) {
        remoteControlStateRef = remoteControl.getState { [unowned self] state in
            guard let state = state else {
                remoteControlConnectionState = .disconnected
                return
            }

            remoteControlConnectionState = state.connectionState
            if remoteControlConnectionState == .connected {
                refreshDroneList()
            }
        }
    }

    /// Starts watcher for drone connection state.
    ///
    /// - Parameters:
    ///    - uid: the uid of the selected drone
    func listenDroneConnectionState(uid: String) {
        droneStateRef = groundSdk.getDrone(uid: uid)?.getState { [unowned self] state in
            guard let state = state else {
                droneConnectionState = .disconnected
                droneStateRef = nil
                return
            }

            droneConnectionState = state.connectionState
            switch state.connectionState {
            case .connecting:
                pairingConnectionState = .connecting
            case .connected:
                pairingConnectionState = .connected
                refreshDroneList()
                droneStateRef = nil
            case .disconnected:
                if state.connectionStateCause == DeviceState.ConnectionStateCause.badPassword {
                    pairingConnectionState = .incorrectPassword
                } else {
                    pairingConnectionState = .disconnected
                }
                droneStateRef = nil
            default:
                break
            }
        }
    }

    /// Updates drone list.
    ///
    /// - Parameters:
    ///     - droneFinder
    func updateDroneList(droneFinder: DroneFinder) {
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
            discoveredDronesList = discoveredDrones
                .filter {
                    ULog.i(.tag, "\($0.name) -> 4G \($0.cellularOnLine ? 1 : 0), " +
                           "Wifi: \($0.wifiVisibility ? 1 : 0), " +
                           "Known: \($0.known ? 1 : 0), " +
                           "Need password: \($0.connectionSecurity.description)")
                    return $0.cellularOnLine || $0.wifiVisibility
                }
                .map { drone -> RemoteConnectDroneModel in
                    let isConnected = isDroneConnected(uid: drone.uid)
                    let wifiSignalQualityImage = isConnected ? drone.wifiHighlightImage : drone.wifiImage
                    let cellularImage = isConnected ? drone.cellularHighlightImage : drone.cellularImage
                    return RemoteConnectDroneModel(droneUid: drone.uid,
                                                   droneName: drone.name,
                                                   isKnown: drone.known,
                                                   wifiSignalQualityImage: wifiSignalQualityImage,
                                                   wifiImageVisible: drone.wifiVisibility,
                                                   cellularImage: cellularImage,
                                                   cellularImageVisible: drone.cellularOnLine,
                                                   isDronePaired: false,
                                                   isDroneConnected: isConnected,
                                                   commonName: "")
                }

            academyApiService.performPairedDroneListRequest { [weak self] pairedDroneListResponse in
                guard let pairedDroneListResponse = pairedDroneListResponse else {
                    self?.isListScanning = false
                    return
                }

                // Tuple of paired 4G drones.
                let paired4GDrones = pairedDroneListResponse.compactMap({
                    return $0.pairedFor4G ? (serial: $0.serial, commonName: $0.commonName) : nil
                })

                self?.discoveredDronesList?
                    .enumerated()
                    .forEach { (index, drone) in
                        if let pairedDrone = paired4GDrones.first(where: { $0.serial == drone.droneUid }) {
                            self?.discoveredDronesList?[index].isDronePaired = true
                            self?.discoveredDronesList?[index].commonName = pairedDrone.commonName ?? ""
                        }
                    }
                self?.isListScanning = false
            }
        } else {
            isListScanning = true
        }
    }

    /// Removes current drone uid in the dismissed pairing list.
    /// The pairing process for the current drone could be displayed again in the HUD.
    func resetPairingDroneListIfNeeded() {
        let drone = currentDroneHolder.drone
        let uid = drone.uid
        guard Defaults.dronesListPairingProcessHidden.contains(uid),
              drone.isAlreadyPaired == false else {
                  return
              }

        Defaults.dronesListPairingProcessHidden.removeAll(where: { $0 == uid })
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

    /// Returns true if the drone is the connected one.
    ///
    /// - Parameters:
    ///     - uid: drone uid
    func isDroneConnected(uid: String) -> Bool {
        guard currentDroneHolder.drone.isConnected == true else { return false }

        return uid == currentDroneHolder.drone.uid
    }

    /// Update the reset status.
    ///
    /// - Parameters:
    ///     - unpairState: tells if drone unpair succeeded
    func updateUnpairStatus(with unpairState: UnpairDroneState) {
        self.unpairState = unpairState
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
