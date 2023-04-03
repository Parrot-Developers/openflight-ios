//    Copyright (C) 2022 Parrot Drones SAS
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
import Combine

fileprivate extension String {
    static let tag = "pictor.engine.coredata"
}

// MARK: - Protocol
protocol CoreDataService {
    // MARK: Publishers
    /// Indicates when an entity has changed to synchronize with the entity name
    var didEntityChangeToSynchroPublisher: AnyPublisher<String, Never> { get }

    /// Indicates when an entity has changed with the entity name
    var didEntityChangePublisher: AnyPublisher<Set<String>, Never> { get }

    /// Indicates when an entity has inserted new objects
    var didInsertEntityPublisher: AnyPublisher<[CoreDataStackService.EntityModification], Never> { get }

    /// Indicates when an entity has updated new objects
    var didUpdateEntityPublisher: AnyPublisher<[CoreDataStackService.EntityModification], Never> { get }

    /// Indicates when an entity has deleted new objects
    var didDeleteEntityPublisher: AnyPublisher<[CoreDataStackService.EntityModification], Never> { get }

    /// Indicates when entity has deleted all objects
    var didDeleteAllEntityPublisher: AnyPublisher<Set<String>, Never> { get }

    // MARK: Context
    /// Gets mainContext.
    var mainContext: NSManagedObjectContext! { get }

    /// Creates new child background context.
    func newChildContext() -> NSManagedObjectContext

    /// Saves changes of child context and propagate changes to its parent writerBackgroundContext
    /// - Parameters
    ///     - context: NSManagedObject to save
    func saveChildContext(_ context: NSManagedObjectContext)

    // MARK: Session
    /// Gets the current session if available.
    /// - Description:
    ///     The SessionCD with its connectedUser is considered to be the source of all request.
    ///     Multitple users can be found in the database, but only one is considered connected and all request should
    ///     be based on the connected user's UUID.
    ///     The application should be considered unresponsive if no session is found as every request will fail.
    /// - Parameters
    ///     - context: NSManagedObjectContext to fetch the current session
    /// - Returns
    ///     the current session in core data if found
    func getCurrentSessionCD(in context: NSManagedObjectContext) -> SessionCD?

    /// Delete all users data with specified UUID
    /// - Description:
    ///     The SessionCD with its connectedUser is considered to be the source of all request.
    ///     Multitple users can be found in the database, but only one is considered connected and all request should
    ///     be based on the connected user's UUID.
    ///     The application should be considered unresponsive if no session is found as every request will fail.
    /// - Parameters
    ///     - pictorContext: NSManagedObjectContext to fetch the current session
    ///     - uuid: user's UUID to specified
    ///     - completion: callback closure when finished
    func deleteAllUsersData(in context: NSManagedObjectContext, uuid: String, completion: @escaping (Result<Bool, PictorEngineError>) -> Void)

    /// Sends a new event to launch synchro
    ///
    ///  - Parameters
    ///     - entityName: the entity name to send
    func sendEventToSynchro(entityName: String)

    /// Sends records mask as deleted
    ///
    ///  - Parameters
    ///     - entityName: the entity name to send
    ///     - uuids: the list of uuids is deleted
    func sendEventMarkAsDeleted(entityName: String, uuids: [String])

    /// Return `NSEntityDescription` based on it's name
    ///
    ///  - Parameters
    ///     - entityName: the entity name to send
    /// - Returns
    ///     the entity description
    func entityDescription(entityName: String) -> NSEntityDescription
}

// MARK: - Implementation
class CoreDataStackService: CoreDataService {
    static let shared = CoreDataStackService()

    struct EntityModification {
        var entityName: String
        var uuids: [String]
    }

    // MARK: Private
    private var didEntityChangeToSynchroSubject = PassthroughSubject<String, Never>()
    private var didEntityChangeSubject = PassthroughSubject<Set<String>, Never>()
    private var didInsertEntitySubject = PassthroughSubject<[EntityModification], Never>()
    private var didUpdateEntitySubject = PassthroughSubject<[EntityModification], Never>()
    private var didDeleteEntitySubject = PassthroughSubject<[EntityModification], Never>()
    private var didDeleteAllEntitySubject = PassthroughSubject<Set<String>, Never>()
    private var didMarkAsDeletedSubject = PassthroughSubject<[EntityModification], Never>()

    // MARK: CoreData Service Protocol
    public var didEntityChangeToSynchroPublisher: AnyPublisher<String, Never> {
        didEntityChangeToSynchroSubject.eraseToAnyPublisher()
    }

    public var didEntityChangePublisher: AnyPublisher<Set<String>, Never> {
        didEntityChangeSubject.eraseToAnyPublisher()
    }

    public var didInsertEntityPublisher: AnyPublisher<[EntityModification], Never> {
        didInsertEntitySubject.eraseToAnyPublisher()
    }

    public var didUpdateEntityPublisher: AnyPublisher<[EntityModification], Never> {
        didUpdateEntitySubject.eraseToAnyPublisher()
    }

    public var didDeleteEntityPublisher: AnyPublisher<[EntityModification], Never> {
        didDeleteEntitySubject
            .merge(with: didMarkAsDeletedSubject)
            .eraseToAnyPublisher()
    }

    public var didDeleteAllEntityPublisher: AnyPublisher<Set<String>, Never> {
        didDeleteAllEntitySubject.eraseToAnyPublisher()
    }

    private(set) var mainContext: NSManagedObjectContext!

    func newChildContext() -> NSManagedObjectContext {
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = writerBackgroundContext
        privateContext.automaticallyMergesChangesFromParent = true

        return privateContext
    }

    func saveChildContext(_ context: NSManagedObjectContext) {
        let contextAddress = Unmanaged.passUnretained(context).toOpaque()

        context.performAndWait {
            guard context.hasChanges else {
                PictorLogger.shared.i(.tag, "💾 Context child no changes: \(contextAddress)")
                return
            }
            do {
                try context.save()
                PictorLogger.shared.i(.tag, "💾✅ Context child did save: \(contextAddress)")
            } catch let error {
                PictorLogger.shared.e(.tag, "💾❌ Context child \(contextAddress) save error: \(error)")
            }
        }

        saveToPersistentStore()
    }

    // MARK: Session
    func getCurrentSessionCD(in contextCD: NSManagedObjectContext) -> SessionCD? {
        var result: SessionCD?

        do {
            let fetchRequest = SessionCD.fetchRequest()
            fetchRequest.shouldRefreshRefetchedObjects = true
            fetchRequest.fetchLimit = 1
            if let first = try contextCD.fetch(fetchRequest).first {
                result = first
            } else {
                PictorLogger.shared.e(.tag, "💾❌ getCurrentSessionCD(in:) error: NO SESSION FOUND")
            }
        } catch let error {
            PictorLogger.shared.e(.tag, "💾❌ getCurrentSessionCD(in:) error: \(error)")
        }

        return result
    }

    func deleteAllUsersData(in context: NSManagedObjectContext, uuid: String, completion: @escaping (Result<Bool, PictorEngineError>) -> Void) {
        context.performAndWait { [weak self] in
            guard let self = self else {
                completion(.failure(.unknown))
                return
            }

            do {
                let entities = [DroneCD.entityName,
                                ProjectCD.entityName,
                                ProjectPix4dCD.entityName,
                                FlightCD.entityName,
                                FlightPlanCD.entityName,
                                GutmaLinkCD.entityName,
                                ThumbnailCD.entityName]
                for entity in entities {
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
                    fetchRequest.predicate = NSPredicate(format: "userUuid == %@", uuid)
                    let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    batchDeleteRequest.resultType = .resultTypeObjectIDs
                    let deleteResult = try context.execute(batchDeleteRequest) as! NSBatchDeleteResult
                    if let objectIDs = deleteResult.result as? [NSManagedObjectID] {
                        NSManagedObjectContext.mergeChanges(
                            fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                            into: [self.writerBackgroundContext, self.mainContext]
                        )
                    }
                }

                try self.writerBackgroundContext.save()

                self.didDeleteAllEntitySubject.send(Set(entities))
                completion(.success(true))
            } catch let error {
                completion(.failure(.fetchError(error)))
            }
        }
    }

    func sendEventToSynchro(entityName: String) {
        didEntityChangeToSynchroSubject.send(entityName)
    }

    func sendEventMarkAsDeleted(entityName: String, uuids: [String]) {
        let entityModification = EntityModification(entityName: entityName, uuids: uuids)
        didMarkAsDeletedSubject.send([entityModification])
    }

    // MARK: Stack
    internal let model: String = "PictorModel"
    internal lazy var persistentContainer: NSPersistentContainer = {
        let url = Bundle(for: CoreDataStackService.self).url(forResource: model, withExtension: "momd")!
        let managedObjectModel = NSManagedObjectModel(contentsOf: url)
        let container = NSPersistentContainer(name: model, managedObjectModel: managedObjectModel!)
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error {
                fatalError("💾❌ Loading of store failed: \(error)")
            }
        }
        return container
    }()
    internal var writerBackgroundContext: NSManagedObjectContext!
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // - writer background context: use only for saving on persistentStore when mainContext is saved
        writerBackgroundContext = persistentContainer.newBackgroundContext()

        // - mainContext: use to get quick access to data on main thread
        // writerBackgroundContext is parent and every modification is merge into mainContext
        mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mainContext.parent = writerBackgroundContext
        mainContext.automaticallyMergesChangesFromParent = true

        // - Notification observer when writerBackgroundContext inserts, update or delete its objects
        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSaveObjectIDs,
                                               object: writerBackgroundContext,
                                               queue: nil) { [weak self] notification in
            PictorLogger.shared.i(.tag, "💾📬 Writer Background Context did save objectIDs from child context")
            guard let self = self else { return }
            guard let userInfo = notification.userInfo else { return }

            // - Inserted
            let insertedObjectIds = userInfo[NSInsertedObjectIDsKey] as? Set<NSManagedObjectID> ?? []
            let insertedEntities = self.createEntityModifications(from: insertedObjectIds)
            if !insertedEntities.isEmpty {
                insertedEntities.forEach {
                    PictorLogger.shared.i(.tag, "💾✏️🟢 Inserted entity \($0.entityName) with \($0.uuids.count) UUIDs \($0.uuids)")
                }
                self.didInsertEntitySubject.send(insertedEntities)
            }

            // - Updated
            let updatedObjectIds = userInfo[NSUpdatedObjectIDsKey] as? Set<NSManagedObjectID> ?? []
            let updatedEntities = self.createEntityModifications(from: updatedObjectIds)
            if !updatedEntities.isEmpty {
                updatedEntities.forEach {
                    PictorLogger.shared.i(.tag, "💾✏️🔵 Updated entity \($0.entityName) with \($0.uuids.count) UUIDs \($0.uuids)")
                }
                self.didUpdateEntitySubject.send(updatedEntities)
            }

            // - Deleted
            let deletedObjectIds = userInfo[NSDeletedObjectIDsKey] as? Set<NSManagedObjectID> ?? []
            let deletedEntities = self.createEntityModifications(from: deletedObjectIds)
            if !deletedEntities.isEmpty {
                deletedEntities.forEach {
                    PictorLogger.shared.i(.tag, "💾✏️🔴 Deleted entity \($0.entityName) with \($0.uuids.count) UUIDs \($0.uuids)")
                }
                self.didDeleteEntitySubject.send(deletedEntities)
            }

            // - Entity changed
            let allModifiedObjectIds = insertedObjectIds.union(updatedObjectIds).union(deletedObjectIds)
            let entities = Set(allModifiedObjectIds.compactMap { $0.entity.name })
            if !entities.isEmpty {
                PictorLogger.shared.i(.tag, "💾✏️ Modified entities: \(entities)")
                self.didEntityChangeSubject.send(entities)
            }
        }

        didMarkAsDeletedSubject
            .sink { markAsDeletedEntities in
                markAsDeletedEntities.forEach {
                    PictorLogger.shared.i(.tag, "💾✏️🔴 Mark as deleted entity \($0.entityName) with \($0.uuids.count) UUIDs \($0.uuids)")
                }
            }
            .store(in: &cancellables)
    }

    func entityDescription(entityName: String) -> NSEntityDescription {
        guard let entity = persistentContainer.managedObjectModel.entitiesByName[entityName] else {
            fatalError("💾 Context Writer Background no changes to save to persistentStore")
        }
        return entity
    }

    private func createEntityModifications(from objectIds: Set<NSManagedObjectID>) -> [EntityModification] {
        var result: [EntityModification] = []

        objectIds.forEach {
            if let object = try? self.writerBackgroundContext.existingObject(with: $0) as? PictorEngineManagedObject,
               let entityName = object.entity.name {
                if let index = result.firstIndex(where: { $0.entityName == entityName }) {
                    result[index].uuids.append(object._uuid)
                } else {
                    result.append(EntityModification(entityName: entityName, uuids: [object._uuid]))
                }
            }
        }

        return result
    }

    private func saveToPersistentStore() {
        writerBackgroundContext.performAndWait {
            guard writerBackgroundContext.hasChanges else {
                PictorLogger.shared.i(.tag, "💾 Context Writer Background no changes to save to persistentStore")
                return
            }
            do {
                try writerBackgroundContext.save()
                PictorLogger.shared.i(.tag, "💾✅ Context Writer Background did save to persistentStore")
            } catch let error {
                PictorLogger.shared.e(.tag, "💾❌ Context Writer Background save error: \(error)")
            }
        }
    }
}
