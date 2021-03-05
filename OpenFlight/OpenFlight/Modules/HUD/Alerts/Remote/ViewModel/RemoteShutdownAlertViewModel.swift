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

/// State for `RemoteShutdownAlertState`.
final class RemoteShutdownAlertState: DeviceConnectionState {
    // MARK: - Internal Properties
    /// Duration before mpp shutdown.
    fileprivate(set) var durationBeforeShutDown: TimeInterval = 0.0
    /// Helpes to know if the alert has to be displayed.
    var canShowModal: Bool {
        return durationBeforeShutDown > 0.0 && connectionState == .connected
    }

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: current remote connection state
    ///    - durationBeforeShutDown: duration before remote shutdown
    init(connectionState: DeviceState.ConnectionState, durationBeforeShutDown: TimeInterval) {
        super.init(connectionState: connectionState)

        self.durationBeforeShutDown = durationBeforeShutDown
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? RemoteShutdownAlertState else { return false }

        return super.isEqual(to: other)
            && self.durationBeforeShutDown == other.durationBeforeShutDown
    }

    override func copy() -> RemoteShutdownAlertState {
        let copy = RemoteShutdownAlertState(connectionState: self.connectionState,
                                            durationBeforeShutDown: self.durationBeforeShutDown)
        return copy
    }
}

// MARK: - RemoteShutdownAlertViewModel
/// ViewModel for Remote shutdown alert, notifies on connection state of the remote.
final class RemoteShutdownAlertViewModel: RemoteControlStateViewModel<RemoteShutdownAlertState> {
    // MARK: - Override Funcs
    override func remoteControlStateDidChange(state: DeviceState) {
        super.remoteControlStateDidChange(state: state)

        let copy = self.state.value.copy()
        copy.durationBeforeShutDown = state.durationBeforeShutDown
        self.state.set(copy)
    }
}
