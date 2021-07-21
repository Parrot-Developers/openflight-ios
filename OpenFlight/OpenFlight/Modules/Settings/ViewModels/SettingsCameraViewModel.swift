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
final class SettingsCameraViewModel: DroneWatcherViewModel<DeviceConnectionState>, SettingsViewModelProtocol {
    // MARK: - Internal Properties
    var infoHandler: ((_ modeType: SettingMode.Type) -> Void)?

    var settingEntries: [SettingEntry] {
        let photoSignatureDisabled = photoSignatureModel?.forceDisabling ?? false
        let videoEncodingDisabled = videoEncodingModel?.forceDisabling ?? false
        let hdrDisabled = !isDynamicRange10Enabled() || highDynamicRangeModel?.forceDisabling ?? false
        let antiflickerDisabled = antiflickerModel?.forceDisabling ?? false
        return [SettingEntry(setting: SettingsOverexposure.self,
                             title: L10n.settingsCameraOverExposure,
                             itemLogKey: LogEvent.LogKeyAdvancedSettings.displayOverexposure),
                SettingEntry(setting: self.photoSignatureModel,
                             title: L10n.settingsCameraPhotoDigitalSignature,
                             alpha: photoSignatureDisabled ? Constants.disabledAlpha : Constants.enabledAlpha,
                             itemLogKey: LogEvent.LogKeyAdvancedSettings.signPictures),
                SettingEntry(setting: self.videoEncodingModel,
                             title: L10n.settingsCameraVideoEncoding,
                             alpha: videoEncodingDisabled ? Constants.disabledAlpha : Constants.enabledAlpha,
                             itemLogKey: LogEvent.LogKeyAdvancedSettings.videoEncoding),
                SettingEntry(setting: self.highDynamicRangeModel,
                             title: L10n.settingsCameraVideoHdrMode + Style.newLine + L10n.settingsCameraHdr10Availability,
                             isEnabled: !hdrDisabled,
                             alpha: hdrDisabled ? Constants.disabledAlpha : Constants.enabledAlpha,
                             itemLogKey: LogEvent.LogKeyAdvancedSettings.videoHDR),
                SettingEntry(setting: self.antiflickerModel,
                             title: L10n.settingsCameraAntiFlickering,
                             alpha: antiflickerDisabled ? Constants.disabledAlpha : Constants.enabledAlpha,
                             itemLogKey: LogEvent.LogKeyAdvancedSettings.antiFlickering)
                // TODO: Add calibration button.
        ]
    }

    var isUpdating: Bool? {
        return drone?.currentCamera?.config.updating == true
            || drone?.getPeripheral(Peripherals.antiflicker)?.setting.updating == true
    }

    // MARK: - Private Enums
    private enum Constants {
        static let enabledAlpha: CGFloat = 1.0
        static let disabledAlpha: CGFloat = 0.3
    }

    // MARK: - Private Properties
    private var cameraRef: Ref<MainCamera2>?
    private var antiFlickerRef: Ref<Antiflicker>?
    private unowned var flightPlanCameraSettingsHandler: FlightPlanCameraSettingsHandler

    // MARK: - init
    init(flightPlanCameraSettingsHandler: FlightPlanCameraSettingsHandler) {
        self.flightPlanCameraSettingsHandler = flightPlanCameraSettingsHandler
        super.init()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [weak self] _ in
            self?.notifyChange()
        }

        antiFlickerRef = drone.getPeripheral(Peripherals.antiflicker) { [weak self] _ in
            self?.notifyChange()
        }
    }

    func resetSettings() {
        let drone = self.drone
        drone?.getPeripheral(Peripherals.antiflicker)?.setting.mode = CameraPreset.antiflickerMode

        if let currentEditor = drone?.currentCamera?.currentEditor {
            currentEditor[Camera2Params.autoRecordMode]?.value = CameraPreset.autoRecord
            currentEditor[Camera2Params.zoomVelocityControlQualityMode]?.value = CameraPreset.velocityQuality
            currentEditor[Camera2Params.videoRecordingCodec]?.value = CameraPreset.videoencoding
            currentEditor[Camera2Params.videoRecordingDynamicRange]?.value = CameraPreset.dynamicHdrRange
            currentEditor[Camera2Params.photoDigitalSignature]?.value = CameraPreset.photoSignature
            currentEditor.saveSettings(currentConfig: drone?.currentCamera?.config)
        }

        Defaults.overexposureSetting = CameraPreset.overexposure.rawValue
    }
}

// MARK: - Private Funcs
private extension SettingsCameraViewModel {
    /// Verifies if HDR10 is enabled.
    ///
    /// - Returns: true if video encoding set on H265, false otherwise.
    func isDynamicRange10Enabled() -> Bool {
        let currentEditor = self.drone?.currentCamera?.currentEditor
        return currentEditor?[Camera2Params.videoRecordingCodec]?.value == .h265
    }
}

// MARK: - Private Properties
private extension SettingsCameraViewModel {
    /// Returns antiflicker setting model.
    var antiflickerModel: DroneSettingModel? {
        let antiFlicker = drone?.getPeripheral(Peripherals.antiflicker)
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

    /// Returns zoom setting model.
    var zoomModel: DroneSettingModel? {
        let zoomAllowance = drone?.currentCamera?.config[Camera2Params.zoomVelocityControlQualityMode]?.value
        return DroneSettingModel(allValues: Camera2ZoomVelocityControlQualityMode.allValues,
                                 supportedValues: Camera2ZoomVelocityControlQualityMode.allValues,
                                 currentValue: zoomAllowance) { [weak self] mode in
                                    guard let mode = mode as? Camera2ZoomVelocityControlQualityMode else { return }

                                    let currentEditor = self?.drone?.currentCamera?.currentEditor
                                    let currentConfig = self?.drone?.currentCamera?.config
                                    currentEditor?[Camera2Params.zoomVelocityControlQualityMode]?.value = mode
                                    currentEditor?.saveSettings(currentConfig: currentConfig)
        }
    }

    /// Returns auto record setting model.
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

    /// Return video encoding setting model.
    var videoEncodingModel: DroneSettingModel? {
        let videoEncoding = drone?.currentCamera?.config[Camera2Params.videoRecordingCodec]?.value
        let forceDisabling = flightPlanCameraSettingsHandler.forbidCameraSettingsChange
        return DroneSettingModel(allValues: Camera2VideoCodec.allValues,
                                 supportedValues: Camera2VideoCodec.allValues,
                                 currentValue: videoEncoding,
                                 forceDisabling: forceDisabling) { [weak self] mode in
            guard let encodingMode = mode as? Camera2VideoCodec else { return }

            let currentEditor = self?.drone?.currentCamera?.currentEditor
            let currentConfig = self?.drone?.currentCamera?.config
            currentEditor?[Camera2Params.videoRecordingCodec]?.value = encodingMode
            // If the current video dynamic range is HDR we update the drone value.
            if currentConfig?[Camera2Params.videoRecordingDynamicRange]?.value.isHdr == true {
                if encodingMode == .h264 {
                    currentEditor?[Camera2Params.videoRecordingDynamicRange]?.value = .hdr8
                }
            }
            currentEditor?.saveSettings(currentConfig: currentConfig)
        }
    }

    /// Returns high dynamic range setting model.
    var highDynamicRangeModel: DroneSettingModel? {
        let currentHdrValue: Camera2DynamicRange

        // If the drone have already a HDR value.
        if let droneHDR = drone?.currentCamera?.config[Camera2Params.videoRecordingDynamicRange]?.value,
           droneHDR != .sdr {
            Defaults.highDynamicRangeSetting = droneHDR.rawValue
        }

        // If we already have a HDR defaults.
        if let defaultsHDRString = Defaults.highDynamicRangeSetting,
           let defaultsHDR = Camera2DynamicRange(rawValue: defaultsHDRString) {
            currentHdrValue = defaultsHDR
        } else {
            let videoEncoding = drone?.currentCamera?.config[Camera2Params.videoRecordingCodec]?.value
            currentHdrValue = videoEncoding == .h265 ? Camera2DynamicRange.hdr10 : Camera2DynamicRange.hdr8
        }
        let forceDisabling = flightPlanCameraSettingsHandler.forbidCameraSettingsChange
        return DroneSettingModel(allValues: Camera2DynamicRange.usedValues,
                                 supportedValues: Camera2DynamicRange.usedValues,
                                 currentValue: currentHdrValue,
                                 forceDisabling: forceDisabling) { [weak self] range in
            guard let videoRange = range as? Camera2DynamicRange else { return }

            Defaults.highDynamicRangeSetting = videoRange.rawValue

            let currentConfig = self?.drone?.currentCamera?.config

            // If the current video dynamic range is HDR we update the drone value.
            if currentConfig?[Camera2Params.videoRecordingDynamicRange]?.value.isHdr == true {
                let currentEditor = self?.drone?.currentCamera?.currentEditor
                currentEditor?[Camera2Params.videoRecordingDynamicRange]?.value = videoRange
                currentEditor?.saveSettings(currentConfig: currentConfig)
            }
        }
    }

    /// Returns photo signature setting model.
    var photoSignatureModel: DroneSettingModel? {
        let photoSignature = drone?.currentCamera?.config[Camera2Params.photoDigitalSignature]?.value
        let forceDisabling = flightPlanCameraSettingsHandler.forbidCameraSettingsChange
        return DroneSettingModel(allValues: Camera2DigitalSignature.allValues,
                                 supportedValues: Camera2DigitalSignature.allValues,
                                 currentValue: photoSignature,
                                 forceDisabling: forceDisabling) { [weak self] digitalSignature in
                                    guard let digitalSignature = digitalSignature as? Camera2DigitalSignature else { return }

                                    let currentEditor = self?.drone?.currentCamera?.currentEditor
                                    let currentConfig = self?.drone?.currentCamera?.config
                                    currentEditor?[Camera2Params.photoDigitalSignature]?.value = digitalSignature
                                    currentEditor?.saveSettings(currentConfig: currentConfig)
        }
    }
}
