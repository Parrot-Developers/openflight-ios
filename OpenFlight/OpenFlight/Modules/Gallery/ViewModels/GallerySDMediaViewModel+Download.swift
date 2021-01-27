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

// TODO: Refact this class with the common one `MediaDownloadState`.
/// Gallery SD Media ViewModel downlaod functions.
// MARK: - Internal Funcs
extension GallerySDMediaViewModel {
    /// Load media's ressource(s) from drone.
    ///
    /// - Parameters:
    ///    - media: Media Item
    ///    - resources: resources to download
    ///    - completion: provides media url after download
    func downloadResource(media: MediaItem?,
                          resources: [MediaItem.Resource],
                          completion: @escaping (URL?) -> Void) {
        guard let mediaStore = mediaStore,
              let imgUrl = MediaItem.Resource.previewDirectoryUrl(droneId: state.value.droneUid),
              let mediaItem = media,
              !resources.isEmpty else {
            return
        }

        downloadRequest = mediaStore.newDownloader(
            mediaResources: MediaUtils.convertMediaResourcesToResourceList(mediaItem: mediaItem,
                                                                           resources: resources,
                                                                           onlyDownloadable: true),
            destination: .directory(path: imgUrl.path),
            observer: { [weak self] mediaDownloader in
                guard let downloadStatus = mediaDownloader?.status else { return }
                switch downloadStatus {
                case .fileDownloaded:
                    completion(mediaDownloader?.fileUrl ?? imgUrl)
                    guard let droneId = self?.state.value.droneUid,
                          let currentMedia = mediaDownloader?.currentMedia else {
                        return
                    }

                    AssetUtils.shared.addMediaItemToLocalList(currentMedia, for: droneId)
                default:
                    break
                }
            })
    }

    /// Download medias and save them to the mobile device.
    ///
    /// - Parameters:
    ///    - mediasToDownload: MediaItem array
    ///    - completion: provides media url after download
    func downloadMedias(mediasToDownload: [MediaItem],
                        completion: @escaping (URL?, Bool) -> Void) {
        guard let droneId = self.state.value.droneUid,
              let mediaStore = mediaStore else {
            return
        }

        let mediaList = MediaUtils.convertMediasToDownloadableResourceList(medias: mediasToDownload)

        downloadRequest = mediaStore.newDownloader(
            mediaResources: mediaList,
            destination: .document(directoryName: "\(Paths.mediasDirectory)/\(droneId)")) { [weak self] mediaDownloader in
            guard let strongSelf = self,
                  let mediaDownloader = mediaDownloader else {
                return
            }

            strongSelf.downloaderDidUpdate(mediaDownloader)
            let isRunning = mediaDownloader.status == .running
            // Enable streaming regarding status regarding status.
            strongSelf.drone?.getPeripheral(Peripherals.streamServer)?.enabled = !isRunning

            if mediaDownloader.status == .fileDownloaded {
                guard let fileUrl = mediaDownloader.fileUrl,
                      let currentMedia = mediaDownloader.currentMedia else {
                    completion(nil, false)
                    return
                }

                let signatureFileUrl = mediaDownloader.signatureUrl
                self?.saveMedia(fileUrl: fileUrl,
                                signatureFileUrl: signatureFileUrl,
                                media: currentMedia,
                                completion: { _ in
                                    completion(fileUrl, mediaDownloader.totalProgress == 1.0)
                                })
            } else if mediaDownloader.status == .error {
                completion(nil, false)
            }
        }
    }

    /// Cancel downloads.
    func cancelDownloads() {
        downloadRequest = nil
        downloaderDidUpdate(nil)
        drone?.getPeripheral(Peripherals.streamServer)?.enabled = true
        refreshMedias()
    }

    /// Save media item.
    ///
    /// - Parameters:
    ///    - fileUrl: media file Url
    ///    - signatureFileUrl: signature file Url
    ///    - media: Media Item
    ///    - completion: provides media url after download
    func saveMedia(fileUrl: URL,
                   signatureFileUrl: URL?,
                   media: MediaItem,
                   completion: @escaping (URL?) -> Void) {
        guard let droneId = self.state.value.droneUid else { return }

        let destinationUrl = MediaUtils.moveFile(fileUrl: fileUrl,
                                                 droneId: droneId,
                                                 mediaType: media.mediaType)
        if let signatureFileUrl = signatureFileUrl {
            _ = MediaUtils.moveFile(fileUrl: signatureFileUrl,
                                    droneId: droneId,
                                    mediaType: media.mediaType)
        }

        AssetUtils.shared.addMediaItemToLocalList(media, for: droneId)
        if let url = destinationUrl {
            MediaUtils.saveMediaRunUid(media.runUid, withUrl: url)
        }

        completion(destinationUrl)
    }
}
