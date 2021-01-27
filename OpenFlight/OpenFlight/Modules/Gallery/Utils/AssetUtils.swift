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

import UIKit
import SwiftyUserDefaults
import GroundSdk
import AVFoundation

/// Utility class to manage Assets.

final class AssetUtils {
    // MARK: - Internal Properties
    static let shared = AssetUtils()

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
    private var localMediaCounts: [String: [String: UInt64]] = [:]

    // MARK: - Internal Enums
    enum Constants {
        static let metadataOriginalDateFormat = "YYYY:MM:dd HH:mm:ss"
        static let prefixLength = 8
    }

    // MARK: - Init
    private init() {
        loadMediasDates()
    }
}

// MARK: - Internal Funcs
extension AssetUtils {
    /// Returns image from given URL (regular format) if exists, nil otherwise.
    ///
    /// - Parameters:
    ///     - url: media Url
    ///     - compression: image compression. Default: no compression
    ///     - completion: completion block
    func loadImage(withURL url: URL, compression: CGFloat = 1.0, completion: @escaping (_ url: URL, _ image: UIImage?) -> Void) {
        var resultImage: UIImage?
        DispatchQueue.global(qos: .background).async {
            if FileManager.default.fileExists(atPath: url.path) {
                if let data = try? Data(contentsOf: url),
                    let rawImage = UIImage(data: data) {
                    let compressedData = rawImage.jpegData(compressionQuality: compression) ?? Data()
                    resultImage = UIImage(data: compressedData)
                }
            }
            DispatchQueue.main.async {
                completion(url, resultImage)
            }
        }
    }

    /// Returns image from given URL (raw/dng format) if exists, nil otherwise.
    ///
    /// - Parameters:
    ///     - url: media Url
    ///     - completion: completion block
    func loadRawImage(withURL url: URL, completion: @escaping (_ url: URL, _ image: UIImage?) -> Void) {
        var resultImage: UIImage?
        DispatchQueue.global(qos: .background).async {
            if FileManager.default.fileExists(atPath: url.path),
                let outputImage = CIImage(contentsOf: url) {
                resultImage = UIImage(ciImage: outputImage)
            }
            DispatchQueue.main.async {
                completion(url, resultImage)
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
            if content.hasDirectoryPath {
                if let mediaUrls = try? FileManager.default.contentsOfDirectory(at: content.appendingPathComponent(mediaType.stringValue),
                                                                                includingPropertiesForKeys: nil,
                                                                                options: []) {
                    var mediaDictionary: [String: [URL]] = [:]
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
                    for url in finalMediaUrls {
                        let imgOrigin = String(url.lastPathComponent.prefix(Constants.prefixLength))
                        if mediaDictionary[imgOrigin] == nil {
                            mediaDictionary[imgOrigin] = [url]
                        } else {
                            mediaDictionary[imgOrigin]?.append(url)
                        }
                    }
                    for entry in mediaDictionary {
                        guard let galleryMedia = galleryMediaForUrls(urls: entry.value, mediaType: mediaType) else { return medias }
                        medias.append(galleryMedia)
                    }
                }
            } else {
                guard let galleryMedia = galleryMediaForUrls(urls: [content], mediaType: mediaType) else { return medias }
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
                } catch let error as NSError {
                    print("Error: \(error), \(error.userInfo)")
                    success = false
                }
            }
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

    /// Removes media date for an url.
    ///
    /// - Parameters:
    ///     - url: url
    func removeMediaDate(forURL url: URL) {
        mediasDates.removeValue(forKey: url.lastPathComponent)
        saveMediasDates()
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

    /// Returns a gallery media object for specified urls.
    ///
    /// - Parameters:
    ///     - urls: urls of the media
    ///     - mediaType : type of the media
    /// - Returns: gallery media object
    func galleryMediaForUrls(urls: [URL], mediaType: GalleryMediaType) -> GalleryMedia? {
        let sortedUrls = urls.sorted(by: { $0.absoluteString < $1.absoluteString })
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
            print(error.localizedDescription)
        }

        let galleryMedia = GalleryMedia(uid: String(mainMediaUrl.prefix),
                                        source: .mobileDevice,
                                        mediaItem: nil,
                                        type: mediaType,
                                        downloadState: .downloaded,
                                        size: mediaSize,
                                        date: mediaDate,
                                        url: mainMediaUrl,
                                        urls: sortedUrls)
        return galleryMedia
    }
}
