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

/// State for `ControlsViewModel`.
final class ControlsState: Equatable {
    // MARK: - Internal Properties
    var isVirtualJogsAvailable: Bool = false
    var isLanded: Bool?
    var isTakingOff: Bool?
    var isLanding: Bool?
    var isReturningHome: Bool?
    var isEvTriggerActivated: Bool? = Defaults.evTriggerSetting
    var controlMode: ControlsSettingsMode = ControlsSettingsMode(value: Defaults.userControlModeSetting) ?? ControlsSettingsMode.defaultMode

    static func == (lhs: ControlsState, rhs: ControlsState) -> Bool {
        lhs.isVirtualJogsAvailable == rhs.isVirtualJogsAvailable
            && lhs.isLanded == rhs.isLanded
            && lhs.isTakingOff == rhs.isTakingOff
            && lhs.isLanding == rhs.isLanding
            && lhs.isReturningHome == rhs.isReturningHome
            && lhs.isEvTriggerActivated == rhs.isEvTriggerActivated
            && lhs.controlMode == rhs.controlMode
    }
}

/// Controls settings view model.
final class ControlsViewModel {
    // MARK: - Published Properties
    @Published private(set) var state = ControlsState()

    // MARK: - Private Properties
    private var gimbalRef: Ref<Gimbal>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var manualPilotingRef: Ref<ManualCopterPilotingItf>?
    private var cancellables = Set<AnyCancellable>()
    private let currentDroneHolder: CurrentDroneHolder!
    private let currentRemoteControlHolder: CurrentRemoteControlHolder!
    private let remoteControlUpdater: RemoteControlUpdater!

    // MARK: - Internal Properties
    var settingEntries: [SettingEntry] {
        return [SettingEntry(setting: SettingsCellType.controlMode)]
    }

    // MARK: - Init
    init(currentDroneHolder: CurrentDroneHolder,
         currentRemoteControlHolder: CurrentRemoteControlHolder,
         remoteControlUpdater: RemoteControlUpdater) {
        self.currentDroneHolder = currentDroneHolder
        self.currentRemoteControlHolder = currentRemoteControlHolder
        self.remoteControlUpdater = remoteControlUpdater

        currentDroneHolder.dronePublisher
            .sink { [unowned self] in
                listenPilotingItf(drone: $0)
                listenGimbal(drone: $0)
                listenFlyingIndicators(drone: $0)
            }
            .store(in: &cancellables)

        currentRemoteControlHolder.remoteControlPublisher
            .sink { [unowned self] _ in
                updateState()
            }
            .store(in: &cancellables)
    }

    /// Update remote mapping regarding controls settings mode.
    /// This has direct effect on remote control mapping.
    ///
    /// - Parameters:
    ///     - controlMode: controls settings mode
    func updateRemoteMapping(withMode controlMode: ControlsSettingsMode) {
        let state = self.state
        state.controlMode = controlMode
        state.isEvTriggerActivated = Defaults.evTriggerSetting
        self.state = state

        remoteControlUpdater.setControlMode(controlMode)
    }
}

// MARK: - Private Funcs
private extension ControlsViewModel {
    /// Starts watcher for the piloting interface.
    ///
    /// - Parameters:
    ///   - drone: the current drone
    func listenPilotingItf(drone: Drone) {
        manualPilotingRef = drone.getPilotingItf(PilotingItfs.manualCopter) { [unowned self] _ in
            updateState()
        }
    }

    /// Starts watcher for the gimbal.
    ///
    /// - Parameters:
    ///   - drone: the current drone
    func listenGimbal(drone: Drone) {
        gimbalRef = drone.getPeripheral(Peripherals.gimbal) { [unowned self] _ in
            updateState()
        }
    }

    /// Starts watcher for the flying indicators.
    ///
    /// - Parameters:
    ///   - drone: the current drone
    func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [unowned self] _ in
            updateState()
        }
    }

    /// Update state for drone and remote states.
    func updateState() {
        let drone = currentDroneHolder.drone
        let remoteControl = currentRemoteControlHolder.remoteControl
        let state = self.state
        state.isLanding = drone.isLanding
        state.isLanded = drone.isStateLanded
        state.isTakingOff = drone.isTakingOff
        state.isReturningHome = drone.isReturningHome
        state.isVirtualJogsAvailable = drone.isConnected && remoteControl?.isConnected != true
        self.state = state
    }
}
