//    Copyright (C) 2022 Parrot Drones SAS
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

import Foundation
import GroundSdk
import Combine
import SwiftyUserDefaults

public protocol PresetsService: AnyObject {

    var resetSettingPublisher: AnyPublisher<Void, Never> { get }

    func resetPreset()
    func savePreset()
    func switchBehavioursMode(mode: SettingsBehavioursMode)
    func start()

}

final class PresetsServiceImpl {

    private var resetSettingSubject = CurrentValueSubject<Void, Never>(())

    private var currentDroneHolder: CurrentDroneHolder

    private var manualPiloting: ManualCopterPilotingItf? {
        return currentDroneHolder.drone.getPilotingItf(PilotingItfs.manualCopter)
    }

    private var gimbal: Gimbal? {
        return currentDroneHolder.drone.getPeripheral(Peripherals.gimbal)
    }

    init(currentDroneHolder: CurrentDroneHolder) {
        self.currentDroneHolder = currentDroneHolder
    }
}

extension PresetsServiceImpl: PresetsService {

    var resetSettingPublisher: AnyPublisher<Void, Never> { resetSettingSubject.eraseToAnyPublisher() }

    func start() {
        // Init content regarding data.
        if Defaults.userPilotingPreset == nil {
            resetPreset()
            Defaults.userPilotingPreset = SettingsBehavioursMode.preset.key
        }
    }

    func resetPreset() {
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

        resetSettingSubject.send()
    }

    /// Apply behaviours settings regarding behaviour mode.
    func applyBehavioursSettings(mode: SettingsBehavioursMode) {
        manualPiloting?.maxPitchRoll.value = Defaults[key: mode.maxPitchRollKey] ?? mode.defaultValues.horizontalSpeed

        if let maxPitchRollVelocityPresetValue = manualPiloting?.maxPitchRollVelocityValueForPercent(mode.defaultValues.horizontalAcceleration) {
            manualPiloting?.maxPitchRollVelocity?.value = maxPitchRollVelocityPresetValue
        }
        manualPiloting?.maxVerticalSpeed.value = Defaults[key: mode.maxVerticalSpeedKey] ?? mode.defaultValues.verticalSpeed
        manualPiloting?.maxYawRotationSpeed.value = Defaults[key: mode.maxYawRotationSpeedKey] ?? mode.defaultValues.rotationSpeed

        manualPiloting?.bankedTurnMode?.value = Defaults[key: mode.bankedTurnModeKey] ?? mode.defaultValues.bankedTurn
        gimbal?.stabilizationSettings[.roll]?.value = !(Defaults[key: mode.inclinedRollModeKey] ?? mode.defaultValues.inclinedRoll)

        gimbal?.maxSpeedSettings[.pitch]?.value = Defaults[key: mode.cameraTiltKey] ?? mode.defaultValues.cameraTilt
        // If camera exposure mode is currently set to automatic, it should be refreshed to recommended mode.
        if let camera = currentDroneHolder.drone.currentCamera,
           let automaticMode = camera.config[Camera2Params.exposureMode]?.value.refreshAutomaticModeIfNeeded() {
            let currentEditor = camera.currentEditor
            currentEditor[Camera2Params.exposureMode]?.value = automaticMode
            currentEditor.saveSettings(currentConfig: camera.config)
        }
    }

    func switchBehavioursMode(mode: SettingsBehavioursMode) {
        Defaults.userPilotingPreset = mode.rawValue
        applyBehavioursSettings(mode: mode)
    }

    func savePreset() {
        Defaults[key: SettingsBehavioursMode.current.maxPitchRollKey] = manualPiloting?.maxPitchRoll.value
        Defaults[key: SettingsBehavioursMode.current.maxPitchRollVelocityKey] = manualPiloting?.maxPitchRollVelocity?.value
        Defaults[key: SettingsBehavioursMode.current.maxVerticalSpeedKey] = manualPiloting?.maxVerticalSpeed.value
        Defaults[key: SettingsBehavioursMode.current.maxYawRotationSpeedKey] = manualPiloting?.maxYawRotationSpeed.value
        Defaults[key: SettingsBehavioursMode.current.bankedTurnModeKey] = manualPiloting?.bankedTurnMode?.value
        Defaults[key: SettingsBehavioursMode.current.inclinedRollModeKey] = !(gimbal?.stabilizationSettings[.roll]?.value ?? true)
        Defaults[key: SettingsBehavioursMode.current.cameraTiltKey] = gimbal?.maxSpeedSettings[.pitch]?.value
    }
}
