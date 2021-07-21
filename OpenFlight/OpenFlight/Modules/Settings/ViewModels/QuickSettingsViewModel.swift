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

import Foundation
import GroundSdk
import SwiftyUserDefaults

/// View model used to watch various drone settings grouped in quick settings.
class QuickSettingsViewModel: DroneWatcherViewModel<DeviceConnectionState>, SettingsViewModelProtocol {
    // MARK: - Internal Properties
    /// SettingsViewModelProtocol implementation, but unused here.
    var infoHandler: ((SettingMode.Type) -> Void)?

    var isUpdating: Bool? {
        return false
    }

    // MARK: - Private Properties
    private var manualPilotingRef: Ref<ManualCopterPilotingItf>?
    private var geofenceRef: Ref<Geofence>?
    private var obstacleAvoidanceRef: Ref<ObstacleAvoidance>?
    private var cameraRef: Ref<MainCamera2>?
    private var rthRef: Ref<ReturnHomePilotingItf>?
    private unowned var obstacleAvoidanceMonitor: ObstacleAvoidanceMonitor

    // MARK: - Init
    init(obstacleAvoidanceMonitor: ObstacleAvoidanceMonitor) {
        self.obstacleAvoidanceMonitor = obstacleAvoidanceMonitor
        super.init()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        // Listen Manual Piloting Interface.
        manualPilotingRef = drone.getPilotingItf(PilotingItfs.manualCopter) { [weak self] _ in
            self?.notifyChange()
        }
        // Listen geofence.
        geofenceRef = drone.getPeripheral(Peripherals.geofence) { [weak self] _ in
            self?.notifyChange()
        }
        // Listen obstacle avoidance.
        obstacleAvoidanceRef = drone.getPeripheral(Peripherals.obstacleAvoidance) { [weak self] _ in
            self?.notifyChange()
        }
        // Listen camera.
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [weak self] _ in
            self?.notifyChange()
        }
        // Listen rth.
        rthRef = drone.getPilotingItf(PilotingItfs.returnHome) { [weak self] _ in
            self?.notifyChange()
        }
    }

    func resetSettings() {
        guard let currentEditor = self.drone?.currentCamera?.currentEditor else { return }

        currentEditor[Camera2Params.audioRecordingMode]?.value = CameraPreset.startAudio
    }
}

// MARK: - Internal Properties
extension QuickSettingsViewModel {
    /// Returns quick settings entries.
    var settingEntries: [SettingEntry] {
        let drone = self.drone
        let geofence = drone?.getPeripheral(Peripherals.geofence)
        let newZoomModel = self.zoomQualityModel

        return [SettingEntry(setting: SecondaryScreenType.self,
                             itemLogKey: LogEvent.LogKeyAdvancedSettings.secondaryScreenType),
                SettingEntry(setting: obstacleAvoidanceModel,
                             title: L10n.settingsQuickAvoidance,
                             itemLogKey: LogEvent.LogKeyQuickSettings.obstacleAvoidance),
                SettingEntry(setting: startAudioModel,
                             title: L10n.settingsQuickAudioRec,
                             image: Asset.Settings.Quick.icStartAudio.image,
                             imageDisabled: Asset.Settings.Quick.icStopAudio.image,
                             itemLogKey: LogEvent.LogKeyQuickSettings.audio),
                SettingEntry(setting: GeofenceViewModel.geofenceModeModel(geofence: geofence),
                             title: L10n.settingsAdvancedCategoryGeofence,
                             itemLogKey: LogEvent.LogKeyQuickSettings.geofence),
                SettingEntry(setting: newZoomModel,
                             title: L10n.settingsCameraLossyZoom,
                             isEnabled: newZoomModel?.currentValue != nil,
                             image: Asset.Settings.Quick.losslessZoomActive.image,
                             imageDisabled: Asset.Settings.Quick.losslessZoomInactive.image,
                             itemLogKey: LogEvent.LogKeyQuickSettings.extraZoom),
                SettingEntry(setting: self.autoRecordModel,
                             title: L10n.settingsCameraAutoRecord,
                             image: Asset.Settings.Quick.autorecordActive.image,
                             imageDisabled: Asset.Settings.Quick.autorecordInactive.image)
        ]
    }
}

// MARK: - Private Properties
private extension QuickSettingsViewModel {
    /// Returns model for zoom quality setting.
    var zoomQualityModel: DroneSettingModel? {
        let zoomAllowance = drone?.currentCamera?.config[Camera2Params.zoomVelocityControlQualityMode]?.value
        return DroneSettingModel(allValues: Camera2ZoomVelocityControlQualityMode.allValues,
                                 supportedValues: Camera2ZoomVelocityControlQualityMode.allValues,
                                 currentValue: zoomAllowance) { mode in
            guard let mode = mode as? Camera2ZoomVelocityControlQualityMode else { return }
            Services.hub.drone.zoomService.setQualityMode(mode)
        }
    }

    /// Returns model for auto record setting.
    var autoRecordModel: DroneSettingModel? {
        let autoRecord = drone?.currentCamera?.config[Camera2Params.autoRecordMode]?.value
        return DroneSettingModel(allValues: Camera2AutoRecordMode.allValues,
                                 supportedValues: Camera2AutoRecordMode.allValues,
                                 currentValue: autoRecord) { [weak self] mode in
            guard let mode = mode as? Camera2AutoRecordMode else { return }

            let currentEditor = self?.drone?.currentCamera?.currentEditor
            let currentConfig = self?.drone?.currentCamera?.config
            currentEditor?[Camera2Params.autoRecordMode]?.value = mode
            currentEditor?.saveSettings(currentConfig: currentConfig)
        }
    }

    /// Returns model for obstacle avoidance zetting.
    var obstacleAvoidanceModel: DroneSettingModel? {
        guard let obstacleAvoidance = drone?.getPeripheral(Peripherals.obstacleAvoidance) else {
            return DroneSettingModel(allValues: ObstacleAvoidanceMode.allValues,
                                     supportedValues: ObstacleAvoidanceMode.allValues,
                                     currentValue: ObstacleAvoidanceMode.disabled)
        }

        return DroneSettingModel(allValues: ObstacleAvoidanceMode.allValues,
                                 supportedValues: ObstacleAvoidanceMode.allValues,
                                 currentValue: obstacleAvoidance.mode.preferredValue,
                                 isUpdating: obstacleAvoidance.mode.updating) { [unowned obstacleAvoidanceMonitor] mode in
            guard let mode = mode as? ObstacleAvoidanceMode else { return }
            obstacleAvoidanceMonitor.userAsks(mode: mode)
        }
    }

    /// Returns model for starting audio setting.
    var startAudioModel: DroneSettingModel? {
        let startAudio = drone?.currentCamera?.config[Camera2Params.audioRecordingMode]?.value
        return DroneSettingModel(allValues: Camera2AudioRecordingMode.allValues,
                                 supportedValues: Camera2AudioRecordingMode.allValues,
                                 currentValue: startAudio) { [weak self] audio in
            guard let audio = audio as? Camera2AudioRecordingMode else { return }

            let currentEditor = self?.drone?.currentCamera?.currentEditor
            let currentConfig = self?.drone?.currentCamera?.config
            currentEditor?[Camera2Params.audioRecordingMode]?.value = audio
            currentEditor?.saveSettings(currentConfig: currentConfig)
        }
    }
}
