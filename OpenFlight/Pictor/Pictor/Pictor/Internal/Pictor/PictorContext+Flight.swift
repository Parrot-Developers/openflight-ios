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
    static let tag = "pictor.context.flight"
}

internal extension PictorContext {
    func createFlights<T: PictorBaseModel>(_ models: [T]) {
        updateFlights(models, forceSave: true, local: false)
    }

    func updateFlights<T: PictorBaseModel>(_ models: [T]) {
        updateFlights(models, forceSave: false, local: false)
    }

    func createFlights<T: PictorBaseModel>(_ models: [T], local: Bool) {
        updateFlights(models, forceSave: true, local: local)
    }

    func updateFlights<T: PictorBaseModel>(_ models: [T], local: Bool) {
        updateFlights(models, forceSave: false, local: local)
    }

    func updateEngineFlights<T: PictorBaseModel>(_ models: [T], local: Bool) {
        updateFlights(models, forceSave: false, local: local, onlyEngine: true)
    }

    func deleteFlights<T: PictorBaseModel>(_ models: [T]) {
        guard T.self is PictorBaseFlightModel.Type || T.self is PictorEngineBaseFlightModel.Type else { return }

        currentChildContext.performAndWait { [weak self] in
            guard let self = self else { return }
            do {
                // - Get existing records
                let modelsUuids: [String] = models.compactMap { $0.uuid }
                var uuidsMarkAsDeleted: [String] = []
                let fetchRequest = FlightCD.fetchRequest()
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
                    if let model = models.first(where: { $0.uuid == existingCD.uuid }) as? PictorBaseFlightModel,
                       model.cloudId == 0 {
                        cloudId = 0
                    }
                    if let engineModel = models.first(where: { $0.uuid == existingCD.uuid }) as? PictorEngineBaseFlightModel,
                       engineModel.cloudId == 0 {
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
                gutmaLinkFetchRequest.predicate = NSPredicate(format: "flightUuid IN %@", modelsUuids)
                let gutmaLinks = try self.currentChildContext.fetch(gutmaLinkFetchRequest).compactMap { PictorGutmaLinkModel(record: $0) }
                if !gutmaLinks.isEmpty {
                    deleteGutmaLinks(gutmaLinks)
                }

                if !uuidsMarkAsDeleted.isEmpty {
                    self.coreDataService.sendEventMarkAsDeleted(entityName: FlightCD.entityName,
                                                                uuids: uuidsMarkAsDeleted)
                    self.coreDataService.sendEventToSynchro(entityName: FlightCD.entityName)
                }
            } catch let error {
                PictorLogger.shared.e(.tag, "save error: \(error)")
            }
        }
    }
}

private extension PictorContext {
    func updateFlights<T: PictorBaseModel>(_ models: [T], forceSave: Bool, local: Bool, onlyEngine: Bool = false) {
        guard T.self is PictorBaseFlightModel.Type || T.self is PictorEngineBaseFlightModel.Type else { return }

        currentChildContext.performAndWait { [weak self] in
            guard let self = self else { return }
            guard let currentSessionCD = self.getCurrentSessionCD() else { return }

            do {
                // - Get UUIDs of models
                let modelsUuids: [String] = models.compactMap { $0.uuid }

                // - Get existing records
                var existingCDs: [FlightCD] = []
                let fetchRequest = FlightCD.fetchRequest()
                fetchRequest.shouldRefreshRefetchedObjects = true
                let uuidPredicate = NSPredicate(format: "uuid IN %@", modelsUuids)
                fetchRequest.predicate = uuidPredicate
                existingCDs = try self.currentChildContext.fetch(fetchRequest)

                // - Save model's thumbnails if it exists
                // - Delete thumbnail records if model's thumbnail is nil
                var flightModels: [PictorBaseFlightModel] = []
                if let models = models as? [PictorEngineBaseFlightModel] {
                    flightModels = models.compactMap { $0.flightModel }
                } else if let models = models as? [PictorBaseFlightModel] {
                    flightModels = models
                }
                if !flightModels.isEmpty {
                    var thumbnailModels: [PictorThumbnailModel] = []
                    var thumbnailUuidsToDelete: [String] = []

                    flightModels.forEach { flight in
                        if let thumbnailModel = flight.thumbnail {
                            thumbnailModels.append(thumbnailModel)
                        } else if let existingCD = existingCDs.first(where: { $0.uuid == flight.uuid }),
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
                    let modelCD: FlightCD

                    // - Search for model in existing records, create new record if not found
                    if let existingCDs = existingCDs.first(where: { $0.uuid == model.uuid }) {
                        modelCD = existingCDs
                    } else if forceSave {
                        modelCD = FlightCD(context: self.currentChildContext)
                        modelCD.userUuid = currentSessionCD.userUuid
                        modelCD.localCreationDate = currentDate
                    } else {
                        PictorLogger.shared.w(.tag, "[\(FlightCD.entityName)] Trying to update an unknown record \(model.uuid)")
                        continue
                    }

                    // - Get gutma from model
                    var hasGutmaFileChanged: Bool = false
                    if let flight = model as? PictorBaseFlightModel,
                       modelCD.gutmaFile != flight.gutmaFile {
                        hasGutmaFileChanged = true
                    }

                    // - Update record
                    if onlyEngine {
                        modelCD.updateEngine(model)
                    } else {
                        modelCD.update(model)
                    }
                    modelCD.localModificationDate = currentDate

                    // - Set engine synchro engine properties only if model conforms to BaseModel
                    if isBase(model) {
                        // - Reset synchro status if gutmaFile has changed
                        // so it will be uploaded in next synchro appointment
                        if hasGutmaFileChanged {
                            modelCD.synchroStatus = PictorEngineSynchroStatus.notSync.rawValue
                        }

                        // - Synchro
                        if !local {
                            // - Set synchro updated date for incremental
                            modelCD.synchroLatestUpdatedDate = currentDate
                            // - Send event to trigger synchro incremental
                            self.coreDataService.sendEventToSynchro(entityName: FlightCD.entityName)
                        }
                    }
                }
            } catch let error {
                PictorLogger.shared.e(.tag, "save error: \(error)")
            }
        }
    }

    func isBase(_ model: PictorBaseModel) -> Bool {
        guard let _ = model as? PictorBaseFlightModel else {
            return false
        }
        return true
    }
}
