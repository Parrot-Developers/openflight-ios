// Copyright (C) 2021 Parrot Drones SAS
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

public protocol ProjectRepository: AnyObject {

    /// Publisher notifys updated projects
    var projectsPublisher: AnyPublisher<[ProjectModel], Never> { get }

    /// Persist or update Project into CoreData
    /// - Parameters:
    ///    - project: ProjectModel to persist
    ///    - byUserUpdate: Bool to indicate in case of modifications, if those are made by User or by synchro process.
    func persist(_ project: ProjectModel, _ byUserUpdate: Bool)

    /// Persist or update ProjectsList into CoreData
    /// - Parameters:
    ///    - projectsList: ProjectsModelsList to persist
    ///    - byUserUpdate: Bool to indicate in case of modifications, if those are made by User or by synchro process.
    func persist(_ projectsList: [ProjectModel], _ byUserUpdate: Bool)

    /// Load Project from CoreData by UUID
    /// - Parameters:
    ///     - projectUuid: projectUuid to search
    ///
    /// - return:  ProjectModel object
    func loadProject(_ projectUuid: String?) -> ProjectModel?

    /// Load Projects flagged tobeDeleted from CoreData
    /// - return:  Projects list
    func loadProjectsToRemove() -> [ProjectModel]

    /// Load Project from CoreData by parrotCloudId
    /// - Parameters:
    ///     - parrotCloudId: int64 value of parrotCloudId
    ///
    /// - return:  ProjectModel object
    func loadProject(_ parrotCloudId: Int64?) -> ProjectModel?

    /// Executed projects
    ///
    /// - Returns: projects containing at least one already executed flight plan,
    /// ordered by last execution date desc
    func executedProjects() -> [ProjectModel]

    /// Load all Projects from CoreData of current user
    /// - return : Array of ProjectModel
    func loadAllProjects() -> [ProjectModel]

    /// Remove Project from CoreData by UUID
    /// - Parameters:
    ///     - projectUuid: projectUuid to remove
    ///
    func removeProject(_ projectUuid: String?)

    /// Fetch flight plans of a project, ordered from newest to oldest
    /// - Parameter project: the project
    func flightPlans(of project: ProjectModel) -> [FlightPlanModel]

    /// Fetch executed flight plans of a project, ordered from newest to oldest
    /// - Parameter project: the project
    func executedFlightPlan(of project: ProjectModel) -> [FlightPlanModel]

    /// Migrate projects made by Anonymous user to current logged user
    /// - Parameter completion: empty block indicates when process is finished
    func migrateProjectsToLoggedUser(_ completion: @escaping () -> Void)

    /// Migrate projects made by a Logged user to ANONYMOUS user
    /// - Parameter completion: empty block indicates when process is finished
    func migrateProjectsToAnonymous(_ completion: @escaping () -> Void)
}

extension CoreDataServiceIml: ProjectRepository {

    public func flightPlans(of project: ProjectModel) -> [FlightPlanModel] {
        self.project("uuid", project.uuid)
            .first?
            .flightPlans?
            .compactMap { $0.model() }
            .sorted(by: { $0.lastUpdate > $1.lastUpdate }) ?? []
    }

    public func executedFlightPlan(of project: ProjectModel) -> [FlightPlanModel] {
        flightPlans(of: project)
            .filter({ $0.lastMissionItemExecuted > 0 })
    }

    public var projectsPublisher: AnyPublisher<[ProjectModel], Never> {
        return projects.eraseToAnyPublisher()
    }

    public func persist(_ project: ProjectModel, _ byUserUpdate: Bool = true) {
        // Prepare content to save.
        guard let managedContext = currentContext else { return }

        // Prepare new CoreData entity
        let projectObject: NSManagedObject?

        // Check object if exists.
        if let object = self.project("uuid", project.uuid).first {
            // Use persisted object.
            projectObject = object
        } else {
            // Create new object.
            let fetchRequest: NSFetchRequest<Project> = Project.fetchRequest()
            guard let name = fetchRequest.entityName else {
                return
            }
            projectObject = NSEntityDescription.insertNewObject(forEntityName: name, into: managedContext)
        }

        guard let projectObj = projectObject as? Project else { return }

        // To ensure synchronisation
        // reset `synchroStatus´ when the modifications made by User
        projectObj.synchroStatus = (((byUserUpdate) ? 0 : project.synchroStatus) ?? 0)
        projectObj.apcId = project.apcId
        projectObj.uuid = project.uuid
        projectObj.title = project.title
        projectObj.type = project.type
        projectObj.lastUpdated = project.lastUpdated
        projectObj.cloudLastUpdate = project.cloudLastUpdate
        projectObj.parrotCloudId = project.parrotCloudId
        projectObj.parrotCloudToBeDeleted = project.parrotCloudToBeDeleted
        projectObj.synchroDate = project.synchroDate
        managedContext.perform {
            do {
                try managedContext.save()
            } catch let error {
                ULog.e(.dataModelTag, "Error during persist Project with UUID \(project.uuid) into Coredata: \(error.localizedDescription)")
            }
        }
    }

    public func persist(_ projectsList: [ProjectModel], _ byUserUpdate: Bool = true) {
        for project in projectsList {
            self.persist(project, byUserUpdate)
        }
    }

    public func loadAllProjects() -> [ProjectModel] {
        // Return projects of current User
        return self.project("apcId", userInformation.apcId).sorted { $0.lastUpdated > $1.lastUpdated }.compactMap({$0.model()})
    }

    public func executedProjects() -> [ProjectModel] {
        self.project("apcId", Services.hub.userInformation.apcId)
            .filter { $0.flightPlans?.contains(where: { $0.lastMissionItemExecuted > 0 }) ?? false }
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

    public func loadProject(_ projectUuid: String?) -> ProjectModel? {
        return self.project("uuid", projectUuid).first?.model()
    }

    public func loadProjectsToRemove() -> [ProjectModel] {
        return self.loadAllProjects().filter({ $0.parrotCloudToBeDeleted })
    }

    public func loadProject(_ parrotCloudId: Int64?) -> ProjectModel? {
        guard let parrotCloudId = parrotCloudId else {
            return nil
        }
        return self.project("parrotCloudId", "\(parrotCloudId)").first?.model()
    }

    public func removeProject(_ projectUuid: String?) {
        guard let managedContext = currentContext,
              let projectUuid = projectUuid,
              let project = self.project("uuid", projectUuid).first else {
            return
        }

        // Remove related FlightPlans and thumbnails if they are not deleted automatically through relationship
        if let relatedFlightPlans = project.flightPlans,
           !relatedFlightPlans.isEmpty {
            relatedFlightPlans.indices.forEach {
                self.removeThumbnail(relatedFlightPlans[$0].thumbnailUuid ?? "")
                relatedFlightPlans[$0].thumbnail = nil
                relatedFlightPlans[$0].thumbnailUuid = nil
                self.removeFlightPlan(relatedFlightPlans[$0].uuid)
            }
            project.flightPlans = nil
        }

        managedContext.delete(project)

        managedContext.perform {
            do {
                try managedContext.save()
            } catch let error {
                ULog.e(.dataModelTag, "Error removing Project with UUID : \(projectUuid) from CoreData : \(error.localizedDescription)")
            }
        }
    }

    /// Listen CoreData's FlightPlanModel add and remove to refresh view.
    @objc func managedObjectContextDidChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }

        // Check inserts.
        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>,
           inserts.contains(where: { $0 is Project }) {
            self.projects.send(self.loadAllProjects())
        } else if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>,
            updates.contains(where: { $0 is Project }) {
            self.projects.send(self.loadAllProjects())
        }// Check deletes.
        else if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>,
            deletes.contains(where: { $0 is Project }) {
            self.projects.send(self.loadAllProjects())
        }
    }

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

// MARK: - Utils
extension CoreDataServiceIml {

    func project(_ key: String?, _ value: String?) -> [Project] {
        guard let managedContext = currentContext,
              let key = key,
              let value = value else {
            return []
        }

        /// Fetch Projects by Key Value
        let fetchRequest: NSFetchRequest<Project> = Project.fetchRequest()
        let predicate = NSPredicate(format: "%K == %@", key, value)
        fetchRequest.predicate = predicate

        var projects = [Project]()

        do {
            projects = try (managedContext.fetch(fetchRequest))
        } catch let error {
            ULog.e(.dataModelTag, "No Project found with \(key): \(value) in CoreData : \(error.localizedDescription)")
            return []
        }

        return projects
    }
}
