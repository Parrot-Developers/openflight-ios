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
    static let tag = "pictor.repository.projectPix4d"
}

// MARK: - Protocol
public protocol PictorBaseProjectPix4dRepository: PictorBaseRepository where PictorBaseModelType == PictorProjectPix4dModel {
    /// Gets Pix4d projects with project date > a minimum date
    ///
    /// - Parameters:
    ///    - afterDate: the minimum project date
    /// - Returns: list of `PictorProjectPix4dModel`
    func getAll(minDate: Date) -> [PictorProjectPix4dModel]
}

// MARK: - Implementation
public class PictorProjectPix4dRepository: PictorRepository<PictorProjectPix4dModel>, PictorBaseProjectPix4dRepository  {
    override var entityName: String { ProjectPix4dCD.entityName }

    override func convertToModel(_ record: PictorEngineManagedObject) -> PictorProjectPix4dModel? {
        guard let record = record as? ProjectPix4dCD else {
            PictorLogger.shared.e(.tag, "❌💾🗂 Bad managed object of \(entityName)")
            return nil
        }
        return PictorProjectPix4dModel(record: record)
    }

    public func getAll(minDate: Date) -> [PictorProjectPix4dModel] {
        var result: [PictorProjectPix4dModel] = []

        coreDataService.mainContext.performAndWait {
            do {
                let fetchRequest = try fetchRequest(minDate: minDate)
                let fetchResult = try coreDataService.mainContext.fetch(fetchRequest)
                result = convertToModels(fetchResult)
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾🗂 get(minDate:) error: \(error)")
            }
        }

        return result
    }
}

// MARK: - Private
private extension PictorProjectPix4dRepository {
    func fetchRequest(uuids: [String]? = nil,
                      excludedUuids: [String]? = nil,
                      minDate: Date? = nil) throws -> NSFetchRequest<ProjectPix4dCD> {
        guard let sessionCD = getCurrentSessionCD() else {
            PictorLogger.shared.e(.tag, "❌💾🗂 getFetchRequest project error: current session not found")
            throw PictorRepositoryError.noSessionFound
        }

        var subPredicateList: [NSPredicate] = []
        // - user session
        subPredicateList.append(userPredicate(from: sessionCD))
        // - synchro is not deleted
        subPredicateList.append(synchroIsNotDeletedPredicate)
        // - UUIDs
        if let uuids = uuids {
            subPredicateList.append(NSPredicate(format: "uuid IN %@", uuids))
        }
        // - no UUIDs
        if let excludedUuids = excludedUuids {
            subPredicateList.append(NSPredicate(format: "NOT (uuid IN %@)", excludedUuids))
        }
        // - project date
        if let minDate = minDate {
            subPredicateList.append(NSPredicate(format: "projectDate >= %@", minDate as NSDate))
        }

        let fetchRequest = ProjectPix4dCD.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)

        return fetchRequest
    }
}
