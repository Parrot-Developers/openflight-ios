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

import UIKit

// MARK: - Internal Enums
/// Enum describing drone connection state for pairing.
enum PairingDroneConnectionState {
    case disconnected
    case connecting
    case connected
    case incorrectPassword

    /// String describing pairing drone connection state.
    var description: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case.connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        case .incorrectPassword:
            return "Incorrect Password"
        }
    }
}

// MARK: - Internal Structs
/// Struct used to provide a model for drones list.
struct RemoteConnectDroneModel: Equatable {
    // MARK: - Internal Properties
    var droneUid: String
    var droneName: String
    var isKnown: Bool
    var rssiImage: UIImage
    var isDronePaired: Bool
    var isDroneConnected: Bool
    var commonName: String

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - droneUid: drone id
    ///    - droneName: drone name
    ///    - isKnown: tells if the drone is already known
    ///    - rssiImage: image for rssi value
    ///    - isDronePaired: tells if drone is paired for 4G
    ///    - isDroneConnected: tells if drone is connected
    ///    - commonName: common name
    init(droneUid: String,
         droneName: String,
         isKnown: Bool,
         rssiImage: UIImage,
         isDronePaired: Bool,
         isDroneConnected: Bool,
         commonName: String) {
        self.droneUid = droneUid
        self.droneName = droneName
        self.isKnown = isKnown
        self.rssiImage = rssiImage
        self.isDronePaired = isDronePaired
        self.isDroneConnected = isDroneConnected
        self.commonName = commonName
    }
}

// MARK: - Public Structs
/// Paired drone object used to parse API reponse to get drones list response..
public struct PairedDroneListResponse: Codable {
    // MARK: - Internal Properties
    public var serial: String?
    public var modelId: String?
    public var pairedFor4g: Bool
    public var commonName: String?

    // MARK: - Internal Enums
    enum CodingKeys: String, CodingKey {
        case serial
        case modelId = "model_id"
        case pairedFor4g = "paired_for_4g"
        case commonName = "common_name"
    }
}

/// Paired drone object used to parse API reponse to get users count response.
public struct PairedUsersCountResponse: Codable {
    // MARK: - Internal Properties
    var usersCount: Int

    // MARK: - Internal Enums
    enum CodingKeys: String, CodingKey {
        case usersCount = "users_count"
    }
}
