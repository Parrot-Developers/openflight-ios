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

import GroundSdk

// MARK: - DashboardFooterState
/// State for `DashboardFooterViewModel`.
final class DashboardFooterState: DevicesConnectionState {
    // MARK: - Internal properties
    /// Drone version number.
    fileprivate(set) var droneVersionNumber: String = Style.dash
    /// Remote version number.
    fileprivate(set) var remoteVersionNumber: String = Style.dash

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - droneConnectionState: drone connection state
    ///    - remoteControlConnectionState: remote control connection state
    ///    - droneVersionNumber: current drone version number
    ///    - remoteVersionNumber: current remote version number
    init(droneConnectionState: DeviceConnectionState?,
         remoteControlConnectionState: DeviceConnectionState?,
         droneVersionNumber: String,
         remoteVersionNumber: String) {
        super.init(droneConnectionState: droneConnectionState,
                   remoteControlConnectionState: remoteControlConnectionState)

        self.droneVersionNumber = droneVersionNumber
        self.remoteVersionNumber = remoteVersionNumber
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DevicesConnectionState) -> Bool {
        guard let other = other as? DashboardFooterState else { return false }

        return super.isEqual(to: other)
            && self.droneVersionNumber == other.droneVersionNumber
            && self.remoteVersionNumber == other.remoteVersionNumber
    }

    // MARK: - Copying Protocol
    override func copy() -> DashboardFooterState {
        let copy = DashboardFooterState(droneConnectionState: self.droneConnectionState,
                                             remoteControlConnectionState: self.remoteControlConnectionState,
                                             droneVersionNumber: self.droneVersionNumber,
                                             remoteVersionNumber: self.remoteVersionNumber)
        return copy
    }
}

// MARK: - DashboardFooterViewModel
/// View model for DashboardFooterCell.
final class DashboardFooterViewModel: DevicesStateViewModel<DashboardFooterState> {
    // MARK: - Private Properties
    private var remoteSystemInfoRef: Ref<SystemInfo>?
    private var droneSystemInfoRef: Ref<SystemInfo>?

    // MARK: - Override Funcs
    override func listenRemoteControl(remoteControl: RemoteControl) {
        super.listenRemoteControl(remoteControl: remoteControl)

        listenSystemInfo(remoteControl)
    }

    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenSystemInfo(drone)
    }
}

// MARK: - Private Funcs
private extension DashboardFooterViewModel {
    /// Starts watcher for remote service info.
    func listenSystemInfo(_ remoteControl: RemoteControl) {
        remoteSystemInfoRef = remoteControl.getPeripheral(Peripherals.systemInfo) { [weak self] systemInfo in
            let copy = self?.state.value.copy()
            copy?.remoteVersionNumber = systemInfo?.firmwareVersion ?? Style.dash
            self?.state.set(copy)
        }
    }

    /// Starts watcher for drone service info.
    func listenSystemInfo(_ drone: Drone) {
        droneSystemInfoRef = drone.getPeripheral(Peripherals.systemInfo) { [weak self] systemInfo in
            let copy = self?.state.value.copy()
            copy?.droneVersionNumber = Services.hub.currentDroneHolder.hasLastConnectedDrone
                                        ? systemInfo?.firmwareVersion ?? Style.dash
                                        : Style.dash
            self?.state.set(copy)
        }
    }
}
