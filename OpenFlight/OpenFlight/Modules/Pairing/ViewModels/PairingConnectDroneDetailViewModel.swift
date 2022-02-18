//    Copyright (C) 2022 Parrot Drones SAS
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
    static let tag = ULogTag(name: "PairingConnectDroneDetailViewModel")
}

/// ViewModel for PairingConnectDrone, notifies on remote/drone changement like list of discovered drones.
final class PairingConnectDroneDetailViewModel {
    // MARK: - Internal Properties
    /// Current pairing connection state.
    @Published private(set) var pairingConnectionState: PairingDroneConnectionState = .disconnected
    /// Remote control connection state.
    @Published private(set) var remoteControlConnectionState: DeviceState.ConnectionState = .disconnected

    // MARK: - Private Properties
    private let groundSdk = GroundSdk()
    private var droneStateRef: Ref<DeviceState>?
    private var remoteControlStateRef: Ref<DeviceState>?
    private var currentRemoteControlHolder: CurrentRemoteControlHolder = Services.hub.currentRemoteControlHolder
    private var cancellables = Set<AnyCancellable>()

    let droneModel: RemoteConnectDroneModel!

    // MARK: - Init
    init(droneModel: RemoteConnectDroneModel) {
        self.droneModel = droneModel

        currentRemoteControlHolder.remoteControlPublisher
            .compactMap { $0 }
            .sink { [unowned self] remoteControl in
                listenRemoteControlConnectionState(remoteControl: remoteControl)
            }
            .store(in: &cancellables)

        listenDroneConnectionState(uid: droneModel.droneUid)
    }

    // MARK: - Internal Funcs
    /// Connect to the drone with password.
    ///
    /// - Parameters:
    ///    - password: Password enter by user
    func connect(password: String?) {
        if let password = password {
            guard WifiPasswordUtil.isValid(password),
                  let droneFinder = currentRemoteControlHolder.remoteControl?.getPeripheral(Peripherals.droneFinder),
                  let drone = droneFinder.discoveredDrones.first(where: { $0.uid == droneModel.droneUid }),
                  droneFinder.connect(discoveredDrone: drone, password: password) == true else {
                      pairingConnectionState = .incorrectPassword
                      return
                  }
            pairingConnectionState = .connecting
        }
        listenDroneConnectionState(uid: droneModel.droneUid)
    }
}

// MARK: - Private Funcs
private extension PairingConnectDroneDetailViewModel {
    /// Starts watcher for remote control connection state.
    ///
    /// - Parameters:
    ///    - remoteControl: the remote control
    func listenRemoteControlConnectionState(remoteControl: RemoteControl) {
        remoteControlStateRef = remoteControl.getState { [unowned self] state in
            remoteControlConnectionState = state?.connectionState ?? .disconnected
        }
    }

    /// Starts watcher for drone connection state.
    ///
    /// - Parameters:
    ///    - uid: the uid of the selected drone
    func listenDroneConnectionState(uid: String) {
        droneStateRef = groundSdk.getDrone(uid: uid)?.getState { [unowned self] state in
            guard let state = state else {
                pairingConnectionState = .disconnected
                return
            }

            switch state.connectionState {
            case .connecting:
                pairingConnectionState = .connecting
            case .connected:
                pairingConnectionState = .connected
            case .disconnected:
                if state.connectionStateCause == DeviceState.ConnectionStateCause.badPassword {
                    pairingConnectionState = .incorrectPassword
                } else {
                    pairingConnectionState = .disconnected
                }
            default:
                break
            }
        }
    }
}
