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
            return Asset.Pairing.icloading.image
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
        case .downloaded,
             .downloading:
            return .white
        case .error:
            return .clear
        }
    }

    var tintColor: UIColor {
        switch self {
        case .toDownload:
            return .white
        case .downloading,
             .downloaded:
            return ColorName.highlightColor.color
        case .error:
            return ColorName.errorColor.color
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

    func title(_ text: String?) -> String? {
        switch self {
        case .downloading,
             .downloaded:
            return nil
        default:
            return text ?? L10n.commonDownload
        }
    }
}

/// Gallery media model.

struct GalleryMedia: Equatable {
    // MARK: - Internal Properties
    var uid: String
    var customTitle: String?
    var source: GallerySourceType
    var mediaItems: [MediaItem]?
    var type: GalleryMediaType
    var downloadState: GalleryMediaDownloadState?
    var size: UInt64
    var date: Date
    var flightDate: Date?
    var bootDate: Date?
    var url: URL?
    var urls: [URL]?
    /// The previewable resources' URLs: any non-DNG resources.
    var previewableUrls: [URL]? {
        urls?.filter { $0.pathExtension != MediaItem.Format.dng.description.uppercased() }
    }
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
        return mediaItems.reduce([]) { $0 + sortedResources($1.resources) }
    }
    /// The previewable resources.
    var previewableResources: [MediaItem.Resource]? {
        guard let mediaItems = mediaItems else { return nil }
        return mediaItems.reduce([]) { $0 + sortedResources($1.previewableResources) }
    }
    /// Whether the media has a DNG resource.
    var hasDng: Bool {
        switch source {
        case .mobileDevice:
            guard let dngUrls = urls?.filter({ $0.pathExtension == MediaItem.Format.dng.description.uppercased() }) else {
                return false
            }
            return !dngUrls.isEmpty
        default:
            guard let dngResources = mediaResources?.filter({ $0.format == .dng }) else {
                return false
            }
            return !dngResources.isEmpty
        }
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

    /// Returns an array containing the index of all linked resources based on a specific previewable resource's index.
    /// Linked resources are DNG and JPG versions of a given capture. Implementation is however generic in order
    /// to allow any further potential change.
    ///
    /// - Parameter previewableIndex: the index of the previewable resource
    /// - Returns: the indexes of all linked resources (previewable AND non-previewable)
    func linkedResourcesIndexes(for previewableIndex: Int) -> [Int] {
        let resourcesCount: Int?
        let previewablesCount: Int?

        // Get resources counts according to media's source.
        switch source {
        case .droneSdCard, .droneInternal:
            resourcesCount = mediaResources?.count
            previewablesCount = previewableResources?.count
        default:
            resourcesCount = urls?.count
            previewablesCount = previewableUrls?.count
        }

        guard let resourcesCount = resourcesCount,
              let previewablesCount = previewablesCount else {
            return []
        }

        if resourcesCount == previewablesCount {
            // Media does not contain any non-previewable resources.
            // => Return the single resource index `previewableIndex`.
            return [previewableIndex]
        }

        // Get resources count multiplier in order to be able to gather all the non-previewable
        // resources for `previewableIndex`.
        // - In usual case, `mult` always equals 2, as a non-previewable resource is limited
        //   to the DNG version of a capture.
        // - Missing resources case needs however to be addressed, as a DNG+JPG download
        //   can been interrupted, which could for example lead to a DNG version missing its
        //   JPG version (hence the `.rounded(.up)`).
        let mult = Int((Float(resourcesCount) / Float(max(1, previewablesCount))).rounded(.up))

        return Array(mult * previewableIndex ..< mult * (previewableIndex + 1))
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
            && lhs.flightDate == rhs.flightDate
            && lhs.bootDate == rhs.bootDate
            && lhs.url == rhs.url
            && lhs.urls == rhs.urls
            && lhs.mediaResources?.count == rhs.mediaResources?.count
    }

    /// Whether an immersive panorama can be shown for the media.
    var canShowImmersivePanorama: Bool {
        guard let panoramaType = type.toPanoramaType,
              panoramaType == .sphere else {
            // Not a sphere panorama media type.
            return false
        }

        return mediaResources?.first(where: { $0.type == .panorama }) != nil
            || urls?.contains(where: { $0.lastPathComponent.contains(panoramaType.rawValue) }) ?? false
    }

    /// Whether a panorama can be generated for the media.
    /// `false` if not a panorama media type or if panorama has already been generated, `true` else.
    var canGeneratePanorama: Bool {
        switch source {
        case .droneSdCard,
             .droneInternal:
            return canGenerateDronePanorama
        case .mobileDevice:
            return canGenerateDevicePanorama
        default:
            return false
        }
    }

    /// The panorama generationState.
    var panoramaGenerationState: PanoramaGenerationState {
        switch source {
        case .droneSdCard,
             .droneInternal:
            return panoramaGenerationState(canGenerate: canGenerateDronePanorama,
                                           hasExpectedCount: hasDronePanoramaExpectedCount)
        case .mobileDevice:
            return panoramaGenerationState(canGenerate: canGenerateDevicePanorama,
                                           hasExpectedCount: hasDevicePanoramaExpectedCount)
        case .unknown:
            return .none
        }
    }

    var title: String {
        guard let customTitle = customTitle else {
            return (flightDate ?? date).commonFormattedString
        }

        return customTitle
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
    }

    var cellTitle: String {
        if let range = title.range(of: " - ", options: [.backwards], range: nil, locale: nil) {
            return title.replacingCharacters(in: range, with: "\n")
        }

        return title
    }

    // MARK: - Private

    /// Whether a panorama can be generated for the drone media.
    /// `false` if not a panorama media type or if panorama has already been generated, `true` else.
    private var canGenerateDronePanorama: Bool {
        guard type.toPanoramaType != nil, let resources = mediaResources else { return false }

        // Check whether a .panorama resource already exists.
        return resources.first(where: { $0.type == .panorama }) == nil
    }

    /// Whether a panorama media on drone's memory has expected resources count for generation.
    private var hasDronePanoramaExpectedCount: Bool {
        guard type.toPanoramaType != nil, let resources = mediaResources else { return false }
        return resources.count == mainMediaItem?.expectedCount ?? 0
    }

    /// Whether a panorama can be generated for the device media.
    /// `false` if not a panorama media type or if panorama has already been generated, `true` else.
    private var canGenerateDevicePanorama: Bool {
        guard let panoramaType = type.toPanoramaType, let urls = urls else { return false }

        // Check whether a .panorama resource already exists.
        return !urls.contains(where: { $0.lastPathComponent.contains(panoramaType.rawValue) })
            && mediaResources?.first(where: { $0.type == .panorama }) == nil
    }

    /// Whether a panorama media on device's memory has expected resources count for generation.
    private var hasDevicePanoramaExpectedCount: Bool {
        guard type.toPanoramaType != nil, let urls = urls else { return false }

        // Return `true` if `expectedCount` is `nil` in order to ensure panoramas that were downloaded on device before
        // `expectedCount` support in `AssetUtils.mediaResourcesInfo` still can be generated.
        guard let expectedCount = mainMediaItem?.expectedCount else { return true }

        return urls.count == expectedCount
    }

    /// The panorama generation state according to generation capability and expected resources count.
    ///
    /// - Parameters:
    ///    - canGenerate: whether media type is panorama and has not already been generated
    ///    - hasExpectedCount: the expected resources count for the panorama generation
    private func panoramaGenerationState(canGenerate: Bool, hasExpectedCount: Bool) -> PanoramaGenerationState {
        guard canGenerate else { return .none }
        return hasExpectedCount ? .toGenerate : .missingResources
    }

    /// Returns sorted resources array (has no effect if initial array does not contain any .panorama resource).
    ///
    /// - Parameters:
    ///    - resources: The initial resources array.
    /// - Returns: Same array with .panorama resource (if any) being moved at first position in order to be correctly displayed in gallery.
    private func sortedResources(_ resources: [MediaItem.Resource]) -> [MediaItem.Resource] {
        guard let index = resources.firstIndex(where: { $0.type == .panorama }) else { return resources }

        var sortedResources = resources
        let resource = sortedResources.remove(at: index)
        sortedResources.insert(resource, at: 0)

        return sortedResources
    }
}

extension MediaItem {
    /// The `MediaItem` resources that can be previewed on the device: any non-DNG resources.
    var previewableResources: [Resource] {
        resources.filter { $0.format != .dng }
    }
}
