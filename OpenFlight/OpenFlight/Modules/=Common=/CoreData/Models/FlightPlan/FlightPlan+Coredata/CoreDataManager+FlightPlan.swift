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
    ///    - flightPlan: FlightPlanModel to persist
    ///    - byUserUpdate: Bool to indicate in case of modifications, if those are made by User or by synchro process.
    func persist(_ flightPlan: FlightPlanModel, _ byUserUpdate: Bool)

    /// Persist or update flightPlans into CoreData
    /// - Parameters:
    ///    - flightPlansList: FlightPlanModel to persist
    ///    - byUserUpdate: Bool to indicate in case of modifications, if those are made by User or by synchro process.
    func persist(flightPlansList: [FlightPlanModel], _ byUserUpdate: Bool)

    /// Load FlightPlan from CoreData by key and value:
    /// example:
    ///     key   = "uuid"
    ///     value = "1234"
    /// - Parameters:
    ///     - key       : key of predicate
    ///     - value  : value of predicate
    ///
    /// - return:  FlightPlanModel object
    func loadFlightPlan(_ key: String, _ value: String) -> FlightPlanModel?

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
    /// - return:  FlightPlanModel
    func loadFlightPlan(_ keysValues: [String: String]) -> FlightPlanModel?

    /// Load FlightPlans from CoreData by key and value:
    /// example:
    ///     key   = "projectUuid"
    ///     value = "1234"
    /// - Parameters:
    ///     - key       : key of predicate
    ///     - value  : value of predicate
    ///
    /// - return:  FlightPlanModel  Array
    func loadFlightPlans(_ key: String, _ value: String) -> [FlightPlanModel]

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
    /// - return:  FlightPlanModel  Array
    func loadFlightPlans(_ keysValues: [String: String]) -> [FlightPlanModel]

    /// Load FlightPlans flagged tobeDeleted from CoreData
    /// - return: FlightPlans list to remove
    func loadFlightPlansToRemove() -> [FlightPlanModel]

    /// Load all FlightsPlans from CoreData
    /// - return : Array of FlightPlanModel
    func loadAllFlightsPlans() -> [FlightPlanModel]

    /// Remove FlightPlan from CoreData by UUID
    /// - Parameters:
    ///     - flightPlanUuid: flightPlanUuid to remove
    func removeFlightPlan(_ flightPlanUuid: String)

    /// Load FlightPlans from CoreData by excluding flightPlan from returned list of a given types:
    ///
    /// - Parameters:
    ///     - types : list of types of FlightPlans to exclude from list
    ///
    /// - Returns : FlightPlanModel  Array
    func loadFlightPlansByExcluding(types: [String]) -> [FlightPlanModel]

    /// Migrate FlightPlans made by Anonymous user to current logged user
    /// - Parameter completion: empty block indicates when process is finished
    func migrateFlightPlansToLoggedUser(_ completion: @escaping () -> Void)

    /// Loads the Flightplan linked to a specific pgyProject
    /// - Parameter pgyProjectId: id to get the flightplan from
    func loadFlightPlansByPgyProject(pgyProjectId: Int64) -> FlightPlanModel?

    /// Migrate FlightPlans made by a Logged user to ANONYMOUS user
    /// - Parameter completion: empty block indicates when process is finished
    func migrateFlightPlansToAnonymous(_ completion: @escaping () -> Void)
}

extension CoreDataServiceIml: FlightPlanRepository {

    public func persist(_ flightPlan: FlightPlanModel, _ byUserUpdate: Bool = true) {
        // Prepare content to save.
        guard let managedContext = currentContext else { return }

        // Prepare new CoreData entity
        let flightPlanObject: NSManagedObject?

        // Check object if exists.
        if let object = self.flightPlan(flightPlan.uuid) {
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

        // To ensure synchronisation
        // reset `synchroStatus´ and `fileSynchroStatus´ when the modifications made by User
        flightPlanObj.synchroStatus = ((byUserUpdate) ? 0 : flightPlan.synchroStatus) ?? 0
        flightPlanObj.fileSynchroStatus = ((byUserUpdate) ? 0 : flightPlan.fileSynchroStatus) ?? 0
        flightPlanObj.apcId = flightPlan.apcId
        flightPlanObj.type = flightPlan.type
        flightPlanObj.parrotCloudId = flightPlan.parrotCloudId
        flightPlanObj.parrotCloudToBeDeleted = flightPlan.parrotCloudToBeDeleted
        flightPlanObj.parrotCloudUploadUrl = flightPlan.parrotCloudUploadUrl
        flightPlanObj.projectUuid = flightPlan.projectUuid
        flightPlanObj.synchroDate = flightPlan.synchroDate
        flightPlanObj.fileSynchroDate = flightPlan.fileSynchroDate
        flightPlanObj.dataStringType = flightPlan.dataStringType
        flightPlanObj.uuid = flightPlan.uuid
        flightPlanObj.version = flightPlan.version
        flightPlanObj.customTitle = flightPlan.customTitle
        flightPlanObj.thumbnailUuid = flightPlan.thumbnailUuid
        flightPlanObj.pgyProjectId = flightPlan.pgyProjectId
        flightPlanObj.dataString = flightPlan.dataSetting?.toJSONString()
        flightPlanObj.mediaCustomId = flightPlan.mediaCustomId
        flightPlanObj.state = flightPlan.state.rawValue
        flightPlanObj.lastMissionItemExecuted = flightPlan.lastMissionItemExecuted
        flightPlanObj.mediaCount = flightPlan.mediaCount
        flightPlanObj.uploadedMediaCount = flightPlan.uploadedMediaCount
        flightPlanObj.lastUpdate = flightPlan.lastUpdate
        flightPlanObj.cloudLastUpdate = flightPlan.cloudLastUpdate
        flightPlanObj.lastUploadAttempt = flightPlan.lastUploadAttempt
        flightPlanObj.uploadAttemptCount = flightPlan.uploadAttemptCount

        if let project = self.project("uuid", flightPlan.projectUuid).first {
            flightPlanObj.ofProject = project
        }

        // Sets thumbnail of the FlightPlan if it exists
        if let thumbnailModel = flightPlan.thumbnail {
            let thumbnailObject = self.thumbnail("uuid", thumbnailModel.uuid).first ?? Thumbnail(context: managedContext)

            thumbnailObject.synchroStatus = (byUserUpdate) ? 0 : thumbnailModel.synchroStatus ?? 0
            thumbnailObject.fileSynchroStatus = (byUserUpdate) ? 0 : thumbnailModel.fileSynchroStatus ?? 0
            thumbnailObject.apcId = thumbnailModel.apcId
            thumbnailObject.uuid = thumbnailModel.uuid
            thumbnailObject.thumbnailData = thumbnailModel.thumbnailImageData
            thumbnailObject.lastUpdate = thumbnailModel.lastUpdate
            thumbnailObject.synchroDate = thumbnailModel.synchroDate
            thumbnailObject.fileSynchroDate = thumbnailModel.fileSynchroDate
            thumbnailObject.cloudLastUpdate = thumbnailModel.cloudLastUpdate
            thumbnailObject.parrotCloudId = thumbnailModel.parrotCloudId
            thumbnailObject.parrotCloudToBeDeleted = thumbnailModel.parrotCloudToBeDeleted

            flightPlanObj.thumbnail = thumbnailObject
        }

        managedContext.perform {
            do {
                try managedContext.save()
            } catch let error {
                ULog.e(.dataModelTag, "Error during persist FlightPlan with UUID \(flightPlan.uuid) into Coredata: \(error.localizedDescription)")
            }
        }
    }

    public func persist(flightPlansList: [FlightPlanModel], _ byUserUpdate: Bool = true) {
        for flightPlan in flightPlansList {
            self.persist(flightPlan, byUserUpdate)
        }
    }

    public func loadAllFlightsPlans() -> [FlightPlanModel] {
        // Return flightPlans of current User
        return self.flightPlan(["apcId": userInformation.apcId]).compactMap({$0.model()})
    }

    public func loadFlightPlan(_ key: String, _ value: String) -> FlightPlanModel? {
        return self.flightPlan([key: value]).first?.model()
    }

    public func loadFlightPlans(_ key: String, _ value: String) -> [FlightPlanModel] {
        return self.flightPlan([key: value]).map({$0.model()})
    }

    public func loadFlightPlan(_ keysValues: [String: String]) -> FlightPlanModel? {
        return self.flightPlan(keysValues).first?.model()
    }

    public func loadFlightPlans(_ keysValues: [String: String]) -> [FlightPlanModel] {
        return self.flightPlan(keysValues).map({$0.model()})
    }

    public func loadFlightPlansToRemove() -> [FlightPlanModel] {
        return self.loadAllFlightsPlans().filter({ $0.parrotCloudToBeDeleted })
    }

    public func removeFlightPlan(_ flightPlanUuid: String) {
        guard let managedContext = currentContext,
              let flightPlan = self.flightPlan(flightPlanUuid) else {
            return
        }

        // Remove related Thumbnail
        flightPlan.thumbnailUuid = nil

        managedContext.delete(flightPlan)

        managedContext.perform {
            do {
                try managedContext.save()
            } catch let error {
                ULog.e(.dataModelTag, "Error removing FlightPlan with UUID : \(flightPlanUuid) from CoreData : \(error.localizedDescription)")
            }
        }
    }

    public func migrateFlightPlansToLoggedUser(_ completion: @escaping () -> Void) {
        let fetchRequest: NSFetchRequest<FlightPlan> = FlightPlan.fetchRequest()
        guard let entityName = fetchRequest.entityName else {
            return
        }
        migrateAnonymousDataToLoggedUser(for: entityName) {
            completion()
        }
    }

    public func loadFlightPlansByExcluding(types: [String]) -> [FlightPlanModel] {
        return loadFlightPlansByExcluding(types: types).map({ $0.model() })
    }

    public func loadFlightPlansByPgyProject(pgyProjectId: Int64) -> FlightPlanModel? {
        return loadFlightPlansByPgyProject(pgyProjectId: pgyProjectId).map({ $0.model() })
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

// MARK: - Utils
internal extension CoreDataServiceIml {

    func loadFlightPlansByExcluding(types: [String]) -> [FlightPlan] {
        guard let managedContext = currentContext else {
            return []
        }

        var predicates: [NSPredicate] = []
        var typesPredicateLog = ""
        let fetchRequest: NSFetchRequest<FlightPlan> = FlightPlan.fetchRequest()

        for type in types {
            let predicate = NSPredicate(format: "type != %@", type)
            predicates.append(predicate)
            typesPredicateLog = String(format: "%@, %@", typesPredicateLog, type)
        }

        let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: predicates)
        fetchRequest.predicate = compoundPredicates

        // Sort by `lastUpdate´ descending
        let sort = NSSortDescriptor(key: "lastUpdate", ascending: false)
        fetchRequest.sortDescriptors = [sort]

        do {
            return try managedContext.fetch(fetchRequest)
        } catch let error {
            ULog.e(.dataModelTag, "Error during loading FlightPlans by excluding types: \(typesPredicateLog) from CoreData: \(error.localizedDescription)")
            return []
        }
    }

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

        /// Load their Thumbnail and FlightPlanFlights if they are not auto loaded by relationship
        flightPlans.indices.forEach {
            if flightPlans[$0].thumbnail == nil,
               let thumbnailUuid = flightPlans[$0].thumbnailUuid {
                flightPlans[$0].thumbnail = self.thumbnail("uuid", thumbnailUuid).first
            }

            if flightPlans[$0].flightPlanFlights == nil ||
                ((flightPlans[$0].flightPlanFlights?.isEmpty) != nil),
               let flightPlanUUid = flightPlans[$0].uuid {
                flightPlans[$0].flightPlanFlights = Set(self.flightPlanFlightKv("flightplanUuid", flightPlanUUid).map { $0 })
            }
        }

        return flightPlans
    }

    func loadFlightPlansByPgyProject(pgyProjectId: Int64) -> FlightPlan? {

        guard let managedContext = currentContext else {
            return nil
        }

        let fetchRequest: NSFetchRequest<FlightPlan> = FlightPlan.fetchRequest()
        let predicate = NSPredicate(format: "pgyProjectId == %ld", pgyProjectId)
        fetchRequest.predicate = predicate

        do {
            return try managedContext.fetch(fetchRequest).first
        } catch let error {
            ULog.e(.dataModelTag, "Error during loading FlightPlans by PgyProjectId: \(pgyProjectId) from CoreData: \(error.localizedDescription)")
            return nil
        }
    }
}

extension CoreDataServiceIml {
    func flightPlan(_ uuid: String) -> FlightPlan? {
        self.flightPlan(["uuid": uuid]).first
    }
}
