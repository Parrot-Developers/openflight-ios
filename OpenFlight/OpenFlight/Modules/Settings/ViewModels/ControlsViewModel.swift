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

/// State for `ControlsViewModel`.
final class ControlsState: DevicesConnectionState {
    // MARK: - Internal Properties
    var isVirtualJogsAvailable: Bool = false
    var isLanded: Bool?
    var isTakingOff: Bool?
    var isLanding: Bool?
    var isReturningHome: Bool?
    var isEvTriggerActivated: Bool? = Defaults.evTriggerSetting
    var controlMode: ControlsSettingsMode = ControlsSettingsMode.defaultMode

    // MARK: - Override Funcs
    override func copy() -> ControlsState {
        let copy = ControlsState(droneConnectionState: droneConnectionState,
                                 remoteControlConnectionState: remoteControlConnectionState)
        copy.isVirtualJogsAvailable = isVirtualJogsAvailable
        copy.isLanded = isLanded
        copy.isTakingOff = isTakingOff
        copy.isLanding = isLanding
        copy.isReturningHome = isReturningHome
        copy.controlMode = controlMode
        copy.isEvTriggerActivated = isEvTriggerActivated

        return copy
    }

    override func isEqual(to other: DevicesConnectionState) -> Bool {
        guard let other = other as? ControlsState else { return false }

        return super.isEqual(to: other)
            && isVirtualJogsAvailable == other.isVirtualJogsAvailable
            && isLanded == other.isLanded
            && isTakingOff == other.isTakingOff
            && isLanding == other.isLanding
            && isReturningHome == other.isReturningHome
            && controlMode == other.controlMode
            && isEvTriggerActivated == other.isEvTriggerActivated
    }
}

/// Controls settings view model.
final class ControlsViewModel: DevicesStateViewModel<ControlsState> {
    // MARK: - Private Properties
    private var gimbalRef: Ref<Gimbal>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var pilotingControlRef: Ref<PilotingControl>?
    private var manualPilotingRef: Ref<ManualCopterPilotingItf>?

    // MARK: - Internal Properties
    var settingEntries: [SettingEntry] {
        return [SettingEntry(setting: SettingsCellType.controlMode)]
    }
    var currentControlMode: ControlsSettingsMode {
        var mode: ControlsSettingsMode = ControlsSettingsMode.defaultMode
        if let rawUserMode = Defaults.userControlModeSetting,
           let userMode = ControlsSettingsMode(value: rawUserMode) {
            mode = userMode
        }

        return mode
    }

    // MARK: - Init
    override init() {
        super.init()

        // Init content regarding data.
        if !Defaults.hasKey(\.userControlModeSetting) {
            resetSettings()
        }
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)
        /// Listen Piloting Control.
        pilotingControlRef = drone.getPeripheral(Peripherals.pilotingControl, observer: { [unowned self] control in
            if control?.behaviourSetting.value == .cameraOperated {
                resetBehaviourSettings()
            }
            // Update remote control mapping to apply changes.
            updateRemoteMapping(withMode: currentControlMode)
        })
        /// Listen Manual Piloting Interface.
        manualPilotingRef = drone.getPilotingItf(PilotingItfs.manualCopter) { [unowned self] _ in
            updateState()
        }
        /// Listen gimbal.
        gimbalRef = drone.getPeripheral(Peripherals.gimbal) { [unowned self] _ in
            updateState()
        }
        /// Listen flying indicators.
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [unowned self] _ in
            updateState()
        }
    }

    override func listenRemoteControl(remoteControl: RemoteControl) {
        super.listenRemoteControl(remoteControl: remoteControl)

        updateState()
    }

    // MARK: - Internal Funcs
    /// Reset settings to default values.
    func resetSettings() {
        Defaults.evTriggerSetting = false
        updateRemoteMapping(withMode: ControlsSettingsMode.defaultMode)
        drone?.getPilotingItf(PilotingItfs.manualCopter)?.thrownTakeOffSettings?.value = PilotingPreset.thrownTakeOff
    }

    /// Update remote mapping regarding controls settings mode.
    /// This has direct effect on remote control mapping.
    ///
    /// - Parameters:
    ///     - controlMode: controls settings mode
    func updateRemoteMapping(withMode controlMode: ControlsSettingsMode) {
        let copy = state.value.copy()
        copy.controlMode = controlMode
        copy.isEvTriggerActivated = Defaults.evTriggerSetting
        state.set(copy)

        Defaults.userControlModeSetting = controlMode.value
        Services.hub.remoteControlUpdater.updateRemoteMapping()
    }
}

// MARK: - Private Funcs
private extension ControlsViewModel {
    /// Update state for drone and remote states.
    func updateState() {
        let copy = state.value.copy()
        copy.isLanding = drone?.isLanding
        copy.isLanded = drone?.isStateLanded
        copy.isTakingOff = drone?.isTakingOff
        copy.isReturningHome = drone?.isReturningHome
        copy.isVirtualJogsAvailable = copy.droneConnectionState?.isConnected() ?? false
            && !(copy.remoteControlConnectionState?.isConnected() ?? false)
        state.set(copy)
    }

    /// Resets behaviour settings.
    func resetBehaviourSettings() {
        drone?.getPeripheral(Peripherals.pilotingControl)?.behaviourSetting.value = .standard
    }
}
