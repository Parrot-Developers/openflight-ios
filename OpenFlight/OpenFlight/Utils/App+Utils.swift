// Copyright (C) 2020 Parrot Drones SAS
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

/// Class for Application version and application locales.
final class AppUtils {
    private init() { }

    /// Get Application version.
    ///
    /// - Returns: String with current application version
    static var version: String {
        var appVersion = "OpenFlight v"

        #if DEBUG
        let debugBuild = true
        #else
        let debugBuild = false
        #endif

        if Bundle.main.isInHouseBuild || debugBuild {
            // Display all informations (DEV or InHouse build).
            if Bundle.main.isInHouseBuild {
                appVersion = "v-InHouse- "
            } else {
                appVersion = "v-Dev-"
            }
            appVersion += Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0.0.0"
        } else {
            // Release build.
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                appVersion += "\(version)"
            } else {
                appVersion += "1.0.0"
            }
            // Release build - try to detect Test Flight.
            if let storeUrl = Bundle.main.appStoreReceiptURL?.lastPathComponent,
                storeUrl.range(of: "sandbox", options: .caseInsensitive) != nil {
                if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    appVersion += " (\(build))"
                }
            }
        }
        return appVersion
    }

    /// Get Application language.
    ///
    /// - Returns: String with current application language
    /// - Note: Format is "xx_XX" e.g. en_US or fr_FR
    static var language: String {
        let locale = Locale.current
        guard let languageCode = locale.languageCode,
            let regionCode = locale.regionCode else {
                return "en_US"
        }
        return languageCode + "_" + regionCode
    }

    /// Get Application language code.
    ///
    /// - Returns: String with current language code
    /// - Note: Format is "xx" e.g. en or fr
    static var languageCode: String {
        let locale = Locale.current
        guard let code = locale.languageCode else {
            return "en"
        }
        return code
    }

    /// Get Application country.
    ///
    /// - Returns: String with current country code
    /// - Note: Format is "XX" e.g. US or FR
    static var countryCode: String {
        let locale = Locale.current
        guard let regionCode = locale.regionCode else {
            return "US"
        }
        return regionCode
    }
}
