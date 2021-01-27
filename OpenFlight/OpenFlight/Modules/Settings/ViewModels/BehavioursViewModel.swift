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

/// Behaviours settings view model.

final class BehavioursViewModel: DroneWatcherViewModel<DeviceConnectionState>, SettingsViewModelProtocol {
    // MARK: - Internal Properties
    var infoHandler: ((_ modeType: SettingMode.Type) -> Void)?

    var isUpdating: Bool? {
        return false
    }

    // MARK: - Private Properties
    private var manualPilotingRef: Ref<ManualCopterPilotingItf>?
    private var gimbalRef: Ref<Gimbal>?
    private var trackerRef: Ref<TargetTracker>?
    private var manualPiloting: ManualCopterPilotingItf? {
        return drone?.getPilotingItf(PilotingItfs.manualCopter)
    }
    private var gimbal: Gimbal? {
        return drone?.getPeripheral(Peripherals.gimbal)
    }

    // MARK: - Init
    override init(stateDidUpdate: ((DeviceConnectionState) -> Void)? = nil) {
        super.init(stateDidUpdate: stateDidUpdate)

        // Init content regarding data.
        if Defaults.userPilotingPreset == nil {
            resetSettings()
            Defaults.userPilotingPreset = SettingsBehavioursMode.preset.key
        }
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        /// listen Manual Piloting Interface
        manualPilotingRef = drone.getPilotingItf(PilotingItfs.manualCopter) { [weak self] _ in
            self?.notifyChange()
        }
        /// listen gimbal
        gimbalRef = drone.getPeripheral(Peripherals.gimbal) { [weak self] _ in
            self?.notifyChange()
        }
        /// listen target tracker
        trackerRef = drone.getPeripheral(Peripherals.targetTracker) { [weak self] _ in
            self?.notifyChange()
        }
    }

    // MARK: - Internal Funcs
    /// Reset settings in User Defaults.
    func resetSettings() {
        Defaults[key: SettingsBehavioursMode.current.maxPitchRollKey] = SettingsBehavioursMode.current.defaultValues.horizontalSpeed
        let horizontalAcceleration = SettingsBehavioursMode.current.defaultValues.horizontalAcceleration
        if let maxPitchRollVelocityPresetValue = manualPiloting?.maxPitchRollVelocityValueForPercent(horizontalAcceleration) {
            Defaults[key: SettingsBehavioursMode.current.maxPitchRollVelocityKey] = maxPitchRollVelocityPresetValue
        }
        Defaults[key: SettingsBehavioursMode.current.maxVerticalSpeedKey] = SettingsBehavioursMode.current.defaultValues.verticalSpeed
        Defaults[key: SettingsBehavioursMode.current.maxYawRotationSpeedKey] = SettingsBehavioursMode.current.defaultValues.rotationSpeed
        Defaults[key: SettingsBehavioursMode.current.bankedTurnModeKey] = SettingsBehavioursMode.current.defaultValues.bankedTurn
        Defaults[key: SettingsBehavioursMode.current.inclinedRollModeKey] = SettingsBehavioursMode.current.defaultValues.inclinedRoll
        Defaults[key: SettingsBehavioursMode.current.cameraTiltKey] = SettingsBehavioursMode.current.defaultValues.cameraTilt

        applyBehavioursSettings(mode: SettingsBehavioursMode.current)

        notifyChange()
    }

    /// Save drone settings in User Defaults.
    func saveSettings() {
        Defaults[key: SettingsBehavioursMode.current.maxPitchRollKey] = manualPiloting?.maxPitchRoll.value
        Defaults[key: SettingsBehavioursMode.current.maxPitchRollVelocityKey] = manualPiloting?.maxPitchRollVelocity?.value
        Defaults[key: SettingsBehavioursMode.current.maxVerticalSpeedKey] = manualPiloting?.maxVerticalSpeed.value
        Defaults[key: SettingsBehavioursMode.current.maxYawRotationSpeedKey] = manualPiloting?.maxYawRotationSpeed.value
        Defaults[key: SettingsBehavioursMode.current.bankedTurnModeKey] = manualPiloting?.bankedTurnMode?.value
        Defaults[key: SettingsBehavioursMode.current.inclinedRollModeKey] = !(gimbal?.stabilizationSettings[.roll]?.value ?? true)
        Defaults[key: SettingsBehavioursMode.current.cameraTiltKey] = gimbal?.maxSpeedSettings[.pitch]?.value
    }

    /// Switch behaviours mode.
    func switchBehavioursMode(mode: SettingsBehavioursMode) {
        Defaults.userPilotingPreset = mode.rawValue
        applyBehavioursSettings(mode: mode)
    }

    /// Apply behaviours settings regarding behaviour mode.
    func applyBehavioursSettings(mode: SettingsBehavioursMode) {
        manualPiloting?.maxPitchRoll.value = Defaults[key: mode.maxPitchRollKey] ?? mode.defaultValues.horizontalSpeed
        if let maxPitchRollVelocitySavedValue = Defaults[key: mode.maxPitchRollVelocityKey] {
            manualPiloting?.maxPitchRollVelocity?.value = maxPitchRollVelocitySavedValue
        } else if let maxPitchRollVelocityPresetValue = manualPiloting?.maxPitchRollVelocityValueForPercent(mode.defaultValues.horizontalAcceleration) {
            manualPiloting?.maxPitchRollVelocity?.value = maxPitchRollVelocityPresetValue
        }
        manualPiloting?.maxVerticalSpeed.value = Defaults[key: mode.maxVerticalSpeedKey] ?? mode.defaultValues.verticalSpeed
        manualPiloting?.maxYawRotationSpeed.value = Defaults[key: mode.maxYawRotationSpeedKey] ?? mode.defaultValues.rotationSpeed

        manualPiloting?.bankedTurnMode?.value = Defaults[key: mode.bankedTurnModeKey] ?? mode.defaultValues.bankedTurn
        gimbal?.stabilizationSettings[.roll]?.value = !(Defaults[key: mode.inclinedRollModeKey] ?? mode.defaultValues.inclinedRoll)

        gimbal?.maxSpeedSettings[.pitch]?.value = Defaults[key: mode.cameraTiltKey] ?? mode.defaultValues.cameraTilt
        // If camera exposure mode is currently set to automatic, it should be refreshed to recommended mode.
        if let camera = drone?.currentCamera,
           let automaticMode = camera.config[Camera2Params.exposureMode]?.value.refreshAutomaticModeIfNeeded() {
            let currentEditor = camera.currentEditor
            currentEditor[Camera2Params.exposureMode]?.value = automaticMode
            currentEditor.saveSettings()
        }
    }

    /// Returns behaviours settings entries.
    var settingEntries: [SettingEntry] {
        let overlimitPreset = SettingsBehavioursMode.current.maxRecommandedValues
        var overlimitMaxPitchRollVelocity: Double?
        if let percent = overlimitPreset?.horizontalAcceleration {
            overlimitMaxPitchRollVelocity = manualPiloting?.maxPitchRollVelocityValueForPercent(percent)
        }
        let horizontalAcceleration = SettingsBehavioursMode.current.defaultValues.horizontalAcceleration
        let defaultPitchRollVelocity = Float(manualPiloting?.maxPitchRollVelocityValueForPercent(horizontalAcceleration))
        return [
            SettingEntry(setting: manualPiloting?.maxPitchRollVelocity,
                         title: L10n.settingsBehaviourReactivity,
                         unit: UnitType.percent,
                         overLimitValue: Float(overlimitMaxPitchRollVelocity),
                         defaultValue: defaultPitchRollVelocity,
                         itemLogKey: LogEvent.LogKeyAdvancedSettings.globalReactivity),
            SettingEntry(setting: Asset.Settings.iconSettingsCamera.image,
                         title: L10n.settingsBehaviourSectionGimbal),
            SettingEntry(setting: gimbal?.maxSpeedSettings[.pitch],
                         title: L10n.settingsBehaviourCameraTilt,
                         unit: UnitType.degreePerSecond,
                         defaultValue: Float(SettingsBehavioursMode.current.defaultValues.cameraTilt),
                         itemLogKey: LogEvent.LogKeyAdvancedSettings.cameraTiltSpeed.description),
            SettingEntry(setting: Asset.Settings.Advanced.drone.image,
                         title: L10n.settingsBehaviourSectionFlight),
            SettingEntry(setting: bankedTurnModel(),
                         title: L10n.settingsBehaviourBankedTurn,
                         showInfo: showBankedTurnInfo,
                         itemLogKey: LogEvent.LogKeyAdvancedSettings.bankedTurn),
            SettingEntry(setting: manualPiloting?.maxPitchRoll,
                         title: L10n.settingsBehaviourMaxInclination,
                         unit: UnitType.degree,
                         defaultValue: Float(SettingsBehavioursMode.current.defaultValues.horizontalSpeed),
                         image: Asset.Settings.Advanced.iconSpeedHorizontal.image,
                         itemLogKey: LogEvent.LogKeyAdvancedSettings.inclination.description),
            SettingEntry(setting: manualPiloting?.maxVerticalSpeed,
                         title: L10n.settingsBehaviourVerticalSpeed,
                         unit: UnitType.speed,
                         overLimitValue: Float(overlimitPreset?.verticalSpeed),
                         defaultValue: Float(SettingsBehavioursMode.current.defaultValues.verticalSpeed),
                         image: Asset.Settings.Advanced.iconSpeedVertical.image,
                         itemLogKey: LogEvent.LogKeyAdvancedSettings.verticalSpeed.description),
            SettingEntry(setting: manualPiloting?.maxYawRotationSpeed,
                         title: L10n.settingsBehaviourRotationSpeed,
                         unit: UnitType.degreePerSecond,
                         overLimitValue: Float(overlimitPreset?.rotationSpeed),
                         defaultValue: Float(SettingsBehavioursMode.current.defaultValues.rotationSpeed),
                         image: Asset.Settings.Advanced.iconSpeedRotation.image,
                         itemLogKey: LogEvent.LogKeyAdvancedSettings.rotationSpeed.description)
        ]
    }
}

// MARK: - Private Funcs
private extension BehavioursViewModel {
    /// Show horizontal info.
    func showHorizontalInfo() {
        self.infoHandler?(InclinedRoll.self)
    }

    /// Show banked turn info.
    func showBankedTurnInfo() {
        self.infoHandler?(BankedTurn.self)
    }

    /// Inclined roll model.
    func inclinedRollModel() -> DroneSettingModel? {
        return DroneSettingModel(allValues: InclinedRoll.allValues,
                                 supportedValues: InclinedRoll.allValues,
                                 currentValue: InclinedRoll.value(from: gimbal?.stabilizationSettings[.roll]),
                                 isUpdating: false) { [weak self] mode in
            guard let inclinedRoll = mode as? InclinedRoll else { return }

            self?.gimbal?.stabilizationSettings[.roll]?.value = inclinedRoll.boolValue
        }
    }

    /// Banked turn model.
    func bankedTurnModel() -> DroneSettingModel? {
        return DroneSettingModel(allValues: BankedTurn.allValues,
                                 supportedValues: BankedTurn.allValues,
                                 currentValue: BankedTurn.value(from: manualPiloting?.bankedTurnMode),
                                 isUpdating: false) { [weak self] mode in
            guard let bankedTurn = mode as? BankedTurn else { return }

            self?.manualPiloting?.bankedTurnMode?.value = bankedTurn.boolValue
        }
    }
}
