//    Copyright (C) 2022 Parrot Drones SAS
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
import Combine

/// A photo viewer zoom level.
enum PhotoViewerZoomLevel {

    /// Level is minimum.
    case minimum
    /// Level is maximum.
    case maximum
    /// Level is any value between minimum and maxium.
    case custom

    /// Toggles current zoom level.
    mutating func toggle() {
        self = self == .minimum ? .maximum : .minimum
    }
}

/// A photo viewer view model.
final class PhotoViewerViewModel {

    /// The media to display.
    @Published private(set) var media: GalleryMedia
    /// The zoom level.
    @Published private(set) var zoomLevel: PhotoViewerZoomLevel = .minimum

    /// The cancellables.
    private var cancellables = Set<AnyCancellable>()

    // MARK: Init
    /// Constructor.
    ///
    /// - Parameters:
    ///    - mediaListService: the media list service
    ///    - media: the media to display
    init(mediaListService: MediaListService, media: GalleryMedia) {
        self.media = media

        listen(to: mediaListService)
    }

    /// The number of items to display in viewer (extra item is needed in case of a non-generated panorama media).
    var itemsCount: Int {
        // `resourcesCount` can be 0 if a media only contains non-previewable resources.
        // => Ensure at least 1 empty cell is displayed (in order to still be able to delete/share
        //    the non-previewable resource).
        return max(1, media.needsPanoGeneration ? media.previewableResourcesCount + 1 : media.previewableResourcesCount)
    }

    /// Returns the photo viewer cell type according to the item index.
    ///
    /// - Parameter item: the item index
    /// - Returns: the photo viewer cell typ
    func cellType(for item: Int) -> PhotoViewerCellType {
        // Specific cell type only concerns first item of the resources collection.
        if item != 0 {
            return .photo
        }

        if media.needsPanoGeneration {
            // Active media is a non-generated panorama.
            // => Update type according to the generation capability.
            switch media.panoramaGenerationState {
            case .missingResources: return .panoGen(isValid: false)
            case .toGenerate: return .panoGen(isValid: true)
            case .none: return .photo
            }
        } else {
            return media.isSphericalPanorama ? .immersivePano : .photo
        }
    }

    /// Returns the media resource URL (if existing) for a specific item index.
    ///
    /// - Parameter item: the item index
    /// - Returns: the media resource URL (if existing)
    func resourceUrl(for item: Int) -> URL? {
        media.resourceUrl(at: resourceIndex(for: item))
    }

    /// The resource index for a specific item (may differ from item index itself in case of additional panoGen item).
    ///
    /// - Parameter item: the item index
    /// - Returns: the resource index
    func resourceIndex(for item: Int) -> Int {
        if !media.needsPanoGeneration {
            // Default case, use actual item index.
            return item
        }

        if item == 0 {
            // PanoGen item, use default resource index.
            return media.defaultResourceIndex
        }

        // Non-generated panorama resource item, use actual item index minus 1 because
        // of additional panoGen item.
        return max(0, item - 1)
    }

    /// Toggles zoom level.
    func didDoubleTap() {
        zoomLevel.toggle()
    }

    /// Sets zoom level.
    ///
    /// - Parameter level: the zoom level to set
    func setZoomLevel(to level: PhotoViewerZoomLevel) {
        zoomLevel = level
    }
}

private extension PhotoViewerViewModel {

    /// Listens to media list service in order to update states accordingly.
    ///
    /// - Parameter mediaListService: the media list service
    func listen(to mediaListService: MediaListService) {
        mediaListService.mediaListPublisher
            .sink { [weak self] list in
                self?.updateMedia(from: list)
            }
            .store(in: &cancellables)
    }

    /// Updates media if it differs from corresponding item in provided list.
    ///
    /// - Parameter list: the list containing the media to compare to
    func updateMedia(from list: [GalleryMedia]) {
        if let media = list.first(where: { $0.isSameMedia(as: self.media) }), self.media != media {
            self.media = media
        }
    }
}
