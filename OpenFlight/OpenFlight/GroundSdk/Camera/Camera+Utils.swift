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

/// Utility extension for `Camera2`.
public extension Camera2 {
    /// Returns true if a gpslapse is currently in progress.
    var isGpsLapseStarted: Bool {
        if let photoState = self.photoCapture?.state,
            photoState.isStarted,
            self.config[Camera2Params.photoMode]?.value == .gpsLapse {
            return true
        } else {
            return false
        }
    }

    // Returns the current camera configuration for edition.
    var currentEditor: Camera2Editor {
        return self.config.edit(fromScratch: false)
    }

    /// Returns `TimeLapseMode` depending on drone current timelapse capture interval value.
    var timeLapseMode: TimeLapseMode? {
        guard let timelapseCaptureInterval = self.config[Camera2Params.photoTimelapseInterval]?.value else { return nil }
        return TimeLapseMode(rawValue: Int(timelapseCaptureInterval))
    }

    /// Returns `GpsLapseMode` depending on drone current GPS Lapse capture interval value.
    var gpsLapseMode: GpsLapseMode? {
        guard let gpslapseCaptureInterval = self.config[Camera2Params.photoGpslapseInterval]?.value else { return nil }
        return GpsLapseMode(rawValue: Int(gpslapseCaptureInterval))
    }

    /// Returns true if Hdr is activated.
    var isHdrOn: Bool {
        guard let currentMode = self.mode else { return false }
        switch currentMode {
        case .photo:
            return self.config[Camera2Params.photoDynamicRange]?.value.isHdr == true
        case .recording:
            return self.config[Camera2Params.videoRecordingDynamicRange]?.value.isHdr == true
        }
    }

    /// Returns true if Hdr is available.
    var hdrAvailable: Bool {
        guard let currentMode = mode else { return false }
        switch currentMode {
        case .photo:
            return photoHdrAvailable
        case .recording:
            return recordingHdrAvailable
        }
    }

    /// Returns true if photo Hdr is available for the current photo mode, format and file format.
    var photoHdrAvailable: Bool {
        let editor = config.edit(fromScratch: true)
        editor[Camera2Params.photoResolution]?.value = config[Camera2Params.photoResolution]?.value
        editor[Camera2Params.photoFormat]?.value = config[Camera2Params.photoFormat]?.value
        editor[Camera2Params.photoFileFormat]?.value = config[Camera2Params.photoFileFormat]?.value

        let hdr8Available = editor[Camera2Params.photoDynamicRange]?.currentSupportedValues.contains(.hdr8)

        return hdr8Available == true
    }

    /// Returns true if video recording Hdr is available for the current recording resolution and framerate.
    var recordingHdrAvailable: Bool {
        let editor = config.edit(fromScratch: true)
        editor[Camera2Params.videoRecordingResolution]?.value = config[Camera2Params.videoRecordingResolution]?.value
        editor[Camera2Params.videoRecordingFramerate]?.value = config[Camera2Params.videoRecordingFramerate]?.value

        let hdr10Available = editor[Camera2Params.videoRecordingDynamicRange]?.currentSupportedValues.contains(.hdr10)
        let hdr8Available = editor[Camera2Params.videoRecordingDynamicRange]?.currentSupportedValues.contains(.hdr8)

        return hdr10Available == true || hdr8Available == true
    }

    /// Returns true if PLog image style is available in the current configuration if HDR was disabled.
    var plogAvailable: Bool {
        let editor = config.edit(fromScratch: false)
        editor[Camera2Params.photoDynamicRange]?.value = .sdr
        editor[Camera2Params.videoRecordingDynamicRange]?.value = .sdr

        return editor[Camera2Params.imageStyle]?.currentSupportedValues.contains(.plog) == true
    }

    /// Returns current camera mode.
    var mode: Camera2Mode? {
        return config[Camera2Params.mode]?.value
    }

    /// Returns current camera zoom component.
    var zoom: Camera2Zoom? {
        return getComponent(Camera2Components.zoom)
    }

    /// Returns current camera photo capture component.
    var photoCapture: Camera2PhotoCapture? {
        return getComponent(Camera2Components.photoCapture)
    }

    /// Returns camera recording component.
    var recording: Camera2Recording? {
        return getComponent(Camera2Components.recording)
    }

    /// Returns camera media meta data component.
    var mediaMetadata: Camera2MediaMetadata? {
        return getComponent(Camera2Components.mediaMetadata)
    }
}

/// Utility extension for `Camera2Editor`.
public extension Camera2Editor {

    /// Set a parameter value, if undefined, by copying the parameter value of a given configuration.
    ///
    /// It has no effect if the given parameter value is not supported in the currently edited configuration.
    ///
    /// - Parameters:
    ///   - config: configuration that handles the parameter value to apply
    ///   - param: configuration parameter descriptor
    func applyValueIfUndefined<V: Hashable>(_ config: Camera2Config, _ param: Camera2Param<V>) {
        guard let editorParam = self[param],
              editorParam.value == nil,
              let valueToApply = config[param]?.value,
              editorParam.currentSupportedValues.contains(valueToApply) else {
            return
        }
        editorParam.value = valueToApply
    }

    /// Set a parameter value, if undefined, by copying the parameter value of a given configuration.
    ///
    /// It has no effect if the given parameter value is not supported in the currently edited configuration.
    ///
    /// - Parameters:
    ///   - config: configuration that handles the parameter value to apply
    ///   - param: configuration parameter descriptor
    func applyValueIfUndefined(_ config: Camera2Config, _ param: Camera2Param<Double>) {
        guard let editorParam = self[param],
              editorParam.value == nil,
              let valueToApply = config[param]?.value,
              editorParam.currentSupportedValues?.contains(valueToApply) == true else {
            return
        }
        editorParam.value = valueToApply
    }

    /// Complete edited configuration using a given configuration.
    ///
    /// For each currently undefined parameter, apply value of given configuration, if and only if
    /// this value is supported in the currently edited configuration.
    ///
    /// - Parameter config: configuration used to set currently undefined parameters
    ///
    /// - Note: The configuration may not be complete after a call to this method.
    func complete(config: Camera2Config) {
        applyValueIfUndefined(config, Camera2Params.alignmentOffsetPitch)
        applyValueIfUndefined(config, Camera2Params.alignmentOffsetRoll)
        applyValueIfUndefined(config, Camera2Params.alignmentOffsetYaw)
        applyValueIfUndefined(config, Camera2Params.audioRecordingMode)
        applyValueIfUndefined(config, Camera2Params.autoExposureMeteringMode)
        applyValueIfUndefined(config, Camera2Params.autoRecordMode)
        applyValueIfUndefined(config, Camera2Params.exposureCompensation)
        applyValueIfUndefined(config, Camera2Params.exposureMode)
        applyValueIfUndefined(config, Camera2Params.imageContrast)
        applyValueIfUndefined(config, Camera2Params.imageSaturation)
        applyValueIfUndefined(config, Camera2Params.imageSharpness)
        applyValueIfUndefined(config, Camera2Params.imageStyle)
        applyValueIfUndefined(config, Camera2Params.isoSensitivity)
        applyValueIfUndefined(config, Camera2Params.maximumIsoSensitivity)
        applyValueIfUndefined(config, Camera2Params.mode)
        applyValueIfUndefined(config, Camera2Params.photoBracketing)
        applyValueIfUndefined(config, Camera2Params.photoBurst)
        applyValueIfUndefined(config, Camera2Params.photoDigitalSignature)
        applyValueIfUndefined(config, Camera2Params.photoDynamicRange)
        applyValueIfUndefined(config, Camera2Params.photoFileFormat)
        applyValueIfUndefined(config, Camera2Params.photoFormat)
        applyValueIfUndefined(config, Camera2Params.photoGpslapseInterval)
        applyValueIfUndefined(config, Camera2Params.photoMode)
        applyValueIfUndefined(config, Camera2Params.photoResolution)
        applyValueIfUndefined(config, Camera2Params.photoStreamingMode)
        applyValueIfUndefined(config, Camera2Params.photoTimelapseInterval)
        applyValueIfUndefined(config, Camera2Params.shutterSpeed)
        applyValueIfUndefined(config, Camera2Params.storagePolicy)
        applyValueIfUndefined(config, Camera2Params.streamingCodec)
        applyValueIfUndefined(config, Camera2Params.streamingMode)
        applyValueIfUndefined(config, Camera2Params.videoRecordingBitrate)
        applyValueIfUndefined(config, Camera2Params.videoRecordingCodec)
        applyValueIfUndefined(config, Camera2Params.videoRecordingDynamicRange)
        applyValueIfUndefined(config, Camera2Params.videoRecordingFramerate)
        applyValueIfUndefined(config, Camera2Params.videoRecordingHyperlapse)
        applyValueIfUndefined(config, Camera2Params.videoRecordingMode)
        applyValueIfUndefined(config, Camera2Params.videoRecordingResolution)
        applyValueIfUndefined(config, Camera2Params.whiteBalanceMode)
        applyValueIfUndefined(config, Camera2Params.whiteBalanceTemperature)
        applyValueIfUndefined(config, Camera2Params.zoomMaxSpeed)
        applyValueIfUndefined(config, Camera2Params.zoomVelocityControlQualityMode)
    }

    /// Save settings.
    ///
    /// - Parameter currentConfig: curent camera configuration, used to set currently undefined parameters
    func saveSettings(currentConfig: Camera2Config?) {
        if !complete,
           let config = currentConfig {
            // complete with current configuration values
            complete(config: config)
        }

        _ = autoComplete().commit()
    }

    /// Enable hdr.
    func enableHdr(camera: Camera2?) {
        self.handleHdr(camera, enable: true)
    }

    /// Disable hdr.
    func disableHdr(camera: Camera2?) {
        self.handleHdr(camera, enable: false)
    }

    /// Enable or disable hdr.
    ///
    /// - Parameters:
    ///    - camera: Current camera.
    ///    - enable: Boolean that specify if we want to enable or disable hdr.
    func handleHdr(_ camera: Camera2?, enable: Bool) {
        guard let strongCamera = camera else { return }

        switch strongCamera.mode {
        case .photo:
            // Photo can only do HDR 8.
            self[Camera2Params.photoDynamicRange]?.value = enable ? .hdr8 : .sdr
        case .recording:
            let newHdrValue: Camera2DynamicRange
            // If we already have an HDR defaults.

            if let defaultsHDRString = Defaults.highDynamicRangeSetting,
               let defaultsHDR = Camera2DynamicRange(rawValue: defaultsHDRString) {
                newHdrValue = defaultsHDR
            } else {
                let videoEncoding = camera?.config[Camera2Params.videoRecordingCodec]?.value
                newHdrValue = videoEncoding == .h265 ? Camera2DynamicRange.hdr10 : Camera2DynamicRange.hdr8
            }

            self[Camera2Params.videoRecordingDynamicRange]?.value = enable ? newHdrValue : .sdr
            Defaults.highDynamicRangeSetting = newHdrValue.rawValue
        default:
            break
        }
    }
}

/// Utility extension for `Camera2RecordingState`.
extension Camera2RecordingState {
    /// Get duration.
    func getDuration(startTime: Date) -> TimeInterval {
        return Date().timeIntervalSince(startTime)
    }
}

/// Utility extension for `Camera2ZoomVelocityControlQualityMode`.
extension Camera2ZoomVelocityControlQualityMode {
    /// Tells if lossy is allowed.
    var isLossyAllowed: Bool {
        return self == .allowDegrading
    }
}

/// Utility extension for `extensionCamera2PhotoCaptureState`.
extension Camera2PhotoCaptureState {
    /// Tells if photo capture is started.
    var isStarted: Bool {
        switch self {
        case .started:
            return true
        default:
            return false
        }
    }
}
