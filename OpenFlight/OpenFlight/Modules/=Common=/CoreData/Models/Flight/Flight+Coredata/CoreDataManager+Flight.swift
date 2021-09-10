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

public protocol FlightRepository: AnyObject {

    /// Persist or update Flight into CoreData
    /// - Parameters:
    ///    - flight: FlightModel to persist
    func persist(_ flight: FlightModel, _ byUserUpdate: Bool)

    /// Persist or update Flights into CoreData
    /// - Parameters:
    ///    - flightsList: flightsModel to persist
    func persist(_ flightsList: [FlightModel], _ byUserUpdate: Bool)

    /// Load Flight from CoreData by UUID
    /// - Parameters:
    ///     - flightUuid: flightUuid to search
    ///
    /// - return:  FlightModel object
    func loadFlight(_ flightUuid: String) -> FlightModel?

    /// Load Flights flagged tobeDeleted from CoreData
    /// - return:  FlightList
    func loadFlightsToRemove() -> [FlightModel]

    /// Load all Flights from CoreData
    /// - return : Array of FlightModel
    func loadAllFlights() -> [FlightModel]

    /// Remove Flight from CoreData
    /// - Parameters:
    ///     - flightUuid: flightUuid to remove
    func removeFlight(_ flightUuid: String)

    /// Load flight plans executed during a specific flight
    ///
    /// - Parameter flight: the flight
    func loadFlightPlans(for flight: FlightModel) -> [FlightPlanModel]

    /// Migrate flights made by Anonymous user to current logged user
    /// - Parameter completion: empty block indicates when process is finished
    func migrateFlightsToLoggedUser(_ completion: @escaping () -> Void)

    /// Migrate flights made by a Logged user to ANONYMOUS user
    /// - Parameter completion: empty block indicates when process is finished
    func migrateFlightsToAnonymous(_ completion: @escaping () -> Void)
}

extension CoreDataServiceIml: FlightRepository {

    public func persist(_ flight: FlightModel, _ byUserUpdate: Bool = true) {
        // Prepare content to save.
        guard let managedContext = currentContext else { return }

        // Prepare new CoreData entity
        let flightObject: NSManagedObject?

        // Check object if exists.
        if let object = self.flight(flight.uuid) {
            // Use persisted object.
            flightObject = object
        } else {
            // Create new object.
            let fetchRequest: NSFetchRequest<Flight> = Flight.fetchRequest()
            guard let name = fetchRequest.entityName else {
                return
            }
            flightObject = NSEntityDescription.insertNewObject(forEntityName: name, into: managedContext)
        }

        guard let flightObj = flightObject as? Flight else { return }

        // To ensure synchronisation
        // reset `synchroStatus´ and `fileSynchroStatus´ when the modifications are made by User
        flightObj.synchroStatus = ((byUserUpdate) ? 0 : flight.synchroStatus) ?? 0
        flightObj.fileSynchroStatus = ((byUserUpdate) ? 0 : flight.fileSynchroStatus) ?? 0

        flightObj.apcId = flight.apcId
        flightObj.title = flight.title
        flightObj.uuid = flight.uuid
        flightObj.version = flight.version
        flightObj.photoCount = flight.photoCount
        flightObj.videoCount = flight.videoCount
        flightObj.startLatitude = flight.startLatitude
        flightObj.startLongitude = flight.startLongitude
        flightObj.startTime = flight.startTime
        flightObj.batteryConsumption = flight.batteryConsumption
        flightObj.distance = flight.distance
        flightObj.duration = flight.duration
        flightObj.gutmaFile = flight.gutmaFile
        flightObj.parrotCloudId = flight.parrotCloudId
        flightObj.parrotCloudToBeDeleted = flight.parrotCloudToBeDeleted
        flightObj.parrotCloudUploadUrl = flight.parrotCloudUploadUrl
        flightObj.synchroDate = flight.synchroDate
        flightObj.fileSynchroDate = flight.fileSynchroDate
        flightObj.cloudLastUpdate = flight.cloudLastUpdate

        managedContext.perform {
            do {
                try managedContext.save()
            } catch let error {
                ULog.e(.dataModelTag, "Error during persist Flight UUID: \(flight.uuid) into Coredata: \(error.localizedDescription)")
            }
        }
    }

    public func persist(_ flightsList: [FlightModel], _ byUserUpdate: Bool = true) {
        for flight in flightsList {
            persist(flight, byUserUpdate)
        }
    }

    public func loadFlightsToRemove() -> [FlightModel] {
        return loadAllFlights().filter({ $0.parrotCloudToBeDeleted })
    }

    public func loadAllFlights() -> [FlightModel] {
        // Return flights of current User
        return flight("apcId", userInformation.apcId).compactMap({$0.model()}).sorted(by: {
            guard let date1 = $0.startTime, let date2 = $1.startTime else { return false }
            return date1.timeIntervalSince1970 > date2.timeIntervalSince1970
        })
    }

    public func loadFlight(_ flightUuid: String) -> FlightModel? {
        return flight(flightUuid)?.model()
    }

    public func removeFlight(_ flightUuid: String) {
        guard let managedContext = currentContext,
              let flight = flight(flightUuid) else {
            return
        }

        managedContext.delete(flight)

        managedContext.perform {
            do {
                try managedContext.save()
            } catch let error {
                ULog.e(.dataModelTag, "Error removing Flight with UUID : \(flightUuid) from CoreData : \(error.localizedDescription)")
            }
        }
    }

    public func loadFlightPlans(for flight: FlightModel) -> [FlightPlanModel] {
        guard let flightPlanFlights = self.flight(flight.uuid)?.flightPlanFlights else { return [] }
        let flightPlans = flightPlanFlights
            .reduce(into: [String: FlightPlanModel]()) { dict, fpf in
                if let flightPlan = fpf.ofFlightPlan?.model() {
                    dict[flightPlan.uuid] = flightPlan
                }
            }.values
        return Array(flightPlans)
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

// MARK: - Utils
private extension CoreDataServiceIml {

    func flight(_ key: String?, _ value: String?) -> [Flight] {
        guard let managedContext = currentContext else {
            return []
        }

        /// Fetch Flights
        let fetchRequest: NSFetchRequest<Flight> = Flight.fetchRequest()
        var flights = [Flight]()

        if let key = key,
           let value = value {
            let predicate = NSPredicate(format: "%K == %@", key, value)
            fetchRequest.predicate = predicate
        }

        do {
            flights = try (managedContext.fetch(fetchRequest))
        } catch let error {
            ULog.e(.dataModelTag, "No Flight found with \(key ?? ""): \(value ?? "") in CoreData : \(error.localizedDescription)")
            return []
        }

        return flights
    }
}

extension CoreDataServiceIml {
    func flight(_ uuid: String) -> Flight? {
        return flight("uuid", uuid).first
    }
}
