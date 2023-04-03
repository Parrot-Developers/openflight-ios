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
    static let tag = "pictor.engine.repository.thumbnail"
}

// MARK: - Protocol
protocol PictorEngineBaseThumbnailRepository: PictorEngineBaseRepository where PictorEngineModelType == PictorEngineThumbnailModel {
    /// Get odd thumbnails that are not linked anymore to a flight or flight plan
    ///
    /// - Parameters:
    ///    - pictorContext: PIctorContext to fetch
    /// - Returns: list of `PictorEngineThumbnailModel`
    func getOdds(in pictorContext: PictorContext) -> [PictorEngineThumbnailModel]

    /// Get odd thumbnails that are not linked anymore to a flight or flight plan
    ///
    /// - Parameters:
    ///    - completion: callback closure called when finished
    func getOdds(in pictorContext: PictorContext, completion: @escaping ((Result<[PictorEngineThumbnailModel], PictorEngineError>) -> Void))
}

// MARK: - Implementation
class PictorEngineThumbnailRepository: PictorEngineRepository<PictorEngineThumbnailModel>, PictorEngineBaseThumbnailRepository  {
    // MARK: Override PictorEngineBaseRepository
    override var entityName: String { ThumbnailCD.entityName }

    // MARK: Pictor Engine Base Thumbnail Repository Protocol
    func getOdds(in pictorContext: PictorContext) -> [PictorEngineThumbnailModel] {
        var result: [PictorEngineThumbnailModel] = []

        pictorContext.performAndWait { [unowned self] contextCD in
            if case let .success(models) = self.getOdds(contextCD: contextCD) {
                result = models
            }
        }

        return result
    }

    func getOdds(in pictorContext: PictorContext, completion: @escaping ((Result<[PictorEngineThumbnailModel], PictorEngineError>) -> Void)) {
        pictorContext.perform { [unowned self] contextCD in
            completion(self.getOdds(contextCD: contextCD))
        }
    }

    override func convertToModel(_ record: PictorEngineManagedObject, context: NSManagedObjectContext) -> PictorEngineThumbnailModel? {
        guard let record = record as? ThumbnailCD else {
            PictorLogger.shared.e(.tag, "❌💾🗂 Bad managed object of \(entityName)")
            return nil
        }
        let model = PictorThumbnailModel(record: record)
        return PictorEngineThumbnailModel(model: model, record: record)
    }
}

private extension PictorEngineThumbnailRepository {
    private func getOdds(contextCD: NSManagedObjectContext) -> Result<[PictorEngineThumbnailModel], PictorEngineError> {
        do {
            let thumbnailProperty = "thumbnailUuid"
            var request = NSFetchRequest<NSDictionary>(entityName: FlightPlanCD.entityName)
            request.propertiesToFetch = [thumbnailProperty]
            request.resultType = .dictionaryResultType
            var referencedThumbnailUuids = try contextCD.fetch(request).compactMap({ $0[thumbnailProperty] as? String })

            request = NSFetchRequest<NSDictionary>(entityName: FlightCD.entityName)
            request.propertiesToFetch = [thumbnailProperty]
            request.resultType = .dictionaryResultType
            let thumbnailUuids = try contextCD.fetch(request).compactMap({ $0[thumbnailProperty] as? String })
            referencedThumbnailUuids.append(contentsOf: thumbnailUuids)

            let thumbnailsRequest = ThumbnailCD.fetchRequest()
            thumbnailsRequest.predicate = NSPredicate(format: "NOT (uuid IN %@)", referencedThumbnailUuids)
            let thumbnails = try contextCD.fetch(thumbnailsRequest)
            let models = thumbnails.compactMap { self.convertToModel($0, context: contextCD) }
            return .success(models)
        } catch let error {
            return .failure(.fetchError(error))
        }
    }
}
