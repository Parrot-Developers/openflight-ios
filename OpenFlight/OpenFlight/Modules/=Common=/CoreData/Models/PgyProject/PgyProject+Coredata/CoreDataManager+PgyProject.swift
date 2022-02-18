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
public protocol PgyProjectRepository: AnyObject {
    /// Publisher notify changes
    var pgyProjectsDidChangePublisher: AnyPublisher<Void, Never> { get }

    // MARK: __ Save Or Update
    /// Save or update PgyProject into CoreData from PgyProjectModel
    /// - Parameters:
    ///    - pgyProjectModel: PgyProjectModel to save or update
    ///    - byUserUpdate: Boolean if updated by user interaction
    ///    - toSynchro: Boolean if should be synchro
    func saveOrUpdatePgyProject(_ pgyProjectModel: PgyProjectModel, byUserUpdate: Bool, toSynchro: Bool)

    /// Save or update PgyProject into CoreData from PgyProjectModel
    /// - Parameters:
    ///    - pgyProjectModel: PgyProjectModel to save or update
    ///    - byUserUpdate: Boolean if updated by user interaction
    ///    - toSynchro: Boolean if should be synchro
    ///    - completion: The callback returning the status.
    func saveOrUpdatePgyProject(_ pgyProjectModel: PgyProjectModel,
                                byUserUpdate: Bool,
                                toSynchro: Bool,
                                completion: ((_ status: Bool) -> Void)?)

    /// Save or update PgyProjects into CoreData from list of PgyProjectModels
    /// - Parameters:
    ///    - pgyProjectModels: List of PgyProjectModels to save or update
    ///    - byUserUpdate: Boolean if updated by user interaction
    ///    - toSynchro: Boolean if should be synchro
    func saveOrUpdatePgyProjects(_ pgyProjectModels: [PgyProjectModel], byUserUpdate: Bool, toSynchro: Bool)

    /// Save or update PgyProjects into CoreData from list of PgyProjectModels
    /// - Parameters:
    ///    - pgyProjectModels: List of PgyProjectModels to save or update
    ///    - byUserUpdate: Boolean if updated by user interaction
    ///    - toSynchro: Boolean if should be synchro
    ///    - completion: The callback returning the status.
    func saveOrUpdatePgyProjects(_ pgyProjectModels: [PgyProjectModel],
                                 byUserUpdate: Bool,
                                 toSynchro: Bool,
                                 completion: ((_ status: Bool) -> Void)?)

    /// Update PgyProject CoreData object to be deleted
    /// - Parameter projectId: project ID to be updated
    func updatePgyProjectToBeDeleted(withProjectId projectId: Int64)

    // MARK: __ Get
    /// Get PgyProjectModel with project ID
    /// - Parameter projectId: PgyProject's ID to search
    /// - Returns PgyProjectModel object if not found
    func getPgyProject(withProjectId projectId: Int64) -> PgyProjectModel?

    /// Get all PgyProjectModels from anonymous user
    /// - Returns List of PgyProjectModels
    func getAllAnonymousPgyProjects(anonymousId: String?) -> [PgyProjectModel]

    /// Get count of all PgyProjects
    /// - Returns: Count of all PgyProjects
    func getAllPgyProjectsCount() -> Int

    /// Get all PgyProjectModels from all PgyProjects in CoreData
    /// - Returns List of PgyProjectModels
    func getAllPgyProjects() -> [PgyProjectModel]

    /// Get all PgyProjectModels to be deleted from PgyProjects in CoreData
    /// - Returns List of PgyProjectModels
    func getAllPgyProjectsToBeDeleted() -> [PgyProjectModel]

    // MARK: __ Delete
    /// Delete PgyProject in CoreData with a specified list of project IDs
    /// - Parameter projectIds: List of project IDs to search
    func deletePgyProjects(withProjectIds projectIds: [Int64])

    /// Delete PgyProject in CoreData withproject ID
    /// - Parameters:
    ///     - projectId: project ID to remove
    ///     - updateRelatedFlightPlan: update related FlightPlan if it exist
    func deletePgyProject(withProjectId projectId: Int64, updateRelatedFlightPlan: Bool)
}

extension CoreDataServiceImpl: PgyProjectRepository {
    public var pgyProjectsDidChangePublisher: AnyPublisher<Void, Never> {
        return pgyProjectsDidChangeSubject.eraseToAnyPublisher()
    }

    // MARK: __ Save Or Update
    public func saveOrUpdatePgyProject(_ pgyProjectModel: PgyProjectModel,
                                       byUserUpdate: Bool,
                                       toSynchro: Bool,
                                       completion: ((_ status: Bool) -> Void)?) {
        var modifDate: Date?

        performAndSave({ [unowned self] _ in
            var pgyProjectObj: PgyProject?
            if let existingPgyProject = getPgyProjectCD(withProjectId: pgyProjectModel.pgyProjectId) {
                pgyProjectObj = existingPgyProject
            } else if let newPgyProject = insertNewObject(entityName: PgyProject.entityName) as? PgyProject {
                pgyProjectObj = newPgyProject
            }

            guard let pgyProject = pgyProjectObj else {
                completion?(false)
                return false
            }

            var pgyProjectModel = pgyProjectModel

            if byUserUpdate {
                modifDate = Date()
                pgyProjectModel.latestLocalModificationDate = modifDate
            }

            let logMessage = """
                🗂⬇️ saveOrUpdatePgyProject: \(pgyProject), \
                byUserUpdate: \(byUserUpdate), toSynchro: \(toSynchro), \
                projectModel: \(pgyProjectModel)
                """
            ULog.d(.dataModelTag, logMessage)

            pgyProject.update(fromPgyProjectModel: pgyProjectModel)

            return true
        }, { [unowned self] result in
            switch result {
            case .success:
                if let modifDate = modifDate, toSynchro {
                    latestPgyProjectLocalModificationDate.send(modifDate)
                }

                pgyProjectsDidChangeSubject.send()

                completion?(true)
            case .failure(let error):
                ULog.e(.dataModelTag,
                        "Error Core Data saveOrUpdatePgyProject projectId: \(pgyProjectModel.pgyProjectId) - error: \(error.localizedDescription)")
                completion?(false)
            }
        })
    }

    public func saveOrUpdatePgyProject(_ pgyProjectModel: PgyProjectModel,
                                       byUserUpdate: Bool,
                                       toSynchro: Bool) {
        saveOrUpdatePgyProject(pgyProjectModel, byUserUpdate: byUserUpdate, toSynchro: toSynchro, completion: nil)
    }

    public func saveOrUpdatePgyProjects(_ pgyProjectModels: [PgyProjectModel], byUserUpdate: Bool, toSynchro: Bool) {
        for pgyProjectModel in pgyProjectModels {
            saveOrUpdatePgyProject(pgyProjectModel, byUserUpdate: byUserUpdate, toSynchro: toSynchro)
        }
    }

    public func saveOrUpdatePgyProjects(_ pgyProjectModels: [PgyProjectModel],
                                        byUserUpdate: Bool,
                                        toSynchro: Bool,
                                        completion: ((_ status: Bool) -> Void)?) {
        var status = true
        pgyProjectModels.enumerated()
            .forEach { (index, pgyProject) in
                saveOrUpdatePgyProject(pgyProject,
                                       byUserUpdate: byUserUpdate,
                                       toSynchro: toSynchro) {
                    status = $0 && status
                    if index == pgyProjectModels.endIndex-1 {
                        completion?(status)
                    }
                }
            }
    }

    public func updatePgyProjectToBeDeleted(withProjectId projectId: Int64) {
        guard let currentContext = currentContext,
              let pgyProject = getPgyProjectCD(withProjectId: projectId) else {
                  return
              }

        pgyProject.isLocalDeleted = true
        let currentDate = Date()
        pgyProject.latestLocalModificationDate = currentDate

        do {
            try currentContext.save()
        } catch let error {
            ULog.e(.dataModelTag, "Error deletePgyProject with projectId: \(projectId) - error: \(error.localizedDescription)")
        }
    }

    // MARK: __ Get
    public func getPgyProject(withProjectId projectId: Int64) -> PgyProjectModel? {
        if let pgyProject = getPgyProjectCD(withProjectId: projectId) {
            return pgyProject.model()
        }
        return nil
    }

    public func getAllAnonymousPgyProjects(anonymousId: String?) -> [PgyProjectModel] {
        return getAllAnonymousPgyProjectsCD(anonymousId: anonymousId, toBeDeleted: false).map({ $0.model() })
    }

    public func getAllPgyProjectsCount() -> Int {
        return getAllPgyProjectsCountCD(toBeDeleted: false)
    }

    public func getAllPgyProjects() -> [PgyProjectModel] {
        return getAllPgyProjectsCD(toBeDeleted: false).map({ $0.model() })
    }

    public func getAllPgyProjectsToBeDeleted() -> [PgyProjectModel] {
        return getAllPgyProjectsCD(toBeDeleted: true).map({ $0.model() })
    }

    // MARK: __ Delete
    public func deletePgyProjects(withProjectIds projectIds: [Int64]) {
        if projectIds.isEmpty {
            return
        }

        performAndSave({ [unowned self] _ in
            let pgyProjects = getPgyProjectsCD(withProjectIds: projectIds)
            deletePgyProjectsCD(pgyProjects)

            return false
        })
    }

    public func deletePgyProject(withProjectId projectId: Int64, updateRelatedFlightPlan: Bool) {
        performAndSave({ [unowned self] context in
            guard let pgyProject = getPgyProjectCD(withProjectId: projectId) else {
                return false
            }

            if updateRelatedFlightPlan, let flightPlan = getFlightPlanCD(withPgyProjectId: projectId)?.model() {
                flightPlan.dataSetting?.pgyProjectDeleted = true
                saveOrUpdateFlightPlan(flightPlan,
                                       byUserUpdate: true,
                                       toSynchro: true,
                                       withFileUploadNeeded: true)
            }

            context.delete(pgyProject)

            return true
        }, { [unowned self] result in
            switch result {
            case .success:
                pgyProjectsDidChangeSubject.send()
            case .failure(let error):
                ULog.e(.dataModelTag, "Error deletePgyProject with projectId: \(projectId) - error: \(error.localizedDescription)")
            }
        })
    }
}

// MARK: - Internal
internal extension CoreDataServiceImpl {
    func getAllPgyProjectsCountCD(toBeDeleted: Bool?) -> Int {
        let fetchRequest: NSFetchRequest<PgyProject> = PgyProject.fetchRequest()
        let apcIdPredicate = NSPredicate(format: "apcId == %@", userInformation.apcId)

        if let toBeDeleted = toBeDeleted {
            let parrotToBeDeletedPredicate = NSPredicate(format: "isLocalDeleted == %@", NSNumber(value: toBeDeleted))

            let subPredicateList: [NSPredicate] = [apcIdPredicate, parrotToBeDeletedPredicate]
            let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
            fetchRequest.predicate = compoundPredicates
        } else {
            fetchRequest.predicate = apcIdPredicate
        }

        let projectDateSortDesc = NSSortDescriptor.init(key: "projectDate", ascending: false)
        fetchRequest.sortDescriptors = [projectDateSortDesc]

        return fetchCount(request: fetchRequest)
    }

    func getAllPgyProjectsCD(toBeDeleted: Bool?) -> [PgyProject] {
        let fetchRequest: NSFetchRequest<PgyProject> = PgyProject.fetchRequest()
        let apcIdPredicate = NSPredicate(format: "apcId == %@", userInformation.apcId)

        if let toBeDeleted = toBeDeleted {
            let parrotToBeDeletedPredicate = NSPredicate(format: "isLocalDeleted == %@", NSNumber(value: toBeDeleted))

            let subPredicateList: [NSPredicate] = [apcIdPredicate, parrotToBeDeletedPredicate]
            let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
            fetchRequest.predicate = compoundPredicates
        } else {
            fetchRequest.predicate = apcIdPredicate
        }

        let projectDateSortDesc = NSSortDescriptor.init(key: "projectDate", ascending: false)
        fetchRequest.sortDescriptors = [projectDateSortDesc]

        return fetch(request: fetchRequest)
    }

    func getAllAnonymousPgyProjectsCD(anonymousId: String?, toBeDeleted: Bool?) -> [PgyProject] {
        let fetchRequest: NSFetchRequest<PgyProject> = PgyProject.fetchRequest()

        let apcIdPredicate = NSPredicate(format: "apcId == %@", anonymousId ?? User.anonymousId)

        if let toBeDeleted = toBeDeleted {
            let parrotToBeDeletedPredicate = NSPredicate(format: "isLocalDeleted == %@", NSNumber(value: toBeDeleted))

            let subPredicateList: [NSPredicate] = [apcIdPredicate, parrotToBeDeletedPredicate]
            let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
            fetchRequest.predicate = compoundPredicates
        } else {
            fetchRequest.predicate = apcIdPredicate
        }

        let projectDateSortDesc = NSSortDescriptor.init(key: "projectDate", ascending: false)
        fetchRequest.sortDescriptors = [projectDateSortDesc]

        return fetch(request: fetchRequest)
    }

    func getPgyProjectCD(withProjectId projectId: Int64) -> PgyProject? {
        let fetchRequest: NSFetchRequest<PgyProject> = PgyProject.fetchRequest()
        let uuidPredicate = NSPredicate(format: "pgyProjectId == %@", "\(projectId)")

        fetchRequest.predicate = uuidPredicate

        let projectDateSortDesc = NSSortDescriptor.init(key: "projectDate", ascending: false)
        fetchRequest.sortDescriptors = [projectDateSortDesc]
        fetchRequest.fetchLimit = 1

        return fetch(request: fetchRequest).first
    }

    func getPgyProjectsCD(withProjectIds projectIds: [Int64]) -> [PgyProject] {
        if projectIds.isEmpty {
            return []
        }

        let fetchRequest = PgyProject.fetchRequest()
        let projectIdPredicate = NSPredicate(format: "pgyProjectId IN %i", projectIds)

        fetchRequest.predicate = projectIdPredicate

        let projectDateSortDesc = NSSortDescriptor.init(key: "projectDate", ascending: false)
        fetchRequest.sortDescriptors = [projectDateSortDesc]

        return fetch(request: fetchRequest)
    }

    func deletePgyProjectsCD(_ pgyProjects: [PgyProject]) {
        if pgyProjects.isEmpty {
            return
        }
        delete(pgyProjects) { error in
            var projectIdsStr = "[ "
            pgyProjects.forEach({
                projectIdsStr += "\($0.pgyProjectId), "
            })
            projectIdsStr += "]"

            ULog.e(.dataModelTag, "Error deletePgyProjectsCD with \(projectIdsStr): \(error.localizedDescription)")
        }
    }
}
