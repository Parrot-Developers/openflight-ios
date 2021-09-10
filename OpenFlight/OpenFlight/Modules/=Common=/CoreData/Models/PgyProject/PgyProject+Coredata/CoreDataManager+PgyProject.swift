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

public protocol PgyProjectRepository: AnyObject {

    /// Persist or update pgyProjects into CoreData
    /// - Parameters:
    ///     - pgyProject: PgyProjectModel to persist
    ///     - byUserUpdate: Bool to indicate in case of modifications, if those are made by User or by synchro process.
    func persist(_ pgyProject: PgyProjectModel, _ byUserUpdate: Bool)

    /// Persist or update pgyProjects list into CoreData
    /// - Parameters:
    ///     - pgyProjectList: PgyProjectModel list to persist
    ///     - byUserUpdate: Bool to indicate in case of modifications, if those are made by User or by synchro process.
    func persist(_ pgyProjectList: [PgyProjectModel], _ byUserUpdate: Bool)

    /// Load PgyProject by pgyProjectsId from CoreData
    /// return PgyProjectModel if exist
    /// - Parameters:
    ///     - pgyProjectId: identifier to load
    func loadPgyProject(_ pgyProjectsId: Int64) -> PgyProjectModel?

    /// Load all PgyProject from CoreData
    /// return PgyProjectModel list if exist
    func loadAllPgyProject() -> [PgyProjectModel]

    /// Load PgyProject flagged tobeDeleted from CoreData
    /// - return: PgyProjectModel list
    func loadPgyProjectToRemove() -> [PgyProjectModel]

    /// Load PgyProject by Key and Value from CoreData
    /// - Parameters:
    ///     - key: Key of PgyProject to load
    ///     - value: Value of PgyProject to load
    /// - return: PgyProjectModel list
    func loadPgyProject(_ key: String, _ value: String) -> [PgyProjectModel]

    /// Remove PgyProject by pgyProjectsId from CoreData
    /// - Parameters:
    ///     - pgyProjectId: pgyProjectIdProject identifier to remove
    func removePgyProject(_ pgyProjectId: Int64)
}

extension CoreDataServiceIml: PgyProjectRepository {

    public func persist(_ pgyProject: PgyProjectModel, _ byUserUpdate: Bool = true) {
        // Prepare content to save.
        guard let managedContext = currentContext else { return }

        // Prepare new CoreData entity
        let pgyProjectObject: NSManagedObject?

        // Check object if exists.
        if let object = self.pgyProjects("pgyProjectId", "\(pgyProject.pgyProjectId)").first {
            // Use persisted object.
            pgyProjectObject = object
        } else {
            // Create new object.
            let fetchRequest: NSFetchRequest<PgyProject> = PgyProject.fetchRequest()
            guard let name = fetchRequest.entityName else {
                return
            }
            pgyProjectObject = NSEntityDescription.insertNewObject(forEntityName: name, into: managedContext)
        }

        guard let pgyProjectObj = pgyProjectObject as? PgyProject else { return }

        // To ensure synchronisation
        // reset `synchroStatus´ when the modifications made by User
        pgyProjectObj.synchroStatus = ((byUserUpdate) ? 0 : pgyProject.synchroStatus) ?? 0
        pgyProjectObj.apcId = pgyProject.apcId
        pgyProjectObj.cloudToBeDeleted = pgyProject.cloudToBeDeleted
        pgyProjectObj.pgyProjectId = pgyProject.pgyProjectId
        pgyProjectObj.name = pgyProject.name
        pgyProjectObj.processingCalled = pgyProject.processingCalled
        pgyProjectObj.projectDate = pgyProject.projectDate
        pgyProjectObj.synchroDate = pgyProject.synchroDate

        managedContext.perform {
            do {
                try managedContext.save()
            } catch let error {
                ULog.e(.dataModelTag, "Error during persist PgyProject into Coredata: \(error.localizedDescription)")
            }
        }
    }

    public func persist(_ pgyProjectList: [PgyProjectModel], _ byUserUpdate: Bool = true) {
        for pgyProject in pgyProjectList {
            self.persist(pgyProject, byUserUpdate)
        }
    }

    public func loadPgyProject(_ pgyProjectId: Int64) -> PgyProjectModel? {
        return self.pgyProjects("pgyProjectId", "\(pgyProjectId)").first?.model()
    }

    public func loadPgyProject(_ key: String, _ value: String) -> [PgyProjectModel] {
        return self.pgyProjects(key, value).compactMap({ $0.model() })
    }

    public func loadAllPgyProject() -> [PgyProjectModel] {
        return self.pgyProjects("apcId", userInformation.apcId).compactMap({ $0.model() })
    }

    public func loadPgyProjectToRemove() -> [PgyProjectModel] {
        return self.loadAllPgyProject().filter({ $0.cloudToBeDeleted })
    }

    public func removePgyProject(_ pgyProjectId: Int64) {
        guard let managedContext = currentContext,
              let pgyProject = self.pgyProjects("pgyProjectId", "\(pgyProjectId)").first else {
            return
        }

        managedContext.delete(pgyProject)

        do {
            try managedContext.save()
        } catch let error {
            ULog.e(.dataModelTag, "Error removing PgyProject with pgyProjectId : \(pgyProjectId) from CoreData : \(error.localizedDescription)")
        }
    }
}

// MARK: - Utils
private extension CoreDataServiceIml {

    func pgyProjects(_ key: String? = nil, _ value: String? = nil) -> [PgyProject] {
        guard let managedContext = currentContext else {
            return []
        }

        /// Fetch PgyProjects
        let fetchRequest: NSFetchRequest<PgyProject> = PgyProject.fetchRequest()
        if let key = key,
           let value = value {
            let predicate = NSPredicate(format: "%K == %@", key, value)
            fetchRequest.predicate = predicate
        }

        do {
            return try (managedContext.fetch(fetchRequest))
        } catch let error {
            ULog.e(.dataModelTag, "No PgyProjects found with \(key ?? ""): \(value ?? "") in CoreData : \(error.localizedDescription)")
            return []
        }
    }
}
