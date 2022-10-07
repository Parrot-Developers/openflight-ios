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

// swiftlint:disable file_length

// MARK: - Repository Protocol
public protocol ProjectRepository: AnyObject {
    // MARK: __ Publisher
    /// Publisher notify changes
    var projectsDidChangePublisher: AnyPublisher<Void, Never> { get }

    /// Publishes when some projects are added into repository.
    var projectsAddedPublisher: AnyPublisher<[ProjectModel], Never> { get }

    /// Publishes when some projects are removed from repository.
    var projectsRemovedPublisher: AnyPublisher<[ProjectModel], Never> { get }

    /// Publishes when all projects are removed from repository.
    var allProjectsRemovedPublisher: AnyPublisher<Void, Never> { get }

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
    ///    - completion: The callback returning the status.
    func saveOrUpdateProjects(_ projectModels: [ProjectModel], byUserUpdate: Bool, toSynchro: Bool, completion: ((Bool) -> Void)?)

    /// Update project and associated lfight plans executionRank if needed
    /// If an executed flight plan has a nil executionRank, all of the executed flighplans executionRank are reordered
    /// - Parameters:
    ///     - project: the specified project
    /// - Returns: The updated project
    /// - Description:
    ///     - If a project has executed flight plan and one of them has no executionRank, all executed flight plan
    ///     will be sorted by their custom title in ascending order and the executionRank will be set according to that order
    ///     Project's 'latestExecutionRank' will be set with the highest executionRank if nil.
    func updateExecutionRankIfNeeded(forProject project: ProjectModel) -> ProjectModel

    /// Update project and associated lfight plans executionRank if needed
    /// If an executed flight plan has a nil executionRank, all of the executed flighplans executionRank are reordered
    /// - Parameters:
    ///     - project: the specified project
    ///     - completion: optional closure called when saved in database if update was required
    /// - Returns: The updated project
    /// - Description:
    ///     - If a project has executed flight plan and one of them has no executionRank, all executed flight plan
    ///     will be sorted by their custom title in ascending order and the executionRank will be set according to that order
    ///     Project's 'latestExecutionRank' will be set with the highest executionRank if nil.
    func updateExecutionRankIfNeeded(forProject project: ProjectModel, completion: ((_ project: ProjectModel) -> Void)?) -> ProjectModel

    // MARK: __ Get
    /// Get ProjectModel with cloudId
    /// - Parameter cloudId: Flight's cloudId to search
    /// - Returns ProjectModel object if found
    func getProject(withCloudId cloudId: Int64) -> ProjectModel?

    /// Get ProjectModel with UUID
    /// - Parameter uuid: Flight's UUID to search
    /// - Returns ProjectModel object if found
    func getProject(withUuid uuid: String) -> ProjectModel?

    /// Get ProjectModels with a specified list of UUIDs
    /// - Parameter uuids: List of UUIDs to search
    /// - Returns List of ProjectModels
    func getProjects(withUuids uuids: [String]) -> [ProjectModel]

    /// Get ProjectModel with cloudId
    /// - Parameter cloudId: Project's cloudId to search
    /// - Returns ProjectModel object if not found
    func getProject(withCloudId cloudId: Int) -> ProjectModel?

    /// Get ProjectModel with UUID with its  editable flight plan
    /// - Parameter uuid: Flight's UUID to search
    /// - Returns ProjectModel object with the editable flight plan if found
    func getProjectWithEditable(withUuid uuid: String) -> ProjectModel?

    /// Get ProjectModels with a specified type
    /// - Parameter type: Type of project
    /// - Returns List of ProjectModels
    func getProjects(withType type: String) -> [ProjectModel]

    /// Get ProjectModels with at least one already executed flight plan
    /// - Parameters:
    ///    - offset: offset start in all projects
    ///    - limit: maximum number of projects to get
    /// - Returns List of ProjectModels ordered by descending last execution date with the last executed flight plan
    func getExecutedProjectsWithLatestExecution(offset: Int, limit: Int, withType: ProjectType?) -> [ProjectModel]

    /// Get count of all Projects
    /// - Returns: Count of all Projects
    func getAllProjectsCount() -> Int

    /// Get count of Projects with specific type
    /// - Parameter type: Type of project
    /// - Returns: Count of projects matching type
    func getProjectsCount(withType type: String) -> Int

    /// Get count of  executed Projects with specific type
    /// - Parameter type: Type of project
    /// - Returns: Count of projects matching type
    func getExecutedProjectsCount(withType type: String?) -> Int

    /// Get ProjectModels from all Projects with an editable flight plan in CoreData
    /// - Parameter type: Type of project
    /// - Returns List of ProjectModels
    func getProjectsWithEditable(withType type: String?) -> [ProjectModel]

    /// Get ProjectModels from a specific offset and number of flights with an editable flight plan in CoreData
    /// - Parameters:
    ///    - offset: offset start
    ///    - limit: maximum number of projects to get
    ///    - type: Type of project
    /// - Returns List of ProjectModels
    func getProjectsWithEditable(offset: Int, limit: Int, withType type: String?) -> [ProjectModel]

    /// Get ProjectModels from all Projects in CoreData
    /// - Returns List of ProjectModels
    func getAllProjects() -> [ProjectModel]

    /// Get all ProjectModels to be deleted from Projects in CoreData
    /// - Returns List of ProjectModels
    func getAllProjectsToBeDeleted() -> [ProjectModel]

    /// Get all ProjectModels locally modified from Projects in CoreData
    /// - Returns:  List of ProjectModels
    func getAllModifiedProjects() -> [ProjectModel]

    /// Get projects that are considered odd
    ///     - projects with no editable flight plan
    ///     - projects with multiple editable flight plan
    ///     - projects with empty flight plans
    /// - Parameter completion: the completion closure when finished
    func getOddProjects(_ completion: @escaping (([ProjectModel]) -> Void))

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
    /// - Parameters
    ///     - uuids: List of project's UUID to remove
    ///     - completion: the completion block with the deletion status (`true` in case of successful deletion)
    func deleteOrFlagToDeleteProjects(withUuids uuids: [String], completion: ((_ status: Bool) -> Void)?)

    /// Delete from CoreData the Project with specified `uuid`.
    /// - Parameters:
    ///    - uuid: the  Project's `uuid`
    ///    - completion: the completion block with the deletion status (`true` in case of successful deletion)
    func deleteProject(withUuid uuid: String, completion: ((_ status: Bool) -> Void)?)

    /// Delete Projects from list of UUIDs
    /// - Parameter uuids: List of UUIDs to search
    /// - Note:
    ///     `Delete Rule` for Project's flight plans is set to `Cascade`.
    ///     It means deleting the project will delete its flight plans.
    ///     (Same rule is used for flight plan filghts, thumbnail, etc.)
    func deleteProjects(withUuids uuids: [String])
    func deleteProjects(withUuids uuids: [String], completion: ((_ status: Bool) -> Void)?)

    /// Remove CloudId and SynchroStatus for all Projects
    /// - Parameters:
    ///    - completion: closure called when all projects are updated
    func removeCloudIdForAllProjects(completion: ((_ status: Bool) -> Void)?)

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

    /// Publishes when some projects are added into repository.
    public var projectsAddedPublisher: AnyPublisher<[ProjectModel], Never> {
        return projectsAddedSubject.eraseToAnyPublisher()
    }

    /// Publishes when some projects are removed from repository.
    public var projectsRemovedPublisher: AnyPublisher<[ProjectModel], Never> {
        return projectsRemovedSubject.eraseToAnyPublisher()
    }

    /// Publishes when all projects are removed from repository.
    public var allProjectsRemovedPublisher: AnyPublisher<Void, Never> {
        return allProjectsRemovedSubject.eraseToAnyPublisher()
    }

    // MARK: __ Save Or Update
    public func saveOrUpdateProject(_ projectModel: ProjectModel,
                                    byUserUpdate: Bool,
                                    toSynchro: Bool,
                                    completion: ((_ status: Bool) -> Void)?) {
        var modifDate: Date?
        var isNewProject = false

        performAndSave({ [unowned self] _ in
            var projectObj: Project?
            if let existingProject = getProjectCD(withUuid: projectModel.uuid) {
                projectObj = existingProject
            } else if let newProject = insertNewObject(entityName: Project.entityName) as? Project {
                projectObj = newProject
                isNewProject = true
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

                // Propagate the project addition event.
                if isNewProject { projectsAddedSubject.send([projectModel]) }

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

    public func saveOrUpdateProjects(_ projectModels: [ProjectModel], byUserUpdate: Bool, toSynchro: Bool, completion: ((Bool) -> Void)?) {
        var modifDate: Date?
        var newProjects: [ProjectModel] = []

        let projectUuids = projectModels.compactMap { $0.uuid }
        performAndSave({ [unowned self] _ in
            let projects = getProjectsCD(withUuids: projectUuids)

            for var projectModel in projectModels {
                var isNewProject = false

                var projectObj: Project?
                if let existingProject = projects.first(where: { $0.uuid == projectModel.uuid }) {
                    projectObj = existingProject
                } else if let newProject = insertNewObject(entityName: Project.entityName) as? Project {
                    projectObj = newProject
                    isNewProject = true
                }

                if let project = projectObj {
                    if byUserUpdate {
                        modifDate = Date()
                        projectModel.latestLocalModificationDate = modifDate
                    }
                    if isNewProject {
                        newProjects.append(projectModel)
                    }

                    let logMessage = """
                        🗂⬇️ saveOrUpdateProject: \(project), \
                        byUserUpdate: \(byUserUpdate), toSynchro: \(toSynchro), \
                        projectModel: \(projectModel)
                    """
                    ULog.d(.dataModelTag, logMessage)

                    project.update(fromProjectModel: projectModel)
                }
            }

            return true
        }, { [unowned self] result in
            switch result {
            case .success:
                if let modifDate = modifDate, toSynchro {
                    latestProjectLocalModificationDate.send(modifDate)
                }

                projectsDidChangeSubject.send()

                // Propagate the project addition event.
                if !newProjects.isEmpty { projectsAddedSubject.send(newProjects) }

                completion?(true)
            case .failure(let error):
                let uuids = projectModels.compactMap({ $0.uuid })
                ULog.e(.dataModelTag, "Error saveOrUpdateProject UUIDs: \(uuids.joined(separator: ", ")) - error: \(error)")
                completion?(false)
            }
        })
    }

    public func updateExecutionRankIfNeeded(forProject project: ProjectModel) -> ProjectModel {
        updateExecutionRankIfNeeded(forProject: project, completion: nil)
    }

    public func updateExecutionRankIfNeeded(forProject project: ProjectModel, completion: ((_ project: ProjectModel) -> Void)?) -> ProjectModel {
        var project = project
        var modifDateProject: Date?
        var modifDateFlightPlans: Date?

        performAndSave({ [unowned self] _ in
            guard isUpdateExecutionRankNeeded(forProjectId: project.uuid) else {
                ULog.i(.databaseUpdate, "updateExecutionRankIfNeeded not needed for projectId \(project.uuid)")
                completion?(project)
                return false
            }
            let editableStr = FlightPlanModel.FlightPlanState.editable.rawValue

            guard let projectCD = getProjectCD(withUuid: project.uuid),
                  let flightPlansCD = projectCD.flightPlans else {
                ULog.e(.databaseUpdate, "updateExecutionRankIfNeeded error : no flight plans found for projectId \(project.uuid)")
                completion?(project)
                return false
            }

            let executedFlightPlansCD = flightPlansCD.filter { $0.state != editableStr }
                .sorted {
                    $0.customTitle.compare(
                        $1.customTitle,
                        options: [.diacriticInsensitive, .numeric, .caseInsensitive])
                    == .orderedAscending
                }

            guard !executedFlightPlansCD.isEmpty else {
                ULog.e(.databaseUpdate, "updateExecutionRankIfNeeded error : no executed flight plans found for projectId \(project.uuid)")
                completion?(project)
                return false
            }

            var rank = 0
            // - Reorder all project's flight plans if a nil executionRank is found
            // if flight plans are already reorder, set the rank to the highest executionRank found
            if executedFlightPlansCD.first(where: { $0.executionRank == nil || $0.executionRank == 0 }) != nil {
                rank = 0
                executedFlightPlansCD.forEach {
                    rank += 1
                    $0.executionRank = NSNumber(value: rank)
                }

                // Extract the possible highest index from custom title
                // executionRank will bet set with the index if higher
                // this will avoid weird behavior if executions is reorder and
                // the last execution has title "Execution 54" but has a lower rank like 42
                // the next execution will be "Execution 43" instead of "Execution 55"
                let customTitles = executedFlightPlansCD.compactMap { $0.customTitle }
                if let highestExecutionTitleIndex = customTitles.highestExecutionIndex,
                   rank < highestExecutionTitleIndex {
                    rank = highestExecutionTitleIndex
                    executedFlightPlansCD[executedFlightPlansCD.count - 1].executionRank = NSNumber(value: rank)
                }

                modifDateFlightPlans = Date()
                executedFlightPlansCD.forEach {
                    // Set the executionRank in the json dataSettings
                    if let data = $0.dataString {
                        let dataStr = String(decoding: data, as: UTF8.self)
                        if var dataSetting = FlightPlanDataSetting.instantiate(with: dataStr) {
                            dataSetting.executionRank = $0.executionRank?.intValue
                            $0.dataString = dataSetting.asData
                        }
                    }

                    // Set synchro attributs for incremental synchro
                    $0.latestLocalModificationDate = modifDateFlightPlans
                    $0.synchroStatus = SynchroStatus.notSync.rawValue
                }
            } else {
                rank = executedFlightPlansCD.compactMap { $0.executionRank?.intValue }.max() ?? 0
            }

            let latestExecutionRank = projectCD.latestExecutionRank ?? 0
            if latestExecutionRank.intValue < rank {
                modifDateProject = Date()
                projectCD.latestExecutionRank = NSNumber(value: rank)
                projectCD.latestLocalModificationDate = modifDateProject
                // Set the project model
                project.latestExecutionRank = rank
            }

            ULog.i(.databaseUpdate,
                   "updateExecutionRankIfNeeded: Project \(project.uuid) has reordered its executed flight plans with latestExecutionRank = \(rank)")

            return true
        }, { [unowned self] result in
            switch result {
            case .success:
                projectsDidChangeSubject.send()

                // trigger incremental synchro
                if let modifDateProject = modifDateProject {
                    latestProjectLocalModificationDate.send(modifDateProject)
                }
                if let modifDateFlightPlans = modifDateFlightPlans {
                    latestFlightPlanLocalModificationDate.send(modifDateFlightPlans)
                    flightPlansDidChangeSubject.send()
                }

                ULog.i(.databaseUpdate, "updateExecutionRankIfNeeded: Project \(project.uuid) has been saved in persistentStore")
                completion?(project)
            case .failure(let error):
                ULog.e(.dataModelTag,
                        "updateExecutionRankIfNeeded failed for projectId \(project.uuid): could not save in persistentStore - error: \(error)")
                completion?(project)
            }
        })

        return project
    }

    // MARK: __ Get
    public func getProject(withCloudId cloudId: Int64) -> ProjectModel? {
        return getProjectCD(withCloudId: cloudId)?.model()
    }

    public func getProject(withUuid uuid: String) -> ProjectModel? {
        return getProjectCD(withUuid: uuid)?.model()
    }

    public func getProjects(withUuids uuids: [String]) -> [ProjectModel] {
        return getProjectsCD(withUuids: uuids).map({ $0.modelWithEditableFlightPlan() })
    }

    public func getProjectWithEditable(withUuid uuid: String) -> ProjectModel? {
        return getProjectCD(withUuid: uuid)?.modelWithEditableFlightPlan()
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

    public func getProjectsCount(withType type: String) -> Int {
        return getProjectsCountCD(withType: type, toBeDeleted: false)
    }

    public func getExecutedProjectsCount(withType type: String?) -> Int {
        return getExecutedProjectsCountCD(withType: type, toBeDeleted: false)
    }

    public func getProjectsWithEditable(withType type: String?) -> [ProjectModel] {
        return getProjectsWithEditableCD(withType: type, toBeDeleted: false).map({ $0.modelWithEditableFlightPlan() })
    }

    public func getProjectsWithEditable(offset: Int, limit: Int, withType type: String?) -> [ProjectModel] {
        return getProjectsWithEditableCD(offset: offset, limit: limit, withType: type, toBeDeleted: false).map({ $0.modelWithEditableFlightPlan() })
    }

    public func getAllProjects() -> [ProjectModel] {
        return getAllProjectsCD(toBeDeleted: false).map({ $0.model() })
    }

    public func getAllProjectsToBeDeleted() -> [ProjectModel] {
        return getAllProjectsCD(toBeDeleted: true).map({ $0.model() })
    }

    public func getExecutedProjectsWithLatestExecution(offset: Int, limit: Int, withType: ProjectType?) -> [ProjectModel] {
        let projectsCD = getExecutedProjectsCD(offset: offset, limit: limit, withType: withType?.rawValue, toBeDeleted: false)
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

        var projects: [ProjectModel] = []

        // Get the latest executed flight plan for each project
        projectsCD.forEach { projectCD in
            var project = projectCD.model()

            let latestExecution = projectCD.flightPlans?.filter({ $0.hasReachedFirstWayPoint })
                .sorted(by: {
                    let lastFlightExecutionDate0 = $0.flightPlanFlights?.compactMap { $0.dateExecutionFlight }.max()
                    let lastFlightExecutionDate1 = $1.flightPlanFlights?.compactMap { $0.dateExecutionFlight }.max()
                    return lastFlightExecutionDate0 ?? Date.distantPast > lastFlightExecutionDate1 ?? Date.distantPast
                }).first
            if let latestExecution = latestExecution {
                project.flightPlans = [latestExecution.model()]
            }

            projects.append(project)
        }

        return projects
    }

    public func getAllModifiedProjects() -> [ProjectModel] {
        let apcIdQuery = "apcId == '\(userService.currentUser.apcId)'"
        return getProjectsCD(withQuery: "latestLocalModificationDate != nil && \(apcIdQuery)").map({ $0.model() })
    }

    public func getOddProjects(_ completion: @escaping (([ProjectModel]) -> Void)) {
        getOddProjectsCD { projects in
            let projectModels = projects.compactMap({ $0.modelWithFlightPlan() })
            DispatchQueue.main.async {
                completion(projectModels)
            }
        }
    }

    // MARK: __ __ Get Flight Plan
    public func getFlightPlans(ofProject projectModel: ProjectModel) -> [FlightPlanModel] {
        guard let project = getProjectCD(withUuid: projectModel.uuid),
              let flightPlans = project.flightPlans, !flightPlans.isEmpty else {
                  return []
              }

        return flightPlans
            .map({ $0.model() })
    }

    public func getExecutedFlightPlans(ofProject projectModel: ProjectModel) -> [FlightPlanModel] {
        getFlightPlans(ofProject: projectModel)
            .filter { !$0.isLocalDeleted }
            .filter({ $0.hasReachedFirstWayPoint })
            .sorted {
                /// Sort FlightPlan by executionRank in descending order
                /// if executionRank is nil, sort by custom title in descending order
                guard let executionRank0 = $0.executionRank else {
                    return $0.customTitle.compare(
                        $1.customTitle,
                        options: [.diacriticInsensitive, .numeric, .caseInsensitive])
                        == .orderedDescending }
                guard let executionRank1 = $1.executionRank else { return true }
                return executionRank0 > executionRank1
            }
    }

    // MARK: __ Delete
    public func deleteOrFlagToDeleteProjects(withUuids uuids: [String], completion: ((_ status: Bool) -> Void)?) {
        guard !uuids.isEmpty else {
            completion?(true)
            return
        }
        var modifDate: Date?
        var deletedProjects: [ProjectModel] = []

        performAndSave({ [unowned self] context in
            let projects = getProjectsCD(withUuids: uuids)
            guard !projects.isEmpty else {
                completion?(false)
                return false
            }

            projects.forEach({
                // Check and remove related FlightPlan
                if let flightPlanUuids = $0.flightPlans?.compactMap({ $0.uuid }) {
                    deleteOrFlagToDeleteFlightPlans(withUuids: flightPlanUuids, completion: nil)
                }
                $0.flightPlans = nil

                // delete only if it exists in CoreData
                if $0.cloudId == 0 {
                    context.delete($0)
                } else {
                    modifDate = Date()
                    $0.latestLocalModificationDate = modifDate
                    $0.isLocalDeleted = true
                }
                deletedProjects.append($0.model())
            })

            return true
        }, { [unowned self] result in
            switch result {
            case .success:
                if let modifDate = modifDate {
                    latestProjectLocalModificationDate.send(modifDate)
                }

                self.projectsDidChangeSubject.send()
                // Propagate the projects deletion event.
                if !deletedProjects.isEmpty {
                    projectsRemovedSubject.send(deletedProjects)
                }
                completion?(true)
            case .failure(let error):
                ULog.e(.dataModelTag, "Error deleteAndAddToRemoveProject with UUID: \(uuids.joined(separator: ", ")) - error: \(error.localizedDescription)")
                completion?(false)
            }
        })
    }

    public func deleteProject(withUuid uuid: String, completion: ((_ status: Bool) -> Void)?) {

        performAndSave({ [unowned self] context in
            guard let project = getProjectCD(withUuid: uuid) else {
                completion?(false)
                return false
            }

            ULog.d(.dataModelTag, "🗂🗑 deleteProject, uuid: \(uuid)")
            context.delete(project)
            return true
        }, { [unowned self] result in
            switch result {
            case .success:
                ULog.d(.dataModelTag, "🗂🗑🟢 deleteProject, uuid: \(uuid)")
                projectsDidChangeSubject.send()
                completion?(true)
            case .failure(let error):
                ULog.e(.dataModelTag,
                       "🗂🗑🔴 Error deleteProject, uuid: \(uuid) - error: \(error.localizedDescription)")
                completion?(false)
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

        var deletedProjects = [ProjectModel]()

        performAndSave({ [unowned self] _ in
            let projectsCD = getProjectsCD(withUuids: uuids)
            deletedProjects = projectsCD.map({ $0.model() })
            deleteObjects(projectsCD)
            return true
        }, { [unowned self] result in
            switch result {
            case .success:
                projectsDidChangeSubject.send()
                // Propagate the projects deletion event.
                projectsRemovedSubject.send(deletedProjects)
                completion?(true)
            case .failure(let error):
                ULog.e(.dataModelTag, "Error deleteProject with UUIDs error: \(error.localizedDescription)")
                completion?(false)
            }
        })
    }

    public func removeCloudIdForAllProjects(completion: ((_ status: Bool) -> Void)?) {
        performAndSave({ [unowned self] _ in
            let projectCDs = getAllProjectsCD(toBeDeleted: false)

            for projectCD in projectCDs {
                projectCD.cloudId = 0
                projectCD.synchroStatus = 0
            }

            return true
        }, { result in
            switch result {
            case .success:
                ULog.d(.dataModelTag, "Remove cloudId and synchroStatus for all projects")
                completion?(true)
            case .failure(let error):
                ULog.e(.dataModelTag, "Error remove cloudId and synchroStatus for all projects: \(error.localizedDescription)")
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
        migrateAnonymousDataToLoggedUser(for: entityName) { [unowned self] in
            projectsAddedSubject.send(getProjects(withUuids: $0))
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
        return fetchCount(request: getAllProjectsFetchRequest(toBeDeleted: toBeDeleted))
    }

    func getProjectsCountCD(withType type: String, toBeDeleted: Bool?) -> Int {
        return fetchCount(request: getProjectsFetchRequest(withType: type, toBeDeleted: toBeDeleted))
    }

    func getExecutedProjectsCountCD(withType type: String?, toBeDeleted: Bool?) -> Int {
        return fetchCount(request: getExecutedProjectsFetchRequest(withUuid: nil, type: type, toBeDeleted: toBeDeleted))
    }

    func getAllProjectsCD(toBeDeleted: Bool?) -> [Project] {
        let fetchRequest = getAllProjectsFetchRequest(toBeDeleted: toBeDeleted)

        let lastUpdatedSortDesc = NSSortDescriptor(key: "lastUpdated", ascending: false)
        fetchRequest.sortDescriptors = [lastUpdatedSortDesc]

        return fetch(request: fetchRequest)
    }

    func getProjectsWithEditableCD(withType type: String?, toBeDeleted: Bool?) -> [Project] {
        let fetchRequest = getEditableProjectsFetchRequest(withUuid: nil, type: type, toBeDeleted: toBeDeleted)

        let lastUpdatedSortDesc = NSSortDescriptor(key: "lastUpdated", ascending: false)
        fetchRequest.sortDescriptors = [lastUpdatedSortDesc]

        return fetch(request: fetchRequest)
    }

    func getProjectsWithEditableCD(offset: Int, limit: Int, withType type: String?, toBeDeleted: Bool?) -> [Project] {
        let fetchRequest = getEditableProjectsFetchRequest(withUuid: nil, type: type, toBeDeleted: toBeDeleted)

        let lastUpdatedSortDesc = NSSortDescriptor(key: "lastUpdated", ascending: false)
        fetchRequest.sortDescriptors = [lastUpdatedSortDesc]

        fetchRequest.fetchOffset = max(offset, 0)
        fetchRequest.fetchLimit = max(limit, 1)
        // - fetchRequest gets all items if fetchLimit is 0, in order to avoid some misuse of this method that can get all projects
        // the limit should be limited to 1, use instead an explicit method if it should get all data

        return fetch(request: fetchRequest)
    }

    func getExecutedProjectsCD(withType type: String?, toBeDeleted: Bool?) -> [Project] {
        let fetchRequest = getExecutedProjectsFetchRequest(withUuid: nil, type: type, toBeDeleted: toBeDeleted)

        let lastUpdatedSortDesc = NSSortDescriptor(key: "lastUpdated", ascending: false)
        fetchRequest.sortDescriptors = [lastUpdatedSortDesc]

        return fetch(request: fetchRequest)
    }

    func getExecutedProjectsCD(offset: Int, limit: Int, withType type: String?, toBeDeleted: Bool?) -> [Project] {
        let fetchRequest = getExecutedProjectsFetchRequest(withUuid: nil, type: type, toBeDeleted: toBeDeleted)

        let lastUpdatedSortDesc = NSSortDescriptor(key: "lastUpdated", ascending: false)
        fetchRequest.sortDescriptors = [lastUpdatedSortDesc]

        fetchRequest.fetchOffset = offset >= 0 ? offset : 0
        fetchRequest.fetchLimit = limit >= 1 ? limit : 1
        // - fetchRequest gets all items if fetchLimit is 0

        return fetch(request: fetchRequest)
    }

    func getProjectsCD(withType type: String, toBeDeleted: Bool?) -> [Project] {
        let fetchRequest = getProjectsFetchRequest(withType: type, toBeDeleted: toBeDeleted)

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

    func getOddProjectsCD(_ completion: @escaping (([Project]) -> Void)) {
        let fetchRequest = Project.fetchRequest()

        let editableState = FlightPlanModel.FlightPlanState.editable.rawValue
        let emptyEditablePredicate = NSPredicate(format: "SUBQUERY(flightPlans, $fp, $fp.state CONTAINS \"\(editableState)\").@count == 0")
        let multipleEditablePredicate = NSPredicate(format: "SUBQUERY(flightPlans, $fp, $fp.state CONTAINS \"\(editableState)\").@count > 1")
        let noFlightPlanPredicate = NSPredicate(format: "flightPlans.@count == 0")
        let subPredicateList: [NSPredicate] = [emptyEditablePredicate, multipleEditablePredicate, noFlightPlanPredicate]

        fetchRequest.predicate = NSCompoundPredicate.init(type: .or, subpredicates: subPredicateList)

        let lastUpdatedSortDesc = NSSortDescriptor(key: "lastUpdated", ascending: true)
        fetchRequest.sortDescriptors = [lastUpdatedSortDesc]

        return fetch(request: fetchRequest, completion: completion)
    }
}

// MARK: - Private
private extension CoreDataServiceImpl {
    func getAllProjectsFetchRequest(toBeDeleted: Bool?) -> NSFetchRequest<Project> {
        let fetchRequest = Project.fetchRequest()

        let apcIdPredicate = NSPredicate(format: "apcId == %@", userService.currentUser.apcId)

        if let toBeDeleted = toBeDeleted {
            let parrotToBeDeletedPredicate = NSPredicate(format: "isLocalDeleted == %@", NSNumber(value: toBeDeleted))

            let subPredicateList: [NSPredicate] = [apcIdPredicate, parrotToBeDeletedPredicate]
            let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
            fetchRequest.predicate = compoundPredicates
        } else {
            fetchRequest.predicate = apcIdPredicate
        }

        return fetchRequest
    }

    func getProjectsFetchRequest(withType type: String, toBeDeleted: Bool?) -> NSFetchRequest<Project> {
        let fetchRequest = Project.fetchRequest()

        var subPredicateList: [NSPredicate] = []

        let apcIdPredicate = NSPredicate(format: "apcId == %@", userService.currentUser.apcId)
        subPredicateList.append(apcIdPredicate)

        let typePredicate = NSPredicate(format: "type == %@", type)
        subPredicateList.append(typePredicate)

        if let toBeDeleted = toBeDeleted {
            let parrotToBeDeletedPredicate = NSPredicate(format: "isLocalDeleted == %@", NSNumber(value: toBeDeleted))
            subPredicateList.append(parrotToBeDeletedPredicate)
        }

        let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
        fetchRequest.predicate = compoundPredicates

        return fetchRequest
    }

    func getExecutedProjectsFetchRequest(withUuid uuid: String?, type: String?, toBeDeleted: Bool?) -> NSFetchRequest<Project> {
        let fetchRequest = Project.fetchRequest()

        let apcIdPredicate = NSPredicate(format: "apcId == %@", userService.currentUser.apcId)
        var subPredicateList: [NSPredicate] = [apcIdPredicate]

        let editableState = FlightPlanModel.FlightPlanState.editable.rawValue
        let editablePredicate = NSPredicate(format: "SUBQUERY(flightPlans, $fp, $fp.state CONTAINS \"\(editableState)\").@count > 0")
        subPredicateList.append(editablePredicate)

        let executedPredicate = NSPredicate(format: "SUBQUERY(flightPlans, $fp, $fp.hasReachedFirstWayPoint == YES).@count > 0")
        subPredicateList.append(executedPredicate)

        if let uuid = uuid {
            let uuidPredicate = NSPredicate(format: "uuid == %@", uuid)
            subPredicateList.append(uuidPredicate)
        }
        if let type = type {
            let typePredicate = NSPredicate(format: "type == %@", type)
            subPredicateList.append(typePredicate)
        }
        if let toBeDeleted = toBeDeleted {
            let parrotToBeDeletedPredicate = NSPredicate(format: "isLocalDeleted == %@", NSNumber(value: toBeDeleted))
            subPredicateList.append(parrotToBeDeletedPredicate)
        }

        let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
        fetchRequest.predicate = compoundPredicates

        return fetchRequest
    }

    func getEditableProjectsFetchRequest(withUuid uuid: String?, type: String?, toBeDeleted: Bool?) -> NSFetchRequest<Project> {
        let fetchRequest = Project.fetchRequest()

        let apcIdPredicate = NSPredicate(format: "apcId == %@", userService.currentUser.apcId)
        var subPredicateList: [NSPredicate] = [apcIdPredicate]

        let editableState = FlightPlanModel.FlightPlanState.editable.rawValue
        let editablePredicate = NSPredicate(format: "SUBQUERY(flightPlans, $fp, $fp.state CONTAINS \"\(editableState)\").@count > 0")
        subPredicateList.append(editablePredicate)

        if let uuid = uuid {
            let uuidPredicate = NSPredicate(format: "uuid == %@", uuid)
            subPredicateList.append(uuidPredicate)
        }
        if let type = type {
            let typePredicate = NSPredicate(format: "type == %@", type)
            subPredicateList.append(typePredicate)
        }
        if let toBeDeleted = toBeDeleted {
            let parrotToBeDeletedPredicate = NSPredicate(format: "isLocalDeleted == %@", NSNumber(value: toBeDeleted))
            subPredicateList.append(parrotToBeDeletedPredicate)
        }

        let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
        fetchRequest.predicate = compoundPredicates

        return fetchRequest
    }

    func isUpdateExecutionRankNeeded(forProjectId projectId: String) -> Bool {
        let fetchRequest = Project.fetchRequest()

        let apcIdPredicate = NSPredicate(format: "apcId == %@", userService.currentUser.apcId)
        var subPredicateList: [NSPredicate] = [apcIdPredicate]

        let uuidPredicate = NSPredicate(format: "uuid == %@", projectId)
        subPredicateList.append(uuidPredicate)

        let editableState = FlightPlanModel.FlightPlanState.editable.rawValue
        // swiftlint:disable:next line_length
        let executionRankPredicate = NSPredicate(format: "latestExecutionRank = nil || latestExecutionRank = 0 || SUBQUERY(flightPlans, $fp, ($fp.executionRank = nil || $fp.executionRank = 0) AND $fp.state != \"\(editableState)\" ).@count > 0")
        subPredicateList.append(executionRankPredicate)

        let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
        fetchRequest.predicate = compoundPredicates

        return fetchCount(request: fetchRequest) > 0
    }
}
