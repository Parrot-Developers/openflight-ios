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

// MARK: - Repository protocol
public protocol FlightRepository: AnyObject {
    // MARK: __ Publisher
    /// Publisher notify changes
    var flightsDidChangePublisher: AnyPublisher<Void, Never> { get }

    // MARK: __ Save Or Update
    /// Save or update Flight into CoreData from FlightModel
    /// - Parameters:
    ///    - flightModel: FlightModel to save or update
    ///    - byUserUpdate: Boolean if updated by user interaction
    ///    - toSynchro: Boolean if should be synchro
    ///    - completion: The callback returning the status.
    func saveOrUpdateFlight(_ flightModel: FlightModel,
                            byUserUpdate: Bool,
                            toSynchro: Bool,
                            withFileUploadNeeded: Bool,
                            completion: ((_ status: Bool) -> Void)?)

    /// Save or update Flight into CoreData from FlightModel
    /// - Parameters:
    ///    - flightModel: FlightModel to save or update
    ///    - byUserUpdate: Boolean if updated by user interaction
    ///    - toSynchro: Boolean if should be synchro
    func saveOrUpdateFlight(_ flightModel: FlightModel,
                            byUserUpdate: Bool,
                            toSynchro: Bool,
                            withFileUploadNeeded: Bool)
    func saveOrUpdateFlight(_ flightModel: FlightModel,
                            byUserUpdate: Bool,
                            toSynchro: Bool)

    /// - Parameters:
    ///    - flightModels: List of FlightModels to save or update
    ///    - byUserUpdate: Boolean if updated by user interaction
    ///    - toSynchro: Boolean if should be synchro
    func saveOrUpdateFlights(_ flightModels: [FlightModel], byUserUpdate: Bool, toSynchro: Bool)

    // MARK: __ Get
    /// Get FlightModel with UUID
    /// - Parameter withUuid: Flight's UUID to search
    /// - Returns: FlightModel object if not found
    func getFlight(withUuid uuid: String) -> FlightModel?

    /// Get FlightModels with a specified list of UUIDs
    /// - Parameter uuids: List of UUIDs to search
    /// - Returns: List of FlightModels
    func getFlights(withUuids uuids: [String]) -> [FlightModel]

    /// Get FlightModel with CloudId
    /// - Parameters:
    ///    - cloudId: Flight's CloudId to search
    /// - Returns: `FlightModel` object if found
    func getFlight(withCloudId cloudId: Int) -> FlightModel?

    /// Get count of all Flights
    /// - Returns: Count of all Flights
    func getAllFlightsCount() -> Int

    /// Get all FlightModels from all Flights in CoreData
    /// - Returns:  List of FlightModels
    func getAllFlights() -> [FlightModel]

    /// Get all FlightModels locally modified from Flights in CoreData
    /// - Returns:  List of FlightModels
    func getAllModifiedFlights() -> [FlightModel]

    /// Get all FlightModels to be deleted from Flights in CoreData
    /// - Returns: List of FlightModels
    func getAllFlightsToBeDeleted() -> [FlightModel]

    /// Get all FlightModels to be synchronize with Skyward
    /// - Returns: List of FlightModels
    func getAllFlightsToExternalSync() -> [FlightModel]

    // MARK: __ Delete
    /// Delete all Flights in CoreData
    func deleteAllFlights()

    /// Delete Flight in CoreData with a specified list of UUIDs
    /// - Parameter uuids: List of UUIDs to search
    /// - Note:
    ///     `Delete Rule` for Flight's flightplanflights is set to `Cascade`.
    ///     It means deleting the Flight will delete its flightplanflights.
    ///     (Same rule is applied to thumbnail)
    func deleteFlights(withUuids uuids: [String])
    func deleteFlights(withUuids uuids: [String], completion: ((_ status: Bool) -> Void)?)

    /// Delete Flight in CoreData from UUID
    /// - Parameter uuid: Flight's UUID to remove
    func deleteOrFlagToDeleteFlight(withUuid uuid: String)

    // MARK: __ Related
    /// Get list of FlightPlanModels executed during a specific FlightModel
    /// - Parameter flightModel: the specified FlightModel
    /// - Returns: List of FlightPlanModels
    func getFlightPlans(ofFlightModel flightModel: FlightModel) -> [FlightPlanModel]

    /// Migrate flights made by Anonymous user to current logged user
    /// - Parameter completion: empty block indicates when process is finished
    func migrateFlightsToLoggedUser(_ completion: @escaping () -> Void)

    /// Migrate flights made by a Logged user to ANONYMOUS user
    /// - Parameter completion: empty block indicates when process is finished
    func migrateFlightsToAnonymous(_ completion: @escaping () -> Void)
}

// MARK: - Implementation
extension CoreDataServiceImpl: FlightRepository {
    // MARK: __ Publisher
    public var flightsDidChangePublisher: AnyPublisher<Void, Never> {
        return flightsDidChangeSubject.eraseToAnyPublisher()
    }

    // MARK: __ Save Or Update
    public func saveOrUpdateFlight(_ flightModel: FlightModel,
                                   byUserUpdate: Bool,
                                   toSynchro: Bool,
                                   withFileUploadNeeded: Bool,
                                   completion: ((_ status: Bool) -> Void)?) {
        var modifDate: Date?

        performAndSave({ [unowned self] _ in
            var flightObj: Flight?
            if let existingFlight = getFlightCD(withUuid: flightModel.uuid) {
                flightObj = existingFlight
            } else if let newFlight = insertNewObject(entityName: Flight.entityName) as? Flight {
                flightObj = newFlight
            }

            guard let flight = flightObj else {
                completion?(false)
                return false
            }

            var flightModel = flightModel

            if byUserUpdate {
                modifDate = Date()
                flightModel.latestLocalModificationDate = modifDate
                if flightModel.synchroStatus == .fileUpload ||
                    withFileUploadNeeded {
                    flightModel.synchroStatus = .notSync
                }
           }

            let logMessage = """
                ✈️⬇️ saveOrUpdateFlight: \(flight), \
                byUserUpdate: \(byUserUpdate), toSynchro: \(toSynchro), \
                withFileUploadNeeded: \(withFileUploadNeeded), flightModel: \(flightModel)
                """
            ULog.d(.dataModelTag, logMessage)

            flight.update(fromFlightModel: flightModel)

            return true
        }, { [unowned self] result in
            switch result {
            case .success:
                if let modifDate = modifDate, toSynchro {
                    latestFlightLocalModificationDate.send(modifDate)
                }

                flightsDidChangeSubject.send()

                completion?(true)
            case .failure(let error):
                ULog.e(.dataModelTag, "Error saveOrUpdateFlight with UUID: \(flightModel.uuid) - error: \(error)")
                completion?(false)
            }
        })
    }

    public func saveOrUpdateFlight(_ flightModel: FlightModel,
                                   byUserUpdate: Bool,
                                   toSynchro: Bool,
                                   withFileUploadNeeded: Bool) {
        saveOrUpdateFlight(flightModel,
                           byUserUpdate: byUserUpdate,
                           toSynchro: toSynchro,
                           withFileUploadNeeded: withFileUploadNeeded,
                           completion: nil)
    }

    public func saveOrUpdateFlight(_ flightModel: FlightModel,
                                   byUserUpdate: Bool,
                                   toSynchro: Bool) {
        saveOrUpdateFlight(flightModel,
                           byUserUpdate: byUserUpdate,
                           toSynchro: toSynchro,
                           withFileUploadNeeded: false,
                           completion: nil)
    }

    public func saveOrUpdateFlights(_ flightModels: [FlightModel], byUserUpdate: Bool, toSynchro: Bool) {
        for flightModel in flightModels {
            saveOrUpdateFlight(flightModel,
                               byUserUpdate: byUserUpdate,
                               toSynchro: false,
                               withFileUploadNeeded: true)
        }
        if byUserUpdate && toSynchro {
            self.latestFlightLocalModificationDate.send(Date())
        }
    }

    // MARK: __ Get
    public func getFlight(withUuid uuid: String) -> FlightModel? {
        return getFlightCD(withUuid: uuid)?.model()
    }

    public func getFlights(withUuids uuids: [String]) -> [FlightModel] {
        return getFlightsCD(withUuids: uuids).map({ $0.model() })
    }

    public func getFlight(withCloudId cloudId: Int) -> FlightModel? {
        getFlightsCD(filteredBy: "cloudId", [cloudId])
            .compactMap { $0.model() }
            .first
    }

    public func getAllFlightsCount() -> Int {
        return getAllFlightsCountCD(toBeDeleted: false)
    }

    public func getAllFlights() -> [FlightModel] {
        return getAllFlightsCD(toBeDeleted: false).map({ $0.model() })
    }

    public func getAllFlightsToBeDeleted() -> [FlightModel] {
        return getAllFlightsCD(toBeDeleted: true).map({ $0.model() })
    }

    public func getAllFlightsToExternalSync() -> [FlightModel] {
        return getAllFlightsToExternalSyncCD()
            .map({ $0.model() })
            .sorted {
                let time0 = ($0.startTime?.timeIntervalSince1970 ?? 0)
                let time1 = ($1.startTime?.timeIntervalSince1970 ?? 0)
                return time0 < time1
            }
    }

    public func getAllModifiedFlights() -> [FlightModel] {
        return getFlightsCD(withQuery: "latestLocalModificationDate != nil").map({ $0.model() })
    }

    // MARK: __ Delete
    public func deleteAllFlights() {
        performAndSave({ [unowned self] context in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Flight.entityName)
            let apcIdPredicate = NSPredicate(format: "apcId == %@", userInformation.apcId)
            fetchRequest.predicate = apcIdPredicate

            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try context.execute(deleteRequest)

                flightsDidChangeSubject.send()
            } catch let error {
                ULog.e(.dataModelTag, "An error is occured when batch delete Flight in CoreData : \(error.localizedDescription)")
            }

            return true
        })
    }

    public func deleteFlights(withUuids uuids: [String]) {
        deleteFlights(withUuids: uuids, completion: nil)
    }

    public func deleteFlights(withUuids uuids: [String], completion: ((_ status: Bool) -> Void)?) {
        guard !uuids.isEmpty else {
            completion?(true)
            return
        }

        performAndSave({ context in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Flight.entityName)

            let uuidPredicate = NSPredicate(format: "uuid IN %@", uuids)
            fetchRequest.predicate = uuidPredicate

            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try context.execute(deleteRequest)
                return true
            } catch let error {
                ULog.e(.dataModelTag, "An error is occured when batch delete Flight in CoreData : \(error.localizedDescription)")
                completion?(false)
                return false
            }
        }, { [unowned self] result in
            switch result {
            case .success:
                flightsDidChangeSubject.send()
                completion?(true)
            case .failure(let error):
                ULog.e(.dataModelTag, "Error deleteFlight with UUIDs error: \(error.localizedDescription)")
                completion?(false)
            }
        })
    }

    public func deleteOrFlagToDeleteFlight(withUuid uuid: String) {
        var modifDate: Date?

        performAndSave({ [unowned self] context in
            guard let flightObject = getFlightCD(withUuid: uuid) else {
                return false

            }

            // Remove related Thumbnail
            if let relatedThumbnail = getThumbnail(withFlightUuid: uuid) {
                deleteOrFlagToDeleteThumbnail(withUuid: relatedThumbnail.uuid)
                flightObject.thumbnail = nil
            }

            deleteOrFlagToDeleteFPlanFlights(withFlightUuid: uuid)
            flightObject.flightPlanFlights = nil

            if flightObject.cloudId == 0 {
                context.delete(flightObject)
            } else {
                modifDate = Date()
                flightObject.latestLocalModificationDate = modifDate
                flightObject.isLocalDeleted = true
            }

            return true
        }, { [unowned self] result in
            switch result {
            case .success:
                if let modifDate = modifDate {
                    latestFlightLocalModificationDate.send(modifDate)
                }

                flightsDidChangeSubject.send()
            case .failure(let error):
                ULog.e(.dataModelTag, "Error deleteFlight with UUID: \(uuid) - error: \(error.localizedDescription)")
            }
        })
    }

    // MARK: __ Related
    public func getFlightPlans(ofFlightModel flightModel: FlightModel) -> [FlightPlanModel] {
        guard let flight = getFlightCD(withUuid: flightModel.uuid),
              let flightPlanFlights = flight.flightPlanFlights else {
                  return []
              }
        let flightPlans = flightPlanFlights
            .sorted { $0.dateExecutionFlight > $1.dateExecutionFlight }
            .compactMap { $0.ofFlightPlan?.model() }

        return flightPlans
    }

    public func migrateFlightsToLoggedUser(_ completion: @escaping () -> Void) {
        let fetchRequest: NSFetchRequest<Flight> = Flight.fetchRequest()
        guard let entityName = fetchRequest.entityName else {
            return
        }
        migrateAnonymousDataToLoggedUser(for: entityName) {
            completion()
        }
    }

    public func migrateFlightsToAnonymous(_ completion: @escaping () -> Void) {
        let fetchRequest: NSFetchRequest<Flight> = Flight.fetchRequest()
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
    func getAllFlightsCountCD(toBeDeleted: Bool?) -> Int {
        let fetchRequest = Flight.fetchRequest()

        let apcIdPredicate = NSPredicate(format: "apcId == %@", userInformation.apcId)

        if let toBeDeleted = toBeDeleted {
            let parrotToBeDeletedPredicate = NSPredicate(format: "isLocalDeleted == %@", NSNumber(value: toBeDeleted))

            let subPredicateList: [NSPredicate] = [apcIdPredicate, parrotToBeDeletedPredicate]
            let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
            fetchRequest.predicate = compoundPredicates
        } else {
            fetchRequest.predicate = apcIdPredicate
        }

        let desc1 = NSSortDescriptor.init(key: "startTime", ascending: false)
        fetchRequest.sortDescriptors = [desc1]

        return fetchCount(request: fetchRequest)
    }

    func getAllFlightsCD(toBeDeleted: Bool?) -> [Flight] {
        let fetchRequest = Flight.fetchRequest()

        let apcIdPredicate = NSPredicate(format: "apcId == %@", userInformation.apcId)

        if let toBeDeleted = toBeDeleted {
            let parrotToBeDeletedPredicate = NSPredicate(format: "isLocalDeleted == %@", NSNumber(value: toBeDeleted))

            let subPredicateList: [NSPredicate] = [apcIdPredicate, parrotToBeDeletedPredicate]
            let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
            fetchRequest.predicate = compoundPredicates
        } else {
            fetchRequest.predicate = apcIdPredicate
        }

        let desc1 = NSSortDescriptor.init(key: "startTime", ascending: false)
        fetchRequest.sortDescriptors = [desc1]

        return fetch(request: fetchRequest)
    }

    func getAllFlightsToExternalSyncCD() -> [Flight] {
        let fetchRequest = Flight.fetchRequest()

        let apcIdPredicate = NSPredicate(format: "apcId == %@", userInformation.apcId)
        let parrotToBeDeletedPredicate = NSPredicate(format: "isLocalDeleted == %@", NSNumber(value: false))
        let externalSyncPredicate = NSPredicate(format: "externalSynchroStatus == %i", 0)

        let subPredicateList: [NSPredicate] = [apcIdPredicate, parrotToBeDeletedPredicate, externalSyncPredicate]
        let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
        fetchRequest.predicate = compoundPredicates

        let desc1 = NSSortDescriptor.init(key: "startTime", ascending: false)
        fetchRequest.sortDescriptors = [desc1]

        return fetch(request: fetchRequest)
    }

    func getFlightCD(withUuid uuid: String) -> Flight? {
        let fetchRequest = Flight.fetchRequest()
        let uuidPredicate = NSPredicate(format: "uuid == %@", uuid)

        fetchRequest.predicate = uuidPredicate

        let startTimeSortDesc = NSSortDescriptor.init(key: "startTime", ascending: false)
        fetchRequest.sortDescriptors = [startTimeSortDesc]
        fetchRequest.fetchLimit = 1

        return fetch(request: fetchRequest).first
    }

    func getFlightsCD(withUuids uuids: [String]) -> [Flight] {
        guard !uuids.isEmpty else {
            return []
        }

        let fetchRequest = Flight.fetchRequest()
        let uuidPredicate = NSPredicate(format: "uuid IN %@", uuids)
        fetchRequest.predicate = uuidPredicate

        let startTimeSortDesc = NSSortDescriptor.init(key: "startTime", ascending: false)
        fetchRequest.sortDescriptors = [startTimeSortDesc]

        return fetch(request: fetchRequest)
    }

    func deleteFlightsCD(_ flights: [Flight]) {
        guard !flights.isEmpty else {
            return
        }
        delete(flights) { error in
            var uuidsStr = "[ "
            flights.forEach({
                uuidsStr += "\($0.uuid ?? "-"), "
            })
            uuidsStr += "]"

            ULog.e(.dataModelTag, "Error deleteFlightsCD with \(uuidsStr): \(error.localizedDescription)")
        }
    }

    func getFlightsCD(filteredBy field: String? = nil,
                      _ values: [Any]? = nil) -> [Flight] {
        objects(filteredBy: field, values)
    }

    func getFlightsCD(withQuery query: String) -> [Flight] {
        objects(withQuery: query)
    }
}
