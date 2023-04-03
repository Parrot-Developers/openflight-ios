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
import Combine
import CoreData

fileprivate extension String {
    static let tag = "pictor.repository"
}

// MARK: - Repository Protocol
public protocol PictorBaseRepository {
    associatedtype PictorBaseModelType

    // MARK: Publishers
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

    // MARK: Get
    /// Count of all records.
    ///
    /// - Returns Int value count
    /// - Description:
    ///     Gets count of all records with synchroIsDeleted to false
    func count() -> Int

    /// Gets record with the specified UUID.
    ///
    /// - Parameters:
    ///    - byUuid: uuid to search
    /// - Returns Record if found
    /// - Description:
    ///     Gets record of connectedUser (in sessionCD) with specified UUID with synchroIsDeleted to false and
    func get(byUuid: String) -> PictorBaseModelType?

    /// Gets all records.
    ///
    /// - Returns List of model record
    /// - Description:
    ///     Gets all records  of connectedUser with synchroIsDeleted to false
    func getAll() -> [PictorBaseModelType]

    /// Gets a list of records with specified UUIDs.
    ///
    /// - Parameters:
    ///    - byUuids: list of uuids to search
    /// - Returns List of records
    /// - Description:
    ///     Gets record  of connectedUser (in sessionCD) with specified UUIDs with synchroIsDeleted to false
    func get(byUuids: [String]) -> [PictorBaseModelType]

    /// Gets a list of records with the specified offset and number of records.
    ///
    ///  - Parameters:
    ///     - from: offset start
    ///     - count: number of records to get
    /// - Returns List of records
    /// - Description:
    ///     Gets record  of connectedUser (in sessionCD) with specified UUIDs with synchroIsDeleted to false
    func get(from: Int, count: Int) -> [PictorBaseModelType]
}

public enum PictorRepositoryError: Error {
    case unknown
    case fetchError
    case noSessionFound
}

// MARK: - Implementation
public class PictorRepository<PictorModelType>: PictorBaseRepository where PictorModelType: PictorBaseModel {
    // MARK: Private
    internal var coreDataService: CoreDataService
    private var didChangeSubject = PassthroughSubject<Void, Never>()
    private var didCreateSubject = PassthroughSubject<[String], Never>()
    private var didUpdateSubject = PassthroughSubject<[String], Never>()
    private var didDeleteSubject = PassthroughSubject<[String], Never>()
    private var didDeleteAllSubject = PassthroughSubject<Void, Never>()
    private var cancellables: [AnyCancellable] = []
    private struct AttributeName {
        static var synchroIsDeleted: String { "synchroIsDeleted" }
        static var user: String { "userUuid" }
    }

    public var repositories: Pictor.Repository {
        Pictor.shared.repository
    }

    // MARK: Internal
    internal var synchroIsNotDeletedPredicate: NSPredicate {
        NSPredicate(format: "%K == %@", AttributeName.synchroIsDeleted, NSNumber(value: false))
    }

    internal var sortBy: [(attributeName: String, ascending: Bool)] {
        []
    }

    // MARK: Pictor Repository Protocol Publishers
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

    internal func convertToModel(_ record: PictorEngineManagedObject) -> PictorModelType? {
        fatalError("Must Override \(#function)")
    }

    internal func convertToModels(_ records: [PictorEngineManagedObject]) -> [PictorModelType] {
        return records.compactMap { convertToModel($0) }
    }

    internal func getSessionCD() throws -> SessionCD {
        guard let sessionCD = getCurrentSessionCD() else {
            PictorLogger.shared.e(.tag, "❌💾🗂 getFetchRequest project error: session not found")
            throw PictorRepositoryError.noSessionFound
        }
        return sessionCD
    }

    internal func getCurrentSessionCD() -> SessionCD? {
        coreDataService.getCurrentSessionCD(in: coreDataService.mainContext)
    }

    internal func userPredicate(from sessionCD: SessionCD) -> NSPredicate {
        NSPredicate(format: "\(AttributeName.user) == %@", sessionCD.userUuid)
    }

    // MARK: Pictor Repository Protocol
    // MARK: Get
    public func count() -> Int {
        var result: Int = 0

        coreDataService.mainContext.performAndWait {
            do {
                let fetchRequest = try fetchRequest()
                result = try coreDataService.mainContext.count(for: fetchRequest)
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾 count() error: \(error)")
            }
        }

        return result
    }

    public func get(byUuid: String) -> PictorModelType? {
        var result: PictorModelType?

        coreDataService.mainContext.performAndWait {
            do {
                let fetchRequest = try fetchRequest(uuids: [byUuid])
                fetchRequest.fetchLimit = 1
                if let first = try coreDataService.mainContext.fetch(fetchRequest).first {
                    result = convertToModel(first)
                }
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾 get(byUuid:) error: \(error)")
            }
        }

        return result
    }

    public func getAll() -> [PictorModelType] {
        getAll(sortBy: sortBy)
    }

    public func get(byUuids: [String]) -> [PictorModelType] {
        get(byUuids: byUuids, sortBy: sortBy)
    }

    public func get(from: Int, count: Int) -> [PictorModelType] {
        get(from: from, count: count, sortBy: sortBy)
    }
}

private extension PictorRepository {
    func getAll(sortBy: [(attributeName: String, ascending: Bool)] = []) -> [PictorModelType] {
        var result: [PictorModelType] = []

        coreDataService.mainContext.performAndWait {
            do {
                let fetchRequest = try fetchRequest()
                let fetchResult = try coreDataService.mainContext.fetch(fetchRequest)
                result = fetchResult.compactMap { convertToModel($0) }
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾 getAll() error: \(error)")
            }
        }

        return result
    }

    func get(byUuids: [String],
             sortBy: [(attributeName: String, ascending: Bool)] = []) -> [PictorModelType] {
        var result: [PictorModelType] = []

        coreDataService.mainContext.performAndWait {
            do {
                let fetchRequest = try fetchRequest(uuids: byUuids,
                                                    sortBy: sortBy)
                let fetchResult = try coreDataService.mainContext.fetch(fetchRequest)
                result = fetchResult.compactMap { convertToModel($0) }
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾 get(byUuids:) error: \(error)")
            }
        }

        return result
    }

    func get(from: Int,
             count: Int,
             sortBy: [(attributeName: String, ascending: Bool)] = []) -> [PictorModelType] {
        var result: [PictorModelType] = []

        coreDataService.mainContext.performAndWait {
            do {
                let fetchRequest = try fetchRequest(sortBy: sortBy)
                fetchRequest.fetchOffset = max(from, 0)
                fetchRequest.fetchLimit = max(count, 1)

                let fetchResult = try coreDataService.mainContext.fetch(fetchRequest)
                result = fetchResult.compactMap { convertToModel($0)}
            } catch let error {
                PictorLogger.shared.e(.tag, "❌💾 get(from:count:) error: \(error)")
            }
        }

        return result
    }

    func fetchRequest(uuids: [String]? = nil,
                      sortBy: [(attributeName: String, ascending: Bool)] = []) throws -> NSFetchRequest<PictorEngineManagedObject> {
        let sessionCD = try getSessionCD()

        var subPredicateList: [NSPredicate] = []
        // - user session
        if entity.hasAttribute(name: AttributeName.user) {
            subPredicateList.append(userPredicate(from: sessionCD))
        }
        // - synchro is not deleted
        if entity.hasAttribute(name: AttributeName.synchroIsDeleted) {
            subPredicateList.append(synchroIsNotDeletedPredicate)
        }
        // - UUIDs
        if let uuids = uuids {
            subPredicateList.append(NSPredicate(format: "uuid IN %@", uuids))
        }

        let fetchRequest: NSFetchRequest<PictorEngineManagedObject> = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
        // - Sort
        fetchRequest.sortDescriptors = sortBy.map { (attributeName, ascending) in
            NSSortDescriptor.init(key: attributeName, ascending: ascending)
        }
        return fetchRequest
    }
}
