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

/// ViewModel for panoramas.

final class GalleryPanoramaViewModel: NSObject {
    // MARK: - Internal Properties
    weak var galleryViewModel: GalleryMediaViewModel?
    var selectedPanoramaMediaType: PanoramaMediaType?
    var selectedPanoramaQuality: PanoramaQuality?

    // MARK: - Init
    ///
    /// - Parameters:
    ///    - galleryViewModel: gallery view model
    init(galleryViewModel: GalleryMediaViewModel?) {
        super.init()
        self.galleryViewModel = galleryViewModel
    }

    /// Update panorama download and generation step models.
    ///
    /// - Parameters:
    ///   - downloadState: current media download state.
    ///   - panoType: current media panorama type.
    ///   - panoGenerationStatus: current media panorama generation status.
    /// - Returns: an array of GalleryPanoramaStepModel.
    func updatePanoramaGenerationModels(downloadState: GalleryMediaDownloadState,
                                        panoType: PanoramaMediaType,
                                        _ panoGenerationStatus: PhotoPanoProcessingStatus? = nil) -> [GalleryPanoramaStepModel] {
        var modelArray: [GalleryPanoramaStepModel] = []

        switch downloadState {
        case .toDownload,
             .downloading:
            modelArray.append(GalleryPanoramaStepModel(image: Asset.Gallery.Panorama.icDownloadHighlighted.image,
                                                       text: L10n.galleryPanoramaDownloadingFiles,
                                                       textColor: ColorName.greenSpring))

            modelArray.append(GalleryPanoramaStepModel(image: panoType.image,
                                                       text: panoType.generatingText,
                                                       textColor: ColorName.white))
        default:
            modelArray.append(GalleryPanoramaStepModel(image: Asset.Common.Checks.icChecked.image,
                                                       text: L10n.galleryPanoramaDownloadingFiles,
                                                       textColor: ColorName.greenSpring))
            panoGenerationStatus == .success
                ? modelArray.append(GalleryPanoramaStepModel(image: Asset.Common.Checks.icChecked.image,
                                                             text: panoType.generatingText,
                                                             textColor: ColorName.greenSpring))
                : modelArray.append(GalleryPanoramaStepModel(image: panoType.image,
                                                             text: panoType.generatingText,
                                                             textColor: ColorName.greenSpring))

        }
        return modelArray
    }
}
