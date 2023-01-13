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

import Combine
import GroundSdk

private extension ULogTag {
    static let tag = ULogTag(name: "MediaStoreService")
}

/// A media store error.
public enum MediaStoreError: Error {

    /// Generic prefetch error.
    case prefetchError
    /// Resource URL not found.
    case resourceUrlNotFound
    /// Unable to download preview.
    case cannotDownloadPreview
    /// Unable to delete media.
    case cannotDeleteMedia
    /// Unable to upload media.
    case cannotUploadMedia
}

// MARK: - Protocol

/// The protocol defining the media store service.
public protocol MediaStoreService: AnyObject {

    // MARK: Store
    /// The publisher for media store's indexing state.
    var indexingStatePublisher: AnyPublisher<MediaStoreIndexingState, Never> { get }

    // MARK: Media List
    /// The publisher for media items list.
    var itemsListPublisher: AnyPublisher<[GalleryMedia], Never> { get }

    // MARK: Download
    /// The download task state publisher.
    var downloadTaskStatePublisher: AnyPublisher<(progress: Float?, status: MediaTaskStatus?), Never> { get }
    /// The publisher for the identifiers of the medias currently downloaded.
    var downloadIdsPublisher: AnyPublisher<[(uid: String, customTitle: String?)], Never> { get }
    /// The publisher for  an ongoing download task.
    var isDownloadingPublisher: AnyPublisher<Bool, Never> { get }
    /// Whether a download task is ongoing.
    var isDownloading: Bool { get }

    /// Whether a specific uid belongs to current download request.
    ///
    /// - Parameter uid: the uid to check
    /// - Returns: whether the uid belongs to current download request
    func isDownloading(uid: String) -> Bool

    /// Requests a download of a `MediaResourceList` to the media store in full mode.
    ///
    /// - Parameter items: the media items to download
    /// - Returns: an async stream tracking the download status
    func download(items: [MediaItem]) -> AsyncStream<MediaTaskStatus>

    /// Requests a download of a `MediaResourceList` to the media store in preview mode.
    ///
    /// - Parameter mediaResources: the resources to download
    /// - Returns: an async stream tracking the download status
    func downloadPreviews(mediaResources: MediaResourceList) -> AsyncStream<MediaTaskStatus>

    /// Requests a download of a `MediaResourceList` to the media store in preview mode and yields the
    /// downloaded URL after the resource with `resId` uid has been downloaded.
    ///
    /// - Parameters:
    ///    - resId: the resource uid triggering the URL yielding
    ///    - mediaResources: the resources to download
    /// - Returns: an async stream returning the downloaded URL of the `resId` resource
    func downloadPreviews(resId: String, mediaResources: MediaResourceList) -> AsyncThrowingStream<URL?, Error>

    /// Cancels any ongoing download.
    func cancelDownload()

    // MARK: Delete
    /// The publisher for the UID of the medias currently deleted.
    var deleteUidsPublisher: AnyPublisher<Set<String>, Never> { get }
    /// Whether a media or one of its resources belongs to current delete request.
    ///
    /// - Parameter media: the media to check
    /// - Returns: whether the media itself or one of its resources belong to current delete request
    func isDeleting(media: GalleryMedia) -> Bool
    /// Requests deletion of a `MediaItem`s array to the media store.
    ///
    /// - Parameter items: the media items to delete
    func delete(items: [MediaItem]) async throws
    /// Requests deletion of a specific resources array from a `MediaItem` to the media store.
    ///
    /// - Parameters:
    ///    - indexes: the indexes of the resources to delete
    ///    - item: the media item containing the resources to delete
    func deleteResourcesAt(_ indexes: [Int], from item: MediaItem) async throws

    // MARK: Upload
    /// The upload task state publisher.
    var uploadTaskStatePublisher: AnyPublisher<(progress: Float?, status: MediaTaskStatus?), Never> { get }

    /// Requests upload of an array of resources URLs to a specific `MediaItem`.
    ///
    /// - Parameters:
    ///    - urls: the urls of the resources to upload to the media
    ///    - mediaItem: the media item to update with the uploaded resources
    /// - Returns: an async stream tracking the upload status
    func upload(urls: [URL], to mediaItem: MediaItem) -> AsyncStream<MediaTaskStatus>

    /// Cancels any ongoing upload.
    func cancelUpload()
}
