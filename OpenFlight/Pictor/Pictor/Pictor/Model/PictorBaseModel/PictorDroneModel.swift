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

// MARK: - Protocol
public protocol PictorBaseDroneModel: PictorBaseModel {
    var cloudId: Int64 { get }
    var serialNumber: String { get set }
    var commonName: String { get set }
    var modelId: String { get set }
    var paired4G: Bool { get set }
}

// MARK: - Model
public struct PictorDroneModel: PictorBaseDroneModel, Equatable {
    // MARK: Properties
    public private(set) var uuid: String

    public var cloudId: Int64
    public var serialNumber: String
    public var commonName: String
    public var modelId: String
    public var paired4G: Bool

    // MARK: Init
    init(uuid: String,
         cloudId: Int64,
         serialNumber: String,
         commonName: String,
         modelId: String,
         paired4G: Bool) {
        self.uuid = uuid
        self.cloudId = cloudId
        self.serialNumber = serialNumber
        self.commonName = commonName
        self.modelId = modelId
        self.paired4G = paired4G
    }

    internal init(record: DroneCD) {
        self.init(uuid: record.uuid,
                  cloudId: record.cloudId,
                  serialNumber: record.serialNumber ?? "",
                  commonName: record.commonName ?? "",
                  modelId: record.modelId ?? "",
                  paired4G: record.paired4G)
    }

    // MARK: Public
    public init(serialNumber: String,
                commonName: String,
                modelId: String,
                paired4G: Bool) {
        self.init(uuid: UUID().uuidString,
                  cloudId: 0,
                  serialNumber: serialNumber,
                  commonName: commonName,
                  modelId: modelId,
                  paired4G: paired4G)
    }
}
