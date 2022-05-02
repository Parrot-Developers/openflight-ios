//    Copyright (C) 2021 Parrot Drones SAS
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

// MARK: - Gallery Internal Media Listener
/// Listener for `GalleryInternalMediaViewModel` state updates.
final class GalleryInternalMediaListener: NSObject {
    // MARK: - Internal Properties
    let didChange: GalleryInternalMediaListenerClosure

    // MARK: - Init
    init(didChange: @escaping GalleryInternalMediaListenerClosure) {
        self.didChange = didChange
    }
}
/// Alias for `GalleryInternalMediaListener` closure.
typealias GalleryInternalMediaListenerClosure = (GalleryInternalMediaState) -> Void

/// State for `GalleryInternalMediaViewModel`.
final class GalleryInternalMediaState: GalleryContentState {
    // MARK: - Private Properties
    /// Drone Uid.
    fileprivate(set) var droneUid: String?
    /// Current physical storage state.
    fileprivate(set) var physicalStorageState: UserStoragePhysicalState?
    /// Current file system storage state.
    fileprivate(set) var fileSystemStorageState: UserStorageFileSystemState?

    // MARK: - Internal Properties
    var source: GallerySource {
        return GallerySource(type: .droneInternal,
                             storageUsed: storageUsed,
                             storageCapacity: capacity,
                             isOffline: false)
    }

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: drone connection state
    ///    - availableSpace: available space, in giga bytes
    ///    - capacity: capacity, in giga bytes
    ///    - isFormatNeeded: format needed status
    ///    - isRemoving: ViewModel is removing
    ///    - medias: media list
    ///    - sourceType: source type
    ///    - referenceDate: reference date
    ///    - videoDuration: video duration
    ///    - videoPosition: video position
    ///    - videoState: video state
    required init(connectionState: DeviceState.ConnectionState,
                  availableSpace: Double,
                  capacity: Double,
                  isFormatNeeded: Bool,
                  isRemoving: Bool,
                  medias: [GalleryMedia],
                  sourceType: GallerySourceType,
                  referenceDate: Date,
                  videoDuration: TimeInterval,
                  videoPosition: TimeInterval,
                  videoState: VideoState?) {
        super.init(connectionState: connectionState,
                   availableSpace: availableSpace,
                   capacity: capacity,
                   isFormatNeeded: false,
                   isRemoving: isRemoving,
                   medias: medias,
                   sourceType: sourceType,
                   referenceDate: referenceDate,
                   videoDuration: videoDuration,
                   videoPosition: videoPosition,
                   videoState: videoState)
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: drone connection state
    ///    - availableSpace: available space on internal memory
    ///    - capacity: Total internal memory capacity
    ///    - isFormatNeeded: format needed status
    ///    - droneUid: media list
    ///    - isRemoving: ViewModel is removing
    ///    - medias: media list
    ///    - referenceDate: reference date
    ///    - sourceType: source type
    ///    - physicalStorageState: Internal memory physical state
    ///    - fileSystemStorageState: Internal memory file system state
    ///    - videoDuration: video duration
    ///    - videoPosition: video position
    ///    - videoState: video state
    required init(connectionState: DeviceState.ConnectionState,
                  availableSpace: Double,
                  capacity: Double,
                  isFormatNeeded: Bool,
                  droneUid: String?,
                  isRemoving: Bool,
                  medias: [GalleryMedia],
                  referenceDate: Date,
                  sourceType: GallerySourceType,
                  physicalStorageState: UserStoragePhysicalState?,
                  fileSystemStorageState: UserStorageFileSystemState?,
                  videoDuration: TimeInterval,
                  videoPosition: TimeInterval,
                  videoState: VideoState?) {
        super.init(connectionState: connectionState,
                   availableSpace: availableSpace,
                   capacity: capacity,
                   isFormatNeeded: isFormatNeeded,
                   isRemoving: isRemoving,
                   medias: medias,
                   sourceType: sourceType,
                   referenceDate: referenceDate,
                   videoDuration: videoDuration,
                   videoPosition: videoPosition,
                   videoState: videoState)
        self.droneUid = droneUid
        self.physicalStorageState = physicalStorageState
        self.fileSystemStorageState = fileSystemStorageState
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let typedOther = other as? GalleryInternalMediaState else {
            return super.isEqual(to: other)
        }

        return super.isEqual(to: typedOther)
            && self.droneUid == typedOther.droneUid
            && self.physicalStorageState == typedOther.physicalStorageState
            && self.fileSystemStorageState == typedOther.fileSystemStorageState
    }

    override func copy() -> GalleryInternalMediaState {
        return GalleryInternalMediaState(connectionState: self.connectionState,
                                         availableSpace: self.availableSpace,
                                         capacity: self.capacity,
                                         isFormatNeeded: self.isFormatNeeded,
                                         droneUid: self.droneUid,
                                         isRemoving: self.isRemoving,
                                         medias: self.medias,
                                         referenceDate: self.referenceDate,
                                         sourceType: self.sourceType,
                                         physicalStorageState: self.physicalStorageState,
                                         fileSystemStorageState: self.fileSystemStorageState,
                                         videoDuration: self.videoDuration,
                                         videoPosition: self.videoPosition,
                                         videoState: self.videoState)
    }

}

/// ViewModel for InternalCard Gallery Media Item.
final class GalleryInternalMediaViewModel: DroneStateViewModel<GalleryInternalMediaState> {
    @Published private(set) var downloadProgress: Float?
    @Published private(set) var downloadStatus: MediaTaskStatus?
    @Published private(set) var downloadingItem: MediaItem?

    // MARK: - Private Properties
    private var internalRef: Ref<InternalUserStorage>?
    private var mediaListRef: Ref<[MediaItem]>?
    private var internalMediaListener: Set<GalleryInternalMediaListener> = []

    // MARK: - Internal Properties
    var availableSpace: Double {
        return self.state.value.availableSpace
    }
    var downloadRequest: Ref<MediaDownloader>?
    var uploadRequest: Ref<ResourceUploader>?
    var deleteRequest: Ref<MediaDeleter>?
    var deleteAllRequest: Ref<AllMediasDeleter>?
    var mediaStore: MediaStore?
    static var shared = GalleryInternalMediaViewModel()
    var storageUsed: Double {
        return self.state.value.storageUsed
    }
    var streamingReplayState: ReplayPlayState? {
        return streamingCurrentReplay?.playState
    }
    var streamingMediaReplayRef: Ref<MediaReplay>?
    var streamingCurrentResource: MediaItem.Resource?
    var streamingCurrentReplay: Replay? {
        return streamingMediaReplayRef?.value
    }
    var streamingDefaultTrack: MediaItem.Track = .defaultVideo

    // MARK: - Init
    private override init() {
        super.init()

        state.valueChanged = { [weak self] state in
            // Run listeners closure.
            self?.internalMediaListener.forEach { listener in
                listener.didChange(state)
            }
        }
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        setupDroneListeners(drone: drone)
    }

    override func droneConnectionStateDidChange() {
        super.droneConnectionStateDidChange()

        if !self.state.value.isConnected() {
            clearMedia()
        } else {
            guard let drone = drone else { return }

            setupDroneListeners(drone: drone)
        }
    }
}

// MARK: - Internal Funcs
extension GalleryInternalMediaViewModel {
    /// Update removing state.
    ///
    /// - Parameters:
    ///     - isRemoving: VM is removing
    func updateRemovingState(_ isRemoving: Bool) {
        let copy = self.state.value.copy()
        copy.isRemoving = isRemoving
        self.state.set(copy)
    }

    /// Downloader did update.
    ///
    /// - Parameters:
    ///     - mediaDownloader: MediaDownloader
    func downloaderDidUpdate(_ mediaDownloader: MediaDownloader?) {
        downloadProgress = mediaDownloader?.totalProgress
        downloadStatus = mediaDownloader?.status
        downloadingItem = mediaDownloader?.currentMedia

        var copy = self.state.value.copy()

        /// Update loading media if needed.
        copy = updateMediasDownloadState(state: copy)

        self.state.set(copy)
    }

    /// Setup drone listeners.
    ///
    /// - Parameters:
    ///     - drone: current drone
    func setupDroneListeners(drone: Drone) {
        updateDroneUid(drone: drone)
        listenInternalMemory(drone: drone)
        loadMediaStore(drone: drone)
        loadMedia(drone: drone)
    }

    /// Refresh media list.
    func refreshMedias() {
        guard let drone = drone else {
            clearMedia()
            return
        }

        loadMedia(drone: drone)
    }

    /// Get a media preview image url.
    ///
    /// - Parameters:
    ///    - media: GalleryMedia
    ///    - index: index of image
    ///    - completion: completion block
    func getMediaPreviewImageUrl(_ media: GalleryMedia, _ index: Int = 0, completion: @escaping (URL?) -> Void) {
        if let galleryURL = ressourceGalleryURL(media, index),
           isResourceDownloaded(media, index) {
            completion(galleryURL)
        } else if let droneId = state.value.droneUid,
                  let mediaResources = media.mediaResources,
                  mediaResources.count > index,
                  let cachedImgUrl = mediaResources[index].cachedImgUrl(droneId: droneId),
                  mediaResources[index].cachedImgUrlExist(droneId: droneId) {
            completion(cachedImgUrl)
        } else {
            completion(nil)
        }
    }
}

// MARK: - Private Funcs
private extension GalleryInternalMediaViewModel {
    /// Update drone Uid.
    ///
    /// - Parameters:
    ///     - drone: current drone
    func updateDroneUid(drone: Drone) {
        let copy = self.state.value.copy()
        copy.droneUid = drone.uid
        self.state.set(copy)
    }

    /// Starts watcher for Internal User Storage.
    func listenInternalMemory(drone: Drone) {
        internalRef = drone.getPeripheral(Peripherals.internalUserStorage) { [weak self] storage in
            guard let storage = storage,
                  let copy = self?.state.value.copy() else {
                return
            }

            // Turn storage in mega bytes.
            copy.availableSpace = Double(storage.availableSpace) / Double(StorageUtils.Constants.bytesPerGigabyte)
            copy.physicalStorageState = storage.physicalState
            copy.fileSystemStorageState = storage.fileSystemState
            if let capacity = storage.mediaInfo?.capacity {
                copy.capacity = Double(capacity) / Double(StorageUtils.Constants.bytesPerGigabyte)
            }
            self?.state.set(copy)
        }
    }

    /// Load MediaStore from drone.
    ///
    /// - Parameters:
    ///     - drone: current drone
    func loadMediaStore(drone: Drone) {
        mediaStore = drone.getPeripheral(Peripherals.mediaStore)
    }

    /// Load MediaList from mediaStore peripherial.
    ///
    /// - Parameters:
    ///     - drone: current drone
    func loadMedia(drone: Drone) {
        guard let mediaStore = mediaStore else {
            clearMedia()
            return
        }

        mediaListRef = mediaStore.newList { [weak self] droneMediaList in
            guard let strongSelf = self,
                  let droneMediaList = droneMediaList else {
                self?.clearMedia()
                return
            }

            let copy = strongSelf.state.value.copy()
            copy.sourceType = .droneInternal
            copy.referenceDate = Date()
            let filteredMediaResources = droneMediaList.filter({ $0.isInternalStorage })
            let allMedias: [GalleryMedia] = strongSelf.mergeMedias(medias: filteredMediaResources)
            copy.medias = allMedias.sorted(by: { $0.date > $1.date })
            strongSelf.state.set(copy)
        }
    }

    /// Merge medias with or without customID.
    ///
    /// - Parameters:
    ///     - medias: Stores media items
    ///
    /// - Returns: The new merged gallery medias.
    func mergeMedias(medias: [MediaItem]) -> [GalleryMedia] {
        var mediasWithoutCustomId: [MediaItem] = []
        var mediasWithCustomId: [String: [MediaItem]] = [:]

        for media in medias {
            // Group timelapse or gpslapse FP Photogrammetry medias by custom_id.
            if let customID = media.customId,
               !customID.isEmpty,
               media.mediaType == .gpsLapse || media.mediaType == .timeLapse {
                if let mediasWithCustomID = mediasWithCustomId[customID] {
                    mediasWithCustomId[customID] = mediasWithCustomID + [media]
                } else {
                    mediasWithCustomId[customID] = [media]
                }
            } else {
                mediasWithoutCustomId.append(media)
            }
        }

        let galleryMediasWithoutCustomID = mediasWithoutCustomId.compactMap({ return convertToGalleryMedia(mediaItems: [$0]) })
        let galleryMediasWithCustomID = mediasWithCustomId.compactMap({ return convertToGalleryMedia(mediaItems: $1) })

        return galleryMediasWithoutCustomID + galleryMediasWithCustomID
    }

    /// Convert MediaItems to GalleryMedia.
    ///
    /// - Parameters:
    ///    - mediaItems: Stores media items
    ///
    /// - Returns: GalleryMedia object for mediaItems in parameter.
    func convertToGalleryMedia(mediaItems: [MediaItem]) -> GalleryMedia? {
        guard let mediaItem = mediaItems.first else { return nil }

        let downloadState: GalleryMediaDownloadState

        if mediaItems.contains(where: { $0.uid == downloadingItem?.uid }), downloadStatus == .running {
            downloadState = .downloading
        } else if mediaItems.allSatisfy({ $0.isDownloaded }) {
            downloadState = .downloaded
        } else {
            downloadState = .toDownload
        }

        return GalleryMedia(uid: mediaItem.uid,
                            customTitle: mediaItem.customTitle,
                            source: .droneInternal,
                            mediaItems: mediaItems,
                            type: mediaItem.mediaType,
                            downloadState: downloadState,
                            size: size(for: mediaItems),
                            date: mediaItem.creationDate,
                            url: nil)
    }

    /// Returns Size for MediaItem.
    ///
    /// - Parameters:
    ///    - mediaItem: MediaItem object
    ///
    /// - Returns: Value for size of all MediaItem resources.
    func size(for mediaItem: MediaItem) -> UInt64 {
        mediaItem.downloadableResources.reduce(0) { $0 + $1.size }
    }

    /// Returns Size for an array of MediaItem.
    ///
    /// - Parameters:
    ///    - mediaItems: the array of MediaItem object
    ///
    /// - Returns: Value for size of all MediaItem resources.
    func size(for mediaItems: [MediaItem]) -> UInt64 {
        mediaItems.reduce(0) { $0 + size(for: $1) }
    }

    /// Update state regarding download status.
    ///
    /// - Parameters:
    ///    - state: Gallery internalMedia State
    /// - Returns: Updated Gallery Internal Media State
    func updateMediasDownloadState(state: GalleryInternalMediaState) -> GalleryInternalMediaState {
        guard let loadingMedia = downloadingItem else { return state }

        let isError = downloadStatus == .error
        var allMedia = self.state.value.medias
        if let index = state.medias.firstIndex(where: { $0.mainMediaItem?.uid == loadingMedia.uid }),
           state.medias[index].downloadState != .downloading {
            // Update item downloadState if necessary.
            var mediaToUpdate = allMedia.remove(at: index)
            mediaToUpdate.downloadState = isError ? .error : .downloading
            allMedia.insert(mediaToUpdate, at: index)
        }
        state.medias = allMedia
        return state
    }

    /// Returns gallery Url.
    ///
    /// - Parameters:
    ///    - media: media
    ///    - index: index of image
    /// - Returns: gallery url for this media
    func ressourceGalleryURL(_ media: GalleryMedia?, _ index: Int = 0) -> URL? {
        guard let media = media,
              let mediaItem = media.mediaItem(for: index),
              let mediaResource = media.mediaResource(for: index) else {
            return nil
        }

        return mediaResource.galleryURL(droneId: self.state.value.droneUid,
                                        mediaType: mediaItem.mediaType)
    }

    /// Determine if a media is downloaded.
    ///
    /// - Parameters:
    ///    - media: media
    ///    - index: index of image
    /// - Returns: boolean determining if the media is downloaded
    func isResourceDownloaded(_ media: GalleryMedia?, _ index: Int = 0) -> Bool {
        guard let media = media,
              let mediaItem = media.mediaItem(for: index),
              let mediaResource = media.mediaResource(for: index) else {
            return false
        }

        return mediaResource.isDownloaded(droneId: self.state.value.droneUid,
                                          mediaType: mediaItem.mediaType)
    }

    func clearMedia() {
        let copy = self.state.value.copy()
        copy.sourceType = .droneInternal
        copy.referenceDate = Date()
        copy.medias = []
        copy.availableSpace = 0.0
        self.state.set(copy)
    }
}

// MARK: - Gallery Internal Media Listener
extension GalleryInternalMediaViewModel {
    /// Registers a listener for `GalleryInternalMediaListener`.
    ///
    /// - Parameters:
    ///    - didChange: listener's closure
    /// - Returns: registered listener
    func registerListener(didChange: @escaping GalleryInternalMediaListenerClosure) -> GalleryInternalMediaListener {
        let listener = GalleryInternalMediaListener(didChange: didChange)
        internalMediaListener.insert(listener)
        // Initial notification.
        listener.didChange(self.state.value)
        return listener
    }

    /// Removes previously registered `GalleryInternalMediaListener`.
    ///
    /// - Parameters:
    ///    - listener: listener to remove
    func unregisterListener(_ listener: GalleryInternalMediaListener?) {
        guard let listener = listener else {
            return
        }

        self.internalMediaListener.remove(listener)
    }

    /// Unregister all listener.
    func unregisterAllListener() {
        self.internalMediaListener.removeAll()
    }
}
