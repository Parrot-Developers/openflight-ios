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

// MARK: - Internal Enums
/// Enum defining camera modes.
public enum CameraCaptureMode: String, BarItemMode, CaseIterable, Equatable {
    case video
    case photo
    case timelapse
    case gpslapse
    case panorama
    case bracketing
    case burst

    public static var allValues: [BarItemMode] {
        return [video, photo, timelapse, gpslapse, panorama, bracketing, burst]
    }

    /// String describing camera capture mode.
    var description: String {
        switch self {
        case .video:
            return "Camera Mode Video"
        case .photo:
            return "Camera Mode Photo"
        case .panorama:
            return "Camera Mode Panorama"
        case .bracketing:
            return "Camera Mode Bracketing"
        case .timelapse:
            return "Camera Mode Timelapse"
        case .gpslapse:
            return "Camera Mode Gpslapse"
        case .burst:
            return "Camera Mode Burst"
        }
    }

    public var title: String {
        switch self {
        case .video:
            return L10n.cameraModeVideo
        case .photo:
            return L10n.cameraModePhoto
        case .panorama:
            return L10n.cameraModePanorama
        case .bracketing:
            return L10n.cameraModeBracketing
        case .timelapse:
            return L10n.cameraModeTimelapse
        case .gpslapse:
            return L10n.cameraModeGpslapse
        case .burst:
            return L10n.cameraModeBurst
        }
    }

    public var image: UIImage? {
        switch self {
        case .video:
            return Asset.BottomBar.CameraModes.icCameraModeVideo.image
        case .photo:
            return Asset.BottomBar.CameraModes.icCameraModePhoto.image
        case .panorama:
            return Asset.BottomBar.CameraModes.icCameraModePano.image
        case .bracketing:
            return Asset.BottomBar.CameraModes.icCameraModeBracketing.image
        case .timelapse:
            return Asset.BottomBar.CameraModes.icCameraModeTimeLapse.image
        case .gpslapse:
            return Asset.BottomBar.CameraModes.icCameraModeGpsLapse.image
        case .burst:
            return Asset.BottomBar.CameraModes.icCameraModeBurst.image
        }
    }

    public var subModes: [BarItemSubMode]? {
        switch self {
        case .bracketing:
            return BracketingMode.allValues as? [BarItemSubMode]
        case .gpslapse:
            return GpsLapseMode.allValues as? [BarItemSubMode]
        case .timelapse:
            return TimeLapseMode.allValues as? [BarItemSubMode]
        case .panorama:
            return PanoramaMode.allValues as? [BarItemSubMode]
        default:
            return nil
        }
    }

    public var key: String {
        return rawValue
    }

    var recordingMode: Camera2VideoRecordingMode? {
        switch self {
        case .video:
            return .standard
        default:
            return nil
        }
    }

    var photoMode: Camera2PhotoMode? {
        switch self {
        case .photo,
             .panorama:
            return .single
        case .bracketing:
            return .bracketing
        case .timelapse:
            return .timeLapse
        case .gpslapse:
            return .gpsLapse
        case .burst:
            return .burst
        default:
            return nil
        }
    }

    public var logKey: String {
        return LogEvent.LogKeyHUDBottomBarButton.imageMode.name
    }
}
