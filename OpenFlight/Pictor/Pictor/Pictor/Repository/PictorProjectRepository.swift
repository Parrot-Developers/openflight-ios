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
    static let tag = "pictor.repository.project"
}

// MARK: - Protocol
public protocol PictorBaseProjectRepository: PictorBaseRepository where PictorBaseModelType == PictorProjectModel {
    /// Count projects with specified type.
    ///
    /// - Parameters:
    ///    - type: type of project to fetch
    ///    - hasExecutedFlightPlans: optional boolean if has executed flight plans
    /// - Returns: count result in `Int`
    func count(type: PictorProjectModel.ProjectType?, hasExecutedFlightPlans: Bool?) -> Int

    /// Get projects with specified type.
    ///
    /// - Parameters:
    ///    - type: type of project to fetch
    /// - Returns: list of `PictorProjectModel`
    func get(type: PictorProjectModel.ProjectType?, hasExecutedFlightPlans: Bool?) -> [PictorProjectModel]

    /// Get the latest opened project or the latest updated if none.
    ///
    /// - Parameters:
    ///    - byUuid: UUID to fetch
    ///    - isUpdateExecutionRankNeeded: boolean if execution index needs to be updated
    /// - Returns: `PictorProjectModel` if found
    func get(byUuid: String, isUpdateExecutionRankNeeded: Bool) -> PictorProjectModel?

    /// Get the latest opened project or the latest updated if none.
    ///
    /// - Parameters:
    ///    - type: type of project to fetch
    /// - Returns: `PictorProjectModel` if found
    func getLatestOpened(type: PictorProjectModel.ProjectType) -> PictorProjectModel?

    /// Get list of all project titles that contains a specified `String` and can excludes uuids in request.
    ///
    /// - Parameters:
    ///    - like: `String` to specified
    ///    - excludedUuids: list of UUIDs to exclude
    /// - Returns: list of `String` that contains the parameter `like`
    func getTitles(like: String, excludedUuids: [String]?) -> [String]

    /// Get all project's titles.
    ///
    /// - Returns: list of `String` of all project's title
    func getAllTitles() -> [String]

    /// Get list of projects with offset `from` and `count` per request with a specified type.
    ///
    /// - Parameters:
    ///    - from: offset of request
    ///    - count: number of records to fetch
    ///    - type: optional type of project to fetch
    ///    - hasExecutedFlightPlans: optional boolean if has executed flight plans
    /// - Returns: list of `PictorProjectModel`
    func get(from: Int,
             count: Int,
             type: PictorProjectModel.ProjectType?,
             hasExecutedFlightPlans: Bool?) -> [PictorProjectModel]
}

// MARK: - Implementation
public class PictorProjectRepository: PictorRepository<PictorProjectModel>, PictorBaseProjectRepository  {
    private struct AttributeName {
        static var lastUpdated: String { "lastUpdated" }
        static var lastOpened: String { "lastOpened" }
        static var latestExecutedFlightPlanDate: String { "latestExecutedFlightPlanDate" }
    }

    override var sortBy: [(attributeName: String, ascending: Bool)] {
        [(attributeName: AttributeName.lastUpdated, ascending: false)]
    }

    override var entityName: String { ProjectCD.entityName }

    override func convertToModel(_ record: PictorEngineManagedObject) -> PictorProjectModel? {
        return convertToModels([record]).first
    }

    override func convertToModels(_ records: [PictorEngineManagedObject]) -> [PictorProjectModel] {
        guard let records = records as? [ProjectCD] else {
            PictorLogger.shared.e(.tag, "❌💾🗂 Bad managed object of \(entityName)")
            return []
        }
        guard !records.isEmpty else {
            return []
        }

        let projectUuids = records.compactMap { $0.uuid }
        let editableFlightPlans = repositories.flightPlan.get(uuids: nil,
                                                              excludedUuids: nil,
                                                              projectUuids: projectUuids,
                                                              projectPix4dUuids: nil,
                                                              states: [.editable],
                                                              types: nil,
                                                              excludedTypes: nil,
                                                              hasReachedFirstWaypoint: nil)

        return records.compactMap { record in
            let editableFlightPlan = editableFlightPlans.first(where: { $0.projectUuid == record.uuid })
            let latestExecution = repositories.flightPlan.getLatestExecution(projectUuid: record.uuid)
            return PictorProjectModel(record: record,
                                      editableFlightPlan: editableFlightPlan,
                                      latestExecutedFlightPlan: latestExecution)
        }
    }

    public func count(type: PictorProjectModel.ProjectType?, hasExecutedFlightPlans: Bool?) -> Int {
        var result = 0
        var types: [PictorProjectModel.ProjectType]?
        if let type = type {
            types = [type]
        }

        coreDataService.mainContext.performAndWait {
            do {
                let fetchRequest = try fetchRequest(types: types,
                                                    hasLatestExecutedFlightPlanDate: hasExecutedFlightPlans)
                result = try coreDataService.mainContext.count(for: fetchRequest)
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾🗂 count(type:) error: \(error)")
            }
        }

        return result
    }

    public func get(type: PictorProjectModel.ProjectType?, hasExecutedFlightPlans: Bool?) -> [PictorProjectModel] {
        var result: [PictorProjectModel] = []
        var types: [PictorProjectModel.ProjectType]?
        if let type = type {
            types = [type]
        }

        coreDataService.mainContext.performAndWait {
            do {
                let projects = try fetchProjects(types: types,
                                                 hasLatestExecutedFlightPlanDate: hasExecutedFlightPlans,
                                                 sortBy: sortBy)
                result = convertToModels(projects)
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾🗂 get(type:) error: \(error)")
            }
        }

        return result
    }

    public func get(byUuid: String, isUpdateExecutionRankNeeded: Bool) -> PictorProjectModel? {
        var result: PictorProjectModel?

        coreDataService.mainContext.performAndWait {
            do {
                let fetchRequest = try fetchRequest(uuids: [byUuid])
                fetchRequest.fetchLimit = 1
                if let projectCD = try coreDataService.mainContext.fetch(fetchRequest).first {
                    let flightPlansRequest = try repositories.flightPlan.fetchRequest(projectUuids: [projectCD.uuid],
                                                                                      excludedStates: [.editable],
                                                                                      executionRank: [nil, 0])
                    if try coreDataService.mainContext.count(for: flightPlansRequest) > 0 {
                        result = convertToModel(projectCD)
                    }
                }
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾🗂 getLatestOpened() error: \(error)")
            }
        }

        return result
    }

    public func getLatestOpened(type: PictorProjectModel.ProjectType) -> PictorProjectModel? {
        var result: PictorProjectModel?

        coreDataService.mainContext.performAndWait {
            do {
                let fetchRequest = try fetchRequest(types: [type],
                                                    sortBy: [(attributeName: AttributeName.lastOpened, ascending: false),
                                                             (attributeName: AttributeName.lastUpdated, ascending: false)])
                fetchRequest.fetchLimit = 1
                if let projectCD = try coreDataService.mainContext.fetch(fetchRequest).first {
                    result = convertToModel(projectCD)
                }
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾🗂 getLatestOpened() error: \(error)")
            }
        }

        return result
    }

    public func getTitles(like: String, excludedUuids: [String]?) -> [String] {
        var result: [String] = []

        coreDataService.mainContext.performAndWait {
            do {
                let projects = try fetchProjects(excludedUuids: excludedUuids,
                                                 likeTitle: like,
                                                 sortBy: sortBy)
                result = projects.compactMap { $0.title }
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾🗂 get(likeTitle:excludedUuids:) error: \(error)")
            }
        }

        return result
    }

    public func getAllTitles() -> [String] {
        var result: [String] = []

        coreDataService.mainContext.performAndWait {
            do {
                result = try fetchProjects(sortBy: sortBy).compactMap { $0.title }
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾🗂 getAllTitles() error: \(error)")
            }
        }

        return result
    }

    public func get(from: Int,
                    count: Int,
                    type: PictorProjectModel.ProjectType?,
                    hasExecutedFlightPlans: Bool?) -> [PictorProjectModel] {
        var result: [PictorProjectModel] = []
        var types: [PictorProjectModel.ProjectType]?
        if let type = type {
            types = [type]
        }

        coreDataService.mainContext.performAndWait {
            do {
                let fetchRequest = try fetchRequest(types: types,
                                                    hasLatestExecutedFlightPlanDate: hasExecutedFlightPlans,
                                                    sortBy: sortBy)
                fetchRequest.fetchOffset = max(from, 0)
                fetchRequest.fetchLimit = max(count, 1)
                let projects = try coreDataService.mainContext.fetch(fetchRequest)
                result = convertToModels(projects)
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾🗂 get(from:count:type:) error: \(error)")
            }
        }

        return result
    }
}

// MARK: - Private
private extension PictorProjectRepository {
    func fetchProjects(uuids: [String]? = nil,
                       excludedUuids: [String]? = nil,
                       types: [PictorProjectModel.ProjectType]? = nil,
                       excludedTypes: [String]? = nil,
                       likeTitle: String? = nil,
                       hasExecutionIndex: Bool? = nil,
                       hasLatestExecutedFlightPlanDate: Bool? = nil,
                       sortBy: [(attributeName: String, ascending: Bool)] = []) throws -> [ProjectCD] {
        let fetchRequest = try fetchRequest(uuids: uuids,
                                            excludedUuids: excludedUuids,
                                            types: types,
                                            excludedTypes: excludedTypes,
                                            likeTitle: likeTitle,
                                            hasExecutionIndex: hasExecutionIndex,
                                            hasLatestExecutedFlightPlanDate: hasExecutionIndex,
                                            sortBy: sortBy)
        return try coreDataService.mainContext.fetch(fetchRequest)
    }

    func fetchRequest(uuids: [String]? = nil,
                      excludedUuids: [String]? = nil,
                      types: [PictorProjectModel.ProjectType]? = nil,
                      excludedTypes: [String]? = nil,
                      likeTitle: String? = nil,
                      hasExecutionIndex: Bool? = nil,
                      hasLatestExecutedFlightPlanDate: Bool? = nil,
                      sortBy: [(attributeName: String, ascending: Bool)] = []) throws -> NSFetchRequest<ProjectCD> {
        guard let sessionCD = getCurrentSessionCD() else {
            PictorLogger.shared.e(.tag, "❌💾🗂 getFetchRequest project error: current session not found")
            throw PictorRepositoryError.noSessionFound
        }

        var subPredicateList: [NSPredicate] = []
        // - user session
        subPredicateList.append(userPredicate(from: sessionCD))
        // - synchro is not deleted
        subPredicateList.append(synchroIsNotDeletedPredicate)
        // - editable
        subPredicateList.append(NSPredicate(format: "hasEditableFlightPlan = %@", NSNumber(booleanLiteral: true)))
        // - UUIDs
        if let uuids = uuids {
            subPredicateList.append(NSPredicate(format: "uuid IN %@", uuids))
        }
        // - no UUIDs
        if let excludedUuids = excludedUuids {
            subPredicateList.append(NSPredicate(format: "NOT (uuid IN %@)", excludedUuids))
        }
        // - types
        if let types = types {
            let rawTypes = types.compactMap { $0.rawValue }
            subPredicateList.append(NSPredicate(format: "type IN %@", rawTypes))
        }
        // - no types
        if let excludedTypes = excludedTypes {
            subPredicateList.append(NSPredicate(format: "NOT (type IN %@)", excludedTypes))
        }
        // - like title
        if let likeTitle = likeTitle {
            subPredicateList.append(NSPredicate(format: "title CONTAINS[cd] %@", likeTitle))
        }
        // - execution index
        if let hasExecutionIndex = hasExecutionIndex {
            if hasExecutionIndex {
                subPredicateList.append(NSPredicate(format: "latestExecutionIndex > 0"))
            } else {
                subPredicateList.append(NSPredicate(format: "latestExecutionIndex = nil || latestExecutionIndex = 0"))
            }
        }
        // - has latest executed flight plan date
        if let hasLatestExecutedFlightPlanDate = hasLatestExecutedFlightPlanDate {
            if hasLatestExecutedFlightPlanDate {
                subPredicateList.append(NSPredicate(format: "latestExecutedFlightPlanDate != nil"))
            } else {
                subPredicateList.append(NSPredicate(format: "latestExecutedFlightPlanDate = nil"))
            }
        }

        let fetchRequest = ProjectCD.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
        // - Sort
        fetchRequest.sortDescriptors = sortBy.map { (attributeName, ascending) in
            NSSortDescriptor.init(key: attributeName, ascending: ascending)
        }
        return fetchRequest
    }
}
