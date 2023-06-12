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
    static let tag = "pictor.repository.flightplan"
}

// MARK: - Protocol
public protocol PictorBaseFlightPlanRepository: PictorBaseRepository where PictorBaseModelType == PictorFlightPlanModel {
    /// Count flight plans with optional criteria
    ///
    /// - Parameters:
    ///    - uuids: optional list of UUIDs
    ///    - excludedUuids: optional list of UUIDs  to exclude
    ///    - projectUuids: optional list of project UUIDs
    ///    - projectPix4dUuids: optional list of project Pix4D UUIDs
    ///    - states: optional list of states
    ///    - excludedStates: optional list of states to exclude
    ///    - types: optional list of types
    ///    - excludedTypes: optional list of types to exclude
    ///    - hasReachedFirstWaypoint:
    /// - Returns: count result in `Int`
    func count(uuids: [String]?,
               excludedUuids: [String]?,
               projectUuids: [String]?,
               projectPix4dUuids: [String]?,
               states: [PictorFlightPlanModel.State]?,
               excludedStates: [PictorFlightPlanModel.State]?,
               types: [String]?,
               excludedTypes: [String]?,
               hasReachedFirstWaypoint: Bool?) -> Int

    /// Get flight plans with optional criteria
    ///
    /// - Parameters:
    ///    - uuids: optional list of UUIDs
    ///    - excludedUuids: optional list of UUIDs  to exclude
    ///    - projectUuids: optional list of project UUIDs
    ///    - projectPix4dUuids: optional list of project Pix4D UUIDs
    ///    - states: optional list of states
    ///    - excludedStates: optional list of states to exclude
    ///    - types: optional list of types
    ///    - excludedTypes: optional list of types to exclude
    ///    - hasReachedFirstWaypoint:
    /// - Returns: list of `PictorFlightPlanModel`
    func get(uuids: [String]?,
             excludedUuids: [String]?,
             projectUuids: [String]?,
             projectPix4dUuids: [String]?,
             states: [PictorFlightPlanModel.State]?,
             excludedStates: [PictorFlightPlanModel.State]?,
             types: [String]?,
             excludedTypes: [String]?,
             hasReachedFirstWaypoint: Bool?) -> [PictorFlightPlanModel]

    /// Count projects with specified format versions.
    ///
    /// - Parameters:
    ///    - formatVersions: list of format version of flight plan
    /// - Returns: count result in `Int`
    func count(formatVersions: [String]) -> Int

    /// Get projects with specified Pix4d project uuids
    ///
    /// - Parameters:
    ///    - projectPix4dUuids: the uuids of Pix4d projects
    /// - Returns: list of `PictorFlightPlanModel`
    func get(projectPix4dUuids: [String]) -> [PictorFlightPlanModel]

    /// Get projects with specified format versions.
    ///
    /// - Parameters:
    ///    - formatVersions: list of format version of flight plan
    /// - Returns: list of `PictorFlightPlanModel`
    func get(formatVersions: [String]) -> [PictorFlightPlanModel]

    /// Get latest execution with a specified project UUID
    ///
    ///- Parameters:
    ///    - projectUuid: project's UUID to specified
    /// - Returns: `PictorFlightPlanModel`  if found
    func getLatestExecution(projectUuid: String) -> PictorFlightPlanModel?

    /// Get all executions with a specified project UUID
    ///
    ///- Parameters:
    ///    - projectUuid: project's UUID to specified
    /// - Returns: list of `PictorFlightPlanModel`
    func getExecutions(projectUuid: String) -> [PictorFlightPlanModel]

    /// Gets all records without thumbnail.
    ///
    /// - Returns: result with list of records without thumbnail
    func getAllWithoutThumbnail() -> [PictorFlightPlanModel]
}

// MARK: - Implementation
public class PictorFlightPlanRepository: PictorRepository<PictorFlightPlanModel>, PictorBaseFlightPlanRepository  {
    private struct AttributeName {
        static var lastUpdated: String { "lastUpdated" }
        static var executionRank: String { "executionRank" }
        static var name: String { "name" }
    }

    override var sortBy: [(attributeName: String, ascending: Bool)] {
        [(AttributeName.lastUpdated, false)]
    }

    override var entityName: String { FlightPlanCD.entityName }

    override func convertToModel(_ record: PictorEngineManagedObject) -> PictorFlightPlanModel? {
        convertToModels([record]).first
    }

    override func convertToModels(_ records: [PictorEngineManagedObject]) -> [PictorFlightPlanModel] {
        convertToModels(records, withGutmaLinks: true)
    }

    public func count(uuids: [String]?,
                      excludedUuids: [String]?,
                      projectUuids: [String]?,
                      projectPix4dUuids: [String]?,
                      states: [PictorFlightPlanModel.State]?,
                      excludedStates: [PictorFlightPlanModel.State]?,
                      types: [String]?,
                      excludedTypes: [String]?,
                      hasReachedFirstWaypoint: Bool?) -> Int {
        var result = 0

        coreDataService.mainContext.performAndWait { [unowned self] in
            do {
                let fetchRequest = try fetchRequest(uuids: uuids,
                                                    excludedUuids: excludedUuids,
                                                    projectUuids: projectUuids,
                                                    projectPix4dUuids: projectPix4dUuids,
                                                    states: states,
                                                    excludedStates: excludedStates,
                                                    types: types,
                                                    excludedTypes: excludedTypes,
                                                    hasReachedFirstWaypoint: hasReachedFirstWaypoint)

                result = try coreDataService.mainContext.count(for: fetchRequest)
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾📌 count(uuids:excludedUuids:projectUuids:projectPix4dUuids:states:types:excludedTypes:hasReachedFirstWaypoint:) error: \(error)")
            }
        }

        return result
    }

    public func get(uuids: [String]?,
                    excludedUuids: [String]?,
                    projectUuids: [String]?,
                    projectPix4dUuids: [String]?,
                    states: [PictorFlightPlanModel.State]?,
                    excludedStates: [PictorFlightPlanModel.State]?,
                    types: [String]?,
                    excludedTypes: [String]?,
                    hasReachedFirstWaypoint: Bool?) -> [PictorFlightPlanModel] {
        var result: [PictorFlightPlanModel] = []

        coreDataService.mainContext.performAndWait { [unowned self] in
            do {
                let fetchRequest = try fetchRequest(uuids: uuids,
                                                    excludedUuids: excludedUuids,
                                                    projectUuids: projectUuids,
                                                    projectPix4dUuids: projectPix4dUuids,
                                                    states: states,
                                                    excludedStates: excludedStates,
                                                    types: types,
                                                    excludedTypes: excludedTypes,
                                                    hasReachedFirstWaypoint: hasReachedFirstWaypoint,
                                                    sortBy: sortBy)
                let fetchResult = try coreDataService.mainContext.fetch(fetchRequest)
                result = convertToModels(fetchResult)
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾📌 get(uuids:excludedUuids:projectUuids:projectPix4dUuids:states:types:excludedTypes:hasReachedFirstWaypoint:) error: \(error)")
            }
        }

        return result
    }

    public func count(formatVersions: [String]) -> Int {
        var result = 0

        coreDataService.mainContext.performAndWait { [unowned self] in
            do {
                let fetchRequest = try fetchRequest(formatVersions: formatVersions)

                result = try coreDataService.mainContext.count(for: fetchRequest)
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾📌 getCount(formatVersions:) error: \(error)")
            }
        }

        return result
    }

    public func get(projectPix4dUuids: [String]) -> [PictorFlightPlanModel] {
        var result: [PictorFlightPlanModel] = []

        coreDataService.mainContext.performAndWait { [unowned self] in
            do {
                let fetchRequest = try fetchRequest(projectPix4dUuids: projectPix4dUuids,
                                                    sortBy: sortBy)
                let fetchResult = try coreDataService.mainContext.fetch(fetchRequest)
                result = convertToModels(fetchResult)
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾📌 get(projectPix4dUuids:) error: \(error)")
            }
        }

        return result
    }

    public func get(formatVersions: [String]) -> [PictorFlightPlanModel] {
        var result: [PictorFlightPlanModel] = []

        coreDataService.mainContext.performAndWait { [unowned self] in
            do {
                let fetchRequest = try fetchRequest(formatVersions: formatVersions,
                                                    sortBy: sortBy)
                let fetchResult = try coreDataService.mainContext.fetch(fetchRequest)
                result = convertToModels(fetchResult)
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾📌 get(formatVersions:) error: \(error)")
            }
        }

        return result
    }

    public func getLatestExecution(projectUuid: String) -> PictorFlightPlanModel? {
        var result: PictorFlightPlanModel?

        coreDataService.mainContext.performAndWait {
            do {
                let fetchRequest = try fetchRequest(projectUuids: [projectUuid],
                                                    hasReachedFirstWaypoint: true,
                                                    sortBy: [(AttributeName.executionRank, false),
                                                             (AttributeName.name, false)])
                fetchRequest.fetchLimit = 1
                let fetchResult = try coreDataService.mainContext.fetch(fetchRequest)
                if let flightPlanCD = fetchResult.first {
                    result = convertToModel(flightPlanCD)
                }
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾 get(byUuid:) error: \(error)")
            }
        }

        return result
    }

    public func getExecutions(projectUuid: String) -> [PictorFlightPlanModel] {
        var result: [PictorFlightPlanModel] = []

        coreDataService.mainContext.performAndWait {
            do {
                let fetchRequest = try fetchRequest(projectUuids: [projectUuid],
                                                    excludedStates: [.editable],
                                                    hasReachedFirstWaypoint: true,
                                                    sortBy: [(AttributeName.executionRank, false),
                                                             (AttributeName.name, false)])
                let fetchResult = try coreDataService.mainContext.fetch(fetchRequest)
                result = convertToModels(fetchResult)
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾 getExecutions(projectUuid:) error: \(error)")
            }
        }

        return result
    }

    public func getAllWithoutThumbnail() -> [PictorFlightPlanModel] {
        var result: [PictorFlightPlanModel] = []
        coreDataService.mainContext.performAndWait { [unowned self] in
            do {
                let fetchRequest = try fetchRequest(isThumbnailEmpty: true,
                                                    sortBy: sortBy)
                let fetchResult = try coreDataService.mainContext.fetch(fetchRequest)
                result = convertToModels(fetchResult)
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾📌 getAllWithoutThumbnail() error: \(error)")
            }
        }

        return result
    }
}

// MARK: - Private
extension PictorFlightPlanRepository {
    func fetchRequest(uuids: [String]? = nil,
                      excludedUuids: [String]? = nil,
                      projectUuids: [String]? = nil,
                      projectPix4dUuids: [String]? = nil,
                      states: [PictorFlightPlanModel.State]? = nil,
                      excludedStates: [PictorFlightPlanModel.State]? = nil,
                      types: [String]? = nil,
                      excludedTypes: [String]? = nil,
                      hasReachedFirstWaypoint: Bool? = nil,
                      formatVersions: [String]? = nil,
                      isThumbnailEmpty: Bool? = nil,
                      executionRank: [Int?]? = nil,
                      sortBy: [(attributeName: String, ascending: Bool)] = []) throws -> NSFetchRequest<FlightPlanCD> {
        guard let sessionCD = getCurrentSessionCD() else {
            PictorLogger.shared.e(.tag, "❌💾📌 getFetchRequest flight plan error: current session not found")
            throw PictorRepositoryError.noSessionFound
        }

        var subPredicateList: [NSPredicate] = []
        // - user session
        subPredicateList.append(userPredicate(from: sessionCD))
        // - synchro is not deleted
        subPredicateList.append(synchroIsNotDeletedPredicate)
        // - check for projectUuid to nil or empty
        subPredicateList.append(NSPredicate(format: "projectUuid != nil AND projectUuid != %@", ""))
        // - UUIDs
        if let uuids = uuids {
            subPredicateList.append(NSPredicate(format: "uuid IN %@", uuids))
        }
        // - no UUIDs
        if let excludedUuids = excludedUuids {
            subPredicateList.append(NSPredicate(format: "NOT (uuid IN %@)", excludedUuids))
        }
        // - project UUIDs
        if let projectUuids = projectUuids {
            subPredicateList.append(NSPredicate(format: "projectUuid IN %@", projectUuids))
        }
        // - projectPix4d UUIDs
        if let projectPix4dUuids = projectPix4dUuids {
            subPredicateList.append(NSPredicate(format: "projectPix4dUuid IN %@", projectPix4dUuids))
        }
        // - states
        if let states = states {
            let rawStates = states.compactMap { $0.rawValue }
            subPredicateList.append(NSPredicate(format: "state IN %@", rawStates))
        }
        // - no states
        if let excludedStates = excludedStates {
            let rawExcludedStates = excludedStates.compactMap { $0.rawValue }
            subPredicateList.append(NSPredicate(format: "NOT (state IN %@)", rawExcludedStates))
        }
        // - types
        if let types = types {
            subPredicateList.append(NSPredicate(format: "flightPlanType IN %@", types))
        }
        // - no types
        if let excludedTypes = excludedTypes {
            subPredicateList.append(NSPredicate(format: "NOT (flightPlanType IN %@)", excludedTypes))
        }
        // - has reached first waypoint
        if let hasReachedFirstWaypoint = hasReachedFirstWaypoint {
            subPredicateList.append(NSPredicate(format: "hasReachedFirstWaypoint = %@", NSNumber(value: hasReachedFirstWaypoint)))
        }
        // - format versions
        if let formatVersions = formatVersions {
            subPredicateList.append(NSPredicate(format: "formatVersion IN %@", formatVersions))
        }
        // - is thumbnail empty
        if let isThumbnailEmpty = isThumbnailEmpty {
            if isThumbnailEmpty {
                subPredicateList.append(NSPredicate(format: "thumbnailUuid == nil"))
            } else {
                subPredicateList.append(NSPredicate(format: "thumbnailUuid != nil"))
            }
        }
        // - execution rank
        if let executionRank = executionRank {
            subPredicateList.append(NSPredicate(format: "executionRank IN %@", executionRank))
        }

        let fetchRequest = FlightPlanCD.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
        // - Sort
        fetchRequest.sortDescriptors = sortBy.map { (attributeName, ascending) in
            NSSortDescriptor.init(key: attributeName, ascending: ascending)
        }
        return fetchRequest
    }

    func convertToModels(_ records: [PictorEngineManagedObject], withGutmaLinks: Bool) -> [PictorFlightPlanModel] {
        guard let records = records as? [FlightPlanCD] else {
            PictorLogger.shared.e(.tag, "❌💾📌 Bad managed object of \(entityName)")
            return []
        }

        var allUuids: [String] = []
        var allThumbnailUuids: [String] = []
        records.forEach {
            allUuids.append($0.uuid)
            if let thumbnailUuid = $0.thumbnailUuid {
                allThumbnailUuids.append(thumbnailUuid)
            }
        }
        let allThumbnails = repositories.thumbnail.get(byUuids: allThumbnailUuids)
        var allGutmaLinks: [PictorGutmaLinkModel] = []
        if withGutmaLinks {
            allGutmaLinks = repositories.gutmaLink.get(byFlightPlanUuids: allUuids)
        }

        return records.compactMap { record in
            let thumbnail = allThumbnails.first(where: { $0.uuid == record.thumbnailUuid })
            let gutmaLinks = allGutmaLinks.filter { $0.flightPlanUuid == record.uuid }
            return PictorFlightPlanModel(record: record,
                                         thumbnail: thumbnail,
                                         gutmaLinks: gutmaLinks)
        }
    }
}

