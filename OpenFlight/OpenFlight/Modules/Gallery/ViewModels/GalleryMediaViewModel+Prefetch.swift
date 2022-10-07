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

import Foundation
import GroundSdk

// An enum describing the media prefetch sequence status.
public enum MediaPrefetchStatus: Int, CustomStringConvertible {
    /// Full prefetch completed successfully.
    case complete
    /// Prefetch stopped or canceled.
    case error
    /// Current resource has been successfully prefetched.
    case resourceFetched

    /// Debug description.
    public var description: String {
        switch self {
        case .complete:
            return "complete"
        case .resourceFetched:
            return "resourceFetched"
        case .error:
            return "error"
        }
    }
}

extension GalleryMediaViewModel {
    // MARK: - Constants
    struct Constants {
        static let mediasPrefetchSize = 2
        static let resourcesInitPrefetchSize = 2
        static let resourcesFullPrefetchSize = 4
    }

    // MARK: - Prefetch Functions

    /// Returns an async throwing stream sequence which downloads a range of contiguous resources previews from `media`.
    /// The range is built in order to first download resource from `resourceIndex`, and then the `Constants.resourcesFullPrefetchSize`
    /// resources located after, and then before.
    ///
    /// - Parameters:
    ///    - media: the media containing the resources to preview-download
    ///    - resourceIndex: the index of the main resource
    /// - Returns: the async throwing stream download sequence
    func prefetchResources(media: GalleryMedia, at resourceIndex: Int) -> AsyncThrowingStream<MediaTaskStatus, Error> {
        AsyncThrowingStream { continuation in
            guard let viewModel = sdCardViewModel,
                  let mediaItem = media.mediaItem(for: resourceIndex),
                  let resources = media.previewableResources,
                  resourceIndex < resources.count else {
                continuation.finish(throwing: GalleryMediaError.mediaPrefetchError)
                return
            }

            // Create the resources array.
            // Add main resource first.
            var resourcesToFetch = [resources[resourceIndex]]

            // Create before and after prefetch ranges.
            let fromIndex = resourceIndex - Constants.resourcesFullPrefetchSize
            let toIndex = resourceIndex + Constants.resourcesFullPrefetchSize + 1
            let fromRange = (fromIndex..<resourceIndex)
                .clamped(to: 0..<resources.count)
            let toRange = (resourceIndex + 1..<toIndex + 1)
                .clamped(to: 0..<resources.count)

            // Append 'after' range first, as we prioritize "next item"-scrolling.
            resourcesToFetch.append(contentsOf: resources[toRange])
            // Append 'before' range in reversed order in order to fetch closest resources first.
            resourcesToFetch.append(contentsOf: resources[fromRange].reversed())
            // Remove any resource already present in cache.
            resourcesToFetch = resourcesToFetch.filter({ !$0.cachedImgUrlExist(droneId: drone?.uid) })

            guard !resourcesToFetch.isEmpty else {
                // All resources are already in cache => finish sequence.
                continuation.yield(.fileDownloaded)
                continuation.finish()
                return
            }

            // Create downloadable resources list from resources to fetch array.
            let mediaResources = MediaUtils.convertMediaResourcesToResourceList(mediaItem: mediaItem,
                                                                                resources: resourcesToFetch,
                                                                                onlyDownloadable: true)

            // Start previews download async sequence and await for its status.
            Task {
                // Do not specify any media uid for `.fileDownloaded` yield condition, as:
                // - `prefetchResources` function is only called during resources browsing on currently displayed media,
                // - media uid can differ within a single media item in case of PGY (each segment creates a dedicated
                //   media item with its own uid that can differ from main media's, which would lead a uid check
                //   between downloader item and current media item uids to fail).
                for await status in viewModel.downloadPreviews(mediaResources: mediaResources) {
                    guard status != .error else {
                        continuation.finish(throwing: GalleryMediaError.mediaPrefetchResourceNotFound)
                        return
                    }

                    continuation.yield(status)

                    if status == .complete {
                        continuation.finish()
                    }
                }
            }
        }
    }

    /// Returns an async throwing stream sequence which downloads a range of resources previews continguous to `media`.
    /// The range is built in order to first download the`Constants.resourcesInitPrefetchSize` first resources of `media`,
    /// and then the first resource of `Constants.mediasPrefetchSize` medias alternatively located after and before.
    ///
    /// - Parameters:
    ///    - media: the main media
    ///    - resourceIndex: the index of the main media
    /// - Returns: the async throwing stream download sequence
    func prefetchMedias(media: GalleryMedia, mediaIndex: Int) -> AsyncThrowingStream<MediaTaskStatus, Error> {
        AsyncThrowingStream { continuation in
            guard let viewModel = sdCardViewModel,
                  let mainMediaItem = media.mainMediaItem,
                  let droneId = drone?.uid else {
                continuation.finish(throwing: GalleryMediaError.mediaPrefetchError)
                return
            }

            // Create the medias info array.
            // Add `Constants.resourcesInitPrefetchSize` main resources first.
            var medias = [(mainMediaItem, Constants.resourcesInitPrefetchSize)]

            // Alternatively add first resource of next and previous medias, from closest to farthest media.
            for offset in 1...Constants.mediasPrefetchSize {
                if let nextMediaItem = getFilteredMedia(index: mediaIndex + offset)?.mainMediaItem {
                    medias.append((nextMediaItem, 1))
                }
                if let prevMediaItem = getFilteredMedia(index: mediaIndex - offset)?.mainMediaItem {
                    medias.append((prevMediaItem, 1))
                }
            }

            // Create downloadable resources list from medias info array.
            let mediaResources = MediaUtils.getDownloadablePreviewableResources(medias: medias, droneId: droneId)

            // Start previews download async sequence and await for its status.
            Task {
                for await status in viewModel.downloadPreviews(mediaUid: media.uid, mediaResources: mediaResources) {
                    guard status != .error else {
                        continuation.finish(throwing: GalleryMediaError.mediaPrefetchResourceNotFound)
                        return
                    }

                    continuation.yield(status)

                    if status == .complete {
                        continuation.finish()
                    }
                }
            }
        }
    }
}
