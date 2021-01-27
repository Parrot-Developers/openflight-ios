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

    var icon: UIImage? {
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

    /// Returns GalleryMediaDownloadState as MediaTaskStatus.
    var asMediaTaskStatus: MediaTaskStatus {
        switch self {
        case .downloading:
            return MediaTaskStatus.running
        case .toDownload:
            return MediaTaskStatus.complete
        case .downloaded:
            return MediaTaskStatus.fileDownloaded
        case .error:
            return MediaTaskStatus.error
        }
    }
}

/// Gallery media model.

struct GalleryMedia: Equatable {
    // MARK: - Internal Properties
    var uid: String
    var source: GallerySourceType
    var mediaItem: MediaItem?
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

    // MARK: - Internal Funcs
    /// Determines if the panorama is already generated or not.
    ///
    /// - Parameters:
    ///     - type: Panorama media type for 360 panorama.
    /// - Returns: a boolean to know if panorama has already been generated for current media.
    func isPanoramaAlreadyGenerated(type: PanoramaMediaType?) -> Bool {
        guard let urls = self.urls,
              let panoramaType = self.type.toPanoramaType else {
            return false
        }

        if let strongType = type {
            switch strongType {
            case .custom, .preview:
                return true
            default:
                return urls.contains(where: { $0.lastPathComponent.contains(strongType.rawValue) })
            }
        } else {
            return urls.contains(where: { $0.lastPathComponent.contains(panoramaType.rawValue) })
        }
    }
}
