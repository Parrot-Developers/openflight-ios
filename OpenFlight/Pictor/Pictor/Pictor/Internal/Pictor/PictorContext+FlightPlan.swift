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
    static let tag = "pictor.context.flightPlan"
}

internal extension PictorContext {
    func createFlightPlans<T: PictorBaseModel>(_ models: [T]) {
        updateFlightPlans(models, forceSave: true, local: false)
    }

    func updateFlightPlans<T: PictorBaseModel>(_ models: [T]) {
        updateFlightPlans(models, forceSave: false, local: false)
    }

    func createFlightPlans<T: PictorBaseModel>(_ models: [T], local: Bool) {
        updateFlightPlans(models, forceSave: true, local: local)
    }

    func updateFlightPlans<T: PictorBaseModel>(_ models: [T], local: Bool) {
        updateFlightPlans(models, forceSave: false, local: local)
    }

    func deleteFlightPlans<T: PictorBaseModel>(_ models: [T]) {
        guard T.self is PictorBaseFlightPlanModel.Type || T.self is PictorEngineBaseFlightPlanModel.Type else { return }

        currentChildContext.performAndWait { [weak self] in
            guard let self = self else { return }
            do {
                // - Get existing records
                let modelsUuids: [String] = models.compactMap { $0.uuid }
                var uuidsMarkAsDeleted: [String] = []
                let fetchRequest = FlightPlanCD.fetchRequest()
                fetchRequest.shouldRefreshRefetchedObjects = true
                let uuidPredicate = NSPredicate(format: "uuid IN %@", modelsUuids)
                fetchRequest.predicate = uuidPredicate
                let existingCDs = try self.currentChildContext.fetch(fetchRequest)
                let thumbnailUuids = existingCDs.compactMap { $0.thumbnailUuid }

                // - Handle records
                let currentDate = Date()
                for existingCD in existingCDs {
                    var cloudId = existingCD.cloudId

                    // - If model has cloudId to 0, it is considered to be deleted locally regardless of the record's cloudId
                    if let model = models.first(where: { $0.uuid == existingCD.uuid }) as? PictorBaseFlightPlanModel,
                       model.cloudId == 0 {
                        cloudId = 0
                    }
                    if let engineModel = models.first(where: { $0.uuid == existingCD.uuid }) as? PictorEngineBaseFlightPlanModel,
                       engineModel.flightPlanModel.cloudId == 0 {
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

                    // - Update related project
                    try updateProjectFromRelatedFlightPlans(withUuid: existingCD.projectUuid)
                }

                // - Handle Thumbnails
                let thumbnailFetchRequest = ThumbnailCD.fetchRequest()
                let thumbnailuuidPredicate = NSPredicate(format: "uuid IN %@", thumbnailUuids)
                thumbnailFetchRequest.predicate = thumbnailuuidPredicate
                let thumbnails = try self.currentChildContext.fetch(thumbnailFetchRequest).compactMap { PictorThumbnailModel(record: $0) }
                if !thumbnails.isEmpty {
                    deleteThumbnails(thumbnails)
                }

                // - Handle GutmaLink
                let gutmaLinkFetchRequest = GutmaLinkCD.fetchRequest()
                gutmaLinkFetchRequest.predicate = NSPredicate(format: "flightPlanUuid IN %@", modelsUuids)
                let gutmaLinks = try self.currentChildContext.fetch(gutmaLinkFetchRequest).compactMap { PictorGutmaLinkModel(record: $0) }
                if !gutmaLinks.isEmpty {
                    deleteGutmaLinks(gutmaLinks)
                }

                if !uuidsMarkAsDeleted.isEmpty {
                    self.coreDataService.sendEventMarkAsDeleted(entityName: FlightPlanCD.entityName,
                                                                uuids: uuidsMarkAsDeleted)
                    self.coreDataService.sendEventToSynchro(entityName: FlightPlanCD.entityName)
                }

            } catch let error {
                PictorLogger.shared.e(.tag, "save error: \(error)")
            }
        }
    }
}

private extension PictorContext {
    func updateFlightPlans<T: PictorBaseModel>(_ models: [T], forceSave: Bool, local: Bool) {
        guard T.self is PictorBaseFlightPlanModel.Type || T.self is PictorEngineBaseFlightPlanModel.Type else { return }

        currentChildContext.performAndWait { [weak self] in
            guard let self = self else { return }
            guard let currentSessionCD = self.getCurrentSessionCD() else { return }

            // - Get existing records
            var existingCDs: [FlightPlanCD] = []
            do {
                // - Get UUIDs of models and assigned projects
                let modelsUuids: [String] = models.compactMap { $0.uuid }

                // - Get existing records
                let fetchRequest = FlightPlanCD.fetchRequest()
                fetchRequest.shouldRefreshRefetchedObjects = true
                fetchRequest.predicate = NSPredicate(format: "uuid IN %@", modelsUuids)
                existingCDs = try self.currentChildContext.fetch(fetchRequest)

                // - Save model's thumbnails if it exists
                // - Delete thumbnail records if model's thumbnail is nil
                var flightPlanModels: [PictorBaseFlightPlanModel] = []
                if let models = models as? [PictorEngineBaseFlightPlanModel] {
                    flightPlanModels = models.compactMap { $0.flightPlanModel }
                } else if let models = models as? [PictorBaseFlightPlanModel] {
                    flightPlanModels = models
                }
                if !flightPlanModels.isEmpty {
                    var thumbnailModels: [PictorThumbnailModel] = []
                    var thumbnailUuidsToDelete: [String] = []

                    flightPlanModels.forEach { flightPlan in
                        if let thumbnailModel = flightPlan.thumbnail {
                            thumbnailModels.append(thumbnailModel)
                        } else if let existingCD = existingCDs.first(where: { $0.uuid == flightPlan.uuid }),
                                  let thumbnailUuid = existingCD.thumbnailUuid {
                            thumbnailUuidsToDelete.append(thumbnailUuid)
                        }
                    }

                    if !thumbnailModels.isEmpty {
                        saveThumbnails(thumbnailModels)
                    }
                    if !thumbnailUuidsToDelete.isEmpty {
                        let thumbnailFetchRequest = ThumbnailCD.fetchRequest()
                        thumbnailFetchRequest.predicate = NSPredicate(format: "uuid IN %@", thumbnailUuidsToDelete)
                        let thumbnailsToDelete = try self.currentChildContext.fetch(thumbnailFetchRequest).compactMap { PictorThumbnailModel(record: $0) }
                        if !thumbnailsToDelete.isEmpty {
                            deleteThumbnails(thumbnailsToDelete)
                        }
                    }
                }

                // - Handle models
                let currentDate = Date()
                for model in models {
                    var modelCD: FlightPlanCD?

                    // - Search for model in existing records, create new record if not found
                    if let existingCDs = existingCDs.first(where: { $0.uuid == model.uuid }) {
                        modelCD = existingCDs
                    } else if forceSave {
                        modelCD = FlightPlanCD(context: self.currentChildContext)
                        modelCD?.userUuid = currentSessionCD.userUuid
                        modelCD?.localCreationDate = currentDate
                    } else {
                        PictorLogger.shared.w(.tag, "[\(FlightPlanCD.entityName)] Trying to update an unknown record \(model.uuid)")
                    }

                    if let modelCD = modelCD {
                        // - Get project dataSetting & formatVersion from model
                        var hasDataSettingChanged: Bool = false
                        var hasFormatVersionChanged: Bool = false
                        if let flightPlan = model as? PictorBaseFlightPlanModel {
                            if modelCD.dataSetting != flightPlan.dataSetting {
                                hasDataSettingChanged = true
                            }
                            if modelCD.formatVersion != flightPlan.formatVersion {
                                hasFormatVersionChanged = true
                            }
                        }

                        // - Update record
                        modelCD.update(model)
                        modelCD.localModificationDate = currentDate

                        // - Set engine synchro engine properties only if model conforms to BaseModel
                        if isBase(model) {
                            // - Reset synchro status to upload file if dataSetting or formatVersion has changed
                            // so it will be uploaded in next synchro appointment
                            if hasDataSettingChanged || hasFormatVersionChanged {
                                modelCD.synchroStatus = PictorEngineSynchroStatus.notSync.rawValue
                            }

                            // - Synchro
                            if !local {
                                // - Set synchro updated date for incremental
                                modelCD.synchroLatestUpdatedDate = currentDate
                                // - Send event to trigger synchro incremental
                                self.coreDataService.sendEventToSynchro(entityName: FlightPlanCD.entityName)
                            }
                        }

                        // - Update related project
                        try updateProjectFromRelatedFlightPlans(withUuid: modelCD.projectUuid)
                    }
                }
            } catch let error {
                PictorLogger.shared.e(.tag, "save error: \(error)")
            }
        }
    }

    func isBase(_ model: PictorBaseModel) -> Bool {
        guard let _ = model as? PictorBaseFlightPlanModel else {
            return false
        }
        return true
    }
}
