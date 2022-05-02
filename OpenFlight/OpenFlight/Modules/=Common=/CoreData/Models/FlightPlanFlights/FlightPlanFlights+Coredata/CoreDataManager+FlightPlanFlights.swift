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

// TODO: Investigate the reason a dedicated table is needed to link a FP and a Flight.

// MARK: - Repository Protocol
public protocol FlightPlanFlightsRepository: AnyObject {
    // MARK: __ Save Or Update
    /// Save or update FlightPlanFlights into CoreData from FlightPlanFlightsModel
    /// - Parameters:
    ///    - fPlanFlightsModel: FlightPlanFlightsModel to save or update
    ///    - byUserUpdate: Boolean if updated by user interaction
    ///    - toSynchro: Boolean if should be synchro
    ///    - completion: The callback returning the status.
    func saveOrUpdateFPlanFlight(_ fPlanFlightsModel: FlightPlanFlightsModel,
                                 byUserUpdate: Bool,
                                 toSynchro: Bool,
                                 completion: ((_ status: Bool) -> Void)?)

    /// Save or update FlightPlanFlights into CoreData from FlightPlanFlightsModel
    /// - Parameters:
    ///    - fPlanFlightsModel: FlightPlanFlightsModel to save or update
    ///    - byUserUpdate: Boolean if updated by user interaction
    ///    - toSynchro: Boolean if should be synchro
    func saveOrUpdateFPlanFlight(_ fPlanFlightsModel: FlightPlanFlightsModel,
                                 byUserUpdate: Bool,
                                 toSynchro: Bool)

    /// Save or update FlightPlanFlights into CoreData from list of FlightPlanFlightsModel
    /// - Parameters:
    ///    - fPlanFlightsModels: List of FlightPlanFlightsModel to save or update
    ///    - byUserUpdate: Boolean if updated by user interaction
    ///    - toSynchro: Boolean if should be synchro
    func saveOrUpdateFPlanFlights(_ fPlanFlightsModels: [FlightPlanFlightsModel], byUserUpdate: Bool, toSynchro: Bool)

    // MARK: __ Get
    /// Get FlightPlanFlightsModel with uuid
    /// - Parameters:
    ///     - flightPlanUuid: FlightPlan UUID to search
    ///     - flightUuid:Flgiht UUID to Search
    /// - Returns FlightPlanFlightsModel object if not found
    func getFPlanFlight(withFlightPlanUuid flightPlanUuid: String, andFlightUuid flightUuid: String) -> FlightPlanFlightsModel?

    /// Get all FlightPlanFlightsModels from all FlightPlanFlightsDatas in CoreData
    /// - Returns  List of FlightPlanFlightsDataModels
    func getAllFPlanFlights() -> [FlightPlanFlightsModel]

    /// Get all FlightPlanFlightsModels to be deleted from FlightPlanFlights in CoreData
    /// - Returns List of FlightPlanFlightsModels
    func getAllFPlanFlightsToBeDeleted() -> [FlightPlanFlightsModel]

    /// Get all FlightPlanFlightsModels locally modified from FlightPlanFlights in CoreData
    /// - Returns:  List of FlightPlanFlightsModels
    func getAllModifiedLinks() -> [FlightPlanFlightsModel]

    // MARK: __ Delete
    /// Delete FlightPlanFlights with flightPlan UUID
    /// - Parameter flightPlanUuid: FlightPlan UUID to search
    func deleteOrFlagToDeleteFPlanFlights(withFlightPlanUuid flightPlanUuid: String)

    /// Delete FlightPlanFlights with flight UUID
    /// - Parameter flightUuid: Flight UUID to search
    func deleteOrFlagToDeleteFPlanFlights(withFlightUuid flightUuid: String)

    /// Remove FlightPlanFlights in CoreData with a specified list of uuids
    /// - Parameters:
    ///    - flightPlanUuid: FlightPlan UUID to search
    ///    - flightUuid: Flight UUID to search
    func deleteFPlanFlight(withFlightPlanUuid flightPlanUuid: String, andFlightUuid flightUuid: String)

    /// Remove FlightPlanFlights in CoreData with a specified cloudId
    /// - Parameters:
    ///    - linkCloudId: The link's (FlightPlanFlight) cloudId
    func deleteFPlanFlight(withCloudId linkCloudId: Int,
                           completion: ((_ status: Bool) -> Void)?)

    // MARK: __ Related
    /// Migrate FlightPlanFlights made by Anonymous user to current logged user
    /// - Parameter completion: empty block indicates when process is finished
    func migrateFPlanFlightsToLoggedUser(_ completion: @escaping () -> Void)

    /// Migrate flights made by a Logged user to ANONYMOUS user
    /// - Parameter completion: empty block indicates when process is finished
    func migrateFPlanFlightsToAnonymous(_ completion: @escaping () -> Void)
}

// MARK: - Implementation
extension CoreDataServiceImpl: FlightPlanFlightsRepository {
    // MARK: __ Save Or Update
    public func saveOrUpdateFPlanFlight(_ fPlanFlightsModel: FlightPlanFlightsModel,
                                        byUserUpdate: Bool,
                                        toSynchro: Bool,
                                        completion: ((_ status: Bool) -> Void)?) {
        var modifDate: Date?

        performAndSave({ [unowned self] _ in
            guard let flightPlan = getFlightPlanCD(withUuid: fPlanFlightsModel.flightplanUuid) else {
                ULog.w(.dataModelTag, "Error saveOrUpdateFPlanFlight, couldn't find flightPlan \(fPlanFlightsModel.flightplanUuid)")
                completion?(false)
                return false
            }
            guard let flight = getFlightCD(withUuid: fPlanFlightsModel.flightUuid) else {
                ULog.w(.dataModelTag, "Error saveOrUpdateFPlanFlight, couldn't find flight \(fPlanFlightsModel.flightUuid)")
                completion?(false)
                return false
            }

            var fPlanFlightsObj: FlightPlanFlights?
            if let existingFPlanFlights = getFPlanFlightCD(withFlightPlanUuid: fPlanFlightsModel.flightplanUuid,
                                                           andFlightUuid: fPlanFlightsModel.flightUuid) {
                fPlanFlightsObj = existingFPlanFlights
            } else if let newFPlanFlights = insertNewObject(entityName: FlightPlanFlights.entityName) as? FlightPlanFlights {
                fPlanFlightsObj = newFPlanFlights
            }

            guard let fPlanFlight = fPlanFlightsObj else {
                completion?(false)
                return false
            }

            var fPlanFlightsModel = fPlanFlightsModel

            if byUserUpdate {
                modifDate = Date()
                fPlanFlightsModel.latestLocalModificationDate = modifDate
            }

            let logMessage = """
                🔗⬇️ saveOrUpdateFPlanFlight: \(fPlanFlight), \
                byUserUpdate: \(byUserUpdate), toSynchro: \(toSynchro), \
                fPlanFlightsModel: \(fPlanFlightsModel)
                """
            ULog.d(.dataModelTag, logMessage)

            fPlanFlight.update(fromFPlanFlightsModel: fPlanFlightsModel,
                               withFlightPlan: flightPlan,
                               withFlight: flight)

            return true
        }, { [unowned self] result in
            switch result {
            case .success:
                if let modifDate = modifDate, toSynchro {
                    latestFPlanFlightLocalModificationDate.send(modifDate)
                }

                completion?(true)
            case .failure(let error):
                let errorFlightPlanStr = "flightPlan: \(fPlanFlightsModel.flightplanUuid)"
                let errorFlightStr = "flightPlan: \(fPlanFlightsModel.flightUuid)"
                ULog.e(.dataModelTag,
                        "Error saveOrUpdateFPlanFlight with \(errorFlightPlanStr) \(errorFlightStr) - error: \(error)")
                completion?(false)
            }
        })
    }

    public func saveOrUpdateFPlanFlight(_ fPlanFlightsModel: FlightPlanFlightsModel, byUserUpdate: Bool, toSynchro: Bool) {
        saveOrUpdateFPlanFlight(fPlanFlightsModel, byUserUpdate: byUserUpdate, toSynchro: toSynchro, completion: nil)
    }

    public func saveOrUpdateFPlanFlights(_ fPlanFlightsModels: [FlightPlanFlightsModel], byUserUpdate: Bool, toSynchro: Bool) {
        for fPlanFlightsModel in fPlanFlightsModels {
            saveOrUpdateFPlanFlight(fPlanFlightsModel, byUserUpdate: byUserUpdate, toSynchro: false)
        }
        if byUserUpdate && toSynchro {
            self.latestFPlanFlightLocalModificationDate.send(Date())
        }
    }

    // MARK: __ Get
    public func getFPlanFlight(withFlightPlanUuid flightPlanUuid: String, andFlightUuid flightUuid: String) -> FlightPlanFlightsModel? {
        return getFPlanFlightCD(withFlightPlanUuid: flightPlanUuid, andFlightUuid: flightUuid)?.model()
    }

    public func getAllFPlanFlights() -> [FlightPlanFlightsModel] {
        return getAllFPlanFlightsCD(toBeDeleted: false).map({ $0.model() })
    }

    public func getAllFPlanFlightsToBeDeleted() -> [FlightPlanFlightsModel] {
        return getAllFPlanFlightsCD(toBeDeleted: true).map({ $0.model() })
    }

    public func getAllModifiedLinks() -> [FlightPlanFlightsModel] {
        return getFPlanFlightsCD(withQuery: "latestLocalModificationDate != nil").map({ $0.model() })
    }

    // MARK: __ Delete
    public func deleteOrFlagToDeleteFPlanFlights(withFlightPlanUuid flightPlanUuid: String) {
        var toSynchroList = [FlightPlanFlights]()
        var toDeleteList = [FlightPlanFlights]()
        let modifDate = Date()

        performAndSave({ [unowned self] _ in
            let fPlanFlights = getFPlanFlightsCD(withFlightPlanUuid: flightPlanUuid, toBeDeleted: false)

            for fPlanFlight in fPlanFlights {
                if fPlanFlight.cloudId != 0 {
                    fPlanFlight.latestLocalModificationDate = modifDate
                    fPlanFlight.isLocalDeleted = true
                    toSynchroList.append(fPlanFlight)
                } else {
                    toDeleteList.append(fPlanFlight)
                }
            }

            deleteFPlanFlightsCD(toDeleteList)

            return true
        }, { [unowned self] result in
            switch result {
            case .success:
                latestFPlanFlightLocalModificationDate.send(modifDate)
            case .failure(let error):
                var uuidsStr = "[ "
                toSynchroList.forEach({
                    uuidsStr += "(\($0.flightplanUuid ?? "-")|\($0.flightUuid ?? "-")), "
                })
                uuidsStr += "]"
                ULog.e(.dataModelTag,
                       "Error deleteOrFlagToDeleteFPlanFlights with \(uuidsStr) - error: \(error)")
            }
        })
    }

    public func deleteOrFlagToDeleteFPlanFlights(withFlightUuid flightUuid: String) {
        let modifDate = Date()
        var toSynchroList = [FlightPlanFlights]()
        var toDeleteList = [FlightPlanFlights]()

        performAndSave({ [unowned self] _ in
            let fPlanFlights = getFPlanFlightsCD(withFlightUuid: flightUuid, toBeDeleted: false)

            for fPlanFlight in fPlanFlights {
                if fPlanFlight.cloudId != 0 {
                    fPlanFlight.latestLocalModificationDate = modifDate
                    fPlanFlight.isLocalDeleted = true
                    toSynchroList.append(fPlanFlight)
                } else {
                    toDeleteList.append(fPlanFlight)
                }
            }

            deleteFPlanFlightsCD(fPlanFlights)

            return true
        }, { [unowned self] result in
            switch result {
            case .success:
                latestFPlanFlightLocalModificationDate.send(modifDate)
            case .failure(let error):
                var uuidsStr = "[ "
                toSynchroList.forEach({
                    uuidsStr += "(\($0.flightplanUuid ?? "-")|\($0.flightUuid ?? "-")), "
                })
                uuidsStr += "]"
                ULog.e(.dataModelTag,
                       "Error deleteOrFlagToDeleteFPlanFlights with \(uuidsStr) - error: \(error)")
            }
        })
    }

    public func deleteFPlanFlight(withFlightPlanUuid flightPlanUuid: String, andFlightUuid flightUuid: String) {
        performAndSave({ [unowned self] _ in
            guard let fPlanFlight = getFPlanFlightCD(withFlightPlanUuid: flightUuid, andFlightUuid: flightUuid) else {
                return false
            }

            deleteFPlanFlightsCD([fPlanFlight])
            return false
        })
    }

    public func deleteFPlanFlight(withCloudId linkCloudId: Int,
                                  completion: ((_ status: Bool) -> Void)?) {

        performAndSave({ [unowned self] _ in
            guard let link = getFPlanFlightsCD(withQuery: "cloudId == \(linkCloudId)").first else {
                completion?(true)
                return false
            }

            deleteObjects([link]) {
                switch $0 {
                case .success:
                    completion?(true)
                case .failure(let error):
                    ULog.e(.dataModelTag, "Error while deleting FPlan / Flight link : \(error.localizedDescription)")
                    completion?(false)
                }
            }

            return false
        })
    }

    // MARK: __ Related
    public func migrateFPlanFlightsToLoggedUser(_ completion: @escaping () -> Void) {
        let fetchRequest: NSFetchRequest<FlightPlanFlights> = FlightPlanFlights.fetchRequest()
        guard let entityName = fetchRequest.entityName else {
            return
        }
        migrateAnonymousDataToLoggedUser(for: entityName) {
            completion()
        }
    }

    public func migrateFPlanFlightsToAnonymous(_ completion: @escaping () -> Void) {
        let fetchRequest: NSFetchRequest<FlightPlanFlights> = FlightPlanFlights.fetchRequest()
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
    func getAllFPlanFlightsCD(toBeDeleted: Bool?) -> [FlightPlanFlights] {
        let fetchRequest = FlightPlanFlights.fetchRequest()

        let apcIdPredicate = NSPredicate(format: "apcId == %@", userService.currentUser.apcId)

        if let toBeDeleted = toBeDeleted {
            let parrotToBeDeletedPredicate = NSPredicate(format: "isLocalDeleted == %@", NSNumber(value: toBeDeleted))

            let subPredicateList: [NSPredicate] = [apcIdPredicate, parrotToBeDeletedPredicate]
            let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
            fetchRequest.predicate = compoundPredicates
        } else {
            fetchRequest.predicate = apcIdPredicate
        }

        return fetch(request: fetchRequest)
    }

    func getFPlanFlightCD(withFlightPlanUuid flightPlanUuid: String, andFlightUuid flightUuid: String) -> FlightPlanFlights? {
        let fetchRequest = FlightPlanFlights.fetchRequest()
        var subPredicateList = [NSPredicate]()

        let flightPlanUuidPredicate = NSPredicate(format: "flightplanUuid == %@", flightPlanUuid)
        subPredicateList.append(flightPlanUuidPredicate)

        let flightUuidPredicate = NSPredicate(format: "flightUuid == %@", flightUuid)
        subPredicateList.append(flightUuidPredicate)

        let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
        fetchRequest.predicate = compoundPredicates
        fetchRequest.fetchLimit = 1

        return fetch(request: fetchRequest).first
    }

    func getFPlanFlightsCD(withFlightPlanUuid flightPlanUuid: String, toBeDeleted: Bool?) -> [FlightPlanFlights] {
        let fetchRequest = FlightPlanFlights.fetchRequest()

        let flightPlanUuidPredicate = NSPredicate(format: "flightplanUuid == %@", flightPlanUuid)

        if let toBeDeleted = toBeDeleted {
            let parrotToBeDeletedPredicate = NSPredicate(format: "isLocalDeleted == %@", NSNumber(value: toBeDeleted))

            let subPredicateList: [NSPredicate] = [flightPlanUuidPredicate, parrotToBeDeletedPredicate]
            let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
            fetchRequest.predicate = compoundPredicates
        } else {
            fetchRequest.predicate = flightPlanUuidPredicate
        }

        return fetch(request: fetchRequest)
    }

    func getFPlanFlightsCD(withFlightUuid flightUuid: String, toBeDeleted: Bool?) -> [FlightPlanFlights] {
        let fetchRequest = FlightPlanFlights.fetchRequest()

        let flightUuidPredicate = NSPredicate(format: "flightUuid == %@", flightUuid)

        if let toBeDeleted = toBeDeleted {
            let parrotToBeDeletedPredicate = NSPredicate(format: "isLocalDeleted == %@", NSNumber(value: toBeDeleted))

            let subPredicateList: [NSPredicate] = [flightUuidPredicate, parrotToBeDeletedPredicate]
            let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
            fetchRequest.predicate = compoundPredicates
        } else {
            fetchRequest.predicate = flightUuidPredicate
        }

        return fetch(request: fetchRequest)
    }

    func deleteFPlanFlightsCD(_ fPlanFlights: [FlightPlanFlights]) {
        guard !fPlanFlights.isEmpty else {
            return
        }
        delete(fPlanFlights) { error in
            var uuidsStr = "[ "
            fPlanFlights.forEach({
                uuidsStr += "(\($0.flightplanUuid ?? "-")|\($0.flightUuid ?? "-")), "
            })
            uuidsStr += "]"

            ULog.e(.dataModelTag, "Error deleteFPlanFlightsCD with \(uuidsStr): \(error.localizedDescription)")
        }
    }

    func getFPlanFlightsCD(withQuery query: String) -> [FlightPlanFlights] {
        objects(withQuery: query)
    }
}
