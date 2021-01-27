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

import UIKit
import GroundSdk

// MARK: - Internal Enums
/// Enum containing photo formats.

enum PhotoFormatMode: String, BarItemMode, CaseIterable {

    case rectilinearJpeg
    case fullFrameJpeg
    case fullFrameDngRectJpeg
    case fullFrameDngJpeg

    var title: String {
        switch self {
        case .rectilinearJpeg:
            return L10n.photoSettingsFormatJpegRect
        case .fullFrameJpeg:
            return L10n.photoSettingsFormatJpegWide
        case .fullFrameDngJpeg:
            return L10n.photoSettingsFormatDngJpeg
        case .fullFrameDngRectJpeg:
            return L10n.photoSettingsFormatDngJpegRect
        }
    }

    var image: UIImage? {
        return nil
    }

    var key: String {
        return rawValue
    }

    static var allValues: [BarItemMode] {
        return self.allCases
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
        case .rectilinearJpeg, .fullFrameDngRectJpeg:
            return .rectilinear
        case  .fullFrameJpeg, .fullFrameDngJpeg:
            return .fullFrame
        }
    }

    /// Returns `CameraPhotoFileFormat` associated with current mode.
    var fileFormat: Camera2PhotoFileFormat {
        switch self {
        case .rectilinearJpeg, .fullFrameJpeg:
            return .jpeg
        case .fullFrameDngJpeg, .fullFrameDngRectJpeg:
            return .dngAndJpeg
        }
    }

    /// Returns `StartPhotoCaptureCommand.Format` associated with current mode.
    var photoCaptureCommandFormat: StartPhotoCaptureCommand.Format {
        switch self {
        case .rectilinearJpeg, .fullFrameDngRectJpeg:
            return .rectilinear
        case  .fullFrameJpeg:
            return .fullFrame
        case  .fullFrameDngJpeg:
            return .fullFrameDng
        }
    }
}

/// Utility extension for `StartPhotoCaptureCommand.Format`.
extension StartPhotoCaptureCommand.Format {

    /// Returns `PhotoFormatMode` associated with current mode.
    var photoFormat: PhotoFormatMode {
        switch self {
        case .rectilinear:
            return .rectilinearJpeg
        case  .fullFrame:
            return .fullFrameJpeg
        case  .fullFrameDng:
            return .fullFrameDngJpeg
        }
    }
}

/// Utility extension for `Camera2` which help to retrieve a PhotoFormatMode.
extension Camera2 {
    var photoFormatMode: PhotoFormatMode? {
        /// Returns photo format mode associated with current settings.
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
            return .fullFrameDngRectJpeg
        default:
            return nil
        }
    }
}
