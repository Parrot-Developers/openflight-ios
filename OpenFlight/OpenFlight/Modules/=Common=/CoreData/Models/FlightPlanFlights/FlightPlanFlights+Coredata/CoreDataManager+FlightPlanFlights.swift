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

public protocol FlightPlanFlightsRepository: AnyObject {

    /// Persist or update FlightPlanFlight into CoreData
    /// - Parameters:
    ///    - flightPlanFlight: FlightPlanFlightsModel to persist
    func persist(_ flightPlanFlight: FlightPlanFlightsModel)

    /// Persist or update flightPlanFlights into CoreData
    /// - Parameters:
    ///    - flightPlansFlightsList: flightsPlansFlightsModel to persist
    func persist(_ flightPlansFlightsList: [FlightPlanFlightsModel])

    /// Load FlightPlanFlight from CoreData by flightUuid and flightplanUuid
    /// - Parameters:
    ///     - flightUuid: flightUuid to search
    ///     - flightplanUuid: flightplanUuid to search
    /// - return:  FlightPlanFlightsModel object
    func loadFlightPlanFlight(_ flightUuid: String, _ flightplanUuid: String) -> FlightPlanFlightsModel?

    /// Load FlightPlanFlight from CoreData by Key and Value
    ///  Example: return flightExecution for a given FlightPlan Uuid
    /// - Parameters:
    ///     - Key:   Key identifier
    ///     - Value: Value of Key
    /// - return:  [FlightPlanFlightsModel]
    func loadFlightPlanFlightKv(_ key: String, _ value: String) -> [FlightPlanFlightsModel]?

    /// Load all FlightsPlansFlights from CoreData
    /// - return : Array of FlightPlanFlightsModel
    func loadAllFlightsPlansFlights() -> [FlightPlanFlightsModel]
}

public protocol FlightPlanFlightsSynchronizable {

    /// Load FlightPlanFlightsList to synchronize with Academy from CoreData
    /// - return : Array of FlightPlanFlightsModel not synchronized
    func loadFlightsPlansFlightsListToSync() -> [FlightPlanFlightsModel]
}

extension CoreDataManager: FlightPlanFlightsRepository {

    public func persist(_ flightPlanFlight: FlightPlanFlightsModel) {
        // Prepare content to save.
        guard let managedContext = currentContext else { return }

        // Prepare new CoreData entity
        let flightPlanFlightObject: NSManagedObject?

        // Check object if exists.
        if let object = self.flightPlanFlight(flightPlanFlight.flightUuid, flightPlanFlight.flightplanUuid) {
            // Use persisted object.
            flightPlanFlightObject = object
        } else {
            // Create new object.
            let fetchRequest: NSFetchRequest<FlightPlan> = FlightPlan.fetchRequest()
            guard let name = fetchRequest.entityName else {
                return
            }
            flightPlanFlightObject = NSEntityDescription.insertNewObject(forEntityName: name, into: managedContext)
        }

        guard let flightPlanFlightObj = flightPlanFlightObject as? FlightPlanFlights else { return }

        flightPlanFlightObj.flightUuid = flightPlanFlight.flightUuid
        flightPlanFlightObj.flightplanUuid = flightPlanFlight.flightplanUuid
        flightPlanFlightObj.dateExecutionFlight = flightPlanFlight.dateExecutionFlight
        flightPlanFlightObj.synchroStatus = flightPlanFlight.synchroStatus ?? 0
        flightPlanFlightObj.synchroDate = flightPlanFlight.synchroDate
        flightPlanFlightObj.parrotCloudId = flightPlanFlight.parrotCloudId
        flightPlanFlightObj.parrotCloudToBeDeleted = flightPlanFlight.parrotCloudToBeDeleted

        do {
            try managedContext.save()
        } catch let error {
            ULog.e(.dataModelTag, "Error during persist FlightPlanFlights into Coredata: \(error.localizedDescription)")
        }
    }

    public func persist(_ flightPlansFlightsList: [FlightPlanFlightsModel]) {
        for flightPlanFlight in flightPlansFlightsList {
            self.persist(flightPlanFlight)
        }
    }

    public func loadFlightPlanFlight(_ flightUuid: String, _ flightplanUuid: String) -> FlightPlanFlightsModel? {
        return self.flightPlanFlight(flightUuid, flightplanUuid)?.model()
    }

    public func loadFlightPlanFlightKv(_ key: String, _ value: String) -> [FlightPlanFlightsModel]? {
        return self.flightPlanFlightKv(key, value).map({$0.model()})
    }

    public func loadAllFlightsPlansFlights() -> [FlightPlanFlightsModel] {
        guard let managedContext = currentContext else {
            return []
        }

        let fetchRequest: NSFetchRequest<FlightPlanFlights> = FlightPlanFlights.fetchRequest()

        do {
            return try managedContext.fetch(fetchRequest).compactMap({$0.model()})
        } catch let error {
            ULog.e(.dataModelTag, "Error fetching FlightPlanFlight from Coredata: \(error.localizedDescription)")
            return []
        }
    }
}

extension CoreDataManager: FlightPlanFlightsSynchronizable {
    public func loadFlightsPlansFlightsListToSync() -> [FlightPlanFlightsModel] {
        guard let managedContext = currentContext else {
            return []
        }

        let fetchRequest: NSFetchRequest<FlightPlanFlights> = FlightPlanFlights.fetchRequest()
        let predicate = NSPredicate(format: "synchroStatus == %@", NSNumber(value: false))
        fetchRequest.predicate = predicate

        do {
            return try managedContext.fetch(fetchRequest).compactMap({$0.model()})
        } catch let error {
            ULog.e(.dataModelTag, "Error fetching FlightPlanFlight from Coredata: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - Utils
internal extension CoreDataManager {

    func flightPlanFlight(_ flightUuid: String?, _ flightplanUuid: String?) -> FlightPlanFlights? {
        guard let managedContext = currentContext,
              let flightUuid = flightUuid,
              let flightplanUuid = flightplanUuid else {
            return nil
        }

        /// fetch FlightPlanFlights by flightUuid and flightplanUuid
        let fetchRequest: NSFetchRequest<FlightPlanFlights> = FlightPlanFlights.fetchRequest()
        let predicate = NSPredicate(format: "flightUuid == %@ AND flightplanUuid == %@", flightUuid, flightplanUuid)
        fetchRequest.predicate = predicate

        do {
            return try (managedContext.fetch(fetchRequest)).first
        } catch let error {
            ULog.e(.dataModelTag,
                   "No FlightPlanFlights found with flightUuid: \(flightUuid) and flightplanUuid: \(flightplanUuid) in CoreData: \(error.localizedDescription)")
            return nil
        }
    }

    func flightPlanFlightKv(_ key: String?, _ value: String?) -> [FlightPlanFlights] {
        guard let managedContext = currentContext,
              let key = key,
              let value = value else {
            return []
        }

        /// fetch FlightPlanFlights by Key and Value
        let fetchRequest: NSFetchRequest<FlightPlanFlights> = FlightPlanFlights.fetchRequest()
        let predicate = NSPredicate(format: "%K == %@", key, value)
        fetchRequest.predicate = predicate

        do {
            return try (managedContext.fetch(fetchRequest))
        } catch let error {
            ULog.e(.dataModelTag,
                   "No FlightPlanFlights found with \(key): \(value) in CoreData: \(error.localizedDescription)")
            return []
        }
    }
}
