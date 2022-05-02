//    Copyright (C) 2022 Parrot Drones SAS
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
import SdkCore

extension ULogTag {
    static let cacheUtils = ULogTag(name: "cacheUtils")
}

// MARK: - CacheUtils
/// Utilities to help with image cache.
final public class CacheUtils {

    // MARK: - Public Properties
    public static let shared = CacheUtils()

    // MARK: - Private Properties
    private var imageCache = [String: UIImage]()
    private let cacheDirectory: URL?
    private enum Constants {
        static let cacheDirectory = "Images"
        static let maxFileNameLength = 64
    }

    // MARK: - Init
    init() {
        cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent(Constants.cacheDirectory)
        if let cacheDirectory = self.cacheDirectory,
           !FileManager.default.fileExists(atPath: cacheDirectory.path) {
            try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }

    // MARK: - Public Funcs
    ///  Put an image in cache.
    ///
    /// - Parameters:
    ///   - image: image to cache.
    ///   - key: key where the image will be cached.
    public func cacheImage(_ image: UIImage, forKey key: String) {
        imageCache[key] = image
        DispatchQueue.global().async { [weak self] in
            guard let self = self,
                  let imageUrl = self.fileUrl(key: key),
                  let imageData = image.pngData() else { return }
            do {
                if FileManager.default.fileExists(atPath: imageUrl.path) {
                    try FileManager.default.removeItem(at: imageUrl)
                }
                try imageData.write(to: imageUrl)
            } catch {
                ULog.e(.cacheUtils, "Unable to write \(imageData.count) bytes in \(imageUrl.absoluteString) : \(error.localizedDescription)")
            }
        }
    }

    ///  Returns an image for a specific key.
    ///
    /// - Parameters:
    ///   - key: key where the image is cached.
    public func image(forKey key: String) -> UIImage? {
        if let cachedImage = imageCache[key] {
            return cachedImage
        }
        if let imageUrl = fileUrl(key: key),
           let savedImage = UIImage(contentsOfFile: imageUrl.path) {
            imageCache[key] = savedImage
            return savedImage
        }
        return nil
    }

    ///  Remove the cache for a specific key.
    ///
    /// - Parameters:
    ///   - key: key where the image is cached.
    public func removeCache(forKey key: String) {
        imageCache[key] = nil
        if let imageUrl = fileUrl(key: key),
           FileManager.default.fileExists(atPath: imageUrl.path) {
            try? FileManager.default.removeItem(at: imageUrl)
        }
    }
}

// MARK: - Private Funcs
private extension CacheUtils {

    func fileUrl(key: String) -> URL? {
        let fileName = key.replacingOccurrences(of: "[^0-9a-zA-Z_]", with: "", options: .regularExpression)
            .prefix(Constants.maxFileNameLength)
        guard !fileName.isEmpty else { return nil }
        return cacheDirectory?.appendingPathComponent(fileName+".png")
    }
}
