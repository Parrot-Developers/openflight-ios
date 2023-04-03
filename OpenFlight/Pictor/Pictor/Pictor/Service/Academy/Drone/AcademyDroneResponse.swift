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

// MARK: - Academy Drone Response
public struct AcademyDroneResponse: Codable {
    public var serial: String?
    public var modelId: String?
    public var lastUseDate: Date?
    public var pairedFor4G: Bool
    public var commonName: String?

    enum CodingKeys: String, CodingKey {
        case serial
        case modelId = "model_id"
        case lastUseDate
        case pairedFor4G = "paired_for_4g"
        case commonName = "common_name"
    }

    func toPictorEngine() -> PictorEngineDroneModel {
        let baseModel = PictorDroneModel(uuid: serial ?? "",
                                         cloudId: 0,
                                         serialNumber: serial ?? "",
                                         commonName: commonName ?? "",
                                         modelId: modelId ?? "",
                                         paired4G: pairedFor4G)
        let engineModel = PictorEngineDroneModel(droneModel: baseModel,
                                                 synchroStatus: .synced,
                                                 synchroLatestStatusDate: Date())
        return engineModel
    }
}

// MARK: - Academy Drone Paired Users Response
struct AcademyPairedUsersCountResponse: Codable {
    var usersCount: Int

    enum CodingKeys: String, CodingKey {
        case usersCount = "users_count"
    }
}
