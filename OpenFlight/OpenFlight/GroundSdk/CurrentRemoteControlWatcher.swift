// Copyright (C) 2020 Parrot Drones SAS
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

/// Class notifying when current remote control changes.

final class CurrentRemoteControlWatcher {

    // MARK: - Private Properties
    private let groundSdk = GroundSdk()
    private var autoConnectionRef: Ref<AutoConnection>?
    private var currentRemoteControlDidChangeCb: ((_ remoteControl: RemoteControl) -> Void)?
    /// Current or last connected remote control.
    private(set) var remoteControl: RemoteControl?

    // MARK: - Internal Funcs
    /// Starts watching for remote control change.
    ///
    /// - Parameters:
    ///    - callback: callback called when the current remote control changes
    ///    - remoteControl: current remote control
    /// - Note: callback is immediately called when registered.
    func start(callback: @escaping (_ remoteControl: RemoteControl) -> Void) {
        currentRemoteControlDidChangeCb = callback
        // Initial notification with stored rc.
        if let remoteControl = groundSdk.getRemoteControl(uid: CurrentRemoteControlStore.currentRcUid) {
            currentRemoteControlDidChange(remoteControl)
        }
        // Listen to autoconnection facility.
        autoConnectionRef = groundSdk.getFacility(Facilities.autoConnection) { [weak self] autoConnection in
            if let remoteControl = autoConnection?.remoteControl {
                self?.currentRemoteControlDidChange(remoteControl)
            }
        }
    }
}

// MARK: - Private Funcs
private extension CurrentRemoteControlWatcher {
    /// Called when current remote control changes (either
    /// AutoConnection update, or initial notification).
    ///
    /// - Parameters:
    ///    - drone: the new drone
    func currentRemoteControlDidChange(_ newRc: RemoteControl) {
        guard newRc.uid != remoteControl?.uid else {
            return
        }
        remoteControl = newRc
        currentRemoteControlDidChangeCb?(newRc)
    }
}
