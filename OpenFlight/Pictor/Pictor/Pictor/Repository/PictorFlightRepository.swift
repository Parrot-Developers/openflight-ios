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
    static let tag = "pictor.repository.flight"
}

// MARK: - Pictor flight summary
public struct PictorFlightSummary {
    public var count: Int = 0
    public var duration: Double = 0.0
    public var distance: Double = 0.0
}

// MARK: - Protocol
public protocol PictorBaseFlightRepository: PictorBaseRepository where PictorBaseModelType == PictorFlightModel {
    /// Gets all records without thumbnail.
    ///
    /// - Returns: result with list of records without thumbnail
    func getAllWithoutThumbnail() -> [PictorFlightModel]

    /// Gets summary of all flights.
    ///
    /// - Returns: the summary
    func getAllSummary() -> PictorFlightSummary

    /// Gets summary of flights by uuids.
    ///
    /// - Returns: the summary
    func getAllSummary(byUuids: [String]) -> PictorFlightSummary
}

// MARK: - Implementation
public class PictorFlightRepository: PictorRepository<PictorFlightModel>, PictorBaseFlightRepository  {
    private struct AttributeName {
        static var runDate: String { "runDate" }
    }

    override var sortBy: [(attributeName: String, ascending: Bool)] {
        [(AttributeName.runDate, false)]
    }

    override var entityName: String { FlightCD.entityName }

    override func convertToModel(_ record: PictorEngineManagedObject) -> PictorFlightModel? {
        convertToModels([record]).first
    }

    override func convertToModels(_ records: [PictorEngineManagedObject]) -> [PictorFlightModel] {
        guard let records = records as? [FlightCD] else {
            PictorLogger.shared.e(.tag, "❌💾🗂 Bad managed object of \(entityName)")
            return []
        }

        let allThumbnails = repositories.thumbnail.get(byUuids: records.compactMap { $0.thumbnailUuid })

        return records.compactMap { record in
            let thumbnail = allThumbnails.first(where: { $0.uuid == record.thumbnailUuid })
            return PictorFlightModel(record: record,
                                     thumbnail: thumbnail)
        }
    }

    public func getAllWithoutThumbnail() -> [PictorFlightModel] {
        var result: [PictorFlightModel] = []
        coreDataService.mainContext.performAndWait { [unowned self] in
            do {
                let fetchRequest = try fetchRequest(isThumbnailEmpty: true,
                                                    sortBy: sortBy)

                let fetchResult = try coreDataService.mainContext.fetch(fetchRequest)
                result = convertToModels(fetchResult)
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾✈️ getAllWithoutThumbnail() error: \(error)")
            }
        }

        return result
    }

    public func getAllSummary() -> PictorFlightSummary {
        getAllSummary(uuids: nil)
    }

    public func getAllSummary(byUuids: [String]) -> PictorFlightSummary {
        getAllSummary(uuids: byUuids)
    }
}

// MARK: - Private
private extension PictorFlightRepository {
    func fetchRequest(uuids: [String]? = nil,
                      excludedUuids: [String]? = nil,
                      isThumbnailEmpty: Bool? = nil,
                      sortBy: [(attributeName: String, ascending: Bool)] = []) throws -> NSFetchRequest<FlightCD> {
        guard let sessionCD = getCurrentSessionCD() else {
            PictorLogger.shared.e(.tag, "❌💾✈️ getFetchRequest flight error: current session not found")
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
        // - is thumbnail empty
        if let isThumbnailEmpty = isThumbnailEmpty {
            if isThumbnailEmpty {
                subPredicateList.append(NSPredicate(format: "thumbnailUuid == nil"))
            } else {
                subPredicateList.append(NSPredicate(format: "thumbnailUuid != nil"))
            }
        }

        let fetchRequest = FlightCD.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
        // - Sort
        fetchRequest.sortDescriptors = sortBy.map { (attributeName, ascending) in
            NSSortDescriptor.init(key: attributeName, ascending: ascending)
        }
        return fetchRequest
    }

    func getAllSummary(uuids: [String]?) -> PictorFlightSummary {
        var summary = PictorFlightSummary()

        coreDataService.mainContext.performAndWait { [unowned self] in
            do {
                let fetchRequest = try fetchRequest(uuids: uuids) as! NSFetchRequest<NSFetchRequestResult>

                let countExp = NSExpressionDescription()
                countExp.expression =  NSExpression(forFunction: "count:", arguments:[NSExpression(forKeyPath: "uuid")])
                countExp.name = "count";
                countExp.expressionResultType = .integer64AttributeType
                let durationExp = NSExpressionDescription()
                durationExp.expression =  NSExpression(forFunction: "sum:", arguments:[NSExpression(forKeyPath: "duration")])
                durationExp.name = "durationTotal";
                durationExp.expressionResultType = .doubleAttributeType
                let distanceExp = NSExpressionDescription()
                distanceExp.expression =  NSExpression(forFunction: "sum:", arguments:[NSExpression(forKeyPath: "distance")])
                distanceExp.name = "distanceTotal";
                distanceExp.expressionResultType = .doubleAttributeType

                fetchRequest.propertiesToFetch = [countExp, durationExp, distanceExp]
                fetchRequest.resultType = .dictionaryResultType

                let fetchResult = try coreDataService.mainContext.fetch(fetchRequest)
                if let resultMap = fetchResult[0] as? [String: Any] {
                    summary.count = resultMap["count"] as? Int ?? 0
                    summary.duration = resultMap["durationTotal"] as? Double ?? 0.0
                    summary.distance = resultMap["distanceTotal"] as? Double ?? 0.0
                }
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾✈️ getAllSummary() error: \(error)")
            }
        }

        return summary
    }
}
