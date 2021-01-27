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

import UIKit
import GroundSdk

/// State for `RemoteDetailsListViewModel`.

final class RemoteDetailsListState: DevicesConnectionState {
    // MARK: - Internal Properties
    fileprivate(set) var remoteName: String?
    fileprivate(set) var serialNumber: String?
    fileprivate(set) var hardwareVersion: String?
    fileprivate(set) var softwareVersion: String?
    fileprivate(set) var needUpdate: Bool?

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - remoteControlConnectionState: remote control connection state
    ///    - remoteName: current remote name
    ///    - serialNumber: remote serial number
    ///    - hardwareVersion: hardware version
    ///    - softwareVersion: software version
    ///    - needUpdate: check if remote need an update
    init(droneConnectionState: DeviceConnectionState?,
         remoteControlConnectionState: DeviceConnectionState?,
         remoteName: String?,
         serialNumber: String?,
         hardwareVersion: String?,
         softwareVersion: String?,
         needUpdate: Bool?) {
        super.init(droneConnectionState: droneConnectionState, remoteControlConnectionState: remoteControlConnectionState)
        self.remoteName = remoteName
        self.serialNumber = serialNumber
        self.hardwareVersion = hardwareVersion
        self.softwareVersion = softwareVersion
        self.needUpdate = needUpdate
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DevicesConnectionState) -> Bool {
        guard let other = other as? RemoteDetailsListState else {
            return false
        }
        return super.isEqual(to: other)
            && self.remoteName == other.remoteName
            && self.serialNumber == other.serialNumber
            && self.hardwareVersion == other.hardwareVersion
            && self.softwareVersion == other.softwareVersion
            && self.needUpdate == other.needUpdate
    }

    override func copy() -> RemoteDetailsListState {
        let copy = RemoteDetailsListState(droneConnectionState: self.droneConnectionState,
                                          remoteControlConnectionState: self.remoteControlConnectionState,
                                          remoteName: self.remoteName,
                                          serialNumber: self.serialNumber,
                                          hardwareVersion: self.hardwareVersion,
                                          softwareVersion: self.softwareVersion,
                                          needUpdate: self.needUpdate)
        return copy
    }
}

/// View Model for system. It is in charge of filling the device system infos.

final class RemoteDetailsListViewModel: DevicesStateViewModel<RemoteDetailsListState> {
    // MARK: - Internal Properties
    // List of items which contains several system info for current remote.
    var remoteSystemItems: [DeviceSystemInfoModel] {
        let copy = self.state.value.copy()
        return [DeviceSystemInfoModel(section: SectionSystemInfo.model, value: copy.remoteName),
                DeviceSystemInfoModel(section: SectionSystemInfo.serial, value: copy.serialNumber),
                DeviceSystemInfoModel(section: SectionSystemInfo.hardware, value: copy.hardwareVersion),
                DeviceSystemInfoModel(section: SectionSystemInfo.software, value: copy.softwareVersion)]
    }

    // MARK: - Private Properties
    private var nameRef: Ref<String>?
    private var systemInfoRef: Ref<SystemInfo>?
    private var updaterRef: Ref<Updater>?
    private let groundSdk = GroundSdk()

    // MARK: - Override Funcs
    override func listenRemoteControl(remoteControl: RemoteControl) {
        super.listenRemoteControl(remoteControl: remoteControl)

        listenRemoteInfos(remoteControl)
        listenRemoteUpdate(remoteControl)
        listenRemoteName(remoteControl)
    }
}

// MARK: - Private Funcs
private extension RemoteDetailsListViewModel {
    /// Starts watcher for remote name.
    func listenRemoteName(_ remoteControl: RemoteControl) {
        nameRef = remoteControl.getName(observer: { [weak self] name in
            let copy = self?.state.value.copy()
            copy?.remoteName = name
            self?.state.set(copy)
        })
    }

    /// Starts watcher for remote system infos.
    func listenRemoteInfos(_ remoteControl: RemoteControl) {
        systemInfoRef = remoteControl.getPeripheral(Peripherals.systemInfo) { [weak self] systemInfo in
            let copy = self?.state.value.copy()
            copy?.serialNumber = systemInfo?.serial
            copy?.hardwareVersion = systemInfo?.hardwareVersion
            copy?.softwareVersion = systemInfo?.firmwareVersion
            self?.state.set(copy)
        }
    }

    /// Starts watcher for remote update.
    func listenRemoteUpdate(_ remoteControl: RemoteControl) {
        updaterRef = remoteControl.getPeripheral(Peripherals.updater) { [weak self] updater in
            if let updater = updater, let copy = self?.state.value.copy() {
                copy.needUpdate = !updater.isUpToDate
                self?.state.set(copy)
            }
        }
    }
}
