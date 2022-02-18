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

/// Typealias for listener callback signature.
typealias AirSdkMissionUpdaterClosure = (_ : AirSdkMissionToUpdateStatus) -> Void

// MARK: - AirSdkMissionUpdaterListener
/// A listener to listen to a change during a AirSdk mission upload.
final class AirSdkMissionUpdaterListener: NSObject {
    // MARK: - Internal Properties
    /// The mission to listen to.
    let missionToUpdateData: AirSdkMissionToUpdateData
    /// The callback that will be called when a change occurs during the mission update.
    let missionToUpdateCallback: AirSdkMissionUpdaterClosure

    // MARK: - Init
    /// Inits the listener.
    ///
    /// - Parameters:
    ///   - missionToUpdateData: The specific mission to listen to
    ///   - missionToUpdateCallback: The callback that will be trigger when a change occurs during the mission upload.
    init(missionToUpdateData: AirSdkMissionToUpdateData,
         missionToUpdateCallback: @escaping AirSdkMissionUpdaterClosure) {
        self.missionToUpdateData = missionToUpdateData
        self.missionToUpdateCallback = missionToUpdateCallback
    }
}

// MARK: - Private Enums
/// The global state of all missions updates.
enum AirSdkMissionsGlobalUpdatingState {
    case ongoing
    case uploading
    case done
}

/// Typealias for listener callback signature.
typealias AirSdkAllMissionsUpdaterClosure = (_ : AirSdkMissionsGlobalUpdatingState) -> Void

/// A listener to listen to a change during a all missions updates.
final class AirSdkAllMissionsUpdaterListener: NSObject {
    // MARK: - Internal Properties
    /// The callback that will be trigger when a change occurs during  all the missions updates.
    let allMissionToUpdateCallback: AirSdkAllMissionsUpdaterClosure

    // MARK: - Init
    /// Inits the listener.
    ///
    /// - Parameters:
    ///   - allMissionToUpdateCallback: The callback that will be trigger when a change occurs during  all the missions updates.
    init(allMissionToUpdateCallback: @escaping AirSdkAllMissionsUpdaterClosure) {
        self.allMissionToUpdateCallback = allMissionToUpdateCallback
    }
}
