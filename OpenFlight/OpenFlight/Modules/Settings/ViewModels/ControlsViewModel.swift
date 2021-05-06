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
import SwiftyUserDefaults

/// State for `ControlsViewModel`.
final class ControlsState: DevicesConnectionState {
    // MARK: - Internal Properties
    var currentPilotingStyle: PilotingStyle = ControlsSettingsMode.defaultPilotingMode
    var isArcadeModeAvailable: Bool = false
    var isVirtualJogsAvailable: Bool = false
    var isLanded: Bool?
    var isTakingOff: Bool?
    var isLanding: Bool?
    var isReturningHome: Bool?
    var isArcadeTiltReversed: Bool? = Defaults.arcadeTiltReversedSetting
    var isEvTriggerActivated: Bool? = Defaults.evTriggerSetting
    var controlMode: ControlsSettingsMode = ControlsSettingsMode.defaultMode
    /// Compute remote control and drone states to allows or not arcade mode.
    var arcadeUnavailabilityIssues: [ArcadeUnavailabilityIssues] {
        var issues = [ArcadeUnavailabilityIssues]()
        if remoteControlConnectionState?.isConnected() != true {
            issues.append(.remoteDisconnected)
        }
        if droneConnectionState?.isConnected() != true {
            issues.append(.droneDisconnected)
        }
        if isLanded == true {
            issues.append(.droneLanded)
        }
        if isTakingOff == true {
            issues.append(.droneTakingOff)
        }
        if isLanding == true {
            issues.append(.droneLanding)
        }
        if isReturningHome == true {
            issues.append(.rthInProgress)
        }

        return issues
    }

    // MARK: - Override Funcs
    override func copy() -> ControlsState {
        let copy = ControlsState(droneConnectionState: self.droneConnectionState,
                                 remoteControlConnectionState: self.remoteControlConnectionState)
        copy.currentPilotingStyle = self.currentPilotingStyle
        copy.isArcadeModeAvailable = self.isArcadeModeAvailable
        copy.isVirtualJogsAvailable = self.isVirtualJogsAvailable
        copy.isLanded = self.isLanded
        copy.isTakingOff = self.isTakingOff
        copy.isLanding = self.isLanding
        copy.isReturningHome = self.isReturningHome
        copy.controlMode = self.controlMode
        copy.isArcadeTiltReversed = self.isArcadeTiltReversed
        copy.isEvTriggerActivated = self.isEvTriggerActivated

        return copy
    }

    override func isEqual(to other: DevicesConnectionState) -> Bool {
        guard let other = other as? ControlsState else { return false }

        return super.isEqual(to: other)
            && self.currentPilotingStyle == other.currentPilotingStyle
            && self.isArcadeModeAvailable == other.isArcadeModeAvailable
            && self.isVirtualJogsAvailable == other.isVirtualJogsAvailable
            && self.isLanded == other.isLanded
            && self.isTakingOff == other.isTakingOff
            && self.isLanding == other.isLanding
            && self.isReturningHome == other.isReturningHome
            && self.controlMode == other.controlMode
            && self.isArcadeTiltReversed == other.isArcadeTiltReversed
            && self.isEvTriggerActivated == other.isEvTriggerActivated
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
    /// Return text to understand why arcade mode is not available.
    var arcadeUnavailabilityHelp: String? {
        let arcadeUnavailabilityIssues = state.value.arcadeUnavailabilityIssues
        /// Rules are defined here is a text is required
        if arcadeUnavailabilityIssues.contains(.remoteDisconnected) {
            return ArcadeUnavailabilityIssues.remoteDisconnected.unavailabilityHelpText
        }
        if !arcadeUnavailabilityIssues.contains(.remoteDisconnected)
            && !arcadeUnavailabilityIssues.contains(.droneDisconnected)
            && (arcadeUnavailabilityIssues.contains(.droneLanded)
                    || arcadeUnavailabilityIssues.contains(.droneLanding)
                    || arcadeUnavailabilityIssues.contains(.rthInProgress)) {
            return ArcadeUnavailabilityIssues.droneLanded.unavailabilityHelpText
        }
        return nil
    }
    var settingEntries: [SettingEntry] {
        return [SettingEntry(setting: SettingsCellType.controlMode)]
    }
    var currentControlMode: ControlsSettingsMode {
        let pilotingStyle = self.state.value.currentPilotingStyle
        var mode: ControlsSettingsMode = PilotingPreset.controlMode
        var rawUserMode: String?
        switch pilotingStyle {
        case .arcade:
            rawUserMode = Defaults.userControlModeArcadeSetting
        case .classical:
            rawUserMode = Defaults.userControlModeSetting
        }

        if let rawUserMode = rawUserMode,
           let userMode = ControlsSettingsMode(value: rawUserMode, mode: pilotingStyle) {
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

        if !Defaults.hasKey(\.userControlModeArcadeSetting) {
            Defaults.userControlModeArcadeSetting = PilotingPreset.controlMode.value
        }
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)
        /// Listen Piloting Control.
        pilotingControlRef = drone.getPeripheral(Peripherals.pilotingControl, observer: { [weak self] control in
            let pilotingStyle: PilotingStyle = control?.behaviourSetting.value == .cameraOperated
                ? .arcade
                : .classical
            // Update piloting style state.
            self?.updateControlState(style: pilotingStyle)
            // Update remote control mapping to apply changes.
            self?.updateRemoteMapping(withMode: self?.currentControlMode ?? PilotingPreset.controlMode)
        })
        /// Listen Manual Piloting Interface.
        manualPilotingRef = drone.getPilotingItf(PilotingItfs.manualCopter) { [weak self] _ in
            self?.updateState()
        }
        /// Listen gimbal.
        gimbalRef = drone.getPeripheral(Peripherals.gimbal) { [weak self] _ in
            self?.updateState()
        }
        /// Listen flying indicators.
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] _ in
            self?.updateState()
        }
    }

    override func listenRemoteControl(remoteControl: RemoteControl) {
        super.listenRemoteControl(remoteControl: remoteControl)

        self.updateState()
    }

    // MARK: - Internal Funcs
    /// Reset settings to default values.
    func resetSettings() {
        Defaults.arcadeTiltReversedSetting = false
        Defaults.evTriggerSetting = false
        updateRemoteMapping(withMode: ControlsSettingsMode.defaultMode(for: self.state.value.currentPilotingStyle))
        drone?.getPilotingItf(PilotingItfs.manualCopter)?.thrownTakeOffSettings?.value = PilotingPreset.thrownTakeOff
    }

    /// Manage piloting control change.
    ///
    /// - Parameters:
    ///     - style: current piloting style
    func switchToPilotingStyle(_ style: PilotingStyle) {
        guard state.value.currentPilotingStyle != style else { return }

        guard let pilotingControl = drone?.getPeripheral(Peripherals.pilotingControl) else {
            self.resetControlState()
            return
        }

        switch style {
        case .classical:
            pilotingControl.behaviourSetting.value = .standard
        case .arcade:
            pilotingControl.behaviourSetting.value = .cameraOperated
        }
    }

    // swiftlint:disable function_body_length
    /// Update remote mapping regarding controls settings mode.
    /// This has direct effect on remote control mapping.
    ///
    /// - Parameters:
    ///     - controlMode: controls settings mode
    func updateRemoteMapping(withMode controlMode: ControlsSettingsMode) {
        let copy = self.state.value.copy()
        copy.controlMode = controlMode
        copy.isArcadeTiltReversed = Defaults.arcadeTiltReversedSetting
        copy.isEvTriggerActivated = Defaults.evTriggerSetting
        self.state.set(copy)

        let pilotingStyle = controlMode.pilotingStyle
        switch pilotingStyle {
        case .arcade:
            Defaults.userControlModeArcadeSetting = controlMode.value
        case .classical:
            Defaults.userControlModeSetting = controlMode.value
        }

        guard let remote = remoteControl,
              let skyCtrl4 = remote.getPeripheral(Peripherals.skyCtrl4Gamepad),
              let droneModel = drone?.model else {
            return
        }

        let tiltReversedSetting = Defaults.arcadeTiltReversedSetting
        skyCtrl4.volatileMappingSetting?.value = pilotingStyle == .arcade

        switch (controlMode, pilotingStyle) {
        case (.mode1, .classical):
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlPitch,
                                                                     axisEvent: .leftStickVertical, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlYawRotationSpeed,
                                                                     axisEvent: .leftStickHorizontal, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlThrottle,
                                                                     axisEvent: .rightStickVertical, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlRoll,
                                                                     axisEvent: .rightStickHorizontal, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .tiltCamera,
                                                                     axisEvent: .leftSlider, buttonEvents: []))
            reverseAxes([.leftSlider])
        case (.mode1, .arcade):
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlPitch,
                                                                     axisEvent: .leftStickVertical, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlYawRotationSpeed,
                                                                     axisEvent: .leftStickHorizontal, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .tiltCamera,
                                                                     axisEvent: .rightStickVertical, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlRoll,
                                                                     axisEvent: .rightStickHorizontal, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlThrottle,
                                                                     axisEvent: .leftSlider, buttonEvents: []))
            let axes: Set<SkyCtrl4Axis> = tiltReversedSetting ? [] : [.rightStickVertical]
            reverseAxes(axes)
        case (.mode2, .classical):
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlThrottle,
                                                                     axisEvent: .leftStickVertical, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlYawRotationSpeed,
                                                                     axisEvent: .leftStickHorizontal, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlPitch,
                                                                     axisEvent: .rightStickVertical, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlRoll,
                                                                     axisEvent: .rightStickHorizontal, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .tiltCamera,
                                                                     axisEvent: .leftSlider, buttonEvents: []))
            reverseAxes([.leftSlider])
        case (.mode2, .arcade):
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .tiltCamera,
                                                                     axisEvent: .leftStickVertical, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlYawRotationSpeed,
                                                                     axisEvent: .leftStickHorizontal, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlPitch,
                                                                     axisEvent: .rightStickVertical, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlRoll,
                                                                     axisEvent: .rightStickHorizontal, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlThrottle,
                                                                     axisEvent: .leftSlider, buttonEvents: []))
            let axes: Set<SkyCtrl4Axis> = tiltReversedSetting ? [] : [.leftStickVertical]
            reverseAxes(axes)
        case (.mode3, .classical):
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlPitch,
                                                                     axisEvent: .leftStickVertical, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlRoll,
                                                                     axisEvent: .leftStickHorizontal, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlThrottle,
                                                                     axisEvent: .rightStickVertical, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlYawRotationSpeed,
                                                                     axisEvent: .rightStickHorizontal, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .tiltCamera,
                                                                     axisEvent: .leftSlider, buttonEvents: []))
            reverseAxes([.leftSlider])
        case (.mode3, .arcade):
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlPitch,
                                                                     axisEvent: .leftStickVertical, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlRoll,
                                                                     axisEvent: .leftStickHorizontal, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .tiltCamera,
                                                                     axisEvent: .rightStickVertical, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlYawRotationSpeed,
                                                                     axisEvent: .rightStickHorizontal, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlThrottle,
                                                                     axisEvent: .leftSlider, buttonEvents: []))
            let axes: Set<SkyCtrl4Axis> = tiltReversedSetting ? [] : [.rightStickVertical]
            reverseAxes(axes)
        case (.mode4, .classical):
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlThrottle,
                                                                     axisEvent: .leftStickVertical, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlRoll,
                                                                     axisEvent: .leftStickHorizontal, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlPitch,
                                                                     axisEvent: .rightStickVertical, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlYawRotationSpeed,
                                                                     axisEvent: .rightStickHorizontal, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .tiltCamera,
                                                                     axisEvent: .leftSlider, buttonEvents: []))
            reverseAxes([.leftSlider])
        case (.mode4, .arcade):
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .tiltCamera,
                                                                     axisEvent: .leftStickVertical, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlRoll,
                                                                     axisEvent: .leftStickHorizontal, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlPitch,
                                                                     axisEvent: .rightStickVertical, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlYawRotationSpeed,
                                                                     axisEvent: .rightStickHorizontal, buttonEvents: []))
            skyCtrl4.register(mappingEntry: SkyCtrl4AxisMappingEntry(droneModel: droneModel, action: .controlThrottle,
                                                                     axisEvent: .leftSlider, buttonEvents: []))
            let axes: Set<SkyCtrl4Axis> = tiltReversedSetting ? [] : [.leftStickVertical]
            reverseAxes(axes)
        }
    }
    // swiftlint:enable function_body_length
}

// MARK: - Private Funcs
private extension ControlsViewModel {
    /// Dedicated helper to handle inverted axes.
    ///
    /// - Parameters:
    ///     - axes: set of Sky controller axis
    func reverseAxes(_ axes: Set<SkyCtrl4Axis>) {
        guard let remote = remoteControl,
              let skyCtrl4 = remote.getPeripheral(Peripherals.skyCtrl4Gamepad),
              let droneModel = drone?.model else {
            return
        }

        SkyCtrl4Axis.allCases.forEach { axe in
            if (skyCtrl4.reversedAxes(forDroneModel: droneModel)?.contains(axe) == false && axes.contains(axe))
                || (skyCtrl4.reversedAxes(forDroneModel: droneModel)?.contains(axe) == true && !axes.contains(axe)) {
                skyCtrl4.reverse(axis: axe, forDroneModel: droneModel)
            }
        }
    }

    /// Update state dedicated to current control mode.
    ///
    /// - Parameters:
    ///     - style: current piloting style
    func updateControlState(style: PilotingStyle) {
        let copy = self.state.value.copy()
        copy.currentPilotingStyle = style
        self.state.set(copy)
    }

    /// Update state for drone and remote states.
    func updateState() {
        let copy = self.state.value.copy()
        copy.isLanding = drone?.isLanding
        copy.isLanded = drone?.isStateLanded
        copy.isTakingOff = drone?.isTakingOff
        copy.isReturningHome = drone?.isReturningHome
        copy.isArcadeModeAvailable = copy.arcadeUnavailabilityIssues.isEmpty
        copy.isVirtualJogsAvailable = copy.droneConnectionState?.isConnected() ?? false
            && !(copy.remoteControlConnectionState?.isConnected() ?? false)
        self.state.set(copy)
    }

    /// Reset control state provide fake state change to for refresh display.
    func resetControlState() {
        let copy = self.state.value.copy()
        copy.currentPilotingStyle = .arcade
        self.state.set(copy)
        copy.currentPilotingStyle = .classical
        self.state.set(copy)
    }
}
