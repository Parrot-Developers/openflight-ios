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
    func batchDeleteData()

    /// Batch delete all stored data of users
    func deleteUsersData()

    /// Batch delete all stored  data of other users with apcId
    func deleteAllOtherUsersData(withApcId apcId: String)

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

        currentContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        currentContext?.parent = backgroundContext
        currentContext?.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: nil) { [weak self] _ in
            self?.saveChangesOnBG()
        }

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
    public func batchDeleteData() {
        deleteAllUsersExceptAnonymous()
        deleteUsersData()
    }

    public func deleteUsersData() {
        var entityNames = persistentContainer.managedObjectModel.entities.compactMap({ $0.name })
        if let indexOfUserEntity = entityNames.firstIndex(of: UserParrot.entityName) {
            entityNames.remove(at: indexOfUserEntity)
        }

        entityNames.forEach { entityName in
            deleteAllData(ofEntityName: entityName)
        }
    }

    public func deleteAllOtherUsersData(withApcId apcId: String) {
        deleteAllOtherUsersExceptAnonymous(fromApcId: apcId)
        persistentContainer.managedObjectModel.entities
            .compactMap { $0.name }
            .filter { $0 != UserParrot.entityName}
            .forEach { [weak self] in
                self?.deleteAllUsersDataForEntityName(entityName: $0,
                                                      withApcId: apcId)

            }
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

    func batchDeleteAndSave(_ task: @escaping ((_ context: NSManagedObjectContext) -> NSFetchRequest<NSFetchRequestResult>?), _ completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard let context = currentContext else {
            ULog.e(.dataModelTag, "Error saveContext: No current context found !")
            completion?(.failure(CoreDataError.unknownContext))
            return
        }

        context.performAndWait {
            let request = task(context)

            guard let request = request else {
                completion?(.failure(CoreDataError.unableToDeleteObject))
                return
            }

            request.resultType = .managedObjectIDResultType
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

            do {
                let deleteResult = try context.execute(deleteRequest) as? NSBatchDeleteResult

                // Extract the IDs of the deleted managed objectss from the request's result.
                if let objectIDs = deleteResult?.result as? [NSManagedObjectID] {
                    // Merge the deletions into the app's managed object context.
                    NSManagedObjectContext.mergeChanges(
                        fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                        into: [context]
                    )
                }

                completion?(.success())
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
        guard let context = currentContext else {
            completion?(.failure(CoreDataError.unknownContext))
            return
        }

        objects.forEach { context.delete($0) }

        saveContext { [weak self] result in
            switch result {
            case .success:
                if T.self is Flight.Type {
                    guard let self = self else { return }
                    self.flightsDidChangeSubject.send()
                    let flights = objects.compactMap { $0 as? Flight }
                    let uuids = flights.compactMap(\.uuid)
                    let flightModels = flights.compactMap { $0.modelLite() }
                    if !uuids.isEmpty {
                        self.flightsRemovedSubject.send(flightModels)
                    }
                }
                if T.self is Project.Type {
                    guard let self = self else { return }
                    self.projectsDidChangeSubject.send()
                    let projects = objects.compactMap { $0 as? Project }
                    let uuids = projects.compactMap(\.uuid)
                    let projectModels = projects.compactMap { $0.model() }
                    if !uuids.isEmpty {
                        self.projectsRemovedSubject.send(projectModels)
                    }
                }
                if T.self is PgyProject.Type { self?.pgyProjectsDidChangeSubject.send() }
                if T.self is FlightPlan.Type { self?.flightPlansDidChangeSubject.send() }
                if T.self is Thumbnail.Type { self?.thumbnailsDidChangeSubject.send() }
                if T.self is DronesData.Type { self?.dronesDidChangeSubject.send() }
            case .failure:
                break
            }

            completion?(result)
        }
    }

    @discardableResult
    private func deleteAllUsersDataForEntityName(entityName: String,
                                                 withApcId apcId: String) -> Error? {
        guard let _ = currentContext else { return CoreDataError.unknownContext }
        var deleteError: Error?

        batchDeleteAndSave({ context in
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
            case .failure(let error):
                ULog.e(.dataModelTag, "An error is occured when batch delete entity \(entityName) in CoreData : \(error.localizedDescription)")
                deleteError = error
            }
        })

        return deleteError
    }

    @discardableResult
    func deleteAllData() -> Error? {
        let entityNames = persistentContainer.managedObjectModel.entities.compactMap({ $0.name })

        var deleteError: Error?
        entityNames.forEach { entityName in
            if let error = deleteAllData(ofEntityName: entityName) {
                deleteError = error
            }
        }

        return deleteError
    }

    @discardableResult
    func deleteAllData(ofEntityName entityName: String) -> Error? {
        var deleteError: Error?

        batchDeleteAndSave({ context in
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
            case .failure(let error):
                ULog.e(.dataModelTag, "An error is occured when batch delete entity in CoreData : \(error.localizedDescription)")
                deleteError = error
            }
        })

        return deleteError
    }

    // MARK: __ Migration utils
    /// Migrate anonymous data to current logged user
    /// - Parameters:
    ///     - entityName: Name of the entity contains the data to migrate
    ///     - completion: Empty block indicates when the process is finished
    func migrateAnonymousDataToLoggedUser(for entityName: String,
                                          _ completion: @escaping () -> Void) {
        guard let currentContext = currentContext else {
            completion()
            return
        }

        let currentUser = userService.currentUser
        guard currentUser.isConnected else {
            ULog.e(.dataModelTag, "User must be logged in")
            completion()
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
                ULog.e(.dataModelTag,
                       "Migrate ANONYMOUS \(entityName) data to current logged User save failed with error: \(error.localizedDescription)")
            }

            completion()
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
