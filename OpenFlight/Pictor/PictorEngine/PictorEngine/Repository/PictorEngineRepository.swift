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

// MARK: - Protocol
public protocol PictorEngineRepository {
    associatedtype PictorBaseModelType

    // MARK: Publishers
    /// Indicates when reposotory has changed.
    var didChangePublisher: AnyPublisher<Void, Never> { get }

    /// Indicates when reposotory has added records.
    var didAddPublisher: AnyPublisher<[String], Never> { get }

    /// Indicates when reposotory has deleted records.
    var didDeletePublisher: AnyPublisher<[String], Never> { get }

    /// Indicates when reposotory has deleted all records.
    var didDeleteAllPublisher: AnyPublisher<Void, Never> { get }

    // MARK: Get
    /// Gets count of all records.
    func getCount() -> Int

    /// Gets record with the specified UUID.
    /// - Parameters:
    ///     - byUuid: uuid to search
    /// - Returns Record if found
    func get(byUuid: String) -> PictorBaseModelType?

    /// Gets all records
    func getAll() -> [PictorBaseModelType]

    /// Gets a list of records with specified UUIDs.
    ///  - Parameters:
    ///     - byUuids: list of uuids to search
    ///  - Returns List of records
    func get(byUuids: [String]) -> [PictorBaseModelType]

    /// Gets a list of records with the specified offset and number of records.
    ///  - Parameters:
    ///     - from: offset start
    ///     - count: number of records to get
    /// - Returns List of records
    func get(from: Int, count: Int) -> [PictorBaseModelType]

    // MARK: Delete
    /// Deletes records with specified UUIDs.
    ///   - Parameters:
    ///     - byUuids: list of uuids to delete
    func delete(byUuids: [String])

    /// Deletes all records
    func deleteAll()
}

// MARK: - Implementation
public class PictorEngineRepositoryImpl<PictorModelType, PictorCDType>: PictorEngineRepository where PictorModelType: PictorEngineBaseModel,
                                                                                                     PictorCDType: NSManagedObject {
    public func convertToModel(_ record: PictorCDType) -> PictorModelType? {
        return nil
    }

    // MARK: Pictor User Repository Protocol
    // MARK: Publishers
    var didChangeSubject = PassthroughSubject<Void, Never>()
    public var didChangePublisher: AnyPublisher<Void, Never> {
        didChangeSubject.eraseToAnyPublisher()
    }

    var didAddSubject = PassthroughSubject<[String], Never>()
    public var didAddPublisher: AnyPublisher<[String], Never> {
        didAddSubject.eraseToAnyPublisher()
    }

    var didDeleteSubject = PassthroughSubject<[String], Never>()
    public var didDeletePublisher: AnyPublisher<[String], Never> {
        didDeleteSubject.eraseToAnyPublisher()
    }

    var didDeleteAllSubject = PassthroughSubject<Void, Never>()
    public var didDeleteAllPublisher: AnyPublisher<Void, Never> {
        didDeleteAllSubject.eraseToAnyPublisher()
    }

    // MARK: Get
    public func getCount() -> Int {
        var result: Int = 0

        coreDataService.mainContext.performAndWait {
            do {
                let fetchRequest = PictorCDType.fetchRequest() as! NSFetchRequest<PictorCDType>
                result = try coreDataService.mainContext.count(for: fetchRequest)
            } catch let error {
                print("getCount() error: \(error)")
            }
        }

        return result
    }

    public func get(byUuid: String) -> PictorModelType? {
        var result: PictorModelType?

        coreDataService.mainContext.performAndWait {
            do {
                let fetchRequest = PictorCDType.fetchRequest() as! NSFetchRequest<PictorCDType>
                let uuidPredicate = NSPredicate(format: "uuid == %@", byUuid)
                fetchRequest.fetchLimit = 1
                fetchRequest.predicate = uuidPredicate
                if let first = try coreDataService.mainContext.fetch(fetchRequest).first,
                   let model = convertToModel(first) {
                    result = model
                }
            } catch let error {
                print("get(byUuid:) error: \(error)")
            }
        }

        return result
    }

    public func getAll() -> [PictorModelType] {
        var result: [PictorModelType] = []

        coreDataService.mainContext.performAndWait {
            do {
                let fetchRequest = PictorCDType.fetchRequest() as! NSFetchRequest<PictorCDType>
                let fetchResult = try coreDataService.mainContext.fetch(fetchRequest)
                result = fetchResult.compactMap {
                    if let model = convertToModel($0) {
                        return model
                    }
                    return nil
                }
            } catch let error {
                print("getAll() error: \(error)")
            }
        }

        return result
    }

    public func get(byUuids: [String]) -> [PictorModelType] {
        var result: [PictorModelType] = []

        coreDataService.mainContext.performAndWait {
            do {
                let fetchRequest = PictorCDType.fetchRequest() as! NSFetchRequest<PictorCDType>
                let uuidPredicate = NSPredicate(format: "uuid IN %@", byUuids)
                fetchRequest.predicate = uuidPredicate
                let fetchResult = try coreDataService.mainContext.fetch(fetchRequest)
                result = fetchResult.compactMap {
                    if let model = convertToModel($0) {
                        return model
                    }
                    return nil
                }
            } catch let error {
                print("get(byUuids:) error: \(error)")
            }
        }

        return result
    }

    public func get(from: Int, count: Int) -> [PictorModelType] {
        var result: [PictorModelType] = []

        coreDataService.mainContext.performAndWait {
            do {
                let fetchRequest = PictorCDType.fetchRequest() as! NSFetchRequest<PictorCDType>
                fetchRequest.fetchOffset = max(from, 0)
                fetchRequest.fetchLimit = max(count, 1)
                let fetchResult = try coreDataService.mainContext.fetch(fetchRequest)
                result = fetchResult.compactMap {
                    if let model = convertToModel($0) {
                        return model
                    }
                    return nil
                }
            } catch let error {
                print("get(from:count:) error: \(error)")
            }
        }

        return result
    }

    // MARK: Delete
    public func delete(byUuids: [String]) {
        let childContext = coreDataService.newChildContext()

        childContext.performAndWait {
            do {
                let fetchRequest = PictorCDType.fetchRequest() as! NSFetchRequest<PictorCDType>
                let uuidPredicate = NSPredicate(format: "uuid IN %@", byUuids)
                fetchRequest.predicate = uuidPredicate
                let fetchResult = try childContext.fetch(fetchRequest)

                fetchResult.forEach {
                    childContext.delete($0)
                }

                coreDataService.save(context: childContext)
            } catch let error {
                print("delete(byUuids:) error: \(error)")
            }
        }

        return
    }

    public func deleteAll() {
        let childContext = coreDataService.newChildContext()

        childContext.performAndWait {
            do {
                let fetchRequest = PictorCDType.fetchRequest() as! NSFetchRequest<PictorCDType>
                let fetchResult = try childContext.fetch(fetchRequest)

                fetchResult.forEach {
                    childContext.delete($0)
                }

                coreDataService.save(context: childContext)
            } catch let error {
                print("deleteAll() error: \(error)")
            }
        }
    }

    // MARK: Init
    private var coreDataService: CoreDataService

    public init(coreDataService: CoreDataService) {
        self.coreDataService = coreDataService
    }
}
