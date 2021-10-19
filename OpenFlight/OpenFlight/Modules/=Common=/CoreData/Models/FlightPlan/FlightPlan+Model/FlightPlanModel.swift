// Copyright (C) 2021 Parrot Drones SAS
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

public struct FlightPlanModel {

    // MARK: Constants
    private enum Constants {
        static let dateTimeIntervalDivider: TimeInterval = 1000.0
    }
    // MARK: - Properties

    public var type: String
    public var uuid: String
    public var customTitle: String
    public var thumbnailUuid: String?
    public var projectUuid: String
    public var dataStringType: String
    public var version: String
    public var pgyProjectId: Int64
    public var mediaCustomId: String?
    public var state: FlightPlanState
    public var lastMissionItemExecuted: Int64
    public var mediaCount: Int16
    public var uploadedMediaCount: Int16
    public var uploadAttemptCount: Int16
    public var lastUploadAttempt: Date?

    private var lastModified: Int
    // MARK: - Synchro Properties

    /// - To identify data user
    public var apcId: String

    /// - lastUpdated: Last modification date
    public var lastUpdate: Date {
        get {
            return Date(timeIntervalSince1970: TimeInterval(lastModified) / Constants.dateTimeIntervalDivider)
        }
        set {
            lastModified = Int(newValue.timeIntervalSince1970 * Constants.dateTimeIntervalDivider)
        }
    }

    /// - dataSetting: object that saved as JSON to data base
    public var dataSetting: FlightPlanDataSetting?

    /// - Id of FlightPlan on server: Set only if synchronized
    public var parrotCloudId: Int64

    /// - Set True if a Delete Request was triguerred without success
    public var parrotCloudToBeDeleted: Bool

    /// - Contains the Date of last synchro trying if is not succeeded
    public var synchroDate: Date?

    /// - Contains 0 if not yet synchronized, 1 if yes
        /// statusCode if sync failed
    public var synchroStatus: Int16?

    /// - Contains 0 if not yet synchronized, 1 if yes,
    ///     statusCode if an error has occured during upload
    public var fileSynchroStatus: Int16?

    /// - fileSynchroDate: Date of synchro file
    public var fileSynchroDate: Date?

    /// - parrotCloudUploadUrl: Contains S3 Upload URL of FlightPlan
    public var parrotCloudUploadUrl: String?

    /// - Last modification date of FlightPlan
    public var cloudLastUpdate: Date?

    /// - Type of flight plan
    public var flightPlanType: FlightPlanType?

    // MARK: - Relationship

    public var thumbnail: ThumbnailModel?

    public var flightPlanFlights: [FlightPlanFlightsModel]?

    /// - Return dataString data type
    public var dataStringData: Data? {
        return dataSetting?.asData
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
                pgyProjectId: Int64?,
                mediaCustomId: String?,
                state: FlightPlanState,
                lastMissionItemExecuted: Int64?,
                mediaCount: Int16?,
                uploadedMediaCount: Int16?,
                lastUpdate: Date = Date(),
                synchroStatus: Int16 = 0,
                fileSynchroStatus: Int16 = 0,
                fileSynchroDate: Date? = nil,
                synchroDate: Date? = nil,
                parrotCloudId: Int64? = 0,
                parrotCloudUploadUrl: String? = nil,
                parrotCloudToBeDeleted: Bool = false,
                cloudLastUpdate: Date? = nil,
                uploadAttemptCount: Int16? = 0,
                lastUploadAttempt: Date? = nil,
                thumbnail: ThumbnailModel?,
                flightPlanFlights: [FlightPlanFlightsModel]? = nil) {

        self.apcId = apcId
        self.type = type
        self.dataStringType = dataStringType
        self.uuid = uuid
        self.version = version
        self.state = state
        self.customTitle = customTitle
        self.lastModified = Int(lastUpdate.timeIntervalSince1970 * Constants.dateTimeIntervalDivider)
        self.mediaCount = mediaCount ?? 0
        self.dataSetting = FlightPlanDataSetting.instantiate(with: dataString)
        self.mediaCustomId = mediaCustomId
        self.lastMissionItemExecuted = lastMissionItemExecuted ?? -1
        self.projectUuid = projectUuid
        self.thumbnailUuid = thumbnailUuid
        self.pgyProjectId = pgyProjectId ?? 0
        self.uploadedMediaCount = uploadedMediaCount ?? 0
        self.parrotCloudId = parrotCloudId ?? 0
        self.parrotCloudToBeDeleted = parrotCloudToBeDeleted
        self.parrotCloudUploadUrl = parrotCloudUploadUrl
        self.synchroDate = synchroDate
        self.synchroStatus = synchroStatus
        self.fileSynchroDate = fileSynchroDate
        self.fileSynchroStatus = fileSynchroStatus
        self.cloudLastUpdate = cloudLastUpdate
        self.uploadAttemptCount = uploadAttemptCount ?? 0
        self.lastUploadAttempt = lastUploadAttempt
        self.thumbnail = thumbnail
        self.flightPlanFlights = flightPlanFlights
    }

    /// Update the polygon points for the current flight plan.
    ///
    /// - Parameters:
    ///     - points: Polygon points
    public func updatePolygonPoints(points: [AGSPoint]) {
        let polygonPoints: [PolygonPoint] = points.map({
            return PolygonPoint(coordinate: $0.toCLLocationCoordinate2D())
        })

        self.dataSetting?.polygonPoints = polygonPoints
    }
}

extension FlightPlanModel {
    public enum FlightPlanState: String, CaseIterable {

        /// Flight Plan States Enum.
        case editable, stopped, flying, completed, uploading, processing, processed, unknown

        public init?(rawString: String?) {
            guard let rawValue = rawString else { return nil }
            self.init(rawValue: rawValue)
        }
    }

    /// Returns fomatted date.
    ///
    /// - Parameters:
    ///     - isShort: result string should be short
    /// - Returns: fomatted execution date or dash if formatting failed.
    public func fomattedDate(isShort: Bool) -> String {
        let fomattedDate = isShort ?
            self.flightPlanFlights?.first?.dateExecutionFlight.shortFormattedString :
            self.flightPlanFlights?.first?.dateExecutionFlight.shortWithTimeFormattedString
        return fomattedDate ?? Style.dash
    }

    /// Returns fomatted execution date.
    ///
    /// - Parameters:
    ///     - isShort: result string should be short
    /// - Returns: fomatted execution date or dash if formatting failed.
    func fomattedExecutionDate(isShort: Bool) -> String {
        // TODO start date ?? 
        let fomattedDate = isShort ? self.lastUpdate.shortFormattedString : self.lastUpdate.shortWithTimeFormattedString
        return fomattedDate ?? Style.dash
    }

    /// Tells if flight Plan should be cleared.
    public func shouldClearFlightPlan() -> Bool {
        return self.dataSetting?.wayPoints.isEmpty == false ||
            self.dataSetting?.pois.isEmpty == false
    }
}

// MARK: - `FlightPlanModel` helpers
extension FlightPlanModel {
    var shouldRequestThumbnail: Bool {
        return true
    }

    var shouldRequestPlacemark: Bool {
        return true
    }

    var points: [CLLocationCoordinate2D] {
        dataSetting?.wayPoints.compactMap({ $0.coordinate }) ?? []
    }

    var isEmpty: Bool {
        return self.dataSetting?.polygonPoints.isEmpty == true && points.isEmpty
    }

    var hasReachedFirstWayPoint: Bool {
        guard let commands = dataSetting?.mavlinkCommands else { return lastMissionItemExecuted > 0 }
        guard let firstWayPointIndex = commands.firstIndex(where: { $0 is MavlinkStandard.NavigateToWaypointCommand })
        else { return false }
        return lastMissionItemExecuted >= firstWayPointIndex
    }

    var hasReachedLastWayPoint: Bool {
        guard let commands = dataSetting?.mavlinkCommands,
              let lastWayPointIndex = commands.lastIndex(where: { $0 is MavlinkStandard.NavigateToWaypointCommand })
        else { return false }
        return lastMissionItemExecuted >= lastWayPointIndex
    }

    var percentCompleted: Double {
        guard let commands = dataSetting?.mavlinkCommands else { return 0 }
        return Double(lastMissionItemExecuted) / Double(commands.count) * 100
    }

    var lastFlightExecutionDate: Date? {
        return self.flightPlanFlights?.compactMap { $0.dateExecutionFlight }.max()
    }
}
