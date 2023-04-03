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
    static let tag = "pictor.repository.gutmalink"
}

// MARK: - Protocol
public protocol PictorBaseGutmaLinkRepository: PictorBaseRepository where PictorBaseModelType == PictorGutmaLinkModel {
    /// Get gutma links associated to a specified list of flight.
    ///
    /// - Parameters:
    ///    - flightUuids: list of flight's UUID
    /// - Returns: list of related `PictorGutmaLinkModel`
    func get(byFlightUuids: [String]) -> [PictorGutmaLinkModel]

    /// Get gutma links associated to a specified list of flight plan.
    ///
    /// - Parameters:
    ///    - flightPlanUuids: list of flight plan's UUID
    /// - Returns: list of related `PictorGutmaLinkModel`
    func get(byFlightPlanUuids: [String]) -> [PictorGutmaLinkModel]

    /// Get related flights by flight plan UUID.
    ///
    /// - Parameters:
    ///    - byFlightPlanUuid: UUID of flight plan
    /// - Returns: list of related `PictorFlightModel`
    func getRelatedFlights(byFlightPlanUuid: String) -> [PictorFlightModel]

    /// Get related flight plans by flight UUID.
    ///
    /// - Parameters:
    ///    - byFlightUuid: UUID of flight
    /// - Returns: list of related `PictorFlightPlanModel`
    func getRelatedFlightPlans(byFlightUuid: String) -> [PictorFlightPlanModel]
}

// MARK: - Implementation
public class PictorGutmaLinkRepository: PictorRepository<PictorGutmaLinkModel>, PictorBaseGutmaLinkRepository  {
    private struct AttributeName {
        static var executionDate: String { "executionDate" }
    }

    override var entityName: String { GutmaLinkCD.entityName }

    override func convertToModel(_ record: PictorEngineManagedObject) -> PictorGutmaLinkModel? {
        guard let record = record as? GutmaLinkCD else {
            PictorLogger.shared.e(.tag, "❌💾🔗 Bad managed object of \(entityName)")
            return nil
        }
        return PictorGutmaLinkModel(record: record)
    }

    public func get(byFlightUuids: [String]) -> [PictorGutmaLinkModel] {
        var result: [PictorGutmaLinkModel] = []

        coreDataService.mainContext.performAndWait { [unowned self] in
            do {
                let fetchRequest = try fetchRequest(flightUuids: byFlightUuids,
                                                    sortBy: [(AttributeName.executionDate, false)])
                let fetchResult = try coreDataService.mainContext.fetch(fetchRequest)
                result = convertToModels(fetchResult)
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾🔗 get(byFlightUuids:) error: \(error)")
            }
        }

        return result
    }

    public func get(byFlightPlanUuids: [String]) -> [PictorGutmaLinkModel] {
        var result: [PictorGutmaLinkModel] = []

        coreDataService.mainContext.performAndWait { [unowned self] in
            do {
                let fetchRequest = try fetchRequest(flightPlanUuids: byFlightPlanUuids,
                                                    sortBy: [(AttributeName.executionDate, false)])
                let fetchResult = try coreDataService.mainContext.fetch(fetchRequest)
                result = convertToModels(fetchResult)
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾🔗 get(byFlightPlanUuids:) error: \(error)")
            }
        }

        return result
    }

    public func getRelatedFlights(byFlightPlanUuid: String) -> [PictorFlightModel] {
        var result: [PictorFlightModel] = []

        coreDataService.mainContext.performAndWait { [unowned self] in
            do {
                let fetchRequest = try fetchRequest(flightPlanUuids: [byFlightPlanUuid],
                                                    sortBy: [(AttributeName.executionDate, false)])
                let fetchResult = try coreDataService.mainContext.fetch(fetchRequest)
                let flightUuids = fetchResult.compactMap { $0.flightUuid }
                result = repositories.flight.get(byUuids: flightUuids)
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾🔗 getRelatedFlights(byFlightPlanUuid:) error: \(error)")
            }
        }

        return result
    }

    public func getRelatedFlightPlans(byFlightUuid: String) -> [PictorFlightPlanModel] {
        var result: [PictorFlightPlanModel] = []

        coreDataService.mainContext.performAndWait { [unowned self] in
            do {
                let fetchRequest = try fetchRequest(flightUuids: [byFlightUuid],
                                                    sortBy: [(AttributeName.executionDate, false)])
                let fetchResult = try coreDataService.mainContext.fetch(fetchRequest)
                let flightPlanUuids = fetchResult.compactMap { $0.flightPlanUuid }
                result = repositories.flightPlan.get(byUuids: flightPlanUuids)
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾🔗 getRelatedFlightPlans(byFlightUuid:) error: \(error)")
            }
        }

        return result
    }
}

// MARK: - Private
private extension PictorGutmaLinkRepository {
    func fetchRequest(executionDates: [Date]? = nil,
                      flightUuids: [String]? = nil,
                      flightPlanUuids: [String]? = nil,
                      sortBy: [(attributeName: String, ascending: Bool)] = []) throws -> NSFetchRequest<GutmaLinkCD> {
        guard let sessionCD = getCurrentSessionCD() else {
            PictorLogger.shared.e(.tag, "❌💾🔗 getFetchRequest gutma link error: current session not found")
            throw PictorRepositoryError.noSessionFound
        }

        var subPredicateList: [NSPredicate] = []
        // - user session
        subPredicateList.append(userPredicate(from: sessionCD))
        // - synchro is not deleted
        subPredicateList.append(synchroIsNotDeletedPredicate)
        // - execution dates
        if let executionDates = executionDates {
            subPredicateList.append(NSPredicate(format: "executionDate IN %@", executionDates))
        }
        // - flight UUIDs
        if let flightUuids = flightUuids {
            subPredicateList.append(NSPredicate(format: "flightUuid IN %@", flightUuids))
        }
        // - flight plan UUIDs
        if let flightPlanUuids = flightPlanUuids {
            subPredicateList.append(NSPredicate(format: "flightPlanUuid IN %@", flightPlanUuids))
        }

        let fetchRequest = GutmaLinkCD.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
        // - Sort
        fetchRequest.sortDescriptors = sortBy.map { (attributeName, ascending) in
            NSSortDescriptor.init(key: attributeName, ascending: ascending)
        }
        return fetchRequest
    }
}
