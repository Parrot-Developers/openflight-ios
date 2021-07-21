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

public protocol FlightPlanRepository: AnyObject {

    /// Persist or update FlightPlan into CoreData
    /// - Parameters:
    ///    - flight: FlightPlanModell to persist
    func persist(_ flightPlan: FlightPlanModell)

    /// Persist or update flightPlans into CoreData
    /// - Parameters:
    ///    - flightPlansList: FlightPlanModell to persist
    func persist(flightPlansList: [FlightPlanModell])

    /// Load FlightPlan from CoreData by key and value:
    /// example:
    ///     key   = "uuid"
    ///     value = "1234"
    /// - Parameters:
    ///     - key       : key of predicate
    ///     - value  : value of predicate
    ///
    /// - return:  FlightPlanModell object
    func loadFlightPlan(_ key: String, _ value: String) -> FlightPlanModell?

    /// Load FlightPlan from CoreData by multiple keys and values:
    /// example:
    ///
    ///     let key    = "projectUuid"
    ///     let value  = "1234"
    ///
    ///     keysValues = [key: value]
    ///
    /// - Parameters:
    ///     - keysValues  : Dictionnary contains pairs of Keys and Values
    ///
    /// - return:  FlightPlanModell
    func loadFlightPlan(_ keysValues: [String: String]) -> FlightPlanModell?

    /// Load FlightPlans from CoreData by key and value:
    /// example:
    ///     key   = "projectUuid"
    ///     value = "1234"
    /// - Parameters:
    ///     - key       : key of predicate
    ///     - value  : value of predicate
    ///
    /// - return:  FlightPlanModell  Array
    func loadFlightPlans(_ key: String, _ value: String) -> [FlightPlanModell]

    /// Load FlightPlans from CoreData by multiple keys and values:
    /// example:
    ///
    ///     let key    = "projectUuid"
    ///     let value  = "1234"
    ///
    ///     keysValues = [key: value]
    ///
    /// - Parameters:
    ///     - keysValues  : Dictionnary contains pairs of Keys and Values
    ///
    /// - return:  FlightPlanModell  Array
    func loadFlightPlans(_ keysValues: [String: String]) -> [FlightPlanModell]

    /// Load all FlightsPlans from CoreData
    /// - return : Array of FlightPlanModell
    func loadAllFlightsPlans() -> [FlightPlanModell]

    /// Remove FlightPlan from CoreData by UUID
    /// - Parameters:
    ///     - flightPlanUuid: flightPlanUuid to remove
    ///
    func removeFlightPlan(_ flightPlanUuid: String)
}

public protocol FlightPlanSynchronizable {

    /// Load FlightPlansList to synchronize with Academy from CoreData
    /// - return : Array of FlightPlanModell not synchronized
    func loadFlightsPlansListToSync() -> [FlightPlanModell]
}

extension CoreDataManager: FlightPlanRepository {

    public func persist(_ flightPlan: FlightPlanModell) {
        // Prepare content to save.
        guard let managedContext = currentContext else { return }

        // Prepare new CoreData entity
        let flightPlanObject: NSManagedObject?

        // Check object if exists.
        if let object = self.flightPlan(["uuid": flightPlan.uuid]).first {
            // Use persisted object.
            flightPlanObject = object
        } else {
            // Create new object.
            let fetchRequest: NSFetchRequest<FlightPlan> = FlightPlan.fetchRequest()
            guard let name = fetchRequest.entityName else {
                return
            }
            flightPlanObject = NSEntityDescription.insertNewObject(forEntityName: name, into: managedContext)
        }

        guard let flightPlanObj = flightPlanObject as? FlightPlan else { return }

        flightPlanObj.parrotCloudId = flightPlan.parrotCloudId
        flightPlanObj.parrotCloudToBeDeleted = flightPlan.parrotCloudToBeDeleted ?? false
        flightPlanObj.parrotCloudUploadUrl = flightPlan.parrotCloudUploadUrl
        flightPlanObj.projectUuid = flightPlan.projectUuid
        flightPlanObj.synchroDate = flightPlan.synchroDate
        flightPlanObj.synchroStatus = flightPlan.synchroStatus ?? 0
        flightPlanObj.fileSynchroStatus = flightPlan.fileSynchroStatus ?? 0
        flightPlanObj.dataStringType = flightPlan.dataStringType
        flightPlanObj.dataString = flightPlan.dataString
        flightPlanObj.uuid = flightPlan.uuid
        flightPlanObj.version = flightPlan.version
        flightPlanObj.customTitle = flightPlan.customTitle
        flightPlanObj.thumbnailUuid = flightPlan.thumbnailUuid
        flightPlanObj.pgyProjectId = flightPlan.pgyProjectId
        flightPlanObj.mediaCustomId = flightPlan.mediaCustomId
        flightPlanObj.state = flightPlan.state
        flightPlanObj.lastMissionItemExecuted = flightPlan.lastMissionItemExecuted
        flightPlanObj.recoveryId = flightPlan.recoveryId
        flightPlanObj.mediaCount = flightPlan.mediaCount
        flightPlanObj.uploadedMediaCount = flightPlan.uploadedMediaCount
        flightPlanObj.lastUpdate = flightPlan.lastUpdate
        flightPlanObj.cloudLastUpdate = flightPlan.cloudLastUpdate

        // Sets thumbnail of the FlightPlan if it exists
        if let thumbnailModel = flightPlan.thumbnail {
            let thumbnail = Thumbnail(context: managedContext)
            thumbnail.uuid = thumbnailModel.uuid
            thumbnail.thumbnailData = thumbnailModel.thumbnailImageData
            thumbnail.synchroStatus = thumbnailModel.synchroStatus ?? 0
            thumbnail.synchroDate = thumbnailModel.synchroDate
            thumbnail.parrotCloudId = thumbnailModel.parrotCloudId
            thumbnail.parrotCloudToBeDeleted = thumbnailModel.parrotCloudToBeDeleted ?? false

            flightPlanObj.thumbnail = thumbnail
        }

        do {
            try managedContext.save()
        } catch let error {
            ULog.e(.dataModelTag, "Error during persist FlightPlan into Coredata: \(error.localizedDescription)")
        }
    }

    public func persist(flightPlansList: [FlightPlanModell]) {
        for flightPlan in flightPlansList {
            self.persist(flightPlan)
        }
    }

    public func loadAllFlightsPlans() -> [FlightPlanModell] {
        guard let managedContext = currentContext else {
            return []
        }

        let fetchRequest: NSFetchRequest<FlightPlan> = FlightPlan.fetchRequest()
        var flightPlans: [FlightPlanModell]

        do {
            flightPlans = try managedContext.fetch(fetchRequest).compactMap({$0.model()})
        } catch let error {
            ULog.e(.dataModelTag, "Error fetching FlightPlan from Coredata: \(error.localizedDescription)")
            return []
        }

        /// Load FlightPlanFlight related to each FlightPlan if is not auto loaded by relationship
        flightPlans.indices.forEach {
            if flightPlans[$0].flightPlanFlights == nil {
                flightPlans[$0].flightPlanFlights = self.loadFlightPlanFlightKv("flightplanUuid", flightPlans[$0].uuid)
            }
        }

        return flightPlans
    }

    public func loadFlightPlan(_ key: String, _ value: String) -> FlightPlanModell? {
        return self.flightPlan([key: value]).first?.model()
    }

    public func loadFlightPlans(_ key: String, _ value: String) -> [FlightPlanModell] {
        return self.flightPlan([key: value]).map({$0.model()})
    }

    public func loadFlightPlan(_ keysValues: [String: String]) -> FlightPlanModell? {
        return self.flightPlan(keysValues).first?.model()
    }

    public func loadFlightPlans(_ keysValues: [String: String]) -> [FlightPlanModell] {
        return self.flightPlan(keysValues).map({$0.model()})
    }

    public func removeFlightPlan(_ flightPlanUuid: String) {
        guard let managedContext = currentContext,
              let flightPlan = self.flightPlan(["uuid": flightPlanUuid]).first else {
            return
        }

        managedContext.delete(flightPlan)

        do {
            try managedContext.save()
        } catch let error {
            ULog.e(.dataModelTag, "Error removing FlightPlan with UUID : \(flightPlanUuid) from CoreData : \(error.localizedDescription)")
        }
    }
}

extension CoreDataManager: FlightPlanSynchronizable {

    public func loadFlightsPlansListToSync() -> [FlightPlanModell] {
        guard let managedContext = currentContext else {
            return []
        }

        let fetchRequest: NSFetchRequest<FlightPlan> = FlightPlan.fetchRequest()
        let predicate = NSPredicate(format: "synchroStatus == %@", NSNumber(value: false))
        fetchRequest.predicate = predicate

        do {
            return try managedContext.fetch(fetchRequest).compactMap({$0.model()})
        } catch let error {
            ULog.e(.dataModelTag, "Error fetching FlightPlans from Coredata: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - Utils
internal extension CoreDataManager {

    func flightPlan (_ keysValues: [String: String]) -> [FlightPlan] {
        guard let managedContext = currentContext else {
            return []
        }

        var predicates: [NSPredicate] = []
        var keyValuePredicateLog = ""

        /// Fetch FlightPlan by Keys and Values
        let fetchRequest: NSFetchRequest<FlightPlan> = FlightPlan.fetchRequest()

        for keyValue in keysValues {
            let predicate = NSPredicate(format: "%K == %@", keyValue.key, keyValue.value)
            keyValuePredicateLog = String(format: "%@ %@:%@", keyValuePredicateLog, keyValue.key, keyValue.value)
            predicates.append(predicate)
        }

        let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: predicates)
        fetchRequest.predicate = compoundPredicates

        var flightPlans = [FlightPlan]()

        do {
            flightPlans = try managedContext.fetch(fetchRequest)
        } catch let error {
            ULog.e(.dataModelTag, "No FlightPlan found with keys and values: \(keyValuePredicateLog) in CoreData : \(error.localizedDescription)")
            return []
        }

        /// Load it's Thumbnail and FlightPlanFlights if are not auto loaded by relationship
        flightPlans.indices.forEach {
            if flightPlans[$0].thumbnail == nil,
               let thumbnailUuid = flightPlans[$0].thumbnailUuid {
                flightPlans[$0].thumbnail = self.thumbnail("uuid", thumbnailUuid)
            }

            if flightPlans[$0].flightPlanFlights == nil,
               let flightPlanUUid = flightPlans[$0].uuid {
                flightPlans[$0].flightPlanFlights = Set(self.flightPlanFlightKv("flightplanUuid", flightPlanUUid).map { $0 })
            }
        }

        return flightPlans

    }
}
