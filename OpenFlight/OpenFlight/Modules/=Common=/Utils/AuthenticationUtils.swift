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
import GroundSdk

// MARK: - AuthenticationUtils
/// Utilities to manage authentication methods.
public final class AuthenticationUtils {
    // MARK: - Public Properties
    public static var boundary: String {
        return "Boundary-\(UUID().uuidString)"
    }

    // MARK: - Public Funcs
    /// Bearer authentication is an HTTP authentication scheme that involves security tokens called bearer tokens.
    ///
    /// - Parameters:
    ///     - token: MyParrot token
    /// - Returns: The bearer string.
    public static func bearer(token: String) -> String {
        return "Bearer \(token)"
    }

    /// Create an authentication token from parameters.
    ///
    /// - Parameters:
    ///    - params: parameters to add to the token
    ///    - apcKey: MyParrot APC key
    /// - Returns: The authentication token.
    public static func token(params: [String: String], apcKey: String) -> String {
        let time = "\(DateTimeUtils.timestamp())"
        var strToHash = params.sorted(by: <).reduce("") { $0 + $1.1 }
        strToHash += "\(time)"
        strToHash += "\(apcKey)"
        let token = strToHash.data(using: .utf8)?.md5 ?? ""
        return "ts=\(time)&token=\(token)"
    }
}

public extension URLSessionConfiguration {

    /// Add User agent
    func addUserAgentHeader() {
        // user agent
        let userAgent = "\(AppInfoCore.appBundle)/\(AppInfoCore.appVersion) " +
            "(\(UIDevice.current.systemName); \(UIDevice.identifier); \(UIDevice.current.systemVersion)) " +
        "\(AppInfoCore.sdkBundle)/\(AppInfoCore.sdkVersion)"
        let additionalHeaders: [AnyHashable: Any] = ["User-Agent": userAgent]
        httpAdditionalHeaders = httpAdditionalHeaders?.merging(additionalHeaders) { (current, _) in current }
    }
}
