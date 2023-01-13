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

import Foundation

/// Utility extension for `URL`.

extension URL {
    /// Returns media Url, relative to Documents directory.
    var mediaRelativeUrl: String? {
        guard let mediaIndex = absoluteString.range(of: Paths.mediasDirectory)?.upperBound
            else { return nil }

        return String(absoluteString[mediaIndex...])
    }

    /// Returns url's prefix last past component.
    var prefix: String {
        return String(self.lastPathComponent.prefix(AssetUtils.Constants.prefixLength))
    }

    /// The drone UID extracted from first URL component (requires a valid media URL path).
    var droneUid: String {
        mediaRelativeUrl?.droneUid ?? ""
    }

    /// The resource ID extracted from URL last component.
    /// Based on SDK spec.
    var resId: String { lastPathComponent }

    /// Adds query parameters to a given URL.
    ///
    /// - Parameters:
    ///   - queryItem: The query item
    ///   - value: The query value
    /// - Returns: a new optional URL with the query parameters.
    public func appending(_ queryItem: String, value: String?) -> URL? {
        guard var urlComponents = URLComponents(string: absoluteString) else { return absoluteURL }

        var queryItems: [URLQueryItem] = urlComponents.queryItems ?? []
        let queryItem = URLQueryItem(name: queryItem,
                                     value: value)
        queryItems.append(queryItem)
        urlComponents.queryItems = queryItems
        // The '+' symbol is not percent encoded by URLComponents, so we have to do it manually
        urlComponents.percentEncodedQuery = urlComponents.percentEncodedQuery?
                   .replacingOccurrences(of: "+", with: "%2B")

        return urlComponents.url
    }

    /// Whether URL is a directory.
    var isDirectory: Bool {
       (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}
