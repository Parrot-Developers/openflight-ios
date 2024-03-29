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
    static let tag = "pictor.context.user"
}

internal extension PictorContext {
    func createUsers<T: PictorBaseModel>(_ models: [T]) {
        updateUsers(models, forceSave: true)
    }

    func updateUsers<T: PictorBaseModel>(_ models: [T]) {
        updateUsers(models, forceSave: false)
    }

    func deleteUsers<T: PictorBaseModel>(_ models: [T]) {
        guard T.self is PictorBaseUserModel.Type || T.self is PictorEngineBaseUserModel.Type else { return }

        currentChildContext.performAndWait { [weak self] in
            guard let self = self else { return }
            do {
                // - Get existing records
                let modelsUuids: [String] = models.compactMap { $0.uuid }
                let fetchRequest = UserCD.fetchRequest()
                fetchRequest.shouldRefreshRefetchedObjects = true
                let uuidPredicate = NSPredicate(format: "uuid IN %@", modelsUuids)
                fetchRequest.predicate = uuidPredicate
                let existingCDs = try self.currentChildContext.fetch(fetchRequest)

                // - Delete records
                for existingCD in existingCDs {
                    self.currentChildContext.delete(existingCD)
                }

                // - Delete all records with UUID
                let models: [PictorEngineManagedObject.Type] = [DroneCD.self, ProjectCD.self, ProjectPix4dCD.self, FlightCD.self, FlightPlanCD.self, GutmaLinkCD.self, ThumbnailCD.self]
                for model in models {
                    let fetchRequest: NSFetchRequest<PictorEngineManagedObject> = NSFetchRequest(entityName: model.entityName)
                    fetchRequest.predicate = NSPredicate(format: "userUuid in %@", modelsUuids)
                    let fetchResult = try currentChildContext.fetch(fetchRequest)
                    for record in fetchResult {
                        self.currentChildContext.delete(record)
                    }
                }
            } catch let error {
                PictorLogger.shared.e(.tag, "save error: \(error)")
            }
        }
    }
}

private extension PictorContext {
    func updateUsers<T: PictorBaseModel>(_ models: [T], forceSave: Bool) {
        guard T.self is PictorBaseUserModel.Type || T.self is PictorEngineBaseUserModel.Type else { return }

        currentChildContext.performAndWait { [weak self] in
            guard let self = self else { return }


            do {
                // - Get UUIDs of models
                let modelsUuids: [String] = models.compactMap { $0.uuid }

                // - Get existing records
                var existingCDs: [UserCD] = []
                let fetchRequest = UserCD.fetchRequest()
                fetchRequest.shouldRefreshRefetchedObjects = true
                let uuidPredicate = NSPredicate(format: "uuid IN %@", modelsUuids)
                fetchRequest.predicate = uuidPredicate
                existingCDs = try self.currentChildContext.fetch(fetchRequest)

                // - Handle models
                let currentDate = Date()
                for model in models {
                    var modelCD: UserCD

                    // - Search for model in existing records, create new record if not found
                    if let existingCDs = existingCDs.first(where: { $0.uuid == model.uuid }) {
                        modelCD = existingCDs
                    } else if forceSave {
                        modelCD = UserCD(context: self.currentChildContext)
                        modelCD.localCreationDate = currentDate
                    } else {
                        PictorLogger.shared.w(.tag, "[\(UserCD.entityName)] Trying to update an unknown record \(model.uuid)")
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
