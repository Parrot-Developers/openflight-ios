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
import CoreData

@objc(FlightPlan)
public class FlightPlan: NSManagedObject {

    // MARK: - Utils
    /// Return FlightPlanModel from FlightPlan type of NSManagedObject
    func model() -> FlightPlanModel {
        var flightPlanSettings: String?
        if let dataString = dataString {
            flightPlanSettings = String(decoding: dataString, as: UTF8.self)
        }
        return FlightPlanModel(apcId: apcId,
                               type: type,
                               uuid: uuid,
                               version: version,
                               customTitle: customTitle,
                               thumbnailUuid: thumbnailUuid,
                               projectUuid: projectUuid,
                               dataStringType: dataStringType,
                               dataString: flightPlanSettings,
                               pgyProjectId: pgyProjectId,
                               state: FlightPlanModel.FlightPlanState(rawString: state) ?? .editable,
                               lastMissionItemExecuted: lastMissionItemExecuted,
                               mediaCount: mediaCount,
                               uploadedMediaCount: uploadedMediaCount,
                               lastUpdate: lastUpdate,
                               synchroStatus: SynchroStatus(status: synchroStatus),
                               fileSynchroStatus: fileSynchroStatus,
                               fileSynchroDate: fileSynchroDate,
                               latestSynchroStatusDate: latestSynchroStatusDate,
                               cloudId: Int(cloudId),
                               parrotCloudUploadUrl: parrotCloudUploadUrl,
                               isLocalDeleted: isLocalDeleted,
                               latestCloudModificationDate: latestCloudModificationDate,
                               uploadAttemptCount: uploadAttemptCount,
                               lastUploadAttempt: lastUploadAttempt,
                               thumbnail: thumbnail?.model(),
                               flightPlanFlights: flightPlanFlights?.toArray().map({ $0.model() }),
                               latestLocalModificationDate: latestLocalModificationDate,
                               synchroError: SynchroError(error: synchroError))
    }

    func modelWithFlightPlanFlights() -> FlightPlanModel {
        var modelResult = model()
        modelResult.flightPlanFlights = flightPlanFlights?.toArray().map({ $0.modelWithFlightAndFlightPlan() })
        return modelResult
    }

    func update(fromFlightPlanModel flightPlanModel: FlightPlanModel, withProject: Project?, withThumbnail: Thumbnail?) {
        apcId = flightPlanModel.apcId
        type = flightPlanModel.type
        cloudId = flightPlanModel.cloudId > 0 ? Int64(flightPlanModel.cloudId) : cloudId
        isLocalDeleted = flightPlanModel.isLocalDeleted
        parrotCloudUploadUrl = flightPlanModel.parrotCloudUploadUrl
        projectUuid = flightPlanModel.projectUuid
        latestSynchroStatusDate = flightPlanModel.latestSynchroStatusDate
        fileSynchroDate = flightPlanModel.fileSynchroDate
        dataStringType = flightPlanModel.dataStringType
        uuid = flightPlanModel.uuid
        version = flightPlanModel.version
        customTitle = flightPlanModel.customTitle
        thumbnailUuid = flightPlanModel.thumbnailUuid
        pgyProjectId = flightPlanModel.pgyProjectId
        dataString = flightPlanModel.dataSetting?.asData
        state = flightPlanModel.state.rawValue
        lastMissionItemExecuted = flightPlanModel.lastMissionItemExecuted
        mediaCount = flightPlanModel.mediaCount
        uploadedMediaCount = flightPlanModel.uploadedMediaCount
        lastUpdate = flightPlanModel.lastUpdate

        hasReachedFirstWayPoint = flightPlanModel.hasReachedFirstWayPoint
        hasReachedLastWayPoint = flightPlanModel.hasReachedLastWayPoint
        if let lastPassedWayPointIndexSetting = flightPlanModel.lastPassedWayPointIndex {
            lastPassedWayPointIndex = NSNumber(value: lastPassedWayPointIndexSetting)
        } else {
            lastPassedWayPointIndex = nil
        }
        percentCompleted = flightPlanModel.percentCompleted
        if let anExecutionRank = flightPlanModel.executionRank {
            executionRank = NSNumber(value: anExecutionRank)
        } else {
            executionRank = nil
        }

        latestCloudModificationDate = flightPlanModel.latestCloudModificationDate
        lastUploadAttempt = flightPlanModel.lastUploadAttempt
        uploadAttemptCount = flightPlanModel.uploadAttemptCount
        latestLocalModificationDate = flightPlanModel.latestLocalModificationDate
        synchroStatus = flightPlanModel.synchroStatus?.rawValue ?? 0
        synchroError = flightPlanModel.synchroError?.rawValue ?? 0
        fileSynchroStatus = flightPlanModel.fileSynchroStatus ?? 0

        if let withProject = withProject {
            ofProject = withProject
        }

        thumbnail = withThumbnail
        thumbnailUuid = withThumbnail?.uuid
    }
}
