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
    /// Medias sorted by date.
    private(set) var mediasByDate: [(key: Date, medias: [GalleryMedia])] = []
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
    ///    - downloadingItem: downloading item
    ///    - downloadStatus: download status
    ///    - downloadProgress: download progress
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
                  downloadingItem: MediaItem?,
                  downloadStatus: MediaTaskStatus,
                  downloadProgress: Float,
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
                   downloadingItem: downloadingItem,
                   downloadStatus: downloadStatus,
                   downloadProgress: downloadProgress,
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
    ///    - downloadingItem: downloading item
    ///    - downloadStatus: download status
    ///    - downloadProgress: download progress
    ///    - isRemoving: ViewModel is removing
    ///    - medias: media list
    ///    - selectedMediaType: selected media type
    ///    - sourceType: source type
    ///    - referenceDate: reference date
    required init(connectionState: DeviceState.ConnectionState,
                  availableSpace: Double,
                  capacity: Double,
                  downloadingItem: MediaItem?,
                  downloadStatus: MediaTaskStatus,
                  downloadProgress: Float,
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
                   downloadingItem: downloadingItem,
                   downloadStatus: downloadStatus,
                   downloadProgress: downloadProgress,
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
                                 downloadingItem: self.downloadingItem,
                                 downloadStatus: self.downloadStatus,
                                 downloadProgress: self.downloadProgress,
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
        var sortedData = medias.sorted(by: { $0.date > $1.date })
        if !selectedMediaTypes.isEmpty {
            sortedData = sortedData.filter({selectedMediaTypes.contains($0.type)})
        }
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
}

/// ViewModel for Gallery Media Item.

final class GalleryMediaViewModel: DroneStateViewModel<GalleryMediaState> {
    // MARK: - Private Properties
    private var mediaListener: Set<GalleryMediaListener> = []
    private var mediaInitialClosure: GalleryMediaListenerClosure?
    private var sdCardListener: GallerySdMediaListener?
    private var internalListener: GalleryInternalMediaListener?
    private var deviceListener: GalleryDeviceMediaListener?

    // MARK: - Internal Properties
    var mediaBrowsingViewModel = GalleryMediaBrowsingViewModel()
    var sdCardViewModel: GallerySDMediaViewModel? = GallerySDMediaViewModel.shared
    var internalViewModel: GalleryInternalMediaViewModel? = GalleryInternalMediaViewModel.shared
    var deviceViewModel: GalleryDeviceMediaViewModel? = GalleryDeviceMediaViewModel.shared
    var selectionModeEnabled: Bool = false
    var shouldDisplayFormatOptions: Bool {
        return sourceType == .droneSdCard
    }

    var mediaStore: MediaStore? {
        switch sourceType {
        case .droneSdCard:
            return sdCardViewModel?.mediaStore
        case .droneInternal:
            return internalViewModel?.mediaStore
        default:
            return nil
        }
    }

    // MARK: - Public Properties
    public var selectedMediaTypes: [GalleryMediaType] {
        return self.state.value.selectedMediaTypes
    }
    public var sourceType: GallerySourceType? {
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
        return self.state.value.medias.count
    }
    public var numberOfImages: Int {
        return self.state.value.medias.filter({$0.type != .video}).count
    }
    public var numberOfVideos: Int {
        return self.state.value.medias.filter({$0.type == .video}).count
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
    func canGeneratePanorama(media: GalleryMedia) -> Bool {
        switch sourceType {
        case .mobileDevice:
            return media.canGeneratePanorama
        case .droneSdCard,
             .droneInternal:
            return deviceViewModel?.getMediaFromUid(media.uid)?.canGeneratePanorama ?? media.type.isPanorama
        default:
            return false
        }
    }

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
                  let mediaResource = media.mediaResource(for: index) else {
                return
            }

            sdCardViewModel?.downloadResource(media: mediaItem,
                                              resources: [mediaResource],
                                              completion: { url in
                                                completion(url)
                                              })
        case .droneInternal:
            guard let mediaItem = media.mediaItem(for: index),
                  let mediaResource = media.mediaResource(for: index) else {
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
        if index < numberOfMedias {
            return self.state.value.medias[index]
        }
        return nil
    }

    /// Get a media from its uid.
    ///
    /// - Parameters:
    ///    - uid: uid
    /// - Returns: a gallery media.
    func getMediaFromUid(_ uid: String) -> GalleryMedia? {
        return self.state.value.medias.first { $0.uid == uid.prefix(AssetUtils.Constants.prefixLength) }
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
    func getMediaImageCount(_ media: GalleryMedia) -> Int {
        switch media.source {
        case .droneSdCard:
            return media.mediaResources?.count ?? 0
        case .droneInternal:
            return media.mediaResources?.count ?? 0
        case .mobileDevice:
            return media.urls?.count ?? 0
        default:
            return 0
        }
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

    /// Get a media default index for image picker.
    ///
    /// - Parameters:
    ///    - media: GalleryMedia
    /// - Returns: default index for image picker.
    func getMediaImageDefaultIndex(_ media: GalleryMedia) -> Int {
        guard media.type == .bracketing,
              getMediaImageCount(media) > 0,
              getMediaImageCount(media) % 2 != 0 else {
            return 0
        }

        let imageCount = getMediaImageCount(media)
        let middleEntry = imageCount - (imageCount - 1) / 2

        return middleEntry - 1
    }

    /// Get a media image title for image picker.
    ///
    /// - Parameters:
    ///    - media: GalleryMedia
    ///    - index: index of image
    /// - Returns: title
    func getMediaImagePickerTitle(_ media: GalleryMedia, index: Int) -> String {
        switch media.type {
        case .bracketing:
            guard getMediaImageCount(media) > 0,
                  getMediaImageCount(media) % 2 != 0 else {
                return "\(index + 1)"
            }

            let imageCount = getMediaImageCount(media)
            let value = index - (imageCount - 1) / 2

            return "\(value > 0 ? "+" : "")\(value)"
        case .dng:
            switch media.source {
            case .droneSdCard:
                guard let mediaResources = media.mediaResources,
                      index < mediaResources.count else {
                    return "\(index + 1)"
                }

                return mediaResources[index].format.description.uppercased()
            case .droneInternal:
                guard let mediaResources = media.mediaResources,
                      index < mediaResources.count else {
                    return "\(index + 1)"
                }

                return mediaResources[index].format.description.uppercased()
            case .mobileDevice:
                guard let urls = media.urls,
                      index < urls.count else {
                    return "\(index + 1)"
                }

                return urls[index].pathExtension.uppercased()
            default:
                return "\(index + 1)"
            }
        case .pano360,
             .panoWide,
             .panoVertical,
             .panoHorizontal:
            guard let urls = media.urls,
                  index < urls.count else {
                return "\(index + 1)"
            }

            let panoramaRelatedEntries = PanoramaMediaType.allCases.map({ $0.rawValue })
            if panoramaRelatedEntries.contains(where: urls[index].lastPathComponent.contains) {
                let matchingTerms = panoramaRelatedEntries.filter({ urls[index].lastPathComponent.contains($0) })
                if let panoramaType = matchingTerms.first {
                    return panoramaType
                } else {
                    return "\(index + 1)"
                }
            } else {
                let panoramaRelatedUrls = urls.filter({panoramaRelatedEntries.contains(where: $0.lastPathComponent.contains)})
                return "\(index - panoramaRelatedUrls.count + 1)"
            }
        default:
            return "\(index + 1)"
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
    }

    /// Init gallery SD Card view Model.
    func initGallerySDCardViewModel() {
        self.sdCardViewModel = GallerySDMediaViewModel.shared
        sdCardListener = self.sdCardViewModel?.registerListener(didChange: { [weak self] state in
            guard let strongSelf = self else { return }

            let copy = strongSelf.state.value.copy()
            if strongSelf.sourceType == .droneSdCard {
                copy.medias = state.medias
                copy.downloadingItem = state.downloadingItem
                copy.availableSpace = state.availableSpace
            }
            copy.downloadStatus = state.downloadStatus
            copy.downloadProgress = state.downloadProgress
            strongSelf.state.set(copy)
        })
    }

    /// Init gallery Internal view Model.
    func initGalleryInternalViewModel() {
        self.internalViewModel = GalleryInternalMediaViewModel.shared
        internalListener = self.internalViewModel?.registerListener(didChange: { [weak self] state in
            guard let strongSelf = self else { return }

            let copy = strongSelf.state.value.copy()
            if strongSelf.sourceType == .droneInternal {
                copy.medias = state.medias
                copy.downloadingItem = state.downloadingItem
                copy.availableSpace = state.availableSpace
            }
            copy.downloadStatus = state.downloadStatus
            copy.downloadProgress = state.downloadProgress
            strongSelf.state.set(copy)
        })
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
    }

    /// Unregister all listener.
    func unregisterAllListener() {
        self.mediaListener.removeAll()
    }
}
