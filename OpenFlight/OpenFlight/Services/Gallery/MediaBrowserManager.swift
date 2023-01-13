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
    static let tag = ULogTag(name: "MediaBrowserManager")
}

/// A manager for gallery medias browsing.
final class MediaBrowserManager {

    /// The media services.
    let mediaServices: MediaServices
    /// The camera recording service.
    let cameraRecordingService: CameraRecordingService
    /// The media list.
    @Published private(set) var mediaList = [GalleryMedia]()
    /// The active media (non-optional, as it is set at init-time).
    @Published private(set) var activeMedia: GalleryMedia
    /// The active resource index.
    @Published private(set) var activeResourceIndex = 0
    /// The state of gallery controls (shown if `true`, hidden else).
    @Published private(set) var areControlsShown = true
    /// Whether video playback is muted.
    @Published private(set) var isVideoMuted = true
    /// The  media located at `activeMediaIndex` (if any).
    var activeFilteredMedia: GalleryMedia? { filteredMedia(at: activeMediaIndex) }
    /// The download task state.
    @Published private(set) var downloadTaskState: (progress: Float?, status: MediaTaskStatus?) = (nil, nil)
    /// The enabled action types.
    @Published private(set) var availableActionTypes: GalleryActionType = []
    /// The currently active action types.
    @Published private(set) var activeActionTypes: GalleryActionType = []
    /// The publisher for the identifiers of the medias currently downloaded.
    var downloadIdsPublisher: AnyPublisher<[(uid: String, customTitle: String?)], Never> { mediaStoreService.downloadIdsPublisher }
    /// The publisher for the identifiers of the medias currently downloaded.
    var deleteUidsPublisher: AnyPublisher<Set<String>, Never> { mediaStoreService.deleteUidsPublisher }
    /// The publisher for an active media change event.
    var activeMediaDidChangePublisher: AnyPublisher<GalleryMedia?, Never> { activeMediaDidChangeSubject.eraseToAnyPublisher() }

    /// The navigation-related delegate.
    weak var delegate: GalleryNavigationDelegate?

    // MARK: - Private Properties
    /// The cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// The active media index.
    private var activeMediaIndex: Int
    /// The active media did change subject.
    private var activeMediaDidChangeSubject = PassthroughSubject<GalleryMedia?, Never>()
    /// The filter applied to media list.
    private let filter: Set<GalleryMediaType>
    /// The filtered media list.
    private var filteredMediaList: [GalleryMedia] { mediaList.filtered(by: filter) }
    /// The task monitoring controls appearance.
    private var controlsDisplayTask: AnyCancellable?
    /// The media list service.
    private var mediaListService: MediaListService { mediaServices.mediaListService }
    /// The media store service.
    private var mediaStoreService: MediaStoreService { mediaServices.mediaStoreService }
    /// The shareable URLs.
    private var shareableResourcesUrls: [URL]? {
        activeMedia.source.isDeviceSource ?
        // `urls` array contains all shareable resources URLs.
        activeMedia.urls :
        // Return URLs pointed by downloaded version of media in case of drone's memory.
        mediaListService.deviceMedia(for: activeMedia)?.urls
    }

    // MARK: Init
    /// Constructor.
    ///
    /// - Parameters:
    ///    - mediaServices: the media services
    ///    - cameraRecordingService: the camera recording service
    ///    - activeMediaIndex: the active media index
    ///    - activeMedia: the active media
    ///    - filter: the filter to apply to media list
    init(mediaServices: MediaServices,
         cameraRecordingService: CameraRecordingService,
         activeMediaIndex: Int,
         activeMedia: GalleryMedia,
         filter: Set<GalleryMediaType>) {
        self.mediaServices = mediaServices
        self.cameraRecordingService = cameraRecordingService
        self.activeMediaIndex = activeMediaIndex
        self.activeMedia = activeMedia
        self.filter = filter

        listen(to: mediaListService)
        listen(to: mediaStoreService)
    }

    deinit {
        // Stop any ongoing stream replay in order to release resource.
        mediaServices.streamReplayService.stop()
    }
}

// MARK: - Actions Public Helpers
extension MediaBrowserManager {

    /// Whether a specific action is available (shown in controller).
    ///
    /// - Parameter action: the action to check
    /// - Returns: whether the action is available
    func isAvailable(_ action: GalleryActionType) -> Bool { availableActionTypes.contains(action) }

    /// Whether a specific action is active.
    ///
    /// - Parameter action: the action to check
    /// - Returns: whether the action is active
    func isActionActive(_ action: GalleryActionType) -> Bool { activeActionTypes.contains(action) }
}

extension MediaBrowserManager {

    // MARK: Browsing
    /// Returns the media located before a specific media in the filtered list.
    ///
    /// - Parameter media: the reference media
    /// - Returns: the media located before `media` in the filtered list (if any)
    func filteredMediaBefore(media: GalleryMedia?) -> GalleryMedia? {
        guard let media = media,
              let index = filteredMediaList.firstIndex(where: { $0.isSameMedia(as: media) }),
              index > 0 else { return nil }
        return filteredMediaList[index - 1]
    }

    /// Returns the media located after a specific media in the filtered list.
    ///
    /// - Parameter media: the reference media
    /// - Returns: the media located after `media` in the filtered list (if any)
    func filteredMediaAfter(media: GalleryMedia?) -> GalleryMedia? {
        guard let media = media,
              let index = filteredMediaList.firstIndex(where: { $0.isSameMedia(as: media) }),
              index < filteredMediaList.count - 1 else { return nil }
        return filteredMediaList[index + 1]
    }

    // MARK: Controls
    /// Shows browser control.
    func showControls() {
        areControlsShown = true
        // Start timer for auto-hiding.
        startControlsTimer()
    }

    /// Hides browser control.
    func hideControls() {
        areControlsShown = false
        // Disable auto-hiding timer.
        cancelControlsTimer()
    }

    /// Disables controls auto-hiding.
    func disableControlsAutohiding() {
        cancelControlsTimer()
    }

    // MARK: Medias
    /// Asks delegate to close screen because of empty media to browse.
    func noMediaToBrowse() {
        delegate?.closeMediaBrowser()
    }

    /// Sets a specific media as active media (informs any listener of currently displayed media).
    ///
    /// - Parameters:
    ///    - media: the active media
    ///    - forceUpdate: whether the media should be updated even if same as currently active
    func setActiveMedia(_ media: GalleryMedia, forceUpdate: Bool = false) {
        guard !activeMedia.isSameMedia(as: media) || forceUpdate else { return }
        activeMedia = media
        activeMediaIndex = index(of: media) ?? activeMediaIndex
        updateActionsAvailability()
    }

    /// Sets a specific resource index as active resource index (informs any listener of currently displayed resource's index).
    ///
    /// - Parameter index: the index of the active resource
    func setActiveResourceIndex(_ index: Int) {
        guard index != activeResourceIndex else { return }
        activeResourceIndex = index
        updateActionsAvailability()
    }

    /// Gets the action state of a specific media.
    ///
    /// - Parameter media: the media to check
    /// - Returns: the action state of the media
    func actionState(of media: GalleryMedia) -> GalleryMediaActionState {
        mediaListService.actionState(of: media)
    }

    /// Cancels ongoing download.
    func cancelDownload() {
        mediaStoreService.cancelDownload()
    }

    /// Deletes active media.
    func deleteActiveMedia() {
        Task {
            start(action: .delete)
            do {
                try await mediaListService.delete(medias: [activeMedia])
            } catch {
                let message = activeMedia.source.deleteErrorMessage(count: 1)
                DispatchQueue.main.async {
                    self.delegate?.showActionErrorAlert(message: message,
                                                        retryAction: self.deleteActiveMedia)
                }
            }
            stop(action: .delete)
        }
    }

    /// Deletes active resource.
    func deleteActiveResource() {
        start(action: .delete)
        let indexes: [Int]
        if activeMedia.source.isDeviceSource {
            indexes = activeMedia.linkedResourcesIndexes(for: activeResourceIndex)
        } else {
            let unsortedResources = activeMedia.mediaItems?.reduce([]) { $0 + $1.resources }
            guard let uid = activeMedia.mediaResource(for: activeResourceIndex)?.uid,
                  let unsortedResourceIndex = unsortedResources?.firstIndex(where: { $0.uid == uid}) else { return }
            indexes = activeMedia.linkedResourcesIndexes(for: unsortedResourceIndex)
        }
        Task {
            do {
                try await mediaListService.deleteResources(of: activeMedia, at: indexes)
            } catch {
                let message = activeMedia.source.deleteErrorMessage(count: 1)
                DispatchQueue.main.async {
                    self.delegate?.showActionErrorAlert(message: message,
                                                        retryAction: self.deleteActiveResource)
                }
            }
        }
        stop(action: .delete)
    }

    /// Fetches a media's resource located at a specific index.
    ///
    /// - Parameters:
    ///    - media: the media to fectch the resources from
    ///    - resourceIndex: the index of the resource to fetch
    ///    - delay: the optional delay to sleep before actually starting to fetch
    /// - Returns: the media resource image
    func fetchResource(of media: GalleryMedia,
                       at resourceIndex: Int,
                       after delay: TimeInterval? = nil) async throws -> UIImage? {
        try await mediaListService.fetchResource(of: media, at: resourceIndex, after: delay)
    }

    /// Prefetches either the resources of the medias contiguous to `media`, or the resources of `media`
    /// contiguous to the resource located at `resourceIndex`.
    ///
    /// - Parameters:
    ///    - media: the media to fetch around
    ///    - resourceIndex: the resource index to fetch around
    func startPrefetch(for media: GalleryMedia, around resourceIndex: Int) {
        if resourceIndex == 0 {
            // Prefetch contiguous medias if browser displays first resource of the media
            // in order to anticipate horizontal scrolling first.
            prefetchMedias(around: media)
        } else {
            // Vertical scrolling has started => favors resources prefetch.
            prefetchResources(of: media, around: resourceIndex)
        }
    }
}

// MARK: - User Interaction
extension MediaBrowserManager {

    /// Asks delegate to close browser.
    func didTapBack() {
        delegate?.closeMediaBrowser()
    }

    /// Downloads active media.
    func didTapDownload() {
        start(action: .download)
        Task {
            for await status in mediaListService.download(medias: [activeMedia]) where status == .error {
                DispatchQueue.main.async {
                    self.delegate?.showActionErrorAlert(message: L10n.galleryDownloadError,
                                                        retryAction: self.didTapDownload)
                }
            }
        }
        stop(action: .download)
    }

    /// Asks delegate to show delete popup confirmation according to active ressources count.
    func didTapDelete() {
        let count = activeMedia.previewableResourcesCount
        if count > 1 {
            // Media has more than 1 resource.
            // => Need to know if user wants to remove displayed resource only, or full media.
            delegate?.showDeleteMediaOrResourceAlert(message: activeMedia.source.deleteResourceConfirmMessage(count: count),
                                                     resourcesCount: count,
                                                     mediaAction: deleteActiveMedia,
                                                     resourceAction: deleteActiveResource)
        } else {
            delegate?.showDeleteConfirmationPopup(message: activeMedia.source.deleteConfirmMessage(count: 1),
                                                  action: deleteActiveMedia)
        }
    }

    /// Toggles video mute state.
    func didTapMute() {
        isVideoMuted.toggle()
    }

    /// Toggles controls showing state.
    func didSingleTap() {
        areControlsShown.toggle()
        if areControlsShown {
            startControlsTimer()
        } else {
            cancelControlsTimer()
        }
    }

    /// Asks delegate to show panorama generation screen for active media.
    func didTapGeneratePanorama() {
        delegate?.showPanoramaGenerationScreen(for: activeMedia)
    }

    /// Asks delegate to show immersive panorama screen for active resource.
    func didTapShowImmersivePanorama() {
        delegate?.showImmersivePanoramaScreen(url: activeMedia.resourceUrl(at: activeResourceIndex))
    }

    /// Asks delegate to show sharing screen for active media.
    ///
    /// - Parameter srcView: the source view of the sharing process
    func didTapShare(srcView: UIView) {
        guard let delegate = delegate, let urls = shareableResourcesUrls else { return }
        start(action: .share)
        DispatchQueue.main.async { [weak self] in
            delegate.showSharingScreen(fromView: srcView, items: urls) {
                self?.stop(action: .share)
            }
        }
    }
}

private extension MediaBrowserManager {

    /// Listens to media list service in order to update states accordingly.
    ///
    /// - Parameter mediaListService: the media list service
    func listen(to mediaListService: MediaListService) {
        mediaListService.mediaListPublisher
            .sink { [weak self] list in
                self?.updateMediaList(with: list)
            }
            .store(in: &cancellables)
    }

    /// Listens to media store service in order to update states accordingly.
    ///
    /// - Parameter mediaStoreService: the media store service
    func listen(to mediaStoreService: MediaStoreService) {
        mediaStoreService.downloadTaskStatePublisher
            .sink { [weak self] state in
                self?.downloadTaskState = state
            }
            .store(in: &cancellables)
    }
}

// MARK: - Controls
private extension MediaBrowserManager {

    private enum ControlsConstants {
        static let autoHideDelay: TimeInterval = 2
    }

    /// Cancels auto-hiding controls timer.
    func cancelControlsTimer() {
        controlsDisplayTask?.cancel()
    }

    /// Starts auto-hiding controls timer.
    func startControlsTimer() {
        cancelControlsTimer()
        controlsDisplayTask = Just(true)
            .delay(for: .seconds(ControlsConstants.autoHideDelay), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                // Duration elapsed => auto-hide controls.
                self?.hideControls()
            }
    }

    /// Updates browser actions availability according to active media.
    func updateActionsAvailability() {
        let isActiveMediaDownloaded = actionState(of: activeMedia) == .downloaded
        update(.share, isAvailable: isActiveMediaDownloaded)
        update(.download, isAvailable: !isActiveMediaDownloaded)
        update(.mute, isAvailable: activeMedia.type == .video && activeMedia.source.isDeviceSource)
        update(.delete, isAvailable: !activeMedia.needsPanoGeneration || activeResourceIndex != 0)
    }
}

private extension MediaBrowserManager {

    /// Updates media list and asks delegate to close browser if there's no media to display.
    ///
    /// - Parameter list: the media list
    func updateMediaList(with list: [GalleryMedia]) {
        mediaList = list

        if list.first(where: { $0.isSameMedia(as: activeMedia) }) == nil {
            // Provided list does not contain active media anymore
            // => update listeners with new active media (if any).
            let media = filteredMediaList.isEmpty ? nil : filteredMediaList[min(activeMediaIndex, filteredMediaList.count - 1)]
            activeMediaDidChangeSubject.send(media)
        }
    }

    /// Returns the filtered media list without any media matching `ignoredTypes` (if specified).
    ///
    /// - Parameter ignoredTypes: the set of types to ignore in filtered media list
    /// - Returns: the filtered media list without any media matching `ignoredTypes` if specified, the original filtered media list otherwise
    func filteredMediaList(ignoredTypes: Set<GalleryMediaType>? = nil) -> [GalleryMedia] {
        if let ignoredTypes = ignoredTypes {
            return filteredMediaList.filter({ !ignoredTypes.contains($0.type) })
        }

        return filteredMediaList
    }

    /// Returns the media located at a specific index in filtered list (if any).
    ///
    /// - Parameters:
    ///    - index: the index of the media to gather
    ///    - ignoredTypes: the set of types to ignore in filtered media list
    func filteredMedia(at index: Int, ignoredTypes: Set<GalleryMediaType>? = nil) -> GalleryMedia? {
        let list = filteredMediaList(ignoredTypes: ignoredTypes)
        guard index >= 0, index < list.count else { return nil }
        return list[index]
    }

    /// Returns the index of a specific media in filtered list (if any).
    ///
    /// - Parameters:
    ///    - media: the media to look for
    ///    - ignoredTypes: the set of types to ignore in filtered media list
    func index(of media: GalleryMedia, ignoredTypes: Set<GalleryMediaType>? = nil) -> Int? {
        filteredMediaList(ignoredTypes: ignoredTypes)
            .firstIndex(where: { $0.isSameMedia(as: media) })
    }
}

// MARK: - Prefetch
private extension MediaBrowserManager {

    // MARK: - Constants
    struct PrefetchConstants {
        static let mediasPrefetchSize = 2
        static let resourcesInitPrefetchSize = 2
        static let resourcesFullPrefetchSize = 4
    }

    /// Returns an async throwing stream sequence which downloads a range of contiguous resources previews from `media`.
    ///
    /// The range is built in order to first download resource from `resourceIndex`, and then the `Constants.resourcesFullPrefetchSize`
    /// resources located after, and then before.
    ///
    /// - Parameters:
    ///    - media: the media containing the resources to preview-download
    ///    - resourceIndex: the index of the main resource
    /// - Returns: the async throwing stream download sequence
    @discardableResult
    func prefetchResources(of media: GalleryMedia, around resourceIndex: Int) -> AsyncThrowingStream<MediaTaskStatus, Error> {
        AsyncThrowingStream { continuation in
            guard let mediaItem = media.mediaItem(for: resourceIndex),
                  let resources = media.previewableResources,
                  resourceIndex < resources.count else {
                continuation.finish(throwing: MediaStoreError.prefetchError)
                return
            }

            // Create the resources array.
            var resourcesToFetch = [MediaItem.Resource]()

            // Create before and after prefetch ranges.
            let fromIndex = resourceIndex - PrefetchConstants.resourcesFullPrefetchSize
            let toIndex = resourceIndex + PrefetchConstants.resourcesFullPrefetchSize + 1
            let fromRange = (fromIndex..<resourceIndex)
                .clamped(to: 0..<resources.count)
            let toRange = (resourceIndex + 1..<toIndex + 1)
                .clamped(to: 0..<resources.count)

            // Append 'after' range first, as we prioritize "next item"-scrolling.
            resourcesToFetch.append(contentsOf: resources[toRange])
            // Append 'before' range in reversed order in order to fetch closest resources first.
            resourcesToFetch.append(contentsOf: resources[fromRange].reversed())
            // Remove any resource already present in cache.
            resourcesToFetch = resourcesToFetch.filter({ !$0.cachedImgUrlExist(droneId: media.droneUid) })

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
                for await status in mediaStoreService.downloadPreviews(mediaResources: mediaResources) {
                    guard status != .error else {
                        continuation.finish(throwing: MediaStoreError.prefetchError)
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
    ///
    /// The range is built in order to first download the`Constants.resourcesInitPrefetchSize` first resources of `media`,
    /// and then the first resource of `Constants.mediasPrefetchSize` medias alternatively located after and before.
    ///
    /// - Parameter media: the main media
    /// - Returns: the async throwing stream download sequence
    @discardableResult
    func prefetchMedias(around media: GalleryMedia) -> AsyncThrowingStream<MediaTaskStatus, Error> {
        AsyncThrowingStream { continuation in
            guard let mainMediaItem = media.mainMediaItem,
                  let mediaIndex = index(of: media, ignoredTypes: [.video]) else {
                continuation.finish(throwing: MediaStoreError.prefetchError)
                return
            }

            // Create the medias info array.
            var medias = [(MediaItem, Int)]()

            // Alternatively add first resource of next and previous medias, from closest to farthest media.
            for offset in 1...PrefetchConstants.mediasPrefetchSize {
                if let nextMediaItem = filteredMedia(at: mediaIndex + offset, ignoredTypes: [.video])?.mainMediaItem {
                    medias.append((nextMediaItem, 1))
                }
                if let prevMediaItem = filteredMedia(at: mediaIndex - offset, ignoredTypes: [.video])?.mainMediaItem {
                    medias.append((prevMediaItem, 1))
                }
            }

            // Add full resources prefetch size.
            medias.append((mainMediaItem, PrefetchConstants.resourcesFullPrefetchSize))

            // Create downloadable resources list from medias info array.
            let mediaResources = MediaUtils.getDownloadablePreviewableResources(medias: medias, droneId: media.droneUid)

            // Start previews download async sequence and await for its status.
            Task {
                for await status in mediaStoreService.downloadPreviews(mediaResources: mediaResources) {
                    guard status != .error else {
                        continuation.finish(throwing: MediaStoreError.prefetchError)
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

// MARK: - Actions Helpers
private extension MediaBrowserManager {

    /// Sets a specific action as active.
    ///
    /// - Parameter action: the action to update
    func start(action: GalleryActionType) { activeActionTypes.insert(action) }

    /// Sets a specific action as inactive.
    ///
    /// - Parameter action: the action to update
    func stop(action: GalleryActionType) { activeActionTypes.remove(action) }

    /// Makes a specific action available (meaning corresponding control will  be shown).
    ///
    /// - Parameter action: the action to update
    func insert(action: GalleryActionType) { availableActionTypes.insert(action) }

    /// Makes a specific action unavailable (meaning corresponding control will  be hidden).
    ///
    /// - Parameter action: the action to update
    func remove(action: GalleryActionType) { availableActionTypes.remove(action) }

    /// Updates the a availability of a specific action.
    ///
    /// - Parameter action: the action to update
    func update(_ action: GalleryActionType, isAvailable: Bool) {
        isAvailable ? insert(action: action) : remove(action: action)
    }
}
