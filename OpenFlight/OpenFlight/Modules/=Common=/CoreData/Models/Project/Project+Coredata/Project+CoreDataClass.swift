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

@objc(Project)
public class Project: NSManagedObject {

    // MARK: - Constant
    /// Project's UUID key identifier used in predicates
    public static let uuidKey = "uuid"

    // MARK: - Utils
    func model() -> ProjectModel {
        var model = ProjectModel(apcId: apcId,
                            cloudId: Int(cloudId),
                            uuid: uuid,
                            title: title,
                            type: ProjectType(rawString: type) ?? .classic,
                            flightPlans: nil,
                            latestCloudModificationDate: latestCloudModificationDate,
                            lastUpdated: lastUpdated,
                            lastOpened: lastOpened,
                            latestExecutionRank: latestExecutionRank?.intValue,
                            isLocalDeleted: isLocalDeleted,
                            synchroStatus: SynchroStatus(status: synchroStatus),
                            synchroError: SynchroError(rawValue: synchroError),
                            latestSynchroStatusDate: latestSynchroStatusDate,
                            latestLocalModificationDate: latestLocalModificationDate)
        model.isProjectExecuted = hasExecutedFlightPlan()
        return model
    }

    func modelWithFlightPlan() -> ProjectModel {
        var project = model()

        var flightPlanModels: [FlightPlanModel] = []

        if let flightPlans = flightPlans {
            flightPlanModels = flightPlans
                .sorted(by: { $0.lastUpdate > $1.lastUpdate })
                .compactMap({ $0.model() })
        }

        project.flightPlans = flightPlanModels
        return project
    }

    func modelWithEditableFlightPlan() -> ProjectModel {
        var project = model()

        var flightPlanModels: [FlightPlanModel] = []

        if let flightPlans = flightPlans {
            flightPlanModels = flightPlans
                .filter { $0.state == FlightPlanModel.FlightPlanState.editable.rawValue }
                .sorted(by: { $0.lastUpdate > $1.lastUpdate })
                .compactMap({ $0.model() })
        }

        project.flightPlans = flightPlanModels
        return project
    }

    func hasExecutedFlightPlan() -> Bool {
        if let flightPlans = flightPlans {
            let flightPlan = flightPlans
                .first { $0.state != FlightPlanModel.FlightPlanState.editable.rawValue && $0.hasReachedFirstWayPoint }
            if flightPlan != nil {
                return true
            }
        }

        return false
    }

    func update(fromProjectModel projectModel: ProjectModel) {
        apcId = projectModel.apcId
        cloudId = projectModel.cloudId > 0 ? Int64(projectModel.cloudId) : cloudId
        uuid = projectModel.uuid
        title = projectModel.title
        type = projectModel.type.rawValue
        latestCloudModificationDate = projectModel.latestCloudModificationDate
        if let aLatestExecutionIndex = projectModel.latestExecutionRank {
            latestExecutionRank = NSNumber(value: aLatestExecutionIndex)
        } else {
            latestExecutionRank = nil
        }

        lastUpdated = projectModel.lastUpdated
        lastOpened = projectModel.lastOpened

        isLocalDeleted = projectModel.isLocalDeleted
        latestSynchroStatusDate = projectModel.latestSynchroStatusDate
        latestLocalModificationDate = projectModel.latestLocalModificationDate
        synchroStatus = projectModel.synchroStatus?.rawValue ?? 0
        synchroError = projectModel.synchroError?.rawValue ?? 0
    }
}
