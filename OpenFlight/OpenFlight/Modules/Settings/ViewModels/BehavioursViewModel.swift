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

/// Behaviours settings view model.
final class BehavioursViewModel: SettingsViewModelProtocol {

    // MARK: - Published properties

    private(set) var notifyChangePublisher = CurrentValueSubject<Void, Never>(())
    var resetSettingPublisher: AnyPublisher<Void, Never> { presetService.resetSettingPublisher }

    // MARK: - Private properties

    private var currentDroneHolder: CurrentDroneHolder
    private var presetService: PresetsService
    private var cancellables = Set<AnyCancellable>()
    private var manualCopterValue: ManualCopterPilotingItf?
    private var gimbalValue: Gimbal?

    // MARK: - Internal Properties
    var infoHandler: ((_ modeType: SettingMode.Type) -> Void)?

    var isUpdating: Bool? {
        return false
    }

    // MARK: - Private Properties
    private var manualPilotingRef: Ref<ManualCopterPilotingItf>?
    private var gimbalRef: Ref<Gimbal>?
    private var trackerRef: Ref<TargetTracker>?

    // MARK: - Init
    init(currentDroneHolder: CurrentDroneHolder, presetService: PresetsService) {
        self.currentDroneHolder = currentDroneHolder
        self.presetService = presetService

        currentDroneHolder.dronePublisher
            .sink { [weak self] drone in
                guard let self = self else { return }
                self.listenManualCopter(drone)
                self.listenGimbal(drone)
                self.listenTargetTracker(drone)
            }
            .store(in: &cancellables)
    }

    // MARK: - Internal Funcs
    /// Reset settings in User Defaults.
    func resetSettings() {
        presetService.resetPreset()
    }

    /// Save drone settings in User Defaults.
    func saveSettings() {
        presetService.savePreset()
    }

    /// Switch behaviours mode.
    func switchBehavioursMode(mode: SettingsBehavioursMode) {
        presetService.switchBehavioursMode(mode: mode)
    }

    /// Returns behaviours settings entries.
    var settingEntries: [SettingEntry] {
        let overlimitPreset = SettingsBehavioursMode.current.maxRecommandedValues
        return [
            SettingEntry(setting: Asset.Settings.iconSettingsCameraFill.image,
                         title: L10n.settingsBehaviourSectionGimbal),
            SettingEntry(setting: gimbalValue?.maxSpeedSettings[.pitch],
                         title: L10n.settingsBehaviourCameraTilt,
                         unit: UnitType.degreePerSecond,
                         defaultValue: Float(SettingsBehavioursMode.current.defaultValues.cameraTilt),
                         itemLogKey: LogEvent.LogKeyAdvancedSettings.cameraTiltSpeed.description),
            SettingEntry(setting: Asset.Settings.Advanced.iconSettingsDrone.image,
                         title: L10n.settingsBehaviourSectionFlight),
            SettingEntry(setting: bankedTurnModel(manualCopter: manualCopterValue),
                         title: L10n.settingsBehaviourBankedTurn,
                         showInfo: showBankedTurnInfo,
                         itemLogKey: LogEvent.LogKeyAdvancedSettings.bankedTurn),
            SettingEntry(setting: manualCopterValue?.maxPitchRoll,
                         title: L10n.settingsBehaviourMaxInclination,
                         unit: UnitType.degree,
                         defaultValue: Float(SettingsBehavioursMode.current.defaultValues.horizontalSpeed),
                         image: Asset.Settings.Advanced.iconSpeedHorizontal.image,
                         itemLogKey: LogEvent.LogKeyAdvancedSettings.inclination.description,
                         settingStepperSlider: SettingStepperSlider(limitIntervalChange: 2, leftIntervalStep: 0.25, rightIntervalStep: 1)),
            SettingEntry(setting: manualCopterValue?.maxVerticalSpeed,
                         title: L10n.settingsBehaviourVerticalSpeed,
                         unit: UnitType.speed,
                         overLimitValue: Float(overlimitPreset?.verticalSpeed),
                         defaultValue: Float(SettingsBehavioursMode.current.defaultValues.verticalSpeed),
                         image: Asset.Settings.Advanced.iconSpeedVertical.image,
                         itemLogKey: LogEvent.LogKeyAdvancedSettings.verticalSpeed.description,
                         settingStepperSlider: SettingStepperSlider(limitIntervalChange: 0.20, leftIntervalStep: 0.05, rightIntervalStep: 0.10)),
            SettingEntry(setting: manualCopterValue?.maxYawRotationSpeed,
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

    func listenManualCopter(_ drone: Drone) {
        manualPilotingRef = drone.getPilotingItf(PilotingItfs.manualCopter) { [unowned self] manualCopter in
            self.manualCopterValue = manualCopter
            notifyChangePublisher.send()
        }
    }

    func listenGimbal(_ drone: Drone) {
        gimbalRef = drone.getPeripheral(Peripherals.gimbal) { [unowned self] gimbal in
            self.gimbalValue = gimbal
            notifyChangePublisher.send()
        }
    }

    func listenTargetTracker(_ drone: Drone) {
        trackerRef = drone.getPeripheral(Peripherals.targetTracker) { [unowned self] _ in
            notifyChangePublisher.send()
        }
    }

    /// Show banked turn info.
    func showBankedTurnInfo() {
        infoHandler?(BankedTurn.self)
    }

    /// Banked turn model.
    func bankedTurnModel(manualCopter: ManualCopterPilotingItf?) -> DroneSettingModel? {
        return DroneSettingModel(allValues: BankedTurn.allValues,
                                 supportedValues: BankedTurn.allValues,
                                 currentValue: BankedTurn.value(from: manualCopter?.bankedTurnMode),
                                 isUpdating: false) { mode in
            guard let bankedTurn = mode as? BankedTurn else { return }

            manualCopter?.bankedTurnMode?.value = bankedTurn.boolValue
        }
    }
}
