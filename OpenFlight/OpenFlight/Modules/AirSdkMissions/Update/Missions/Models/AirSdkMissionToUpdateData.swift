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

/// Indication of compatibility of a drone firmware with the mission.
public enum FirmwareCompatibility {
    case compatible
    case tooOld
    case tooRecent
}

// MARK: - Internal Structs
/// A struct to represent a AirSdk mission to update.
public struct AirSdkMissionToUpdateData: Equatable, Decodable {
    // MARK: - Internal Properties
    let missionVersion: String
    let internalName: String
    let missionUID: String
    let missionFilePath: String
    let minTargetVersion: String
    let maxTargetVersion: String
    var missionName: String?

    // MARK: - Private Enums
    private enum CodingKeys: String, CodingKey {
        case missionVersion = "version"
        case internalName = "name"
        case missionUID = "uid"
        case missionFilePath = "embeddedPath"
        case minTargetVersion = "minTargetVersion"
        case maxTargetVersion = "maxTargetVersion"
    }

    // MARK: - Equatable
    public static func == (lhs: AirSdkMissionToUpdateData, rhs: AirSdkMissionToUpdateData) -> Bool {
        return lhs.missionUID == rhs.missionUID
            && lhs.missionFilePath == rhs.missionFilePath
            && lhs.missionVersion == rhs.missionVersion
    }

    // MARK: - Internal Funcs
    /// Returns `true` if the mission is the same as the one given in parameter, but with an upper version.
    ///
    /// - Parameters:
    ///   - mission: a mission
    func isSameAndGreaterVersion(of mission: AirSdkMissionBasicInformation) -> Bool {
        // verify mission ids match
        if missionUID != mission.missionUID {
            return false
        } else if let version = FirmwareVersion.parse(versionStr: missionVersion),
                  let otherVersion = FirmwareVersion.parse(versionStr: mission.missionVersion) {
            // missions versions are formatted in 'firmware version format',
            // compare versions using GroundSdk helpers
            return version > otherVersion
        } else {
            // fallback, should not happen
            return missionVersion > mission.missionVersion
        }
    }

    /// Returns the indication of compatibility of the given firmware with the mission.
    ///
    /// - Parameter firmwareVersionStr: a firmware version
    func compatibility(with firmwareVersionStr: String) -> FirmwareCompatibility {
        if let firmwareVersion = FirmwareVersion.parse(versionStr: firmwareVersionStr),
           let minVersion = FirmwareVersion.parse(versionStr: minTargetVersion),
           let maxVersion = FirmwareVersion.parse(versionStr: maxTargetVersion) {
            // versions are formatted in 'firmware version format',
            // compare versions using GroundSdk helpers
            if firmwareVersion < minVersion {
                return .tooOld
            } else if firmwareVersion > maxVersion {
                return .tooRecent
            }
        }
        return .compatible
    }
}

/// A struct to represent a AirSdk mission.
public struct AirSdkMissionBasicInformation: Equatable {
    let missionUID: String
    let missionName: String
    let missionVersion: String
    let isBuiltIn: Bool
    let isCompatible: Bool

    // MARK: - Equatable
    public static func == (lhs: AirSdkMissionBasicInformation,
                    rhs: AirSdkMissionBasicInformation) -> Bool {
        return lhs.missionUID == rhs.missionUID
            && lhs.missionVersion == rhs.missionVersion
    }
}
