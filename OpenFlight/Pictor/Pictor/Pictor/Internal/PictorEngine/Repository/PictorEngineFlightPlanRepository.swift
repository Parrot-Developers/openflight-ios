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
import Combine
import CoreData

fileprivate extension String {
    static let tag = "pictor.engine.repository.flightplan"
}

// MARK: - Protocol
protocol PictorEngineBaseFlightPlanRepository: PictorEngineBaseRepository where PictorEngineModelType == PictorEngineFlightPlanModel {
    /// Get flight plans by project UUID
    ///
    /// - Parameters:
    ///    - pictorContext: PIctorContext to fetch
    ///    - byProjectUuid: list of format version of flight plan
    /// - Returns: list of `PictorEngineFlightPlanModel`
    func get(in pictorContext: PictorContext, byProjectUuid: String) async -> [PictorEngineFlightPlanModel]

    /// Get flight plans by project UUID
    ///
    /// - Parameters:
    ///    - pictorContext: PIctorContext to fetch
    ///    - byProjectUuid: list of format version of flight plan
    ///    - completion: callback closure called when finished
    func get(in pictorContext: PictorContext, byProjectUuid: String, completion: @escaping ((_ result: Result<[PictorEngineFlightPlanModel], PictorEngineError>) -> Void))
}

// MARK: - Implementation
class PictorEngineFlightPlanRepository: PictorEngineRepository<PictorEngineFlightPlanModel>, PictorEngineBaseFlightPlanRepository  {
    // MARK: Override PictorEngineBaseRepository
    override var entityName: String { FlightPlanCD.entityName }

    // MARK: Pictor Engine Base Flight Plan Repository Protocol
    func get(in pictorContext: PictorContext, byProjectUuid: String) async -> [PictorEngineFlightPlanModel] {
        return await withCheckedContinuation { continuation in
            get(in: pictorContext, byProjectUuid: byProjectUuid) {
                if case .success(let models) = $0 {
                    continuation.resume(returning: models)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    func get(in pictorContext: PictorContext, byProjectUuid: String, completion: @escaping ((Result<[PictorEngineFlightPlanModel], PictorEngineError>) -> Void)) {
        pictorContext.perform { [weak self] contextCD in
            guard let self = self else {
                completion(.failure(.unknown))
                return
            }

            completion(self.get(contextCD: contextCD, byProjectUuid: byProjectUuid))
        }
    }

    override func convertToModel(_ record: PictorEngineManagedObject, context: NSManagedObjectContext) -> PictorEngineFlightPlanModel? {
        guard let record = record as? FlightPlanCD else {
            PictorLogger.shared.e(.tag, "❌💾🗂 Bad managed object of \(entityName)")
            return nil
        }

        var thumbnail: PictorThumbnailModel?
        if let thumbnailUuid = record.thumbnailUuid {
            thumbnail = try? repositories.thumbnail.get(contextCD: context, byUuid: thumbnailUuid, synchroIsDeleted: nil).get()?.thumbnailModel
        }
        let gutmaLinks = ((try? repositories.gutmaLink.get(contextCD: context, flightPlanUuid: record.uuid).get()) ?? []).map { $0.gutmaLinkModel }
        let model = PictorFlightPlanModel(record: record, thumbnail: thumbnail, gutmaLinks: gutmaLinks)
        return PictorEngineFlightPlanModel(model: model, record: record)
    }
}

extension PictorEngineFlightPlanRepository {
    internal func get(contextCD: NSManagedObjectContext, byProjectUuid: String) -> Result<[PictorEngineFlightPlanModel], PictorEngineError> {
        do {
            let fetchRequest: NSFetchRequest<PictorEngineManagedObject> = NSFetchRequest(entityName: entityName)
            let predicate = NSPredicate(format: "projectUuid == %@", byProjectUuid)
            fetchRequest.predicate = predicate

            let fetchResult = try contextCD.fetch(fetchRequest)
            let models = fetchResult.compactMap { self.convertToModel($0, context: contextCD) }
            return .success(models)
        } catch let error {
            return .failure(.fetchError(error))
        }
    }
}
