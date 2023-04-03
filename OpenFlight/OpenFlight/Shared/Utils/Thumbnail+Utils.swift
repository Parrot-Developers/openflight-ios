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

import AVFoundation
import GroundSdk
import UIKit
import MapKit

/// Utilities to handle image thumbnails.
final class ThumbnailUtils {
    // MARK: - Constants
    private enum Constants {
        static let thumbnailWidth: CGFloat = 300
        static let timeTolerance: Double = 1.0
        static let coordinateSpan: CLLocationDegrees = 0.03
    }

    // MARK: - Public Properties
    static let shared = ThumbnailUtils()

    // MARK: - Private properties
    private let operationQueue = OperationQueue()
    static private let imageCache = NSCache<AnyObject, AnyObject>()

    // MARK: - Init
    init() {
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.qualityOfService = .userInteractive
    }

    /// Loads a local thumbnail if available, generates it otherwise.
    ///
    /// - Parameters:
    ///    - resourceURL: url of the ressource
    ///    - isVideo: boolean
    ///    - completion: completion block
    static func loadLocalThumbnail(resourceURL: URL, isVideo: Bool = false, completion: @escaping (_ image: UIImage?) -> Void) {
        if isThumbnailInCache(resourceURL: resourceURL) {
            loadThumbnailFromCache(resourceURL: resourceURL, completion: completion)
        } else if FileManager.default.fileExists(atPath: resourceURL.path) {
            generateThumbnail(resourceURL: resourceURL, isVideo: isVideo, completion: completion)
        }
    }

    /// Generates the map thumbnail.
    ///
    /// - Parameters:
    ///    - location: the center location of the thumbnail
    ///    - thumbnailSize: the size of the thumbnail
    ///    - completion: completion block
    static func generateMapThumbnail(location: CLLocation,
                                     thumbnailSize: CGSize? = nil,
                                     completion: @escaping (UIImage?) -> Void) {
        let center = location.coordinate
        let mapSnapshotterOptions = MKMapSnapshotter.Options()
        let region = MKCoordinateRegion(center: center,
                                        span: MKCoordinateSpan(latitudeDelta: Constants.coordinateSpan,
                                                               longitudeDelta: Constants.coordinateSpan))
        mapSnapshotterOptions.region = region
        mapSnapshotterOptions.mapType = .satellite
        mapSnapshotterOptions.size = thumbnailSize ?? CGSize(width: Constants.thumbnailWidth,
                                                             height: Constants.thumbnailWidth)
        let snapShotter = MKMapSnapshotter(options: mapSnapshotterOptions)
        DispatchQueue.global(qos: .background).async {
            snapShotter.start { (snapshot: MKMapSnapshotter.Snapshot?, _) in
                completion(snapshot?.image)
            }
        }
    }
}

// MARK: - Private Funcs
private extension ThumbnailUtils {
    /// Generates a thumbnail for given resourceURL.
    ///
    /// - Parameters:
    ///    - resourceURL: url of the ressource
    ///    - isVideo: boolean
    ///    - completion: completion block
    static func generateThumbnail(resourceURL: URL, isVideo: Bool, completion: @escaping (_ image: UIImage?) -> Void) {
        let mainThreadCompletion: (_ image: UIImage?) -> Void = { image in
            if let thumbnail = image {
                thumbnail.compressedThumbnail(width: Constants.thumbnailWidth) { data in
                    if let compressedData = data {
                        DispatchQueue.global(qos: .background).async {
                            if let compressedImage = UIImage(data: compressedData) {
                                imageCache.setObject(compressedImage, forKey: resourceURL.absoluteString as AnyObject)
                                DispatchQueue.main.async {
                                    completion(compressedImage)
                                }
                            } else {
                                DispatchQueue.main.async {
                                    completion(nil)
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                    }
                }
            }
        }
        if isVideo {
            ThumbnailUtils.shared.generateImageForAsset(withURL: resourceURL, completion: mainThreadCompletion)
        } else {
            ThumbnailUtils.shared.loadImageOnQueue(withURL: resourceURL, completion: mainThreadCompletion)
        }
    }

    /// Check if a given resourceURL has a thumbnail in cache.
    ///
    /// - Parameters:
    ///    - resourceURL: url of the ressource
    /// - Returns: boolean result
    static func isThumbnailInCache(resourceURL: URL) -> Bool {
        return imageCache.object(forKey: resourceURL.absoluteString as AnyObject) != nil
    }

    /// load a thumbnail from cache for given resourceURL.
    ///
    /// - Parameters:
    ///    - resourceURL: url of the ressource
    ///    - completion: completion block
    static func loadThumbnailFromCache(resourceURL: URL, completion: @escaping (_ image: UIImage?) -> Void) {
        let image = imageCache.object(forKey: resourceURL.absoluteString as AnyObject) as? UIImage
        completion(image)
    }

    /// Returns image generated from first asset frame.
    ///
    /// - Parameters:
    ///    - url: url
    ///    - completion: completion block
    func generateImageForAsset(withURL url: URL, completion: @escaping (_ image: UIImage?) -> Void) {
        operationQueue.addOperation {
            var resultImage: UIImage?
            let asset = AVAsset(url: url)
            let assetImageGenerate = AVAssetImageGenerator(asset: asset)
            assetImageGenerate.appliesPreferredTrackTransform = true
            assetImageGenerate.requestedTimeToleranceAfter = CMTime(seconds: Constants.timeTolerance,
                                                                    preferredTimescale: asset.duration.timescale)
            assetImageGenerate.requestedTimeToleranceBefore = CMTime.zero
            assetImageGenerate.maximumSize = CGSize(width: Constants.thumbnailWidth, height: Constants.thumbnailWidth)

            if let generatedImage = try? assetImageGenerate.copyCGImage(at: CMTimeMake(value: 0, timescale: asset.duration.timescale), actualTime: nil) {
                resultImage = UIImage(cgImage: generatedImage)
            }

            completion(resultImage)
        }
    }

    /// Returns image from given URL if exists, nil otherwise. It operates on operationQueue.
    ///
    /// - Parameters:
    ///    - url: url
    ///    - completion: completion block
    func loadImageOnQueue(withURL url: URL, completion: @escaping (_ image: UIImage?) -> Void) {
        var resultImage: UIImage?
        operationQueue.addOperation {
            if FileManager.default.fileExists(atPath: url.path) {
                if let data = try? Data(contentsOf: url) {
                    resultImage = UIImage(data: data)
                }
            }
            completion(resultImage)
        }
    }
}
