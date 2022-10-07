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

private extension ULogTag {
    static let tag = ULogTag(name: "SettingsCameraViewModel")
}

/// Behaviours settings view model.
final class SettingsCameraViewModel: SettingsViewModelProtocol {
    // MARK: - Published Properties

    private(set) var notifyChangePublisher = CurrentValueSubject<Void, Never>(())

    // MARK: - Private Properties

    private var currentDroneHolder: CurrentDroneHolder
    private var cancellables = Set<AnyCancellable>()
    private var drone: Drone { currentDroneHolder.drone }
    private var mainCamera2: MainCamera2?
    private var antiFlicker: Antiflicker?

    // MARK: - Internal Properties
    var infoHandler: ((_ modeType: SettingMode.Type) -> Void)?

    var settingEntries: [SettingEntry] {
        let photoSignatureDisabled = photoSignatureModel?.forceDisabling ?? false
        let videoEncodingDisabled = videoEncodingModel?.forceDisabling ?? false
        let highDynamicRangeModel = self.highDynamicRangeModel
        let hdrDisabled = !isVideoDynamicRange10Possible() || highDynamicRangeModel?.forceDisabling ?? false
        let antiflickerDisabled = antiflickerModel?.forceDisabling ?? false
        return [SettingEntry(setting: SettingsOverexposure.self,
                             title: L10n.settingsCameraOverExposure,
                             itemLogKey: LogEvent.LogKeyAdvancedSettings.displayOverexposure),
                SettingEntry(setting: self.photoSignatureModel,
                             title: L10n.settingsCameraPhotoDigitalSignature,
                             isEnabled: !photoSignatureDisabled,
                             itemLogKey: LogEvent.LogKeyAdvancedSettings.signPictures),
                SettingEntry(setting: self.videoEncodingModel,
                             title: L10n.settingsCameraVideoEncoding,
                             isEnabled: !videoEncodingDisabled,
                             itemLogKey: LogEvent.LogKeyAdvancedSettings.videoEncoding),
                SettingEntry(setting: highDynamicRangeModel,
                             title: L10n.settingsCameraVideoHdrMode,
                             isEnabled: !hdrDisabled,
                             itemLogKey: LogEvent.LogKeyAdvancedSettings.videoHDR),
                SettingEntry(setting: self.antiflickerModel,
                             title: L10n.settingsCameraAntiFlickering,
                             isEnabled: !antiflickerDisabled,
                             itemLogKey: LogEvent.LogKeyAdvancedSettings.antiFlickering)
                // TODO: Add calibration button.
        ]
    }

    var isUpdating: Bool? {
        return drone.currentCamera?.config.updating == true
            || drone.getPeripheral(Peripherals.antiflicker)?.setting.updating == true
    }

    // MARK: - Private Properties
    private var cameraRef: Ref<MainCamera2>?
    private var antiFlickerRef: Ref<Antiflicker>?
    private unowned var flightPlanCameraSettingsHandler: FlightPlanCameraSettingsHandler

    // MARK: - init
    init(flightPlanCameraSettingsHandler: FlightPlanCameraSettingsHandler, currentDroneHolder: CurrentDroneHolder) {
        self.flightPlanCameraSettingsHandler = flightPlanCameraSettingsHandler
        self.currentDroneHolder = currentDroneHolder

        currentDroneHolder.dronePublisher
            .sink { [weak self] drone in
                guard let self = self else { return }
                self.listenMainCamera2(drone)
                self.listenAntiFlicher(drone)
            }
            .store(in: &cancellables)
    }

    func resetSettings() {
        drone.getPeripheral(Peripherals.antiflicker)?.setting.mode = CameraPreset.antiflickerMode

        if let currentEditor = drone.currentCamera?.currentEditor {
            currentEditor[Camera2Params.autoRecordMode]?.value = CameraPreset.autoRecord
            currentEditor[Camera2Params.zoomVelocityControlQualityMode]?.value = CameraPreset.velocityQuality
            currentEditor[Camera2Params.videoRecordingCodec]?.value = CameraPreset.videoencoding
            currentEditor[Camera2Params.videoRecordingDynamicRange]?.value = CameraPreset.dynamicHdrRange
            currentEditor[Camera2Params.photoDigitalSignature]?.value = CameraPreset.photoSignature
            currentEditor.saveSettings(currentConfig: drone.currentCamera?.config)
        }

        Defaults.overexposureSetting = CameraPreset.overexposure.rawValue
    }
}

// MARK: - Private Funcs
private extension SettingsCameraViewModel {
    /// Verifies if video HDR10 can be enabled.
    ///
    /// - Returns: true if video encoding set on H265, false otherwise.
    func isVideoDynamicRange10Possible() -> Bool {
        UserDefaults.videoRecordingCodec == .h265
    }

    /// Listens to camera2 peripheral
    func listenMainCamera2(_ drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [weak self] mainCamera2 in
            guard let self = self else { return }
            self.mainCamera2 = mainCamera2
            self.notifyChangePublisher.send()
        }
    }

    func listenAntiFlicher(_ drone: Drone) {
        antiFlickerRef = drone.getPeripheral(Peripherals.antiflicker) { [weak self] antiFlicker in
            guard let self = self else { return }
            self.antiFlicker = antiFlicker
            self.notifyChangePublisher.send()
        }
    }
}

// MARK: - Private Properties
private extension SettingsCameraViewModel {
    /// Returns antiflicker setting model.
    var antiflickerModel: DroneSettingModel? {
        let antiFlicker = drone.getPeripheral(Peripherals.antiflicker)
        guard let supportedModes = antiFlicker?.setting.supportedModes,
            let currentAntiflicker = antiFlicker?.setting.mode else {
                return nil
        }
        let forceDisabling = flightPlanCameraSettingsHandler.forbidCameraSettingsChange
        return DroneSettingModel(allValues: AntiflickerMode.allValues,
                                 supportedValues: Array(supportedModes),
                                 currentValue: currentAntiflicker,
                                 isUpdating: antiFlicker?.setting.updating ?? false,
                                 forceDisabling: forceDisabling) { [weak self] mode in
                                    guard let mode = mode as? AntiflickerMode else { return }

                                    let drone = self?.drone
                                    drone?.getPeripheral(Peripherals.antiflicker)?.setting.mode = mode
        }
    }

    /// Returns auto record setting model.
    var autoRecordModel: DroneSettingModel? {
        let autoRecord = drone.currentCamera?.config[Camera2Params.autoRecordMode]?.value
        return DroneSettingModel(allValues: Camera2AutoRecordMode.allValues,
                                 supportedValues: Camera2AutoRecordMode.allValues,
                                 currentValue: autoRecord) { [weak self] mode in
                                    guard let mode = mode as? Camera2AutoRecordMode else { return }

                                    let currentEditor = self?.drone.currentCamera?.currentEditor
                                    let currentConfig = self?.drone.currentCamera?.config
                                    currentEditor?[Camera2Params.autoRecordMode]?.value = mode
                                    currentEditor?.saveSettings(currentConfig: currentConfig)
        }
    }

    /// Return video encoding setting model.
    var videoEncodingModel: DroneSettingModel? {
        let videoEncoding = UserDefaults.videoRecordingCodec
        let droneValue = drone.currentCamera?.config[Camera2Params.videoRecordingCodec]?.value

        if videoEncoding != droneValue {
            ULog.w(.tag, "Video Encoding setting: \(videoEncoding) is different in the Drone: \(droneValue?.rawValue ?? "-")")
        }

        let forceDisabling = flightPlanCameraSettingsHandler.forbidCameraSettingsChange
        return DroneSettingModel(allValues: Camera2VideoCodec.allValues,
                                 supportedValues: Camera2VideoCodec.allValues,
                                 currentValue: videoEncoding,
                                 forceDisabling: forceDisabling) { [weak self] mode in
            guard let encodingMode = mode as? Camera2VideoCodec else { return }

            // Store the new value locally.
            Defaults.userVideoCodecSetting = encodingMode.rawValue

            // Update Drone's camera config.
            let currentEditor = self?.drone.currentCamera?.currentEditor
            let currentConfig = self?.drone.currentCamera?.config
            currentEditor?[Camera2Params.videoRecordingCodec]?.value = encodingMode
            // h264 only supports hdr8. Update the dynamic range accordingly.
            // hdr10 will automatically set when switching to h265.
            let hdr: Camera2DynamicRange = encodingMode == .h264 ? .hdr8 : .hdr10
            Defaults.highDynamicRangeSetting = hdr.rawValue
            // If the current video dynamic range is HDR we update the drone value.
            if currentConfig?[Camera2Params.videoRecordingDynamicRange]?.value.isHdr == true {
                currentEditor?[Camera2Params.videoRecordingDynamicRange]?.value = hdr
                Defaults.videoDynamicRangeSetting = hdr.rawValue
            }
            currentEditor?.saveSettings(currentConfig: currentConfig)
            // Notify the change to update the HDR switch.
            self?.notifyChangePublisher.send()
        }
    }

    /// Returns high dynamic range setting model.
    var highDynamicRangeModel: DroneSettingModel? {
        let videoDynamicRange = UserDefaults.videoRecordingDynamicRange
        let currentHdrValue: Camera2DynamicRange
        let droneValue = drone.currentCamera?.config[Camera2Params.videoRecordingDynamicRange]?.value

        if videoDynamicRange != .sdr {
            // If video HDR is enabled, use its value.
            currentHdrValue = videoDynamicRange
        } else if let defaultsHDRString = Defaults.highDynamicRangeSetting,
                  let defaultsHDR = Camera2DynamicRange(rawValue: defaultsHDRString) {
            // If a default HDR value is available, use its value.
            currentHdrValue = defaultsHDR
        } else {
            // else set the value depending the video encoding setting.
            currentHdrValue = UserDefaults.videoRecordingCodec == .h265 ? .hdr10 : .hdr8
            Defaults.highDynamicRangeSetting = currentHdrValue.rawValue
        }

        // Update the stored video dynamic range if HDR is enabled.
        if drone.currentCamera?.config[Camera2Params.videoRecordingDynamicRange]?.value.isHdr == true {
            Defaults.videoDynamicRangeSetting = currentHdrValue.rawValue
        }

        if currentHdrValue != droneValue {
            ULog.w(.tag, "Video Dynamic Range setting: \(currentHdrValue) is different in the Drone: \(droneValue?.rawValue ?? "-")")
        }

        let forceDisabling = flightPlanCameraSettingsHandler.forbidCameraSettingsChange
        return DroneSettingModel(allValues: Camera2DynamicRange.usedValues,
                                 supportedValues: Camera2DynamicRange.usedValues,
                                 currentValue: currentHdrValue,
                                 forceDisabling: forceDisabling) { [weak self] range in
            guard let videoRange = range as? Camera2DynamicRange else { return }

            Defaults.highDynamicRangeSetting = videoRange.rawValue

            let currentConfig = self?.drone.currentCamera?.config

            // If the current video dynamic range is HDR we update the drone value.
            if currentConfig?[Camera2Params.videoRecordingDynamicRange]?.value.isHdr == true {
                let currentEditor = self?.drone.currentCamera?.currentEditor
                currentEditor?[Camera2Params.videoRecordingDynamicRange]?.value = videoRange
                Defaults.videoDynamicRangeSetting = videoRange.rawValue
                currentEditor?.saveSettings(currentConfig: currentConfig)
            }
        }
    }

    /// Returns photo signature setting model.
    var photoSignatureModel: DroneSettingModel? {
        let photoSignature = UserDefaults.photoDigitalSignature
        let droneValue = drone.currentCamera?.config[Camera2Params.photoDigitalSignature]?.value

        if photoSignature != droneValue {
            ULog.w(.tag, "Photo signature setting: \(photoSignature) is different in the Drone: \(droneValue?.rawValue ?? "-")")
        }

        let forceDisabling = flightPlanCameraSettingsHandler.forbidCameraSettingsChange

        return DroneSettingModel(allValues: Camera2DigitalSignature.allValues,
                                 supportedValues: Camera2DigitalSignature.allValues,
                                 currentValue: photoSignature,
                                 forceDisabling: forceDisabling) { [weak self] digitalSignature in
            guard let digitalSignature = digitalSignature as? Camera2DigitalSignature else { return }

            // Store the new value locally.
            Defaults.userPhotoSignatureSetting = digitalSignature.rawValue

            // Update Drone's camera config.
            let currentEditor = self?.drone.currentCamera?.currentEditor
            let currentConfig = self?.drone.currentCamera?.config
            currentEditor?[Camera2Params.photoDigitalSignature]?.value = digitalSignature
            currentEditor?.saveSettings(currentConfig: currentConfig)
        }
    }
}
