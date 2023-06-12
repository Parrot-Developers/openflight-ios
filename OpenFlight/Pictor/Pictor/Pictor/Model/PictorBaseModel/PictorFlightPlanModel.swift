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
public protocol PictorBaseFlightPlanModel: PictorBaseModel {
    var cloudId: Int64 { get }

    var name: String { get set }
    var state: PictorFlightPlanModel.State { get set }
    var fileType: String { get set }
    var flightPlanType: String { get set }
    var mediaCount: Int { get set }
    var uploadedMediaCount: Int { get set }
    var lastMissionItemExecuted: Int { get set }
    var formatVersion: String { get set }
    var dataSetting: Data? { get set }

    var lastUpdated: Date { get set }
    var executionRank: Int? { get set }
    var hasReachedFirstWaypoint: Bool? { get set }
    var hasLatestFormatVersion: Bool { get }

    var projectUuid: String { get set }
    var projectPix4dUuid: String? { get set }

    var gutmaLinks: [PictorGutmaLinkModel] { get set }

    var thumbnail: PictorThumbnailModel? { get set }
}

// MARK: - Model
public struct PictorFlightPlanModel: PictorBaseFlightPlanModel {
    // MARK: Enum
    public enum FormatVersion {
        // Version returned by the cloud for flight plan before the addition of 'version' field.
        // This version can be handled as 'v1'.
        public static let unknown: String = "unknown"
        // The first version.
        // swiftlint:disable:next identifier_name
        public static let v1: String = "1"
        // Version `2` stores the following fields into Core Data:
        //    • hasReachedFirstWayPoint
        //    • hasReachedLastWayPoint
        //    • lastPassedWayPointIndex
        //    • percentCompleted
        // swiftlint:disable:next identifier_name
        public static let v2: String = "2"

        // Returns the latest version.
        public static let latest = v2
        // Returns the list of obsolete versions
        public static let obsoletes: [String] = [unknown, v1]
    }

    public enum State: String, CaseIterable, CustomStringConvertible {
        /// Flight Plan States Enum.
        case editable, stopped, flying, completed, uploading, processing, processed, unknown

        public init?(rawString: String?) {
            guard let rawValue = rawString else { return nil }
            self.init(rawValue: rawValue)
        }

        public var description: String {
            switch self {
            case .editable:
                return ".editable"
            case .stopped:
                return ".stopped"
            case .flying:
                return ".flying"
            case .completed:
                return ".completed"
            case .uploading:
                return ".uploading"
            case .processing:
                return ".processing"
            case .processed:
                return ".processed"
            case .unknown:
                return ".unknown"
            }
        }

        public var isExecution: Bool {
            switch self {
            case .editable,
                    .unknown:
                return false
            default:
                return true
            }
        }
    }

    // MARK: Properties
    public private(set) var uuid: String

    public var cloudId: Int64
    public var name: String
    public var state: State
    public var fileType: String
    public var flightPlanType: String
    public var mediaCount: Int
    public var uploadedMediaCount: Int
    public var lastMissionItemExecuted: Int
    public var formatVersion: String
    public var dataSetting: Data?

    public var lastUpdated: Date
    public var executionRank: Int?
    public var hasReachedFirstWaypoint: Bool?
    public var hasLatestFormatVersion: Bool {
        formatVersion == FormatVersion.latest
    }

    public var gutmaLinks: [PictorGutmaLinkModel]
    public var projectUuid: String
    public var projectPix4dUuid: String?
    public var thumbnail: PictorThumbnailModel?

    // MARK: Init
    init(uuid: String,
         cloudId: Int64,
         name: String,
         state: State,
         flightPlanType: String,
         formatVersion: String,
         lastUpdated: Date,
         fileType: String,
         dataSetting: Data?,
         mediaCount: Int,
         uploadedMediaCount: Int,
         lastMissionItemExecuted: Int,
         executionRank: Int?,
         hasReachedFirstWaypoint: Bool?,
         projectUuid: String?,
         projectPix4dUuid: String?,
         thumbnail: PictorThumbnailModel?) {
        self.uuid = uuid
        self.cloudId = cloudId
        self.name = name
        self.state = state
        self.flightPlanType = flightPlanType
        self.formatVersion = formatVersion
        self.lastUpdated = lastUpdated
        self.fileType = fileType
        self.dataSetting = dataSetting
        self.mediaCount = mediaCount
        self.uploadedMediaCount = uploadedMediaCount
        self.lastMissionItemExecuted = lastMissionItemExecuted
        self.executionRank = executionRank
        self.hasReachedFirstWaypoint = hasReachedFirstWaypoint
        self.gutmaLinks = []
        self.projectUuid = projectUuid ?? ""
        self.projectPix4dUuid = projectPix4dUuid
        self.thumbnail = thumbnail
    }

    internal init(record: FlightPlanCD,
                  thumbnail: PictorThumbnailModel?,
                  gutmaLinks: [PictorGutmaLinkModel]) {
        self.init(uuid: record.uuid,
                  cloudId: record.cloudId,
                  name: record.name ?? "",
                  state: PictorFlightPlanModel.State(rawString: record.state) ?? .unknown,
                  flightPlanType: record.flightPlanType ?? "",
                  formatVersion: record.formatVersion ?? PictorFlightPlanModel.FormatVersion.unknown,
                  lastUpdated: record.lastUpdated ?? Date(),
                  fileType: record.fileType ?? "",
                  dataSetting: record.dataSetting,
                  mediaCount: Int(record.mediaCount),
                  uploadedMediaCount: Int(record.uploadedMediaCount),
                  lastMissionItemExecuted: Int(record.lastMissionItemExecuted),
                  executionRank: record.executionRank?.intValue,
                  hasReachedFirstWaypoint: record.hasReachedFirstWaypoint?.boolValue,
                  projectUuid: record.projectUuid,
                  projectPix4dUuid: record.projectPix4dUuid,
                  thumbnail: thumbnail)
        self.gutmaLinks = gutmaLinks
    }

    // MARK: Public
    public init(name: String,
                state: State,
                flightPlanType: String,
                formatVersion: String,
                lastUpdated: Date,
                fileType: String,
                dataSetting: Data?,
                mediaCount: Int,
                uploadedMediaCount: Int,
                lastMissionItemExecuted: Int,
                executionRank: Int?,
                hasReachedFirstWaypoint: Bool?,
                projectUuid: String?,
                projectPix4dUuid: String?,
                thumbnail: PictorThumbnailModel?) {
        self.init(uuid: UUID().uuidString,
                  cloudId: 0,
                  name: name,
                  state: state,
                  flightPlanType: flightPlanType,
                  formatVersion: formatVersion,
                  lastUpdated: lastUpdated,
                  fileType: fileType,
                  dataSetting: dataSetting,
                  mediaCount: mediaCount,
                  uploadedMediaCount: uploadedMediaCount,
                  lastMissionItemExecuted: lastMissionItemExecuted,
                  executionRank: executionRank,
                  hasReachedFirstWaypoint: hasReachedFirstWaypoint,
                  projectUuid: projectUuid,
                  projectPix4dUuid: projectPix4dUuid,
                  thumbnail: thumbnail)
    }

    public func duplicate() -> PictorFlightPlanModel {
        PictorFlightPlanModel(name: name + " \(Date().timeIntervalSinceReferenceDate)",
                              state: state,
                              flightPlanType: flightPlanType,
                              formatVersion: formatVersion,
                              lastUpdated: Date(),
                              fileType: fileType,
                              dataSetting: dataSetting,
                              mediaCount: 0,
                              uploadedMediaCount: 0,
                              lastMissionItemExecuted: 0,
                              executionRank: nil,
                              hasReachedFirstWaypoint: nil,
                              projectUuid: projectUuid,
                              projectPix4dUuid: projectPix4dUuid,
                              thumbnail: thumbnail)
    }
}

// - MARK: Equatable
extension PictorFlightPlanModel: Equatable {
    public static func == (lhs: PictorFlightPlanModel, rhs: PictorFlightPlanModel) -> Bool {
        lhs.uuid == rhs.uuid
        && lhs.cloudId == rhs.cloudId
        && lhs.name == rhs.name
        && lhs.state == rhs.state
        && lhs.fileType == rhs.fileType
        && lhs.flightPlanType == rhs.flightPlanType
        && lhs.mediaCount == rhs.mediaCount
        && lhs.uploadedMediaCount == rhs.uploadedMediaCount
        && lhs.lastMissionItemExecuted == rhs.lastMissionItemExecuted
        && lhs.formatVersion == rhs.formatVersion
        && lhs.dataSetting == rhs.dataSetting
        && lhs.executionRank == rhs.executionRank
        && lhs.hasReachedFirstWaypoint == rhs.hasReachedFirstWaypoint
        && lhs.projectUuid == rhs.projectUuid
        && lhs.projectPix4dUuid == rhs.projectPix4dUuid
    }
}
