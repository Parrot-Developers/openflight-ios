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

/// Gallery SD Media ViewModel delete functions.

// MARK: - Internal Funcs
extension GallerySDMediaViewModel {
    /// Delete medias.
    ///
    /// - Parameters:
    ///    - mediaItems: medias to remove
    ///    - completion: provides success after delete
    func deleteMedias(_ mediaItems: [MediaItem], completion: @escaping (Bool) -> Void) {
        let mediaList = MediaResourceListFactory.listWith(allOf: mediaItems)
        deleteRequest = drone?
            .getPeripheral(Peripherals.mediaStore)?
            .newDeleter(mediaResources: mediaList) { [weak self] mediaDeleter in
                guard let mediaDeleter = mediaDeleter
                    else {
                        self?.updateRemovingState(false)
                        completion(false)
                        return
                }

                switch mediaDeleter.status {
                case .complete:
                    self?.updateRemovingState(false)
                    completion(true)
                case .error:
                    self?.updateRemovingState(false)
                    completion(false)
                case .running:
                    self?.updateRemovingState(true)
                default:
                    // fileDownloaded case is not supposed to happen.
                    break
                }
        }
    }

    /// Deletes a resource from a media.
    ///
    /// - Parameters:
    ///    - resource: Resource to delete.
    ///    - mediaItem: Media containing the resource to delete.
    ///    - completion: Completion block called after deletion.
    func deleteResource(_ resource: MediaItem.Resource, of mediaItem: MediaItem, completion: @escaping (Bool) -> Void) {
        deleteResources([resource], of: mediaItem, completion: completion)
    }

    /// Deletes some resources from a media.
    ///
    /// - Parameters:
    ///    - resources: the resources to delete
    ///    - mediaItem: the media containing the resources to delete
    ///    - completion: the completion block called after deletion
    func deleteResources(_ resources: [MediaItem.Resource], of mediaItem: MediaItem, completion: @escaping (Bool) -> Void) {
        let mediaList = MediaResourceListFactory.emptyList()
        for resource in resources {
            mediaList.add(media: mediaItem, resource: resource)
        }

        deleteRequest = drone?
            .getPeripheral(Peripherals.mediaStore)?
            .newDeleter(mediaResources: mediaList) { [weak self] mediaDeleter in
                guard let mediaDeleter = mediaDeleter
                    else {
                        self?.updateRemovingState(false)
                        completion(false)
                        return
                }

                switch mediaDeleter.status {
                case .complete:
                    self?.updateRemovingState(false)
                    completion(true)
                case .error:
                    self?.updateRemovingState(false)
                    completion(false)
                case .running:
                    self?.updateRemovingState(true)
                default:
                    // fileDownloaded case is not supposed to happen.
                    break
                }
        }
    }
}
