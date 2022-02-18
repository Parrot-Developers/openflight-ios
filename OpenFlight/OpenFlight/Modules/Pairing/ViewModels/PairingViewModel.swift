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

import Foundation
import GroundSdk

/// View model used to watch drone and remote in order to update pairing welcome screen.

class PairingViewModel: DevicesStateViewModel<DevicesConnectionState> {
    // MARK: - Internal Properties
    // Instantiate a current device style which will update the datasource.
    var currentControllerStyle: Controller = Controller.remoteControl
    var isDroneSwitchedOn: Bool = false
    var isRemoteControlConnected: Bool {
        return state.value.remoteControlConnectionState?.isConnected() == true
    }
    var isDroneConnected: Bool {
        return state.value.droneConnectionState?.isConnected() == true
    }

    // MARK: - Internal Funcs
    /// Update the controller style.
    ///
    /// - Parameters:
    ///    - controllerStyle: style of the controller, it can be a remote or a phone
    func setControllerStyle(controllerStyle: Controller) {
        currentControllerStyle = controllerStyle
    }
}

// MARK: - Internal Properties
extension PairingViewModel {
    /// Returns pairing list.
    var pairingList: [PairingModel] {
        // Default values for state.
        var pairingRemoteState: PairingState = PairingState.todo
        var pairingDroneWithRemoteState: PairingState = PairingState.todo
        var pairingWifiState: PairingState = PairingState.todo
        var pairingDroneWithoutRemoteState: PairingState = PairingState.todo

        if currentControllerStyle == .remoteControl {
            pairingRemoteState = .doing
            if !isRemoteControlConnected && !isDroneConnected {
                pairingDroneWithRemoteState = .todo
            } else if isRemoteControlConnected && !isDroneConnected {
                pairingRemoteState = .done
                pairingDroneWithRemoteState = .doing
            } else if isRemoteControlConnected && isDroneConnected {
                pairingRemoteState = .done
                pairingDroneWithRemoteState = .done
            }
            return [RemotePairingModel(state: pairingRemoteState),
                    DroneWithRemotePairingModel(state: pairingDroneWithRemoteState)]
        } else {
            if isDroneConnected {
                pairingDroneWithoutRemoteState = .done
                pairingWifiState = .done
            } else if !isDroneSwitchedOn {
                pairingDroneWithoutRemoteState = .doing
                pairingWifiState = .todo
            } else {
                pairingDroneWithoutRemoteState = .done
                pairingWifiState = .doing
            }
            return [DroneWithoutRemotePairingModel(state: pairingDroneWithoutRemoteState),
                    WifiPairingModel(state: pairingWifiState)]
        }
    }
}
