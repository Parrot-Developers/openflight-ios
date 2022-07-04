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

import Foundation
import GroundSdk
import SwiftyUserDefaults
import Combine

private extension ULogTag {
    static let tag = ULogTag(name: "SettingsQuickViewController")
}

/// View model used to watch various drone settings grouped in quick settings.
class QuickSettingsViewModel: SettingsViewModelProtocol {

    // MARK: - Published properties

    private(set) var notifyChangePublisher = CurrentValueSubject<Void, Never>(())

    // MARK: - Private Properties

    private var manualCopter: ManualCopterPilotingItf?
    private var geofence: Geofence?
    private var obstacleAvoidance: ObstacleAvoidance?
    private var mainCamera2: MainCamera2?
    private var rth: ReturnHomePilotingItf?
    private var currentDroneHolder: CurrentDroneHolder
    private unowned var obstacleAvoidanceMonitor: ObstacleAvoidanceMonitor
    private var cancellables = Set<AnyCancellable>()
    private var drone: Drone { currentDroneHolder.drone }

    // MARK: - Internal Properties
    /// SettingsViewModelProtocol implementation, but unused here.
    var infoHandler: ((SettingMode.Type) -> Void)?

    var isUpdating: Bool? {
        return false
    }

    // MARK: - Ground SDK References

    private var manualPilotingRef: Ref<ManualCopterPilotingItf>?
    private var geofenceRef: Ref<Geofence>?
    private var obstacleAvoidanceRef: Ref<ObstacleAvoidance>?
    private var cameraRef: Ref<MainCamera2>?
    private var rthRef: Ref<ReturnHomePilotingItf>?

    // MARK: - Init
    init(obstacleAvoidanceMonitor: ObstacleAvoidanceMonitor, currentDroneHolder: CurrentDroneHolder) {
        self.obstacleAvoidanceMonitor = obstacleAvoidanceMonitor
        self.currentDroneHolder = currentDroneHolder

        currentDroneHolder.dronePublisher
            .sink { [weak self] drone in
                guard let self = self else { return }
                self.listenManualCopter(drone)
                self.listenGeofence(drone)
                self.listenObstacleAvoidance(drone)
                self.listenMainCamera2(drone)
                self.listenRth(drone)
            }
            .store(in: &cancellables)
    }

    func resetSettings() {
        guard let currentEditor = drone.currentCamera?.currentEditor else { return }

        currentEditor[Camera2Params.audioRecordingMode]?.value = CameraPreset.startAudio
    }
}

// MARK: - Internal Properties
extension QuickSettingsViewModel {
    /// Returns quick settings entries.
    var settingEntries: [SettingEntry] {
        let newZoomModel = zoomQualityModel(mainCamera: mainCamera2)

        return [SettingEntry(setting: SecondaryScreenType.self,
                             itemLogKey: LogEvent.LogKeyAdvancedSettings.secondaryScreenType),
                SettingEntry(setting: obstacleAvoidanceModel(obstacleAvoidance: obstacleAvoidance),
                             title: L10n.settingsQuickAvoidance,
                             itemLogKey: LogEvent.LogKeyQuickSettings.obstacleAvoidance),
                SettingEntry(setting: startAudioModel(mainCamera: mainCamera2),
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
                SettingEntry(setting: autoRecordModel(mainCamera: mainCamera2),
                             title: L10n.settingsCameraAutoRecord,
                             image: Asset.Settings.Quick.autorecordActive.image,
                             imageDisabled: Asset.Settings.Quick.autorecordInactive.image)
        ]
    }
}
// MARK: - Private Functions
private extension QuickSettingsViewModel {

    /// Listen Manual Piloting Interface
    func listenManualCopter(_ drone: Drone) {
        manualPilotingRef = drone.getPilotingItf(PilotingItfs.manualCopter) { [weak self] manualCopter in
            guard let self = self else { return }
            self.manualCopter = manualCopter
            self.notifyChangePublisher.send()
        }
    }

    /// Listen geofence
    func listenGeofence(_ drone: Drone) {
        geofenceRef = drone.getPeripheral(Peripherals.geofence) { [weak self] geofence in
            guard let self = self else { return }
            self.geofence = geofence
            self.notifyChangePublisher.send()
        }
    }

    /// Listen obstacle avoidance
    func listenObstacleAvoidance(_ drone: Drone) {
        obstacleAvoidanceRef = drone.getPeripheral(Peripherals.obstacleAvoidance) { [weak self] obstacleAvoidance in
            guard let self = self else { return }
            self.obstacleAvoidance = obstacleAvoidance
            self.notifyChangePublisher.send()
        }
    }

    /// Listen camera
    func listenMainCamera2(_ drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [weak self] mainCamera2 in
            guard let self = self else { return }
            self.mainCamera2 = mainCamera2
            self.notifyChangePublisher.send()
        }
    }

    /// Listen rth
    func listenRth(_ drone: Drone) {
        rthRef = drone.getPilotingItf(PilotingItfs.returnHome) { [weak self] returnHome in
            guard let self = self else { return }
            self.rth = returnHome
            self.notifyChangePublisher.send()
        }
    }
}
// MARK: - Private Properties
private extension QuickSettingsViewModel {
    /// Returns model for zoom quality setting.
    func zoomQualityModel(mainCamera: MainCamera2?) -> DroneSettingModel? {
        let zoomAllowance = mainCamera?.config[Camera2Params.zoomVelocityControlQualityMode]?.value
        return DroneSettingModel(allValues: Camera2ZoomVelocityControlQualityMode.allValues,
                                 supportedValues: Camera2ZoomVelocityControlQualityMode.allValues,
                                 currentValue: zoomAllowance) { mode in
            guard let mode = mode as? Camera2ZoomVelocityControlQualityMode else {
                ULog.e(.tag, "Camera2ZoomVelocityControlQualityMode is undefined")
                return
            }
            Services.hub.drone.zoomService.setQualityMode(mode)
        }
    }

    /// Returns model for auto record setting.
    func autoRecordModel(mainCamera: MainCamera2?) -> DroneSettingModel? {
        let autoRecord = mainCamera?.config[Camera2Params.autoRecordMode]?.value
        return DroneSettingModel(allValues: Camera2AutoRecordMode.allValues,
                                 supportedValues: Camera2AutoRecordMode.allValues,
                                 currentValue: autoRecord) { mode in
            guard let mode = mode as? Camera2AutoRecordMode else {
                ULog.e(.tag, "Camera2AutoRecordMode is undefined")
                return
            }

            let currentEditor = mainCamera?.currentEditor
            let currentConfig = mainCamera?.config
            currentEditor?[Camera2Params.autoRecordMode]?.value = mode
            currentEditor?.saveSettings(currentConfig: currentConfig)
        }
    }

    /// Returns model for obstacle avoidance setting.
    func obstacleAvoidanceModel(obstacleAvoidance: ObstacleAvoidance?) -> DroneSettingModel? {
        guard let obstacleAvoidance = obstacleAvoidance else {
            return DroneSettingModel(allValues: ObstacleAvoidanceMode.allValues,
                                     supportedValues: ObstacleAvoidanceMode.allValues,
                                     currentValue: ObstacleAvoidanceMode.disabled)
        }

        return DroneSettingModel(allValues: ObstacleAvoidanceMode.allValues,
                                 supportedValues: ObstacleAvoidanceMode.allValues,
                                 currentValue: obstacleAvoidance.mode.preferredValue,
                                 isUpdating: obstacleAvoidance.mode.updating) { [unowned obstacleAvoidanceMonitor] mode in
            guard let mode = mode as? ObstacleAvoidanceMode else {
                ULog.e(.tag, "ObstacleAvoidanceMode is undefined")
                return
            }
            obstacleAvoidanceMonitor.userAsks(mode: mode)
        }
    }

    /// Returns model for starting audio setting.
    func startAudioModel(mainCamera: MainCamera2?) -> DroneSettingModel? {
        let startAudio = mainCamera?.config[Camera2Params.audioRecordingMode]?.value
        return DroneSettingModel(allValues: Camera2AudioRecordingMode.allValues,
                                 supportedValues: Camera2AudioRecordingMode.allValues,
                                 currentValue: startAudio) { audio in
            guard let audio = audio as? Camera2AudioRecordingMode else {
                ULog.e(.tag, "Camera2AudioRecordingMode is undefined")
                return
            }
            let currentEditor = mainCamera?.currentEditor
            let currentConfig = mainCamera?.config
            currentEditor?[Camera2Params.audioRecordingMode]?.value = audio
            currentEditor?.saveSettings(currentConfig: currentConfig)
        }
    }
}
