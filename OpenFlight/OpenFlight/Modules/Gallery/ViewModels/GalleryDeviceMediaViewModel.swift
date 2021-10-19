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
import AVFoundation

// MARK: - Gallery Device Media Listener
/// Listener for `GalleryDeviceMediaViewModel` state updates.
final class GalleryDeviceMediaListener: NSObject {
    // MARK: - Internal Properties
    let didChange: GalleryDeviceMediaListenerClosure

    // MARK: - Init
    init(didChange: @escaping GalleryDeviceMediaListenerClosure) {
        self.didChange = didChange
    }
}
/// Alias for `GalleryDeviceMediaListener` closure.
typealias GalleryDeviceMediaListenerClosure = (GalleryDeviceMediaState) -> Void

/// State for GalleryMediaViewModel.

final class GalleryDeviceMediaState: GalleryContentState {
    // MARK: - Internal Properties
    var source: GallerySource {
        return GallerySource(type: .mobileDevice,
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

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        return super.isEqual(to: other)
    }

    override func copy() -> GalleryDeviceMediaState {
        return GalleryDeviceMediaState(connectionState: self.connectionState,
                                       availableSpace: self.availableSpace,
                                       capacity: self.capacity,
                                       downloadingItem: self.downloadingItem,
                                       downloadStatus: self.downloadStatus,
                                       downloadProgress: self.downloadProgress,
                                       isRemoving: self.isRemoving,
                                       medias: self.medias,
                                       sourceType: self.sourceType,
                                       referenceDate: self.referenceDate,
                                       videoDuration: self.videoDuration,
                                       videoPosition: self.videoPosition,
                                       videoState: self.videoState)
    }
}

/// ViewModel for Device Gallery Media Item.

final class GalleryDeviceMediaViewModel: DroneStateViewModel<GalleryDeviceMediaState> {
    // MARK: - Private Properties
    private var deviceMediaListener: Set<GalleryDeviceMediaListener> = []

    // MARK: - Internal Properties
    var availableSpace: Double {
        return self.state.value.availableSpace
    }
    var numberOfMedias: Int {
        return self.state.value.medias.count
    }
    var downloadRequest: Ref<MediaDownloader>?
    var deleteRequest: Ref<MediaDeleter>?
    var deleteAllRequest: Ref<AllMediasDeleter>?
    static var shared = GalleryDeviceMediaViewModel()
    var storageUsed: Double {
        return self.state.value.storageUsed
    }
    var videoPlayer: AVPlayer?

    // MARK: - Init
    private override init() {
        super.init()

        state.valueChanged = { [weak self] state in
            // Run listeners closure.
            self?.deviceMediaListener.forEach { listener in
                listener.didChange(state)
            }
        }
    }
}

// MARK: - Internal Funcs
extension GalleryDeviceMediaViewModel {
    /// Update removing state.
    ///
    /// - Parameters:
    ///     - isRemoving: VM is removing
    func updateRemovingState(_ isRemoving: Bool) {
        let copy = self.state.value.copy()
        copy.isRemoving = isRemoving
        self.state.set(copy)
    }

    /// Refresh media list.
    func refreshMedias() {
        let copy = self.state.value.copy()
        copy.sourceType = .mobileDevice
        copy.referenceDate = Date()
        let allMedias = AssetUtils.shared.allLocalImages() + AssetUtils.shared.allLocalVideos()
        copy.medias = allMedias.sorted(by: { $0.date > $1.date })
        copy.availableSpace = UIDevice.current.availableSpaceAsDouble
        copy.capacity = UIDevice.current.capacityAsDouble
        self.state.set(copy)
    }
}

// MARK: - Gallery Device Media Listener
extension GalleryDeviceMediaViewModel {
    /// Registers a listener for `GalleryDeviceMediaListener`.
    ///
    /// - Parameters:
    ///    - didChange: listener's closure
    /// - Returns: registered listener
    func registerListener(didChange: @escaping GalleryDeviceMediaListenerClosure) -> GalleryDeviceMediaListener {
        let listener = GalleryDeviceMediaListener(didChange: didChange)
        deviceMediaListener.insert(listener)
        // Initial notification.
        listener.didChange(self.state.value)
        return listener
    }

    /// Removes previously registered `GalleryDeviceMediaListener`.
    ///
    /// - Parameters:
    ///    - listener: listener to remove
    func unregisterListener(_ listener: GalleryDeviceMediaListener?) {
        guard let listener = listener else {
            return
        }
        self.deviceMediaListener.remove(listener)
    }

    /// Unregister all listener.
    func unregisterAllListener() {
        self.deviceMediaListener.removeAll()
    }

    /// Get a media from its index.
    ///
    /// - Parameters:
    ///    - index: Media index in the gallery media array
    /// - Returns: a gallery media
    func getMedia(index: Int) -> GalleryMedia? {
        return index < numberOfMedias ? self.state.value.medias[index] : nil
    }

    /// Get a media from its uid.
    ///
    /// - Parameters:
    ///    - uid: uid
    /// - Returns: a gallery media
    func getMediaFromUid(_ uid: String) -> GalleryMedia? {
        return self.state.value.medias.first { $0.uid == uid.prefix(AssetUtils.Constants.prefixLength) }
    }
}
