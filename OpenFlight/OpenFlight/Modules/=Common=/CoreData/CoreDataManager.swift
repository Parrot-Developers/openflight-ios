//    Copyright (C) 2020 Parrot Drones SAS
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

import UIKit
import CoreData
import Combine
import GroundSdk

/// CoreData Errors
public enum CoreDataError: Error {
    case unknownContext
    case objectNotFound
    case unableToDeleteObject
    case unableToSaveContext
    case unableToInsertObject
}

public protocol CoreDataService: AnyObject {
    /// Batch delete all stored data entities in CoreData
    /// to use only when switch between users accounts
    func batchDeleteData(completion: (() -> Void)?)

    /// Batch delete all stored data of users
    func deleteUsersData(completion: (() -> Void)?)

    /// Batch delete all stored  data of other users with apcId
    func deleteAllOtherUsersData(withApcId apcId: String, completion: ((_ status: Bool) -> Void)?)

    var latestFlightLocalModificationDatePublisher: AnyPublisher<Date, Never> { get }

    var latestFlightPlanLocalModificationDatePublisher: AnyPublisher<Date, Never> { get }

    var latestProjectLocalModificationDatePublisher: AnyPublisher<Date, Never> { get }

    var latestPgyProjectLocalModificationDatePublisher: AnyPublisher<Date, Never> { get }

    var latestThumbnailLocalModificationDatePublisher: AnyPublisher<Date, Never> { get }

    var latestFPlanFlightLocalModificationDatePublisher: AnyPublisher<Date, Never> { get }

}

/// CoreData Service
public class CoreDataServiceImpl: CoreDataService {

    // MARK: - Public Properties
    private let backgroundContext: NSManagedObjectContext
    /// Returns current Managed Object Context.
    public var currentContext: NSManagedObjectContext?
    /// Returns current PersistentContainer.
    private let persistentContainer: NSPersistentContainer
    /// Returns array of `ProjectModel` subject
    public var projects = CurrentValueSubject<[ProjectModel], Never>([])

    /// Returns if Flights core data changed
    public var flightsDidChangeSubject = CurrentValueSubject<Void, Never>(())

    /// Indicates when some flights are added into core data.
    public var flightsAddedSubject = CurrentValueSubject<[FlightModel], Never>([])

    /// Indicates when some flights are removed from core data.
    public var flightsRemovedSubject = CurrentValueSubject<[FlightModel], Never>([])

    /// Indicates when all flights are removed from core data.
    public var allFlightsRemovedSubject = PassthroughSubject<Void, Never>()

    /// Returns if Project core data changed
    public var projectsDidChangeSubject = CurrentValueSubject<Void, Never>(())

    /// Indicates when some Projects are added into core data.
    public var projectsAddedSubject = CurrentValueSubject<[ProjectModel], Never>([])

    /// Indicates when some Projects are removed from core data.
    public var projectsRemovedSubject = CurrentValueSubject<[ProjectModel], Never>([])

    /// Indicates when all projects are removed from core data.
    public var allProjectsRemovedSubject = PassthroughSubject<Void, Never>()

    /// Returns if PgyProject core data changed
    public var pgyProjectsDidChangeSubject = CurrentValueSubject<Void, Never>(())

    /// Returns if Flight Plan core data changed
    public var flightPlansDidChangeSubject = CurrentValueSubject<Void, Never>(())

    /// Returns if Thumbnail core data changed
    public var thumbnailsDidChangeSubject = CurrentValueSubject<Void, Never>(())

    /// Returns if Paired Drone core data changed
    public var dronesDidChangeSubject = CurrentValueSubject<Void, Never>(())

    var latestFlightLocalModificationDate = PassthroughSubject<Date, Never>()
    public var latestFlightLocalModificationDatePublisher: AnyPublisher<Date, Never> {
        latestFlightLocalModificationDate.eraseToAnyPublisher()
    }

    var latestFlightPlanLocalModificationDate = PassthroughSubject<Date, Never>()
    public var latestFlightPlanLocalModificationDatePublisher: AnyPublisher<Date, Never> {
        latestFlightPlanLocalModificationDate.eraseToAnyPublisher()
    }

    var latestFPlanFlightLocalModificationDate = PassthroughSubject<Date, Never>()
    public var latestFPlanFlightLocalModificationDatePublisher: AnyPublisher<Date, Never> {
        latestFPlanFlightLocalModificationDate.eraseToAnyPublisher()
    }

    var latestProjectLocalModificationDate = PassthroughSubject<Date, Never>()
    public var latestProjectLocalModificationDatePublisher: AnyPublisher<Date, Never> {
        latestProjectLocalModificationDate.eraseToAnyPublisher()
    }

    var latestPgyProjectLocalModificationDate = PassthroughSubject<Date, Never>()
    public var latestPgyProjectLocalModificationDatePublisher: AnyPublisher<Date, Never> {
        latestPgyProjectLocalModificationDate.eraseToAnyPublisher()
    }

    var latestThumbnailLocalModificationDate = PassthroughSubject<Date, Never>()
    public var latestThumbnailLocalModificationDatePublisher: AnyPublisher<Date, Never> {
        latestThumbnailLocalModificationDate.eraseToAnyPublisher()
    }

    internal var userService: UserService!

    public init(with persistentContainer: NSPersistentContainer,
                and userService: UserService) {
        self.persistentContainer = persistentContainer
        self.userService = userService

        backgroundContext = persistentContainer.newBackgroundContext()

        // `currentContext` is a main queue context dedicated to be used in the app (e.g. fetch object, update UI...)
        // `backgroundContext` is a private backgroubd queue context, set as parent of the `currentContext`.
        // `backgroundContext` is dedicated to save changes into DB file in background.

        currentContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        currentContext?.parent = backgroundContext
        // Our implementation is designed to have all changes being made in the current context.
        // Changes performed in current context are automatically propagated to its parent (the background context).
        // The background context is only used to save the context in the Core Data file.
        // So no need to automatically merge the `backgroundContext` changes to the `currentContext`.
        // Specific cases like BatchDelete are handled in dedicated method.
        // /!\ Depending on implementation, setting automaticallyMergesChangesFromParent = true
        //     can cause some potential unwanted behaviors (or crashs). This must be used carefully.
        currentContext?.automaticallyMergesChangesFromParent = false
        currentContext?.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Ask background context to perform a save (store in DB file) before terminating app.
        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: nil) { [weak self] _ in
            self?.saveChangesOnBG()
        }

        // Ask background context to perform a save (store in DB file) when a save is detected on the current context.
        // /!\ Ensure to ALWAYS use `queue: nil` when adding an observer to NSManagedObjectContext changes.
        // Passing the .main queue will freeze app.
        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: currentContext, queue: nil) { [weak self] _ in
            self?.saveChangesOnBG()
        }
    }

    private func saveChangesOnBG() {
        backgroundContext.perform {
            do {
                if self.backgroundContext.hasChanges {
                    try self.backgroundContext.save()
                }
            } catch let error {
                ULog.i(.dataModelTag, "Error in CoreDataServices with error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Public
extension CoreDataServiceImpl {
    public func batchDeleteData(completion: (() -> Void)?) {
        deleteAllUsersExceptAnonymous(completion: { [unowned self] _ in
            self.deleteUsersData(completion: completion)
        })
    }

    public func deleteUsersData(completion: (() -> Void)?) {
        var entityNames = persistentContainer.managedObjectModel.entities.compactMap({ $0.name })
        if let indexOfUserEntity = entityNames.firstIndex(of: UserParrot.entityName) {
            entityNames.remove(at: indexOfUserEntity)
        }

        deleteAllData(ofEntityNames: entityNames, completion: completion)
    }

    public func deleteAllOtherUsersData(withApcId apcId: String, completion: ((_ status: Bool) -> Void)?) {
        deleteAllOtherUsersExceptAnonymous(fromApcId: apcId)
        let dispatchGroup = DispatchGroup()

        persistentContainer.managedObjectModel.entities
            .compactMap { $0.name }
            .filter { $0 != UserParrot.entityName}
            .forEach { [weak self] in
                dispatchGroup.enter()
                self?.deleteAllUsersDataForEntityName(entityName: $0,
                                                      withApcId: apcId,
                                                      completion: { _ in
                    dispatchGroup.leave()
                })
            }

        dispatchGroup.notify(queue: .main, execute: {
            completion?(true)
        })
    }
}

// MARK: - Internal
internal extension CoreDataServiceImpl {
    // MARK: __ Context
    /// Commit unsaved changes to registered objects to the context’s parent store.
    /// - Parameters:
    ///     - errorHandler: Called when an error is catched while saving changes.
    func saveContext(_ completion: @escaping ((Result<Void, Error>) -> Void)) {
        guard let context = currentContext else {
            ULog.e(.dataModelTag, "Error saveContext: No current context found !")
            completion(.failure(CoreDataError.unknownContext))
            return
        }

        context.perform {
            guard context.hasChanges else {
                completion(.success())
                return
            }
            do {
                try context.save()

                completion(.success())
            } catch let error {
                ULog.e(.dataModelTag, "Error saving CoreData : \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    func performAndSave(_ task: @escaping ((_ context: NSManagedObjectContext) -> Bool), _ completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard let context = currentContext else {
            ULog.e(.dataModelTag, "Error saveContext: No current context found !")
            completion?(.failure(CoreDataError.unknownContext))
            return
        }

        context.performAndWait {
            if task(context) {
                context.perform {
                    guard context.hasChanges else {
                        ULog.w(.dataModelTag, "Trying to save context without any changes.")
                        completion?(.success())
                        return
                    }
                    do {
                        try context.save()

                        completion?(.success())
                    } catch let error {
                        ULog.e(.dataModelTag, "Error saving CoreData : \(error.localizedDescription)")
                        completion?(.failure(error))
                    }
                }
            }
        }
    }

    /*
     BatchDelete should only be used as a wiped out (or when dealing with 10k+ records),
        as batchDelete directly writes into the persistent store that bypasses any validation rules therefore relationships.
     When merging into context, it can leave faulty relationships that can cause an error when contexts are trying to be saved.
     */
    func batchDeleteAndSave(_ task: @escaping ((_ context: NSManagedObjectContext) -> NSFetchRequest<NSFetchRequestResult>?),
                            _ completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard let currentContext = currentContext else {
            ULog.e(.dataModelTag, "Error saveContext: No current context found !")
            completion?(.failure(CoreDataError.unknownContext))
            return
        }

        currentContext.perform { [unowned self] in
            let request = task(currentContext)

            guard let request = request else {
                completion?(.failure(CoreDataError.unableToDeleteObject))
                return
            }

            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            deleteRequest.resultType = .resultTypeObjectIDs

            do {
                let deleteResult = try currentContext.execute(deleteRequest) as? NSBatchDeleteResult
                ULog.i(.dataModelTag, "Performing batchDelete")

                // Extract the IDs of the deleted managed objectss from the request's result.
                if let objectIDs = deleteResult?.result as? [NSManagedObjectID] {
                    // When we delete the objects by fetching and then deleting, we're working through the context,
                    // so it knows about the changes being made. But it's not the case of BatchDelete.
                    // Batch updates work directly on the persistent store file instead of going through
                    // the managed object context, so the context doesn't know about them.
                    // Therefore we need to merge changes into all contexts used in the app (especially the currentContext).
                    NSManagedObjectContext.mergeChanges(
                        fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                        into: [backgroundContext, currentContext]
                    )

                    completion?(.success())
                } else {
                    completion?(.failure(CoreDataError.unableToSaveContext))
                }
            } catch let error {
                ULog.e(.dataModelTag, "batchDelete failed in CoreData : \(error.localizedDescription)")
                completion?(.failure(error))
            }
        }
    }

    /// Insert new NSManagedObject from entityName
    /// - Parameter entityName: entity name of the NSManagedObject
    func insertNewObject(entityName: String) -> NSManagedObject? {
        guard let currentContext = currentContext else {
            ULog.e(.dataModelTag, "Failed insertNewObject: No context found!")
            return nil
        }

        return NSEntityDescription.insertNewObject(forEntityName: entityName, into: currentContext)
    }

    // MARK: __ Fetch
    /// Fetch specified request
    /// - Parameter request: NSFetchRequest to specidifed
    /// - Returns list of NSManagedObject
    func fetch<T: NSManagedObject>(request: NSFetchRequest<T>) -> [T] {
        guard let currentContext = currentContext else {
            ULog.e(.dataModelTag, "Failed fetch request: No context found!")
            return []
        }

        var resultList: [T] = []

        currentContext.performAndWait {
            do {
                resultList = try currentContext.fetch(request)
            } catch let error {
                ULog.e(.dataModelTag, "Failed fetch request: \(error.localizedDescription)")
                resultList = []
            }
        }

        return resultList
    }

    func fetch<T: NSManagedObject>(request: NSFetchRequest<T>, completion: ((_ objects: [T]) -> Void)?) {
        backgroundContext.perform { [unowned self] in
            do {
                let resultList = try backgroundContext.fetch(request)
                completion?(resultList)
            } catch let error {
                ULog.e(.dataModelTag, "Failed fetch async request: \(error.localizedDescription)")
                completion?([])
            }
        }
    }

    /// Fetch count specified request
    /// - Parameter request: NSFetchRequest to specidifed
    /// - Returns Count of objects found
    func fetchCount<T: NSManagedObject>(request: NSFetchRequest<T>) -> Int {
        guard let currentContext = currentContext else {
            ULog.e(.dataModelTag, "Failed fetch count request: No context found!")
            return 0
        }

        var countResult: Int = 0

        currentContext.performAndWait {
            do {
                countResult = try currentContext.count(for: request)
            } catch let error {
                ULog.e(.dataModelTag, "Failed fetch count request: \(error.localizedDescription)")
                countResult = 0
            }
        }

        return countResult
    }

    /// Return objects according search criteria.
    ///
    /// - Parameters:
    ///    - field: Field used to filter result.
    ///    - values: Values used to filter result.
    /// - Returns:
    ///    - The objects list.
    func objects<T: NSManagedObject>(filteredBy field: String? = nil,
                                     _ values: [Any]? = nil) -> [T] {
        guard let entityName = T.entity().name else { return [] }

        let request = NSFetchRequest<T>(entityName: entityName)

        if let field = field,
           let values = values {
            let predicates = values.map {
                NSPredicate.equalPredicate(forField: field, andValue: $0)
            }
            request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        }

        return fetch(request: request)
    }

    /// Return objects according specified query.
    ///
    /// - Parameters:
    ///    - query: The quey to use as predicate (e.g. "key != nil").
    /// - Returns:
    ///    - The objects list.
    func objects<T: NSManagedObject>(withQuery query: String) -> [T] {
        guard let entityName = T.entity().name else { return [] }
        let request = NSFetchRequest<T>(entityName: entityName)
        request.predicate = NSPredicate(format: query)
        return fetch(request: request)
    }

    // MARK: __ Delete
    /// Delete a list of objects.
    ///
    /// - Parameters:
    ///     - objects: The objects to delete.
    func delete<T: NSManagedObject>(_ objects: [T], errorHandler: ((Error) -> Void)? = nil) {
        deleteObjects(objects) {
            if case .failure(let error) = $0 {
                errorHandler?(error)
            }
        }
    }

    func deleteObjects<T: NSManagedObject>(_ objects: [T], completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard currentContext != nil else {
            completion?(.failure(CoreDataError.unknownContext))
            return
        }

        var removedFlights: [FlightModel] = []
        var removedProjects: [ProjectModel] = []

        performAndSave({ context in
            if T.self is Flight.Type {
                removedFlights = objects.compactMap { $0 as? Flight }.compactMap { $0.modelLite() }
            }
            if T.self is Project.Type {
                removedProjects = objects.compactMap { $0 as? Project }.compactMap { $0.model() }
            }

            objects.forEach { context.delete($0) }
            return true
        }, { [unowned self] result in
            switch result {
            case .success:
                if T.self is Flight.Type {
                    self.flightsDidChangeSubject.send()
                    if !removedFlights.isEmpty {
                        self.flightsRemovedSubject.send(removedFlights)
                    }
                }
                if T.self is Project.Type {
                    self.projectsDidChangeSubject.send()
                    if !removedProjects.isEmpty {
                        self.projectsRemovedSubject.send(removedProjects)
                    }
                }
                if T.self is PgyProject.Type { self.pgyProjectsDidChangeSubject.send() }
                if T.self is FlightPlan.Type { self.flightPlansDidChangeSubject.send() }
                if T.self is Thumbnail.Type { self.thumbnailsDidChangeSubject.send() }
                if T.self is DronesData.Type { self.dronesDidChangeSubject.send() }
            case .failure:
                break
            }
            completion?(result)
        })
    }

    private func deleteAllUsersDataForEntityName(entityName: String,
                                                 withApcId apcId: String,
                                                 completion: ((_ status: Bool) -> Void)?) {
        guard currentContext != nil else {
            completion?(false)
            return
        }

        batchDeleteAndSave({ _ in
            let apcIdPredicate = NSPredicate(format: "apcId != %@", apcId)
            let anonymousPredicate = NSPredicate(format: "apcId != %@", User.anonymousId)
            let subPredicateList: [NSPredicate] = [apcIdPredicate, anonymousPredicate]
            let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            fetchRequest.predicate = compoundPredicates

            return fetchRequest
        }, { [unowned self] result in
            switch result {
            case .success:
                switch entityName {
                case Flight.entityName:
                    flightsDidChangeSubject.send()
                    allFlightsRemovedSubject.send()
                case Project.entityName:
                    projectsDidChangeSubject.send()
                    allProjectsRemovedSubject.send()
                case PgyProject.entityName:
                    pgyProjectsDidChangeSubject.send()
                case FlightPlan.entityName:
                    flightPlansDidChangeSubject.send()
                case Thumbnail.entityName:
                    thumbnailsDidChangeSubject.send()
                case DronesData.entityName:
                    dronesDidChangeSubject.send()
                default:
                    break
                }
                completion?(true)
            case .failure(let error):
                ULog.e(.dataModelTag, "An error is occured when batch delete entity \(entityName) in CoreData : \(error.localizedDescription)")
                completion?(false)
            }
        })
    }

    @discardableResult
    func deleteAllData(completion: (() -> Void)?) -> Error? {
        let entityNames = persistentContainer.managedObjectModel.entities.compactMap({ $0.name })
        deleteAllData(ofEntityNames: entityNames, completion: completion)

        return nil
    }

    func deleteAllData(ofEntityNames entityNames: [String], completion: (() -> Void)?) {
        guard !entityNames.isEmpty else {
            completion?()
            return
        }

        let dispatchGroup = DispatchGroup()

        entityNames.forEach { entityName in
            dispatchGroup.enter()
            deleteAllData(ofEntityName: entityName, completion: { _ in
                dispatchGroup.leave()
            })
        }

        dispatchGroup.notify(queue: .main, execute: {
            completion?()
        })
    }

    @discardableResult
    func deleteAllData(ofEntityName entityName: String, completion: ((_  status: Bool) -> Void)?) -> Error? {
        var deleteError: Error?

        batchDeleteAndSave({ _ in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)

            return fetchRequest
        }, { [unowned self] result in
            switch result {
            case .success:
                switch entityName {
                case Flight.entityName:
                    flightsDidChangeSubject.send()
                    allFlightsRemovedSubject.send()
                case Project.entityName:
                    projectsDidChangeSubject.send()
                    allProjectsRemovedSubject.send()
                case PgyProject.entityName:
                    pgyProjectsDidChangeSubject.send()
                case FlightPlan.entityName:
                    flightPlansDidChangeSubject.send()
                case Thumbnail.entityName:
                    thumbnailsDidChangeSubject.send()
                case DronesData.entityName:
                    dronesDidChangeSubject.send()
                default:
                    break
                }
                completion?(true)
            case .failure(let error):
                ULog.e(.dataModelTag, "An error is occured when batch delete entity in CoreData : \(error.localizedDescription)")
                deleteError = error
                completion?(false)
            }
        })

        return deleteError
    }

    // MARK: __ Migration utils
    /// Migrate anonymous data to current logged user
    /// - Parameters:
    ///     - entityName: Name of the entity contains the data to migrate
    ///     - completion: Closure indicates when the process is finished with list of UUIDs that have been migrated successfully
    func migrateAnonymousDataToLoggedUser(for entityName: String,
                                          _ completion: @escaping (_ migratedUuids: [String]) -> Void) {
        var migratedUuids: [String] = []

        guard let currentContext = currentContext else {
            completion(migratedUuids)
            return
        }

        let currentUser = userService.currentUser
        guard currentUser.isConnected else {
            ULog.e(.dataModelTag, "User must be logged in")
            completion(migratedUuids)
            return
        }

        let entity = NSEntityDescription.entity(forEntityName: entityName, in: currentContext)
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = entity
        let predicate = NSPredicate(format: "%K == %@", "apcId", User.anonymousId)
        request.predicate = predicate

        currentContext.performAndWait {
            do {
                if let requestResult = try currentContext.fetch(request) as? [NSManagedObject] {
                    if !requestResult.isEmpty {

                        requestResult.forEach { managedObject in
                            managedObject.setValue(currentUser.apcId, forKey: "apcId")
                            managedObject.setValue(0, forKey: "synchroStatus")
                            managedObject.setValue(Date(), forKey: "latestLocalModificationDate")

                            if managedObject.entity.propertiesByName.keys.contains("uuid"),
                               let uuid = managedObject.value(forKey: "uuid") as? String {
                                migratedUuids.append(uuid)
                            }
                        }

                    } else {
                        ULog.i(.dataModelTag, "No ANONYMOUS data found in: \(entityName)")
                    }
                }
            } catch let error {
                ULog.e(.dataModelTag,
                       "Migrate ANONYMOUS \(entityName) data to current logged User failed with error: \(error.localizedDescription)")
            }
        }

        saveContext {
            if case .failure(let error) = $0 {
                migratedUuids = []
                ULog.e(.dataModelTag,
                       "Migrate ANONYMOUS \(entityName) data to current logged User save failed with error: \(error.localizedDescription)")
            }

            completion(migratedUuids)
        }
    }

    /// Migrate logged user data to Anonymous
    /// - Parameters:
    ///     - entityName: Name of the entity contains the data to migrate
    ///     - completion: Empty block indicates when the process is finished
    func migrateLoggedToAnonymous(for entityName: String,
                                  _ completion: @escaping () -> Void) {
        guard let currentContext = currentContext else {
            completion()
            return
        }
        let apcId = userService.currentUser.apcId
        let entity = NSEntityDescription.entity(forEntityName: entityName, in: currentContext)
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = entity
        let predicate = NSPredicate(format: "%K == %@", "apcId", apcId)
        request.predicate = predicate

        currentContext.performAndWait {
            do {
                if let requestResult = try currentContext.fetch(request) as? [NSManagedObject] {
                    if !requestResult.isEmpty {
                        requestResult.forEach { managedObject in
                            managedObject.setValue(User.anonymousId, forKey: "apcId")
                            managedObject.setValue(0, forKey: "cloudId")
                            managedObject.setValue(nil, forKey: "latestCloudModificationDate")
                            managedObject.setValue(0, forKey: "synchroStatus")
                            managedObject.setValue(0, forKey: "synchroError")
                            managedObject.setValue(nil, forKey: "latestSynchroStatusDate")
                            managedObject.setValue(Date(), forKey: "latestLocalModificationDate")
                            managedObject.setValue(0, forKey: "fileSynchroStatus")
                            managedObject.setValue(nil, forKey: "fileSynchroDate")
                        }
                    } else {
                        ULog.i(.dataModelTag, "No data found in: \(entityName) for user apcId: \(apcId)")
                    }
                }
            } catch let error {
                ULog.e(.dataModelTag,
                       "Migrate logged user \(apcId) for \(entityName) to ANONYMOUS failed with error \(error.localizedDescription)")
            }
        }

        saveContext {
            if case .failure(let error) = $0 {
                ULog.e(.dataModelTag,
                       "Migrate logged user \(apcId) for \(entityName) to ANONYMOUS save failed with error \(error.localizedDescription)")
            }

            completion()
        }
    }
}
