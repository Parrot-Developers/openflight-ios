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

/// The gallery navigation-related protocol.
protocol GalleryNavigationDelegate: AnyObject {

    /// Closes gallery screen.
    func close()

    /// Shows media browser.
    ///
    /// - Parameters:
    ///    - media: the media to display
    ///    - index: the media's index in filtered media list
    ///    - filter: the filter to apply to media list
    func showMediaBrowser(media: GalleryMedia, index: Int, filter: Set<GalleryMediaType>)

    /// Closes media browser.
    func closeMediaBrowser()

    /// Shows sharing screen.
    ///
    /// - Parameters:
    ///    - fromView: the source view for sharing screen display
    ///    - items: the items to share
    ///    - completion: the completion block
    func showSharingScreen(fromView view: UIView, items: [Any], completion: (() -> Void)?)

    /// Shows formatting screen.
    func showFormattingScreen()

    /// Shows a deletion confirmation popup alert.
    ///
    /// - Parameters:
    ///   - message: the confirmation message to display
    ///   - action: the delete action block
    func showDeleteConfirmationPopup(message: String, action: (() -> Void)?)

    /// Shows an alert for full media or single resource removal choice proposal.
    ///
    /// - Parameters:
    ///    - message: the popup message
    ///    - resourcesCount: the number of resources of the media
    ///    - mediaAction: the media delete action
    ///    - resourceAction: the resource delete action
    func showDeleteMediaOrResourceAlert(message: String,
                                        resourcesCount: Int,
                                        mediaAction: (() -> Void)?,
                                        resourceAction: (() -> Void)?)

    /// Shows an action failure popup alert.
    ///
    /// - Parameters:
    ///   - message: the error message to display
    ///   - retryAction: the retry action block
    func showActionErrorAlert(message: String, retryAction: @escaping () -> Void)

    /// Shows panorama visualisation screen.
    ///
    /// - Parameter url: panorama url
    func showImmersivePanoramaScreen(url: URL?)

    /// Shows panorama generation screen.
    ///
    /// - Parameter media: the panorama media to generate
    func showPanoramaGenerationScreen(for media: GalleryMedia)

    /// Dismisses panorama generation screen.
    func dismissPanoramaGenerationScreen()

    /// Dismisses immersive panorama screen.
    func dismissImmersivePanoramaScreen()
}

/// A media list state for gallery status info display.
enum MediaListState {

    /// List state is unknown.
    case unknown
    /// List is loading.
    case loading
    /// List has been loaded and is empty.
    case empty
    /// List has been loaded and is not empty.
    case available

    /// The info label to display.
    var label: String? {
        switch self {
        case .empty: return L10n.galleryNoMedia
        case .loading: return L10n.galleryLoading
        default: return nil
        }
    }

    /// The icon to display.
    var icon: UIImage? {
        self == .loading ? Asset.Pairing.icloading.image : nil
    }

    /// Whether status info message needs to be displayed for current media list state.
    var hasInfoMessage: Bool {
        self == .empty || self == .loading
    }
}

/// An option set describing the gallery action types.
struct GalleryActionType: OptionSet {
    let rawValue: Int

    static let download = GalleryActionType(rawValue: 1 << 0)
    static let delete = GalleryActionType(rawValue: 1 << 1)
    static let share = GalleryActionType(rawValue: 1 << 2)
    static let select = GalleryActionType(rawValue: 1 << 3)
    static let format = GalleryActionType(rawValue: 1 << 4)
    static let mute = GalleryActionType(rawValue: 1 << 5)

    /// The title of the corresponding button.
    var buttonTitle: String? {
        switch self {
        case .download: return L10n.commonDownload
        case .share: return L10n.commonShare
        default: return nil
        }
    }

    /// The style of the corresponding button.
    var buttonStyle: ActionButtonStyle {
        switch self {
        case .download: return .validate
        default: return .default1
        }
    }
}

/// A view model for the gallery.
final class GalleryViewModel {

    // MARK: Media List
    /// The filtered media list tuples array (organized by date and filtered according to `filterItems`).
    @Published private(set) var filteredMediaData = [(date: Date, medias: [GalleryMedia])]()
    /// The media list state.
    @Published private(set) var mediaListState: MediaListState = .unknown
    /// The publisher for uids of currently selected medias.
    var selectedMediaUidsPublisher: AnyPublisher<Set<String>, Never> { selectedMediaUidsSubject.eraseToAnyPublisher() }
    /// The currently selected medias.
    var selectedMedias: [GalleryMedia] {
        Array(filteredMedias.filter({ selectedMediaUids.contains($0.uid) }))
    }
    /// The filters media types of current media list.
    private(set) var filteredMediaTypes = Set<GalleryMediaType>()
    /// The Select All button title.
    var selectAllButtonTitle: String {
        isAllSelected ? L10n.commonDeselectAll : L10n.commonSelectAll
    }

    // MARK: Filters
    /// The filter items of current media list.
    @Published private(set) var filterItems = [GalleryFilterItem]()

    // MARK: Storage
    /// The publisher for active storage source.
    var storageSourceTypePublisher: AnyPublisher<GallerySourceType, Never> { storageSourceTypeSubject.eraseToAnyPublisher() }
    /// The active storage source details.
    @Published private(set) var sourceDetails = UserStorageDetails()
    /// The SD card error state.
    @Published private(set) var sdCardErrorState: UserStorageState?
    /// Whether active storage can be formatted.
    @Published private(set) var isFormatStorageAvailable = false

    // MARK: Actions
    /// The type of gallery main action (download of share).
    @Published private(set) var mainActionType: GalleryActionType = .download
    /// The enabled action types.
    @Published private(set) var enabledActionTypes: GalleryActionType = []
    /// The currently active action types.
    @Published private(set) var activeActionTypes: GalleryActionType = []
    /// The download task state.
    @Published private(set) var downloadTaskState: (progress: Float?, status: MediaTaskStatus?) = (nil, nil)
    /// The publisher for the identifiers of the medias currently downloaded.
    public var downloadIdsPublisher: AnyPublisher<[(uid: String, customTitle: String?)], Never> { mediaStoreService.downloadIdsPublisher }

    /// The navigation-related delegate.
    weak var delegate: GalleryNavigationDelegate?

    // MARK: - Private Properties
    /// The cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// The media services.
    private let mediaServices: MediaServices
    /// The media store indexing state.
    private var mediaStoreIndexingState: MediaStoreIndexingState = .unavailable
    /// The removable storage state.
    private var removableStorageState: UserStorageState = .unknown
    /// The subject of currently selected medias uids.
    private var selectedMediaUidsSubject = CurrentValueSubject<Set<String>, Never>([])
    /// The filtered media list.
    private var filteredMedias: [GalleryMedia] {
        filteredMediaData.flatMap { $0.medias }
    }
    /// The filtered media list uids.
    private var filteredMediaUids: Set<String> {
        Set(filteredMedias.map { $0.uid })
    }
    /// Whether all medias are selected.
    private var isAllSelected: Bool {
        filteredMediaUids.subtracting(selectedMediaUids).isEmpty
    }
    /// The default storage source type.
    private var defaultStorageSourceSegment: GallerySourceSegment = .device
    /// The current storage source type subject.
    private var storageSourceTypeSubject = CurrentValueSubject<GallerySourceType, Never>(.mobileDevice)
    /// The media list.
    private var medias = [GalleryMedia]()
    /// Whether user storage can be formatted.
    private var canFormatUserStorage = false {
        didSet {
            guard oldValue != canFormatUserStorage else { return }
            updateFormatState()
        }
    }
    /// The active storage source type.
    private(set) var storageSourceType: GallerySourceType {
        get { storageSourceTypeSubject.value }
        set { setStorageSource(newValue) }
    }
    /// The media list service.
    private var mediaListService: MediaListService { mediaServices.mediaListService }
    /// The media store service.
    private var mediaStoreService: MediaStoreService { mediaServices.mediaStoreService }
    /// The user storage service.
    private var userStorageService: UserStorageService { mediaServices.userStorageService }

    // MARK: Init
    /// Constructor.
    ///
    /// - Parameter mediaServices: the media services
    init(mediaServices: MediaServices) {
        self.mediaServices = mediaServices

        listenToMediaListService(mediaListService)
        listenToMediaStoreService(mediaStoreService)
        listenToUserStorageService(userStorageService)
    }
}

// MARK: - Actions Public Helpers
extension GalleryViewModel {

    /// Whether a specific action is enabled.
    ///
    /// - Parameter action: the action to check
    /// - Returns: whether the action is enabled
    func isEnabled(_ action: GalleryActionType) -> Bool { enabledActionTypes.contains(action) }

    /// Whether a specific action is active.
    ///
    /// - Parameter action: the action to check
    /// - Returns: whether the action is active
    func isActionActive(_ action: GalleryActionType) -> Bool { activeActionTypes.contains(action) }
}

// MARK: - User Interaction
extension GalleryViewModel {

    // MARK: Main Action
    /// Performs main gallery action (download or share) according to current main action type.
    ///
    /// - Parameter srcView: the source view for main action (only used for sharing)
    func didTapMainAction(srcView: UIView) {
        Task {
            switch mainActionType {
            case .download:
                download(medias: selectedMedias)
            case .share:
                start(action: .share)
                showSharingScreen(srcView: srcView) { [weak self] in
                    self?.stop(action: .share)
                }
            default: break
            }
        }
    }

    // MARK: Source Selection
    /// Selects default storage source.
    func selectDefaultStorage() {
        setStorageSource(for: defaultStorageSourceSegment)
    }

    /// Sets active storage source according to provided segment.
    ///
    /// - Parameter segment: the source's segment
    func setStorageSource(for segment: GallerySourceSegment) {
        setStorageSource(storageSourceType(for: segment))
    }

    // MARK: Media Selection
    /// Handles media selection for specified media.
    ///
    /// - Parameter media: the selected media
    func didSelectMedia(_ media: GalleryMedia) {
        if activeActionTypes.contains(.select) {
            // Selection mode is enabled => toggle `media` selection state.
            toggleSelection(for: media.uid)
        } else if let index = filteredMediaData.flatMap({ $0.medias }).firstIndex(of: media) {
            // Browsing mode => ask delegate to show media browser for `media`.
            delegate?.showMediaBrowser(media: media,
                                      index: index,
                                      filter: filteredMediaTypes)
        }
    }

    /// The currently selected medias uids.
    var selectedMediaUids: Set<String> {
        get { selectedMediaUidsSubject.value }
        set {
            selectedMediaUidsSubject.value = newValue
            // Update actions availability according to selection.
            updateActionsEnableState()
        }
    }

    /// Sets gallery select mode active state.
    ///
    /// - Parameter isActive: whether select mode needs to be activated
    func setSelectMode(_ isActive: Bool) {
        if isActive {
            start(action: .select)
        } else {
            stop(action: .select)
        }

        // Needs to update format capability state, as it should be unavailable in select mode.
        updateFormatState()

        // Clear any selection when leaving select mode.
        if !isActive {
            deselectAll()
        }
    }

    /// Toggles select mode active state.
    func toggleSelectMode() {
        setSelectMode(!isActionActive(.select))
    }

    /// Toggles Select All state.
    func toggleSelectAll() {
        if isAllSelected {
            deselectAll()
        } else {
            selectAll()
        }
    }

    /// Toggles selection for a specific media uid.
    ///
    /// - Parameter uid: the uid of the media to select/deselect
    func toggleSelection(for uid: String) {
        let isSelected = selectedMediaUids.contains(uid)
        if isSelected {
            deselectMedia(with: uid)
        } else {
            selectMedia(with: uid)
        }
    }

    /// Whether a media with a specific uid is selected.
    ///
    /// - Parameter uid: the uid of the media to check
    func isSelected(uid: String) -> Bool {
        selectedMediaUids.contains(uid)
    }

    // MARK: Download
    /// Requests a download of a gallery medias array to media store.
    ///
    /// - Parameter medias: the media array to download
    func download(medias: [GalleryMedia]) {
        Task {
            for await status in mediaListService.download(medias: medias) where status == .error {
                DispatchQueue.main.async {
                    self.delegate?.showActionErrorAlert(message: L10n.galleryDownloadError,
                                                        retryAction: { self.download(medias: medias) })
                }
            }
        }
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

    // MARK: Filters
    /// Checks if a specific media type is selected for filtering.
    ///
    /// - Parameter type: the media type to check
    /// - Returns: whether the type is selected
    func isFilterMediaTypeSelected(_ type: GalleryMediaType) -> Bool {
        filteredMediaTypes.contains(type)
    }

    /// Updates filters and active medai list according to selected media type.
    ///
    /// - Parameter type: the selected filter media type
    func didSelect(filterMediaType type: GalleryMediaType) {
        // Toggle filter selection.
        if isFilterMediaTypeSelected(type) {
            filteredMediaTypes.remove(type)
        } else {
            filteredMediaTypes.insert(type)
        }
        // Update media list of active storage in order to reflect filters selection.
        updateMediaList()
    }

    // MARK: Delete
    /// Asks delegate to show delete confirmation popup for current selection.
    func didTapDelete() {
        let message: String = storageSourceType.deleteConfirmMessage(count: selectedMedias.count)
        delegate?.showDeleteConfirmationPopup(message: message,
                                                action: deleteSelection)
    }

    /// Deletes current selection.
    func deleteSelection() {
        Task {
            do {
                try await delete(medias: selectedMedias)
            } catch {
                let message = storageSourceType.deleteErrorMessage(count: selectedMedias.count)
                DispatchQueue.main.async {
                    self.delegate?.showActionErrorAlert(message: message,
                                                        retryAction: self.deleteSelection)
                }
            }
        }
    }

    /// Requests a deletion of a specific gallery media array.
    ///
    /// - Parameter medias: the media array to delete
    func delete(medias: [GalleryMedia]) async throws {
        start(action: .delete)

        try await mediaListService.delete(medias: medias)

        stop(action: .delete)
    }

    /// Requests a deletion of a specific resources array from a gallery media.
    ///
    /// - Parameters:
    ///    - indexes: the indexes of the resources to delete
    ///    - media: the gallery media containing the resources to delete
    func deleteResourcesAt(_ indexes: [Int], from media: GalleryMedia) async throws {
        if storageSourceType.isDroneSource {
            guard let item = media.mainMediaItem else { return }
            start(action: .delete)
            try await mediaStoreService.deleteResourcesAt(indexes, from: item)
            stop(action: .delete)
        } else {
            try await AssetUtils.shared.removeResources(at: indexes, from: media)
            // Need to refresh device's media list, as there's no automatic update listener for device storage.
            updateMediaList()
        }
    }
}

// MARK: - Navigation
extension GalleryViewModel {

    /// Asks delegate to close view.
    func close() {
        delegate?.close()
    }

    /// Asks delegate to show sharing screen for currently selected medias.
    ///
    /// - Parameter srcView: the source view of the sharing process
    func showSharingScreen(srcView: UIView, completion: (() -> Void)?) {
        let urls = selectedMedias.urls
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.showSharingScreen(fromView: srcView, items: urls, completion: completion)
        }
    }

    /// Asks delegate to show formatting screen.
    func didTapFormat() {
        delegate?.showFormattingScreen()
    }
}

private extension GalleryViewModel {

    /// Listens to media list service in order to update states accordingly.
    ///
    /// - Parameter mediaListService: the media list service
    func listenToMediaListService(_ mediaListService: MediaListService) {
        mediaListService.mediaListPublisher
            .sink { [weak self] medias in
                self?.medias = medias
                self?.updateMediaList()
            }
            .store(in: &cancellables)
    }

    /// Listens to media store service in order to update states accordingly.
    ///
    /// - Parameter mediaStoreService: the media store service
    func listenToMediaStoreService(_ mediaStoreService: MediaStoreService) {

        mediaStoreService.indexingStatePublisher.removeDuplicates()
            .sink { [weak self] state in
                self?.updateIndexingState(state)
            }
            .store(in: &cancellables)

        mediaStoreService.downloadTaskStatePublisher
            .sink { [weak self] state in
                self?.downloadTaskState = state
            }
            .store(in: &cancellables)
    }

    /// Listens to user storage service in order to update states accordingly.
    ///
    /// - Parameter userStorageService: the user storage service
    func listenToUserStorageService(_ userStorageService: UserStorageService) {
        userStorageService.removableStorageStatePublisher
            .removeDuplicates()
            .sink { [weak self] state in
                guard let self = self else { return }
                self.updateRemovableStorageState(state)
            }
            .store(in: &cancellables)

        userStorageService.formattingStatePublisher
            .sink { [weak self] state in
                if case .available = state {
                    self?.canFormatUserStorage = true
                } else {
                    self?.canFormatUserStorage = false
                }
            }
            .store(in: &cancellables)

        userStorageService.removableStorageDetailsPublisher.sink { [weak self] details in
            guard let self = self else { return }
            self.defaultStorageSourceSegment = details.isOffline ? .device : .drone
            guard self.storageSourceType == .droneSdCard else { return }
            self.sourceDetails = details
        }
        .store(in: &cancellables)

        userStorageService.internalStorageDetailsPublisher.sink { [weak self] details in
            guard self?.storageSourceType == .droneInternal else { return }
            self?.sourceDetails = details
        }
        .store(in: &cancellables)
    }
}

private extension GalleryViewModel {

    // MARK: Media List

    /// Updates active media list according to selected storage source.
    func updateMediaList() {
        // Get filter items from media array.
        updateFilterItems(from: medias)
        // Ensure selected filter types are all valid items (may correspond to an empty media list after media deletion).
        filteredMediaTypes = filteredMediaTypes.intersection(Set(filterItems.map({ $0.type })))
        // Update actual media list data.
        filteredMediaData = medias.orderedByDate(filter: filteredMediaTypes)
        // Update UI components for new list.
        updateMediaListState()
        // Select action is enabled only if a media list is available.
        update(.select, isEnabled: mediaListState == .available)
    }

    /// Updates media store indexing state according to parameter.
    ///
    /// - Parameter state: the media store indexing state
    func updateIndexingState(_ state: MediaStoreIndexingState) {
        mediaStoreIndexingState = state
        updateMediaListState()
    }

    /// Updates media list state according to media store indexing state and media list content.
    func updateMediaListState() {
        let mediaContentState: MediaListState = filteredMedias.isEmpty ? .empty : .available

        if storageSourceType.isDroneSource {
            // Need to check media store indexing state for drone source.
            switch mediaStoreIndexingState {
            case .indexing: mediaListState = .loading
            default: mediaListState = mediaContentState
            }
        } else {
            mediaListState = mediaContentState
        }
    }

    // MARK: Filters
    /// Updates filter items for provided media array.
    ///
    /// - Parameter medias: the media array
    func updateFilterItems(from medias: [GalleryMedia]) {
        filterItems = Array(Set(medias.map { $0.type }))
            .sorted(by: { $0.rawValue < $1.rawValue })
            .map { type in GalleryFilterItem(type: type,
                                             count: medias.filter({ $0.type == type }).count)}
    }

    // MARK: Storage
    /// Updates removable storage state according to parameter.
    ///
    /// - Parameter state: the removable storage state
    func updateRemovableStorageState(_ state: UserStorageState) {
        removableStorageState = state

        // Update storage source according to SD card availability.
        if storageSourceType.isDroneSource {
            if state == .available || state == .unknown {
                storageSourceType = .droneSdCard
            } else {
                storageSourceType = .droneInternal
            }
        }

        updateSdCardErrorState()
    }

    /// Updates SD card error state according to removable storage state and active source type.
    func updateSdCardErrorState() {
        sdCardErrorState = removableStorageState.hasError && storageSourceType.isDroneSource ? removableStorageState : nil
    }

    /// Gets storage source type for a specific gallery source segment.
    ///
    /// - Parameter segment: the gallery source segment
    /// - Returns: the corresponding storage source type
    func storageSourceType(for segment: GallerySourceSegment) -> GallerySourceType {
        segment == .device ? .mobileDevice :
        removableStorageState != .notDetected ? .droneSdCard : .droneInternal
    }

    /// Sets active storage source.
    ///
    /// - Parameter source: the gallery source type
    func setStorageSource(_ source: GallerySourceType) {
        mediaListService.setStorageSource(source)
        storageSourceTypeSubject.value = source
        mainActionType = source.mainActionType

        // Update storage details according to selected source.
        sourceDetails = userStorageService.storageDetails(for: storageSourceType)

        // Update UI when source changes.
        setSelectMode(false) // Exit select mode.
        setFilter([]) // Clear selected filters.
        updateSdCardErrorState()
    }

    /// Updates storage formatting availability.
    func updateFormatState() {
        isFormatStorageAvailable = storageSourceType == .droneSdCard && !isActionActive(.select)
        update(.format, isEnabled: canFormatUserStorage)
    }

    // MARK: Filters
    /// Sets media filters and update media list content accordingly.
    ///
    /// - Parameter filter: the media filters set
    func setFilter(_ filter: Set<GalleryMediaType>) {
        filteredMediaTypes = filter
        updateMediaList()
    }

    // MARK: Media Selection
    /// Selects a media with a specific uid.
    ///
    /// - Parameter uid: the uid of the media to select
    func selectMedia(with uid: String) { selectedMediaUids.insert(uid) }

    /// Deselects a media with a specific uid.
    ///
    /// - Parameter uid: the uid of the media to deselect
    func deselectMedia(with uid: String) { selectedMediaUids.remove(uid) }

    /// Adds all displayed medias to current selection.
    func selectAll() { selectedMediaUids = selectedMediaUids.union(filteredMediaUids) }

    /// Deselects all medias.
    func deselectAll() { selectedMediaUids.removeAll() }

    /// Updates gallery actions availability according to active selection.
    func updateActionsEnableState() {
        guard !selectedMedias.isEmpty else {
            // Main and delete actions are disabled for an empty list.
            disable(action: mainActionType)
            disable(action: .delete)
            return
        }

        if mainActionType == .download {
            // Download action should be available only if selection contains at least 1 downloadable item.
            update(.download, isEnabled: selectedMedias.first(where: { !$0.isDownloaded }) != nil)
        } else {
            enable(action: mainActionType)
        }
        enable(action: .delete)
    }
}

// MARK: - Actions Helpers
private extension GalleryViewModel {

    /// Sets a specific action as active.
    ///
    /// - Parameter action: the action to update
    func start(action: GalleryActionType) { activeActionTypes.insert(action) }

    /// Sets a specific action as inactive.
    ///
    /// - Parameter action: the action to update
    func stop(action: GalleryActionType) { activeActionTypes.remove(action) }

    /// Enables a specific action (meaning it can be activated).
    ///
    /// - Parameter action: the action to update
    func enable(action: GalleryActionType) { enabledActionTypes.insert(action) }

    /// Disables a specific action (meaning it can't be activated).
    ///
    /// - Parameter action: the action to update
    func disable(action: GalleryActionType) { enabledActionTypes.remove(action) }

    /// Updates the enabled state of a specific action.
    ///
    /// - Parameter action: the action to update
    func update(_ action: GalleryActionType, isEnabled: Bool) {
        isEnabled ? enable(action: action) : disable(action: action)
    }
}
