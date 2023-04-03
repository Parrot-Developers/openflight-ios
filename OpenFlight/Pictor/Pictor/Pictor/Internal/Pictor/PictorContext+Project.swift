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
import CoreData

fileprivate extension String {
    static let tag = "pictor.context.project"
}

internal extension PictorContext {
    func createProjects<T: PictorBaseModel>(_ models: [T]) {
        updateProjects(models, forceSave: true, local: false)
    }

    func updateProjects<T: PictorBaseModel>(_ models: [T]) {
        updateProjects(models, forceSave: false, local: false)
    }

    func createProjects<T: PictorBaseModel>(_ models: [T], local: Bool) {
        updateProjects(models, forceSave: true, local: local)
    }

    func updateProjects<T: PictorBaseModel>(_ models: [T], local: Bool) {
        updateProjects(models, forceSave: false, local: local)
    }

    func deleteProjects<T: PictorBaseModel>(_ models: [T]) {
        guard T.self is PictorBaseProjectModel.Type || T.self is PictorEngineBaseProjectModel.Type else { return }

        currentChildContext.performAndWait { [weak self] in
            guard let self = self else { return }
            do {
                // - Get existin records
                let modelsUuids: [String] = models.compactMap { $0.uuid }
                var uuidsMarkAsDeleted: [String] = []
                let fetchRequest = ProjectCD.fetchRequest()
                let uuidPredicate = NSPredicate(format: "uuid IN %@", modelsUuids)
                fetchRequest.predicate = uuidPredicate
                let existingCDs = try self.currentChildContext.fetch(fetchRequest)

                // - Handle records
                let currentDate = Date()
                for existingCD in existingCDs {
                    var cloudId = existingCD.cloudId

                    // - If model has cloudId to 0, it is considered to be deleted locally regardless of the record's cloudId
                    if let model = models.first(where: { $0.uuid == existingCD.uuid }) as? PictorBaseProjectModel,
                       model.cloudId == 0 {
                        cloudId = 0
                    }
                    if let engineModel = models.first(where: { $0.uuid == existingCD.uuid }) as? PictorEngineBaseProjectModel,
                       engineModel.projectModel.cloudId == 0 {
                        cloudId = 0
                    }

                    if cloudId != 0 {
                        existingCD.localModificationDate = currentDate
                        existingCD.synchroLatestUpdatedDate = currentDate
                        existingCD.synchroIsDeleted = true
                        uuidsMarkAsDeleted.append(existingCD.uuid)

                    } else {
                        self.currentChildContext.delete(existingCD)
                    }
                }

                if !uuidsMarkAsDeleted.isEmpty {
                    self.coreDataService.sendEventMarkAsDeleted(entityName: ProjectCD.entityName,
                                                                uuids: existingCDs.map { $0.uuid })
                    self.coreDataService.sendEventToSynchro(entityName: ProjectCD.entityName)
                }

                // - Handle flight plans
                let flightPlanFetchRequest = FlightPlanCD.fetchRequest()
                let projectUuidPredicate = NSPredicate(format: "projectUuid IN %@", modelsUuids)
                flightPlanFetchRequest.predicate = projectUuidPredicate
                let existingFlightPlanCDs = try self.currentChildContext.fetch(flightPlanFetchRequest)
                let flightPlans = existingFlightPlanCDs.compactMap { PictorFlightPlanModel(record: $0, thumbnail: nil, gutmaLinks: []) }
                deleteFlightPlans(flightPlans)
            } catch let error {
                PictorLogger.shared.e(.tag, "save error: \(error)")
            }
        }
    }

    func updateProjectFromRelatedFlightPlans(withUuid: String?) throws {
        guard let withUuid = withUuid else {
            throw PictorEngineError.unknown
        }
        let projectFetchRequest = ProjectCD.fetchRequest()
        projectFetchRequest.predicate = NSPredicate(format: "uuid = %@", withUuid)
        projectFetchRequest.fetchLimit = 1
        if let projectCD = try self.currentChildContext.fetch(projectFetchRequest).first {
            try updateFromEditableFlightPlan(projectCD)
            try updateFromLatestExecutedFlightPlan(projectCD)
        }
    }
}

private extension PictorContext {
    func updateProjects<T: PictorBaseModel>(_ models: [T], forceSave: Bool, local: Bool) {
        guard T.self is PictorBaseProjectModel.Type || T.self is PictorEngineBaseProjectModel.Type else { return }

        currentChildContext.performAndWait { [weak self] in
            guard let self = self else { return }
            guard let currentSessionCD = self.getCurrentSessionCD() else { return }

            do {
                // - Get UUIDs of models
                let modelsUuids: [String] = models.compactMap { $0.uuid }

                // - Get existing records
                var existingCDs: [ProjectCD] = []
                let fetchRequest = ProjectCD.fetchRequest()
                fetchRequest.shouldRefreshRefetchedObjects = true
                fetchRequest.predicate = NSPredicate(format: "uuid IN %@", modelsUuids)
                existingCDs = try self.currentChildContext.fetch(fetchRequest)

                // - Handle models
                let currentDate = Date()
                for model in models {
                    var modelCD: ProjectCD?

                    // - Search for model in existing records, create new record if not found
                    if let existingCDs = existingCDs.first(where: { $0.uuid == model.uuid }) {
                        modelCD = existingCDs
                    } else if forceSave {
                        modelCD = ProjectCD(context: self.currentChildContext)
                        modelCD?.userUuid = currentSessionCD.userUuid
                        modelCD?.localCreationDate = currentDate
                    } else {
                        PictorLogger.shared.w(.tag, "[\(ProjectCD.entityName)] Trying to update an unknown record \(model.uuid)")
                    }

                    if let modelCD = modelCD {
                        // - Update record
                        modelCD.update(model)
                        modelCD.localModificationDate = currentDate

                        // - Set engine synchro engine properties only if model conforms to BaseModel
                        if isBase(model) {
                            // - Synchro
                            if !local {
                                // - Set synchro updated date for incremental
                                modelCD.synchroLatestUpdatedDate = currentDate
                                // - Send event to trigger synchro incremental
                                self.coreDataService.sendEventToSynchro(entityName: ProjectCD.entityName)
                            }
                        }

                        // - Update from related flight plans
                        try updateFromEditableFlightPlan(modelCD)
                        try updateFromLatestExecutedFlightPlan(modelCD)
                    }
                }
            } catch let error {
                PictorLogger.shared.e(.tag, "save error: \(error)")
            }
        }
    }

    func isBase(_ model: PictorBaseModel) -> Bool {
        guard let _ = model as? PictorBaseProjectModel else {
            return false
        }
        return true
    }

    func updateFromEditableFlightPlan(_ projectCD: ProjectCD) throws {
        var subPredicateList: [NSPredicate] = []
        subPredicateList.append(NSPredicate(format: "projectUuid = %@", projectCD.uuid))
        subPredicateList.append(NSPredicate(format: "state = %@", PictorFlightPlanModel.State.editable.rawValue))
        subPredicateList.append(NSPredicate(format: "synchroIsDeleted = %@", NSNumber(value: false)))

        let editableFlightPlanFetchRequest = FlightPlanCD.fetchRequest()
        editableFlightPlanFetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
        editableFlightPlanFetchRequest.fetchLimit = 1
        if let editableFlightPlan = try self.currentChildContext.fetch(editableFlightPlanFetchRequest).first {
            projectCD.hasEditableFlightPlan = true
            projectCD.latestUpdatedEditableFlightPlanDate = editableFlightPlan.lastUpdated
        } else {
            projectCD.hasEditableFlightPlan = false
            projectCD.latestUpdatedEditableFlightPlanDate = nil
        }
    }

    func updateFromLatestExecutedFlightPlan(_ projectCD: ProjectCD) throws {
        var subPredicateList: [NSPredicate] = []
        subPredicateList.append(NSPredicate(format: "projectUuid = %@", projectCD.uuid))
        subPredicateList.append(NSPredicate(format: "state != %@", PictorFlightPlanModel.State.editable.rawValue))
        subPredicateList.append(NSPredicate(format: "hasReachedFirstWaypoint = %@", NSNumber(value: true)))
        subPredicateList.append(NSPredicate(format: "synchroIsDeleted = %@", NSNumber(value: false)))

        let executedFlightPlanFetchRequest = FlightPlanCD.fetchRequest()
        executedFlightPlanFetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
        executedFlightPlanFetchRequest.fetchLimit = 1
        executedFlightPlanFetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastUpdated", ascending: false)]
        if let executedFlightPlan = try self.currentChildContext.fetch(executedFlightPlanFetchRequest).first {
            projectCD.latestExecutedFlightPlanDate = executedFlightPlan.lastUpdated
        } else {
            projectCD.latestExecutedFlightPlanDate = nil
        }
    }
}
