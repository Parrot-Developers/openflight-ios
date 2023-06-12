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
    static let tag = "pictor.context.drone"
}

internal extension PictorContext {
    func createDrones<T: PictorBaseModel>(_ models: [T]) {
        updateDrones(models, forceSave: true)
    }

    func updateDrones<T: PictorBaseModel>(_ models: [T]) {
        updateDrones(models, forceSave: false)
    }

    func deleteDrones<T: PictorBaseModel>(_ models: [T]) {
        guard T.self is PictorBaseDroneModel.Type || T.self is PictorEngineBaseDroneModel.Type else { return }

        currentChildContext.performAndWait { [weak self] in
            guard let self = self else { return }
            do {
                // - Get existing records
                let modelsUuids: [String] = models.compactMap { $0.uuid }
                let fetchRequest = DroneCD.fetchRequest()
                fetchRequest.shouldRefreshRefetchedObjects = true
                let uuidPredicate = NSPredicate(format: "uuid IN %@", modelsUuids)
                fetchRequest.predicate = uuidPredicate
                let existingCDs = try self.currentChildContext.fetch(fetchRequest)

                // - Delete records
                for existingCD in existingCDs {
                    self.currentChildContext.delete(existingCD)
                }
            } catch let error {
                PictorLogger.shared.e(.tag, "save error: \(error)")
            }
        }
    }
}

private extension PictorContext {
    func updateDrones<T: PictorBaseModel>(_ models: [T], forceSave: Bool) {
        guard T.self is PictorBaseDroneModel.Type || T.self is PictorEngineBaseDroneModel.Type else { return }

        currentChildContext.performAndWait { [weak self] in
            guard let self = self else { return }
            guard let currentSessionCD = self.getCurrentSessionCD() else { return }

            do {
                // - Get UUIDs of models
                let modelsUuids: [String] = models.compactMap { $0.uuid }

                // - Get existing records
                var existingCDs: [DroneCD] = []
                let fetchRequest = DroneCD.fetchRequest()
                fetchRequest.shouldRefreshRefetchedObjects = true
                let uuidPredicate = NSPredicate(format: "uuid IN %@", modelsUuids)
                fetchRequest.predicate = uuidPredicate
                existingCDs = try self.currentChildContext.fetch(fetchRequest)

                // - Handle models
                let currentDate = Date()
                for model in models {
                    var modelCD: DroneCD

                    // - Search for model in existing records, create new record if not found
                    if let existingCDs = existingCDs.first(where: { $0.uuid == model.uuid }) {
                        modelCD = existingCDs
                    } else if forceSave {
                        modelCD = DroneCD(context: self.currentChildContext)
                        modelCD.userUuid = currentSessionCD.userUuid
                        modelCD.localCreationDate = currentDate
                    } else {
                        PictorLogger.shared.w(.tag, "[\(DroneCD.entityName)] Trying to update an unknown record \(model.uuid)")
                        continue
                    }

                    // - Update record
                    modelCD.update(model)
                    modelCD.localModificationDate = currentDate
                }
            } catch let error {
                PictorLogger.shared.e(.tag, "save error: \(error)")
            }
        }
    }
}
