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

/// An object to find all AirSdk missions to upload.
class AirSdkMissionsToUploadFinder {
    // MARK: - Private Enums
    private enum Constants {
        static let airSdkMissionsPlistName: String = "embedded_missions_updates"
        static let airSdkMissionsPlistExtension: String = "plist"
        static let airSdkMissionsPlistDirectory: String = "embedded_missions"
    }

    // MARK: - Internal Funcs
    /// Returns all AirSdk missions on the file system.
    ///
    /// - Returns: The list of  all AirSdk missions to update.
    static func allAirSdkMissionsOnFiles() -> [AirSdkMissionToUpdateData] {
        guard let url = Bundle.main.url(forResource: Constants.airSdkMissionsPlistName,
                                        withExtension: Constants.airSdkMissionsPlistExtension,
                                        subdirectory: Constants.airSdkMissionsPlistDirectory) else {
            ULog.e(.missionUpdateTag,
                   "Missing \(Constants.airSdkMissionsPlistDirectory)/"
                    + "\(Constants.airSdkMissionsPlistName)."
                    + "\(Constants.airSdkMissionsPlistExtension) in main bundle.")
            assert(false)
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = PropertyListDecoder()
            do {
                return try decoder.decode([AirSdkMissionToUpdateData].self, from: data)
            } catch {
                ULog.e(.missionUpdateTag,
                       "Decoding \(Constants.airSdkMissionsPlistDirectory)/"
                        + "\(Constants.airSdkMissionsPlistName)."
                        + "\(Constants.airSdkMissionsPlistExtension) failed: \(error).")
                assert(false)
            }
        } catch {
            ULog.e(.missionUpdateTag,
                   "Reading \(Constants.airSdkMissionsPlistDirectory)/"
                    + "\(Constants.airSdkMissionsPlistName)."
                    + "\(Constants.airSdkMissionsPlistExtension) failed: \(error)")
            assert(false)
        }
        return []
    }

    /// Returns an URL pointing in the main bundle for a given file name.
    ///
    /// - Parameters:
    ///    - missionFilePath: The mission file name, prefixed by the containing folder and suffixed
    ///      by the file name extension.
    /// - Returns: An URL pointing in the main bundle for the given file name or `nil` if the
    ///   requested file name can not be found in the main bundle.
    static func url(ofMissionFileName missionFileName: String) -> URL? {
        // The extension is included in the missionFileName.
        guard let url = Bundle.main.url(forResource: missionFileName, withExtension: nil) else {
            return nil
        }

        return url
    }
}
