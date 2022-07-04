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

// MARK: - Repository Protocol
public protocol ThumbnailRepository: AnyObject {
    // MARK: __ Publisher
    /// Publisher notify changes
    var thumbnailsDidChangePublisher: AnyPublisher<Void, Never> { get }

    // MARK: __ Save Or Update
    /// Save or update Thumbnail into CoreData from ThumbnailModel
    /// - Parameters:
    ///    - thumbnailModel: ThumbnailModel to save or update
    ///    - byUserUpdate: Boolean if updated by user interaction
    ///    - toSynchro: Boolean if should be synchro
    func saveOrUpdateThumbnail(_ thumbnailModel: ThumbnailModel, byUserUpdate: Bool, toSynchro: Bool)

    /// Save or update Thumbnail into CoreData from ThumbnailModel
    /// - Parameters:
    ///    - thumbnailModel: ThumbnailModel to save or update
    ///    - byUserUpdate: Boolean if updated by user interaction
    ///    - toSynchro: Boolean if should be synchro
    ///    - completion: The callback returning the status.
    func saveOrUpdateThumbnail(_ thumbnailModel: ThumbnailModel,
                               byUserUpdate: Bool,
                               toSynchro: Bool,
                               completion: ((_ status: Bool) -> Void)?)

    // MARK: __ Get
    /// Get ThumbnailModel with uuid
    /// - Parameter uuid: Thumbnail's uuid to search
    /// - Returns ThumbnailModel object if not found
    func getThumbnail(withUuid uuid: String) -> ThumbnailModel?

    /// Get ThumbnailModel with flightt UUID
    /// - Parameter flightUuid: Flight's uuid to search
    /// - Returns ThumbnailModel object if not found
    func getThumbnail(withFlightUuid flightUuid: String) -> ThumbnailModel?

    /// Get ThumbnailModel with cloudId
    /// - Parameters:
    ///    - cloudId: Thumbnail's cloudId to search
    /// - Returns ThumbnailModel object if found
    func getThumbnail(withCloudId cloudId: Int) -> ThumbnailModel?

    /// Get count of all Thumbnails
    /// - Returns: Count of all Thumbnails
    func getAllThumbnailsCount() -> Int

    /// Get all ThumbnailModels from all Thumbnails in CoreData
    /// - Returns List of ThumbnailModels
    func getAllThumbnails() -> [ThumbnailModel]

    /// Get all ThumbnailModels to be deleted from Thumbnail in CoreData
    /// - Returns List of ThumbnailModels
    func getAllThumbnailsToBeDeleted() -> [ThumbnailModel]

    /// Get all ThumbnailModels locally modified from Thumbnails in CoreData
    /// - Returns:  List of ThumbnailModels
    func getAllModifiedThumbnails() -> [ThumbnailModel]

    /// Get thumbnails that are considered odd
    ///     - thumbnails that has no flight or flight plan associated
    /// - Parameter completion: the completion closure when finished
    func getOddThumbnails(_ completion: @escaping (([ThumbnailModel]) -> Void))

    // MARK: __ Delete
    /// Delete Thumbnail if cloudId is 0 (doesn't exist on server)
    ///  If cloudId is other than 0, then it is flagged to be deleted later on
    /// - Parameters
    ///     - uuids: List of uuid to search
    ///     - completion: the completion block with the deletion status (`true` in case of successful deletion)
    func deleteOrFlagToDeleteThumbnails(withUuids uuids: [String], completion: ((_ status: Bool) -> Void)?)

    /// Delete from CoreData the Thumbnail with specified `uuid`.
    /// - Parameters:
    ///    - uuid: the  Thumbnail's `uuid`
    ///    - completion: the completion block with the deletion status (`true` in case of successful deletion)
    func deleteThumbnail(withUuid uuid: String, completion: ((_ status: Bool) -> Void)?)

    /// Delete Thumbnail in CoreData with a specified list of uuids
    /// - Parameters:
    ///    - uuids: List of serials to search
    func deleteThumbnails(withUuids uuids: [String])
    func deleteThumbnails(withUuids uuids: [String],
                          completion: ((_ status: Bool) -> Void)?)

    // MARK: __ Related
    /// Migrate Thumbnails made by Anonymous user to current logged user
    /// - Parameter completion: empty block indicates when process is finished
    func migrateThumbnailToLoggedUser(_ completion: @escaping () -> Void)

    /// Migrate Thumbnails made by a Logged user to ANONYMOUS user
    /// - Parameter completion: empty block indicates when process is finished
    func migrateThumbnailToAnonymous(_ completion: @escaping () -> Void)
}

// MARK: - Implementation
extension CoreDataServiceImpl: ThumbnailRepository {
    // MARK: __ Publisher
    public var thumbnailsDidChangePublisher: AnyPublisher<Void, Never> {
        return thumbnailsDidChangeSubject.eraseToAnyPublisher()
    }

    // MARK: __ Save Or Update
    public func saveOrUpdateThumbnail(_ thumbnailModel: ThumbnailModel,
                                      byUserUpdate: Bool,
                                      toSynchro: Bool,
                                      completion: ((_ status: Bool) -> Void)?) {
        var modifDate: Date?

        performAndSave({ [unowned self] _ in
            var thumbnailObj: Thumbnail?
            if let existingThumbnail = getThumbnailCD(withUuid: thumbnailModel.uuid) {
                thumbnailObj = existingThumbnail
            } else if let newThumbnail = insertNewObject(entityName: Thumbnail.entityName) as? Thumbnail {
                thumbnailObj = newThumbnail
            }

            guard let thumbnail = thumbnailObj else {
                completion?(false)
                return false
            }

            var thumbnailModel = thumbnailModel

            if byUserUpdate {
                modifDate = Date()
                thumbnailModel.latestLocalModificationDate = modifDate
                thumbnailModel.synchroStatus = .notSync
            }

            var flight: Flight?
            if let flightUuid = thumbnailModel.flightUuid, let foundFlight = getFlightCD(withUuid: flightUuid) {
                flight = foundFlight
            }

            let logMessage = """
                🌉⬇️ saveOrUpdateThumbnail: \(thumbnail), \
                byUserUpdate: \(byUserUpdate), toSynchro: \(toSynchro), \
                thumbnailModel: \(thumbnailModel)
                """
            ULog.d(.dataModelTag, logMessage)

            thumbnail.update(fromThumbnailModel: thumbnailModel, withFlight: flight)

            return true
        }, { [unowned self] result in
            switch result {
            case .success:
                if let modifDate = modifDate, toSynchro {
                    latestThumbnailLocalModificationDate.send(modifDate)
                }

                thumbnailsDidChangeSubject.send()
                completion?(true)
            case .failure(let error):
                ULog.e(.dataModelTag,
                       "Error saveOrUpdateThumbnail with uuid: \(thumbnailModel.uuid) - error: \(error)")
                completion?(false)
            }
        })
    }

    public func saveOrUpdateThumbnail(_ thumbnailModel: ThumbnailModel, byUserUpdate: Bool, toSynchro: Bool) {
        saveOrUpdateThumbnail(thumbnailModel, byUserUpdate: byUserUpdate, toSynchro: toSynchro, completion: nil)
    }

    // MARK: __ Get
    public func getThumbnail(withUuid uuid: String) -> ThumbnailModel? {
        if let thumbnail = getThumbnailCD(withUuid: uuid) {
            return thumbnail.model()
        }
        return nil
    }

    public func getThumbnail(withFlightUuid flightUuid: String) -> ThumbnailModel? {
        if let thumbnail = getThumbnailCD(withFlightUuid: flightUuid) {
            return thumbnail.model()
        }
        return nil
    }

    public func getThumbnail(withCloudId cloudId: Int) -> ThumbnailModel? {
        getThumbnailsCD(filteredBy: "cloudId", [cloudId])
            .compactMap { $0.model() }
            .first
    }

    public func getAllThumbnailsCount() -> Int {
        return getAllThumbnailsCountCD(toBeDeleted: false)
    }

    public func getAllThumbnails() -> [ThumbnailModel] {
        return getAllThumbnailsCD(toBeDeleted: false).compactMap({ $0.model() })
    }

    public func getAllThumbnailsToBeDeleted() -> [ThumbnailModel] {
        return getAllThumbnailsCD(toBeDeleted: true).compactMap({ $0.model() })
    }

    public func getAllModifiedThumbnails() -> [ThumbnailModel] {
        return getThumbnailsCD(withQuery: "latestLocalModificationDate != nil").map({ $0.model() })
    }

    public func getOddThumbnails(_ completion: @escaping (([ThumbnailModel]) -> Void)) {
        getOddThumbnailsCD { thumbnails in
            let thumbnailModels = thumbnails.compactMap({ $0.model() })
            DispatchQueue.main.async {
                completion(thumbnailModels)
            }
        }
    }

    // MARK: __ Delete
    public func deleteOrFlagToDeleteThumbnails(withUuids uuids: [String], completion: ((_ status: Bool) -> Void)?) {
        var modifDate: Date?

        performAndSave({ [unowned self] context in
            let thumbnails = getThumbnailsCD(withUuids: uuids)
            guard !thumbnails.isEmpty else {
                completion?(false)
                return false
            }

            thumbnails.forEach({
                if $0.cloudId == 0 {
                    context.delete($0)
                } else {
                    modifDate = Date()
                    $0.latestLocalModificationDate = modifDate
                    $0.isLocalDeleted = true
                }
            })

            return true
        }, { [unowned self] result in
            switch result {
            case .success:
                if let modifDate = modifDate {
                    latestThumbnailLocalModificationDate.send(modifDate)
                }

                thumbnailsDidChangeSubject.send()
                completion?(true)
            case .failure(let error):
                ULog.e(.dataModelTag,
                       "Error deleteThumbnail(fromThumbnailModel:) with UUID: \(uuids.joined(separator: ", ")) - error: \(error.localizedDescription)")
                completion?(false)
            }
        })
    }

    public func deleteThumbnail(withUuid uuid: String, completion: ((_ status: Bool) -> Void)?) {

        performAndSave({ [unowned self] context in
            guard let thumbnail = getThumbnailCD(withUuid: uuid) else {
                completion?(false)
                return false
            }

            ULog.d(.dataModelTag, "🌉🗑 deleteThumbnail, uuid: \(uuid)")
            context.delete(thumbnail)
            return true
        }, { [unowned self] result in
            switch result {
            case .success:
                ULog.d(.dataModelTag, "🌉🗑🟢 deleteThumbnail, uuid: \(uuid)")
                thumbnailsDidChangeSubject.send()
                completion?(true)
            case .failure(let error):
                ULog.e(.dataModelTag,
                       "🌉🗑🔴 Error deleteThumbnail, uuid: \(uuid) - error: \(error.localizedDescription)")
                completion?(false)
            }
        })
    }

    public func deleteThumbnails(withUuids uuids: [String]) {
        deleteThumbnails(withUuids: uuids, completion: nil)
    }

    public func deleteThumbnails(withUuids uuids: [String],
                                 completion: ((_ status: Bool) -> Void)?) {
        guard !uuids.isEmpty else {
            completion?(true)
            return
        }

        batchDeleteAndSave({ _ in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Thumbnail.entityName)
            let uuidPredicate = NSPredicate(format: "uuid IN %@", uuids)
            fetchRequest.predicate = uuidPredicate

            return fetchRequest
        }, { [unowned self] result in
            switch result {
            case .success:
                thumbnailsDidChangeSubject.send()
                completion?(true)
            case .failure(let error):
                ULog.e(.dataModelTag, "Error deleteThumbnail with UUIDs error: \(error.localizedDescription)")
                completion?(false)
            }
        })
    }

    // MARK: __ Related
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

// MARK: - Internal
internal extension CoreDataServiceImpl {
    func getAllThumbnailsCountCD(toBeDeleted: Bool?) -> Int {
        let fetchRequest = Thumbnail.fetchRequest()

        let apcIdPredicate = NSPredicate(format: "apcId == %@", userService.currentUser.apcId)

        if let toBeDeleted = toBeDeleted {
            let parrotToBeDeletedPredicate = NSPredicate(format: "isLocalDeleted == %@", NSNumber(value: toBeDeleted))

            let subPredicateList: [NSPredicate] = [apcIdPredicate, parrotToBeDeletedPredicate]
            let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
            fetchRequest.predicate = compoundPredicates
        } else {
            fetchRequest.predicate = apcIdPredicate
        }

        return fetchCount(request: fetchRequest)
    }

    func getAllThumbnailsCD(toBeDeleted: Bool?) -> [Thumbnail] {
        let fetchRequest = Thumbnail.fetchRequest()

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

    func getThumbnailCD(withUuid uuid: String) -> Thumbnail? {
        let fetchRequest = Thumbnail.fetchRequest()
        let uuidPredicate = NSPredicate(format: "uuid == %@", uuid)

        fetchRequest.predicate = uuidPredicate
        fetchRequest.fetchLimit = 1

        return fetch(request: fetchRequest).first
    }

    func getThumbnailCD(withParrotCloudId parrotCloudId: Int64) -> Thumbnail? {
        let fetchRequest = Thumbnail.fetchRequest()
        let uuidPredicate = NSPredicate(format: "cloudId == %@", "\(parrotCloudId)")

        fetchRequest.predicate = uuidPredicate
        fetchRequest.fetchLimit = 1

        return fetch(request: fetchRequest).first
    }

    func getThumbnailCD(withFlightUuid flightUuid: String) -> Thumbnail? {
        let fetchRequest = Thumbnail.fetchRequest()
        let flightUuidPredicate = NSPredicate(format: "ofFlight.uuid == %@", flightUuid)

        fetchRequest.predicate = flightUuidPredicate
        fetchRequest.fetchLimit = 1

        return fetch(request: fetchRequest).first
    }

    func getThumbnailsCD(withUuids uuids: [String]) -> [Thumbnail] {
        guard !uuids.isEmpty else {
            return []
        }

        let fetchRequest = Thumbnail.fetchRequest()
        let uuidPredicate = NSPredicate(format: "uuid IN %@", uuids)
        fetchRequest.predicate = uuidPredicate

        let lastUpdateSortDesc = NSSortDescriptor(key: "lastUpdate", ascending: false)
        fetchRequest.sortDescriptors = [lastUpdateSortDesc]

        return fetch(request: fetchRequest)
    }

    func deleteThumbnailsCD(_ thumbnails: [Thumbnail]) {
        guard !thumbnails.isEmpty else {
            return
        }
        delete(thumbnails) { error in
            var uuidsStr = "[ "
            thumbnails.forEach({
                uuidsStr += "\($0.uuid ?? "-"), "
            })
            uuidsStr += "]"

            ULog.e(.dataModelTag, "Error deleteThumbnailsCD with \(uuidsStr): \(error.localizedDescription)")
        }
    }

    func getThumbnailsCD(filteredBy field: String? = nil,
                         _ values: [Any]? = nil) -> [Thumbnail] {
        objects(filteredBy: field, values)
    }

    func getThumbnailsCD(withQuery query: String) -> [Thumbnail] {
        objects(withQuery: query)
    }

    func getOddThumbnailsCD(_ completion: @escaping (([Thumbnail]) -> Void)) {
        let fetchRequest = Thumbnail.fetchRequest()

        let noFlightPredicate = NSPredicate(format: "SUBQUERY(ofFlight, $flight, $flight.thumbnail.uuid == uuid).@count == 0")
        let noFlightPlanPredicate = NSPredicate(format: "SUBQUERY(ofFlightPlan, $fp, $fp.thumbnail.uuid == uuid).@count == 0")
        let subPredicateList: [NSPredicate] = [noFlightPlanPredicate, noFlightPredicate]

        fetchRequest.predicate = NSCompoundPredicate.init(type: .and, subpredicates: subPredicateList)

        let lastUpdatedSortDesc = NSSortDescriptor(key: "lastUpdate", ascending: true)
        fetchRequest.sortDescriptors = [lastUpdatedSortDesc]

        return fetch(request: fetchRequest, completion: completion)
    }
}
