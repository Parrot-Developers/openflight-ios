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
import Pictor

private extension ULogTag {
    static let tag = ULogTag(name: "FlightPlanModel")
}

public typealias FlightPlanModelVersion = PictorFlightPlanModel.FormatVersion
public typealias FlightPlanState = PictorFlightPlanModel.State

// - Easy init for FlightPlanModel
public extension PictorFlightPlanModel {
    var flightPlanModel: FlightPlanModel {
        FlightPlanModel(pictorModel: self)
    }

    var lastFlightExecutionDate: Date? {
        gutmaLinks.compactMap { $0.executionDate }.max()
    }
}

public struct FlightPlanModel: Equatable {
    // MARK: Properties
    public var uuid: String { pictorModel.uuid }
    public var pictorModel: PictorFlightPlanModel
    public var dataSetting: FlightPlanDataSetting? {
        // Check if change of property trigger didSet
        didSet {
            updatePictorFromDataSetting()
        }
    }

    // MARK: Init
    init(pictorModel: PictorFlightPlanModel) {
        self.pictorModel = pictorModel

        // - create dataSetting
        if let pictorDataSetting = self.pictorModel.dataSetting {
            let dataSettingStr = String(decoding: pictorDataSetting, as: UTF8.self)
            dataSetting = FlightPlanDataSetting.instantiate(with: dataSettingStr)
        } else {
            dataSetting = FlightPlanDataSetting(captureMode: FlightPlanCaptureMode.defaultValue)
        }

        updatePictorFromDataSetting()
    }

    static func new(from flightPlanModel: FlightPlanModel) -> FlightPlanModel {
        var flightPlanDataSetting: FlightPlanDataSetting?
        if let aFlightPlanDataSetting = flightPlanModel.dataSetting {
            flightPlanDataSetting = aFlightPlanDataSetting
            flightPlanDataSetting?.notPropagatedSettings = [:]
            flightPlanDataSetting?.pgyProjectId = 0
        }

        var pictorThumbnail: PictorThumbnailModel?
        if let thumbnail = flightPlanModel.pictorModel.thumbnail {
            pictorThumbnail = PictorThumbnailModel(image: thumbnail.image)
        }

        let pictorModel = PictorFlightPlanModel(name: flightPlanModel.pictorModel.name,
                                                state: .editable,
                                                flightPlanType: flightPlanModel.pictorModel.flightPlanType,
                                                formatVersion: flightPlanModel.pictorModel.formatVersion,
                                                lastUpdated: Date(),
                                                fileType: flightPlanModel.pictorModel.fileType,
                                                dataSetting: flightPlanDataSetting?.asData,
                                                mediaCount: 0,
                                                uploadedMediaCount: 0,
                                                lastMissionItemExecuted: 0,
                                                executionRank: nil,
                                                hasReachedFirstWaypoint: flightPlanDataSetting?.hasReachedFirstWayPoint,
                                                projectUuid: flightPlanModel.pictorModel.projectUuid,
                                                projectPix4dUuid: nil,
                                                thumbnail: pictorThumbnail)

        return FlightPlanModel(pictorModel: pictorModel)
    }

    // MARK: Internal
    mutating internal func updatePictorFromDataSetting() {
        guard let dataSetting = dataSetting else {
            pictorModel.dataSetting = nil
            pictorModel.projectPix4dUuid = nil
            pictorModel.executionRank = nil
            pictorModel.hasReachedFirstWaypoint = nil
            return
        }
        pictorModel.dataSetting = dataSetting.asData

        if let projectPix4dUuid = dataSetting.pgyProjectId {
            pictorModel.projectPix4dUuid = "\(projectPix4dUuid)"
        } else {
            pictorModel.projectPix4dUuid = nil
        }

        pictorModel.executionRank = dataSetting.executionRank

        pictorModel.hasReachedFirstWaypoint = dataSetting.hasReachedFirstWayPoint
    }

    // MARK: Data setting properties
    // MARK: Project Pix4D related
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

    // MARK: Execution state
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

    public var mavlinkCommands: [MavlinkStandard.MavlinkCommand]? {
        // Mavlink commands is a computed property and should only be used by Run Manager.
        // All execution information (e.g. hasReachedFirstWayPoint) are updated during a run
        // and must not be recalculated each time using the mavlink commands.
        guard let data = dataSetting?.mavlinkDataFile,
              let str = String(data: data, encoding: .utf8)
        else { return nil }
        ULog.i(.tag, "Parsing mavlink file of Flight Plan: \(pictorModel.uuid)")
        let commands = try? MavlinkStandard.MavlinkFiles.parse(mavlinkString: str)
        return commands
    }

    /// Tells if flight Plan should be cleared.
    public func shouldClearFlightPlan() -> Bool {
        return dataSetting?.wayPoints.isEmpty == false ||
        dataSetting?.pois.isEmpty == false
    }

    public var lastFlightDate: Date? {
        guard !pictorModel.gutmaLinks.isEmpty else {
            return nil
        }
        return pictorModel.gutmaLinks.map { $0.executionDate }.max()
    }

    // MARK: Helpers
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

    mutating func updateCloudIdIfNeeded(from pictorFlightPlanModel: PictorFlightPlanModel) {
        guard uuid == pictorFlightPlanModel.uuid,
              pictorModel.cloudId == 0 else {
            return
        }
        pictorModel.cloudId = pictorFlightPlanModel.cloudId
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
        guard pictorModel.name == flightPlan.pictorModel.name else { return false }
        // Checking Data Settings.
        return dataSetting == flightPlan.dataSetting
    }

    /// Whether the Flight Plan has been created from an imported Mavlink.
    ///
    /// - Description: The current implementation uses the flight plan `DataSetting`'s `readOnly` field
    ///                to indicate if it has been created by a Mavlink import (when `readOnly` = `true`).
    var hasImportedMavlink: Bool { dataSetting?.readOnly == true }

    // MARK: Versionning
    mutating public func updateToLatestVersionIfNeeded() {
        guard pictorModel.formatVersion != FlightPlanModelVersion.latest else {
            ULog.i(.tag, "Flight plan has latest version: \(FlightPlanModelVersion.latest)")
            return
        }

        // - Update to latest version considered by FlightPlanModelVersion.latest
        // The process is to update version by version, unknown/v1 > v2 > v3 and so on, until the latestVersion
        guard FlightPlanModelVersion.obsoletes.contains(where: { $0 == pictorModel.formatVersion }) else {
            ULog.i(.tag, "Flight plan has unknown formatVersion to be updated: \(pictorModel.formatVersion)")
            return
        }
        // - Update 'unknown' or 'v1' to 'v2'
        updateVersionToV2()

        // - Update to the latest version
        pictorModel.formatVersion = FlightPlanModelVersion.latest

        // - Update pictor model
        updatePictorFromDataSetting()
    }

    mutating private func updateVersionToV2() {
        guard pictorModel.formatVersion == FlightPlanModelVersion.unknown || pictorModel.formatVersion == FlightPlanModelVersion.v1 else {
            ULog.i(.tag, "Flight plan version update to V2 not required")
            return
        }
        if let commands = mavlinkCommands {
            ULog.i(.tag, "Update completion state from mavlink for FP: '\(pictorModel.uuid)'")
            let itemExecuted = Int(pictorModel.lastMissionItemExecuted)
            hasReachedFirstWayPoint = commands.hasReachedFirstWayPoint(index: itemExecuted)
            hasReachedLastWayPoint = commands.hasReachedLastWayPoint(index: itemExecuted)
            lastPassedWayPointIndex = commands.lastPassedWayPointIndex(for: itemExecuted)

            let progress: Double = commands.percentCompleted(for: itemExecuted, flightPlan: self)
            percentCompleted = progress
        } else {
            ULog.e(.tag, "Cannot update completion state without mavlink commands for FP: \(pictorModel.uuid)")
            hasReachedFirstWayPoint = false
            hasReachedLastWayPoint = false
            lastPassedWayPointIndex = nil
            percentCompleted = 0
        }

        pictorModel.formatVersion = FlightPlanModelVersion.v2
    }
}
