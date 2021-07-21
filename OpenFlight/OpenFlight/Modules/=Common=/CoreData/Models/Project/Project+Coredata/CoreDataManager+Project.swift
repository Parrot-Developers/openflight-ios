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

public protocol ProjectRepository: AnyObject {

    /// Persist or update Project into CoreData
    /// - Parameters:
    ///    - project: ProjectModel to persist
    func persist(_ project: ProjectModel)

    /// Persist or update ProjectsList into CoreData
    /// - Parameters:
    ///    - projectsList: ProjectsModelsList to persist
    func persist(_ projectsList: [ProjectModel])

    /// Load Project from CoreData by UUID
    /// - Parameters:
    ///     - projectUuid: projectUuid to search
    ///
    /// - return:  ProjectModel object
    func loadProject(_ projectUuid: String?) -> ProjectModel?

    /// Load all Projects from CoreData
    /// - return : Array of ProjectModel
    func loadAllProjects() -> [ProjectModel]

    /// Remove Project from CoreData by UUID
    /// - Parameters:
    ///     - projectUuid: projectUuid to remove
    ///
    func removeProject(_ projectUuid: String?)
}

public protocol ProjectSynchronizable {
    /// Load ProjectsList to synchronize with Academy from CoreData
    /// - return : Array of ProjectModel not synchronized
    func loadProjectsListToSync() -> [ProjectModel]
}

extension CoreDataManager: ProjectRepository {

    public func persist(_ project: ProjectModel) {
        // Prepare content to save.
        guard let managedContext = currentContext else { return }

        // Prepare new CoreData entity
        let projectObject: NSManagedObject?

        // Check object if exists.
        if let object = self.project(project.uuid) {
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

        projectObj.uuid = project.uuid
        projectObj.title = project.title
        projectObj.type = project.type
        projectObj.lastUpdated = project.lastUpdated
        projectObj.cloudLastUpdate = project.cloudLastUpdate
        projectObj.parrotCloudId = project.parrotCloudId
        projectObj.parrotCloudToBeDeleted = project.parrotCloudToBeDeleted ?? false
        projectObj.synchroDate = project.synchroDate
        projectObj.synchroStatus = project.synchroStatus ?? 0

        /// Sets FlightPlans related to the current Project if they exist
        if let flightPlanModels = project.flightPlanModels {
            for flightPlanModel in flightPlanModels {
                let flightPlan = FlightPlan(context: managedContext)
                flightPlan.parrotCloudId = flightPlanModel.parrotCloudId
                flightPlan.parrotCloudToBeDeleted = flightPlanModel.parrotCloudToBeDeleted ?? false
                flightPlan.parrotCloudUploadUrl = flightPlanModel.parrotCloudUploadUrl
                flightPlan.projectUuid = flightPlanModel.projectUuid
                flightPlan.synchroDate = flightPlanModel.synchroDate
                flightPlan.synchroStatus = flightPlanModel.synchroStatus ?? 0
                flightPlan.dataStringType = flightPlanModel.dataStringType
                flightPlan.uuid = flightPlanModel.uuid
                flightPlan.version = flightPlanModel.version
                flightPlan.customTitle = flightPlanModel.customTitle
                flightPlan.thumbnailUuid = flightPlanModel.thumbnailUuid
                flightPlan.dataString = flightPlanModel.dataString
                flightPlan.pgyProjectId = flightPlanModel.pgyProjectId
                flightPlan.mediaCustomId = flightPlanModel.mediaCustomId
                flightPlan.state = flightPlanModel.state
                flightPlan.lastMissionItemExecuted = flightPlanModel.lastMissionItemExecuted
                flightPlan.recoveryId = flightPlanModel.recoveryId
                flightPlan.mediaCount = flightPlanModel.mediaCount
                flightPlan.uploadedMediaCount = flightPlanModel.uploadedMediaCount
                flightPlan.lastUpdate = flightPlanModel.lastUpdate

                /// Sets thumbnail related to the current FlightPlan if it exists
                if let thumbnailModel = flightPlanModel.thumbnail {
                    let thumbnail = Thumbnail(context: managedContext)
                    thumbnail.uuid = thumbnailModel.uuid
                    thumbnail.thumbnailData = thumbnailModel.thumbnailImageData
                    thumbnail.synchroStatus = thumbnailModel.synchroStatus ?? 0
                    thumbnail.synchroDate = thumbnailModel.synchroDate
                    thumbnail.parrotCloudId = thumbnailModel.parrotCloudId
                    thumbnail.parrotCloudToBeDeleted = thumbnailModel.parrotCloudToBeDeleted ?? false

                    flightPlan.thumbnail = thumbnail
                }

                /// append the current FlightPlan to FlightPlans Set
                projectObj.addToFlightPlan(flightPlan)
            }
        }

        do {
            try managedContext.save()
        } catch let error {
            ULog.e(.dataModelTag, "Error during persist Project into Coredata: \(error.localizedDescription)")
        }
    }

    public func persist(_ projectsList: [ProjectModel]) {
        for project in projectsList {
            self.persist(project)
        }
    }

    public func loadAllProjects() -> [ProjectModel] {
        guard let managedContext = currentContext else {
            return []
        }

        let fetchRequest: NSFetchRequest<Project> = Project.fetchRequest()
        var projects = [ProjectModel]()

        do {
             projects = try managedContext.fetch(fetchRequest).compactMap({$0.model()})
        } catch let error {
            ULog.e(.dataModelTag, "Error fetching Projects from Coredata: \(error.localizedDescription)")
            return []
        }

        /// Load FlightPlan related to each project if is not auto loaded by relationship
        projects.indices.forEach {
            if projects[$0].flightPlanModels == nil {
                projects[$0].flightPlanModels = self.loadFlightPlans("projectUuid", projects[$0].uuid)
            }
        }

        return projects
    }

    public func loadProject(_ projectUuid: String?) -> ProjectModel? {
        return self.project(projectUuid)?.model()
    }

    public func removeProject(_ projectUuid: String?) {
        guard let managedContext = currentContext,
              let projectUuid = projectUuid,
              let project = self.project(projectUuid) else {
            return
        }

        managedContext.delete(project)

        do {
            try managedContext.save()
        } catch let error {
            ULog.e(.dataModelTag, "Error removing Project with UUID : \(projectUuid) from CoreData : \(error.localizedDescription)")
        }
    }
}

extension CoreDataManager: ProjectSynchronizable {

    public func loadProjectsListToSync() -> [ProjectModel] {
        guard let managedContext = currentContext else {
            return []
        }

        let fetchRequest: NSFetchRequest<Project> = Project.fetchRequest()
        let predicate = NSPredicate(format: "synchroStatus == %@", NSNumber(value: false))
        fetchRequest.predicate = predicate

        do {
            return try managedContext.fetch(fetchRequest).compactMap({$0.model()})
        } catch let error {
            ULog.e(.dataModelTag, "Error fetching Projects from Coredata: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - Utils
private extension CoreDataManager {

    func project(_ projectUuid: String?) -> Project? {
        guard let managedContext = currentContext,
              let projectUuid = projectUuid else {
            return nil
        }

        /// Fetch Project by UUID
        let fetchRequest: NSFetchRequest<Project> = Project.fetchRequest()
        let predicate = NSPredicate(format: "uuid == %@", projectUuid)
        fetchRequest.predicate = predicate

        var project: Project?

        do {
            project = try (managedContext.fetch(fetchRequest)).first
        } catch let error {
            ULog.e(.dataModelTag, "No Project found with UUID : \(projectUuid) in CoreData : \(error.localizedDescription)")
            return nil
        }

        /// Load it's FlightPlans if are not auto loaded by relationship
        if project?.flightPlan == nil {
            project?.flightPlan = Set(self.flightPlan(["projectUuid": projectUuid]).map { $0 })
        }
        return project
    }
}
