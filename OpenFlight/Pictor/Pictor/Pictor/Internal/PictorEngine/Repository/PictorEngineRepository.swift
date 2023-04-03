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
    static let tag = "pictor.engine.repository"
}

// MARK: - Repository Protocol
protocol PictorEngineBaseRepository {
    associatedtype PictorEngineModelType

    // MARK: Publishers
    /// Indicates when repository has changed.
    var didChangeToSynchroPublisher: AnyPublisher<Void, Never> { get }

    /// Indicates when repository has changed.
    var didChangePublisher: AnyPublisher<Void, Never> { get }

    /// Indicates when repository has created new records.
    var didCreatePublisher: AnyPublisher<[String], Never> { get }

    /// Indicates when repository has updated records.
    var didUpdatePublisher: AnyPublisher<[String], Never> { get }

    /// Indicates when repository has deleted records.
    var didDeletePublisher: AnyPublisher<[String], Never> { get }

    /// Indicates when repository has deleted all records.
    var didDeleteAllPublisher: AnyPublisher<Void, Never> { get }

    /// Gets asynchronous all records.
    ///
    /// - Parameters:
    ///     - pictorContext: pictorContext to work in
    /// - Description:
    ///     Gets all existing records
    func getAll(in pictorContext: PictorContext) async -> [PictorEngineModelType]

    /// Gets asynchronous all records.
    ///
    /// - Parameters:
    ///     - pictorContext: pictorContext to work in
    ///     - byUserUuid: user's UUID to search
    /// - Description:
    ///     Gets all existing records with specified user's UUID
    func getAll(in pictorContext: PictorContext,
                byUserUuid: String) async -> [PictorEngineModelType]

    /// Gets asynchronous all records by user uuid.
    ///
    /// - Parameters:
    ///     - pictorContext: pictorContext to work in
    ///     - byUserUuid: optional user's UUID to search
    ///     - synchroIsDeleted: optional boolean to search
    func getAll(in pictorContext: PictorContext,
                byUserUuid: String?,
                synchroIsDeleted: Bool?) async -> [PictorEngineModelType]

    /// Gets asynchronous all records by user uuid.
    ///
    /// - Parameters:
    ///     - pictorContext: pictorContext to work in
    ///     - completion: closure called when finished
    func getAll(in pictorContext: PictorContext,
                completion: @escaping ((Result<[PictorEngineModelType], PictorEngineError>) -> Void))

    /// Gets asynchronous all records by user uuid.
    ///
    /// - Parameters:
    ///     - pictorContext: pictorContext to work in
    ///     - byUserUuid: user's UUID to search
    ///     - completion: closure called when finished
    func getAll(in pictorContext: PictorContext,
                byUserUuid: String,
                completion: @escaping ((Result<[PictorEngineModelType], PictorEngineError>) -> Void))

    /// Gets asynchronous all records by user uuid.
    ///
    /// - Parameters:
    ///     - pictorContext: pictorContext to work in
    ///     - byUserUuid: optional user's UUID to search
    ///     - synchroIsDeleted: optional boolean to search
    ///     - completion: closure called when finished
    func getAll(in pictorContext: PictorContext,
                byUserUuid: String?,
                synchroIsDeleted: Bool?,
                completion: @escaping ((Result<[PictorEngineModelType], PictorEngineError>) -> Void))

    /// Get asynchronous record with a specified UUID.
    ///
    /// - Parameters:
    ///     - pictorContext: pictorContext to work in
    ///     - byUuid: UUID to search
    /// - Returns:
    ///     - record if found
    func get(in pictorContext: PictorContext,
             byUuid: String) async -> PictorEngineModelType?

    /// Get asynchronous record with a specified UUID.
    ///
    /// - Parameters:
    ///     - pictorContext: pictorContext to work in
    ///     - byUuid: UUID to search
    ///     - synchroIsDeleted: optional boolean to search
    /// - Returns:
    ///     - record if found
    func get(in pictorContext: PictorContext,
             byUuid: String,
             synchroIsDeleted: Bool?) async -> PictorEngineModelType?

    /// Get asynchronous record with a specified UUID.
    ///
    /// - Parameters:
    ///     - pictorContext: pictorContext to work in
    ///     - byUuid: UUID to search
    ///     - completion: closure called when finished
    func get(in pictorContext: PictorContext,
             byUuid: String,
             completion: @escaping ((Result<PictorEngineModelType?, PictorEngineError>) -> Void))

    /// Get asynchronous record with a specified UUID.
    ///
    /// - Parameters:
    ///     - pictorContext: pictorContext to work in
    ///     - byUuid: UUID to search
    ///     - synchroIsDeleted: optional boolean to search
    ///     - completion: closure called when finished
    func get(in pictorContext: PictorContext,
             byUuid: String,
             synchroIsDeleted: Bool?,
             completion: @escaping ((Result<PictorEngineModelType?, PictorEngineError>) -> Void))

    /// Gets asynchronous records with a specified UUIDs.
    ///
    /// - Parameters:
    ///     - pictorContext: pictorContext to work in
    ///     - byUuids: UUIDs to search
    /// - Returns:
    ///     - list of found records
    func get(in pictorContext: PictorContext,
             byUuids: [String]) async -> [PictorEngineModelType]

    /// Gets asynchronous records with a specified UUIDs.
    ///
    /// - Parameters:
    ///     - pictorContext: pictorContext to work in
    ///     - byUuids: UUIDs to search
    ///     - synchroIsDeleted: optional boolean to search
    /// - Returns:
    ///     - list of found records
    func get(in pictorContext: PictorContext,
             byUuids: [String],
             synchroIsDeleted: Bool?) async -> [PictorEngineModelType]

    /// Gets asynchronous records with a specified UUIDs.
    ///
    /// - Parameters:
    ///     - pictorContext: pictorContext to work in
    ///     - byUuids: UUIDs to search
    ///     - completion: closure called when finished
    func get(in pictorContext: PictorContext,
             byUuids: [String],
             completion: @escaping ((Result<[PictorEngineModelType], PictorEngineError>) -> Void))

    /// Gets asynchronous records with a specified UUIDs.
    ///
    /// - Parameters:
    ///     - pictorContext: pictorContext to work in
    ///     - byUuids: UUIDs to search
    ///     - synchroIsDeleted: optional boolean to search
    ///     - completion: closure called when finished
    func get(in pictorContext: PictorContext,
             byUuids: [String],
             synchroIsDeleted: Bool?,
             completion: @escaping ((Result<[PictorEngineModelType], PictorEngineError>) -> Void))

    /// Get asynchronous record with a specified cloudId.
    ///
    /// - Parameters:
    ///     - pictorContext: pictorContext to work in
    ///     - byCloudId: cloudId to search
    /// - Returns:
    ///     - record if found
    func get(in pictorContext: PictorContext,
             byCloudId: Int64) async throws -> PictorEngineModelType?

    /// Get asynchronous record with a specified cloudId.
    ///
    /// - Parameters:
    ///     - pictorContext: pictorContext to work in
    ///     - byCloudId: cloudId to search
    ///     - completion: closure called when finished
    func get(in pictorContext: PictorContext,
             byCloudId: Int64,
             completion: @escaping ((Result<PictorEngineModelType?, PictorEngineError>) -> Void))

    /// Gets asynchronous all modified records with a synchroLatestUpdatedDate of the current session.
    ///
    /// - Parameters:
    ///     - pictorContext: pictorContext to work in
    ///     - completion: closure called when finished
    /// - Returns:
    ///     - list of records if found
    func getAllModifiedsForSession(in pictorContext: PictorContext) async -> [PictorEngineModelType]

    /// Gets asynchronous all modified records with a synchroLatestUpdatedDate of the current session.
    ///
    /// - Parameters:
    ///     - pictorContext: pictorContext to work in
    ///     - completion: closure called when finished
    func getAllModifiedsForSession(in pictorContext: PictorContext,
                                   completion: @escaping ((Result<[PictorEngineModelType], PictorEngineError>)) -> Void)

    /// Gets asynchronous all synchronized records UUIDs  of the current session.
    ///
    /// - Parameters:
    ///     - pictorContext: pictorContext to work in
    ///     - completion: closure called when finished
    /// - Returns:
    ///     - list of UUIDs
    func getAllSynchronizedUuidsForSession(in pictorContext: PictorContext) async -> [String]

    /// Gets asynchronous all synchronized records UUIDs of the current session.
    ///
    /// - Parameters:
    ///     - pictorContext: pictorContext to work in
    ///     - completion: closure called when finished
    func getAllSynchronizedUuidsForSession(in pictorContext: PictorContext,
                                           completion: @escaping ((Result<[String], PictorEngineError>)) -> Void)

    /// Transfer all data of  all users to anonymous
    ///
    /// - Parameters:
    ///     - pictorContext: pictorContext to work in
    ///     - completion: closure called when finished
    func transferAllDataToAnonymous(in pictorContext: PictorContext,
                                    completion: @escaping ((Result<Void, PictorEngineError>)) -> Void)

    /// Transfer all anonymoud data to a existing user with specified UUID
    ///
    /// - Parameters:
    ///     - pictorContext: pictorContext to work in
    ///     - withUuid: user's UUID to specified
    ///     - completion: closure called when finished
    func transferAllAnonymousDataToUser(in pictorContext: PictorContext,
                                        withUuid: String,
                                        completion: @escaping ((Result<Void, PictorEngineError>)) -> Void)
}

// MARK: - Implementation
class PictorEngineRepository<PictorEngineModelType>: PictorEngineBaseRepository where PictorEngineModelType: PictorEngineBaseModel {

    // MARK: Private
    internal var coreDataService: CoreDataService
    private var didChangeToSynchroSubject = PassthroughSubject<Void, Never>()
    private var didChangeSubject = PassthroughSubject<Void, Never>()
    private var didCreateSubject = PassthroughSubject<[String], Never>()
    private var didUpdateSubject = PassthroughSubject<[String], Never>()
    private var didDeleteSubject = PassthroughSubject<[String], Never>()
    private var didDeleteAllSubject = PassthroughSubject<Void, Never>()
    private var cancellables: [AnyCancellable] = []
    private struct AttributeName {
        static var user: String { "userUuid" }
        static var cloudId: String { "cloudId" }
        static var cloudCreationDate: String { "cloudCreationDate" }
        static var cloudModificationDate: String { "cloudModificationDate" }
        static var synchroStatus: String { "synchroStatus" }
        static var synchroError: String { "synchroError" }
        static var synchroLatestUpdatedDate: String { "synchroLatestUpdatedDate" }
        static var synchroLatestStatusDate: String { "synchroLatestStatusDate" }
        static var synchroIsDeleted: String { "synchroIsDeleted" }
    }

    // MARK: Pictor Repository Protocol Publishers
    public var didChangeToSynchroPublisher: AnyPublisher<Void, Never> {
        didChangeToSynchroSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    public var didChangePublisher: AnyPublisher<Void, Never> {
        didChangeSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    public var didCreatePublisher: AnyPublisher<[String], Never> {
        didCreateSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    public var didUpdatePublisher: AnyPublisher<[String], Never> {
        didUpdateSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    public var didDeletePublisher: AnyPublisher<[String], Never> {
        didDeleteSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    public var didDeleteAllPublisher: AnyPublisher<Void, Never> {
        didDeleteAllSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    // MARK: Init
    init(coreDataService: CoreDataService) {
        self.coreDataService = coreDataService
        self.coreDataService.didEntityChangeToSynchroPublisher
            .sink { [unowned self] in
                if $0 == entityName {
                    didChangeToSynchroSubject.send()
                }
            }.store(in: &cancellables)

        self.coreDataService.didEntityChangePublisher
            .sink { [unowned self] in
            if let _ = $0.first(where: { $0 == entityName }) {
                didChangeSubject.send()
            }
        }.store(in: &cancellables)

        self.coreDataService.didInsertEntityPublisher
            .sink { [unowned self] in
            if let entityModification = $0.first(where: { $0.entityName == entityName }) {
                didCreateSubject.send(entityModification.uuids)
            }
        }.store(in: &cancellables)

        self.coreDataService.didUpdateEntityPublisher
            .sink { [unowned self] in
            if let entityModification = $0.first(where: { $0.entityName == entityName }) {
                didUpdateSubject.send(entityModification.uuids)
            }
        }.store(in: &cancellables)

        self.coreDataService.didDeleteEntityPublisher
            .sink { [unowned self] in
            if let entityModification = $0.first(where: { $0.entityName == entityName }) {
                didDeleteSubject.send(entityModification.uuids)
            }
        }.store(in: &cancellables)

        self.coreDataService.didDeleteAllEntityPublisher
            .sink { [unowned self] in
                if let _ = $0.first(where: { $0 == entityName }) {
                    didDeleteAllSubject.send()
                }
            }.store(in: &cancellables)
    }

    // MARK: To override
    var entity: NSEntityDescription { coreDataService.entityDescription(entityName: entityName) }

    // MARK: Internal
    internal var entityName: String {
        fatalError("Must Override entity()")
    }

    public var repositories: PictorEngine.Repository {
        PictorEngine.shared.repository
    }

    internal func getCurrentSessionCD(in contextCD: NSManagedObjectContext) -> SessionCD? {
        coreDataService.getCurrentSessionCD(in: contextCD)
    }

    internal func convertToModel(_ record: PictorEngineManagedObject, context: NSManagedObjectContext) -> PictorEngineModelType? {
        fatalError("Must Override \(#function)")
    }

    internal func convertToModels(_ records: [PictorEngineManagedObject], context: NSManagedObjectContext) -> [PictorEngineModelType] {
        records.compactMap { convertToModel($0, context: context) }
    }

    internal func convertToUuids(_ records: [PictorEngineManagedObject]) -> [String] {
        records.compactMap { $0._uuid }
    }

    internal func userPredicate(from sessionCD: SessionCD) -> NSPredicate {
        NSPredicate(format: "\(AttributeName.user) == %@", sessionCD.userUuid)
    }

    internal func synchroIsDeletedPredicate(_ value: Bool) -> NSPredicate {
        NSPredicate(format: "%K == %@", AttributeName.synchroIsDeleted, NSNumber(value: value))
    }

    // MARK: Pictor Engine Synchro Repository Protocol
    // - Get All
    func getAll(in pictorContext: PictorContext) async -> [PictorEngineModelType] {
        return await withCheckedContinuation { continuation in
            getAll(in: pictorContext) {
                if case .success(let models) = $0 {
                    continuation.resume(returning: models)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    func getAll(in pictorContext: PictorContext, byUserUuid: String) async -> [PictorEngineModelType] {
        return await withCheckedContinuation { continuation in
            getAll(in: pictorContext, byUserUuid: byUserUuid) {
                if case .success(let models) = $0 {
                    continuation.resume(returning: models)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    func getAll(in pictorContext: PictorContext,
                byUserUuid: String?,
                synchroIsDeleted: Bool?) async -> [PictorEngineModelType] {
        return await withCheckedContinuation { continuation in
            getAll(in: pictorContext, byUserUuid: byUserUuid, synchroIsDeleted: synchroIsDeleted) {
                if case .success(let models) = $0 {
                    continuation.resume(returning: models)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    func getAll(in pictorContext: PictorContext,
                completion: @escaping ((Result<[PictorEngineModelType], PictorEngineError>) -> Void)) {
        pictorContext.perform { [weak self] contextCD in
            guard let self = self else { return }
            completion(self.getAll(contextCD: contextCD, byUserUuid: nil, synchroIsDeleted: nil))
        }
    }

    func getAll(in pictorContext: PictorContext,
                byUserUuid: String,
                completion: @escaping ((Result<[PictorEngineModelType], PictorEngineError>) -> Void)) {
        pictorContext.perform { [weak self] contextCD in
            guard let self = self else { return }
            completion(self.getAll(contextCD: contextCD, byUserUuid: byUserUuid, synchroIsDeleted: nil))
        }
    }

    func getAll(in pictorContext: PictorContext,
                byUserUuid: String?,
                synchroIsDeleted: Bool?,
                completion: @escaping ((Result<[PictorEngineModelType], PictorEngineError>) -> Void)) {
        pictorContext.perform { [weak self] contextCD in
            guard let self = self else { return }
            completion(self.getAll(contextCD: contextCD, byUserUuid: byUserUuid, synchroIsDeleted: synchroIsDeleted))
        }
    }

    // - Get By UUID
    func get(in pictorContext: PictorContext,
             byUuid: String) async -> PictorEngineModelType? {
        return await withCheckedContinuation { continuation in
            get(in: pictorContext, byUuid: byUuid) {
                if case .success(let model) = $0 {
                    continuation.resume(returning: model)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    func get(in pictorContext: PictorContext,
             byUuid: String,
             synchroIsDeleted: Bool?) async -> PictorEngineModelType? {
        return await withCheckedContinuation { continuation in
            get(in: pictorContext, byUuid: byUuid, synchroIsDeleted: synchroIsDeleted) {
                if case .success(let model) = $0 {
                    continuation.resume(returning: model)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    func get(in pictorContext: PictorContext,
             byUuid: String,
             completion: @escaping ((Result<PictorEngineModelType?, PictorEngineError>) -> Void)) {
        pictorContext.perform { [unowned self] contextCD in
            completion(self.get(contextCD: contextCD, byUuid: byUuid, synchroIsDeleted: nil))
        }
    }

    func get(in pictorContext: PictorContext,
             byUuid: String,
             synchroIsDeleted: Bool?,
             completion: @escaping ((Result<PictorEngineModelType?, PictorEngineError>) -> Void)) {
        pictorContext.perform { [unowned self] contextCD in
            completion(self.get(contextCD: contextCD, byUuid: byUuid, synchroIsDeleted: synchroIsDeleted))
        }
    }

    // - Get By UUIDs
    func get(in pictorContext: PictorContext,
             byUuids: [String]) async -> [PictorEngineModelType] {
        return await withCheckedContinuation { continuation in
            get(in: pictorContext, byUuids: byUuids) {
                if case .success(let models) = $0 {
                    continuation.resume(returning: models)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    func get(in pictorContext: PictorContext,
             byUuids: [String],
             synchroIsDeleted: Bool?) async -> [PictorEngineModelType] {
        return await withCheckedContinuation { continuation in
            get(in: pictorContext, byUuids: byUuids, synchroIsDeleted: synchroIsDeleted) {
                if case .success(let models) = $0 {
                    continuation.resume(returning: models)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    func get(in pictorContext: PictorContext,
             byUuids: [String],
             completion: @escaping ((Result<[PictorEngineModelType], PictorEngineError>)) -> Void) {
        pictorContext.perform { [unowned self] contextCD in
            completion(self.get(contextCD: contextCD, byUuids: byUuids, synchroIsDeleted: nil))
        }
    }

    func get(in pictorContext: PictorContext,
             byUuids: [String],
             synchroIsDeleted: Bool?,
             completion: @escaping ((Result<[PictorEngineModelType], PictorEngineError>)) -> Void) {
        pictorContext.perform { [unowned self] contextCD in
            completion(self.get(contextCD: contextCD, byUuids: byUuids, synchroIsDeleted: synchroIsDeleted))
        }
    }

    // - Get By Cloud ID
    func get(in pictorContext: PictorContext,
             byCloudId: Int64) async -> PictorEngineModelType? {
        return await withCheckedContinuation { continuation in
            get(in: pictorContext, byCloudId: byCloudId) {
                if case .success(let model) = $0 {
                    continuation.resume(returning: model)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    func get(in pictorContext: PictorContext,
             byCloudId: Int64,
             completion: @escaping ((Result<PictorEngineModelType?, PictorEngineError>) -> Void)) {
        pictorContext.perform { [unowned self] contextCD in
            completion(self.get(contextCD: contextCD, byCloudId: byCloudId))
        }
    }

    // - Get All Modifieds
    func getAllModifiedsForSession(in pictorContext: PictorContext) async -> [PictorEngineModelType] {
        return await withCheckedContinuation { continuation in
            getAllModifiedsForSession(in: pictorContext) {
                if case .success(let models) = $0 {
                    continuation.resume(returning: models)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    func getAllModifiedsForSession(in pictorContext: PictorContext,
                         completion: @escaping ((Result<[PictorEngineModelType], PictorEngineError>)) -> Void) {
        pictorContext.perform { [unowned self] contextCD in
            completion(self.getAllModifiedsForSession(contextCD: contextCD))
        }
    }

    // - Get All Synchronized UUIDs
    func getAllSynchronizedUuidsForSession(in pictorContext: PictorContext) async -> [String] {
        return await withCheckedContinuation { continuation in
            getAllSynchronizedUuidsForSession(in: pictorContext) {
                if case .success(let models) = $0 {
                    continuation.resume(returning: models)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    func getAllSynchronizedUuidsForSession(in pictorContext: PictorContext,
                                 completion: @escaping ((Result<[String], PictorEngineError>)) -> Void) {
        pictorContext.perform { [unowned self] contextCD in
            completion(self.getAllSynchronizedUuidsForSession(contextCD: contextCD))
        }
    }

    // - Data transfer
    func transferAllDataToAnonymous(in pictorContext: PictorContext,
                                    completion: @escaping ((Result<Void, PictorEngineError>)) -> Void) {
        pictorContext.perform { [unowned self] contextCD in
            completion(self.transferAllDataToAnonymous(contextCD: contextCD))
        }
    }

    func transferAllAnonymousDataToUser(in pictorContext: PictorContext,
                                        withUuid: String,
                                        completion: @escaping ((Result<Void, PictorEngineError>)) -> Void) {
        pictorContext.perform { [unowned self] contextCD in
            completion(self.transferAllAnonymousDataToUser(contextCD: contextCD, withUuid: withUuid))
        }
    }
}

extension PictorEngineRepository {
    private func getAll(contextCD: NSManagedObjectContext,
                        byUserUuid: String?,
                        synchroIsDeleted: Bool?) -> Result<[PictorEngineModelType], PictorEngineError> {
        do {
            var subPredicateList: [NSPredicate] = []
            // - user.uuid
            if let byUserUuid = byUserUuid, entity.hasAttribute(name: AttributeName.user) {
                subPredicateList.append(NSPredicate(format: "\(AttributeName.user) == %@", byUserUuid))
            }
            // - synchroIsDeleted
            if let synchroIsDeleted = synchroIsDeleted, entity.hasAttribute(name: AttributeName.synchroIsDeleted) {
                subPredicateList.append(synchroIsDeletedPredicate(synchroIsDeleted))
            }
            let predicate = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)

            let fetchRequest: NSFetchRequest<PictorEngineManagedObject> = NSFetchRequest(entityName: self.entityName)
            fetchRequest.shouldRefreshRefetchedObjects = true
            fetchRequest.predicate = predicate
            let fetchResult = try contextCD.fetch(fetchRequest)
            let models = fetchResult.compactMap { self.convertToModel($0, context: contextCD) }
            return .success(models)
        } catch let error {
            return .failure(.fetchError(error))
        }
    }

    internal func get(contextCD: NSManagedObjectContext,
                     byUuid: String,
                     synchroIsDeleted: Bool?) -> Result<PictorEngineModelType?, PictorEngineError> {
        do {
            var subPredicateList: [NSPredicate] = []
            // - UUID
            subPredicateList.append(NSPredicate(format: "uuid == %@", byUuid))
            // - synchroIsDeleted
            if let synchroIsDeleted = synchroIsDeleted, entity.hasAttribute(name: AttributeName.synchroIsDeleted) {
                subPredicateList.append(synchroIsDeletedPredicate(synchroIsDeleted))
            }
            let predicate = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)

            let fetchRequest: NSFetchRequest<PictorEngineManagedObject> = NSFetchRequest(entityName: self.entityName)
            fetchRequest.shouldRefreshRefetchedObjects = true
            fetchRequest.fetchLimit = 1
            fetchRequest.predicate = predicate
            if let first = try contextCD.fetch(fetchRequest).first {
                return .success(convertToModel(first, context: contextCD))
            } else {
                return .success(nil)
            }
        } catch let error {
            return .failure(.fetchError(error))
        }
    }

    private func get(contextCD: NSManagedObjectContext,
                     byUuids: [String],
                     synchroIsDeleted: Bool?) -> Result<[PictorEngineModelType], PictorEngineError> {
        do {
            var subPredicateList: [NSPredicate] = []
            // - UUIDs
            subPredicateList.append(NSPredicate(format: "uuid IN %@", byUuids))
            // - synchroIsDeleted
            if let synchroIsDeleted = synchroIsDeleted, entity.hasAttribute(name: AttributeName.synchroIsDeleted) {
                subPredicateList.append(synchroIsDeletedPredicate(synchroIsDeleted))
            }
            let predicate = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)

            let fetchRequest: NSFetchRequest<PictorEngineManagedObject> = NSFetchRequest(entityName: self.entityName)
            fetchRequest.shouldRefreshRefetchedObjects = true
            fetchRequest.predicate = predicate
            let fetchResult = try contextCD.fetch(fetchRequest)
            let models = fetchResult.compactMap { self.convertToModel($0, context: contextCD) }
            return .success(models)
        } catch let error {
            return .failure(.fetchError(error))
        }
    }

    private func get(contextCD: NSManagedObjectContext,
                     byCloudId: Int64) -> Result<PictorEngineModelType?, PictorEngineError> {
        do {
            var subPredicateList: [NSPredicate] = []
            // - cloudId
            subPredicateList.append(NSPredicate(format: "%K == %i", "cloudId", byCloudId))
            let predicate = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)

            let fetchRequest: NSFetchRequest<PictorEngineManagedObject> = NSFetchRequest(entityName: self.entityName)
            fetchRequest.shouldRefreshRefetchedObjects = true
            fetchRequest.fetchLimit = 1
            fetchRequest.predicate = predicate
            if let first = try contextCD.fetch(fetchRequest).first {
                return .success(convertToModel(first, context: contextCD))
            } else {
                return .success(nil)
            }
        } catch let error {
            return .failure(.fetchError(error))
        }
    }

    private func getAllModifiedsForSession(contextCD: NSManagedObjectContext) -> Result<[PictorEngineModelType], PictorEngineError> {
        do {
            guard let sessionCD = getCurrentSessionCD(in: contextCD) else {
                PictorLogger.shared.e(.tag, "getAllModifieds() error: current session not found")
                return .failure(.unknown)
            }

            var subPredicateList: [NSPredicate] = []
            // - synchroLatestUpdatedDate
            subPredicateList.append(NSPredicate(format: "synchroLatestUpdatedDate != nil"))
            // - user.uuid
            if entity.hasAttribute(name: AttributeName.user) {
                subPredicateList.append(userPredicate(from: sessionCD))
            }
            let predicate = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)

            let fetchRequest: NSFetchRequest<PictorEngineManagedObject> = NSFetchRequest(entityName: self.entityName)
            fetchRequest.shouldRefreshRefetchedObjects = true
            fetchRequest.predicate = predicate
            let fetchResult = try contextCD.fetch(fetchRequest)
            let models = fetchResult.compactMap { self.convertToModel($0, context: contextCD) }
            return .success(models)
        } catch let error {
            return .failure(.fetchError(error))
        }
    }

    private func getAllSynchronizedUuidsForSession(contextCD: NSManagedObjectContext) -> Result<[String], PictorEngineError> {
        do {
            guard let sessionCD = getCurrentSessionCD(in: contextCD) else {
                PictorLogger.shared.e(.tag, "getAllSynchronizedUuids() error: current session not found")
                return .failure(.unknown)
            }

            var subPredicateList: [NSPredicate] = []
            // - cloudId
            subPredicateList.append(NSPredicate(format: "cloudId > 0"))
            // - user.uuid
            if entity.hasAttribute(name: AttributeName.user) {
                subPredicateList.append(userPredicate(from: sessionCD))
            }
            let predicate = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)

            let fetchRequest: NSFetchRequest<PictorEngineManagedObject> = NSFetchRequest(entityName: self.entityName)
            fetchRequest.shouldRefreshRefetchedObjects = true
            fetchRequest.predicate = predicate
            let fetchResult = try contextCD.fetch(fetchRequest)
            let uuids = self.convertToUuids(fetchResult)
            return .success(uuids)
        } catch let error {
            return .failure(.fetchError(error))
        }
    }

    private func transferAllDataToAnonymous(contextCD: NSManagedObjectContext) -> Result<Void, PictorEngineError> {
        do {
            let anonymousFetchRequest = UserCD.fetchRequest()
            anonymousFetchRequest.predicate = NSPredicate(format: "uuid == %@", PictorUserModel.Constants.anonymousId)
            let anonymousFetchResult = try contextCD.fetch(anonymousFetchRequest).first
            guard let _ = anonymousFetchResult else {
                return .failure(.unknown)
            }

            var subPredicateList: [NSPredicate] = []
            // - userUuid
            if entity.hasAttribute(name: AttributeName.user) {
                subPredicateList.append(NSPredicate(format: "\(AttributeName.user) != %@", PictorUserModel.Constants.anonymousId))
            }
            let predicate = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)

            let fetchRequest: NSFetchRequest<PictorEngineManagedObject> = NSFetchRequest(entityName: self.entityName)
            fetchRequest.shouldRefreshRefetchedObjects = true
            fetchRequest.predicate = predicate
            let fetchResult = try contextCD.fetch(fetchRequest)

            if !fetchResult.isEmpty {
                fetchResult.forEach { managedObject in
                    if entity.hasAttribute(name: AttributeName.cloudId) {
                        managedObject.setValue(0, forKey: AttributeName.cloudId)
                    }
                    if entity.hasAttribute(name: AttributeName.cloudCreationDate) {
                        managedObject.setValue(nil, forKey: AttributeName.cloudCreationDate)
                    }
                    if entity.hasAttribute(name: AttributeName.cloudModificationDate) {
                        managedObject.setValue(nil, forKey: AttributeName.cloudModificationDate)
                    }
                    if entity.hasAttribute(name: AttributeName.synchroStatus) {
                        managedObject.setValue(0, forKey: AttributeName.synchroStatus)
                    }
                    if entity.hasAttribute(name: AttributeName.synchroError) {
                        managedObject.setValue(0, forKey: AttributeName.synchroError)
                    }
                    if entity.hasAttribute(name: AttributeName.synchroLatestUpdatedDate) {
                        managedObject.setValue(Date(), forKey: AttributeName.synchroLatestUpdatedDate)
                    }
                    if entity.hasAttribute(name: AttributeName.synchroLatestStatusDate) {
                        managedObject.setValue(nil, forKey: AttributeName.synchroLatestStatusDate)
                    }
                    if entity.hasAttribute(name: AttributeName.user) {
                        managedObject.setValue(PictorUserModel.Constants.anonymousId, forKey: AttributeName.user)
                    }
                }

                try contextCD.save()
            }
            return .success(())
        } catch let error {
            return .failure(.fetchError(error))
        }
    }

    private func transferAllAnonymousDataToUser(contextCD: NSManagedObjectContext, withUuid: String) -> Result<Void, PictorEngineError> {
        do {
            let userFetchRequest = UserCD.fetchRequest()
            userFetchRequest.predicate = NSPredicate(format: "uuid == %@", withUuid)
            let userFetchResult = try contextCD.fetch(userFetchRequest).first
            guard let _ = userFetchResult else {
                return .failure(.unknown)
            }

            var subPredicateList: [NSPredicate] = []
            // - user.uuid
            if entity.hasAttribute(name: AttributeName.user) {
                subPredicateList.append(NSPredicate(format: "\(AttributeName.user) == %@", PictorUserModel.Constants.anonymousId))
            }
            let predicate = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)

            let fetchRequest: NSFetchRequest<PictorEngineManagedObject> = NSFetchRequest(entityName: self.entityName)
            fetchRequest.shouldRefreshRefetchedObjects = true
            fetchRequest.predicate = predicate
            let fetchResult = try contextCD.fetch(fetchRequest)
            if !fetchResult.isEmpty {
                fetchResult.forEach { managedObject in
                    if entity.hasAttribute(name: AttributeName.synchroStatus) {
                        managedObject.setValue(0, forKey: AttributeName.synchroStatus)
                    }
                    if entity.hasAttribute(name: AttributeName.synchroError) {
                        managedObject.setValue(0, forKey: AttributeName.synchroError)
                    }
                    if entity.hasAttribute(name: AttributeName.synchroLatestUpdatedDate) {
                        managedObject.setValue(Date(), forKey: AttributeName.synchroLatestUpdatedDate)
                    }
                    if entity.hasAttribute(name: AttributeName.synchroLatestStatusDate) {
                        managedObject.setValue(nil, forKey: AttributeName.synchroLatestStatusDate)
                    }
                    if entity.hasAttribute(name: AttributeName.user) {
                        managedObject.setValue(withUuid, forKey: AttributeName.user)
                    }
                }

                try contextCD.save()
            }

            return .success(())
        } catch let error {
            return .failure(.fetchError(error))
        }
    }

}
