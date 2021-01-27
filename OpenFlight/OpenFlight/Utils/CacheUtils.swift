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

import Foundation
import UIKit

// MARK: - CacheUtils
/// Utilities to help with image cache.
final public class CacheUtils {

    // MARK: - Public Properties
    public static let shared = CacheUtils()

    // MARK: - Private Properties
    private let imageCacheSyncronizeQueue = DispatchQueue(label: "imageCacheSyncronizeQueue")
    private var imageCacheValues = [String: UIImage]()
    private var imageCache: [String: UIImage] {
        get {
            return imageCacheSyncronizeQueue.sync {
                imageCacheValues
            }
        }
        set(newValue) {
            imageCacheSyncronizeQueue.sync {
                self.imageCacheValues = newValue
            }
        }
    }
    private enum Constants {
        static let cacheDirectory = "Images"
        static let cacheSubDirectory = "imageCache"
    }

    // MARK: - Init
    init() {
        loadDictionary()
    }

    // MARK: - Public Funcs
    ///  Put an image in cache.
    ///
    /// - Parameters:
    ///   - image: image to cache.
    ///   - key: key where the image will be cached.
    public func cacheImage(_ image: UIImage, forKey key: String) {
        imageCache[key] = image
        writeDictionary()
    }

    ///  Returns an image for a specific key.
    ///
    /// - Parameters:
    ///   - key: key where the image is cached.
    public func image(forKey key: String) -> UIImage? {
        return imageCache[key]
    }

    ///  Remove the cache for a specific key.
    ///
    /// - Parameters:
    ///   - key: key where the image is cached.
    public func removeCache(forKey key: String) {
        imageCache[key] = nil
        writeDictionary()
    }
}

// MARK: - Private Computed Properties
private extension CacheUtils {
    var cacheImageURL: URL? {
        guard let cacheDirectoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let imageCacheDirectoryURL = cacheDirectoryURL.appendingPathComponent(Constants.cacheDirectory)
        try? FileManager.default.createDirectory(at: imageCacheDirectoryURL, withIntermediateDirectories: false, attributes: nil)
        return imageCacheDirectoryURL.appendingPathComponent(Constants.cacheSubDirectory)
    }
}

// MARK: - Private Funcs
private extension CacheUtils {

    /// Write image in cache folder.
    func writeDictionary() {
        guard let cacheFileURL = cacheImageURL else { return }
        let dict = NSDictionary(dictionary: imageCache.mapValues {value in
            return NSData(data: value.pngData() ?? Data())
        })
        dict.write(to: cacheFileURL, atomically: true)
    }

    /// Load image from cache folder.
    func loadDictionary() {
        guard let cacheFileURL = cacheImageURL else { return }
        let dict = NSDictionary(contentsOf: cacheFileURL)
        dict?.forEach { if let key = $0.key as? String,
            let value = $0.value as? NSData {
            imageCache[key] = UIImage(data: value as Data)
            }
        }
    }
}
