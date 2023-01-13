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
import AVFoundation

/// Utility class to manage Assets.

private extension ULogTag {
    static let tag = ULogTag(name: "AssetUtils")
}

private extension DefaultsKeys {
    var mediaResourcesInfo: DefaultsKey<Data?> { .init("key_assetUtilsMediaResourcesInfo") }
}

final class AssetUtils {
    // MARK: - Internal Properties
    static let shared = AssetUtils()

    /// A struct used to associate some media information with its local URL.
    struct MediaItemResourceInfo: Codable {
        /// The media ID.
        var mediaId: String
        /// The media custom ID (for resources grouping).
        var customId: String?
        /// The media customtitle (project and execution names).
        var customTitle: String?
        /// The media flight date.
        var flightDate: Date?
        /// The media boot date.
        var bootDate: Date?
        /// Whether the media is a panorama.
        var isPanorama: Bool = false
        /// The expected resources count for media (if available).
        var expectedCount: UInt64?
    }

    // MARK: - Private Properties
    private let mediasDatesSyncronizeQueue = DispatchQueue(label: "mediasDatesSyncronizeQueue")
    private var mediasDatesValues: [String: Date] = [:]
    private var mediasDates: [String: Date] {
        get {
            return mediasDatesSyncronizeQueue.sync {
                mediasDatesValues
            }
        }
        set(newValue) {
            mediasDatesSyncronizeQueue.sync {
                self.mediasDatesValues = newValue
            }
        }
    }
    // Medias UIDs local list. Allows to sync medias UIDs and resources URLs.
    private let mediaResourcesInfoSyncronizeQueue = DispatchQueue(label: "mediaResourcesInfoSyncronizeQueue")
    private var mediaResourcesInfoValues: [String: MediaItemResourceInfo] = [:]
    private var mediaResourcesInfo: [String: MediaItemResourceInfo] {
        get {
            mediaResourcesInfoSyncronizeQueue.sync {
                mediaResourcesInfoValues
            }
        }
        set(newValue) {
            mediaResourcesInfoSyncronizeQueue.sync {
                mediaResourcesInfoValues = newValue
            }
        }
    }
    private var localMediaCounts: [String: [String: UInt64]] = [:]

    // MARK: - Internal Enums
    enum Constants {
        static let metadataOriginalDateFormat = "YYYY:MM:dd HH:mm:ss"
        static let prefixLength = 8
    }

    // MARK: - Init
    private init() {
        loadMediasDates()
        loadMediaResourcesInfo()
    }
}

// MARK: - Internal Funcs
extension AssetUtils {
    /// Returns image from given URL (regular format) if exists, nil otherwise.
    ///
    /// - Parameters:
    ///     - url: media Url
    ///     - completion: completion block
    func loadImage(withURL url: URL, completion: @escaping (_ image: UIImage?) -> Void) {
        var resultImage: UIImage?
        DispatchQueue.global(qos: .background).async {
            if FileManager.default.fileExists(atPath: url.path) {
                if let data = try? Data(contentsOf: url) {
                    resultImage = UIImage(data: data)
                }
            }
            DispatchQueue.main.async {
                completion(resultImage)
            }
        }
    }

    /// Returns local image stored at a specific URL (if existing).
    ///
    /// - Parameter url: the URL of the image
    /// - Returns: the image stored at provided URL
    static func loadImage(url: URL) -> UIImage? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        if let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }

        return nil
    }

    /// Returns image from given URL (raw/dng format) if exists, nil otherwise.
    ///
    /// - Parameters:
    ///     - url: media Url
    ///     - completion: completion block
    func loadRawImage(withURL url: URL, completion: @escaping (_ image: UIImage?) -> Void) {
        var resultImage: UIImage?
        DispatchQueue.global(qos: .background).async {
            if FileManager.default.fileExists(atPath: url.path),
                let outputImage = CIImage(contentsOf: url) {
                resultImage = UIImage(ciImage: outputImage)
            }
            DispatchQueue.main.async {
                completion(resultImage)
            }
        }
    }

    /// Add MediaItem to localMediaCounts.
    ///
    /// - Parameters:
    ///     - mediaItem: MediaItem
    ///     - droneId: drone Id
    func addMediaItemToLocalList(_ mediaItem: MediaItem, for droneId: String) {
        guard let expectedCount = mediaItem.expectedCount else { return }
        var droneContentVar: [String: UInt64] = [:]
        if let droneContent = localMediaCounts[droneId] {
            droneContentVar = droneContent
        }
        droneContentVar[mediaItem.uid] = expectedCount
        localMediaCounts[droneId] = droneContentVar
        saveLocalMediaCounts()
    }

    /// Adds a media info dictionary entry to local list.
    ///
    /// - Parameters:
    ///    - info: The media information to associate with the local URL (if specified).
    ///    - media: The full media item to associate with the local URL (if specified, ignored if `info` is not nil).
    ///    - url: URL of the media resource.
    func addMediaInfoToLocalList(_ info: MediaItemResourceInfo? = nil, media: MediaItem? = nil, url: URL?) {
        guard let mediaRelativeUrl = url?.mediaRelativeUrl else { return }

        guard let media = media else {
            // Default case, no `media` item provided.
            mediaResourcesInfo[mediaRelativeUrl] = info
            saveMediaResourcesInfo()
            return
        }

        // No `info` provided.
        // => Gather corresponding resource from `media.resources` array and build its `MediaItemResourceInfo` dictionary value.
        guard let resId = url?.lastPathComponent,
              let resource = media.resources.first(where: { $0.uid == resId }) else {
            return
        }
        let mediaInfo = AssetUtils.MediaItemResourceInfo(mediaId: media.uid,
                                                         customId: media.customId,
                                                         customTitle: media.customTitle,
                                                         flightDate: media.flightDate,
                                                         bootDate: media.bootDate,
                                                         isPanorama: resource.type == .panorama,
                                                         expectedCount: media.expectedCount)
        mediaResourcesInfo[mediaRelativeUrl] = mediaInfo
        saveMediaResourcesInfo()
    }

    /// Removes a media info dictionary entry from local list.
    ///
    /// - Parameters:
    ///    - url: URL of the media resource.
    func removeMediaInfoFromLocalList(url: URL) {
        guard let mediaRelativeUrl = url.mediaRelativeUrl else { return }

        mediaResourcesInfo.removeValue(forKey: mediaRelativeUrl)
        saveMediaResourcesInfo()
    }

    /// Updates the URL key of a media info dictionary entry.
    ///
    /// - Parameters:
    ///    - srcUrl: Source URL of the media resource.
    ///    - dstUrl: Destination URL of the media resource.
    func updateMediaInfoUrlInLocalList(srcUrl: URL, dstUrl: URL) {
        guard let srcMediaRelativeUrl = srcUrl.mediaRelativeUrl,
              let info = mediaResourcesInfo[srcMediaRelativeUrl] else {
            return
        }

        addMediaInfoToLocalList(info, url: dstUrl)
        removeMediaInfoFromLocalList(url: srcUrl)
    }

    /// Returns the local panorama resource URL of a specified media if stored locally.
    ///
    /// - Parameters:
    ///    - uid: the media UID containing the resource to look for
    ///    - droneUid: the UID of the drone which captured the media
    /// - Returns: the local URL of the corresponding panorama resource (if any)
    func panoramaResourceUrlForMediaId(_ uid: String?, droneUid: String) -> URL? {
        guard var relativeUrlString = mediaResourcesInfo
            .filter({ $0.value.mediaId == uid && $0.value.isPanorama })
            .map({ $0.key })
            .filter({ $0.droneUid == droneUid })
            .first
        else {
            // No local URL found for provided media/drone UIDs.
            return nil
        }
        relativeUrlString.removeFirst() // Remove first '/' character from .mediaRelativeUrl string.
        return MediaUtils.imgGalleryDirectoryUrl?.appendingPathComponent(relativeUrlString)
    }

    /// Returns all images on smartphone.
    func allLocalImages() -> [GalleryMedia] {
        let directoryName = Paths.mediasDirectory
        let burst = AssetUtils.shared.mediasInDirectory(withName: directoryName, mediaType: .burst)
        let bracketing = AssetUtils.shared.mediasInDirectory(withName: directoryName, mediaType: .bracketing)
        let singleImage = AssetUtils.shared.mediasInDirectory(withName: directoryName, mediaType: .photo)
        let dng = AssetUtils.shared.mediasInDirectory(withName: directoryName, mediaType: .dng)
        let panoVertical = AssetUtils.shared.mediasInDirectory(withName: directoryName, mediaType: .panoVertical)
        let panoHorizontal = AssetUtils.shared.mediasInDirectory(withName: directoryName, mediaType: .panoHorizontal)
        let pano360 = AssetUtils.shared.mediasInDirectory(withName: directoryName, mediaType: .pano360)
        let panoWide = AssetUtils.shared.mediasInDirectory(withName: directoryName, mediaType: .panoWide)
        let timeLapse = AssetUtils.shared.mediasInDirectory(withName: directoryName, mediaType: .timeLapse)
        let gpsLapse = AssetUtils.shared.mediasInDirectory(withName: directoryName, mediaType: .gpsLapse)
        return burst + bracketing + singleImage + dng + panoVertical + panoHorizontal + pano360 + panoWide + timeLapse + gpsLapse
    }

    /// Returns all videos on smartphone.
    func allLocalVideos() -> [GalleryMedia] {
        let directoryName = Paths.mediasDirectory
        let video = AssetUtils.shared.mediasInDirectory(withName: directoryName, mediaType: .video)
        return video
    }

    /// Returns all media in a directory for a specific media type.
    ///
    /// - Parameters:
    ///    - directoryName: directory
    ///    - mediaType: type of media
    /// - Returns: list of medias
    func mediasInDirectory(withName directoryName: String, mediaType: GalleryMediaType) -> [GalleryMedia] {
        guard let directoryContents = contentOfDirectory(withName: directoryName) else { return [] }
        var medias: [GalleryMedia] = []
        for content in directoryContents {
            guard let mediaUrls = try? FileManager.default.contentsOfDirectory(at: content.appendingPathComponent(mediaType.stringValue),
                                                                            includingPropertiesForKeys: nil,
                                                                            options: []) else {
                continue
            }
            let finalMediaUrls = mediaUrls.filter { mediaUrl -> Bool in
                switch mediaType {
                case .video:
                    return mediaUrl.pathExtension == MediaItem.Format.mp4.description.uppercased()
                default:
                    return (
                        mediaUrl.pathExtension == MediaItem.Format.jpg.description.uppercased()
                        || mediaUrl.pathExtension == MediaItem.Format.dng.description.uppercased()
                    )
                }
            }
            var mediaDictionary: [String: [URL]] = [:]
            for url in finalMediaUrls {
                // Group items according to their media title first, as they may belong to the same media (e.g. GPS lapse).
                // Group by UID if no media title is found.
                let imgOrigin = mediaTitleFromUrl(url) ?? mediaUidFromUrl(url, urls: finalMediaUrls)
                if mediaDictionary[imgOrigin] == nil {
                    mediaDictionary[imgOrigin] = [url]
                } else {
                    mediaDictionary[imgOrigin]?.append(url)
                }
            }
            for urls in mediaDictionary.values {
                guard let galleryMedia = galleryMediaForUrls(urls: urls, mediaType: mediaType) else { continue }
                medias.append(galleryMedia)
            }
        }
        return medias
    }

    /// Return the original date for an image url.
    ///
    /// - Parameters:
    ///     - url: url
    /// - Returns: date
    func originalDateTimeFromPhoto(withURL url: URL) -> Date {
        return originalDateTimeFrom(url: url, isVideo: false)
    }

    /// Return the original date for a video url.
    ///
    /// - Parameters:
    ///     - url: url
    /// - Returns: date
    func originalDateTimeFromVideo(withURL url: URL) -> Date {
        return originalDateTimeFrom(url: url, isVideo: true)
    }

    /// Remove selected medias.
    ///
    /// - Parameters:
    ///     - medias: list of medias
    func removeMedias(medias: [GalleryMedia]) -> Bool {
        var success = true
        for media in medias {
            guard let urls = media.urls else { return false }
            for url in urls {
                do {
                    try FileManager.default.removeItem(at: url)
                    // Remove entry from local list if deletion is successful.
                    removeMediaInfoFromLocalList(url: url)
                } catch let error as NSError {
                    ULog.e(.tag, "Error: \(error), \(error.userInfo)")
                    success = false
                }
            }
        }
        return success
    }

    /// Removes a medias array from device memory.
    ///
    /// - Parameter medias: the medias array to remove
    func removeMedias(medias: [GalleryMedia]) async throws {
        for media in medias {
            guard let urls = media.urls else { continue }
            for url in urls {
                try FileManager.default.removeItem(at: url)
                // Remove entry from local list if deletion is successful.
                removeMediaInfoFromLocalList(url: url)
            }
        }
    }

    /// Removes the resources located at specific indexes of a media.
    ///
    /// - Parameters:
    ///    - indexes: the indexes of the resources to remove
    ///    - media: the media containing the resources to remove
    func removeResources(at indexes: [Int], from media: GalleryMedia) async throws {
        guard let urls = media.urls else { return }
        for index in indexes.filter({ $0 < urls.count }) {
            try FileManager.default.removeItem(at: urls[index])
            // Remove entry from local list if deletion is successful.
            removeMediaInfoFromLocalList(url: urls[index])
        }
    }

    /// Deletes a resource from a media.
    ///
    /// - Parameters:
    ///    - index: Index of the resource to delete.
    ///    - media: Media containing the resource to delete.
    /// - Returns: `true` if deletion is successful, `false` otherwise.
    func removeResourceAt(_ index: Int, of media: GalleryMedia) -> Bool {
        var success = true
        guard let urls = media.urls,
              index < urls.count else { return false }
        do {
            try FileManager.default.removeItem(at: urls[index])
            // Remove entry from local list if deletion is successful.
            removeMediaInfoFromLocalList(url: urls[index])
        } catch let error as NSError {
            ULog.e(.tag, "Error: \(error), \(error.userInfo)")
            success = false
        }
        return success
    }
}

// MARK: - Private Funcs
private extension AssetUtils {
    /// Saves localMediaCounts to Defaults.
    func saveLocalMediaCounts() {
        Defaults.localMediaCounts = localMediaCounts
    }

    /// Returns an array of file URLs for the wanted directory in Documents.
    ///
    /// - Parameters:
    ///     - directoryName: directory
    /// - Returns: array of URL
    func contentOfDirectory(withName directoryName: String) -> [URL]? {
        if let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
            let directoryContents = try? FileManager.default.contentsOfDirectory(at: documentsUrl.appendingPathComponent(directoryName),
                                                                                 includingPropertiesForKeys: nil,
                                                                                 options: []) {
            return directoryContents
        }
        return nil
    }

    /// Loads medias dates from Defaults.
    func loadMediasDates() {
        if let mediasDatesData = Defaults.mediasDatesGallery as? [String: Date] {
            mediasDates = mediasDatesData
        }
    }

    /// Saves medias dates to Defaults.
    func saveMediasDates() {
        Defaults.mediasDatesGallery = mediasDates
    }

    /// Returns a date for an url.
    ///
    /// - Parameters:
    ///     - url: url
    ///     - isVideo: boolean
    /// - Returns: date
    func originalDateTimeFrom(url: URL, isVideo: Bool) -> Date {
        var resultDate = Date()
        if let mediaDate = mediasDates[url.lastPathComponent] {
            resultDate = mediaDate
        } else {
            resultDate = isVideo ? dateForVideo(atURL: url) : dateForImage(atURL: url)
            mediasDates[url.lastPathComponent] = resultDate
            saveMediasDates()
        }
        return resultDate
    }

    /// Returns a date for a video url.
    ///
    /// - Parameters:
    ///     - url: url
    /// - Returns: date
    func dateForVideo(atURL url: URL) -> Date {
        let asset = AVAsset(url: url)
        return asset.creationDate?.dateValue ?? Date()
    }

    /// Returns a date for an image url.
    ///
    /// - Parameters:
    ///     - url: url
    /// - Returns: date
    func dateForImage(atURL url: URL) -> Date {
        guard let imageData = try? Data(contentsOf: url),
            let source = CGImageSourceCreateWithData(imageData as CFData, nil),
            let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [AnyHashable: Any] else {
                return Date()
        }
        let metadataDateFormatter = DateFormatter()
        metadataDateFormatter.dateFormat = Constants.metadataOriginalDateFormat
        let exifDict = metadata[kCGImagePropertyExifDictionary] as? [AnyHashable: Any]
        return metadataDateFormatter.date(from: exifDict?[kCGImagePropertyExifDateTimeOriginal] as? String ?? "") ?? Date()
    }

    /// Loads medias resources info from Defaults.
    func loadMediaResourcesInfo() {
        guard let data = Defaults[\.mediaResourcesInfo],
              let info = try? JSONDecoder().decode([String: MediaItemResourceInfo].self, from: data) else {
            return
        }
        mediaResourcesInfo = info
    }

    /// Saves medias resources info to Defaults.
    func saveMediaResourcesInfo() {
        Defaults.mediaResourcesInfo = try? JSONEncoder().encode(mediaResourcesInfo)
    }

    /// Returns the UID of the media containing the resource stored at a specified URL.
    ///
    /// - Parameters:
    ///     - url: The URL of the resource.
    ///     - urls: The URLs array containing the URL of the resource (used for legacy corner case only).
    /// - Returns: The UID of the media containing the resource if found.
    func mediaUidFromUrl(_ url: URL, urls: [URL]) -> String {
        guard let mediaRelativeUrl = url.mediaRelativeUrl,
              let uid = mediaResourcesInfo[mediaRelativeUrl]?.mediaId else {
            return legacyMediaUidFromUrl(url, urls: urls)
        }
        return uid
    }

    /// Returns the Title of the media containing the resource stored at a specified URL.
    ///
    /// - Parameters:
    ///     - url: The URL of the resource.
    /// - Returns: The Title of the media containing the resource if found.
    func mediaTitleFromUrl(_ url: URL?) -> String? {
        guard let mediaRelativeUrl = url?.mediaRelativeUrl,
              let customId = mediaResourcesInfo[mediaRelativeUrl]?.customId,
              !customId.isEmpty else {
            return nil
        }
        return mediaResourcesInfo[mediaRelativeUrl]?.customTitle
    }

    /// Returns the flight date of the media containing the resource stored at a specified URL.
    ///
    /// - Parameters:
    ///     - url: The URL of the resource.
    /// - Returns: The flight date of the media containing the resource if found.
    func mediaFlightDateFromUrl(_ url: URL?) -> Date? {
        guard let mediaRelativeUrl = url?.mediaRelativeUrl else {
            return nil
        }
        return mediaResourcesInfo[mediaRelativeUrl]?.flightDate
    }

    /// Returns the boot date of the media containing the resource stored at a specified URL.
    ///
    /// - Parameters:
    ///     - url: The URL of the resource.
    /// - Returns: The boot date of the media containing the resource if found.
    func mediaBootDateFromUrl(_ url: URL?) -> Date? {
        guard let mediaRelativeUrl = url?.mediaRelativeUrl else {
            return nil
        }
        return mediaResourcesInfo[mediaRelativeUrl]?.bootDate
    }

    /// Indicates whether a panorama resource is locally stored at a specified URL.
    ///
    /// - Parameters:
    ///    - url: The URL of the resource.
    /// - Returns: `true` if the corresponding resource is a panorama, `false` otherwise.
    func isPanoramaResourceFromUrl(_ url: URL) -> Bool {
        guard let mediaRelativeUrl = url.mediaRelativeUrl else { return false }
        return mediaResourcesInfo[mediaRelativeUrl]?.isPanorama ?? false
    }

    /// The resources expected count of the media containing the resource stored at a specified URL.
    ///
    /// - Parameters:
    ///    - url: the URL of the resource
    /// - Returns: the expected resources count (if available)
    func resourcesExpectedCount(_ url: URL) -> UInt64? {
        guard let mediaRelativeUrl = url.mediaRelativeUrl else { return nil }
        return mediaResourcesInfo[mediaRelativeUrl]?.expectedCount
    }

    /// Returns the UID of the media containing the resource stored at a specified URL in legacy cases.
    /// Backward compatibility purpose only:
    /// This function is called if the URL is not found in local `mediasUids` dictionary (media was downloaded before new implementation).
    /// Calls the UID rebuild function (`rebuiltMediaUidFromUrl(URL)`) on specified URL.
    /// If rebuild fails, same process is performed on sibling URL (first similar URL found in urls array).
    /// This is needed for legacy panorama URLs that does not contain all needed information.
    /// If no sibling is found, falls back to legacy method (url.prefix).
    ///
    /// - Parameters:
    ///     - url: The URL of the resource.
    ///     - urls: The URLs array containing the URL of the resource.
    /// - Returns: The UID of the media containing the resource if successfully rebuilt, `Constants.prefixLength` first characters otherwise.
    func legacyMediaUidFromUrl(_ url: URL, urls: [URL]) -> String {
        guard let rebuiltUid = rebuiltMediaUidFromUrl(url) else {
            guard let siblingUrl = urls.first(where: { $0.prefix == url.prefix && $0 != url }) else {
                return url.prefix
            }
            return rebuiltMediaUidFromUrl(siblingUrl) ?? url.prefix
        }

        return rebuiltUid
    }

    /// Returns the UID of the media containing the resource stored at a specified URL in legacy cases.
    /// Backward compatibility purpose only: This function tries to rebuild the UID by extracting needed information from URL.
    ///
    /// - Parameters:
    ///     - url: The URL of the resource.
    ///     - urls: The URLs array containing the URL of the resource.
    /// - Returns: The UID of the media containing the resource if successfully rebuilt, `nil` otherwise.
    func rebuiltMediaUidFromUrl(_ url: URL) -> String? {
        let components = url.deletingPathExtension().lastPathComponent.split(separator: "_")

        guard components.count > 2,
              let mediaIdInfo = components.first,
              let sourceInfo = components.last else {
            return nil
        }
        return mediaIdInfo + "_" + sourceInfo
    }

    /// Returns a gallery media object for specified urls.
    ///
    /// - Parameters:
    ///     - urls: urls of the media
    ///     - mediaType : type of the media
    /// - Returns: gallery media object
    func galleryMediaForUrls(urls: [URL], mediaType: GalleryMediaType) -> GalleryMedia? {
        var sortedUrls = urls.sorted(by: { $0.absoluteString < $1.absoluteString })
        guard let mainMediaUrl = sortedUrls.first else { return nil }
        var mediaDate = Date()
        var mediaSize: UInt64 = 0
        if mediaType == .video {
            mediaDate = AssetUtils.shared.originalDateTimeFromVideo(withURL: mainMediaUrl)
        } else {
            mediaDate = AssetUtils.shared.originalDateTimeFromPhoto(withURL: mainMediaUrl)
        }
        do {
            for url in urls {
                let attr = try FileManager.default.attributesOfItem(atPath: url.absoluteString)
                let dict = attr as NSDictionary
                mediaSize += dict.fileSize()
            }
        } catch let error {
            ULog.e(.tag, error.localizedDescription)
        }

        let resourceType: MediaItem.ResourceType
        if let panoResourceIndex = sortedUrls.firstIndex(where: { isPanoramaResourceFromUrl($0) }) {
            // A panorama resource is locally stored for current mediaItem.
            // => Ensure it's located in first position of the resources list.
            let panoUrl = sortedUrls[panoResourceIndex]
            sortedUrls.remove(at: panoResourceIndex)
            sortedUrls.insert(panoUrl, at: 0)
            resourceType = .panorama
        } else {
            resourceType = .photo
        }
        var mediaItems: [MediaItem]?
        if let expectedCountUrl = sortedUrls.first(where: { resourcesExpectedCount($0) != nil }) {
            // Some expectedCount information has been found for current media.
            // => Need to create a mock media item in order to be able to correctly display
            // panorama availability and resources in gallery.
            mediaItems = [mockMediaItem(type: resourceType, expectedCount: resourcesExpectedCount(expectedCountUrl))]
        }

        let galleryMedia = GalleryMedia(uid: mediaUidFromUrl(mainMediaUrl, urls: urls),
                                        droneUid: mainMediaUrl.droneUid,
                                        customTitle: mediaTitleFromUrl(mainMediaUrl),
                                        source: .mobileDevice,
                                        mediaItems: mediaItems,
                                        type: mediaType,
                                        date: mediaDate,
                                        flightDate: mediaFlightDateFromUrl(mainMediaUrl),
                                        bootDate: mediaBootDateFromUrl(mainMediaUrl),
                                        url: mainMediaUrl,
                                        urls: sortedUrls)
        return galleryMedia
    }
}

private extension AssetUtils {
    /// Creates a mock media item containing only 1 resource.
    /// Useful for local gallery medias. Fullscreen gallery needs indeed to be aware of the type of the displayed resources
    /// in order to know whether a panorama needs to be displayed/generated. However local medias are directly handled
    /// via their URLs only => if a panorama has been uploaded to the drone's memory, then the .pano type information and
    /// the expected resources count are lost as upload process creates its own resource UID (without any pano information
    /// in its name). Therefore a mock resource is used for specific panorama cases (and may also be used in the future
    /// for non-panorama types with expected resources count).
    ///
    /// - Parameters:
    ///    - type: the type of the mock media item to create (should only be .panorama for now)
    ///    - expectedCount: the expected resources count for the media
    /// - Returns: the mock media item with 1 mock resource
    func mockMediaItem(type: MediaItem.ResourceType, expectedCount: UInt64?) -> MediaItem {
        let mockResource = MediaItemResourceCore(uid: "",
                                                 type: type,
                                                 format: .jpg,
                                                 size: 0,
                                                 streamUrl: nil,
                                                 location: nil,
                                                 creationDate: Date(),
                                                 storage: nil)
        return MediaItemCore(uid: "",
                             name: "",
                             type: .photo,
                             runUid: "",
                             customId: nil,
                             customTitle: "",
                             creationDate: Date(),
                             bootDate: nil,
                             flightDate: nil,
                             expectedCount: expectedCount,
                             photoMode: .single,
                             panoramaType: nil,
                             resources: [mockResource])
    }
}

extension AssetUtils {
    var medias: [GalleryMedia] { allLocalImages() + allLocalVideos() }
}
