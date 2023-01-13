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

/// A view model for the dashboard medias tile.
final class DashboardMediasViewModel {

    /// The media list.
    @Published private(set) var medias = [GalleryMedia]()
    /// The active storage source details.
    @Published private(set) var sourceDetails = UserStorageDetails()
    /// The SD card error state.
    @Published private(set) var sdCardErrorState: UserStorageState?

    /// The cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// The user storage service.
    private let userStorageService: UserStorageService
    /// The drone media list.
    private var droneMedias = [GalleryMedia]()
    /// The device media list.
    private var deviceMedias: [GalleryMedia] { AssetUtils.shared.medias }
    /// The active source according to connection and content states.
    private var storageSource: GallerySourceType = .mobileDevice {
        didSet {
            updateActiveMediaList()
            updateSourceDetails()
        }
    }
    /// The removable storage state.
    private var removableStorageState: UserStorageState = .unknown
    /// The preferred drone source according to SD card availability.
    private var preferredDroneSource: GallerySourceType = .droneSdCard

    private enum Constants {
        /// The maximum number of medias displayed in collection.
        static let maxNumberOfMedias = 3
    }

    // MARK: Init
    /// Constructor.
    ///
    /// - Parameter mediaServices: the media services
    init(mediaServices: MediaServices) {
        userStorageService = mediaServices.userStorageService

        listen(to: mediaServices.mediaStoreService)
        listen(to: userStorageService)
    }
}

private extension DashboardMediasViewModel {

    /// Listens to media store service in order to update states accordingly.
    ///
    /// - Parameter mediaStoreService: the media store service
    func listen(to mediaStoreService: MediaStoreService) {
        mediaStoreService.itemsListPublisher
            .sink { [weak self] items in
                self?.updateDroneMediaList(items: items)
            }
            .store(in: &cancellables)
    }

    /// Listens to user storage service in order to update states accordingly.
    ///
    /// - Parameter userStorageService: the user storage service
    func listen(to userStorageService: UserStorageService) {
        userStorageService.removableStorageStatePublisher
            .removeDuplicates()
            .sink { [weak self] state in
                guard let self = self else { return }
                self.updateRemovableStorageState(state)
            }
            .store(in: &cancellables)

        userStorageService.removableStorageDetailsPublisher.sink { [weak self] details in
            guard let self = self else { return }
            self.storageSource = details.isOffline ? .mobileDevice : self.preferredDroneSource
            guard self.storageSource == .droneSdCard else { return }
            self.sourceDetails = details
        }
        .store(in: &cancellables)

        userStorageService.internalStorageDetailsPublisher.sink { [weak self] details in
            guard self?.storageSource == .droneInternal else { return }
            self?.sourceDetails = details
        }
        .store(in: &cancellables)
    }
}

private extension DashboardMediasViewModel {

    // MARK: Media List
    /// Updates drone media list state.
    ///
    /// - Parameter list: the media items list
    func updateDroneMediaList(items: [GalleryMedia]) {
        // Update local drone media list.
        droneMedias = items

        updateActiveMediaList()
    }

    /// Updates active media list according to selected storage source.
    func updateActiveMediaList() {
        if storageSource.isDeviceSource || (droneMedias.isEmpty && !deviceMedias.isEmpty) {
            updateMediaList(with: deviceMedias)
        } else if storageSource.isDroneSource {
            updateMediaList(with: droneMedias)
        }
    }

    /// Updates active media list with provided media array.
    ///
    /// - Parameter medias: the media array
    func updateMediaList(with medias: [GalleryMedia]) {
        self.medias = Array(medias.orderedByDate.prefix(Constants.maxNumberOfMedias))
    }

    /// Updates active source details according to active storage source.
    func updateSourceDetails() {
        sourceDetails = userStorageService.storageDetails(for: storageSource)
    }

    // MARK: Storage
    /// Updates removable storage state according to parameter.
    ///
    /// - Parameter state: the removable storage state
    func updateRemovableStorageState(_ state: UserStorageState) {
        removableStorageState = state

        // Update preferred storage source according to SD card availability.
        if state == .available || state == .unknown {
            preferredDroneSource = .droneSdCard
        } else {
            preferredDroneSource = .droneInternal
        }

        updateSdCardErrorState()
    }

    /// Updates SD card error state according to removable storage state and active source type.
    func updateSdCardErrorState() {
        sdCardErrorState = removableStorageState.hasError ? removableStorageState : nil
    }
}
