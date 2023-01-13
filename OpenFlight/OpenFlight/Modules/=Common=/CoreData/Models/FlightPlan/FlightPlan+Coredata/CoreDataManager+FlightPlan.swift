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

// swiftlint:disable file_length

import Foundation
import CoreData
import GroundSdk
import Combine

// MARK: - Repository Protocol
public protocol FlightPlanRepository: AnyObject {
    // MARK: __ Publisher
    /// Publisher notify changes
    var flightPlansDidChangePublisher: AnyPublisher<Void, Never> { get }

    // MARK: __ Save Or Update
    /// Save or update FlightPlan into CoreData from FlightPlanModel
    /// - Parameters:
    ///    - flightPlanModel: FlightPlanModel to save or update
    ///    - byUserUpdate: Boolean if updated by user interaction
    ///    - toSynchro: Boolean if should be synchro
    ///    - completion: The callback returning the status.
    ///    - withFileUploadNeeded: Indicates if a file needs to be uploaded.
    ///    - completion: closure called on completion
    func saveOrUpdateFlightPlan(_ flightPlanModel: FlightPlanModel,
                                byUserUpdate: Bool,
                                toSynchro: Bool,
                                withFileUploadNeeded: Bool,
                                completion: ((_ status: Bool) -> Void)?)

    /// Save or update FlightPlan into CoreData from FlightPlanModel
    /// - Parameters:
    ///    - flightPlanModel: FlightPlanModel to save or update
    ///    - byUserUpdate: Boolean if updated by user interaction
    ///    - toSynchro: Boolean if should be synchro
    ///    - withFileUploadNeeded: Indicates if a file needs to be uploaded.
    func saveOrUpdateFlightPlan(_ flightPlanModel: FlightPlanModel,
                                byUserUpdate: Bool,
                                toSynchro: Bool,
                                withFileUploadNeeded: Bool)
    func saveOrUpdateFlightPlan(_ flightPlanModel: FlightPlanModel,
                                byUserUpdate: Bool,
                                toSynchro: Bool)

    /// Save or update FlightPlan into CoreData from list of FlightPlanModel
    /// - Parameters:
    ///    - flightPlanModels: List of FlightPlanModel to save or update
    ///    - byUserUpdate: Boolean if updated by user interaction
    ///    - toSynchro: Boolean if should be synchro
    ///    - withFileUploadNeeded: Indicates if a file needs to be uploaded.
    ///    - completion: closure called on completion
    func saveOrUpdateFlightPlans(_ flightPlanModels: [FlightPlanModel],
                                 byUserUpdate: Bool,
                                 toSynchro: Bool,
                                 withFileUploadNeeded: Bool,
                                 completion: ((_ status: Bool) -> Void)?)

    // MARK: __ Get
    /// Get FlightPlanModel with UUID
    /// - Parameter uuid: FlightPlan's UUID to search
    /// - Returns:
    ///     - FlightPlanModel object if not found
    func getFlightPlan(withUuid uuid: String) -> FlightPlanModel?

    /// Get FlightPlanModels with a specified list of UUIDs
    /// - Parameter uuids: List of UUIDs to search
    /// - Returns:
    ///     - List of FlightPlanModels
    func getFlightPlans(withUuids uuids: [String]) -> [FlightPlanModel]

    /// Get FlightPlanModel with CloudId
    /// - Parameters:
    ///    - cloudId: FlightPlan's CloudId to search
    /// - Returns:
    ///     - `FlightPlanModel object if  found
    func getFlightPlan(withCloudId cloudId: Int) -> FlightPlanModel?

    /// Get FlightPlanModels by excluding specified types
    /// - Parameter excludingTypes: List of type to be excluded
    /// - Returns:
    ///     - List of FlightPlanModels
    func getFlightPlans(byExcludingTypes excludingTypes: [String]) -> [FlightPlanModel]

    /// Get FlightPlanModel with pgyProject UUID
    /// - Parameter pgyProjectId: PgyProject's UUID to search
    /// - Returns:
    ///     - FlightPlanModel object if not found
    func getFlightPlan(withPgyProjectId pgyProjectId: Int64) -> FlightPlanModel?

    /// Get FlightPlanModel with pgyProject UUID and a specific FlightPlan State
    /// - Parameters:
    ///    - projectUuid: Project's UUID to search
    ///    - withState: FlightPlanState to search
    /// - Returns:
    ///     - List of FlightPlanModels
    func getFlightPlans(withProjectUuid projectUuid: String, withState: FlightPlanModel.FlightPlanState) -> [FlightPlanModel]

    /// Get FlightPlanModels with a specific state by excluding specified types
    /// - Parameters:
    ///    - withState: Specified state of flight plan
    ///    - byExcludingTypes: List of type to be excluded
    ///    - completion: Callback closure on completion
    func getFlightPlans(withState: FlightPlanModel.FlightPlanState, byExcludingTypes: [String], completion: @escaping (([FlightPlanModel]) -> Void))

    /// Get the last flight date of a FlightPlan if any
    /// - Parameter flightPlanModel: flightPlanModel to search
    /// - Returns:
    ///     - Date if found
    func getLastFlightDateOfFlightPlan(_ flightPlanModel: FlightPlanModel) -> Date?

    /// Get the first FlightPlan's Flight date.
    /// - Parameter flightPlanModel: the Flight Plan
    /// - Returns: the `Date` if exists, `nil` otherwise
    func firstFlightDate(of flightPlanModel: FlightPlanModel) -> Date?

    /// Get count of executed FlightPlans with specified project UUID
    /// - Parameters:
    ///    - projectUuid: project's UUID to specify
    ///    - excludeUuids: flight plan's uuid to exclude (case of flying flight plan...)
    /// - Returns: count of executed flight plan found
    func getExecutedFlightPlansCount(withProjectUuid projectUuid: String, excludedUuids: [String]) -> Int

    /// Get count of all FlightPlans
    /// - Returns: Count of all FlightPlans
    func getAllFlightPlansCount() -> Int

    /// Get all FlightPlanModels from all FlightPlan in CoreData
    /// - Returns:
    ///     -  List of FlightPlanModels
    func getAllFlightPlans() -> [FlightPlanModel]

    /// Get all FlightPlanModels to be deleted from FlightPlan in CoreData
    /// - Returns:
    ///     - List of FlightPlanModels
    func getAllFlightPlansToBeDeleted() -> [FlightPlanModel]

    /// Get all FlightPlanModels locally modified from Flight Plans in CoreData
    /// - Returns:  List of FlightPlanModels
    func getAllModifiedFlightPlans() -> [FlightPlanModel]

    /// Get all synchronized flightplans UUIDs
    /// - Returns: List of UUIDs
    func getAllSynchronizedFlightPlansUuids() -> [String]

    /// Get count of FlightPlans with specified versions
    func getFlightPlansCount(withVersions: [String]) -> Int

    /// Get FlightPlansModels with specified versions
    /// - Parameters:
    ///     - completion: closure called on finish with a list of flight plan with specified version
    func getFlightPlans(withVersions: [String], _ completion: @escaping (([FlightPlanModel]) -> Void))

    // MARK: __ Delete
    /// Delete FlightPlan in CoreData from UUID
    /// - Parameters:
    ///    - uuids: List of flightPlan's UUID to remove
    ///    - completion: the completion block with the deletion status (`true` in case of successful deletion)
    func deleteOrFlagToDeleteFlightPlans(withUuids uuids: [String], completion: ((_ status: Bool) -> Void)?)

    /// Delete from CoreData the FlightPlan with specified `uuid`.
    /// - Parameters:
    ///    - uuid: the  FlightPlan's `uuid`
    ///    - completion: the completion block with the deletion status (`true` in case of successful deletion)
    func deleteFlightPlan(withUuid uuid: String, completion: ((_ status: Bool) -> Void)?)

    /// Delete FlightPlans in CoreData with UUIDs
    /// - Parameter uuids: List of  UUIDs to search
    func deleteFlightPlans(withUuids uuids: [String])
    func deleteFlightPlans(withUuids uuids: [String], completion: ((_ status: Bool) -> Void)?)

    /// Remove CloudId and SynchroStatus for all FlightPlan
    /// - Parameters:
    ///    - completion: closure called when all flight plan are updated
    func removeCloudIdForAllFlightPlans(completion: ((_ status: Bool) -> Void)?)

    // MARK: __ Related
    /// Migrate FlightPlans made by Anonymous user to current logged user
    /// - Parameter completion: empty block indicates when process is finished
    func migrateFlightPlansToLoggedUser(_ completion: @escaping () -> Void)

    /// Migrate FlightPlans made by a Logged user to ANONYMOUS user
    /// - Parameter completion: empty block indicates when process is finished
    func migrateFlightPlansToAnonymous(_ completion: @escaping () -> Void)
}

extension CoreDataServiceImpl: FlightPlanRepository {
    // MARK: __ Publisher
    public var flightPlansDidChangePublisher: AnyPublisher<Void, Never> {
        return flightPlansDidChangeSubject.eraseToAnyPublisher()
    }

    // MARK: __ Save Or Update
    public func saveOrUpdateFlightPlan(_ flightPlanModel: FlightPlanModel,
                                       byUserUpdate: Bool,
                                       toSynchro: Bool,
                                       withFileUploadNeeded: Bool,
                                       completion: ((Bool) -> Void)?) {
        var modifDate: Date?
        var thumbnailModifDate: Date?

        performAndSave({ [unowned self] context in
            var isUpdating = false
            var flightPlanObj: FlightPlan?

            ULog.d(.dataModelTag, "saveOrUpdateFlightPlan for \(flightPlanModel)")

            if let existingFlightPlan = getFlightPlanCD(withUuid: flightPlanModel.uuid) {
                flightPlanObj = existingFlightPlan
                isUpdating = true
                ULog.d(.dataModelTag, "saveOrUpdateFlightPlan for UUID \(flightPlanModel.uuid) found in database, flight plan will be updated")
            } else if let newFlightPlan = insertNewObject(entityName: FlightPlan.entityName) as? FlightPlan {
                flightPlanObj = newFlightPlan
                ULog.d(.dataModelTag, "saveOrUpdateFlightPlan with UUID \(flightPlanModel.uuid) not found in database, new flight plan created")
            }

            guard let flightPlan = flightPlanObj else {
                ULog.e(.dataModelTag, "Unable to insert or update Flight Plan '\(flightPlanModel.uuid)'")
                completion?(false)
                return false
            }

            var flightPlanModel = flightPlanModel
            if byUserUpdate {
                modifDate = Date()
                flightPlanModel.latestLocalModificationDate = modifDate
                if flightPlanModel.synchroStatus == .fileUpload ||
                    withFileUploadNeeded {
                    flightPlanModel.synchroStatus = .notSync
                }
            }

            var project: Project?
            if let projectObj = getProjectCD(withUuid: flightPlanModel.projectUuid) {
                project = projectObj
            }

            // Sets thumbnail of the FlightPlan if it exists
            var thumbnail: Thumbnail?
            if let thumbnailModel = flightPlanModel.thumbnail {
                var thumbnailModel = thumbnailModel
                if byUserUpdate {
                    // TODO: Check if thumbnail is not already uploaded to the cloud
                    thumbnailModifDate = Date()
                    thumbnailModel.latestLocalModificationDate = thumbnailModifDate
                    flightPlanModel.synchroStatus = .notSync
                }
                thumbnail = self.getThumbnailCD(withUuid: thumbnailModel.uuid) ?? Thumbnail(context: context)
                thumbnail?.update(fromThumbnailModel: thumbnailModel, withFlight: nil)
            }

            let logMessage = """
                🗺⬇️ saveOrUpdateFlightPlan: \(flightPlan), \
                byUserUpdate: \(byUserUpdate), toSynchro: \(toSynchro), \
                withFileUploadNeeded: \(withFileUploadNeeded) project: \(String(describing: project)), \
                thumbnail: \(String(describing: thumbnail)), flightPlanModel: \(flightPlanModel)
                """
            ULog.d(.dataModelTag, logMessage)

            // Check if there is an error getting the data in Core Data from its UUID.
            // TODO: Only for debug purposes. To remove.
            if isUpdating && flightPlan.uuid != flightPlanModel.uuid {
                ULog.e(.dataModelTag, "ERROR: Trying to update CD FP '\(flightPlan.uuid ?? "-")' with model '\(flightPlanModel.uuid)'")
                completion?(false)
                return false
            }

            // Update the CD Flight plan.
            flightPlan.update(fromFlightPlanModel: flightPlanModel,
                              withProject: project,
                              withThumbnail: thumbnail)

            // Return true to tell to save the Core Data context.
            return true
        }, { [unowned self] result in
            switch result {
            case .success:
                if let modifDate = modifDate, toSynchro {
                    latestFlightPlanLocalModificationDate.send(modifDate)
                }
                if let thumbnailModifDate = thumbnailModifDate, toSynchro {
                    latestThumbnailLocalModificationDate.send(thumbnailModifDate)
                }
                ULog.i(.dataModelTag, "🗺⬇️🟢 saveOrUpdateFlightPlan \(flightPlanModel.uuid) - Flight Plan stored Locally")
                flightPlansDidChangeSubject.send()
                completion?(true)
            case .failure(let error):
                ULog.e(.dataModelTag, "Error saveOrUpdateFlightPlan with UUID : \(flightPlanModel.uuid) - error : \(error)")
                completion?(false)
            }
        })
    }

    public func saveOrUpdateFlightPlan(_ flightPlanModel: FlightPlanModel,
                                       byUserUpdate: Bool,
                                       toSynchro: Bool) {
        saveOrUpdateFlightPlan(flightPlanModel,
                               byUserUpdate: byUserUpdate,
                               toSynchro: toSynchro,
                               withFileUploadNeeded: false,
                               completion: nil)
    }

    public func saveOrUpdateFlightPlan(_ flightPlanModel: FlightPlanModel,
                                       byUserUpdate: Bool,
                                       toSynchro: Bool,
                                       withFileUploadNeeded: Bool) {
        saveOrUpdateFlightPlan(flightPlanModel,
                               byUserUpdate: byUserUpdate,
                               toSynchro: toSynchro,
                               withFileUploadNeeded: withFileUploadNeeded,
                               completion: nil)
    }

    public func saveOrUpdateFlightPlans(_ flightPlanModels: [FlightPlanModel],
                                        byUserUpdate: Bool = true,
                                        toSynchro: Bool,
                                        withFileUploadNeeded: Bool,
                                        completion: ((Bool) -> Void)?) {
        guard !flightPlanModels.isEmpty else {
            completion?(true)
            return
        }

        var modifDate: Date?
        var thumbnailModifDate: Date?

        let flightPlanUuids = flightPlanModels.compactMap { $0.uuid }
        let projectUuids = flightPlanModels.compactMap { $0.projectUuid }
        let thumbnailUuids = flightPlanModels.compactMap { $0.thumbnail?.uuid }

        performAndSave({ [unowned self] context in
            let flightPlans = getFlightPlansCD(withUuids: flightPlanUuids)
            let projects = getProjectsCD(withUuids: projectUuids)
            let thumbnails = getThumbnailsCD(withUuids: thumbnailUuids)

            for var flightPlanModel in flightPlanModels {
                var flightPlanObj: FlightPlan?

                if let flightPlan = flightPlans.first(where: { $0.uuid == flightPlanModel.uuid }) {
                    flightPlanObj = flightPlan
                    ULog.d(.dataModelTag, "saveOrUpdateFlightPlans for UUID \(flightPlanModel.uuid) found in database, flight plan will be updated")
                } else if let newFlightPlan = insertNewObject(entityName: FlightPlan.entityName) as? FlightPlan {
                    flightPlanObj = newFlightPlan
                    ULog.d(.dataModelTag, "saveOrUpdateFlightPlans with UUID \(flightPlanModel.uuid) not found in database, new flight plan created")
                }

                if let flightPlan = flightPlanObj {
                    if byUserUpdate {
                        modifDate = Date()
                        flightPlanModel.latestLocalModificationDate = modifDate
                        if flightPlanModel.synchroStatus == .fileUpload ||
                            withFileUploadNeeded {
                            flightPlanModel.synchroStatus = .notSync
                        }
                    }

                    var project: Project?
                    if let projectObj = projects.first(where: { $0.uuid == flightPlanModel.projectUuid }) {
                        project = projectObj
                    }

                    // Sets thumbnail of the FlightPlan if it exists
                    var thumbnail: Thumbnail?
                    if let thumbnailModel = flightPlanModel.thumbnail {
                        var thumbnailModel = thumbnailModel
                        if byUserUpdate {
                            // TODO: Check if thumbnail is not already uploaded to the cloud
                            thumbnailModifDate = Date()
                            thumbnailModel.latestLocalModificationDate = thumbnailModifDate
                            flightPlanModel.synchroStatus = .notSync
                        }
                        thumbnail = thumbnails.first(where: { $0.uuid == thumbnailModel.uuid }) ?? Thumbnail(context: context)
                        thumbnail?.update(fromThumbnailModel: thumbnailModel, withFlight: nil)
                    }

                    let logMessage = """
                    🗺⬇️ saveOrUpdateFlightPlan: \(flightPlan), \
                    byUserUpdate: \(byUserUpdate), toSynchro: \(toSynchro), \
                    withFileUploadNeeded: \(withFileUploadNeeded) project: \(String(describing: project)), \
                    thumbnail: \(String(describing: thumbnail)), flightPlanModel: \(flightPlanModel)
                    """
                    ULog.d(.dataModelTag, logMessage)

                    flightPlan.update(fromFlightPlanModel: flightPlanModel,
                                      withProject: project,
                                      withThumbnail: thumbnail)
                }
            }

            return true
        }, { [unowned self] result in
            switch result {
            case .success:
                if let modifDate = modifDate, toSynchro {
                    latestFlightPlanLocalModificationDate.send(modifDate)
                }
                if let thumbnailModifDate = thumbnailModifDate, toSynchro {
                    latestThumbnailLocalModificationDate.send(thumbnailModifDate)
                }

                ULog.i(.dataModelTag, "🗺⬇️🟢 saveOrUpdateFlightPlan \(flightPlanUuids.joined(separator: ", ")) - Flight Plan stored Locally")
                flightPlansDidChangeSubject.send()
                completion?(true)
            case .failure(let error):
                ULog.e(.dataModelTag, "Error saveOrUpdateFlightPlan with UUID : \(flightPlanUuids.joined(separator: ", ")) - error : \(error)")
                completion?(false)
            }
        })
    }

    // MARK: __ Get
    public func getFlightPlan(withUuid uuid: String) -> FlightPlanModel? {
        return getFlightPlanCD(withUuid: uuid)?.model()
    }

    public func getFlightPlans(withUuids uuids: [String]) -> [FlightPlanModel] {
        return getFlightPlansCD(withUuids: uuids).map({ $0.model() })
    }

    public func getFlightPlan(withCloudId cloudId: Int) -> FlightPlanModel? {
        getFlightPlansCD(filteredBy: "cloudId", [cloudId])
            .compactMap { $0.model() }
            .first
    }

    public func getFlightPlans(byExcludingTypes: [String]) -> [FlightPlanModel] {
        return getFlightPlansCD(byExcludingTypes: byExcludingTypes, toBeDeleted: false)
            .map({ $0.model() })
    }

    public func getFlightPlans(withState: FlightPlanModel.FlightPlanState, byExcludingTypes: [String], completion: @escaping (([FlightPlanModel]) -> Void)) {
        getFlightPlansCD(withState: withState.rawValue, byExcludingTypes: byExcludingTypes, toBeDeleted: false) { flightPlansCD in
            let flightPlanModels = flightPlansCD.compactMap({ $0.modelWithFlightPlanFlights() })
            DispatchQueue.main.async {
                completion(flightPlanModels)
            }
        }
    }

    public func getFlightPlan(withPgyProjectId pgyProjectId: Int64) -> FlightPlanModel? {
        return getFlightPlanCD(withPgyProjectId: pgyProjectId)?.model()
    }

    public func getFlightPlans(withProjectUuid projectUuid: String, withState: FlightPlanModel.FlightPlanState) -> [FlightPlanModel] {
        let result = getFlightPlansCD(withProjectUuid: projectUuid, withState: withState.rawValue).compactMap({ $0.model() })
        ULog.d(.dataModelTag, "getFlightPlans with projectUuid [\(projectUuid)] withState \(withState)\nResult: \(result)")
        return result
    }

    public func getFlightPlansCount(withVersions versions: [String]) -> Int {
        getFlightPlansCountCD(withVersions: versions)
    }

    public func getFlightPlans(withVersions versions: [String], _ completion: @escaping (([FlightPlanModel]) -> Void)) {
        return getFlightPlansCD(withVersions: versions) { flightPlans in
            let flightPlanModels = flightPlans.compactMap({ $0.model() })
            DispatchQueue.main.async {
                completion(flightPlanModels)
            }
        }
    }

    public func getLastFlightDateOfFlightPlan(_ flightPlanModel: FlightPlanModel) -> Date? {
        guard let flightPlan = getFlightPlanCD(withUuid: flightPlanModel.uuid) else {
            return nil
        }
        return flightPlan.flightPlanFlights?.compactMap { $0.ofFlight?.startTime }.max() ?? flightPlan.lastUpdate
    }

    public func firstFlightDate(of flightPlanModel: FlightPlanModel) -> Date? {
        // Get the FP Core Data Object.
        guard let flightPlanObject = getFlightPlanCD(withUuid: flightPlanModel.uuid)
        else { return nil }
        // Returns the first FlightPlan's Flight date.
        // 1 - Get all FP <-> Flight links.
        // 2 - Map them to the Flight's start date.
        // 3 - Get the oldest date.
        return flightPlanObject.flightPlanFlights?
            .compactMap { $0.ofFlight?.startTime }
            .min()
    }

    public func getExecutedFlightPlansCount(withProjectUuid projectUuid: String, excludedUuids: [String]) -> Int {
        return getExecutedFlightPlansCountCD(withProjectUuid: projectUuid, excludedUuids: excludedUuids)
    }

    public func getAllFlightPlansCount() -> Int {
        return getAllFlightPlansCountCD(toBeDeleted: false)
    }

    public func getAllFlightPlans() -> [FlightPlanModel] {
        return getAllFlightPlansCD(toBeDeleted: false)
            .compactMap({ $0.model() })
    }

    public func getAllFlightPlansToBeDeleted() -> [FlightPlanModel] {
        return getAllFlightPlansCD(toBeDeleted: true).map({ $0.model() })
    }

    public func getAllModifiedFlightPlans() -> [FlightPlanModel] {
        let apcIdQuery = "apcId == '\(userService.currentUser.apcId)'"
        return getFlightPlansCD(withQuery: "latestLocalModificationDate != nil && \(apcIdQuery)").map({ $0.model() })
    }

    public func getAllSynchronizedFlightPlansUuids() -> [String] {
        getAllSynchronizedFlightPlansCD().compactMap { $0.uuid }
    }

    // MARK: __ Delete
    public func deleteOrFlagToDeleteFlightPlans(withUuids uuids: [String], completion: ((_ status: Bool) -> Void)?) {
        guard !uuids.isEmpty else {
            completion?(true)
            return
        }
        var modifDate: Date?

        performAndSave({ [unowned self] context in
            let flightPlans = getFlightPlansCD(withUuids: uuids)
            guard !flightPlans.isEmpty else {
                completion?(false)
                return false
            }

            flightPlans.forEach({
                // Remove related Thumbnail
                if let relatedThumbnail = $0.thumbnail {
                    $0.thumbnailUuid = nil
                    $0.thumbnail = nil
                    deleteOrFlagToDeleteThumbnails(withUuids: [relatedThumbnail.uuid], completion: nil)
                }

                $0.flightPlanFlights = nil

                if let relatedPgyProject = getPgyProject(withProjectId: $0.pgyProjectId) {
                    updatePgyProjectToBeDeleted(withProjectId: relatedPgyProject.pgyProjectId)
                }

                if $0.cloudId == 0 {
                    ULog.d(.dataModelTag, "🗺🗑 deleteOrFlagToDeleteFlightPlan, uuid: \(uuids.joined(separator: ", ")) - delete locally -")
                    context.delete($0)
                } else {
                    ULog.d(.dataModelTag, "🗺🗑 deleteOrFlagToDeleteFlightPlan, uuid: \(uuids.joined(separator: ", ")) - flag as LocalDeleted -")
                    modifDate = Date()
                    $0.latestLocalModificationDate = modifDate
                    $0.isLocalDeleted = true
                }
            })

            return true
        }, { [unowned self] result in
            switch result {
            case .success:
                if let modifDate = modifDate {
                    latestFlightPlanLocalModificationDate.send(modifDate)
                }

                ULog.d(.dataModelTag, "🗺🗑🟢 deleteOrFlagToDeleteFlightPlan, uuid: \(uuids.joined(separator: ", "))")
                flightPlansDidChangeSubject.send()
                completion?(true)
            case .failure(let error):
                ULog.e(.dataModelTag, "🗺🗑🔴 Error deleteOrFlagToDeleteFlightPlan(fromFlightPlanModel:) with UUID:"
                       + "\(uuids.joined(separator: ", ")) - error: \(error.localizedDescription)")
                completion?(false)
            }
        })
    }

    public func deleteFlightPlan(withUuid uuid: String, completion: ((_ status: Bool) -> Void)?) {

        performAndSave({ [unowned self] context in
            guard let flightPlan = getFlightPlanCD(withUuid: uuid) else {
                completion?(false)
                return false
            }

            ULog.d(.dataModelTag, "🗺🗑 deleteFlightPlan, uuid: \(uuid), flightPlan: \(flightPlan)")
            context.delete(flightPlan)
            return true
        }, { [unowned self] result in
            switch result {
            case .success:
                ULog.d(.dataModelTag, "🗺🗑🟢 deleteFlightPlan, uuid: \(uuid)")
                flightPlansDidChangeSubject.send()
                completion?(true)
            case .failure(let error):
                ULog.e(.dataModelTag,
                       "🗺🗑🔴 Error deleteFlightPlan, uuid: \(uuid) - error: \(error.localizedDescription)")
                completion?(false)
            }
        })
    }

    public func deleteFlightPlans(withUuids uuids: [String]) {
        deleteFlightPlans(withUuids: uuids, completion: nil)
    }

    public func deleteFlightPlans(withUuids uuids: [String], completion: ((_ status: Bool) -> Void)?) {
        guard !uuids.isEmpty else {
            completion?(true)
            return
        }

        performAndSave({ [unowned self] _ in
            deleteObjects(getFlightPlansCD(withUuids: uuids))
            return true
        }, { [unowned self] result in
            switch result {
            case .success:
                flightPlansDidChangeSubject.send()
                ULog.i(.dataModelTag, "FlightPlans Deleted. uuids: (\(uuids.joined(separator: ",")))")
                completion?(true)
            case .failure(let error):
                ULog.e(.dataModelTag, "Error deleteFlightPlan with UUIDs error: \(error.localizedDescription)")
                completion?(false)
            }
        })
    }

    public func removeCloudIdForAllFlightPlans(completion: ((_ status: Bool) -> Void)?) {
        performAndSave({ [unowned self] _ in
            let flightPlanCDs = getAllFlightPlansCD(toBeDeleted: false)

            for flightPlanCD in flightPlanCDs {
                flightPlanCD.cloudId = 0
                flightPlanCD.synchroStatus = 0
            }

            return true
        }, { result in
            switch result {
            case .success:
                ULog.d(.dataModelTag, "Remove cloudId and synchroStatus for all flight plans")
                completion?(true)
            case .failure(let error):
                ULog.e(.dataModelTag, "Error remove cloudId for all flight plans: \(error.localizedDescription)")
                completion?(false)
            }
        })
    }

    // MARK: __ Related
    public func migrateFlightPlansToLoggedUser(_ completion: @escaping () -> Void) {
        let fetchRequest: NSFetchRequest<FlightPlan> = FlightPlan.fetchRequest()
        guard let entityName = fetchRequest.entityName else {
            return
        }
        migrateAnonymousDataToLoggedUser(for: entityName) { _ in
            completion()
        }
    }

    public func migrateFlightPlansToAnonymous(_ completion: @escaping () -> Void) {
        let fetchRequest: NSFetchRequest<FlightPlan> = FlightPlan.fetchRequest()
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
    // MARK: __ Get
    func getAllFlightPlansCountCD(toBeDeleted: Bool?) -> Int {
        let fetchRequest = FlightPlan.fetchRequest()

        let apcIdPredicate = NSPredicate(format: "apcId == %@", userService.currentUser.apcId)

        if let toBeDeleted = toBeDeleted {
            let parrotToBeDeletedPredicate = NSPredicate(format: "isLocalDeleted == %@", NSNumber(value: toBeDeleted))

            let subPredicateList: [NSPredicate] = [apcIdPredicate, parrotToBeDeletedPredicate]
            let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
            fetchRequest.predicate = compoundPredicates
        } else {
            fetchRequest.predicate = apcIdPredicate
        }

        let lastUpdateSortDesc = NSSortDescriptor.init(key: "lastUpdate", ascending: false)
        fetchRequest.sortDescriptors = [lastUpdateSortDesc]

        return fetchCount(request: fetchRequest)
    }

    func getAllFlightPlansCD(toBeDeleted: Bool?) -> [FlightPlan] {
        let fetchRequest = FlightPlan.fetchRequest()

        let apcIdPredicate = NSPredicate(format: "apcId == %@", userService.currentUser.apcId)

        if let toBeDeleted = toBeDeleted {
            let parrotToBeDeletedPredicate = NSPredicate(format: "isLocalDeleted == %@", NSNumber(value: toBeDeleted))

            let subPredicateList: [NSPredicate] = [apcIdPredicate, parrotToBeDeletedPredicate]
            let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
            fetchRequest.predicate = compoundPredicates
        } else {
            fetchRequest.predicate = apcIdPredicate
        }

        let lastUpdateSortDesc = NSSortDescriptor.init(key: "lastUpdate", ascending: false)
        fetchRequest.sortDescriptors = [lastUpdateSortDesc]

        return fetch(request: fetchRequest)
    }

    func getFlightPlanCD(withUuid uuid: String) -> FlightPlan? {
        let fetchRequest = FlightPlan.fetchRequest()
        let uuidPredicate = NSPredicate(format: "uuid == %@", uuid)

        fetchRequest.predicate = uuidPredicate

        let lastUpdateSortDesc = NSSortDescriptor.init(key: "lastUpdate", ascending: false)
        fetchRequest.sortDescriptors = [lastUpdateSortDesc]
        fetchRequest.fetchLimit = 1

        return fetch(request: fetchRequest).first
    }

    func getFlightPlansCD(withUuids uuids: [String]) -> [FlightPlan] {
        guard !uuids.isEmpty else {
            return []
        }

        let fetchRequest = FlightPlan.fetchRequest()
        let uuidPredicate = NSPredicate(format: "uuid IN %@", uuids)
        fetchRequest.predicate = uuidPredicate

        let lastUpdateSortDesc = NSSortDescriptor.init(key: "lastUpdate", ascending: false)
        fetchRequest.sortDescriptors = [lastUpdateSortDesc]

        return fetch(request: fetchRequest)
    }

    func getFlightPlanCD(withPgyProjectId pgyProjectId: Int64) -> FlightPlan? {
        let fetchRequest = FlightPlan.fetchRequest()

        let pgyProjectIdPredicate = NSPredicate(format: "pgyProjectId == %i", pgyProjectId)
        fetchRequest.predicate = pgyProjectIdPredicate

        let lastUpdateSortDesc = NSSortDescriptor(key: "lastUpdate", ascending: false)
        fetchRequest.sortDescriptors = [lastUpdateSortDesc]

        fetchRequest.fetchLimit = 1

        return fetch(request: fetchRequest).first
    }

    func getFlightPlansCD(withPgyProjectIds pgyProjectIds: [Int64]) -> [FlightPlan] {
        let fetchRequest = FlightPlan.fetchRequest()

        let pgyProjectIdPredicate = NSPredicate(format: "pgyProjectId IN %@", pgyProjectIds)
        fetchRequest.predicate = pgyProjectIdPredicate

        let lastUpdateSortDesc = NSSortDescriptor(key: "lastUpdate", ascending: false)
        fetchRequest.sortDescriptors = [lastUpdateSortDesc]

        return fetch(request: fetchRequest)
    }

    func getFlightPlansCD(withProjectUuid projectUuid: String, withState: String?) -> [FlightPlan] {
        let fetchRequest = FlightPlan.fetchRequest()

        var subPredicateList = [NSPredicate]()

        let projectUuidPredicate = NSPredicate(format: "projectUuid == %@", projectUuid)
        subPredicateList.append(projectUuidPredicate)

        if let withState = withState {
            let statePredicate = NSPredicate(format: "state == %@", withState)
            subPredicateList.append(statePredicate)
        }

        let parrotToBeDeletedPredicate = NSPredicate(format: "isLocalDeleted == %@", NSNumber(value: false))
        subPredicateList.append(parrotToBeDeletedPredicate)

        let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
        fetchRequest.predicate = compoundPredicates

        let lastUpdateSortDesc = NSSortDescriptor(key: "lastUpdate", ascending: false)
        fetchRequest.sortDescriptors = [lastUpdateSortDesc]

        return fetch(request: fetchRequest)
    }

    func getFlightPlansCD(withState: String, byExcludingTypes: [String], toBeDeleted: Bool?, completion: (([FlightPlan]) -> Void)?) {
        let fetchRequest = FlightPlan.fetchRequest()

        var subPredicateList = [NSPredicate]()

        let apcIdPredicate = NSPredicate(format: "apcId == %@", userService.currentUser.apcId)
        subPredicateList.append(apcIdPredicate)

        let statePredicate = NSPredicate(format: "state == %@", withState)
        subPredicateList.append(statePredicate)

        for excludingType in byExcludingTypes {
            let excludingTypePredicate = NSPredicate(format: "type != %@", excludingType)
            subPredicateList.append(excludingTypePredicate)
        }

        if let toBeDeleted = toBeDeleted {
            let toBeDeletedPredicate = NSPredicate(format: "isLocalDeleted == %@", NSNumber(value: toBeDeleted))
            subPredicateList.append(toBeDeletedPredicate)
        }

        fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)

        let lastUpdateSortDesc = NSSortDescriptor(key: "lastUpdate", ascending: false)
        fetchRequest.sortDescriptors = [lastUpdateSortDesc]

        fetch(request: fetchRequest, completion: completion)
    }

    func getFlightPlansCD(byExcludingTypes excludingTypes: [String], toBeDeleted: Bool?) -> [FlightPlan] {
        guard !excludingTypes.isEmpty else {
            return getAllFlightPlansCD(toBeDeleted: toBeDeleted)
        }

        let fetchRequest = FlightPlan.fetchRequest()

        var subPredicateList = [NSPredicate]()

        let apcIdPredicate = NSPredicate(format: "apcId == %@", userService.currentUser.apcId)
        subPredicateList.append(apcIdPredicate)

        for excludingType in excludingTypes {
            let excludingTypePredicate = NSPredicate(format: "type != %@", excludingType)
            subPredicateList.append(excludingTypePredicate)
        }

        if let toBeDeleted = toBeDeleted {
            let toBeDeletedPredicate = NSPredicate(format: "isLocalDeleted == %@", NSNumber(value: toBeDeleted))
            subPredicateList.append(toBeDeletedPredicate)
        }

        fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)

        let lastUpdateSortDesc = NSSortDescriptor(key: "lastUpdate", ascending: false)
        fetchRequest.sortDescriptors = [lastUpdateSortDesc]

        return fetch(request: fetchRequest)
    }

    func getExecutedFlightPlansCountCD(withProjectUuid projectUuid: String, excludedUuids: [String]) -> Int {
        let fetchRequest = FlightPlan.fetchRequest()
        var subPredicateList = [NSPredicate]()

        let apcIdPredicate = NSPredicate(format: "apcId == %@", userService.currentUser.apcId)
        subPredicateList.append(apcIdPredicate)

        let projectUuidPredicate = NSPredicate(format: "projectUuid == %@", projectUuid)
        subPredicateList.append(projectUuidPredicate)

        let excludeUuidsPredicate = NSPredicate(format: "NOT (uuid IN %@)", excludedUuids)
        subPredicateList.append(excludeUuidsPredicate)

        let executionPredicate = NSPredicate(format: "hasReachedFirstWayPoint == YES")
        subPredicateList.append(executionPredicate)

        let toBeDeletedPredicate = NSPredicate(format: "isLocalDeleted == %@", NSNumber(value: false))
        subPredicateList.append(toBeDeletedPredicate)

        fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)

        return fetchCount(request: fetchRequest)
    }

    func getFlightPlansCountCD(withVersions versions: [String]) -> Int {
        let fetchRequest = getFlightPlansCDFetchRequest(withVersions: versions)

        let lastUpdatedSortDesc = NSSortDescriptor(key: "lastUpdate", ascending: true)
        fetchRequest.sortDescriptors = [lastUpdatedSortDesc]

        return fetchCount(request: fetchRequest)
    }

    func getFlightPlansCD(withVersions versions: [String], _ completion: @escaping (([FlightPlan]) -> Void)) {
        guard !versions.isEmpty else {
            completion([])
            return
        }
        let fetchRequest = getFlightPlansCDFetchRequest(withVersions: versions)

        let lastUpdatedSortDesc = NSSortDescriptor(key: "lastUpdate", ascending: true)
        fetchRequest.sortDescriptors = [lastUpdatedSortDesc]

        return fetch(request: fetchRequest, completion: completion)
    }

    func getAllSynchronizedFlightPlansCD() -> [FlightPlan] {
        let fetchRequest = FlightPlan.fetchRequest()

        var subPredicateList: [NSPredicate] = []

        let apcIdPredicate = NSPredicate(format: "apcId == %@", userService.currentUser.apcId)
        subPredicateList.append(apcIdPredicate)

        let cloudIdPredicate =  NSPredicate(format: "cloudId > 0")
        subPredicateList.append(cloudIdPredicate)

        let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
        fetchRequest.predicate = compoundPredicates

        return fetch(request: fetchRequest)
    }

    // MARK: __ Delete
    func deleteFlightPlansCD(_ flightPlans: [FlightPlan]) {
        guard !flightPlans.isEmpty else {
            return
        }
        delete(flightPlans) { error in
            var uuidsStr = "[ "
            flightPlans.forEach({
                uuidsStr += "\($0.uuid ?? "-"), "
            })
            uuidsStr += "]"

            ULog.e(.dataModelTag, "Error deleteFlightPlansCD with \(uuidsStr) : \(error.localizedDescription)")
        }
    }

    func getFlightPlansCD(filteredBy field: String? = nil,
                          _ values: [Any]? = nil) -> [FlightPlan] {
        objects(filteredBy: field, values)
    }

    func getFlightPlansCD(withQuery query: String) -> [FlightPlan] {
        objects(withQuery: query)
    }
}

// MARK: - Private
private extension CoreDataServiceImpl {
    func getFlightPlansCDFetchRequest(withVersions versions: [String]) -> NSFetchRequest<FlightPlan> {
        let fetchRequest = FlightPlan.fetchRequest()
        var subPredicateList = [NSPredicate]()

        let apcIdPredicate = NSPredicate(format: "apcId == %@", userService.currentUser.apcId)
        subPredicateList.append(apcIdPredicate)

        let versionPredicate = NSPredicate(format: "version IN %@", versions)
        subPredicateList.append(versionPredicate)

        let toBeDeletedPredicate = NSPredicate(format: "isLocalDeleted == %@", NSNumber(value: false))
        subPredicateList.append(toBeDeletedPredicate)

        fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)

        return fetchRequest
    }
}
