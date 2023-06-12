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

// MARK: - Protocol
protocol PictorBaseContext {
    /// Gets a new context to work in.
    static func new() -> PictorContext

    /// Create or update if found list of models in current context.
    /// - Parameters:
    ///     - models: array of models to create
    func create<T: PictorBaseModel>(_ models: [T])

    /// Update list of models in current context.
    /// - Parameters:
    ///     - models: array of models to update
    func update<T: PictorBaseModel>(_ models: [T])

    /// Create or update locally if found list of models in current context.
    /// - Parameters:
    ///     - models: array of models to create
    func createLocal<T: PictorBaseModel>(_ models: [T])

    /// Update locally list of models in current context.
    /// - Parameters:
    ///     - models: array of models to update
    func updateLocal<T: PictorBaseModel>(_ models: [T])

    /// Delete list of models in current context.
    /// - Parameters:
    ///     - models: array of models to delete
    func delete<T: PictorBaseModel>(_ models: [T])

    /// Propagates changes to the database.
    func commit()

    /// Cancels all changes and restore from the persistentStore.
    func rollback()

    /// Undo last modification.
    func undo()

    /// Redo last modification.
    func redo()

    /// Refresh all records.
    func refreshAll()
}

// MARK: - Implementation
public class PictorContext: PictorBaseContext {
    // MARK: Private
    internal var coreDataService: CoreDataService!
    private var mainContext: NSManagedObjectContext!
    internal var currentChildContext: NSManagedObjectContext!
    private var cancellables = Set<AnyCancellable>()

    // MARK: Init
    private init(coreDataService: CoreDataService) {
        self.coreDataService = coreDataService
        self.mainContext = coreDataService.mainContext
        self.currentChildContext = coreDataService.newChildContext()
    }

    public static func new() -> PictorContext {
        PictorContext(coreDataService: CoreDataStackService.shared)
    }

    public func create<T: PictorBaseModel>(_ models: [T]) {
        createUsers(models)
        createSessions(models)
        createDrones(models)
        createProjects(models)
        createProjectPix4ds(models)
        createFlights(models)
        createFlightPlans(models)
        createGutmaLinks(models)
    }

    public func update<T: PictorBaseModel>(_ models: [T]) {
        updateUsers(models)
        updateSessions(models)
        updateDrones(models)
        updateProjects(models)
        updateProjectPix4ds(models)
        updateFlights(models)
        updateFlightPlans(models)
        updateGutmaLinks(models)
    }

    public func createLocal<T: PictorBaseModel>(_ models: [T]) {
        createUsers(models)
        createSessions(models)
        createDrones(models)
        createProjects(models, local: true)
        createProjectPix4ds(models)
        createFlights(models, local: true)
        createFlightPlans(models, local: true)
        createGutmaLinks(models, local: true)
    }

    public func updateLocal<T: PictorBaseModel>(_ models: [T]) {
        updateUsers(models)
        updateSessions(models)
        updateDrones(models)
        updateProjects(models, local: true)
        updateProjectPix4ds(models)
        updateFlights(models, local: true)
        updateFlightPlans(models, local: true)
        updateGutmaLinks(models, local: true)
    }

    public func delete<T: PictorBaseModel>(_ models: [T]) {
        deleteUsers(models)
        deleteSessions(models)
        deleteDrones(models)
        deleteProjects(models)
        deleteProjectPix4ds(models)
        deleteFlights(models)
        deleteFlightPlans(models)
        deleteGutmaLinks(models)
    }

    public func commit() {
        coreDataService.saveChildContext(currentChildContext)
    }

    public func rollback() {
        currentChildContext.rollback()
    }

    public func undo() {
        currentChildContext.undo()
    }

    public func redo() {
        currentChildContext.redo()
    }

    public func refreshAll() {
        currentChildContext.refreshAllObjects()
    }
}
