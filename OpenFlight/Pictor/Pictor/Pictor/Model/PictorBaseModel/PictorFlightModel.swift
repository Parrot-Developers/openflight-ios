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
public protocol PictorBaseFlightModel: PictorBaseModel {
    var cloudId: Int64 { get }
    var formatVersion: String { get set }
    var title: String { get set }
    var parseError: Bool { get set }
    var runDate: Date? { get set }
    var serial: String { get set }
    var firmware: String { get set }
    var modelId: String { get set }
    var gutmaFile: Data? { get set }
    var photoCount: Int16  { get set }
    var videoCount: Int16  { get set }
    var startLatitude: Double  { get set }
    var startLongitude: Double  { get set }
    var batteryConsumption: Int16  { get set }
    var distance: Double  { get set }
    var duration: Double  { get set }
    var thumbnail: PictorThumbnailModel? { get set }
}

// MARK: - Model
public struct PictorFlightModel: PictorBaseFlightModel {
    // MARK: Properties
    public private(set) var uuid: String

    public var cloudId: Int64
    public var formatVersion: String
    public var title: String
    public var parseError: Bool
    public var runDate: Date?
    public var serial: String
    public var firmware: String
    public var modelId: String
    public var gutmaFile: Data?

    public var photoCount: Int16
    public var videoCount: Int16
    public var startLatitude: Double
    public var startLongitude: Double
    public var batteryConsumption: Int16
    public var distance: Double
    public var duration: Double
    public var thumbnail: PictorThumbnailModel?

    // MARK: Init
    init(uuid: String,
         cloudId: Int64,
         formatVersion: String,
         title: String,
         parseError: Bool,
         runDate: Date?,
         serial: String,
         firmware: String,
         modelId: String,
         gutmaFile: Data?,
         photoCount: Int16,
         videoCount: Int16,
         startLatitude: Double,
         startLongitude: Double,
         batteryConsumption: Int16,
         distance: Double,
         duration: Double,
         thumbnail: PictorThumbnailModel?) {
        self.uuid = uuid
        self.cloudId = cloudId
        self.formatVersion = formatVersion
        self.title = title
        self.parseError = parseError
        self.runDate = runDate
        self.serial = serial
        self.firmware = firmware
        self.modelId = modelId
        self.gutmaFile = gutmaFile
        self.photoCount = photoCount
        self.videoCount = videoCount
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        self.batteryConsumption = batteryConsumption
        self.distance = distance
        self.duration = duration
        self.thumbnail = thumbnail
    }

    // MARK: Public
    public init(formatVersion: String,
                title: String,
                parseError: Bool,
                runDate: Date?,
                serial: String,
                firmware: String,
                modelId: String,
                gutmaFile: Data?,
                photoCount: Int16,
                videoCount: Int16,
                startLatitude: Double,
                startLongitude: Double,
                batteryConsumption: Int16,
                distance: Double,
                duration: Double,
                thumbnail: PictorThumbnailModel?) {
        self.init(uuid: UUID().uuidString,
                  cloudId: 0,
                  formatVersion: formatVersion,
                  title: title,
                  parseError: parseError,
                  runDate: runDate,
                  serial: serial,
                  firmware: firmware,
                  modelId: modelId,
                  gutmaFile: gutmaFile,
                  photoCount: photoCount,
                  videoCount: videoCount,
                  startLatitude: startLatitude,
                  startLongitude: startLongitude,
                  batteryConsumption: batteryConsumption,
                  distance: distance,
                  duration: duration,
                  thumbnail: thumbnail)
    }

    internal init(record: FlightCD, thumbnail: PictorThumbnailModel?) {
        self.init(uuid: record.uuid,
                  cloudId: record.cloudId,
                  formatVersion: record.formatVersion ?? "",
                  title: record.title ?? "",
                  parseError: record.parseError,
                  runDate: record.runDate,
                  serial: record.serial ?? "",
                  firmware: record.firmware ?? "",
                  modelId: record.modelId ?? "",
                  gutmaFile: record.gutmaFile,
                  photoCount: record.photoCount,
                  videoCount: record.videoCount,
                  startLatitude: record.startLatitude,
                  startLongitude: record.startLongitude,
                  batteryConsumption: record.batteryConsumption,
                  distance: record.distance,
                  duration: record.duration,
                  thumbnail: thumbnail)
    }
}

// - MARK: Equatable
extension PictorFlightModel: Equatable {
    public static func == (lhs: PictorFlightModel, rhs: PictorFlightModel) -> Bool {
        lhs.uuid == rhs.uuid
        && lhs.cloudId == rhs.cloudId
        && lhs.formatVersion == rhs.formatVersion
        && lhs.title == rhs.title
        && lhs.parseError == rhs.parseError
        && lhs.runDate == rhs.runDate
        && lhs.serial == rhs.serial
        && lhs.firmware == rhs.firmware
        && lhs.modelId == rhs.modelId
        && lhs.gutmaFile == rhs.gutmaFile
        && lhs.photoCount == rhs.photoCount
        && lhs.videoCount == rhs.videoCount
        && lhs.startLatitude == rhs.startLatitude
        && lhs.startLongitude == rhs.startLongitude
        && lhs.batteryConsumption == rhs.batteryConsumption
        && lhs.distance == rhs.distance
        && lhs.duration == rhs.duration
    }
}
