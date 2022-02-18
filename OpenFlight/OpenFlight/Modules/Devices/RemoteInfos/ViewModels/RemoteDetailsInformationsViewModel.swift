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

import UIKit
import GroundSdk

/// State for `RemoteDetailsInformationsViewModel`.
final class RemoteDetailsInformationsState: DeviceConnectionState {
    // MARK: - Internal Properties
    fileprivate(set) var serialNumber: String = Style.dash
    fileprivate(set) var hardwareVersion: String = Style.dash
    fileprivate(set) var firmwareVersion: String = Style.dash

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: remote control connection state
    ///    - serialNumber: remote serial number
    ///    - hardwareVersion: hardware version
    ///    - firmwareVersion: firmware version
    init(connectionState: DeviceState.ConnectionState,
         serialNumber: String,
         hardwareVersion: String,
         firmwareVersion: String
    ) {
        super.init(connectionState: connectionState)
        self.serialNumber = serialNumber
        self.hardwareVersion = hardwareVersion
        self.firmwareVersion = firmwareVersion
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? RemoteDetailsInformationsState else { return false }

        return super.isEqual(to: other)
            && self.serialNumber == other.serialNumber
            && self.hardwareVersion == other.hardwareVersion
            && self.firmwareVersion == other.firmwareVersion
    }

    override func copy() -> RemoteDetailsInformationsState {
        let copy = RemoteDetailsInformationsState(connectionState: self.connectionState,
                                                  serialNumber: self.serialNumber,
                                                  hardwareVersion: self.hardwareVersion,
                                                  firmwareVersion: self.firmwareVersion)
        return copy
    }
}

/// View Model for system. It is in charge of filling the remote device system infos.
final class RemoteDetailsInformationsViewModel: RemoteControlStateViewModel<RemoteDetailsInformationsState> {
    // MARK: - Private Properties
    private var systemInfoRef: Ref<SystemInfo>?

    // MARK: - Override Funcs
    override func listenRemoteControl(remoteControl: RemoteControl) {
        super.listenRemoteControl(remoteControl: remoteControl)

        listenRemoteInfos(remoteControl)
    }

    // MARK: - Internal Funcs
    /// Resets the remote to factory state.
    func resetRemote() {
        _ = remoteControl?.getPeripheral(Peripherals.systemInfo)?.factoryReset()
    }
}

// MARK: - Private Funcs
private extension RemoteDetailsInformationsViewModel {
    /// Starts watcher for remote system infos.
    func listenRemoteInfos(_ remoteControl: RemoteControl) {
        systemInfoRef = remoteControl.getPeripheral(Peripherals.systemInfo) { [weak self] _ in
            self?.updateSystemInfos()
        }
        updateSystemInfos()
    }

    /// Updates Remote Control system informations.
    func updateSystemInfos() {
        guard let systemInfo = remoteControl?.getPeripheral(Peripherals.systemInfo) else { return }

        let copy = state.value.copy()
        copy.serialNumber = systemInfo.serial
        copy.hardwareVersion = systemInfo.hardwareVersion
        copy.firmwareVersion = systemInfo.firmwareVersion
        state.set(copy)
    }
}
