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
        guard let currentMode = self.mode else { return false }
        switch currentMode {
        case .photo:
            let hdr8Available = self.config[Camera2Params.photoDynamicRange]?.overallSupportedValues.contains(.hdr8)

            return hdr8Available == true
        case .recording:
            let hdr10Available = self.config[Camera2Params.videoRecordingDynamicRange]?.overallSupportedValues.contains(.hdr10)
            let hdr8Available = self.config[Camera2Params.videoRecordingDynamicRange]?.overallSupportedValues.contains(.hdr8)

            return hdr10Available == true || hdr8Available == true
        }
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
    /// Save settings.
    func saveSettings() {
        _ = self.autoComplete().commit()
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
