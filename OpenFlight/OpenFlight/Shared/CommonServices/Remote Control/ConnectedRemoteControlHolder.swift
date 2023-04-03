//    Copyright (C) 2021 Parrot Drones SAS
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
import Combine

/// Protocol for the service responsible of holding the connected remote control if any
public protocol ConnectedRemoteControlHolder: AnyObject {
    /// Last seen remote control
    var remoteControl: RemoteControl? { get }
    /// Publisher for currently connected remote control
    var remoteControlPublisher: AnyPublisher<RemoteControl?, Never> { get }
}

class ConnectedRemoteControlHolderImpl: ConnectedRemoteControlHolder {

    private var groundSdk = GroundSdk()
    private var autoConnectionRef: Ref<AutoConnectionDesc.ApiProtocol>?
    private var remoteControlStateRef: Ref<DeviceState>?

    @Published private(set) var remoteControl: RemoteControl?

    var remoteControlPublisher: AnyPublisher<RemoteControl?, Never> { $remoteControl.eraseToAnyPublisher() }

    init() {
        setupListening(groundSdk: groundSdk)
    }

    private func setupListening(groundSdk: GroundSdk) {
        autoConnectionRef = groundSdk.getFacility(Facilities.autoConnection) { [unowned self] autoConnection in
            // If there's no autoconnection facility or the autoconnection is stopped, we consider there's no remote control
            guard let autoConnection = autoConnection, autoConnection.state != .stopped else {
                setRemoteControl(nil)
                return
            }
            // The autoconnection is started, if it carries a remote control listen to its state
            if let remoteControl = autoConnection.remoteControl {
                listenRemoteControlState(remoteControl)
            }
        }
    }

    /// Listen to remote control's state to catch when it becomes connected
    /// - Parameter remoteControl: the remote control
    private func listenRemoteControlState(_ remoteControl: RemoteControl) {
        remoteControlStateRef = remoteControl.getState { [unowned self] remoteControlState in
            // If the remote control is not connected we don't consider it
            guard let remoteControlState = remoteControlState,
                  remoteControlState.connectionState == .connected else {
                setRemoteControl(nil)
                return
            }
            // Connected remote control case, ensure it's properly set
            setRemoteControl(remoteControl)
        }
    }

    private func setRemoteControl(_ remoteControl: RemoteControl?) {
        // Only trigger anything when there's an effective change
        guard remoteControl?.uid != self.remoteControl?.uid else { return }
        self.remoteControl = remoteControl
    }
}
