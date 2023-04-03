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
    static let tag = ULogTag(name: "MediaListService")
}

// MARK: - Protocol

/// The protocol defining the media list service.
public protocol MediaListService: AnyObject {

    /// The publisher for the media list.
    var mediaListPublisher: AnyPublisher<[GalleryMedia], Never> { get }

    /// Returns the media downloaded on device's memory (if existing) corresponding to a specific media.
    /// Media provided as parameter will be returned if it already is located on device's memory,
    /// drone's memory with same UID and drone's UID will be returned otherwise.
    ///
    /// - Parameter media: the media to look for
    /// - Returns: the corresponding device's memory media (if existing)
    func deviceMedia(for media: GalleryMedia) -> GalleryMedia?

    /// Updates active media list according to selected storage source.
    func updateActiveMediaList()

    /// Sets active storage source.
    ///
    /// - Parameter source: the gallery source type
    func setStorageSource(_ source: GallerySourceType)

    /// Requests a download of a gallery medias array to media store.
    ///
    /// - Parameter medias: the media array to download
    /// - Returns: an async stream tracking the download status
    func download(medias: [GalleryMedia]) -> AsyncStream<MediaTaskStatus>

    /// Gets the action state of a specific media.
    ///
    /// - Parameter media: the media to check
    /// - Returns: the action state of the media
    func actionState(of media: GalleryMedia) -> GalleryMediaActionState

    /// Deletes a medias array.
    ///
    /// - Parameter medias: the medias to delete
    func delete(medias: [GalleryMedia]) async throws

    /// Requests a deletion of a specific resources array from a gallery media.
    ///
    /// - Parameters:
    ///    - media: the gallery media containing the resources to delete
    ///    - indexes: the indexes of the resources to delete
    func deleteResources(of media: GalleryMedia, at indexes: [Int]) async throws

    /// Fetches a media's resource image located at a specific index.
    ///
    /// - Parameters:
    ///    - media: the media containing the resource to fetch
    ///    - resourceIndex: the index of the resource to fetch
    ///    - delay: the delay to wait before triggering fetching (optional)
    /// - Returns: the image of the resource to fetch
    func fetchResource(of media: GalleryMedia,
                       at resourceIndex: Int,
                       after delay: TimeInterval?) async throws -> UIImage?
}

// MARK: - Implementation

/// An implementation of the `MediaListService` protocol.
public class MediaListServiceImpl {

    // MARK: - Private Properties
    /// The cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// The media store service.
    private let mediaStoreService: MediaStoreService
    /// The media list subject.
    private var mediaListSubject = CurrentValueSubject<[GalleryMedia], Never>([])
    /// The drone media list.
    private var droneMedias = [GalleryMedia]()
    /// The device media list.
    private var deviceMedias: [GalleryMedia] { AssetUtils.shared.medias }
    /// The active storage source type.
    private var storageSource: GallerySourceType = .mobileDevice {
        didSet { updateActiveMediaList() }
    }

    // MARK: Init
    /// Constructor.
    ///
    /// - Parameters:
    ///    - mediaStoreService: the media store service
    ///    - userStorageService: the user storage service
    init(mediaStoreService: MediaStoreService) {
        self.mediaStoreService = mediaStoreService

        listenToMediaStoreService(mediaStoreService)
    }
}

// MARK: `MediaListService` protocol conformance
extension MediaListServiceImpl: MediaListService {

    /// The publisher for the media list.
    public var mediaListPublisher: AnyPublisher<[GalleryMedia], Never> { mediaListSubject.eraseToAnyPublisher() }

    /// Returns the media downloaded on device's memory (if existing) corresponding to a specific media.
    /// Media provided as parameter will be returned if it already is located on device's memory,
    /// drone's memory with same UID and drone's UID will be returned otherwise.
    ///
    /// - Parameter media: the media to look for
    /// - Returns: the corresponding device's memory media (if existing)
    public func deviceMedia(for media: GalleryMedia) -> GalleryMedia? {
        deviceMedias.mediaWith(uid: media.uid, droneUid: media.droneUid)
    }

    /// Updates active media list according to selected storage source.
    public func updateActiveMediaList() {
        if storageSource.isDeviceSource {
            updateMediaList(with: deviceMedias)
        } else if storageSource.isDroneSource {
            updateMediaList(with: droneMedias)
        }
    }

    /// Sets active storage source.
    ///
    /// - Parameter source: the gallery source type
    public func setStorageSource(_ source: GallerySourceType) {
        storageSource = source
        updateActiveMediaList()
    }

    /// Requests a download of a gallery medias array to media store.
    ///
    /// - Parameter medias: the media array to download
    /// - Returns: an async stream tracking the download status
    public func download(medias: [GalleryMedia]) -> AsyncStream<MediaTaskStatus> {
        mediaStoreService.download(items: medias.mediaItems)
    }

    /// Gets the action state of a specific media.
    ///
    /// - Parameter media: the media to check
    /// - Returns: the action state of the media
    public func actionState(of media: GalleryMedia) -> GalleryMediaActionState {
        mediaStoreService.isDownloading(uid: media.uid) ? .downloading :
        mediaStoreService.isDeleting(media: media) ? .deleting :
        media.isDownloaded ? .downloaded : .toDownload
    }

    /// Requests a deletion of a specific resources array from a gallery media.
    ///
    /// - Parameters:
    ///    - media: the gallery media containing the resources to delete
    ///    - indexes: the indexes of the resources to delete
    ///
    /// The drone media list is supposed to be updated by `mediaStoreService.itemsListPublisher`.
    /// The `updateActiveMediaList` call in device media list case (`else` part) is required because of the way local medias are handled (there's no update event on delete in this case).
    ///
    /// - Remark: `mediaStoreService.deleteResourcesAt` will trigger a media store delete request, which should trigger a `mediaStoreService.itemsListPublisher` event once deletion is completed.
    public func deleteResources(of media: GalleryMedia, at indexes: [Int]) async throws {
        if storageSource.isDroneSource {
            guard let item = media.mainMediaItem else { return }
            try await mediaStoreService.deleteResourcesAt(indexes, from: item)
        } else {
            try await AssetUtils.shared.removeResources(at: indexes, from: media)
            // Need to refresh device's media list, as there's no automatic update listener for device storage.
            updateActiveMediaList()
        }
    }

    /// Requests a deletion of a specific gallery media array.
    ///
    /// - Parameter medias: the media array to delete
    public func delete(medias: [GalleryMedia]) async throws {
        if storageSource.isDroneSource {
            try await mediaStoreService.delete(items: medias.mediaItems)
        } else {
            try await AssetUtils.shared.removeMedias(medias: medias)
            updateActiveMediaList()
        }
    }

    /// Fetches a media's resource image located at a specific index.
    ///
    /// - Parameters:
    ///    - media: the media containing the resource to fetch
    ///    - resourceIndex: the index of the resource to fetch
    ///    - delay: the delay to wait before triggering fetching (optional)
    /// - Returns: the image of the resource to fetch
    public func fetchResource(of media: GalleryMedia,
                              at resourceIndex: Int,
                              after delay: TimeInterval? = nil) async throws -> UIImage? {
        if let url = media.resourceUrl(at: resourceIndex) {
            // URL already exists for selected resource => load image from cache or device's memory.
            return try await loadImage(url: url)
        }

        // Ensure resource index is valid.
        guard let mediaItem = media.mediaItem(for: resourceIndex),
              let resources = media.previewableResources,
              resourceIndex < resources.count else {
            return nil
        }

        // Build list (1 item) to pass to media store downloader.
        let mediaResource = MediaUtils.convertMediaResourcesToResourceList(mediaItem: mediaItem,
                                                                           resources: [resources[resourceIndex]],
                                                                           onlyDownloadable: true)

        if let delay = delay {
            try await Task.sleep(nanoseconds: UInt64(delay))
        }

        // Download preview and gather URL.
        for try await url in mediaStoreService.downloadPreviews(resId: resources[resourceIndex].uid,
                                                                mediaResources: mediaResource) {
            return try await loadImage(url: url)
        }

        return nil
    }
}

private extension MediaListServiceImpl {

    /// Listens to media store service in order to update states accordingly.
    ///
    /// - Parameter mediaStoreService: the media store service
    func listenToMediaStoreService(_ mediaStoreService: MediaStoreService) {
        mediaStoreService.itemsListPublisher
            .sink { [weak self] items in
                self?.updateDroneMediaList(items: items)
            }
            .store(in: &cancellables)

        mediaStoreService.downloadIdsPublisher
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.storageSource.isDeviceSource {
                    // Need to refresh device's media list at `downloadIds` events, as there's no automatic update listener for device storage.
                    self.updateMediaList(with: self.deviceMedias)
                }
            }
            .store(in: &cancellables)
    }
}

private extension MediaListServiceImpl {

    // MARK: Media List
    /// Updates drone media list state.
    ///
    /// - Parameter list: the media items list
    func updateDroneMediaList(items: [GalleryMedia]) {
        // Update local drone media list.
        droneMedias = items

        // Update active media list if current source is drone.
        guard storageSource.isDroneSource else { return }
        updateMediaList(with: droneMedias)
    }

    /// Updates active media list with provided media array.
    ///
    /// - Parameter medias: the media array
    func updateMediaList(with medias: [GalleryMedia]) {
        mediaListSubject.value = medias
    }

    /// Loads an image stored in cache or device's memory based on its URL.
    ///
    /// - Parameter url: the URL of the image to load.
    /// - Returns: the image located at `url` (if any)
    @MainActor
    func loadImage(url: URL?) async throws -> UIImage? {
        try await withCheckedThrowingContinuation { continuation in
            guard let url = url, url.pathExtension == GalleryMediaType.photo.pathExtension else {
                continuation.resume(throwing: MediaStoreError.prefetchError)
                return
            }

            AssetUtils.shared.loadImage(withURL: url) { image in
                continuation.resume(returning: image)
            }
        }
    }
}
