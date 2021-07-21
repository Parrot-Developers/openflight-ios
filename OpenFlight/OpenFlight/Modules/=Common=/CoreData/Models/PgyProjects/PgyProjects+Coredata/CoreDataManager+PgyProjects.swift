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

public protocol PgyProjectsRepository: AnyObject {

    /// Persist or update pgyProjects into CoreData
    /// - Parameters:
    ///     - pgyProjects: PgyProjectsModel to persist
    func persist(_ pgyProjects: PgyProjectsModel)

    /// Persist or update pgyProjects list into CoreData
    /// - Parameters:
    ///     - pgyProjectsList: PgyProjectsModel list to persist
    func persist(_ pgyProjectsList: [PgyProjectsModel])

    /// Load PgyProjects by pgyProjectsId from CoreData
    /// return PgyProjectsModel if exist
    /// - Parameters:
    ///     - pgyProjectsId: identifier to load
    func loadPgyProjects(_ pgyProjectsId: Int64) -> PgyProjectsModel?

    /// Load all pgyProjects from CoreData
    /// return PgyProjectsModel list if exist
    func loadAllPgyProjects() -> [PgyProjectsModel]

    /// Remove PgyProjects by pgyProjectsId from CoreData
    /// - Parameters:
    ///     - pgyProjectsId: pgyProjectsIdProject identifier to remove
    func removePgyProjects(_ pgyProjectId: Int64)
}

public protocol PgyProjectsSynchronizable {

    /// Load PgyProjectsList to synchronize with Academy from CoreData
    /// - return : Array of PgyProjectsModel not synchronized
    func loadPgyProjectsListToSync() -> [PgyProjectsModel]
}

extension CoreDataManager: PgyProjectsRepository {

    public func persist(_ pgyProjects: PgyProjectsModel) {
        // Prepare content to save.
        guard let managedContext = currentContext else { return }

        // Prepare new CoreData entity
        let pgyProjectsObject: NSManagedObject?

        // Check object if exists.
        if let object = self.pgyProjects(pgyProjects.pgyProjectId) {
            // Use persisted object.
            pgyProjectsObject = object
        } else {
            // Create new object.
            let fetchRequest: NSFetchRequest<PgyProjects> = PgyProjects.fetchRequest()
            guard let name = fetchRequest.entityName else {
                return
            }
            pgyProjectsObject = NSEntityDescription.insertNewObject(forEntityName: name, into: managedContext)
        }

        guard let pgyProjectsObj = pgyProjectsObject as? PgyProjects else { return }

        pgyProjectsObj.cloudToBeDeleted = pgyProjects.cloudToBeDeleted
        pgyProjectsObj.pgyProjectId = pgyProjects.pgyProjectId
        pgyProjectsObj.name = pgyProjects.name
        pgyProjectsObj.processingCalled = pgyProjects.processingCalled
        pgyProjectsObj.projectDate = pgyProjects.projectDate
        pgyProjectsObj.synchroDate = pgyProjects.synchroDate
        pgyProjectsObj.synchroStatus = pgyProjects.synchroStatus ?? 0

        do {
            try managedContext.save()
        } catch let error {
            ULog.e(.dataModelTag, "Error during persist PgyProjects into Coredata: \(error.localizedDescription)")
        }
    }

    public func persist(_ pgyProjectsList: [PgyProjectsModel]) {
        for pgyProjects in pgyProjectsList {
            self.persist(pgyProjects)
        }
    }

    public func loadPgyProjects(_ pgyProjectsId: Int64) -> PgyProjectsModel? {
        return self.pgyProjects(pgyProjectsId)?.model()
    }

    public func loadAllPgyProjects() -> [PgyProjectsModel] {
        guard let managedContext = currentContext else {
            return []
        }

        let fetchRequest: NSFetchRequest<PgyProjects> = PgyProjects.fetchRequest()

        do {
            return try managedContext.fetch(fetchRequest).compactMap({$0.model()})
        } catch let error {
            ULog.e(.dataModelTag, "Error fetching PgyProjects from Coredata: \(error.localizedDescription)")
            return []
        }
    }

    public func removePgyProjects(_ pgyProjectId: Int64) {
        guard let managedContext = currentContext,
              let pgyProjects = self.pgyProjects(pgyProjectId) else {
            return
        }

        managedContext.delete(pgyProjects)

        do {
            try managedContext.save()
        } catch let error {
            ULog.e(.dataModelTag, "Error removing PgyProjects with pgyProjectId : \(pgyProjectId) from CoreData : \(error.localizedDescription)")
        }
    }
}

extension CoreDataManager: PgyProjectsSynchronizable {

    public func loadPgyProjectsListToSync() -> [PgyProjectsModel] {
        guard let managedContext = currentContext else {
            return []
        }

        let fetchRequest: NSFetchRequest<PgyProjects> = PgyProjects.fetchRequest()
        let predicate = NSPredicate(format: "synchroStatus == %@", NSNumber(value: false))
        fetchRequest.predicate = predicate

        do {
            return try managedContext.fetch(fetchRequest).compactMap({$0.model()})
        } catch let error {
            ULog.e(.dataModelTag, "Error fetching PgyProjects from Coredata: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - Utils
private extension CoreDataManager {

    func pgyProjects(_ pgyProjectId: Int64) -> PgyProjects? {
        guard let managedContext = currentContext else {
            return nil
        }

        /// Fetch PgyProjects by pgyProjectsId
        let fetchRequest: NSFetchRequest<PgyProjects> = PgyProjects.fetchRequest()
        let predicate = NSPredicate(format: "pgyProjectId == %i", pgyProjectId)
        fetchRequest.predicate = predicate

        do {
            return try (managedContext.fetch(fetchRequest)).first
        } catch let error {
            ULog.e(.dataModelTag, "No PgyProjects found with pgyProjectId : \(pgyProjectId) in CoreData : \(error.localizedDescription)")
            return nil
        }
    }
}
