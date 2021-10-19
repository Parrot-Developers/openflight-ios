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
import ArsdkEngine

// MARK: - Public Struct
/// Protobuf Mission Signature protocol.
public protocol ProtobufMissionSignature {
    /// The mission name.
    var name: String { get }
    /// The mission UID.
    var missionUID: String { get }
    /// The mission service unique id command.
    var serviceUidCommand: UInt { get }
    /// The mission service unique id event.
    var serviceUidEvent: UInt { get }
}

/// All OpenFlight signatures.
public struct OFMissionSignatures {
    public static let helloWorld = HelloWorldMissionSignature()
    public static let ophtalmo = OphtalmoMissionSignature()
    public static let defaultMission = DefaultMissionSignature()
}

// MARK: - Default mission
/// Default protobuf mission.
public struct DefaultMissionSignature: ProtobufMissionSignature {
    public init() {}

    /// The mission name.
    public let name: String = ""

    /// The mission UID.
    public let missionUID: String = "default"

    /// The mission service unique id command.
    public var serviceUidCommand: UInt = 0

    /// The mission service unique id event.
    public var serviceUidEvent: UInt = 0
}

/// Default protobuf mission activation model.
public struct DefaultMissionActivationModel: MissionActivationModel {
    private var protobufMissionsManager: ProtobufMissionsManager {
        Services.hub.drone.protobufMissionsManager
    }

    private var protobufMissionListener: ProtobufMissionsListener {
        Services.hub.drone.protobufMissionsListener
    }

    public init () { }

    /// Activates the mission.
    public func startMission() {
        protobufMissionsManager.activate(mission: OFMissionSignatures.defaultMission)
    }

    /// Deactivates the mission.
    public func stopMissionIfNeeded() {
        protobufMissionsManager.deactivate(mission: OFMissionSignatures.defaultMission)
    }
}

// MARK: - Ophtalmo mission
/// Ophtalmo mission signature.
public struct OphtalmoMissionSignature: ProtobufMissionSignature {

    fileprivate init() {}

    /// The mission name.
    public let name: String = "Ophtalmo" // TODO: add resource

    /// The mission UID.
    public let missionUID: String = "com.parrot.missions.ophtalmo"

    /// The mission service unique id command.
    public var serviceUidCommand: UInt {
        return "parrot.missions.ophtalmo.airsdk.messages.Command".serviceId
    }

    /// The mission service unique id event.
    public var serviceUidEvent: UInt {
        return "parrot.missions.ophtalmo.airsdk.messages.Event".serviceId
    }
}

// MARK: - HelloWorld mission
/// HelloWorld protobuf mission.
public struct HelloWorldMissionSignature: ProtobufMissionSignature {
    public init() {}

    /// The mission name.
    public let name: String = L10n.missionHello

    /// The mission UID.
    public let missionUID: String = "com.parrot.missions.samples.hello"

    /// The mission service unique id command.
    public var serviceUidCommand: UInt {
        return "parrot.missions.samples.hello.airsdk.messages.Command".serviceId
    }

    /// The mission service unique id event.
    public var serviceUidEvent: UInt {
        return "parrot.missions.samples.hello.airsdk.messages.Event".serviceId
    }
}
