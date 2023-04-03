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

import UIKit
import GroundSdk

private extension ULogTag {
    static let tag = ULogTag(name: URL(fileURLWithPath: #file).lastPathComponent)
}

// MARK: - Internal Enums
/// Enum containing photo formats.

enum PhotoFormatMode: String, BarItemMode, CaseIterable {

    case rectilinearJpeg
    case fullFrameJpeg
    case rectilinearDngJpeg
    case fullFrameDngJpeg

    var title: String {
        switch self {
        case .rectilinearJpeg:
            return L10n.photoSettingsFormatJpegRect
        case .fullFrameJpeg:
            return L10n.photoSettingsFormatJpegWide
        case .rectilinearDngJpeg:
            return L10n.photoSettingsFormatDngJpegRect
        case .fullFrameDngJpeg:
            return L10n.photoSettingsFormatDngJpeg
        }
    }

    var shortTitle: String {
        switch self {
        case .rectilinearJpeg:
            return L10n.photoSettingsFormatJpegRect
        case .fullFrameJpeg:
            return L10n.photoSettingsFormatJpegWide
        case .rectilinearDngJpeg:
            return L10n.photoSettingsFormatDngJpegRectShort
        case .fullFrameDngJpeg:
            return L10n.photoSettingsFormatDngJpegShort

        }
    }

    var image: UIImage? {
        switch self {
        case .rectilinearJpeg:
            return Asset.BottomBar.PhotoSettingsDefinition.iconPhotoSettingsDefinitionJpegRect.image
        case .fullFrameJpeg:
            return Asset.BottomBar.PhotoSettingsDefinition.iconPhotoSettingsDefinitionWide.image
        case .rectilinearDngJpeg:
            return Asset.BottomBar.PhotoSettingsDefinition.iconPhotoSettingsDefinitionWideRect.image
        case .fullFrameDngJpeg:
            return Asset.BottomBar.PhotoSettingsDefinition.iconPhotoSettingsDefinitionWideWide.image
        }
    }

    var key: String {
        return rawValue
    }

    static var allValues: [BarItemMode] {
        return allCases
    }

    var subModes: [BarItemSubMode]? {
        return nil
    }

    var logKey: String {
        return LogEvent.LogKeyHUDBottomBarButton.photoFormatSetting.name
    }
}

/// Utility extension used to retrieve GroundSdk settings associated with `PhotoFormatMode`.
extension PhotoFormatMode {
    /// Returns `CameraPhotoFormat` associated with current mode.
    var format: Camera2PhotoFormat {
        switch self {
        case .rectilinearJpeg, .rectilinearDngJpeg:
            return .rectilinear
        case .fullFrameJpeg, .fullFrameDngJpeg:
            return .fullFrame
        }
    }

    /// Returns `CameraPhotoFileFormat` associated with current mode.
    var fileFormat: Camera2PhotoFileFormat {
        switch self {
        case .rectilinearJpeg, .fullFrameJpeg:
            return .jpeg
        case .fullFrameDngJpeg, .rectilinearDngJpeg:
            return .dngAndJpeg
        }
    }
}

/// Utility extension for `StartPhotoCaptureCommand.Format`.
extension StartPhotoCaptureCommand.Format {
    /// Returns `PhotoFormatMode` associated with current mode.
    var photoFormat: PhotoFormatMode {
        switch self {
        case .rectilinear,
             .photogrammetry:
            return .rectilinearJpeg
        case .fullFrame:
            return .fullFrameJpeg
        case .fullFrameDng:
            return .fullFrameDngJpeg
        }
    }
}

/// Utility extension for `Camera2` which help to retrieve a PhotoFormatMode.
extension Camera2 {
    /// Returns photo format mode associated with current settings.
    var photoFormatMode: PhotoFormatMode? {
        let format = config[Camera2Params.photoFormat]?.value
        let fileFormat = config[Camera2Params.photoFileFormat]?.value
        switch (format, fileFormat) {
        case (.rectilinear, .jpeg):
            return .rectilinearJpeg
        case (.fullFrame, .jpeg):
            return .fullFrameJpeg
        case (.fullFrame, .dngAndJpeg):
            return .fullFrameDngJpeg
        case (.rectilinear, .dngAndJpeg):
            return .rectilinearDngJpeg
        default:
            return nil
        }
    }

    /// Returns photo format mode supported values for current settings.
    var photoFormatModeSupportedValues: [PhotoFormatMode] {
        let photoFormatSupportedValues = Array(config[Camera2Params.photoFormat]?.currentSupportedValues ?? [])
        let photoFileFormatSupportedValues = Array(config[Camera2Params.photoFileFormat]?.currentSupportedValues ?? [])

        guard !photoFormatSupportedValues.isEmpty,
              !photoFileFormatSupportedValues.isEmpty else {
            return []
        }

        var supportedValues: [PhotoFormatMode] = []
        let photoFormatSupportRectilinear = photoFormatSupportedValues.contains(.rectilinear)
        let photoFormatSupportFullFrame = photoFormatSupportedValues.contains(.fullFrame)
        let photoFileFormatSupportJpeg = photoFileFormatSupportedValues.contains(.jpeg)
        let photoFileFormatSupportDngAndJpeg = photoFileFormatSupportedValues.contains(.dngAndJpeg)

        if photoFormatSupportRectilinear,
           photoFileFormatSupportJpeg {
            supportedValues.append(.rectilinearJpeg)
        }

        if photoFormatSupportFullFrame,
           photoFileFormatSupportJpeg {
            supportedValues.append(.fullFrameJpeg)
        }

        if photoFormatSupportRectilinear,
           photoFileFormatSupportDngAndJpeg {
            supportedValues.append(.rectilinearDngJpeg)
        }

        if photoFormatSupportFullFrame,
           photoFileFormatSupportDngAndJpeg {
            supportedValues.append(.fullFrameDngJpeg)
        }

        return supportedValues
    }
}

/// Utility extension for `Camera2Params` which help to retrieve default camera supported values.
extension Camera2Params {
    /// Gets camera configuration of current drone.
    ///
    /// - Returns: camera configuration, `nil` if unavailable
    private static func currentCameraConfig() -> Camera2Config? {
        // TODO very wrong to access a service here
        guard let camera = Services.hub.currentDroneHolder.drone.currentCamera else {
            ULog.i(.tag, "`mainCamera2` peripheral missing on drone: \(Services.hub.currentDroneHolder.drone.uid)")
            return nil
        }
        return camera.config
    }

    /// Gets supported video recording framerates regarding resolution.
    ///
    /// - Parameter resolution: video recording resolution
    /// - Returns: supported video recording framerates
    static func supportedRecordingFramerate(for resolution: Camera2RecordingResolution) -> [Camera2RecordingFramerate] {
        // create configuration editor starting from scratch
        guard let editor = currentCameraConfig()?.edit(fromScratch: true) else { return [] }

        editor[Camera2Params.videoRecordingResolution]?.value = resolution

        let currentSupportedValues = editor[Camera2Params.videoRecordingFramerate]?.currentSupportedValues ?? []

        let supportedValues = currentSupportedValues.intersection(Camera2RecordingFramerate.availableFramerates)
        return Array(supportedValues).sorted()
    }

    /// Gets supported recording resolutions.
    ///
    /// - Returns: supported video recording framerates
    static func supportedRecordingResolution() -> [Camera2RecordingResolution] {
        guard let config = currentCameraConfig() else { return [] }
        guard let overallSupportedValues = config[Camera2Params.videoRecordingResolution]?.overallSupportedValues else {
            ULog.i(.tag, "`videoRecordingResolution` missing in config: \(config)")
            return []
        }

        let supportedValues = overallSupportedValues.intersection(Camera2RecordingResolution.availableResolutions)
        return Array(supportedValues).sorted()
    }

    /// Gets range of supported photo capture timelapse interval for a given photo resolution.
    ///
    /// - Parameter resolution: photo resolution
    /// - Returns: range of supported values for timelapse interval, `nil` if not supported
    static func supportedTimelapseInterval(for resolution: Camera2PhotoResolution) -> ClosedRange<Double>? {
        // create configuration editor starting from scratch
        guard let editor = currentCameraConfig()?.edit(fromScratch: true) else { return nil }

        editor[Camera2Params.photoResolution]?.value = resolution
        let photoTimelapseInterval = editor[Camera2Params.photoTimelapseInterval]
        return photoTimelapseInterval?.currentSupportedValues
    }

    /// Gets range of supported photo capture timepalse interval in current configuration,
    /// considering camera mode is photo.
    ///
    /// - Returns: range of supported values for timelapse interval, `nil` if not supported
    static func currentSupportedTimelapseInterval() -> ClosedRange<Double>? {
        // create configuration editor starting from current configuration
        guard let editor = currentCameraConfig()?.edit(fromScratch: false) else { return nil }

        // in video recording mode, no timelapse value is supported,
        // so set camera mode in configuration editor to photo
        editor[Camera2Params.mode]?.value = .photo
        return editor[Camera2Params.photoTimelapseInterval]?.currentSupportedValues
    }

    /// Gets range of supported photo capture gpslapse interval in current configuration,
    /// considering camera mode is photo and photo mode is gpslapse.
    ///
    /// - Returns: range of supported values for gpslapse interval, `nil` if not supported
    static func currentSupportedGpslapseInterval() -> ClosedRange<Double>? {
        // create configuration editor starting from current configuration
        guard let editor = currentCameraConfig()?.edit(fromScratch: false) else { return nil }

        // gpslapse values are available only in photo mode and gpslapse mode,
        // so set camera mode and photo mode in configuration editor
        editor[Camera2Params.mode]?.value = .photo
        editor[Camera2Params.photoMode]?.value = .gpsLapse
        return editor[Camera2Params.photoGpslapseInterval]?.currentSupportedValues
    }
}
