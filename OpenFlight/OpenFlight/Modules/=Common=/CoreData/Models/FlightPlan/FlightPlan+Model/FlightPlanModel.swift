//    Copyright (C) 2021 Parrot Drones SAS
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
import ArcGIS
import CoreLocation

private extension ULogTag {
    static let tag = ULogTag(name: "FlightPlanModel")
}

public typealias FlightPlanModelVersion = FlightPlanModel.ModelVersion

public struct FlightPlanModel {
    public enum ModelVersion {
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
    // MARK: __ Constants
    private enum Constants {
        static let dateTimeIntervalDivider: TimeInterval = 1000.0
        static let progressRoundPrecision: Int = 4
    }
    // MARK: __ Private
    private var lastModified: Int

    // MARK: __ User's Id
    public var apcId: String

    // MARK: __ Academy
    public var cloudId: Int
    public var uuid: String
    public var customTitle: String
    public var lastUpdate: Date {
        get {
            return Date(timeIntervalSince1970: TimeInterval(lastModified) / Constants.dateTimeIntervalDivider)
        }
        set {
            lastModified = Int(newValue.timeIntervalSince1970 * Constants.dateTimeIntervalDivider)
        }
    }
    public var latestCloudModificationDate: Date?
    public var version: String
    public var type: String
    public var projectUuid: String
    public var thumbnailUuid: String?
    public var dataStringType: String
    public var state: FlightPlanState
    public var lastMissionItemExecuted: Int64
    public var mediaCount: Int16
    public var uploadedMediaCount: Int16

    // MARK: __ Local
    ///  dataSetting: object that saved as JSON to data base
    public var dataSetting: FlightPlanDataSetting?

    /// PGY
    public var pgyProjectId: Int64 {
        get { dataSetting?.pgyProjectId ?? 0 }
        set { dataSetting?.pgyProjectId = newValue }
    }
    public var uploadAttemptCount: Int16 {
        get { dataSetting?.uploadAttemptCount ?? 0 }
        set { dataSetting?.uploadAttemptCount = newValue }
    }
    public var lastUploadAttempt: Date? {
        get { dataSetting?.lastUploadAttempt }
        set { dataSetting?.lastUploadAttempt = newValue }
    }
    /// Identifier of first media resource captured after the drone has passed the `lastMissionItemExecuted`.
    public var recoveryResourceId: String? {
        get { dataSetting?.recoveryResourceId }
        set { dataSetting?.recoveryResourceId = newValue }
    }
    ///  parrotCloudUploadUrl: Contains S3 Upload URL of FlightPlan
    public var parrotCloudUploadUrl: String?
    public var mediaCustomId: String? // UNUSED

    // MARK: __ Execution completion state
    /// Whether the first way point has been reached.
    public var hasReachedFirstWayPoint: Bool {
        get { dataSetting?.hasReachedFirstWayPoint ?? false }
        set { dataSetting?.hasReachedFirstWayPoint = newValue }
    }
    /// Whether the last way point has been reached.
    public var hasReachedLastWayPoint: Bool {
        get { dataSetting?.hasReachedLastWayPoint ?? false }
        set { dataSetting?.hasReachedLastWayPoint = newValue }
    }
    /// Returns the last passed way point index.
    public var lastPassedWayPointIndex: Int? {
        get { dataSetting?.lastPassedWayPointIndex }
        set { dataSetting?.lastPassedWayPointIndex = newValue }
    }
    /// Returns the execution completion in percent.
    public var percentCompleted: Double {
        get { dataSetting?.percentCompleted ?? 0 }
        set { dataSetting?.percentCompleted = newValue }
    }
    public var executionRank: Int? {
        get { dataSetting?.executionRank }
        set { dataSetting?.executionRank = newValue }
    }

    public var isAMSL: Bool? {
        get { dataSetting?.isAMSL }
        set { dataSetting?.isAMSL = newValue }
    }

    // MARK: __ Relationship
    public var thumbnail: ThumbnailModel?
    public var flightPlanFlights: [FlightPlanFlightsModel]?

    // MARK: __ Synchronization
    ///  Boolean to know if it delete locally but needs to be deleted on server
    public var isLocalDeleted: Bool
    ///  Synchro status
    public var synchroStatus: SynchroStatus?
    ///  Synchro error
    public var synchroError: SynchroError?
    ///  Date of last tried synchro
    public var latestSynchroStatusDate: Date?
    ///  Date of local modification
    public var latestLocalModificationDate: Date?
    ///  Contains 0 if not yet synchronized, 1 if yes,
    ///     statusCode if an error has occured during upload
    public var fileSynchroStatus: Int16?
    ///  fileSynchroDate: Date of synchro file
    public var fileSynchroDate: Date?
    /// Mavlink
    public var mavlinkCommands: [MavlinkStandard.MavlinkCommand]? {
        // Mavlink commands is a computed property and should only be used by Run Manager.
        // All execution information (e.g. hasReachedFirstWayPoint) are updated during a run
        // and must not be recalculated each time using the mavlink commands.
        guard let data = dataSetting?.mavlinkDataFile,
              let str = String(data: data, encoding: .utf8)
        else { return nil }
        ULog.d(.tag, "Parsing mavlink file of Flight Plan: \(uuid)")
        let commands = try? MavlinkStandard.MavlinkFiles.parse(mavlinkString: str)
        return commands
    }

    // MARK: - Public init
    public init(apcId: String,
                type: String,
                uuid: String,
                version: String,
                customTitle: String,
                thumbnailUuid: String?,
                projectUuid: String,
                dataStringType: String,
                dataString: String?,
                pgyProjectId: Int64? = nil,
                state: FlightPlanState,
                lastMissionItemExecuted: Int64?,
                mediaCount: Int16?,
                uploadedMediaCount: Int16?,
                lastUpdate: Date = Date(),
                synchroStatus: SynchroStatus? = .notSync,
                fileSynchroStatus: Int16 = 0,
                fileSynchroDate: Date? = nil,
                latestSynchroStatusDate: Date? = nil,
                cloudId: Int? = 0,
                parrotCloudUploadUrl: String? = nil,
                isLocalDeleted: Bool = false,
                latestCloudModificationDate: Date? = nil,
                uploadAttemptCount: Int16? = nil,
                lastUploadAttempt: Date? = nil,
                thumbnail: ThumbnailModel?,
                flightPlanFlights: [FlightPlanFlightsModel]? = nil,
                latestLocalModificationDate: Date? = nil,
                synchroError: SynchroError? = .noError) {
        self.dataSetting = FlightPlanDataSetting.instantiate(with: dataString)
        self.apcId = apcId
        self.type = type
        self.dataStringType = dataStringType
        self.uuid = uuid
        self.version = version
        self.state = state
        self.customTitle = customTitle
        self.lastModified = Int(lastUpdate.timeIntervalSince1970 * Constants.dateTimeIntervalDivider)
        self.mediaCount = mediaCount ?? 0
        self.lastMissionItemExecuted = lastMissionItemExecuted ?? 0
        self.projectUuid = projectUuid
        self.thumbnailUuid = thumbnailUuid
        self.uploadedMediaCount = uploadedMediaCount ?? 0
        self.cloudId = cloudId ?? 0
        self.isLocalDeleted = isLocalDeleted
        self.parrotCloudUploadUrl = parrotCloudUploadUrl
        self.latestSynchroStatusDate = latestSynchroStatusDate
        self.synchroStatus = synchroStatus
        self.fileSynchroDate = fileSynchroDate
        self.fileSynchroStatus = fileSynchroStatus
        self.latestCloudModificationDate = latestCloudModificationDate
        self.thumbnail = thumbnail
        self.flightPlanFlights = flightPlanFlights
        self.latestLocalModificationDate = latestLocalModificationDate
        self.synchroError = synchroError

        // PGY properties are handled by `dataSetting`.
        // Only overwrite them if specified in parameters (when created from local data base).
        // TODO: Should not be available in parameters. Handle it during Tchouri integration.
        if let pgyProjectId = pgyProjectId {
            self.pgyProjectId = pgyProjectId
        }
        if let uploadAttemptCount = uploadAttemptCount {
            self.uploadAttemptCount = uploadAttemptCount
        }
        if let lastUploadAttempt = lastUploadAttempt {
            self.lastUploadAttempt = lastUploadAttempt
        }
    }
}

// MARK: - Custom init
extension FlightPlanModel {
    public init(apcId: String,
                uuid: String,
                type: String,
                title: String,
                state: FlightPlanState,
                projectUuid: String,
                dataSetting: FlightPlanDataSetting) {
        self.init(apcId: apcId,
                  type: type,
                  uuid: uuid,
                  version: FlightPlanModelVersion.latest,
                  customTitle: title,
                  thumbnailUuid: nil,
                  projectUuid: projectUuid,
                  dataStringType: "json",
                  dataString: dataSetting.toJSONString(),
                  state: state,
                  lastMissionItemExecuted: nil,
                  mediaCount: 0,
                  uploadedMediaCount: nil,
                  lastUpdate: Date(),
                  synchroStatus: .notSync,
                  fileSynchroStatus: 0,
                  latestSynchroStatusDate: nil,
                  cloudId: nil,
                  parrotCloudUploadUrl: nil,
                  isLocalDeleted: false,
                  latestCloudModificationDate: nil,
                  thumbnail: nil,
                  flightPlanFlights: [],
                  latestLocalModificationDate: Date(),
                  synchroError: .noError)
    }

    public init(from flightPlan: FlightPlanModel, uuid: String, state: FlightPlanState, title: String) {
        // - Reset data settings
        var dataSetting = flightPlan.dataSetting
        dataSetting?.pgyProjectId = 0
        dataSetting?.uploadAttemptCount = nil
        dataSetting?.lastUploadAttempt = nil
        dataSetting?.recoveryResourceId = nil
        dataSetting?.notPropagatedSettings = [:]
        dataSetting?.takeoffActions = []

        self.init(apcId: flightPlan.apcId,
                  type: flightPlan.type,
                  uuid: uuid,
                  version: flightPlan.version,
                  customTitle: title,
                  thumbnailUuid: nil,
                  projectUuid: flightPlan.projectUuid,
                  dataStringType: flightPlan.dataStringType,
                  dataString: dataSetting?.toJSONString(),
                  state: state,
                  lastMissionItemExecuted: 0,
                  mediaCount: 0,
                  uploadedMediaCount: 0,
                  lastUpdate: Date(),
                  synchroStatus: .notSync,
                  fileSynchroStatus: 0,
                  fileSynchroDate: nil,
                  latestSynchroStatusDate: nil,
                  cloudId: 0,
                  parrotCloudUploadUrl: nil,
                  isLocalDeleted: false,
                  latestCloudModificationDate: nil,
                  thumbnail: nil,
                  flightPlanFlights: [],
                  latestLocalModificationDate: Date(),
                  synchroError: .noError)

        if let fpThumbnail = flightPlan.thumbnail {
            var fpThumbnail = fpThumbnail
            fpThumbnail.uuid = UUID().uuidString
            fpThumbnail.flightUuid = nil
            thumbnailUuid = fpThumbnail.uuid
            thumbnail = fpThumbnail
        }
    }
}

extension FlightPlanModel {
    public enum FlightPlanState: String, CaseIterable, CustomStringConvertible {

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

    /// Returns formatted date.
    /// - Returns: formatted execution date or dash if formatting failed
    public func formattedDate() -> String {
        let formattedDate = self.flightPlanFlights?.first?.dateExecutionFlight.commonFormattedString
        return formattedDate ?? L10n.flightPlanHistoryExecutionNotSynchronized
    }

    /// Tells if flight Plan should be cleared.
    public func shouldClearFlightPlan() -> Bool {
        return self.dataSetting?.wayPoints.isEmpty == false ||
            self.dataSetting?.pois.isEmpty == false
    }

    public var lastFlightDate: Date? {
        flightPlanFlights?.compactMap { $0.ofFlight?.startTime }.max()
    }
}

// MARK: - `FlightPlanModel` helpers
extension FlightPlanModel {
    var points: [CLLocationCoordinate2D] {
        dataSetting?.wayPoints.compactMap({ $0.coordinate }) ?? []
    }

    var center: CLLocationCoordinate2D? {
        let points = self.points
        guard !points.isEmpty else { return nil }
        var lat = 0.0
        var lng = 0.0
        for point in points {
            lat += point.latitude
            lng += point.longitude
        }
        return CLLocationCoordinate2D(latitude: lat / Double(points.count), longitude: lng / Double(points.count))
    }

    var isEmpty: Bool {
        return self.dataSetting?.polygonPoints.isEmpty == true && points.isEmpty
    }

    var lastFlightExecutionDate: Date? {
        return self.flightPlanFlights?.compactMap { $0.dateExecutionFlight }.max()
    }

    /// Update the Flight Plan's Cloud State.
    ///
    /// - Parameter flightPlan: the flight plan with updated cloud state
    mutating func updateCloudState(with flightPlan: FlightPlanModel) {
        // Ensure it's the correct FP.
        guard uuid == flightPlan.uuid else { return }
        // Ensure to have a valid CloudID before overwriting it.
        cloudId = flightPlan.cloudId > 0 ? flightPlan.cloudId : cloudId
        latestCloudModificationDate = flightPlan.latestCloudModificationDate
        synchroError = flightPlan.synchroError
        synchroStatus = flightPlan.synchroStatus
        latestSynchroStatusDate = flightPlan.latestSynchroStatusDate
        latestLocalModificationDate = flightPlan.latestLocalModificationDate
    }

    // MARK: Edition mode
    /// Indicates if a Flight Plan has the same settings than the one passed in parameters.
    ///
    /// - Parameters:
    ///  - flightPlan: The flight plan to compare.
    ///
    /// - Returns: `true` if settings (Custom Title and Data Settings) are identicals, `false` in other cases.
    func hasSameSettings(than flightPlan: FlightPlanModel) -> Bool {
        // Checking title.
        guard customTitle == flightPlan.customTitle else { return false }
        // Checking Data Settings.
        return dataSetting == flightPlan.dataSetting
    }

    /// Whether the Flight Plan has been created from an imported Mavlink.
    ///
    /// - Description: The current implementation uses the flight plan `DataSetting`'s `readOnly` field
    ///                to indicate if it has been created by a Mavlink import (when `readOnly` = `true`).
    var hasImportedMavlink: Bool { dataSetting?.readOnly == true }
}

// MARK: - Model Versioning
extension FlightPlanModel {
    mutating public func updateToLatestVersionIfNeeded() {
        guard version != FlightPlanModelVersion.latest else {
            ULog.d(.tag, "Flight plan has latest version: \(FlightPlanModelVersion.latest)")
            return
        }

        // - Update to latest version considered by FlightPlanModelVersion.latest
        // The process is to update version by version, unknown/v1 > v2 > v3 and so on, until the latestVersion
        if FlightPlanModelVersion.obsoletes.contains(where: { $0 == version }) {
            // - Update 'unknown' or 'v1' to 'v2'
            updateVersionToV2()

            // - Update to the latest version
            version = FlightPlanModelVersion.latest
        }
    }

    mutating private func updateVersionToV2() {
        guard version == FlightPlanModelVersion.unknown || version == FlightPlanModelVersion.v1 else {
            ULog.d(.tag, "Flight plan version update to V2 not required")
            return
        }
        if let commands = mavlinkCommands {
            ULog.i(.tag, "Update completion state from mavlink for FP: '\(uuid)'")
            let itemExecuted = Int(lastMissionItemExecuted)
            hasReachedFirstWayPoint = commands.hasReachedFirstWayPoint(index: itemExecuted)
            hasReachedLastWayPoint = commands.hasReachedLastWayPoint(index: itemExecuted)
            lastPassedWayPointIndex = commands.lastPassedWayPointIndex(for: itemExecuted)
            let progress = commands.percentCompleted(for: itemExecuted, flightPlan: self)
            percentCompleted = progress
        } else {
            ULog.e(.tag, "Cannot update completion state without mavlink commands for FP: \(uuid)")
            hasReachedFirstWayPoint = false
            hasReachedLastWayPoint = false
            lastPassedWayPointIndex = nil
            percentCompleted = 0
        }

        version = FlightPlanModelVersion.v2
    }
}

/// Extension for Equatable conformance.
extension FlightPlanModel: Equatable {
    public static func == (lhs: FlightPlanModel, rhs: FlightPlanModel) -> Bool {
        lhs.apcId == rhs.apcId
        && lhs.type == rhs.type
        && lhs.uuid == rhs.uuid
        && lhs.version == rhs.version
        && lhs.customTitle == rhs.customTitle
        && lhs.thumbnailUuid == rhs.thumbnailUuid
        && lhs.projectUuid == rhs.projectUuid
        && lhs.dataStringType == rhs.dataStringType
        && lhs.dataSetting == rhs.dataSetting
        && lhs.pgyProjectId == rhs.pgyProjectId
        && lhs.state == rhs.state
        && lhs.lastMissionItemExecuted == rhs.lastMissionItemExecuted
        && lhs.mediaCount == rhs.mediaCount
        && lhs.uploadedMediaCount == rhs.uploadedMediaCount
        && lhs.lastUpdate == rhs.lastUpdate
        && lhs.synchroStatus == rhs.synchroStatus
        && lhs.fileSynchroStatus == rhs.fileSynchroStatus
        && lhs.fileSynchroDate == rhs.fileSynchroDate
        && lhs.latestSynchroStatusDate == rhs.latestSynchroStatusDate
        && lhs.cloudId == rhs.cloudId
        && lhs.parrotCloudUploadUrl == rhs.parrotCloudUploadUrl
        && lhs.isLocalDeleted == rhs.isLocalDeleted
        && lhs.latestCloudModificationDate == rhs.latestCloudModificationDate
        && lhs.uploadAttemptCount == rhs.uploadAttemptCount
        && lhs.lastUploadAttempt == rhs.lastUploadAttempt
        && lhs.thumbnail == rhs.thumbnail
        && lhs.flightPlanFlights == rhs.flightPlanFlights
        && lhs.latestLocalModificationDate == rhs.latestLocalModificationDate
        && lhs.synchroError == rhs.synchroError
    }
}
