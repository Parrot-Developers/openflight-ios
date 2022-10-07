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

import UIKit
import SwiftyUserDefaults
import GroundSdk

/// Medias utility class.
final class MediaUtils {
    // MARK: - Internal Funcs
    /// Builds a MediaResourceList from an array of resources associated to a specific mediaItem
    ///
    /// - Parameters:
    ///     - mediaItem: mediaItem from which the resources are taken
    ///     - resources: array of all selected resources
    ///     - onlyDownloadable: boolean indicating whether function should return a complete resources list
    ///                         or only downloadable ones (default: false)
    ///     - returns: result MediaResourceList
    static func convertMediaResourcesToResourceList(mediaItem: MediaItem,
                                                    resources: [MediaItem.Resource],
                                                    onlyDownloadable: Bool = false) -> MediaResourceList {
        let resourceList = MediaResourceListFactory.emptyList()
        // TODO uses Services.hub, should be done another way
        let filteredList = onlyDownloadable ?
            resources.filter({ !$0.isDownloaded(droneId: Services.hub.currentDroneHolder.drone.uid, mediaType: mediaItem.mediaType) }) :
        resources
        filteredList.forEach({ resourceList.add(media: mediaItem, resource: $0) })
        return resourceList
    }

    /// Returns Url For gallery Directory.
    static var imgGalleryDirectoryUrl: URL? {
        guard let documentsUrl =  FileManager.default.urls(for: .documentDirectory,
                                                           in: .userDomainMask).first
            else { return nil }

        return documentsUrl.appendingPathComponent(Paths.mediasDirectory)
    }

    // MARK: File management

    /// Moves a file to a folder depending on its type and returns destination URL if the operation was successful.
    ///
    /// - Parameters:
    ///     - fileUrl: file Url
    ///     - droneId: drone Id
    ///     - mediaType: Gallery Media Type
    static func moveFile(fileUrl: URL, droneId: String, mediaType: GalleryMediaType) -> URL? {
        guard let destinationUrl = imgGalleryDirectoryUrl?
            .appendingPathComponent(droneId)
            .appendingPathComponent(mediaType.stringValue),
            createDirectoryIfNeeded(url: destinationUrl)
            else { return nil }

        let fileDestination = destinationUrl.appendingPathComponent(fileUrl.lastPathComponent)
        return moveFile(srcUrl: fileUrl, dstUrl: fileDestination)
    }

    /// Moves a file from a source URL to a destination URL and returns destination URL if the operation was successful.
    ///
    /// - Parameters:
    ///    - srcUrl: Source URL.
    ///    - dstUrl: Destination URL.
    /// - Returns: The destination URL if the operation was successful.
    @discardableResult static func moveFile(srcUrl: URL, dstUrl: URL) -> URL? {
        guard FileManager.default.fileExists(atPath: srcUrl.path) else { return nil }

        do {
            if FileManager.default.fileExists(atPath: dstUrl.path) {
                try FileManager.default.removeItem(at: dstUrl)
            }
            try FileManager.default.moveItem(at: srcUrl, to: dstUrl)
        } catch {
            return nil
        }

        return dstUrl
    }

    /// Associates a runUid to a media relative Url.
    ///
    /// - Parameters:
    ///     - runUid: run Uid
    ///     - url: media Url
    static func saveMediaRunUid(_ runUid: String, withUrl url: URL) {
        var mediasRunUids = Defaults.mediasRunUidGallery as? [String: String] ?? [String: String]()
        if let mediaRelativeUrl = url.mediaRelativeUrl, !runUid.isEmpty {
            mediasRunUids[mediaRelativeUrl] = runUid
            Defaults.mediasRunUidGallery = mediasRunUids
        }
    }

    /// Creates a folder at the specific URL and returns a boolean for the result of creation.
    ///
    /// - Parameters:
    ///     - url: directory url
    /// - Returns: true on success
    @discardableResult
    static func createDirectoryIfNeeded(url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) == false
            else { return true }

        do {
            try FileManager.default.createDirectory(at: url,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        } catch {
            return false
        }

        return FileManager.default.fileExists(atPath: url.path)
    }

    // MARK: Media resource
    /// Returns a MediaResourceList with all downloadable resources for an array of MediaItem.
    ///
    /// - Parameters:
    ///     - medias: medias
    /// - Returns: MediaResourceList
    static func getDownloadableResources(medias: [MediaItem]) -> MediaResourceList {
        let resourceList = MediaResourceListFactory.emptyList()
        medias.forEach { mediaItem in
            mediaItem.downloadableResources.forEach({ resource in
                resourceList.add(media: mediaItem, resource: resource)
            })
        }
        return resourceList
    }

    /// Returns a `MediaResourceList` with n first downloadable resources of a `MediaItem` array that have not been cached yet.
    ///
    /// - Parameters:
    ///    - medias: the array describing the number of resources to download for each `MediaItem`
    ///    - droneId: the drone's uid (used to parse cache directory)
    /// - Returns: the media resources list containing the downloadable previewable and non-cached resources.
    static func getDownloadablePreviewableResources(medias: [(MediaItem, Int)], droneId: String) -> MediaResourceList {
        let resourceList = MediaResourceListFactory.emptyList()
        medias.forEach { (mediaItem, length) in
            mediaItem.downloadablePreviewableResources
                .prefix(length)
                .filter { !$0.cachedImgUrlExist(droneId: droneId) }
                .forEach { resourceList.add(media: mediaItem, resource: $0) }
        }
        return resourceList
    }
}
