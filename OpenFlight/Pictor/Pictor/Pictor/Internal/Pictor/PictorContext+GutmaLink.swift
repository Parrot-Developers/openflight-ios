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
    static let tag = "pictor.context.gutmaLink"
}

internal extension PictorContext {
    func createGutmaLinks<T: PictorBaseModel>(_ models: [T]) {
        updateGutmaLinks(models, forceSave: true, local: false)
    }

    func updateGutmaLinks<T: PictorBaseModel>(_ models: [T]) {
        updateGutmaLinks(models, forceSave: false, local: false)
    }

    func createGutmaLinks<T: PictorBaseModel>(_ models: [T], local: Bool) {
        updateGutmaLinks(models, forceSave: true, local: local)
    }

    func updateGutmaLinks<T: PictorBaseModel>(_ models: [T], local: Bool) {
        updateGutmaLinks(models, forceSave: false, local: local)
    }

    func updateEngineGutmaLinks<T: PictorBaseModel>(_ models: [T], local: Bool) {
        updateGutmaLinks(models, forceSave: false, local: local, onlyEngine: true)
    }

    func deleteGutmaLinks<T: PictorBaseModel>(_ models: [T]) {
        guard T.self is PictorBaseGutmaLinkModel.Type || T.self is PictorEngineBaseGutmaLinkModel.Type else { return }

        currentChildContext.performAndWait { [weak self] in
            guard let self = self else { return }
            do {
                // - Get existing records
                let modelsUuids: [String] = models.compactMap { $0.uuid }
                var uuidsMarkAsDeleted: [String] = []
                let fetchRequest = GutmaLinkCD.fetchRequest()
                fetchRequest.shouldRefreshRefetchedObjects = true
                fetchRequest.predicate = NSPredicate(format: "uuid IN %@", modelsUuids)
                let existingCDs = try self.currentChildContext.fetch(fetchRequest)

                // - Handle records
                let currentDate = Date()
                for existingCD in existingCDs {
                    var cloudId = existingCD.cloudId

                    // - If model has cloudId to 0, it is considered to be deleted locally regardless of the record's cloudId
                    if let model = models.first(where: { $0.uuid == existingCD.uuid }) as? PictorBaseGutmaLinkModel,
                       model.cloudId == 0 {
                        cloudId = 0
                    }
                    if let engineModel = models.first(where: { $0.uuid == existingCD.uuid }) as? PictorEngineBaseGutmaLinkModel,
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

                if !uuidsMarkAsDeleted.isEmpty {
                    self.coreDataService.sendEventMarkAsDeleted(entityName: GutmaLinkCD.entityName,
                                                                uuids: uuidsMarkAsDeleted)
                    self.coreDataService.sendEventToSynchro(entityName: GutmaLinkCD.entityName)
                }
            } catch let error {
                PictorLogger.shared.e(.tag, "save error: \(error)")
            }
        }
    }
}

private extension PictorContext {
    func updateGutmaLinks<T: PictorBaseModel>(_ models: [T], forceSave: Bool, local: Bool, onlyEngine: Bool = false) {
        guard T.self is PictorBaseGutmaLinkModel.Type || T.self is PictorEngineBaseGutmaLinkModel.Type else { return }

        currentChildContext.performAndWait { [weak self] in
            guard let self = self else { return }
            guard let currentSessionCD = self.getCurrentSessionCD() else { return }

            do {
                // - Get UUIDs of models, assigned flights and assigned flight plans
                let modelsUuids: [String] = models.compactMap { $0.uuid }

                // - Get existing records
                var existingCDs: [GutmaLinkCD] = []
                let fetchRequest = GutmaLinkCD.fetchRequest()
                fetchRequest.shouldRefreshRefetchedObjects = true
                let uuidPredicate = NSPredicate(format: "uuid IN %@", modelsUuids)
                fetchRequest.predicate = uuidPredicate
                existingCDs = try self.currentChildContext.fetch(fetchRequest)

                // - Handle models
                let currentDate = Date()
                for model in models {
                    var modelCD: GutmaLinkCD

                    // - Search for model in existing records, create new record if not found
                    if let existingCDs = existingCDs.first(where: { $0.uuid == model.uuid }) {
                        modelCD = existingCDs
                    } else if forceSave {
                        modelCD = GutmaLinkCD(context: self.currentChildContext)
                        modelCD.userUuid = currentSessionCD.userUuid
                        modelCD.localCreationDate = currentDate
                    } else {
                        PictorLogger.shared.w(.tag, "[\(GutmaLinkCD.entityName)] Trying to update an unknown record \(model.uuid)")
                        continue
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
                        // - Synchro
                        if !local {
                            // - Set synchro updated date for incremental
                            modelCD.synchroLatestUpdatedDate = currentDate
                            // - Send event to trigger synchro incremental
                            self.coreDataService.sendEventToSynchro(entityName: GutmaLinkCD.entityName)
                        }
                    }
                }
            } catch let error {
                PictorLogger.shared.e(.tag, "save error: \(error)")
            }
        }
    }

    func isBase(_ model: PictorBaseModel) -> Bool {
        guard let _ = model as? PictorBaseGutmaLinkModel else {
            return false
        }
        return true
    }
}
