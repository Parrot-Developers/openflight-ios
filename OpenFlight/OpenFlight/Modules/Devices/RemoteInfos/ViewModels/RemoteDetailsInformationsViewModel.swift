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
import Combine

/// View Model for system. It is in charge of filling the remote device system infos.
final class RemoteDetailsInformationsViewModel {

    // MARK: - Published Properties
    @Published private(set) var serialNumber: String = Style.dash
    @Published private(set) var hardwareVersion: String = Style.dash
    @Published private(set) var firmwareVersion: String = Style.dash

    // MARK: - Private Properties
    private var systemInfoRef: Ref<SystemInfo>?
    private let connectedRemoteControlHolder: ConnectedRemoteControlHolder
    private let currentRemoteControlHolder: CurrentRemoteControlHolder
    private var cancellables = Set<AnyCancellable>()

    init(connectedRemoteControlHolder: ConnectedRemoteControlHolder, currentRemoteControlHolder: CurrentRemoteControlHolder) {
        self.connectedRemoteControlHolder = connectedRemoteControlHolder
        self.currentRemoteControlHolder = currentRemoteControlHolder

        currentRemoteControlHolder.remoteControlPublisher
            .sink { [weak self] remoteControl in
                guard let self = self else { return }
                self.listenRemoteInfos(remoteControl)
            }
            .store(in: &cancellables)
    }

    // MARK: - Internal Funcs
    /// Resets the remote to factory state.
    func resetRemote() {
        _ = connectedRemoteControlHolder.remoteControl?.getPeripheral(Peripherals.systemInfo)?.factoryReset()
    }

    var resetButtonEnabled: AnyPublisher<Bool, Never> {
        connectedRemoteControlHolder.remoteControlPublisher
            .map { [weak self] remoteControl in
                guard self != nil else { return false }
                guard let remoteControl = remoteControl else { return false }
                return remoteControl.isConnected
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private Funcs
private extension RemoteDetailsInformationsViewModel {
    /// Starts watcher for remote system infos.
    func listenRemoteInfos(_ remoteControl: RemoteControl?) {
        systemInfoRef = remoteControl?.getPeripheral(Peripherals.systemInfo) { [weak self] systemInfo in
            guard let self = self else { return }
            self.updateSystemInfos(systemInfos: systemInfo)
        }
    }

    /// Updates Remote Control system informations.
    func updateSystemInfos(systemInfos: SystemInfo?) {
        guard let systemInfos = systemInfos else { return }
        serialNumber = systemInfos.serial
        hardwareVersion = systemInfos.hardwareVersion
        firmwareVersion = systemInfos.firmwareVersion
    }
}
