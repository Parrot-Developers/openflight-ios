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

// MARK: - Implementation

/// An implementation of the `MediaStoreService` protocol.
public class MediaStoreServiceImpl {

    /// The current drone holder.
    private let currentDroneHolder: CurrentDroneHolder
    /// The cancellables.
    private var cancellables = Set<AnyCancellable>()

    // MARK: Store
    /// The media store reference.
    private var mediaStoreRef: Ref<MediaStore>?
    /// The media store indexing state subject.
    private let indexingStateSubject = CurrentValueSubject<MediaStoreIndexingState, Never>(.unavailable)

    // MARK: Media List
    /// The media list reference.
    private var itemsListRef: Ref<[MediaItem]>?
    /// The media items list subject.
    private let itemsListSubject = CurrentValueSubject<[GalleryMedia], Never>([])

    // MARK: Download
    /// The downloader reference.
    private var downloaderRef: Ref<MediaDownloader>?
    /// The preview downloader reference.
    private var previewDownloaderRequest: Ref<MediaDownloader>?
    /// The current download task's state subject.
    private let downloadTaskStateSubject = CurrentValueSubject<(progress: Float?, status: MediaTaskStatus?), Never>((nil, nil))
    /// The identifiers of the medias currently downloaded.
    private let downloadIdsSubject = CurrentValueSubject<[(uid: String, customTitle: String?)], Never>([])
    /// The ongoing download task subject.
    private let isDownloadingSubject = CurrentValueSubject<Bool, Never>(false)

    // MARK: Delete
    /// The deleter reference.
    private var deleterRef: Ref<MediaDeleter>?
    /// The UIDs of the medias currently deleted.
    private let deleteUidsSubject = CurrentValueSubject<Set<String>, Never>([])

    // MARK: Upload
    /// The uploader reference.
    private var uploaderRef: Ref<ResourceUploader>?
    /// The current upload task's state subject.
    private let uploadTaskStateSubject = CurrentValueSubject<(progress: Float?, status: MediaTaskStatus?), Never>((nil, nil))

    // MARK: Init
    /// Constructor.
    ///
    /// - Parameter currentDroneHolder: the current drone holder
    init(currentDroneHolder: CurrentDroneHolder) {
        self.currentDroneHolder = currentDroneHolder
        listenTo(currentDroneHolder)
    }
}

// MARK: `MediaStoreService` protocol conformance
extension MediaStoreServiceImpl: MediaStoreService {

    // MARK: Store
    /// The publisher for media store's indexing state.
    public var indexingStatePublisher: AnyPublisher<MediaStoreIndexingState, Never> { indexingStateSubject.eraseToAnyPublisher() }

    // MARK: Media List
    /// The publisher for media items list.
    public var itemsListPublisher: AnyPublisher<[GalleryMedia], Never> { itemsListSubject.eraseToAnyPublisher() }

    // MARK: Download
    /// The publisher for current download task state.
    public var downloadTaskStatePublisher: AnyPublisher<(progress: Float?, status: MediaTaskStatus?), Never> { downloadTaskStateSubject.eraseToAnyPublisher() }
    /// The publisher for the identifiers of the medias currently downloaded.
    public var downloadIdsPublisher: AnyPublisher<[(uid: String, customTitle: String?)], Never> { downloadIdsSubject.eraseToAnyPublisher() }
    /// The publisher for  an ongoing download task.
    public var isDownloadingPublisher: AnyPublisher<Bool, Never> { isDownloadingSubject.eraseToAnyPublisher() }
    /// Whether a download task is ongoing.
    public var isDownloading: Bool { isDownloadingSubject.value }

    // MARK: Delete
    /// The publisher for the identifiers of the medias currently deleted.
    public var deleteUidsPublisher: AnyPublisher<Set<String>, Never> { deleteUidsSubject.eraseToAnyPublisher() }

    // MARK: Upload
    /// The publisher for current upload task state.
    public var uploadTaskStatePublisher: AnyPublisher<(progress: Float?, status: MediaTaskStatus?), Never> { uploadTaskStateSubject.eraseToAnyPublisher() }

    /// Whether a specific uid belongs to current download request.
    ///
    /// - Parameter uid: the uid to check
    /// - Returns: whether the uid belongs to current download request
    public func isDownloading(uid: String) -> Bool {
        downloadIds.contains(where: { $0.uid == uid })
    }

    /// Requests download of a `MediaItem`s array to the media store.
    ///
    /// - Parameter items: the media items to download
    /// - Returns: an async stream tracking the download status
    public func download(items: [MediaItem]) -> AsyncStream<MediaTaskStatus> {
        AsyncStream { continuation in
            guard let mediaStore = mediaStore else {
                continuation.yield(.error)
                continuation.finish()
                return
            }

            // Init identifiers array of items to be downloaded.
            initDownloadIds(from: items)

            let mediaResources = MediaUtils.getDownloadableResources(items: items)
            let destination = DownloadDestination.document(directoryName: "\(Paths.mediasDirectory)/\(droneUid)")

            // Get media store downloader reference (potential ongoing preview download request will be canceled).
            downloaderRef = mediaStore.newDownloader(
                mediaResources: mediaResources,
                type: DownloadType.full,
                destination: destination) { mediaDownloader in
                    guard let mediaDownloader = mediaDownloader else {
                        // Report error and finish sequence, as download may never be complete.
                        self.downloadState = (nil, .error)
                        self.clearDownloadIds()
                        continuation.yield(.error)
                        continuation.finish()
                        return
                    }

                    // Update download state.
                    self.downloadState = (mediaDownloader.totalProgress, mediaDownloader.status)

                    // Handle current status.
                    switch mediaDownloader.status {
                    case .fileDownloaded:
                        guard let fileUrl = mediaDownloader.fileUrl else {
                            self.clearDownloadIds()
                            continuation.yield(.error)
                            continuation.finish()
                            return
                        }

                        self.saveMedia(fileUrl: fileUrl,
                                       signatureFileUrl: mediaDownloader.signatureUrl,
                                       media: mediaDownloader.currentMedia)
                        self.removeFromDownloadIds(identifier: (mediaDownloader.currentMedia?.uid, mediaDownloader.currentMedia?.customTitle))
                        continuation.yield(.fileDownloaded)

                    case .error:
                        self.clearDownloadIds()
                        continuation.yield(.error)
                        // Should only yield continuation (with `.error` status) here. Unfortunately `newDownloader` currently
                        // interrupts download as soon as an error is met.
                        continuation.finish()

                    case .complete:
                        self.clearDownloadIds()
                        continuation.yield(.complete)
                        continuation.finish()

                    default:
                        break
                    }
                }
        }
    }

    /// Requests a download of a `MediaResourceList` to the media store in preview mode.
    ///
    /// - Parameter mediaResources: the resources to download
    /// - Returns: an async stream tracking the download status
    public func downloadPreviews(mediaResources: MediaResourceList) -> AsyncStream<MediaTaskStatus> {
        AsyncStream { continuation in
            guard let imgUrl = MediaItem.Resource.previewDirectoryUrl(droneId: droneUid),
                  let mediaStore = mediaStore else {
                continuation.yield(.error)
                continuation.finish()
                return
            }

            // Get media store downloader reference (potential ongoing preview download request will be canceled).
            previewDownloaderRequest = mediaStore.newDownloader(
                mediaResources: mediaResources,
                type: DownloadType.preview,
                destination: .directory(path: imgUrl.path)) { mediaDownloader in
                    guard let downloadStatus = mediaDownloader?.status else {
                        // Unknown status => report error and finish sequence, as download may never be complete.
                        continuation.yield(.error)
                        continuation.finish()
                        return
                    }

                    switch downloadStatus {
                    case .fileDownloaded:
                        continuation.yield(.fileDownloaded)

                    case .error:
                        continuation.yield(.error)
                        // Should only yield continuation (with `.error` status) here. Unfortunately `newDownloader` currently
                        // interrupts download as soon as an error is met.
                        continuation.finish()

                    case .complete:
                        continuation.yield(.complete)
                        continuation.finish()

                    default:
                        break
                    }
                }
        }
    }

    /// Requests a download of a `MediaResourceList` to the media store in preview mode and yields the
    /// downloaded URL after the resource with `resId` uid has been downloaded.
    ///
    /// - Parameters:
    ///    - resId: the resource uid triggering the URL yielding
    ///    - mediaResources: the resources to download
    /// - Returns: an async stream returning the downloaded URL of the `resId` resource
    public func downloadPreviews(resId: String, mediaResources: MediaResourceList) -> AsyncThrowingStream<URL?, Error> {
        AsyncThrowingStream { continuation in
            guard let imgUrl = MediaItem.Resource.previewDirectoryUrl(droneId: droneUid),
                  let mediaStore = mediaStore else {
                continuation.finish(throwing: MediaStoreError.cannotDownloadPreview)
                return
            }

            // Get media store downloader reference (potential ongoing preview download request will be canceled).
            previewDownloaderRequest = mediaStore.newDownloader(
                mediaResources: mediaResources,
                type: DownloadType.preview,
                destination: .directory(path: imgUrl.path)) { mediaDownloader in
                    guard let downloadStatus = mediaDownloader?.status else {
                        continuation.finish(throwing: MediaStoreError.cannotDownloadPreview)
                        return
                    }

                    switch downloadStatus {
                    case .fileDownloaded:
                        if mediaDownloader?.fileUrl?.resId == resId {
                            continuation.yield(mediaDownloader?.fileUrl)
                            continuation.finish()
                        }

                    case .complete:
                        continuation.finish()

                    case .error:
                        continuation.finish(throwing: MediaStoreError.cannotDownloadPreview)

                    default:
                        break
                    }
                }
        }
    }

    /// Cancels any ongoing download.
    public func cancelDownload() {
        // Clear states.
        downloaderRef = nil
        downloadState = (nil, nil)
        clearDownloadIds()
    }

    // MARK: Delete
    /// Whether a media or one of its resources belongs to current delete request.
    ///
    /// - Parameter media: the media to check
    /// - Returns: whether the media it self or one of its resources belong to current delete request
    public func isDeleting(media: GalleryMedia) -> Bool {
        deleteUids.contains(where: { uid in
            uid == media.uid || media.previewableResources?.contains(where: { uid == $0.uid }) == true
        })
    }
    /// Requests deletion of a `MediaItem`s array to the media store.
    ///
    /// - Parameter items: the media items to delete
    public func delete(items: [MediaItem]) async throws {
        initDeleteUids(Set(items.map({ $0.uid })))

        try await withCheckedThrowingContinuation { continuation in
            delete(items: items) { success in
                success ? continuation.resume() : continuation.resume(throwing: MediaStoreError.cannotDeleteMedia)
            }
        }
    }

    /// Requests deletion of a specific resources array from a `MediaItem` to the media store.
    ///
    /// - Parameters:
    ///    - indexes: the indexes of the resources to delete
    ///    - item: the media item containing the resources to delete
    public func deleteResourcesAt(_ indexes: [Int], from item: MediaItem) async throws {
        let resources = indexes
            .filter { $0 < item.resources.count }
            .map { item.resources[$0] }

        initDeleteUids(Set(resources.map({ $0.uid })))

        try await withCheckedThrowingContinuation { continuation in
            delete(resources: resources, from: item) { success in
                success ? continuation.resume() : continuation.resume(throwing: MediaStoreError.cannotDeleteMedia)
            }
        }
    }

    // MARK: Upload
    /// Requests upload of an array of resources URLs to a specific `MediaItem`.
    ///
    /// - Parameters:
    ///    - urls: the urls of the resources to upload to the media
    ///    - mediaItem: the media item to update with the uploaded resources
    /// - Returns: an async stream tracking the upload status
    public func upload(urls: [URL], to mediaItem: MediaItem) -> AsyncStream<MediaTaskStatus> {
        AsyncStream { continuation in
            guard let mediaStore = mediaStore,
                  let target = mediaItem as? MediaItemCore else {
                continuation.yield(.error)
                continuation.finish()
                return
            }

            uploaderRef = mediaStore.newUploader(resources: urls, target: target) { uploader in
                guard let uploader = uploader else {
                    // Unknown status => report error and finish sequence, as upload may never be complete.
                    continuation.yield(.error)
                    continuation.finish()
                    return
                }

                // Update upload state.
                self.uploadState = (uploader.totalProgress, uploader.status)

                // Handle current status.
                switch uploader.status {
                case .fileDownloaded:
                    continuation.yield(.fileDownloaded)

                case .error:
                    continuation.yield(.error)
                    continuation.finish()

                case .complete:
                    continuation.yield(.complete)
                    continuation.finish()

                default:
                    break
                }
            }
        }
    }

    /// Cancels any ongoing upload.
    public func cancelUpload() {
        // Clear states.
        uploaderRef = nil
        downloadState = (nil, nil)
    }
}

// MARK: - Media List
private extension MediaStoreServiceImpl {

    /// The media store.
    var mediaStore: MediaStore? { mediaStoreRef?.value }
    /// The media list.
    var mediaList: [GalleryMedia] {
        get { itemsListSubject.value }
        set { itemsListSubject.value = newValue }
    }
    /// The media store indexing state.
    var indexingState: MediaStoreIndexingState {
        get { indexingStateSubject.value }
        set { indexingStateSubject.value = newValue }
    }

    /// Listens to current drone holder.
    ///
    /// - Parameter currentDroneHolder: the current drone holder
    func listenTo(_ currentDroneHolder: CurrentDroneHolder) {
        currentDroneHolder.dronePublisher
            .sink { [unowned self] drone in
                ULog.d(.tag, "[galleryRework] Drone update \(drone.uid)")
                listenToMediaStore(drone: drone)
            }
            .store(in: &cancellables)
    }

    /// Listens to media store.
    ///
    /// - Parameter drone: the current drone
    func listenToMediaStore(drone: Drone) {
        ULog.d(.tag, "[galleryRework] Listen to media store")
        mediaStoreRef = drone.getPeripheral(Peripherals.mediaStore) { [weak self] mediaStore in
            self?.updateMediaStore(mediaStore)
        }
    }

    /// Updates media store indexing state and gathers medias.
    ///
    /// - Parameter store: the media store
    func updateMediaStore(_ store: MediaStore?) {
        indexingState = store?.indexingState ?? .unavailable
        ULog.d(.tag, "[galleryRework] Indexing state: \(indexingState)")
        guard let store = store else {
            // Store is unavailable => clear media list.
            ULog.d(.tag, "[galleryRework] Empty media store => Clear list.")
            clearMediaList()
            return
        }
        if indexingState == .indexed {
            // Get medias from current store.
            getMediaList(store: store)
        }
    }

    /// Gets media list from media store.
    ///
    /// - Parameter store: the media store
    func getMediaList(store: MediaStore) {
        // No need to create a new list if reference already exists.
        if itemsListRef != nil { return }

        ULog.i(.tag, "[galleryRework] List ref creation from store \(store)")
        // Create new media store list reference and listens to updates.
        itemsListRef = store.newList { [weak self] list in
            guard let self = self else { return }
            guard let list = list else {
                ULog.i(.tag, "[galleryRework] List unavailable")
                self.mediaList = []
                return
            }

            ULog.d(.tag, "[galleryRework] Media total count: \(list.count) | video: \(list.videoMediaCount) | photo: \(list.photoMediaCount)")
            self.mediaList = list.galleryMedias(droneUid: self.droneUid)
            // This refresh is supposed to only be temporary, as we should be able to update the delete uids list
            // dynamically according to deleter events. To be checked after SDK rework.
            self.refreshDeleteUids(for: self.mediaList)
        }
    }

    /// Forces new media list reference creation.
    ///
    /// - Parameter store: the media store
    func reloadMediaList(store: MediaStore) {
        itemsListRef = nil
        getMediaList(store: store)
    }

    /// Clears existing media list.
    func clearMediaList() {
        itemsListRef = nil
        mediaList = []
    }
}

// MARK: - Download
private extension MediaStoreServiceImpl {

    /// The current drone uid.
    var droneUid: String { currentDroneHolder.drone.uid }
    /// The download state.
    var downloadState: (progress: Float?, status: MediaTaskStatus?) {
        get { downloadTaskStateSubject.value }
        set { downloadTaskStateSubject.value = newValue }
    }
    /// The download indentifiers.
    ///
    /// A (`uid`, `customTitle`) tuple is used in order to be able to correctly track GPS lapses downloads
    /// (GPS lapses medias are composed of several items with a common `customTitle` and distinct `uid`s).
    var downloadIds: [(uid: String, customTitle: String?)] {
        get { downloadIdsSubject.value }
        set {
            downloadIdsSubject.value = newValue
            // Download task is ongoing if downloadIds array is not empty.
            isDownloadingSubject.value = !newValue.isEmpty
            // Update stream according to download status.
            currentDroneHolder.drone.getPeripheral(Peripherals.streamServer)?.enabled = !isDownloadingSubject.value
        }
    }
    /// The upload state.
    var uploadState: (progress: Float?, status: MediaTaskStatus?) {
        get { uploadTaskStateSubject.value }
        set { uploadTaskStateSubject.value = newValue }
    }

    /// Initializes the ongoing download uids set from specified items array.
    ///
    /// - Parameter items: the items array
    func initDownloadIds(from items: [MediaItem]) {
        let uids = items.filter({ !$0.isDownloaded }).map { ($0.uid, $0.customTitle) }
        ULog.d(.tag, "[galleryRework] Init download for: \(uids)")
        downloadIds = uids
    }

    /// Removes a specific identifier from ongoing download uids array if corresponding item is fully downloaded.
    ///
    /// - Parameter uid: the uid to remove
    func removeFromDownloadIds(identifier: (uid: String?, customTitle: String?)) {
        guard let uid = identifier.uid,
              // Need to parse down all mediaItems, as GPS lapses are composed of several items with distinct UIDs.
              let mediaItems = mediaList.first(where: { media in
                  media.mediaItems?.map({ $0.uid }).contains(uid) ?? false
              })?.mediaItems else {
            // No corresponding media found.
            return
        }

        // Remove from list only if item download is fully complete (some resources may still need to be downloaded).
        if mediaItems.isDownloadComplete {
            if let customTitle = identifier.customTitle {
                // Downloaded item has a custom title => remove all related identifiers.
                downloadIds.removeAll(where: { $0.customTitle == customTitle })
            } else {
                downloadIds.removeAll(where: { $0.uid == uid })
            }
        }
    }

    /// Clears ongoing download identifiers array.
    func clearDownloadIds() {
        downloadIds.removeAll()
    }

    /// Saves a media item located at a given URL into dedicated directory based on its media type.
    ///
    /// - Parameters:
    ///    - fileURL: the URL to save the item to
    ///    - signatureFileUrl: the signature file URL to move the item to
    ///    - media: the media to save
    func saveMedia(fileUrl: URL,
                   signatureFileUrl: URL?,
                   media: MediaItem?) {
        guard let media = media else { return }

        let destinationUrl = MediaUtils.moveFile(fileUrl: fileUrl,
                                                 droneId: droneUid,
                                                 mediaType: media.mediaType)
        if let signatureFileUrl = signatureFileUrl {
            _ = MediaUtils.moveFile(fileUrl: signatureFileUrl,
                                    droneId: droneUid,
                                    mediaType: media.mediaType)
        }

        AssetUtils.shared.addMediaItemToLocalList(media, for: droneUid)
        AssetUtils.shared.addMediaInfoToLocalList(media: media, url: destinationUrl)

        if let url = destinationUrl {
            MediaUtils.saveMediaRunUid(media.runUid, withUrl: url)
        }
    }
}

// MARK: - Delete
private extension MediaStoreServiceImpl {

    /// The ongoing delete uids.
    var deleteUids: Set<String> {
        get { deleteUidsSubject.value }
        set { deleteUidsSubject.value = newValue }
    }

    /// Requests deletion of a media items array to media store.
    ///
    /// - Parameters:
    ///    - items: the media items to delete
    ///    - completion: the completion block
    func delete(items: [MediaItem], completion: @escaping (Bool) -> Void) {
        guard let mediaStore = mediaStore else {
            completion(false)
            return
        }

        let resourcesList = MediaResourceListFactory.listWith(allOf: items)
        delete(mediaStore: mediaStore, resourcesList: resourcesList, completion: completion)
    }

    /// Requests deletion of a specific resources array from a `MediaItem` to the media store.
    ///
    /// - Parameters:
    ///    - indexes: the indexes of the resources to delete
    ///    - item: the media item containing the resources to delete
    ///    - completion: the completion block
    func delete(resources: [MediaItem.Resource], from item: MediaItem, completion: @escaping (Bool) -> Void) {
        guard let mediaStore = mediaStore else {
            completion(false)
            return
        }

        let resourcesList = MediaResourceListFactory.emptyList()
        for resource in resources {
            resourcesList.add(media: item, resource: resource)
        }

        delete(mediaStore: mediaStore, resourcesList: resourcesList, completion: completion)
    }

    /// Requests deletion of a specific resources list to the media store.
    ///
    /// - Parameters:
    ///    - mediaStore: the media store to request the deletion to
    ///    - resourcesList: the resources list to delete
    ///    - completion: the completion block
    func delete(mediaStore: MediaStore, resourcesList: MediaResourceList, completion: @escaping (Bool) -> Void) {
        deleterRef = mediaStore.newDeleter(mediaResources: resourcesList) { mediaDeleter in
            guard let mediaDeleter = mediaDeleter else {
                // Report error and finish sequence, as download may never be complete.
                completion(false)
                return
            }

            switch mediaDeleter.status {
            case .error, .complete:
                // TODO: [GalleryRework] To address after SDK rework.
                // Media list reload should not be needed, but it seems like media store does not update
                // its list when removing more than 1 item at once (`mediaStore.backend.browse` request
                // still active when trying to update next items and is therefore ignored).
                self.reloadMediaList(store: mediaStore)
                completion(true)
            default: break
            }
        }
    }

    /// Initializes the ongoing delete uids set with provided uids list.
    ///
    /// - Parameter uids: the uids set
    func initDeleteUids(_ uids: Set<String>) {
        ULog.d(.tag, "[galleryRework] Init delete for: [\(uids)]")
        deleteUids = uids
    }

    /// Refreshes ongoing delete uids according to a specific media list content.
    /// If list does not contain any media with an uid stored in ongoing delete uids array,
    /// then it should be removed from the `deleteUids` set.
    ///
    /// - Parameter list: the media list to base the refresh on
    func refreshDeleteUids(for list: [GalleryMedia]) {
        var uidsToRemove = [String]()
        for uid in deleteUids {
            if !list.contains(where: { $0.uid == uid }) {
                uidsToRemove.append(uid)
            }
        }

        if !uidsToRemove.isEmpty {
            // Some uids do not belong to provided media list anymore.
            // => Remove them from ongoing delete uids.
            _ = uidsToRemove.map { deleteUids.remove($0) }
        }
    }

    /// Clears ongoing delete uids array.
    func clearDeleteUids() {
        deleteUids.removeAll()
    }
}
