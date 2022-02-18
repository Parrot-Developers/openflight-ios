//    Copyright (C) 2021 Parrot Drones SAS
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
import GroundSdk
import Combine

// MARK: - Repository Protocol
public protocol ProjectRepository: AnyObject {
    // MARK: __ Publisher
    /// Publisher notify changes
    var projectsDidChangePublisher: AnyPublisher<Void, Never> { get }

    // MARK: __ Save or Update
    /// Save or update Project into CoreData from ProjectModel
    /// - Parameters:
    ///    - projectModel: ProjectModel to save or update
    ///    - byUserUpdate: Boolean if updated by user interaction
    ///    - toSynchro: Boolean if should be synchro
    func saveOrUpdateProject(_ projectModel: ProjectModel, byUserUpdate: Bool, toSynchro: Bool)

    /// Save or update Project into CoreData from ProjectModel
    /// - Parameters:
    ///    - projectModel: ProjectModel to save or update
    ///    - byUserUpdate: Boolean if updated by user interaction
    ///    - toSynchro: Boolean if should be synchro
    ///    - completion: The callback returning the status.
    func saveOrUpdateProject(_ projectModel: ProjectModel,
                             byUserUpdate: Bool,
                             toSynchro: Bool,
                             completion: ((_ status: Bool) -> Void)?)

    /// Save or update Projects into CoreData from list of ProjectModels
    /// - Parameters:
    ///    - projectModels: List of ProjectModels to save or update
    ///    - byUserUpdate: Boolean if updated by user interaction
    ///    - toSynchro: Boolean if should be synchro
    func saveOrUpdateProjects(_ projectModels: [ProjectModel], byUserUpdate: Bool, toSynchro: Bool)

    /// Reset CloudId and synchro flag of Project from UUIDs
    /// - Parameter uuids: List of UUIDs to search
    func resetProjectsCloudId(withUuids uuids: [String])

    // MARK: __ Get
    /// Get ProjectModel with cloudId
    /// - Parameter cloudId: Flight's cloudId to search
    /// - Returns ProjectModel object if not found
    func getProject(withCloudId cloudId: Int64) -> ProjectModel?

    /// Get ProjectModel with UUID
    /// - Parameter uuid: Flight's UUID to search
    /// - Returns ProjectModel object if not found
    func getProject(withUuid uuid: String) -> ProjectModel?

    /// Get ProjectModels with a specified list of UUIDs
    /// - Parameter uuids: List of UUIDs to search
    /// - Returns List of ProjectModels
    func getProjects(withUuids uuids: [String]) -> [ProjectModel]

    /// Get ProjectModel with cloudId
    /// - Parameter cloudId: Project's cloudId to search
    /// - Returns ProjectModel object if not found
    func getProject(withCloudId cloudId: Int) -> ProjectModel?

    /// Get ProjectModels with a specified type
    /// - Parameter type: Type of project
    /// - Returns List of ProjectModels
    func getProjects(withType type: String) -> [ProjectModel]

    /// Get ProjectModels with at least one already executed flight plan
    /// - Returns List of ProjectModels ordered by descending last execution date
    func getExecutedProjects() -> [ProjectModel]

    /// Get count of all Projects
    /// - Returns: Count of all Projects
    func getAllProjectsCount() -> Int

    /// Get ProjectModels from all Projects in CoreData
    /// - Returns List of ProjectModels
    func getAllProjects() -> [ProjectModel]

    /// Get all ProjectModels to be deleted from Projects in CoreData
    /// - Returns List of ProjectModels
    func getAllProjectsToBeDeleted() -> [ProjectModel]

    /// Get all ProjectModels locally modified from Projects in CoreData
    /// - Returns:  List of ProjectModels
    func getAllModifiedProjects() -> [ProjectModel]

    // MARK: __ __ Get Flight Plans
    /// Get FlightPlanModels of ProjectModel
    /// - Parameter projectModel: specified ProjectModel
    /// - Returns List of FlightPlanModel ordered from newest to oldest
    func getFlightPlans(ofProject projectModel: ProjectModel) -> [FlightPlanModel]

    /// Get executed FlightPlanModels of ProjectModel
    /// - Parameter projectModel: specified ProjectModel
    /// - Returns List of FlightPlanModel ordered from newest to oldest
    func getExecutedFlightPlans(ofProject projectModel: ProjectModel) -> [FlightPlanModel]

    // MARK: __ Delete
    /// Delete Project from UUID
    /// - Parameter uuid: Project's UUID to search
    func deleteOrFlagToDeleteProject(withUuid uuid: String)

    /// Delete Projects from list of UUIDs
    /// - Parameter uuids: List of UUIDs to search
    /// - Note:
    ///     `Delete Rule` for Project's flight plans is set to `Cascade`.
    ///     It means deleting the project will delete its flight plans.
    ///     (Same rule is used for flight plan filghts, thumbnail, etc.)
    func deleteProjects(withUuids uuids: [String])
    func deleteProjects(withUuids uuids: [String], completion: ((_ status: Bool) -> Void)?)

    // MARK: __ Related
    /// Migrate projects made by Anonymous user to current logged user
    /// - Parameter completion: empty block indicates when process is finished
    func migrateProjectsToLoggedUser(_ completion: @escaping () -> Void)

    /// Migrate projects made by a Logged user to ANONYMOUS user
    /// - Parameter completion: empty block indicates when process is finished
    func migrateProjectsToAnonymous(_ completion: @escaping () -> Void)
}

extension CoreDataServiceImpl: ProjectRepository {

    public var projectsDidChangePublisher: AnyPublisher<Void, Never> {
        return projectsDidChangeSubject.eraseToAnyPublisher()
    }

    // MARK: __ Save Or Update
    public func saveOrUpdateProject(_ projectModel: ProjectModel,
                                    byUserUpdate: Bool,
                                    toSynchro: Bool,
                                    completion: ((_ status: Bool) -> Void)?) {
        var modifDate: Date?

        performAndSave({ [unowned self] _ in
            var projectObj: Project?
            if let existingProject = getProjectCD(withUuid: projectModel.uuid) {
                projectObj = existingProject
            } else if let newProject = insertNewObject(entityName: Project.entityName) as? Project {
                projectObj = newProject
            }

            guard let project = projectObj else {
                completion?(false)
                return false
            }

            var projectModel = projectModel

            if byUserUpdate {
                modifDate = Date()
                projectModel.latestLocalModificationDate = modifDate
            }

            let logMessage = """
                🗂⬇️ saveOrUpdateProject: \(project), \
                byUserUpdate: \(byUserUpdate), toSynchro: \(toSynchro), \
                projectModel: \(projectModel)
                """
            ULog.d(.dataModelTag, logMessage)

            project.update(fromProjectModel: projectModel)

            return true
        }, { [unowned self] result in
            switch result {
            case .success:
                if let modifDate = modifDate, toSynchro {
                    latestProjectLocalModificationDate.send(modifDate)
                }

                projectsDidChangeSubject.send()

                completion?(true)
            case .failure(let error):
                ULog.e(.dataModelTag, "Error saveOrUpdateProject UUID: \(projectModel.uuid) - error: \(error)")
                completion?(false)
            }
        })
    }

    public func saveOrUpdateProject(_ projectModel: ProjectModel, byUserUpdate: Bool, toSynchro: Bool) {
        saveOrUpdateProject(projectModel, byUserUpdate: byUserUpdate, toSynchro: toSynchro, completion: nil)
    }

    public func saveOrUpdateProjects(_ projectModels: [ProjectModel], byUserUpdate: Bool, toSynchro: Bool) {
        for projectModel in projectModels {
            saveOrUpdateProject(projectModel, byUserUpdate: byUserUpdate, toSynchro: false)
        }
        if byUserUpdate && toSynchro {
            self.latestProjectLocalModificationDate.send(Date())
        }
    }

    public func resetProjectsCloudId(withUuids uuids: [String]) {
        let projects = getProjectsCD(withUuids: uuids)

        if !projects.isEmpty {
            projects.forEach {
                $0.cloudId = 0
                $0.synchroStatus = 0
            }

            saveContext {
                if case .failure(let error) = $0 {
                    ULog.e(.dataModelTag, "Error resetProjectsCloudId: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: __ Get
    public func getProject(withCloudId cloudId: Int64) -> ProjectModel? {
        return getProjectCD(withCloudId: cloudId)?.model()
    }

    public func getProject(withUuid uuid: String) -> ProjectModel? {
        return getProjectCD(withUuid: uuid)?.model()
    }

    public func getProjects(withUuids uuids: [String]) -> [ProjectModel] {
        return getProjectsCD(withUuids: uuids).map({ $0.model() })
    }

    public func getProject(withCloudId cloudId: Int) -> ProjectModel? {
        return getProjectCD(withCloudId: Int64(cloudId))?.model()
    }

    public func getProjects(withType type: String) -> [ProjectModel] {
        return getProjectsCD(withType: type, toBeDeleted: false).map({ $0.model() })
    }

    public func getAllProjectsCount() -> Int {
        return getAllProjectsCountCD(toBeDeleted: false)
    }

    public func getAllProjects() -> [ProjectModel] {
        return getAllProjectsCD(toBeDeleted: false).map({ $0.model() })
    }

    public func getAllProjectsToBeDeleted() -> [ProjectModel] {
        return getAllProjectsCD(toBeDeleted: true).map({ $0.model() })
    }

    public func getExecutedProjects() -> [ProjectModel] {
        return getAllProjectsCD(toBeDeleted: false)
            .filter {
                $0.flightPlans?.contains(where: {
                    $0.lastMissionItemExecuted > 0 && $0.model().hasReachedFirstWayPoint
                }) ?? false }
            .sorted { project1, project2 in
                let date1 = project1.flightPlans?
                    .compactMap { $0.flightPlanFlights?.compactMap { $0.ofFlight?.startTime }.max() }
                    .max()
                let date2 = project2.flightPlans?
                    .compactMap { $0.flightPlanFlights?.compactMap { $0.ofFlight?.startTime }.max() }
                    .max()
                guard let date1 = date1 else { return false }
                guard let date2 = date2 else { return true }
                return date1 > date2
            }
            .map { $0.model() }
    }

    public func getAllModifiedProjects() -> [ProjectModel] {
        return getProjectsCD(withQuery: "latestLocalModificationDate != nil").map({ $0.model() })
    }

    // MARK: __ __ Get Flight Plan
    public func getFlightPlans(ofProject projectModel: ProjectModel) -> [FlightPlanModel] {
        guard let project = getProjectCD(withUuid: projectModel.uuid),
              let flightPlans = project.flightPlans, !flightPlans.isEmpty else {
                  return []
              }

        return flightPlans
            .map({ $0.model() })
            .sorted(by: { $0.lastUpdate > $1.lastUpdate })
    }

    public func getExecutedFlightPlans(ofProject projectModel: ProjectModel) -> [FlightPlanModel] {
        getFlightPlans(ofProject: projectModel)
            .filter({ $0.hasReachedFirstWayPoint })
            .sorted {
                ($0.lastFlightExecutionDate ?? Date.distantPast, $0.lastUpdate, $0.uuid) >
                ($1.lastFlightExecutionDate ?? Date.distantPast, $1.lastUpdate, $1.uuid)
            }
    }

    // MARK: __ Delete
    public func deleteOrFlagToDeleteProject(withUuid uuid: String) {
        var modifDate: Date?

        performAndSave({ [unowned self] context in
            guard let project = getProjectCD(withUuid: uuid) else {
                return false
            }

            // Check and remove related FlightPlan
            project.flightPlans?.forEach({
                deleteOrFlagToDeleteFlightPlan(withUuid: $0.model().uuid)
            })
            project.flightPlans = nil

            // delete only if it exists in CoreData
            if project.cloudId == 0 {
                context.delete(project)
            } else {
                modifDate = Date()
                project.latestLocalModificationDate = modifDate
                project.isLocalDeleted = true
            }

            return true
        }, { [unowned self] result in
            switch result {
            case .success:
                if let modifDate = modifDate {
                    latestProjectLocalModificationDate.send(modifDate)
                }

                self.projectsDidChangeSubject.send()
            case .failure(let error):
                ULog.e(.dataModelTag, "Error deleteAndAddToRemoveProject with UUID: \(uuid) - error: \(error.localizedDescription)")
            }
        })
    }

    public func deleteProjects(withUuids uuids: [String]) {
        deleteProjects(withUuids: uuids, completion: nil)
    }

    public func deleteProjects(withUuids uuids: [String], completion: ((_ status: Bool) -> Void)?) {
        guard !uuids.isEmpty else {
            completion?(true)
            return
        }

        performAndSave({ context in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Project.entityName)
            let uuidPredicate = NSPredicate(format: "uuid IN %@", uuids)
            fetchRequest.predicate = uuidPredicate

            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try context.execute(deleteRequest)
                return true
            } catch let error {
                ULog.e(.dataModelTag, "An error is occured when batch delete Project in CoreData : \(error.localizedDescription)")
                completion?(false)
                return false
            }
        }, { [unowned self] result in
            switch result {
            case .success:
                projectsDidChangeSubject.send()
                completion?(true)
            case .failure(let error):
                ULog.e(.dataModelTag, "Error deleteProject with UUIDs error: \(error.localizedDescription)")
                completion?(false)
            }
        })
    }

    // MARK: __ Related
    public func migrateProjectsToLoggedUser(_ completion: @escaping () -> Void) {
        let fetchRequest: NSFetchRequest<Project> = Project.fetchRequest()
        guard let entityName = fetchRequest.entityName else {
            return
        }
        migrateAnonymousDataToLoggedUser(for: entityName) {
            completion()
        }
    }

    public func migrateProjectsToAnonymous(_ completion: @escaping () -> Void) {
        let fetchRequest: NSFetchRequest<Project> = Project.fetchRequest()
        guard let entityName = fetchRequest.entityName else {
            return
        }
        migrateLoggedToAnonymous(for: entityName) {
            completion()
        }
    }
}

// MARK: - Internal
internal extension CoreDataServiceImpl {
    func getAllProjectsCountCD(toBeDeleted: Bool?) -> Int {
        let fetchRequest = Project.fetchRequest()

        let apcIdPredicate = NSPredicate(format: "apcId == %@", userInformation.apcId)

        if let toBeDeleted = toBeDeleted {
            let parrotToBeDeletedPredicate = NSPredicate(format: "isLocalDeleted == %@", NSNumber(value: toBeDeleted))

            let subPredicateList: [NSPredicate] = [apcIdPredicate, parrotToBeDeletedPredicate]
            let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
            fetchRequest.predicate = compoundPredicates
        } else {
            fetchRequest.predicate = apcIdPredicate
        }

        let lastUpdatedSortDesc = NSSortDescriptor(key: "lastUpdated", ascending: false)
        fetchRequest.sortDescriptors = [lastUpdatedSortDesc]

        return fetchCount(request: fetchRequest)
    }

    func getAllProjectsCD(toBeDeleted: Bool?) -> [Project] {
        let fetchRequest = Project.fetchRequest()

        let apcIdPredicate = NSPredicate(format: "apcId == %@", userInformation.apcId)

        if let toBeDeleted = toBeDeleted {
            let parrotToBeDeletedPredicate = NSPredicate(format: "isLocalDeleted == %@", NSNumber(value: toBeDeleted))

            let subPredicateList: [NSPredicate] = [apcIdPredicate, parrotToBeDeletedPredicate]
            let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
            fetchRequest.predicate = compoundPredicates
        } else {
            fetchRequest.predicate = apcIdPredicate
        }

        let lastUpdatedSortDesc = NSSortDescriptor(key: "lastUpdated", ascending: false)
        fetchRequest.sortDescriptors = [lastUpdatedSortDesc]

        return fetch(request: fetchRequest)
    }

    func getProjectsCD(withType type: String, toBeDeleted: Bool?) -> [Project] {
        let fetchRequest = Project.fetchRequest()

        var subPredicateList: [NSPredicate] = []

        let apcIdPredicate = NSPredicate(format: "apcId == %@", userInformation.apcId)
        subPredicateList.append(apcIdPredicate)

        let typePredicate = NSPredicate(format: "type == %@", type)
        subPredicateList.append(typePredicate)

        if let toBeDeleted = toBeDeleted {
            let parrotToBeDeletedPredicate = NSPredicate(format: "isLocalDeleted == %@", NSNumber(value: toBeDeleted))
            subPredicateList.append(parrotToBeDeletedPredicate)
        }

        let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
        fetchRequest.predicate = compoundPredicates

        let lastUpdatedSortDesc = NSSortDescriptor(key: "lastUpdated", ascending: false)
        fetchRequest.sortDescriptors = [lastUpdatedSortDesc]

        return fetch(request: fetchRequest)
    }

    func getProjectCD(withCloudId cloudId: Int64) -> Project? {
        let fetchRequest = Project.fetchRequest()
        let uuidPredicate = NSPredicate(format: "cloudId == %@", "\(cloudId)")

        fetchRequest.predicate = uuidPredicate

        let lastUpdatedSortDesc = NSSortDescriptor(key: "lastUpdated", ascending: false)
        fetchRequest.sortDescriptors = [lastUpdatedSortDesc]
        fetchRequest.fetchLimit = 1

        return fetch(request: fetchRequest).first
    }

    func getProjectCD(withUuid uuid: String) -> Project? {
        let fetchRequest = Project.fetchRequest()
        let uuidPredicate = NSPredicate(format: "uuid == %@", uuid)

        fetchRequest.predicate = uuidPredicate

        let lastUpdatedSortDesc = NSSortDescriptor(key: "lastUpdated", ascending: false)
        fetchRequest.sortDescriptors = [lastUpdatedSortDesc]
        fetchRequest.fetchLimit = 1

        return fetch(request: fetchRequest).first
    }

    func getProjectsCD(withUuids uuids: [String]) -> [Project] {
        guard !uuids.isEmpty else {
            return []
        }

        let fetchRequest = Project.fetchRequest()

        var subPredicateList = [NSPredicate]()
        for uuid in uuids {
            let uuidPredicate = NSPredicate(format: "uuid == %@", uuid)
            subPredicateList.append(uuidPredicate)
        }

        fetchRequest.predicate = NSCompoundPredicate.init(type: .or, subpredicates: subPredicateList)

        let lastUpdatedSortDesc = NSSortDescriptor(key: "lastUpdated", ascending: false)
        fetchRequest.sortDescriptors = [lastUpdatedSortDesc]

        return fetch(request: fetchRequest)
    }

    func deleteProjectsCD(_ projects: [Project]) {
        guard !projects.isEmpty else {
            return
        }

        delete(projects) { error in
            var uuidsStr = "[ "
            projects.forEach({ uuidsStr += "\($0.uuid ?? "-") "})
            uuidsStr += "]"

            ULog.e(.dataModelTag, "Error deleteProjectsCD \(uuidsStr): \(error.localizedDescription)")
        }
    }

    func getProjectsCD(withQuery query: String) -> [Project] {
        objects(withQuery: query)
    }
}
