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

extension CoreDataServiceIml: ThumbnailRepository {

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
        if let object = self.thumbnail("uuid", thumbnail.uuid).first {
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
        thumbnailObj.ofFlight = flight

        managedContext.perform {
            do {
                try managedContext.save()
            } catch let error {
                ULog.e(.dataModelTag, "Error during persist Thumbnail uuid: \(thumbnail.uuid) into Coredata: \(error.localizedDescription)")
            }
        }
    }

    public func persist(_ thumbnailsList: [ThumbnailModel], _ byUserUpdate: Bool = true) {
        for thumbnail in thumbnailsList {
            self.persist(thumbnail, byUserUpdate)
        }
    }

    public func loadThumbnail(_ key: String, _ value: String) -> ThumbnailModel? {
        return self.thumbnail(key, value).first?.model()
    }

    public func loadThumbnail(parrotCloudId: Int64?) -> ThumbnailModel? {
        guard let parrotCloudId = parrotCloudId else {
            return nil
        }
        return self.thumbnail("parrotCloudId", "\(parrotCloudId)").first?.model()
    }

    public func loadThumbnailsToRemove() -> [ThumbnailModel] {
        return self.loadAllThumbnails().filter({ $0.parrotCloudToBeDeleted })
    }

    public func loadAllThumbnails() -> [ThumbnailModel] {
        return self.thumbnail("apcId", userInformation.apcId).compactMap({ $0.model() })
    }

    public func removeThumbnail(_ thumbnailUuid: String) {
        guard let managedContext = currentContext,
              let thumbnail = self.thumbnail("uuid", thumbnailUuid).first else {
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
        thumbnail("ofFlight.uuid", flight.uuid).first?.model()
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
internal extension CoreDataServiceIml {
    func thumbnail(_ key: String?, _ value: String?) -> [Thumbnail] {
        guard let managedContext = currentContext,
              let key = key,
              let value = value else {
            return []
        }

        /// fetch Thumbnails by Key Value
        let fetchRequest: NSFetchRequest<Thumbnail> = Thumbnail.fetchRequest()
        let predicate = NSPredicate(format: "%K == %@", key, value)
        fetchRequest.predicate = predicate

        do {
            return try (managedContext.fetch(fetchRequest))
        } catch let error {
            ULog.e(.dataModelTag, "No Thumbnail found with \(key): \(value) in CoreData: \(error.localizedDescription)")
            return []
        }
    }
}
