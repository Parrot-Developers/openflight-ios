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

import GroundSdk
import Combine

// MARK: - Gallery Media Error
enum GalleryMediaError: Error {
    /// Unable to get the media's preview image url
    case mediaPreviewImageUrlNotFound
    /// Unable to prefetch the resource.
    case mediaPrefetchResourceNotFound
    /// Generic prefetch error.
    case mediaPrefetchError
}

// MARK: - Gallery Media Listener
/// Listener for `GalleryMediaViewModel` state updates.
final class GalleryMediaListener: NSObject {
    // MARK: - Internal Properties
    let didChange: GalleryMediaListenerClosure

    // MARK: - Init
    init(didChange: @escaping GalleryMediaListenerClosure) {
        self.didChange = didChange
    }
}
/// Alias for `GalleryMediaListener` closure.
typealias GalleryMediaListenerClosure = (GalleryMediaState) -> Void

/// State for `GalleryMediaViewModel`.

final class GalleryMediaState: GalleryContentState {
    // MARK: - Private Properties
    /// Array of Medias
    private(set) var filteredMedias: [GalleryMedia] = []
    /// Medias sorted by date.
    private(set) var mediasByDate: [(key: Date, medias: [GalleryMedia])] = [] {
        didSet {
            filteredMedias = sortedFilteredMedias()
        }
    }
    /// Selected media type.
    fileprivate(set) var selectedMediaTypes: [GalleryMediaType] = [] {
        didSet {
            mediasByDate = sortMediasByDate()
        }
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
                   isFormatNeeded: isFormatNeeded,
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
    ///    - availableSpace: available space, in giga bytes
    ///    - capacity: capacity, in giga bytes
    ///    - isFormatNeeded: format needed status
    ///    - isRemoving: ViewModel is removing
    ///    - medias: media list
    ///    - selectedMediaType: selected media type
    ///    - sourceType: source type
    ///    - referenceDate: reference date
    required init(connectionState: DeviceState.ConnectionState,
                  availableSpace: Double,
                  capacity: Double,
                  isFormatNeeded: Bool,
                  isRemoving: Bool,
                  medias: [GalleryMedia],
                  selectedMediaTypes: [GalleryMediaType],
                  sourceType: GallerySourceType,
                  referenceDate: Date,
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
        self.selectedMediaTypes = selectedMediaTypes
        self.sourceType = sourceType
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let typedOther = other as? GalleryMediaState else {
            return super.isEqual(to: other)
        }
        return super.isEqual(to: typedOther)
            && self.selectedMediaTypes == typedOther.selectedMediaTypes
            && self.sourceType == typedOther.sourceType
    }

    override func copy() -> GalleryMediaState {
        return GalleryMediaState(connectionState: self.connectionState,
                                 availableSpace: self.availableSpace,
                                 capacity: self.capacity,
                                 isFormatNeeded: self.isFormatNeeded,
                                 isRemoving: self.isRemoving,
                                 medias: self.medias,
                                 selectedMediaTypes: self.selectedMediaTypes,
                                 sourceType: self.sourceType,
                                 referenceDate: self.referenceDate,
                                 videoDuration: self.videoDuration,
                                 videoPosition: self.videoPosition,
                                 videoState: self.videoState)
    }

    override func sourceWasUpdated() {
        mediasByDate = sortMediasByDate()
    }

    override func mediasWereUpdated() {
        mediasByDate = sortMediasByDate()
    }
}

// MARK: - Private Funcs
private extension GalleryMediaState {
    /// Sort medias by date.
    ///
    /// - Returns: list of medias ordered by date and possibly filtered by type.
    func sortMediasByDate() -> [(key: Date, medias: [GalleryMedia])] {
        var sortedItems: [(key: Date, medias: [GalleryMedia])] = []
        let sortedData = sortedFilteredMedias()

        for item in sortedData {
            if let currentDate = sortedItems.first(where: { $0.key.isSameDay(date: item.date) }) {
                var newDateTuple = currentDate
                sortedItems.removeAll(where: { $0.key.isSameDay(date: currentDate.key) })
                newDateTuple.medias.append(item)
                sortedItems.append(newDateTuple)
            } else {
                sortedItems.append((key: item.date, medias: [item]))
            }
        }
        return sortedItems
    }

    /// Sort medias by date with selected type
    ///
    /// - Returns: list of medias ordered by date and possibly filtered by type.
    func sortedFilteredMedias() -> [GalleryMedia] {
        var filteredMedias =  medias.sorted(by: { $0.date > $1.date })
        if !selectedMediaTypes.isEmpty {
            filteredMedias = filteredMedias.filter({selectedMediaTypes.contains($0.type)})
        }

        return filteredMedias
    }
}

/// ViewModel for Gallery Media Item.

final class GalleryMediaViewModel: DroneStateViewModel<GalleryMediaState> {
    @Published private(set) var downloadProgress: Float?
    @Published private(set) var downloadStatus: MediaTaskStatus?
    @Published private(set) var downloadingItem: MediaItem?
    @Published private(set) var canFormat: Bool = true

    // MARK: - Private Properties
    private var mediaListener: Set<GalleryMediaListener> = []
    private var mediaInitialClosure: GalleryMediaListenerClosure?
    private var sdCardListener: GallerySdMediaListener?
    private var internalListener: GalleryInternalMediaListener?
    private var deviceListener: GalleryDeviceMediaListener?

    // MARK: - Internal Properties
    private var cancellables = Set<AnyCancellable>()
    var mediaBrowsingViewModel = GalleryMediaBrowsingViewModel(cameraRecordingService: Services.hub.drone.cameraRecordingService)
    var sdCardViewModel: GallerySDMediaViewModel? = GallerySDMediaViewModel.shared
    var internalViewModel: GalleryInternalMediaViewModel? = GalleryInternalMediaViewModel.shared
    var deviceViewModel: GalleryDeviceMediaViewModel? = GalleryDeviceMediaViewModel.shared
    var selectionModeEnabled: Bool = false

    // MARK: - Public Properties
    public var selectedMediaTypes: [GalleryMediaType] {
        return self.state.value.selectedMediaTypes
    }
    public var sourceType: GallerySourceType {
        switch state.value.sourceType {
        case .droneSdCard,
             .droneInternal:
            // Need to switch between the 2 drone storages depending on SD card state.
            return isSdCardActive ? .droneSdCard : .droneInternal
        case .unknown:
            // No source defined yet => select by highest priority according to storages state:
            // SD card if ready, internal memory if ready and not empty, mobile otherwise.
            return isSdCardReady ? .droneSdCard
                : isInternalReady && !isInternalEmpty
                ? .droneInternal
                : .mobileDevice
        default:
            return state.value.sourceType
        }
    }
    /// Number of medias according to source type.
    public var numberOfMedias: Int {
        state.value.medias.count
    }
    public var numberOfFilteredMedias: Int {
        state.value.filteredMedias.count
    }
    public var isSdCardActive: Bool {
        isSdCardReady || !isInternalReady
    }
    public var isSdCardReady: Bool {
        guard let sdState = sdCardViewModel?.state.value,
              sdState.isConnected(),
              sdState.fileSystemStorageState == .ready else {
            return false
        }
        return true
    }
    public var isSdCardMissing: Bool {
        guard self.state.value.isConnected() else { return false }
        return !isSdCardReady
    }
    public var isInternalReady: Bool {
        guard let internalState = internalViewModel?.state.value,
              internalState.isConnected(),
              internalState.fileSystemStorageState == .ready else {
            return false
        }
        return true
    }
    public var isInternalEmpty: Bool {
        guard let internalState = internalViewModel?.state.value else { return true }
        return internalState.storageUsed == 0
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - onMediaStateUpdate: called when media state changes
    init(onMediaStateUpdate: ((GalleryMediaState) -> Void)? = nil) {
        super.init()

        mediaInitialClosure = onMediaStateUpdate
        state.valueChanged = { [weak self] state in
            // Run stateDidUpdate closure.
            self?.mediaInitialClosure?(state)
            // Run listeners closure.
            self?.mediaListener.forEach { listener in
                listener.didChange(state)
            }
        }
        initGallerySDCardViewModel()
        initGalleryInternalViewModel()
        initGalleryDeviceViewModel()

        // Init model's sourceType according to storage initial states.
        setSourceType(type: sourceType)
    }

    // MARK: - Deinit
    deinit {
        resetListeners()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)
    }
}

// MARK: - Internal Funcs
extension GalleryMediaViewModel {
    /// Refresh media list.
    ///
    /// - Parameters:
    ///   - source: says if we are on the sd card gallery, internal memory galery or device gallery
    func refreshMedias(source: GallerySourceType? = nil) {
        switch source ?? sourceType {
        case .droneSdCard:
            sdCardViewModel?.refreshMedias()
        case .droneInternal:
            internalViewModel?.refreshMedias()
        case .mobileDevice:
            deviceViewModel?.refreshMedias()
        default:
            return
        }
    }

    /// Download medias.
    ///
    /// - Parameters:
    ///    - medias: GalleryMedia array
    ///    - completion: completion block
    func downloadMedias(_ medias: [GalleryMedia], completion: @escaping (Bool) -> Void) {
        guard downloadStatus != .running else {
            // Can't add a new download to current one.
            completion(false)
            return
        }

        let mediaItems = medias.compactMap({ $0.mediaItems }).flatMap({ $0 })
        switch sourceType {
        case .droneSdCard:
            sdCardViewModel?.downloadMedias(mediasToDownload: mediaItems,
                                            completion: { [weak self] (_, success) in
                                                if success {
                                                    // Check SD card when finish.
                                                    self?.sdCardViewModel?.refreshMedias()
                                                }
                                                completion(success)
                                            })
        case .droneInternal:
            internalViewModel?.downloadMedias(mediasToDownload: mediaItems,
                                              completion: { [weak self] (_, success) in
                                                if success {
                                                    // Check internal memory when finish.
                                                    self?.internalViewModel?.refreshMedias()
                                                }
                                                completion(success)
                                              })
        default:
            return
        }
    }

    /// Cancel downloads.
    func cancelDownloads() {
        sdCardViewModel?.cancelDownloads()
        internalViewModel?.cancelDownloads()
    }

    /// Cancel previews downloads.
    func cancelPreviewsDownloads() {
        sdCardViewModel?.cancelPreviewsDownloads()
    }

    /// Upload media resources.
    ///
    /// - Parameters:
    ///    - urls: URLs array of the media resources to upload.
    ///    - mediaItem: Media item to update with the uploaded resources.
    ///    - completion: Completion block returning upload task status and progress.
    func uploadResources(_ urls: [URL],
                         mediaItem: MediaItem,
                         completion: @escaping (MediaTaskStatus, Float) -> Void) {
        guard let media = mediaItem as? MediaItemCore else {
            completion(.error, 0)
            return
        }

        switch sourceType {
        case .droneSdCard:
            sdCardViewModel?.uploadResources(urls: urls, media: media) { (status, progress) in
                completion(status, progress)
            }
        case .droneInternal:
            internalViewModel?.uploadResources(urls: urls, media: media) { (status, progress) in
                completion(status, progress)
            }
        default:
            completion(.error, 0)
            return
        }
    }

    /// Cancel uploads.
    ///
    /// - Parameters:
    ///    - completion: Completion block.
    func cancelUploads(_ completion: @escaping () -> Void) {
        sdCardViewModel?.cancelUploads()
        internalViewModel?.cancelUploads()
        completion()
    }

    /// Delete medias.
    ///
    /// - Parameters:
    ///    - medias: medias to remove
    ///    - completion: provides success after delete
    func deleteMedias(_ medias: [GalleryMedia], completion: @escaping (Bool) -> Void) {
        switch sourceType {
        case .droneSdCard:
            let mediaItems = medias.compactMap({ $0.mediaItems }).flatMap({ $0 })
            sdCardViewModel?.deleteMedias(mediaItems, completion: { success in
                completion(success)
            })
        case .droneInternal:
            let mediaItems = medias.compactMap({ $0.mediaItems }).flatMap({ $0 })
            internalViewModel?.deleteMedias(mediaItems, completion: { success in
                completion(success)
            })
        case .mobileDevice:
            deviceViewModel?.deleteMedias(medias, completion: { success in
                completion(success)
            })
        default:
            return
        }
    }

    /// Deletes a resource from a media.
    ///
    /// - Parameters:
    ///    - index: Index of the resource to delete.
    ///    - media: Media containing the resource to delete.
    ///    - completion: Completion block called after deletion.
    func deleteResourceAt(_ index: Int, of media: GalleryMedia, completion: @escaping (Bool) -> Void) {
        guard downloadStatus != .running else {
            // Can't delete resources while downloading.
            completion(false)
            return
        }

        switch sourceType {
        case .droneSdCard:
            guard let item = media.mediaItem(for: index),
                  let resources = media.mediaResources else {
                completion(false)
                return
            }
            sdCardViewModel?.deleteResource(resources[index], of: item) { success in
                completion(success)
            }
        case .droneInternal:
            guard let item = media.mediaItem(for: index),
                  let resources = media.mediaResources else {
                completion(false)
                return
            }
            internalViewModel?.deleteResource(resources[index], of: item) { success in
                completion(success)
            }
        case .mobileDevice:
            deviceViewModel?.deleteResourceAt(index, of: media) { success in
                completion(success)
            }
        default:
            return
        }
    }

    /// Deletes resources from a media based on an indexes array.
    /// Note: the indexes array MUST contain resources belonging to the same media item.
    ///
    /// - Parameters:
    ///    - indexes: the indexes of the resources to delete
    ///    - media: the media containing the resources to delete
    ///    - completion: the completion block called after deletion
    func deleteResourcesAt(_ indexes: [Int], of media: GalleryMedia, completion: @escaping (Bool) -> Void) {
        guard downloadStatus != .running else {
            // Can't delete resources while downloading.
            completion(false)
            return
        }

        switch sourceType {
        case .droneSdCard, .droneInternal:
            // Ensure `mediaItem` and `resources` are valid.
            // (Use first index for `mediaItem` check, as all indexes are supposed to point to same media item.)
            guard let firstIndex = indexes.first,
                  let item = media.mediaItem(for: firstIndex),
                  let resources = media.mediaResources else {
                completion(false)
                return
            }

            let resourcesToDelete = indexes
                .filter { $0 < resources.count }
                .map { resources[$0] }
            sdCardViewModel?.deleteResources(resourcesToDelete, of: item) { success in
                completion(success)
            }

        case .mobileDevice:
            deviceViewModel?.deleteResourcesAt(indexes, of: media) { success in
                completion(success)
            }

        default:
            return
        }
    }

    /// Set selected media types.
    ///
    /// - Parameters:
    ///    - types: selected media types
    func setSelectedMediaTypes(types: [GalleryMediaType]) {
        let copy = self.state.value.copy()
        copy.selectedMediaTypes = types
        self.state.set(copy)
    }

    /// Set source type.
    ///
    /// - Parameters:
    ///    - type: source type
    func setSourceType(type: GallerySourceType) {
        let copy = self.state.value.copy()
        copy.sourceType = type
        self.state.set(copy)
    }

    /// Fetch a media.
    ///
    /// - Parameters:
    ///    - media: GalleryMedia
    ///    - index: index of image
    ///    - completion: completion block
    func fetchMedia(_ media: GalleryMedia, _ index: Int = 0, completion: @escaping (URL?) -> Void) {
        switch media.source {
        case .droneSdCard:
            guard let mediaItem = media.mediaItem(for: index),
                  let mediaResource = media.mediaResource(for: index)
            else {
                completion(nil)
                return
            }

            sdCardViewModel?.downloadPreviews(media: mediaItem,
                                              resources: [mediaResource],
                                              completion: { url in
                                                completion(url)
                                              })
        case .droneInternal:
            guard let mediaItem = media.mediaItem(for: index),
                  let mediaResource = media.mediaResource(for: index),
                  downloadStatus != .running  else {
                completion(nil)
                return
            }

            internalViewModel?.downloadResource(media: mediaItem,
                                                resources: [mediaResource],
                                                completion: { url in
                                                    completion(url)
                                                })
        case .mobileDevice:
            guard let urls = media.urls,
                  urls.count > index else {
                completion(nil)
                return
            }

            completion(urls[index])
        default:
            return
        }
    }

    /// Get a media from its index.
    ///
    /// - Parameters:
    ///    - index: Media index in the gallery media array
    /// - Returns: gallery media.
    func getMedia(index: Int) -> GalleryMedia? {
        if index >= 0,
           index < numberOfMedias {
            return self.state.value.medias[index]
        }
        return nil
    }

    /// Get a media from sortedFilteredMedias with specified index
    ///
    /// - Parameters:
    ///    - index: Media index in the sorted filtered media
    /// - Returns: gallery media.
    func getFilteredMedia(index: Int) -> GalleryMedia? {
        guard index >= 0,
              index < state.value.filteredMedias.count else {
            return nil
        }
        return state.value.filteredMedias[index]
    }

    /// Get a media index.
    ///
    /// - Parameters:
    ///    - media: GalleryMedia
    func getMediaIndex(_ media: GalleryMedia) -> Int? {
        return self.state.value.medias.firstIndex(of: media)
    }

    /// Get a media number of images.
    ///
    /// - Parameters:
    ///    - media: GalleryMedia
    /// - Returns: a gallery media.
    func getMediaImageCount(_ media: GalleryMedia, previewableOnly: Bool = false) -> Int {
        switch media.source {
        case .droneSdCard, .droneInternal:
            let resources = previewableOnly ? media.previewableResources : media.mediaResources
            return resources?.count ?? 0
        case .mobileDevice:
            let urls = previewableOnly ? media.previewableUrls : media.urls
            return urls?.count ?? 0
        default:
            return 0
        }
    }

    /// Returns the URL of a given media resource if it has been downloaded or cached.
    ///
    /// - Parameters:
    ///    - media: the media containing the resource to look for
    ///    - index: the index of the resource to look for
    /// - Returns: the URL of the resource if found, `nil` otherwise
    func mediaResourceUrl(_ media: GalleryMedia?, at index: Int) -> URL? {
        guard let media = media else { return nil }

        if media.source == .mobileDevice {
            guard let urls = media.previewableUrls, index < urls.count else { return nil }
            // URLs are already stored in `GalleryMedia` object if source is device.
            return urls[index]
        }

        guard let resources = media.previewableResources, index < resources.count else { return nil }

        let resource = resources[index]
        if resource.type == .panorama,
           let url = AssetUtils.shared.panoramaResourceUrlForMediaId(media.uid) {
            // Local panorama resource exists => use local url.
            return url
        }

        if let url = resource.galleryURL(droneId: drone?.uid, mediaType: media.type),
           resource.isDownloaded(droneId: drone?.uid, mediaType: media.type) {
            // Resource has been downloaded to device => use local url.
            return url
        }

        // Return cached image URL if any, nil otherwise.
        return resources[index].cachedImgUrlExist(droneId: drone?.uid) ?
        resources[index].cachedImgUrl(droneId: drone?.uid) :
        nil
    }

    /// Get a media preview image url.
    ///
    /// - Parameters:
    ///    - media: GalleryMedia
    ///    - index: index of image
    ///    - completion: completion block
    func getMediaPreviewImageUrl(_ media: GalleryMedia, _ index: Int = 0, completion: @escaping (URL?) -> Void) {
        switch media.source {
        case .droneSdCard:
            sdCardViewModel?.getMediaPreviewImageUrl(media, index, completion: { [weak self] url in
                if url != nil {
                    completion(url)
                } else {
                    self?.fetchMedia(media, index, completion: completion)
                }
            })
        case .droneInternal:
            internalViewModel?.getMediaPreviewImageUrl(media, index, completion: { [weak self] url in
                if url != nil {
                    completion(url)
                } else {
                    self?.fetchMedia(media, index, completion: completion)
                }
            })
        case .mobileDevice:
            fetchMedia(media, index, completion: completion)
        default:
            return
        }
    }

    /// Returns an array containing the URL of all linked resources based on a specific previewable resource's index.
    ///
    /// - Parameters:
    ///    - media: the media containing the resources URLs to gather
    ///    - previewableIndex: the previewable resource index to base the gathering on
    /// - Returns: the array containing all linked resources
    func getLinkedResourcesUrls(media: GalleryMedia, previewableIndex: Int) async -> [URL] {
        // Gather all linked urls (previewable AND non-previewable) for media's previewable
        // resource number `index`.
        var linkedUrls = [URL]()
        for index in media.linkedResourcesIndexes(for: previewableIndex) {
            if let url = try? await getMediaPreviewImageUrl(media, index) {
                linkedUrls.append(url)
            }
        }

        return linkedUrls
    }

    /// Get a media default index for image picker.
    ///
    /// - Parameters:
    ///    - media: GalleryMedia
    /// - Returns: default index for image picker.
    func getMediaImageDefaultIndex(_ media: GalleryMedia) -> Int {
        switch media.type {
        case .bracketing:
            return Int((Float(getMediaImageCount(media)) / 2).rounded(.up))
        default: return 0
        }
    }

    // Get available storage on current source, in giga bytes.
    func getAvailableSpace() -> Double {
        switch sourceType {
        case .droneSdCard:
            return sdCardViewModel?.availableSpace ?? 0.0
        case .droneInternal:
            return internalViewModel?.availableSpace ?? 0.0
        case .mobileDevice:
            return deviceViewModel?.availableSpace ?? 0.0
        default:
            return 0.0
        }
    }
}

// MARK: - Internal Async/Await Funcs
extension GalleryMediaViewModel {
    /// Get a media preview image url (`async/await` version).
    ///
    /// - Parameters:
    ///    - media: GalleryMedia.
    ///    - index: index of image.
    ///
    /// - returns async:
    ///    - The media's preview image's `URL`.
    func getMediaPreviewImageUrl(_ media: GalleryMedia, _ index: Int = 0) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            getMediaPreviewImageUrl(media, index) { url in
                // Throws an error if the completion block returns no url.
                guard let url = url else {
                    continuation.resume(throwing: GalleryMediaError.mediaPreviewImageUrlNotFound)
                    return
                }
                // Returns the url.
                continuation.resume(returning: url)
            }
        }
    }
}

// MARK: - Private Funcs
private extension GalleryMediaViewModel {
    /// Reset listeners.
    func resetListeners() {
        sdCardViewModel?.unregisterListener(sdCardListener)
        sdCardListener = nil
        internalViewModel?.unregisterListener(internalListener)
        internalListener = nil
        deviceViewModel?.unregisterListener(deviceListener)
        deviceListener = nil
        // Reset media list refs in order to avoid unwanted media server updates
        // when VM is not active.
        sdCardViewModel?.resetMediaRef()
        internalViewModel?.resetMediaRef()
    }

    /// Init gallery SD Card view Model.
    func initGallerySDCardViewModel() {
        self.sdCardViewModel = GallerySDMediaViewModel.shared
        sdCardListener = self.sdCardViewModel?.registerListener(didChange: { [weak self] state in
            guard let strongSelf = self else { return }

            let copy = strongSelf.state.value.copy()
            if strongSelf.sourceType == .droneSdCard {
                copy.medias = state.medias
                copy.availableSpace = state.availableSpace
            }
            copy.isFormatNeeded = state.isConnected() && state.fileSystemStorageState == .needFormat
            strongSelf.state.set(copy)
            // Publish canFormat state.
            strongSelf.canFormat = state.canFormat
        })

        // Listen to download state changes.
        guard let sdCardViewModel = sdCardViewModel else { return  }
        sdCardViewModel.$downloadProgress
            .combineLatest(sdCardViewModel.$downloadStatus, sdCardViewModel.$downloadingItem)
            .sink { [unowned self] (progress, status, item) in
                downloadProgress = progress
                downloadStatus = status
                downloadingItem = item
            }
            .store(in: &cancellables)
    }

    /// Init gallery Internal view Model.
    func initGalleryInternalViewModel() {
        self.internalViewModel = GalleryInternalMediaViewModel.shared
        internalListener = self.internalViewModel?.registerListener(didChange: { [weak self] state in
            guard let strongSelf = self else { return }

            let copy = strongSelf.state.value.copy()
            if strongSelf.sourceType == .droneInternal {
                copy.medias = state.medias
                copy.availableSpace = state.availableSpace
            }
            strongSelf.state.set(copy)
        })

        // Listen to download state changes.
        guard let internalViewModel = internalViewModel else { return  }
        internalViewModel.$downloadProgress
            .combineLatest(internalViewModel.$downloadStatus, internalViewModel.$downloadingItem)
            .sink { [unowned self] (progress, status, item) in
                downloadProgress = progress
                downloadStatus = status
                downloadingItem = item
            }
            .store(in: &cancellables)
    }

    /// Init gallery device view Model.
    func initGalleryDeviceViewModel() {
        self.deviceViewModel = GalleryDeviceMediaViewModel.shared
        deviceListener = self.deviceViewModel?.registerListener(didChange: { [weak self] state in
            guard let strongSelf = self,
                  strongSelf.sourceType == .mobileDevice,
                  !strongSelf.state.value.isEqual(to: state) else {
                return
            }

            let copy = strongSelf.state.value.copy()
            copy.medias = state.medias
            strongSelf.state.set(copy)
        })
    }
}

// MARK: - Gallery Media Listener
extension GalleryMediaViewModel {
    /// Registers a listener for `GalleryMediaListener`.
    ///
    /// - Parameters:
    ///    - didChange: listener's closure
    /// - Returns: registered listener
    func registerListener(didChange: @escaping GalleryMediaListenerClosure) -> GalleryMediaListener {
        let listener = GalleryMediaListener(didChange: didChange)
        mediaListener.insert(listener)
        // Initial notification.
        listener.didChange(self.state.value)
        return listener
    }

    /// Removes previously registered `GalleryMediaListener`.
    ///
    /// - Parameters:
    ///    - listener: listener to remove
    func unregisterListener(_ listener: GalleryMediaListener?) {
        guard let listener = listener else { return }

        self.mediaListener.remove(listener)
        downloadProgress = nil
        downloadStatus = nil
        downloadingItem = nil
    }

    /// Unregister all listener.
    func unregisterAllListener() {
        self.mediaListener.removeAll()
    }
}
