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

public protocol PictorEngineContext {
    associatedtype PictorEngineType
    associatedtype PictorModelType

    /// Gets a new context to work in.
    static func new() -> PictorEngineType

    /// Saves list of models in current context.
    /// - Parameters:
    ///     - models: array of models to save
    func save<T: PictorEngineBaseModel>(_ models: [T])

    /// Propagates changes to the database.
    func commit()

    /// Cancels changes.
    func rollback()
}

public protocol PictorEngineFullContext: PictorEngineContext {
    /// Fetches count of records in context with specified request.
    /// - Parameters:
    ///     - request: fetch request to specified.
    func fetchCount(request: NSFetchRequest<NSManagedObject>, completion: @escaping ((Result<Int, Error>) -> Void))

    /// Fetches in context with the specified request.
    func fetch(request: NSFetchRequest<NSManagedObject>, completion: @escaping ((Result<[PictorModelType], Error>) -> Void))

    /// Deletes in context with the specified request.
    func delete(request: NSFetchRequest<NSManagedObject>, completion: @escaping ((Result<Void, Error>) -> Void))
}

open class PictorEngineContextImpl: PictorEngineContext {
    public typealias PictorEngineType = PictorEngineContextImpl
    public typealias PictorModelType = PictorEngineBaseModel

    // MARK: - Pictor Engine Context Protocol
    public static func new() -> PictorEngineType {
        PictorEngineContextImpl(coreDataService: CoreDataStackService.shared)
    }

    public func save<T: PictorEngineBaseModel>(_ models: [T]) {
        if let models = models as? [PictorEngineUserModel] {
            saveUsers(models)
        }
    }

    public func commit() {
        coreDataService.save(context: currentChildContext)
    }

    public func rollback() {

    }

    // MARK: - Private
    internal var coreDataService: CoreDataService!
    internal var currentChildContext: NSManagedObjectContext!
    internal var mainContext: NSManagedObjectContext!

    private init(coreDataService: CoreDataService) {
        self.coreDataService = coreDataService
        self.mainContext = coreDataService.mainContext
        self.currentChildContext = coreDataService.newChildContext()
    }

    private func saveUsers(_ models: [PictorEngineUserModel]) {
        currentChildContext.perform { [weak self] in
            guard let self = self else {
                return
            }
            // Get existing records
            var existingUserCDs: [UserCD] = []
            do {
                let modelsUuids: [String] = models.compactMap { $0.uuid }
                let fetchRequest = UserCD.fetchRequest()
                let uuidPredicate = NSPredicate(format: "uuid IN %@", modelsUuids)
                fetchRequest.predicate = uuidPredicate
                existingUserCDs = try self.currentChildContext.fetch(fetchRequest)
            } catch let error {
                print("save error: \(error)")
            }

            for model in models {
                var userCD: UserCD?

                if let existingUserCD = existingUserCDs.first(where: { $0.uuid == model.uuid }) {
                    userCD = existingUserCD
                } else {
                    userCD = UserCD(context: self.currentChildContext)
                }

                if let userCD = userCD {
                    userCD.update(model)
                }
            }
        }
    }
}

open class PictorEngineFullContextImpl: PictorEngineContextImpl, PictorEngineFullContext {
    public typealias PictorEngineType = PictorEngineFullContextImpl
    public typealias PictorModelType = PictorEngineBaseModel

    public func fetchCount(request: NSFetchRequest<NSManagedObject>, completion: @escaping ((Result<Int, Error>) -> Void)) {
        currentChildContext.perform { [weak self] in
            guard let self = self else {
                completion(.success(0))
                return
            }

            do {
                let count = try self.currentChildContext.count(for: request)
                completion(.success(count))
            } catch let error {
                print("fetchCount error: \(error)")
                completion(.failure(error))
            }
        }
    }

    public func fetch<T: NSFetchRequest<NSManagedObject>>(request: T, completion: @escaping ((Result<[PictorModelType], Error>) -> Void)) {
        currentChildContext.perform { [weak self] in
            guard let self = self else {
                completion(.success([]))
                return
            }

            do {
                let fetchResult = try self.currentChildContext.fetch(request)
                //let models = fetchResult.compactMap { $0.synchroModel() }
                completion(.success([]))
            } catch let error {
                print("fetchCount error: \(error)")
                completion(.failure(error))
            }
        }
    }

    public func delete<T>(request: NSFetchRequest<T>, completion: @escaping ((Result<Void, Error>) -> Void)) where T : NSManagedObject {
        currentChildContext.perform { [weak self] in
            guard let self = self else {
                completion(.success(()))
                return
            }

            do {
                let fetchResult = try self.currentChildContext.fetch(request)
                fetchResult.forEach { self.currentChildContext.delete($0) }
                completion(.success(()))
            } catch let error {
                print("fetchCount error: \(error)")
                completion(.failure(error))
            }
        }
    }
}
