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

/// Gallery media download state.

enum GalleryMediaDownloadState: CaseIterable {
    case toDownload
    case downloading
    case downloaded
    case error

    static let defaultValue: GalleryMediaDownloadState = .toDownload

    var icon: UIImage {
        switch self {
        case .downloading:
            return Asset.Gallery.mediaDownloading.image
        case .toDownload:
            return Asset.Gallery.mediaDownload.image
        case .downloaded:
            return Asset.Gallery.mediaDownloaded.image
        case .error:
            return Asset.Gallery.mediaCorrupted.image
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .toDownload:
            return ColorName.highlightColor.color
        case .downloaded:
            return .white
        case .downloading:
            return ColorName.greenSpring20.color
        case .error:
            return .clear
        }
    }

    var tintColor: UIColor {
        switch self {
        case .toDownload:
            return .white
        case .downloading:
            return ColorName.greenSpring.color
        case .downloaded,
             .error:
            return ColorName.highlightColor.color
        }
    }

    var isDownloadActionInfoShown: Bool {
        switch self {
        case .toDownload,
             .downloading,
             .error:
            return true
        case .downloaded:
            return false
        }
    }

    var isShareActionInfoShown: Bool {
        !isDownloadActionInfoShown
    }
}

/// Gallery media model.

struct GalleryMedia: Equatable {
    // MARK: - Internal Properties
    var uid: String
    var source: GallerySourceType
    var mediaItems: [MediaItem]?
    var type: GalleryMediaType
    var downloadState: GalleryMediaDownloadState?
    var size: UInt64
    var date: Date
    var url: URL?
    var urls: [URL]?
    var formattedSize: String {
        return StorageUtils.sizeForFile(size: size)
    }
    var folderPath: String? {
        guard let url = url else { return nil }

        return url.deletingLastPathComponent().absoluteString
    }
    var prefix: String? {
        guard let url = url else { return nil }

        return url.prefix
    }
    var mainMediaItem: MediaItem? {
        guard let mediaItems = mediaItems else { return nil }

        return mediaItems.first
    }
    var mediaResources: [MediaItem.Resource]? {
        guard let mediaItems = mediaItems else { return nil }

        return mediaItems.reduce([]) { $0 + $1.resources }
    }

    /// Returns the media resource for a reduced resource index (from `mediaResources` array).
    ///
    /// - Parameters:
    ///    - reducedResourceIndex: Index of the resource to get in `mediaResources` array.
    ///
    /// - Returns: The media resource at index `reducedResourceIndex` in `mediaResources` if found, nil otherwise.
    func mediaResource(for reducedResourceIndex: Int) -> MediaItem.Resource? {
        guard let mediaResources = mediaResources,
              reducedResourceIndex < mediaResources.count  else { return nil }

        return mediaResources[reducedResourceIndex]
    }

    /// Returns the media item for a reduced resource index (from `mediaResources` array).
    ///
    /// - Parameters:
    ///    - reducedResourceIndex: Index of the resource to get in `mediaResources` array.
    ///
    /// - Returns: The media item from `mediaItems` array containing the desired resource if found, nil otherwise.
    func mediaItem(for reducedResourceIndex: Int) -> MediaItem? {
        guard let mediaResource = mediaResource(for: reducedResourceIndex) else { return nil }

        return mediaItems?.first(where: { $0.resources.map({ $0.uid }).contains(mediaResource.uid) })
    }

    // MARK: - Equatable Protocol
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.uid == rhs.uid
            && lhs.type == rhs.type
            && lhs.downloadState == rhs.downloadState
            && lhs.size == rhs.size
            && lhs.date == rhs.date
            && lhs.url == rhs.url
            && lhs.urls == rhs.urls
    }

    /// Whether an immersive panorama can be shown for the media.
    var canShowImmersivePanorama: Bool {
        guard let panoramaType = type.toPanoramaType,
              panoramaType == .sphere else {
            // Not a sphere panorama media type.
            return false
        }

        guard let urls = urls else { return false }
        return urls.contains(where: { $0.lastPathComponent.contains(panoramaType.rawValue) })
    }

    /// Whether a panorama can be generated for the media.
    /// `false` if not a panorama media type or if panorama has already been generated, `true` else.
    var canGeneratePanorama: Bool {
        guard let panoramaType = type.toPanoramaType else {
            // Not a panorama media type.
            return false
        }

        guard let urls = urls else { return false }
        return !urls.contains(where: { $0.lastPathComponent.contains(panoramaType.rawValue) })
    }

    var displayTitle: String? {
        let customTitle = mainMediaItem?.customTitle?
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")

        return customTitle?.isEmpty ?? true
            ? date.formattedString(dateStyle: .long, timeStyle: .short)
            : customTitle
    }
}
