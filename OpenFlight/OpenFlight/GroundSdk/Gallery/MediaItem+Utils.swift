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
import GroundSdk
import CoreLocation

/// Utility extension for `MediaItem`.
extension MediaItem {
    /// Converts MediaItem's mediaType into GalleryMediaType.
    var mediaType: GalleryMediaType {
        switch type {
        case .photo:
            switch photoMode {
            case .bracketing:
                return .bracketing
            case .burst:
                return .burst
            case .gpsLapse:
                return .gpsLapse
            case .panorama:
                switch panoramaType {
                case .horizontal_180:
                    return .panoHorizontal
                case .vertical_180:
                    return .panoVertical
                case .spherical:
                    return .pano360
                case .super_wide:
                    return .panoWide
                default:
                    return .photo
                }
            case .single:
                switch resources.first?.format {
                case .dng:
                    return .dng
                default:
                    return .photo
                }
            case .timeLapse:
                return .timeLapse
            default:
                return .photo
            }
        case .video:
            return .video
        }
    }

    var droneId: String {
        // TODO very wrong to access a service here
        return Services.hub.currentDroneHolder.drone.uid
    }

    /// Returns a list of all downloadable resources for this mediaItem.
    var downloadableResources: [MediaItem.Resource] {
        return resources.filter { !$0.isDownloaded(droneId: droneId, mediaType: mediaType) }
    }

    /// Returns true if mediaItem is downloaded.
    var isDownloaded: Bool {
        return downloadableResources.isEmpty
    }

    /// Returns true if resources are present in SD Card memory.
    var isSdStorage: Bool {
        return !resources.filter({ $0.storage == .removable }).isEmpty
    }

    /// Returns true if resources are present in internal memory.
    var isInternalStorage: Bool {
        return !resources.filter({ $0.storage == .internal }).isEmpty
    }

    /// Requests the address description of location.
    ///
    /// - Parameters:
    ///     - completion: callback which returns the location detail string
    func locationDetail(completion: @escaping(String?) -> Void) {
        guard let location = resources.first?.location else {
            completion(nil)
            return
        }

        location.locationDetail(completion: completion)
    }

}

/// Utility extension for `MediaItem.Resource`.
extension MediaItem.Resource {
    // MARK: - Gallery helpers
    /// Provides Url for gallery image directory.
    /// Create path if needed.
    ///
    /// - Parameters:
    ///     - droneId: drone Id
    ///     - mediaType: GalleryMediaType
    /// - Returns: Url For Gallery Image Directory.
    func galleryURL(droneId: String?, mediaType: GalleryMediaType?) -> URL? {
        guard let galleryURL = createGalleryURL(droneId: droneId, mediaType: mediaType) else { return nil }

        // Special case: test if single image was part of DNG MediaItem.
        if !FileManager.default.fileExists(atPath: galleryURL.path) && mediaType == .photo {
            return createGalleryURL(droneId: droneId, mediaType: .dng)
        }

        return galleryURL
    }

    /// Tells if the resource is downloaded.
    ///
    /// - Parameters:
    ///     - droneId: drone Id
    ///     - mediaType: GalleryMediaType
    /// - Returns: true if the resource is downloaded.
    func isDownloaded(droneId: String?, mediaType: GalleryMediaType?) -> Bool {
        guard let galleryURL = galleryURL(droneId: droneId, mediaType: mediaType) else { return false }

        return FileManager.default.fileExists(atPath: galleryURL.path)
    }

    /// Creates Url for gallery directory for given media type.
    ///
    /// - Parameters:
    ///     - droneId: drone Id
    ///     - mediaType: GalleryMediaType
    /// - Returns: Resource gallery Url
    private func createGalleryURL(droneId: String?, mediaType: GalleryMediaType?) -> URL? {
        guard var imgGalleryDirectoryUrl = MediaUtils.imgGalleryDirectoryUrl else { return nil }

        if let droneId = droneId {
            imgGalleryDirectoryUrl = imgGalleryDirectoryUrl.appendingPathComponent(droneId)
        }
        if let mediaType = mediaType {
            imgGalleryDirectoryUrl = imgGalleryDirectoryUrl.appendingPathComponent(mediaType.stringValue)
        }

        return imgGalleryDirectoryUrl.appendingPathComponent(uid, isDirectory: false)
    }

    // MARK: - Cache helpers
    /// Provides resource Url preview directory.
    ///
    /// - Parameters:
    ///    - droneId: drone Id
    /// - Returns: Url for image preview directory
    static func previewDirectoryUrl(droneId: String?) -> URL? {
        guard let cacheURL = FileManager.default.urls(for: .cachesDirectory,
                                                      in: .userDomainMask).first,
              let droneId = droneId else {
            return nil
        }

        return cacheURL
            .appendingPathComponent(Paths.imagePreviewDirectory)
            .appendingPathComponent(droneId)
    }

    /// Provides Url For Cached Image Directory.
    ///
    /// - Parameters:
    ///    - droneId: drone Id
    /// - Returns: Url For Cached Image Directory
    func cachedImgUrl(droneId: String?) -> URL? {
        guard let imgPreviewDirectoryUrl = MediaItem.Resource.previewDirectoryUrl(droneId: droneId) else { return nil }

        return imgPreviewDirectoryUrl.appendingPathComponent(uid, isDirectory: false)
    }

    /// Tells if image cache directory exists.
    ///
    /// - Parameters:
    ///    - droneId: drone Id
    /// - Returns: true if image cache directory exists
    func cachedImgUrlExist(droneId: String?) -> Bool {
        guard let cachedImgUrl = cachedImgUrl(droneId: droneId) else { return false }

        return FileManager.default.fileExists(atPath: cachedImgUrl.path)
    }
}
