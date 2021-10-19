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

public protocol ThumbnailRepository: AnyObject {

    /// Persist or update thumbnail into CoreData
    /// - Parameters:
    ///     - thumbnail: ThumbnailModel to persist
    ///     - byUserUpdate: Bool to indicate in case of modifications, if those are made by User or by synchro process.
    func persist(_ thumbnail: ThumbnailModel, _ byUserUpdate: Bool)

    /// Persist or update thumbnails list into CoreData
    /// - Parameters:
    ///     - thumbnailsList: ThumbnailModel list to persist
    ///     - byUserUpdate: Bool to indicate in case of modifications, if those are made by User or by synchro process.
    func persist(_ thumbnailsList: [ThumbnailModel], _ byUserUpdate: Bool)

    /// Load Thumbnail from CoreData by key and value:
    /// example:
    ///     key   = "uuid"
    ///     value = "1234"
    /// - Parameters:
    ///     - key       : key of predicate
    ///     - value  : value of predicate
    ///
    func loadThumbnail(_ key: String, _ value: String) -> ThumbnailModel?

    /// Load Thumbnail from CoreData by ParrotCloudId:
    /// - Parameters:
    ///     - parrotCloudId : int64 value of parrotCloudId
    ///
    func loadThumbnail(parrotCloudId: Int64?) -> ThumbnailModel?

    /// Load Thumbnails flagged tobeDeleted from CoreData
    /// - return: ThumbnailsList
    func loadThumbnailsToRemove() -> [ThumbnailModel]

    /// Load all thumbnail from CoreData
    /// return ThumbnailModel list if exist
    func loadAllThumbnails() -> [ThumbnailModel]

    /// Remove Thumbnail by Uuid from CoreData
    /// - Parameters:
    ///     - thumbnailUuid: Thumbnail identifier to remove
    func removeThumbnail(_ thumbnailUuid: String)

    /// Perform remove Thumbnail with Flag
    /// - Parameters:
    ///     - thumbnail: ThumbnailModel to remove
    func performRemoveThumbnail(_ thumbnail: ThumbnailModel)

    /// Retrieve any thumbnail associated with a flight
    /// - Parameter flight: the flight
    func thumbnail(for flight: FlightModel) -> ThumbnailModel?

    /// Migrate Thumbnails made by Anonymous user to current logged user
    /// - Parameter completion: empty block indicates when process is finished
    func migrateThumbnailToLoggedUser(_ completion: @escaping () -> Void)

    /// Migrate Thumbnails made by a Logged user to ANONYMOUS user
    /// - Parameter completion: empty block indicates when process is finished
    func migrateThumbnailToAnonymous(_ completion: @escaping () -> Void)
}

extension CoreDataServiceImpl: ThumbnailRepository {

    public func persist(_ thumbnail: ThumbnailModel, _ byUserUpdate: Bool = true) {
        // Prepare content to save.
        guard let managedContext = currentContext else { return }

        var flight: Flight?
        if let flightUuid = thumbnail.flightUuid,
           let foundFlight = self.flight(flightUuid) {
            flight = foundFlight
        }

        // Prepare new CoreData entity
        let thumbnailObject: NSManagedObject?

        // Check object if exists.
        if let object = self.loadThumbnails("uuid", thumbnail.uuid, false).first {
            // Use persisted object.
            thumbnailObject = object
        } else {
            // Create new object.
            let fetchRequest: NSFetchRequest<Thumbnail> = Thumbnail.fetchRequest()
            guard let name = fetchRequest.entityName else {
                return
            }
            thumbnailObject = NSEntityDescription.insertNewObject(forEntityName: name, into: managedContext)
        }

        guard let thumbnailObj = thumbnailObject as? Thumbnail else { return }

        // To ensure synchronisation
        // reset `synchroStatus´ when the modifications made by User
        thumbnailObj.synchroStatus = ((byUserUpdate) ? 0 : thumbnail.synchroStatus) ?? 0
        thumbnailObj.fileSynchroStatus = ((byUserUpdate) ? 0 : thumbnail.fileSynchroStatus) ?? 0
        thumbnailObj.apcId = thumbnail.apcId
        thumbnailObj.uuid = thumbnail.uuid
        thumbnailObj.thumbnailData = thumbnail.thumbnailImageData
        thumbnailObj.lastUpdate = thumbnail.lastUpdate
        thumbnailObj.synchroDate = thumbnail.synchroDate
        thumbnailObj.fileSynchroDate = thumbnail.fileSynchroDate
        thumbnailObj.cloudLastUpdate = thumbnail.cloudLastUpdate
        thumbnailObj.parrotCloudId = thumbnail.parrotCloudId
        thumbnailObj.parrotCloudToBeDeleted = thumbnail.parrotCloudToBeDeleted
        if let flight = flight {
            thumbnailObj.ofFlight = flight
        }

        managedContext.perform {
            do {
                try managedContext.save()
                if byUserUpdate {
                    self.objectToUpload.send(thumbnail)
                }
            } catch let error as NSError {
                ULog.e(.dataModelTag, "Error during persist Thumbnail uuid: \(thumbnail.uuid) into Coredata: \(error.localizedDescription)")
            }
        }
    }

    public func persist(_ thumbnailsList: [ThumbnailModel], _ byUserUpdate: Bool = true) {
        for thumbnail in thumbnailsList {
            persist(thumbnail, byUserUpdate)
        }
    }

    public func loadThumbnail(_ key: String, _ value: String) -> ThumbnailModel? {
        return loadThumbnails(key, value)
            .first?.model()
    }

    public func loadThumbnail(parrotCloudId: Int64?) -> ThumbnailModel? {
        guard let parrotCloudId = parrotCloudId else {
            return nil
        }
        return loadThumbnails("parrotCloudId", "\(parrotCloudId)")
            .first?.model()
    }

    public func loadThumbnailsToRemove() -> [ThumbnailModel] {
        return loadThumbnails("apcId", userInformation.apcId, false)
            .filter({ $0.parrotCloudToBeDeleted })
            .compactMap({ $0.model() })
    }

    public func loadAllThumbnails() -> [ThumbnailModel] {
        return loadThumbnails("apcId", userInformation.apcId)
            .compactMap({ $0.model() })
    }

    public func performRemoveThumbnail(_ thumbnail: ThumbnailModel) {
        guard let managedContext = currentContext,
              let thumbnailObject = self.loadThumbnails("uuid", thumbnail.uuid, false).first else {
            return
        }

        if thumbnailObject.parrotCloudId == 0 {
            managedContext.delete(thumbnailObject)
        } else {
            thumbnailObject.parrotCloudToBeDeleted = true
            objectToRemove.send(thumbnail)
        }

        managedContext.perform {
            do {
                try managedContext.save()
            } catch let error {
                ULog.e(.dataModelTag, "Error perform deletion of Thumbnail with UUID : \(thumbnail.uuid) from CoreData : \(error.localizedDescription)")
            }
        }
    }

    public func removeThumbnail(_ thumbnailUuid: String) {
        guard let managedContext = currentContext,
              let thumbnail = self.loadThumbnails("uuid", thumbnailUuid, false).first else {
            return
        }

        managedContext.delete(thumbnail)

        managedContext.perform {
            do {
                try managedContext.save()
            } catch let error {
                ULog.e(.dataModelTag, "Error removing Thumbnail with uuid: \(thumbnailUuid) from CoreData: \(error.localizedDescription)")
            }
        }
    }

    public func thumbnail(for flight: FlightModel) -> ThumbnailModel? {
        loadThumbnails("ofFlight.uuid", flight.uuid)
            .first?.model()
    }

    public func migrateThumbnailToLoggedUser(_ completion: @escaping () -> Void) {
        let fetchRequest: NSFetchRequest<Thumbnail> = Thumbnail.fetchRequest()
        guard let entityName = fetchRequest.entityName else {
            return
        }
        migrateAnonymousDataToLoggedUser(for: entityName) {
            completion()
        }
    }

    public func migrateThumbnailToAnonymous(_ completion: @escaping () -> Void) {
        let fetchRequest: NSFetchRequest<Thumbnail> = Thumbnail.fetchRequest()
        guard let entityName = fetchRequest.entityName else {
            return
        }
        migrateLoggedToAnonymous(for: entityName) {
            completion()
        }
    }
}

// MARK: - Utils
internal extension CoreDataServiceImpl {
    /// Returns list of Thumbnails type of NSManagedObject by key and Value if needed
    /// - Parameters:
    ///     - key: Key of value to search
    ///     - value: Value to search
    ///     - onlyNotDeleted: flag to filter on flagged deleted object
    func loadThumbnails(_ key: String? = nil,
                        _ value: String? = nil,
                        _ onlyNotDeleted: Bool = true) -> [Thumbnail] {
        guard let managedContext = currentContext else {
            return []
        }

        var predicates: [NSPredicate] = []

        let fetchRequest: NSFetchRequest<Thumbnail> = Thumbnail.fetchRequest()

        /// fetch Thumbnails by Key Value
        if let key = key,
           let value = value {
            let predicate = NSPredicate(format: "%K == %@", key, value)
            predicates.append(predicate)
        }

        if onlyNotDeleted {
            let predicate = NSPredicate(format: "parrotCloudToBeDeleted == %@", NSNumber(value: false))
            predicates.append(predicate)
        }

        fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: predicates)

        do {
            return try managedContext.fetch(fetchRequest)
        } catch let error {
            ULog.e(.dataModelTag, "No Thumbnail found with \(key ?? ""): \(value ?? "") in CoreData: \(error.localizedDescription)")
            return []
        }
    }
}
