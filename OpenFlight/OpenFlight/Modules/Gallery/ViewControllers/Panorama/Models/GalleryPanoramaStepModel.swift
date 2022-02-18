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

typealias GalleryPanoramaStepAction = () -> Void

/// Panorama generation step status possible values.
enum GalleryPanoramaStepStatus {
    case inactive
    case active
    case success
    case failure

    func icon(_ defaultIcon: AssetImageTypeAlias?) -> AssetImageTypeAlias? {
        switch self {
        case .success:
            return Asset.Common.Checks.icChecked.image
        case .active:
            return Asset.Pairing.icloading.image
        default:
            return defaultIcon
        }
    }

    var iconColor: ColorName {
        switch self {
        case .inactive:
            return ColorName.defaultTextColor
        case .active,
             .success:
            return ColorName.highlightColor
        case .failure:
            return ColorName.errorColor
        }
    }

    var textColor: ColorName {
        switch self {
        case .success:
            return ColorName.highlightColor
        default:
            return ColorName.defaultTextColor
        }
    }

    var toProgressStatus: ProgressStatus {
        switch self {
        case .inactive: return .inactive
        case .active: return .active
        case .success: return .succes
        case .failure: return .failure
        }

    }
}

/// Model for panorama step content.
struct GalleryPanoramaStepContentModel {
    // MARK: - Internal Properties
    /// Step icon.
    var icon: UIImage?
    /// Step main text.
    var text: String?
    /// Step error text.
    var errorText: String?
}

enum GalleryPanoramaStepContent {
    case download
    case generate(PanoramaMediaType? = nil)
    case upload(GallerySourceType? = nil)

    var descModel: GalleryPanoramaStepContentModel {
        switch self {
        case .download:
            return GalleryPanoramaStepContentModel(icon: Asset.Gallery.Panorama.icDownloadBig.image,
                                                   text: L10n.galleryPanoramaDownloadingFiles,
                                                   errorText: L10n.galleryPanoramaFilesDownloadError)
        case .generate(let mediaType):
            return GalleryPanoramaStepContentModel(icon: mediaType?.filterImage,
                                                   text: mediaType?.generatingText,
                                                   errorText: L10n.galleryPanoramaGenerationError)
        case .upload(let sourceType):
            return GalleryPanoramaStepContentModel(icon: sourceType?.image ?? UIImage(),
                                                   text: sourceType?.panoramaCopyTitle,
                                                   errorText: L10n.galleryPanoramaCopyError)
        }
    }
}

/// Model for panorama step view.
struct GalleryPanoramaStepModel {
    // MARK: - Internal Properties
    /// Step content.
    var step: GalleryPanoramaStepContent
    /// Step state.
    var status: GalleryPanoramaStepStatus = .inactive
    /// Step action.
    var action: GalleryPanoramaStepAction

    // MARK: - Convenience Computed Properties
    var stateIcon: AssetImageTypeAlias? { status.icon(step.descModel.icon) }
    var iconColor: ColorName { status.iconColor }
    var textColor: ColorName { status.textColor }
}
