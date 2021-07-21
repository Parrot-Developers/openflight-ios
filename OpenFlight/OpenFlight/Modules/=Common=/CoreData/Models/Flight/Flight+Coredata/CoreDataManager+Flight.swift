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
    func persist(_ flight: FlightModel)

    /// Persist or update Flights into CoreData
    /// - Parameters:
    ///    - flightsList: flightsModel to persist
    func persist(_ flightsList: [FlightModel])

    /// Load Flight from CoreData by UUID
    /// - Parameters:
    ///     - flightUuid: flightUuid to search
    ///
    /// - return:  FlightModel object
    func loadFlight(_ flightUuid: String) -> FlightModel?

    /// Load all Flights from CoreData
    /// - return : Array of FlightModel
    func loadAllFlights() -> [FlightModel]

    /// Remove Flight from CoreData by UUID
    /// - Parameters:
    ///     - flightUuid: flightUuid to remove
    ///
    func removeFlight(_ flightUuid: String)
}

public protocol FlightSynchronizable {

    /// Load FlightsList to synchronize with Academy from CoreData
    /// - return : Array of FlightModel not synchronized
    func loadFlightsListToSync() -> [FlightModel]
}

extension CoreDataManager: FlightRepository {

    public func persist(_ flight: FlightModel) {
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
        flightObj.parrotCloudToBeDeleted = flight.parrotCloudToBeDeleted ?? false
        flightObj.parrotCloudUploadUrl = flight.parrotCloudUploadUrl
        flightObj.synchroDate = flight.synchroDate
        flightObj.synchroStatus = flight.synchroStatus ?? 0
        flightObj.cloudLastUpdate = flight.cloudLastUpdate
        flightObj.fileSynchroStatus = flight.fileSynchroStatus ?? 0

        /// Set it's related FlightPlanFlight
        if let dateExecutionFlight = flight.dateExecutionFlight,
           let flighPlanUuid = flight.flightPlanUuid {
            let flightPlanFlight = FlightPlanFlights(context: managedContext)
            flightPlanFlight.flightUuid = flight.uuid
            flightPlanFlight.flightplanUuid = flighPlanUuid
            flightPlanFlight.dateExecutionFlight = dateExecutionFlight
            flightObj.flightPlanFlights?.update(flightPlanFlight, shouldAdd: true)
        }

        do {
            try managedContext.save()
        } catch let error {
            ULog.e(.dataModelTag, "Error during persist Flight into Coredata: \(error.localizedDescription)")
        }
    }

    public func persist(_ flightsList: [FlightModel]) {
        for flight in flightsList {
            self.persist(flight)
        }
    }

    public func loadAllFlights() -> [FlightModel] {
        guard let managedContext = currentContext else {
            return []
        }

        let fetchRequest: NSFetchRequest<Flight> = Flight.fetchRequest()
        var flights = [FlightModel]()

        do {
            flights = try managedContext.fetch(fetchRequest).compactMap({$0.model()})
        } catch let error {
            ULog.e(.dataModelTag, "Error fetching Flights from Coredata: \(error.localizedDescription)")
            return []
        }

        /// Load FlightPlanFlight related to each Flight if is not auto loaded by relationship
        flights.indices.forEach {
            if flights[$0].flightPlanFlights == nil {
                flights[$0].flightPlanFlights = self.loadFlightPlanFlightKv("flightUuid", flights[$0].uuid)
            }
        }

        return flights
    }

    public func loadFlight(_ flightUuid: String) -> FlightModel? {
        return self.flight(flightUuid)?.model()
    }

    public func removeFlight(_ flightUuid: String) {
        guard let managedContext = currentContext,
              let flight = self.flight(flightUuid) else {
            return
        }

        managedContext.delete(flight)

        do {
            try managedContext.save()
        } catch let error {
            ULog.e(.dataModelTag, "Error removing Flight with UUID : \(flightUuid) from CoreData : \(error.localizedDescription)")
        }
    }
}

extension CoreDataManager: FlightSynchronizable {

    public func loadFlightsListToSync() -> [FlightModel] {
        guard let managedContext = currentContext else {
            return []
        }

        let fetchRequest: NSFetchRequest<Flight> = Flight.fetchRequest()
        let predicate = NSPredicate(format: "synchroStatus == %@", NSNumber(value: false))
        fetchRequest.predicate = predicate

        do {
            return try managedContext.fetch(fetchRequest).compactMap({$0.model()})
        } catch let error {
            ULog.e(.dataModelTag, "Error fetching Flights from Coredata: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - Utils
private extension CoreDataManager {

    func flight(_ flightUuid: String?) -> Flight? {
        guard let managedContext = currentContext,
              let flightUuid = flightUuid else {
            return nil
        }

        /// Fetch Flight by UUID
        let fetchRequest: NSFetchRequest<Flight> = Flight.fetchRequest()
        let predicate = NSPredicate(format: "uuid == %@", flightUuid)
        fetchRequest.predicate = predicate

        var flight: Flight?

        do {
            flight = try (managedContext.fetch(fetchRequest)).first
        } catch let error {
            ULog.e(.dataModelTag, "No Flight found with UUID : \(flightUuid) in CoreData : \(error.localizedDescription)")
            return nil
        }

        /// Load it's FlightPlanFlights if are not auto loaded by relationship
        if flight?.flightPlanFlights == nil {
            flight?.flightPlanFlights = Set(self.flightPlanFlightKv("flightUuid", flightUuid).map { $0 })
        }

        return flight
    }
}
