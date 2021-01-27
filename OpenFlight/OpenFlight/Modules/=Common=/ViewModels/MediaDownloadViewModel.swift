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

/// State for `MediaDownloadViewModel`.
public class MediaDownloadState: ViewModelState, Copying, EquatableState {
    // MARK: - Public Properties
    /// Total download progress.
    public fileprivate(set) var totalProgress: Float = 0.0
    /// Download progress status.
    public fileprivate(set) var status: MediaTaskStatus?
    /// Tells if medias are being removed.
    public fileprivate(set) var isRemoving: Bool = false

    // MARK: - Init
    required public init() {}

    /// Init.
    ///
    /// - Parameters:
    ///     - totalProgress: current download progress
    ///     - status: download status
    ///     - isRemoving: tells if medias are being removed
    public convenience init(totalProgress: Float,
                            status: MediaTaskStatus?,
                            isRemoving: Bool) {
        self.init()

        self.totalProgress = totalProgress
        self.status = status
        self.isRemoving = isRemoving
    }

    // MARK: - Copying
    public func copy() -> Self {
        if let copy = MediaDownloadState(totalProgress: totalProgress,
                                         status: status,
                                         isRemoving: isRemoving) as? Self {
            return copy
        } else {
            fatalError("Must override...")
        }
    }

    public func isEqual(to other: MediaDownloadState) -> Bool {
        return self.totalProgress == other.totalProgress
            && self.status == other.status
            && self.isRemoving == other.isRemoving
    }
}

/// View model in charge of downloading medias.
public class MediaDownloadViewModel: DroneWatcherViewModel<MediaDownloadState> {
    // MARK: - Private Properties
    /// Returns MediaStore from drone.
    private var mediaStore: MediaStore? {
        return drone?.getPeripheral(Peripherals.mediaStore)
    }
    private var downloadRequest: Ref<MediaDownloader>?
    private var deleteRequest: Ref<MediaDeleter>?

    // MARK: - Override Funcs
    public override func listenDrone(drone: Drone) { }

    // MARK: - Public Funcs
    /// Saves media's resource(s).
    ///
    /// - Parameters:
    ///    - medias: Media Item
    ///    - resources: resources to download
    ///    - completion: provides media url after download
    public func downloadMediasTemporary(medias: [MediaItem]?,
                                        resources: [MediaItem.Resource],
                                        completion: @escaping (URL?, Bool?) -> Void) {
        self.downloadResources(medias: medias,
                               resources: resources,
                               completion: completion)
    }

    /// Downloads medias locally.
    ///
    /// - Parameters:
    ///    - mediasToDownload: Media item array to download
    ///    - completion: provides media url after download
    public func downloadMediasLocally(mediasToDownload: [MediaItem],
                                      completion: @escaping (URL?, Bool) -> Void) {
        self.downloadMedias(mediasToDownload: mediasToDownload,
                            completion: completion)
    }

    /// Cancels downloads.
    public func cancelDownloads() {
        downloadRequest = nil
        updateProgressState(progress: nil, status: nil)
    }

    /// Deletes medias.
    ///
    /// - Parameters:
    ///    - mediasToDownload: Media item array to download
    ///    - completion: provides media url after download and a bool which is true when download is finish
    public func deleteMedias(mediasToDelete: [MediaItem], completion: ((Bool) -> Void)? = nil) {
        self.delete(mediasToDelete: mediasToDelete, completion: completion)
    }
}

// MARK: - Download Private Funcs
private extension MediaDownloadViewModel {
    /// Loads media's resource(s) from drone.
    ///
    /// - Parameters:
    ///    - medias: List of Media Item to download
    ///    - resources: resources to download
    ///    - completion: provides media url after download
    func downloadResources(medias: [MediaItem]?,
                           resources: [MediaItem.Resource],
                           completion: @escaping (URL?, Bool?) -> Void) {
        guard let mediaStore = mediaStore,
              let imgUrl = MediaItem.Resource.previewDirectoryUrl(droneId: drone?.uid),
              let mediaItems = medias,
              !resources.isEmpty else {
            return
        }

        downloadRequest = mediaStore.newDownloader(
            mediaResources: MediaResourceListFactory.listWith(allOf: mediaItems),
            destination: .directory(path: imgUrl.path),
            observer: { [weak self] mediaDownloader in
                guard let downloadStatus = mediaDownloader?.status,
                      let strongSelf = self else {
                    return
                }

                strongSelf.updateProgressState(progress: mediaDownloader?.currentFileProgress,
                                               status: mediaDownloader?.status)
                switch downloadStatus {
                case .fileDownloaded:
                    guard let url = mediaDownloader?.fileUrl,
                          let droneId = strongSelf.drone?.uid,
                          let currentMedia = mediaDownloader?.currentMedia else {
                        return
                    }

                    completion(url, false)
                    AssetUtils.shared.addMediaItemToLocalList(currentMedia, for: droneId)
                case .complete:
                    completion(nil, true)
                    return
                case .running,
                     .error:
                    break
                }
            })
    }

    /// Downloads medias and save them to the mobile device.
    ///
    /// - Parameters:
    ///    - mediasToDownload: Media item array to download
    ///    - completion: provides media url after download and a bool which is true when download is finish
    func downloadMedias(mediasToDownload: [MediaItem],
                        completion: @escaping (URL?, Bool) -> Void) {
        guard let mediaStore = mediaStore,
              let destination = drone?.droneSavedMediaDirectory else {
            return
        }

        let mediaList = MediaUtils.convertMediasToDownloadableResourceList(medias: mediasToDownload)

        downloadRequest = mediaStore.newDownloader(
            mediaResources: mediaList,
            destination: destination) { [weak self] mediaDownloader in
            guard let mediaDownloader = mediaDownloader,
                  let strongSelf = self else {
                return
            }

            strongSelf.updateProgressState(progress: mediaDownloader.totalProgress,
                                           status: mediaDownloader.status)

            switch mediaDownloader.status {
            case .fileDownloaded:
                guard let fileUrl = mediaDownloader.fileUrl else {
                    completion(nil, false)
                    return
                }

                strongSelf.saveCurrentMedia(fileUrl: fileUrl,
                                            mediaDownloader: mediaDownloader,
                                            completion: { _ in
                                                completion(fileUrl, mediaDownloader.totalProgress == 1.0)
                                            })
            case .error:
                completion(nil, false)
            case .running,
                 .complete:
                break
            }
        }
    }

    /// Saves media item.
    ///
    /// - Parameters:
    ///    - fileUrl: media file Url
    ///    - mediaDownloader: Media Item downloader
    ///    - completion: provides media url after download
    func saveCurrentMedia(fileUrl: URL,
                          mediaDownloader: MediaDownloader,
                          completion: @escaping (URL?) -> Void) {
        guard let droneId = drone?.uid,
              let currentMedia = mediaDownloader.currentMedia else { return }

        let signatureFileUrl = mediaDownloader.signatureUrl

        let destinationUrl = MediaUtils.moveFile(fileUrl: fileUrl,
                                                 droneId: droneId,
                                                 mediaType: currentMedia.mediaType)
        if let signatureFileUrl = signatureFileUrl {
            _ = MediaUtils.moveFile(fileUrl: signatureFileUrl,
                                    droneId: droneId,
                                    mediaType: currentMedia.mediaType)
        }

        AssetUtils.shared.addMediaItemToLocalList(currentMedia, for: droneId)

        if let url = destinationUrl {
            MediaUtils.saveMediaRunUid(currentMedia.runUid, withUrl: url)
        }

        completion(destinationUrl)
    }
}

// MARK: - Delete Private Funcs
private extension MediaDownloadViewModel {
    /// Deletes medias.
    ///
    /// - Parameters:
    ///     - mediasToDelete: array of medias to delete
    ///     - completion: callback which indicates the potential success of the operation
    func delete(mediasToDelete: [MediaItem], completion: ((Bool) -> Void)? = nil) {
        let mediaList = MediaResourceListFactory.listWith(allOf: mediasToDelete)
        deleteRequest = drone?
            .getPeripheral(Peripherals.mediaStore)?
            .newDeleter(mediaResources: mediaList) { [weak self] mediaDeleter in
                guard let mediaDeleter = mediaDeleter,
                      let strongSelf = self else {
                    self?.updateRemovingState(isRemoving: false)
                    completion?(false)
                    return
                }

                switch mediaDeleter.status {
                case .complete:
                    strongSelf.updateRemovingState(isRemoving: false)
                    completion?(true)
                case .error:
                    strongSelf.updateRemovingState(isRemoving: false)
                    completion?(false)
                case .running:
                    strongSelf.updateRemovingState(isRemoving: true)
                    completion?(true)
                case .fileDownloaded:
                    // The `fileDownloaded` case is not supposed to happen.
                    completion?(false)
                }
            }
    }
}

// MARK: - State Update Funcs
private extension MediaDownloadViewModel {
    /// Updates state with new progress and status values.
    ///
    /// - Parameters:
    ///     - progress: download progress
    ///     - status: current download
    func updateProgressState(progress: Float?, status: MediaTaskStatus?) {
        let copy = state.value.copy()
        copy.totalProgress = progress ?? 0.0
        copy.status = status
        state.set(copy)
    }

    /// Updates removing medias state.
    ///
    /// - Parameters:
    ///     - isRemoving: tells if medias are being removed
    func updateRemovingState(isRemoving: Bool) {
        let copy = state.value.copy()
        copy.isRemoving = isRemoving
        state.set(copy)
    }
}
