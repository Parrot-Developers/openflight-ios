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

/// Used to identify media type.

enum GalleryMediaType: Int {
    case video
    case photo
    case dng
    case burst
    case bracketing
    case gpsLapse
    case timeLapse
    case panoHorizontal
    case panoVertical
    case pano360
    case panoWide

    /// Returns if media type is a panorama.
    var isPanorama: Bool {
        switch self {
        case .pano360,
             .panoWide,
             .panoVertical,
             .panoHorizontal:
            return true
        default:
            return false
        }
    }
}

// MARK: - Internal Properties
extension GalleryMediaType: CaseIterable {
    var stringValue: String {
        switch self {
        case .video:
            return L10n.galleryVideoPathComponent
        case .photo:
            return L10n.galleryPhotoPathComponent
        case .dng:
            return L10n.galleryDngPathComponent
        case .burst:
            return L10n.galleryBurstPathComponent
        case .bracketing:
            return L10n.galleryBracketingPathComponent
        case .gpsLapse:
            return L10n.galleryGpslapsePathComponent
        case .timeLapse:
            return L10n.galleryTimelapsePathComponent
        case .panoHorizontal:
            return L10n.galleryHorizontalPathComponent
        case .panoVertical:
            return L10n.galleryVerticalPathComponent
        case .pano360:
            return L10n.gallerySphericalPathComponent
        case .panoWide:
            return L10n.gallerySuperwidePathComponent
        }
    }
    var filterImage: UIImage? {
        switch self {
        case .video:
            return Asset.BottomBar.CameraModes.icCameraModeVideo.image
        case .photo:
            return Asset.BottomBar.CameraModes.icCameraModePhoto.image
        case .dng:
            return Asset.Gallery.dng.image
        case .burst:
            return Asset.BottomBar.CameraModes.icCameraModeBurst.image
        case .bracketing:
            return Asset.BottomBar.CameraModes.icCameraModeBracketing.image
        case .gpsLapse:
            return Asset.BottomBar.CameraModes.icCameraModeGpsLapse.image
        case .timeLapse:
            return Asset.BottomBar.CameraModes.icCameraModeTimeLapse.image
        case .panoHorizontal:
            return Asset.BottomBar.CameraSubModes.icPanoHorizontal.image
        case .panoVertical:
            return Asset.BottomBar.CameraSubModes.icPanoVertical.image
        case .pano360:
            return Asset.BottomBar.CameraSubModes.icPano360.image
        case .panoWide:
            return Asset.BottomBar.CameraSubModes.icPanoWide.image
        }
    }
    var image: UIImage? {
        switch self {
        case .video:
            return Asset.Gallery.icVideo.image
        case .photo:
            return nil
        case .dng:
            return Asset.Gallery.icDng.image
        case .burst:
            return Asset.Gallery.icBurst.image
        case .bracketing:
            return Asset.Gallery.icBracketing.image
        case .gpsLapse:
            return Asset.Gallery.icGPSLapse.image
        case .timeLapse:
            return Asset.Gallery.icTimelapse.image
        case .panoHorizontal:
            return Asset.Gallery.icPanoH.image
        case .panoVertical:
            return Asset.Gallery.icPanoV.image
        case .pano360:
            return Asset.Gallery.icPano360.image
        case .panoWide:
            return Asset.Gallery.icWide.image
        }
    }
    var pathExtension: String {
        switch self {
        case .photo:
            return MediaItem.Format.jpg.description.uppercased()
        case .dng:
            return MediaItem.Format.dng.description.uppercased()
        case .video:
            return MediaItem.Format.mp4.description.uppercased()
        default:
            return ""
        }
    }
    var preferredWidth: CGFloat {
        switch self {
        case .video:
            return 14.0
        case .photo:
            return 11.0
        case .dng:
            return 22.0
        default:
            return 20.0
        }
    }
    var preferredHeight: CGFloat {
        switch self {
        case .video,
             .photo:
            return 9.0
        case .dng:
            return 15.0
        default:
            return 20.0
        }
    }

    /// Returns a PanoramaMediaType according to a GalleryMediaType.
    var toPanoramaType: PanoramaMediaType? {
        switch self {
        case .panoHorizontal:
            return .horizontal
        case .panoVertical:
            return .vertical
        case .panoWide:
            return .superWide
        case .pano360:
            return .sphere
        default:
            return nil
        }
    }
}
