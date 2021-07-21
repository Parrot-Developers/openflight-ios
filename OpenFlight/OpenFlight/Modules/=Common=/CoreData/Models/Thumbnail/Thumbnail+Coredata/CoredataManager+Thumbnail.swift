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
    func persist(_ thumbnail: ThumbnailModel)

    /// Persist or update thumbnails list into CoreData
    /// - Parameters:
    ///     - thumbnailsList: ThumbnailModel list to persist
    func persist(_ thumbnailsList: [ThumbnailModel])

    /// Load Thumbnail from CoreData by key and value:
    /// example:
    ///     key   = "uuid"
    ///     value = "1234"
    /// - Parameters:
    ///     - key       : key of predicate
    ///     - value  : value of predicate
    ///
    func loadThumbnail(_ key: String, _ value: String) -> ThumbnailModel?

    /// Load all thumbnail from CoreData
    /// return ThumbnailModel list if exist
    func loadAllThumbnails() -> [ThumbnailModel]

    /// Remove Thumbnail by Uuid from CoreData
    /// - Parameters:
    ///     - thumbnailUuid: Thumbnail identifier to remove
    func removeThumbnail(_ thumbnailUuid: String)
}

public protocol ThumbnailSynchronizable {

    /// Load ThumbnailList to synchronize with Academy from CoreData
    /// - return : Array of ThumbnailModel not synchronized
    func loadThumbnailListToSync() -> [ThumbnailModel]
}

extension CoreDataManager: ThumbnailRepository {

    public func persist(_ thumbnail: ThumbnailModel) {
        // Prepare content to save.
        guard let managedContext = currentContext else { return }

        // Prepare new CoreData entity
        let thumbnailObject: NSManagedObject?

        // Check object if exists.
        if let object = self.thumbnail("uuid", thumbnail.uuid) {
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

        thumbnailObj.uuid = thumbnail.uuid
        thumbnailObj.thumbnailData = thumbnail.thumbnailImageData
        thumbnailObj.synchroStatus = thumbnail.synchroStatus ?? 0
        thumbnailObj.synchroDate = thumbnail.synchroDate
        thumbnailObj.fileSynchroStatus = thumbnail.fileSynchroStatus ?? 0
        thumbnailObj.cloudLastUpdate = thumbnail.cloudLastUpdate
        thumbnailObj.parrotCloudId = thumbnail.parrotCloudId
        thumbnailObj.parrotCloudToBeDeleted = thumbnail.parrotCloudToBeDeleted ?? false

        do {
            try managedContext.save()
        } catch let error {
            ULog.e(.dataModelTag, "Error during persist Thumbnail into Coredata: \(error.localizedDescription)")
        }
    }

    public func persist(_ thumbnailsList: [ThumbnailModel]) {
        for thumbnail in thumbnailsList {
            self.persist(thumbnail)
        }
    }

    public func loadThumbnail(_ key: String, _ value: String) -> ThumbnailModel? {
        return self.thumbnail(key, value)?.model()
    }

    public func loadAllThumbnails() -> [ThumbnailModel] {
        guard let managedContext = currentContext else {
            return []
        }

        let fetchRequest: NSFetchRequest<Thumbnail> = Thumbnail.fetchRequest()

        do {
            return try managedContext.fetch(fetchRequest).compactMap({$0.model()})
        } catch let error {
            ULog.e(.dataModelTag, "Error fetching Thumbnails from Coredata: \(error.localizedDescription)")
            return []
        }
    }

    public func removeThumbnail(_ thumbnailUuid: String) {
        guard let managedContext = currentContext,
              let thumbnail = self.thumbnail("uuid", thumbnailUuid) else {
            return
        }

        managedContext.delete(thumbnail)

        do {
            try managedContext.save()
        } catch let error {
            ULog.e(.dataModelTag, "Error removing Thumbnail with uuid: \(thumbnailUuid) from CoreData: \(error.localizedDescription)")
        }
    }
}

extension CoreDataManager: ThumbnailSynchronizable {

    public func loadThumbnailListToSync() -> [ThumbnailModel] {
        guard let managedContext = currentContext else {
            return []
        }

        let fetchRequest: NSFetchRequest<Thumbnail> = Thumbnail.fetchRequest()
        let predicate = NSPredicate(format: "synchroStatus == %@", NSNumber(value: false))
        fetchRequest.predicate = predicate

        do {
            return try managedContext.fetch(fetchRequest).compactMap({$0.model()})
        } catch let error {
            ULog.e(.dataModelTag, "Error fetching Thumbnail from Coredata: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - Utils
internal extension CoreDataManager {
    func thumbnail(_ key: String?, _ value: String?) -> Thumbnail? {
        guard let managedContext = currentContext,
              let key = key,
              let value = value else {
            return nil
        }

        /// fetch Thumbnail by Key Value
        let fetchRequest: NSFetchRequest<Thumbnail> = Thumbnail.fetchRequest()
        let predicate = NSPredicate(format: "%K == %@", key, value)
        fetchRequest.predicate = predicate

        do {
            return try (managedContext.fetch(fetchRequest)).first
        } catch let error {
            ULog.e(.dataModelTag, "No Thumbnail found with \(key): \(value) in CoreData: \(error.localizedDescription)")
            return nil
        }
    }
}
