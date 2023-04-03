// Copyright (C) 2022 Parrot Drones SAS
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

public extension FileManager {

    /// List files urls in a directory, with a filter on the file extension.
    ///
    /// - Parameters:
    ///   - directoryUrl: URL of the directory
    ///   - fileExt: Name of the file extension to filter, `nil` otherwise.
    ///   - keys: keys An array of keys that identify the file properties that you want pre-fetched for each item in
    ///   - includingSubfolders: `true` to include subfolders, `false` otherwise
    ///  the directory. For each returned URL, the specified properties are fetched and cached in the NSURL object.
    ///  For a list of keys you can specify, see Common File System Resource Keys.
    /// - Returns: the list of urls
    /// - Throws: propagate the `FileManager.default.contentsOfDirectory()` error
    static func listURLs(
        directoryUrl: URL, fileExt: String?, includingPropertiesForKeys keys: [URLResourceKey]? = nil,
        includingSubfolders: Bool = false)  throws -> [URL] {

        var returnList = [URL]()
        let optionMask: FileManager.DirectoryEnumerationOptions =
            includingSubfolders ? [] : [FileManager.DirectoryEnumerationOptions.skipsSubdirectoryDescendants]

        if let allContent = FileManager.default.enumerator(
            at: directoryUrl, includingPropertiesForKeys: keys, options: optionMask, errorHandler: nil) {

            for case let url as URL in allContent {
                if let fileExt = fileExt, url.pathExtension != fileExt {
                    // skip
                } else {
                    returnList.append(url)
                }
            }
        }
        return returnList
    }

    /// List files urls and attributes (`.creationDateKey`, `.fileSizeKey`) in a directory, with a filter on the file
    /// extension.
    ///
    /// - Parameters:
    ///   - directoryUrl: URL of the directory
    ///   - fileExt: name of the file extension to filter, `nil` otherwise.
    ///   - includingSubfolders: `true` to include subfolders, `false` otherwise
    /// - Returns: an array of tuples (`URL`, `URLResourceValues`). Note: only [.creationDateKey, .fileSizeKey]
    /// values are read
    /// - Throws: propagate the `FileManager.default.contentsOfDirectory()` error
    static func listURLsWitAttributes(directoryUrl: URL, fileExt: String?, includingSubfolders: Bool = false) throws
        -> [(url: URL, res: URLResourceValues?)] {

        let propertiesKeys: Set<URLResourceKey> = [.creationDateKey, .fileSizeKey]
        let directoryContent = try listURLs(
            directoryUrl: directoryUrl, fileExt: fileExt, includingPropertiesForKeys: Array(propertiesKeys),
            includingSubfolders: includingSubfolders)

        return directoryContent.map {
            let attr = try? $0.resourceValues(forKeys: propertiesKeys)
            return ($0, attr)
        }
    }

    /// Checks files in a directory, with a filter on the file extension. Older files are deleted
    /// if the total size is greater than a specified quota.
    ///
    /// - Parameters:
    ///   - url: URL of the directory, `nil` otherwise
    ///   - fileExt: name of the file extension to filter
    ///   - totalMaxSizeMb: quota in mega bytes
    ///   - includingSubfolders: `true` to include subfolders, `false` otherwise
    /// - Throws: propagate the `FileManager.default.contentsOfDirectory()` error
    static func reduceDirectorySize(
        url: URL, fileExt: String?, totalMaxSizeMb: Int, includingSubfolders: Bool = false) throws {

        do {
            let listFilesWithAttr = try FileManager.listURLsWitAttributes(
                directoryUrl: url, fileExt: fileExt, includingSubfolders: includingSubfolders).sorted { elt1, elt2 in
                    let date1 = elt1.res?.creationDate ?? Date.distantPast
                    let date2 = elt2.res?.creationDate ?? Date.distantPast
                    return date1 > date2
            }
            var totalSize = 0
            for elt in listFilesWithAttr {
                let size = elt.res?.fileSize ?? 0
                totalSize += size
                if totalSize > totalMaxSizeMb * 1024  * 1024 {
                    try? FileManager.default.removeItem(at: elt.url)
                }
            }
        } catch {
            // no directory
            return
        }
    }
}
