//
//  Copyright (C) 2021 Parrot Drones SAS.
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

private extension ULogTag {
    static let tag = ULogTag(name: "camera")
}

/// User defaults keys for camera configuraton edition.
private extension DefaultsKeys {
    var cameraConfig: DefaultsKey<Data?> { .init("key_cameraConfig") }
}

/// Camera configuration parameters.
private struct CameraConfig: Codable {
    let alignmentOffsetPitch: Double?
    let alignmentOffsetRoll: Double?
    let alignmentOffsetYaw: Double?
    let audioRecordingMode: Camera2AudioRecordingMode?
    let autoExposureMeteringMode: Camera2AutoExposureMeteringMode?
    let autoRecordMode: Camera2AutoRecordMode?
    let exposureCompensation: Camera2EvCompensation?
    let exposureMode: Camera2ExposureMode?
    let imageContrast: Double?
    let imageSaturation: Double?
    let imageSharpness: Double?
    let imageStyle: Camera2Style?
    let isoSensitivity: Camera2Iso?
    let maximumIsoSensitivity: Camera2Iso?
    let mode: Camera2Mode?
    let photoBracketing: Camera2BracketingValue?
    let photoBurst: Camera2BurstValue?
    let photoDigitalSignature: Camera2DigitalSignature?
    let photoDynamicRange: Camera2DynamicRange?
    let photoFileFormat: Camera2PhotoFileFormat?
    let photoFormat: Camera2PhotoFormat?
    let photoGpslapseInterval: Double?
    let photoMode: Camera2PhotoMode?
    let photoResolution: Camera2PhotoResolution?
    let photoStreamingMode: Camera2PhotoStreamingMode?
    let photoTimelapseInterval: Double?
    let shutterSpeed: Camera2ShutterSpeed?
    let storagePolicy: Camera2StoragePolicy?
    let videoRecordingBitrate: UInt?
    let videoRecordingCodec: Camera2VideoCodec?
    let videoRecordingDynamicRange: Camera2DynamicRange?
    let videoRecordingFramerate: Camera2RecordingFramerate?
    let videoRecordingMode: Camera2VideoRecordingMode?
    let videoRecordingResolution: Camera2RecordingResolution?
    let whiteBalanceMode: Camera2WhiteBalanceMode?
    let whiteBalanceTemperature: Camera2WhiteBalanceTemperature?
    let zoomMaxSpeed: Double?
    let zoomVelocityControlQualityMode: Camera2ZoomVelocityControlQualityMode?
}

/// Constants for camera configuraton edition.
private struct Constants {
    /// Default camera configuration parameters.
    static let defaults = CameraConfig(
        alignmentOffsetPitch: 0,
        alignmentOffsetRoll: 0,
        alignmentOffsetYaw: 0,
        audioRecordingMode: CameraPreset.startAudio,
        autoExposureMeteringMode: .standard,
        autoRecordMode: CameraPreset.autoRecord,
        exposureCompensation: .ev0_00,
        exposureMode: .automatic,
        imageContrast: 0,
        imageSaturation: 0,
        imageSharpness: 0,
        imageStyle: .standard,
        isoSensitivity: .iso100,
        maximumIsoSensitivity: .iso6400,
        mode: .recording,
        photoBracketing: .preset1ev,
        photoBurst: .burst10Over1s,
        photoDigitalSignature: CameraPreset.photoSignature,
        photoDynamicRange: .hdr8,
        photoFileFormat: .jpeg,
        photoFormat: .rectilinear,
        photoGpslapseInterval: GpsLapseMode.preset.value.map { Double($0) } ?? 10,
        photoMode: .single,
        photoResolution: Camera2PhotoResolution.defaultResolution,
        photoStreamingMode: .continuous,
        photoTimelapseInterval: TimeLapseMode.preset.interval,
        shutterSpeed: .one,
        storagePolicy: .automatic,
        videoRecordingBitrate: nil, // no value for video bitrate
        videoRecordingCodec: CameraPreset.videoencoding,
        videoRecordingDynamicRange: CameraPreset.dynamicHdrRange,
        videoRecordingFramerate: Camera2RecordingFramerate.defaultFramerate,
        videoRecordingMode: .standard,
        videoRecordingResolution: Camera2RecordingResolution.defaultResolution,
        whiteBalanceMode: Camera2WhiteBalanceMode.defaultMode,
        whiteBalanceTemperature: .k2000,
        zoomMaxSpeed: 0.34,
        zoomVelocityControlQualityMode: CameraPreset.velocityQuality)
}

/// Helpers for camera configuration edition.
public extension Camera2Editor {

    /// Sets a parameter value. Value is applied only contained in current supported values, or `nil`.
    ///
    /// - Parameters:
    ///   - param: configuration parameter descriptor
    ///   - value: value to apply or `nil`
    func applyValueNotForced<V: Hashable>(_ param: Camera2Param<V>, _ value: V?) {
        guard let editorParam = self[param] else {
            return
        }
        if let value = value {
            if editorParam.currentSupportedValues.contains(value) {
                editorParam.value = value
            }
        } else {
            editorParam.value = nil
        }
    }

    /// Sets a parameter value. Value is applied only contained in current supported values, or `nil`.
    ///
    /// - Parameters:
    ///   - param: configuration parameter descriptor
    ///   - value: value to apply or `nil`
    func applyValueNotForced(_ param: Camera2Param<Double>, _ value: Double?) {
        guard let editorParam = self[param] else {
            return
        }
        if let value = value {
            if editorParam.currentSupportedValues?.contains(value) == true {
                editorParam.value = value
            }
        } else {
            editorParam.value = nil
        }
    }

    /// Completes and applies edited camera configuration.
    ///
    /// - Parameters:
    ///   - currentConfig: curent camera configuration, used to set currently undefined parameters
    ///   - saveParams: `false` to not save configured parameters
    func saveSettings(currentConfig: Camera2Config?, saveParams: Bool = true) {
        let savedConfig = getStoredConfig()

        if saveParams {
            // save configured parameters
            saveConfiguredParams()
        }

        if !complete,
           let config = currentConfig {
            // complete with current configuration values
            complete(config: config)
        }

        if !complete,
           let savedConfig = savedConfig {
            // complete with saved parameters
            complete(with: savedConfig)
        }

        if !complete {
            // complete with best choices
            completeWithBestChoices()
        }

        if !complete {
            // let groundSdk complete missing parameters
            ULog.d(.tag, "Camera config not complete, auto-complete")
            autoComplete()
        }

        if !commit() {
            ULog.e(.tag, "Failed to commit camera config")
        }
    }
}

/// Private extension for camera configuration edition helpers.
private extension Camera2Editor {
    /// Sets a parameter value, if undefined. Value is applied only contained in current supported values, and not `nil`.
    ///
    /// - Parameters:
    ///   - param: configuration parameter descriptor
    ///   - value: value to apply or `nil`
    func applyValueIfUndefined<V: Hashable>(_ param: Camera2Param<V>, _ value: V?) {
        guard let editorParam = self[param],
              editorParam.value == nil,
              let valueToApply = value,
              editorParam.currentSupportedValues.contains(valueToApply) else {
            return
        }
        editorParam.value = valueToApply
    }

    /// Sets a parameter value, if undefined. Value is applied only contained in current supported values, and not `nil`.
    ///
    /// - Parameters:
    ///   - param: configuration parameter descriptor
    ///   - value: value to apply or `nil`
    func applyValueIfUndefined(_ param: Camera2Param<Double>, _ value: Double?) {
        guard let editorParam = self[param],
              editorParam.value == nil,
              let valueToApply = value,
              editorParam.currentSupportedValues?.contains(valueToApply) == true else {
            return
        }
        editorParam.value = valueToApply
    }

    /// Sets a parameter value, if undefined, by copying the parameter value of a given configuration.
    ///
    /// It has no effect if the given parameter value is not supported in the currently edited configuration.
    ///
    /// - Parameters:
    ///   - param: configuration parameter descriptor
    ///   - config: configuration that handles the parameter value to apply
    func applyValueIfUndefined<V: Hashable>(_ param: Camera2Param<V>, _ config: Camera2Config) {
        applyValueIfUndefined(param, config[param]?.value)
    }

    /// Sets a parameter value, if undefined, by copying the parameter value of a given configuration.
    ///
    /// It has no effect if the given parameter value is not supported in the currently edited configuration.
    ///
    /// - Parameters:
    ///   - param: configuration parameter descriptor
    ///   - config: configuration that handles the parameter value to apply
    func applyValueIfUndefined(_ param: Camera2Param<Double>, _ config: Camera2Config) {
        applyValueIfUndefined(param, config[param]?.value)
    }

    /// Sets a parameter value, if undefined. The value applied is the first value contained in current supported values.
    ///
    /// - Parameters:
    ///   - param: configuration parameter descriptor
    ///   - values: values where the applied value should be picked
    func applyFirstValueIfUndefined<V: Hashable>(_ param: Camera2Param<V>, _ values: [V]) {
        guard let editorParam = self[param],
              editorParam.value == nil,
              let valueToApply = values.first(where: { editorParam.currentSupportedValues.contains($0) }) else {
            return
        }
        editorParam.value = valueToApply
    }

    /// Sets a parameter value, if undefined. The value applied is the first value contained in current supported values.
    ///
    /// - Parameters:
    ///   - param: configuration parameter descriptor
    ///   - values: values where the applied value should be picked
    func applyFirstValueIfUndefined(_ param: Camera2Param<Double>, _ values: [Double]) {
        guard let editorParam = self[param],
              editorParam.value == nil,
              let valueToApply = values.first(where: { editorParam.currentSupportedValues?.contains($0) == true }) else {
            return
        }
        editorParam.value = valueToApply
    }

    /// Gets stored camera configuration parameters.
    func getStoredConfig() -> CameraConfig? {
        guard let data = Defaults[\.cameraConfig] else { return nil }
        return try? JSONDecoder().decode(CameraConfig.self, from: data)
    }

    /// Sets stored camera configuration parameters.
    func setStoredConfig(config: CameraConfig) {
        Defaults.cameraConfig = try? JSONEncoder().encode(config)
    }

    /// Merges configured parameters with previously saved parameters and saves parameters.
    func saveConfiguredParams() {
        let savedConfig = getStoredConfig()
        let configToSave = CameraConfig(
            alignmentOffsetPitch: self[Camera2Params.alignmentOffsetPitch]?.value ?? savedConfig?.alignmentOffsetPitch,
            alignmentOffsetRoll: self[Camera2Params.alignmentOffsetRoll]?.value ?? savedConfig?.alignmentOffsetRoll,
            alignmentOffsetYaw: self[Camera2Params.alignmentOffsetYaw]?.value ?? savedConfig?.alignmentOffsetYaw,
            audioRecordingMode: self[Camera2Params.audioRecordingMode]?.value ?? savedConfig?.audioRecordingMode,
            autoExposureMeteringMode: self[Camera2Params.autoExposureMeteringMode]?.value ?? savedConfig?.autoExposureMeteringMode,
            autoRecordMode: self[Camera2Params.autoRecordMode]?.value ?? savedConfig?.autoRecordMode,
            exposureCompensation: self[Camera2Params.exposureCompensation]?.value ?? savedConfig?.exposureCompensation,
            exposureMode: self[Camera2Params.exposureMode]?.value ?? savedConfig?.exposureMode,
            imageContrast: self[Camera2Params.imageContrast]?.value ?? savedConfig?.imageContrast,
            imageSaturation: self[Camera2Params.imageSaturation]?.value ?? savedConfig?.imageSaturation,
            imageSharpness: self[Camera2Params.imageSharpness]?.value ?? savedConfig?.imageSharpness,
            imageStyle: self[Camera2Params.imageStyle]?.value ?? savedConfig?.imageStyle,
            isoSensitivity: self[Camera2Params.isoSensitivity]?.value ?? savedConfig?.isoSensitivity,
            maximumIsoSensitivity: self[Camera2Params.maximumIsoSensitivity]?.value ?? savedConfig?.maximumIsoSensitivity,
            mode: self[Camera2Params.mode]?.value ?? savedConfig?.mode,
            photoBracketing: self[Camera2Params.photoBracketing]?.value ?? savedConfig?.photoBracketing,
            photoBurst: self[Camera2Params.photoBurst]?.value ?? savedConfig?.photoBurst,
            photoDigitalSignature: self[Camera2Params.photoDigitalSignature]?.value ?? savedConfig?.photoDigitalSignature,
            photoDynamicRange: self[Camera2Params.photoDynamicRange]?.value ?? savedConfig?.photoDynamicRange,
            photoFileFormat: self[Camera2Params.photoFileFormat]?.value ?? savedConfig?.photoFileFormat,
            photoFormat: self[Camera2Params.photoFormat]?.value ?? savedConfig?.photoFormat,
            photoGpslapseInterval: self[Camera2Params.photoGpslapseInterval]?.value ?? savedConfig?.photoGpslapseInterval,
            photoMode: self[Camera2Params.photoMode]?.value ?? savedConfig?.photoMode,
            photoResolution: self[Camera2Params.photoResolution]?.value ?? savedConfig?.photoResolution,
            photoStreamingMode: self[Camera2Params.photoStreamingMode]?.value ?? savedConfig?.photoStreamingMode,
            photoTimelapseInterval: self[Camera2Params.alignmentOffsetPitch]?.value ?? savedConfig?.alignmentOffsetPitch,
            shutterSpeed: self[Camera2Params.shutterSpeed]?.value ?? savedConfig?.shutterSpeed,
            storagePolicy: self[Camera2Params.storagePolicy]?.value ?? savedConfig?.storagePolicy,
            videoRecordingBitrate: self[Camera2Params.videoRecordingBitrate]?.value ?? savedConfig?.videoRecordingBitrate,
            videoRecordingCodec: self[Camera2Params.videoRecordingCodec]?.value ?? savedConfig?.videoRecordingCodec,
            videoRecordingDynamicRange: self[Camera2Params.videoRecordingDynamicRange]?.value ?? savedConfig?.videoRecordingDynamicRange,
            videoRecordingFramerate: self[Camera2Params.videoRecordingFramerate]?.value ?? savedConfig?.videoRecordingFramerate,
            videoRecordingMode: self[Camera2Params.videoRecordingMode]?.value ?? savedConfig?.videoRecordingMode,
            videoRecordingResolution: self[Camera2Params.videoRecordingResolution]?.value ?? savedConfig?.videoRecordingResolution,
            whiteBalanceMode: self[Camera2Params.whiteBalanceMode]?.value ?? savedConfig?.whiteBalanceMode,
            whiteBalanceTemperature: self[Camera2Params.whiteBalanceTemperature]?.value ?? savedConfig?.whiteBalanceTemperature,
            zoomMaxSpeed: self[Camera2Params.zoomMaxSpeed]?.value ?? savedConfig?.zoomMaxSpeed,
            zoomVelocityControlQualityMode: self[Camera2Params.zoomVelocityControlQualityMode]?.value ?? savedConfig?.zoomVelocityControlQualityMode)
        setStoredConfig(config: configToSave)
    }

    /// Completes edited configuration using a given configuration.
    ///
    /// For each currently undefined parameter, apply value of given configuration, if and only if
    /// this value is supported in the currently edited configuration.
    ///
    /// - Parameters:
    ///    - config: configuration used to set currently undefined parameters
    ///
    /// - Note: The configuration may not be complete after a call to this method.
    func complete(config: Camera2Config) {
        // parameters are applied by order of priority
        applyValueIfUndefined(Camera2Params.mode, config)
        applyValueIfUndefined(Camera2Params.photoMode, config)
        applyValueIfUndefined(Camera2Params.photoResolution, config)
        applyValueIfUndefined(Camera2Params.photoFileFormat, config)
        applyValueIfUndefined(Camera2Params.photoFormat, config)
        applyValueIfUndefined(Camera2Params.photoBracketing, config)
        applyValueIfUndefined(Camera2Params.photoBurst, config)
        applyValueIfUndefined(Camera2Params.photoGpslapseInterval, config)
        applyValueIfUndefined(Camera2Params.photoTimelapseInterval, config)
        applyValueIfUndefined(Camera2Params.photoDynamicRange, config)
        applyValueIfUndefined(Camera2Params.photoDigitalSignature, config)
        applyValueIfUndefined(Camera2Params.photoStreamingMode, config)
        applyValueIfUndefined(Camera2Params.videoRecordingMode, config)
        applyValueIfUndefined(Camera2Params.videoRecordingCodec, config)
        applyValueIfUndefined(Camera2Params.videoRecordingFramerate, config)
        applyValueIfUndefined(Camera2Params.videoRecordingResolution, config)
        applyValueIfUndefined(Camera2Params.videoRecordingDynamicRange, config)
        applyValueIfUndefined(Camera2Params.audioRecordingMode, config)
        applyValueIfUndefined(Camera2Params.autoRecordMode, config)
        applyValueIfUndefined(Camera2Params.exposureMode, config)
        applyValueIfUndefined(Camera2Params.autoExposureMeteringMode, config)
        applyValueIfUndefined(Camera2Params.shutterSpeed, config)
        applyValueIfUndefined(Camera2Params.isoSensitivity, config)
        applyValueIfUndefined(Camera2Params.whiteBalanceMode, config)
        applyValueIfUndefined(Camera2Params.whiteBalanceTemperature, config)
        applyValueIfUndefined(Camera2Params.exposureCompensation, config)
        applyValueIfUndefined(Camera2Params.imageStyle, config)
        applyValueIfUndefined(Camera2Params.imageContrast, config)
        applyValueIfUndefined(Camera2Params.imageSaturation, config)
        applyValueIfUndefined(Camera2Params.imageSharpness, config)
        applyValueIfUndefined(Camera2Params.zoomVelocityControlQualityMode, config)
        applyValueIfUndefined(Camera2Params.zoomMaxSpeed, config)
        applyValueIfUndefined(Camera2Params.storagePolicy, config)
        applyValueIfUndefined(Camera2Params.alignmentOffsetPitch, config)
        applyValueIfUndefined(Camera2Params.alignmentOffsetRoll, config)
        applyValueIfUndefined(Camera2Params.alignmentOffsetYaw, config)
        applyValueIfUndefined(Camera2Params.maximumIsoSensitivity, config)
        applyValueIfUndefined(Camera2Params.videoRecordingBitrate, config)
    }

    /// Completes edited configuration using a given configuration.
    ///
    /// For each currently undefined parameter, apply value of given configuration, if and only if
    /// this value is supported in the currently edited configuration.
    ///
    /// - Parameters:
    ///    - config: configuration used to set currently undefined parameters
    ///
    /// - Note: The configuration may not be complete after a call to this method.
    func complete(with config: CameraConfig) {
        // parameters are applied by order of priority
        applyValueIfUndefined(Camera2Params.mode, config.mode)
        applyValueIfUndefined(Camera2Params.photoMode, config.photoMode)
        applyValueIfUndefined(Camera2Params.photoResolution, config.photoResolution)
        applyValueIfUndefined(Camera2Params.photoFileFormat, config.photoFileFormat)
        applyValueIfUndefined(Camera2Params.photoFormat, config.photoFormat)
        applyValueIfUndefined(Camera2Params.photoBracketing, config.photoBracketing)
        applyValueIfUndefined(Camera2Params.photoBurst, config.photoBurst)
        applyValueIfUndefined(Camera2Params.photoGpslapseInterval, config.photoGpslapseInterval)
        applyValueIfUndefined(Camera2Params.photoTimelapseInterval, config.photoTimelapseInterval)
        applyValueIfUndefined(Camera2Params.photoDynamicRange, config.photoDynamicRange)
        applyValueIfUndefined(Camera2Params.photoDigitalSignature, config.photoDigitalSignature)
        applyValueIfUndefined(Camera2Params.photoStreamingMode, config.photoStreamingMode)
        applyValueIfUndefined(Camera2Params.videoRecordingMode, config.videoRecordingMode)
        applyValueIfUndefined(Camera2Params.videoRecordingCodec, config.videoRecordingCodec)
        applyValueIfUndefined(Camera2Params.videoRecordingFramerate, config.videoRecordingFramerate)
        applyValueIfUndefined(Camera2Params.videoRecordingResolution, config.videoRecordingResolution)
        applyValueIfUndefined(Camera2Params.videoRecordingDynamicRange, config.videoRecordingDynamicRange)
        applyValueIfUndefined(Camera2Params.audioRecordingMode, config.audioRecordingMode)
        applyValueIfUndefined(Camera2Params.autoRecordMode, config.autoRecordMode)
        applyValueIfUndefined(Camera2Params.exposureMode, config.exposureMode)
        applyValueIfUndefined(Camera2Params.autoExposureMeteringMode, config.autoExposureMeteringMode)
        applyValueIfUndefined(Camera2Params.shutterSpeed, config.shutterSpeed)
        applyValueIfUndefined(Camera2Params.isoSensitivity, config.isoSensitivity)
        applyValueIfUndefined(Camera2Params.whiteBalanceMode, config.whiteBalanceMode)
        applyValueIfUndefined(Camera2Params.whiteBalanceTemperature, config.whiteBalanceTemperature)
        applyValueIfUndefined(Camera2Params.exposureCompensation, config.exposureCompensation)
        applyValueIfUndefined(Camera2Params.imageStyle, config.imageStyle)
        applyValueIfUndefined(Camera2Params.imageContrast, config.imageContrast)
        applyValueIfUndefined(Camera2Params.imageSaturation, config.imageSaturation)
        applyValueIfUndefined(Camera2Params.imageSharpness, config.imageSharpness)
        applyValueIfUndefined(Camera2Params.zoomVelocityControlQualityMode, config.zoomVelocityControlQualityMode)
        applyValueIfUndefined(Camera2Params.zoomMaxSpeed, config.zoomMaxSpeed)
        applyValueIfUndefined(Camera2Params.storagePolicy, config.storagePolicy)
        applyValueIfUndefined(Camera2Params.alignmentOffsetPitch, config.alignmentOffsetPitch)
        applyValueIfUndefined(Camera2Params.alignmentOffsetRoll, config.alignmentOffsetRoll)
        applyValueIfUndefined(Camera2Params.alignmentOffsetYaw, config.alignmentOffsetYaw)
        applyValueIfUndefined(Camera2Params.maximumIsoSensitivity, config.maximumIsoSensitivity)
        applyValueIfUndefined(Camera2Params.videoRecordingBitrate, config.videoRecordingBitrate)
    }

    /// Completes edited configuration trying to apply best choice for each parameter.
    ///
    /// For most parameters, we just try to apply the default value.
    /// For some specific parameters, we try to apply the highest or lowest available value.
    func completeWithBestChoices() {
        let config = Constants.defaults
        // parameters are applied by order of priority
        applyValueIfUndefined(Camera2Params.mode, config.mode)
        applyValueIfUndefined(Camera2Params.photoMode, config.photoMode)
        applyValueIfUndefined(Camera2Params.photoResolution, config.photoResolution)
        applyValueIfUndefined(Camera2Params.photoFileFormat, config.photoFileFormat)
        applyValueIfUndefined(Camera2Params.photoFormat, config.photoFormat)
        applyValueIfUndefined(Camera2Params.photoBracketing, config.photoBracketing)
        applyValueIfUndefined(Camera2Params.photoBurst, config.photoBurst)

        // best choice for gpslapse interval is default interval or lowest interval
        applyValueIfUndefined(Camera2Params.photoGpslapseInterval, config.photoGpslapseInterval)
        let gpslapseValues = GpsLapseMode.allValues.compactMap { ($0 as? GpsLapseMode)?.value.map { Double($0) } }
        applyFirstValueIfUndefined(Camera2Params.photoGpslapseInterval, gpslapseValues)

        // best choice for timelapse interval is default interval or lowest interval
        applyValueIfUndefined(Camera2Params.photoTimelapseInterval, config.photoTimelapseInterval)
        let timelapseValues = TimeLapseMode.allValues.compactMap { ($0 as? TimeLapseMode)?.interval }
        applyFirstValueIfUndefined(Camera2Params.photoTimelapseInterval, timelapseValues)

        applyValueIfUndefined(Camera2Params.photoDynamicRange, config.photoDynamicRange)
        applyValueIfUndefined(Camera2Params.photoDigitalSignature, config.photoDigitalSignature)
        applyValueIfUndefined(Camera2Params.photoStreamingMode, config.photoStreamingMode)
        applyValueIfUndefined(Camera2Params.videoRecordingMode, config.videoRecordingMode)
        applyValueIfUndefined(Camera2Params.videoRecordingCodec, config.videoRecordingCodec)

        // best choice for video framerate is highest framerate
        applyFirstValueIfUndefined(Camera2Params.videoRecordingFramerate,
                                   Camera2RecordingFramerate.sortedCases.reversed())
        applyValueIfUndefined(Camera2Params.videoRecordingFramerate, config.videoRecordingFramerate)

        applyValueIfUndefined(Camera2Params.videoRecordingResolution, config.videoRecordingResolution)
        applyValueIfUndefined(Camera2Params.videoRecordingDynamicRange, config.videoRecordingDynamicRange)
        applyValueIfUndefined(Camera2Params.audioRecordingMode, config.audioRecordingMode)
        applyValueIfUndefined(Camera2Params.autoRecordMode, config.autoRecordMode)
        applyValueIfUndefined(Camera2Params.exposureMode, config.exposureMode)
        applyValueIfUndefined(Camera2Params.autoExposureMeteringMode, config.autoExposureMeteringMode)
        applyValueIfUndefined(Camera2Params.shutterSpeed, config.shutterSpeed)
        applyValueIfUndefined(Camera2Params.isoSensitivity, config.isoSensitivity)
        applyValueIfUndefined(Camera2Params.whiteBalanceMode, config.whiteBalanceMode)
        applyValueIfUndefined(Camera2Params.whiteBalanceTemperature, config.whiteBalanceTemperature)
        applyValueIfUndefined(Camera2Params.exposureCompensation, config.exposureCompensation)
        applyValueIfUndefined(Camera2Params.imageStyle, config.imageStyle)
        applyValueIfUndefined(Camera2Params.imageContrast, config.imageContrast)
        applyValueIfUndefined(Camera2Params.imageSaturation, config.imageSaturation)
        applyValueIfUndefined(Camera2Params.imageSharpness, config.imageSharpness)
        applyValueIfUndefined(Camera2Params.zoomVelocityControlQualityMode, config.zoomVelocityControlQualityMode)
        applyValueIfUndefined(Camera2Params.zoomMaxSpeed, config.zoomMaxSpeed)
        applyValueIfUndefined(Camera2Params.storagePolicy, config.storagePolicy)
        applyValueIfUndefined(Camera2Params.alignmentOffsetPitch, config.alignmentOffsetPitch)
        applyValueIfUndefined(Camera2Params.alignmentOffsetRoll, config.alignmentOffsetRoll)
        applyValueIfUndefined(Camera2Params.alignmentOffsetYaw, config.alignmentOffsetYaw)
        applyValueIfUndefined(Camera2Params.maximumIsoSensitivity, config.maximumIsoSensitivity)
        applyValueIfUndefined(Camera2Params.videoRecordingBitrate, config.videoRecordingBitrate)
    }
}

/// Add Codable conformance to camera parameters types.
extension Camera2AudioRecordingMode: Codable {}
extension Camera2AutoExposureMeteringMode: Codable {}
extension Camera2AutoRecordMode: Codable {}
extension Camera2EvCompensation: Codable {}
extension Camera2ExposureMode: Codable {}
extension Camera2Style: Codable {}
extension Camera2Iso: Codable {}
extension Camera2Mode: Codable {}
extension Camera2BracketingValue: Codable {}
extension Camera2BurstValue: Codable {}
extension Camera2DigitalSignature: Codable {}
extension Camera2DynamicRange: Codable {}
extension Camera2PhotoFileFormat: Codable {}
extension Camera2PhotoFormat: Codable {}
extension Camera2PhotoMode: Codable {}
extension Camera2PhotoResolution: Codable {}
extension Camera2PhotoStreamingMode: Codable {}
extension Camera2ShutterSpeed: Codable {}
extension Camera2StoragePolicy: Codable {}
extension Camera2VideoCodec: Codable {}
extension Camera2RecordingFramerate: Codable {}
extension Camera2VideoRecordingMode: Codable {}
extension Camera2RecordingResolution: Codable {}
extension Camera2WhiteBalanceMode: Codable {}
extension Camera2WhiteBalanceTemperature: Codable {}
extension Camera2ZoomVelocityControlQualityMode: Codable {}
