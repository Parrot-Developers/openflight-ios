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
    static let tag = "pictor.engine.repository.gutmalink"
}

// MARK: - Protocol
protocol PictorEngineBaseGutmaLinkRepository: PictorEngineBaseRepository where PictorEngineModelType == PictorEngineGutmaLinkModel {
    /// Get GutmaLink by flight's UUID and flight plan's UUID
    ///
    /// - Parameters:
    ///    - pictorContext: PIctorContext to fetch
    ///    - flightUuid: flight's UUID to specify
    ///    - flightPlanUuid: flight plan's UUID to specify
    /// - Returns: list of `PictorEngineGutmaLinkModel`
    func get(in pictorContext: PictorContext, flightUuid: String, flightPlanUuid: String) async -> PictorEngineGutmaLinkModel?

    /// Get GutmaLink by flight's UUID and flight plan's UUID
    ///
    /// - Parameters:
    ///    - pictorContext: PIctorContext to fetch
    ///    - flightUuid: flight's UUID to specify
    ///    - flightPlanUuid: flight plan's UUID to specify
    ///    - completion: callback closure called when finished
    func get(in pictorContext: PictorContext, flightUuid: String, flightPlanUuid: String, completion: @escaping ((Result<PictorEngineGutmaLinkModel?, PictorEngineError>) -> Void))
}

// MARK: - Implementation
class PictorEngineGutmaLinkRepository: PictorEngineRepository<PictorEngineGutmaLinkModel>, PictorEngineBaseGutmaLinkRepository  {
    // MARK: Override PictorEngineBaseRepository
    override var entityName: String { GutmaLinkCD.entityName }

    // MARK: Pictor Engine Base GutmaLink Repository Protocol
    func get(in pictorContext: PictorContext, flightUuid: String, flightPlanUuid: String) async -> PictorEngineGutmaLinkModel? {
        return await withCheckedContinuation { continuation in
            get(in: pictorContext, flightUuid: flightUuid, flightPlanUuid: flightPlanUuid) {
                if case .success(let gutmaLink) = $0, let gutmaLink = gutmaLink {
                    continuation.resume(returning: gutmaLink)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    // MARK: Pictor Base GutmaLink Repository Protocol
    func get(in pictorContext: PictorContext, flightUuid: String, flightPlanUuid: String, completion: @escaping ((Result<PictorEngineGutmaLinkModel?, PictorEngineError>) -> Void)) {
        pictorContext.perform { [unowned self] contextCD in
            completion(self.get(contextCD: contextCD, flightUuid: flightUuid, flightPlanUuid: flightPlanUuid))
        }
    }

    override func convertToModel(_ record: PictorEngineManagedObject, context: NSManagedObjectContext) -> PictorEngineGutmaLinkModel? {
        guard let record = record as? GutmaLinkCD else {
            PictorLogger.shared.e(.tag, "❌💾🗂 Bad managed object of \(entityName)")
            return nil
        }
        let model = PictorGutmaLinkModel(record: record)
        return PictorEngineGutmaLinkModel(model: model, record: record)
    }
}

extension PictorEngineGutmaLinkRepository {
    internal func get(contextCD: NSManagedObjectContext, flightUuid: String, flightPlanUuid: String) -> Result<PictorEngineGutmaLinkModel?, PictorEngineError> {
        do {
            let fetchRequest: NSFetchRequest<PictorEngineManagedObject> = NSFetchRequest(entityName: self.entityName)

            var subPredicateList = [NSPredicate]()

            let flightPlanUuidPredicate = NSPredicate(format: "flightPlanUuid == %@", flightPlanUuid)
            subPredicateList.append(flightPlanUuidPredicate)

            let flightUuidPredicate = NSPredicate(format: "flightUuid == %@", flightUuid)
            subPredicateList.append(flightUuidPredicate)

            let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
            fetchRequest.predicate = compoundPredicates
            fetchRequest.fetchLimit = 1

            if let first = try contextCD.fetch(fetchRequest).first {
                return .success(convertToModel(first, context: contextCD))
            } else {
                return .success(nil)
            }
        } catch let error {
            return .failure(.fetchError(error))
        }
    }

    internal func get(contextCD: NSManagedObjectContext, flightPlanUuid: String) -> Result<[PictorEngineGutmaLinkModel], PictorEngineError> {
        do {
            let fetchRequest: NSFetchRequest<PictorEngineManagedObject> = NSFetchRequest(entityName: self.entityName)
            fetchRequest.predicate = NSPredicate(format: "flightPlanUuid == %@", flightPlanUuid)

            let fetchResult = try contextCD.fetch(fetchRequest)
            return .success(convertToModels(fetchResult, context: contextCD))
        } catch let error {
            return .failure(.fetchError(error))
        }
    }
}
