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
import SwiftyUserDefaults

/// Utility class mapping `CameraRecordingSettings` and `CameraPhotoSettings` to `CameraCaptureMode`.

final class CameraUtils {

    /// Compute current camera capture mode.
    /// - Parameters:
    ///    - camera: drone camera
    /// Returns current camera capture mode `CameraCaptureMode`.
    static func computeCameraMode(camera: Camera2) -> CameraCaptureMode? {
        guard let cameraMode = camera.mode else { return nil }

        switch cameraMode {
        case .recording:
            return computeVideoMode(camera: camera)
        case .photo:
            return computePhotoMode(camera: camera)
        }
    }

    /// Compute current camera sub-mode.
    /// - Parameters:
    ///    - camera: drone camera
    /// Returns current camera sub-mode `BarItemSubMode`.
    static func computeCameraSubMode(camera: Camera2, forMode cameraMode: CameraCaptureMode) -> BarItemSubMode? {
        switch cameraMode {
        case .bracketing:
            return camera.config[Camera2Params.photoBracketing]?.value.bracketingMode
        case .gpslapse:
            return camera.gpsLapseMode
        case .timelapse:
            return camera.timeLapseMode
        case .panorama:
            return PanoramaMode(rawValue: Defaults[key: PanoramaMode.defaultKey])
        default:
            return nil
        }
    }
}

// MARK: - Private Funcs
private extension CameraUtils {
    static func computeVideoMode(camera: Camera2) -> CameraCaptureMode? {
        guard let videoMode = camera.config[Camera2Params.videoRecordingMode]?.value else { return nil }

        switch videoMode {
        case .standard:
            return .video
        }
    }

    static func computePhotoMode(camera: Camera2) -> CameraCaptureMode? {
        guard let photoMode = camera.config[Camera2Params.photoMode]?.value else { return nil }

        switch photoMode {
        case .timeLapse:
            return .timelapse
        case .gpsLapse:
            return .gpslapse
        case .single:
            return Defaults.isPanoramaModeActivated ? .panorama : .photo
        case .bracketing:
            return .bracketing
        case .burst:
            return .burst
        }
    }
}
