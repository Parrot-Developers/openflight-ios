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
import Reusable
import GroundSdk

// MARK: - GalleryMediaThumbnailViewModel
/// View model used to get a thumbnail image for a given media.
final class GalleryMediaThumbnailViewModel: NSObject {
    // MARK: - Private Properties
    private var thumbnailReference: Ref<UIImage>?
    private var media: GalleryMedia?
    private var mediaStore: MediaStore?
    private var index: Int = 0

    // MARK: - Init
    /// Init the view model based on media parameters.
    ///
    /// - Parameters:
    ///    - media: Gallery Media
    ///    - mediaStore: Media Store
    ///    - index: Media index in the gallery media array image
    public init(media: GalleryMedia, mediaStore: MediaStore?, index: Int) {
        self.media = media
        self.mediaStore = mediaStore
        self.index = index
    }

    /// Get thumbnail image from media.
    ///
    /// - Parameters:
    ///    - completion: completion block
    func getThumbnail(completion: @escaping (UIImage?) -> Void) {
        guard let media = media else { return }
        if let mediaStore = mediaStore,
           let mediaResources = media.mediaResources,
           index < mediaResources.count {
            thumbnailReference = mediaStore.newThumbnailDownloader(resource: mediaResources[index]) { image in
                completion(image)
            }
        } else if let urls = media.urls,
            index < urls.count {
            let isVideo = media.type == .video
            ThumbnailUtils.loadLocalThumbnail(resourceURL: urls[index], isVideo: isVideo) { image in
                completion(image)
            }
        }
    }

}
