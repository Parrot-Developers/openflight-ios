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

// MARK: - Protocol
public protocol CoreDataService {
    /// Create new child background context
    func newChildContext() -> NSManagedObjectContext

    /// Get mainContext
    var mainContext: NSManagedObjectContext! { get }

    /// Save changes in the specified context
    /// - Parameters
    ///     context: NSManagedObject to save
    func save(context: NSManagedObjectContext)
}

// MARK: - Implementation
class CoreDataStackService: CoreDataService {
    public static let shared = CoreDataStackService()

    // MARK: CoreData Service Protocol
    public private(set) var mainContext: NSManagedObjectContext!

    public func newChildContext() -> NSManagedObjectContext {
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = writerBackgroundContext
        privateContext.automaticallyMergesChangesFromParent = true

        return privateContext
    }

    public func save(context: NSManagedObjectContext) {
        context.performAndWait {
            do {
                if context.hasChanges {
                    try context.save()
                    // print("context did save")
                } else {
                    // print("context no changes")
                }
            } catch let error {
                // print("context error: \(error)")
            }
        }
    }

    // MARK: Stack
    private let identifier: String = "com.parrot.PictorEngine"
    private let model: String = "TestModel"
    private lazy var persistentContainer: NSPersistentContainer = {
        let bundle = Bundle(identifier: self.identifier)
        let url = bundle!.url(forResource: self.model, withExtension: "momd")!
        let managedObjectModel =  NSManagedObjectModel(contentsOf: url)

        let container = NSPersistentContainer(name: self.model, managedObjectModel: managedObjectModel!)
        container.loadPersistentStores { (storeDescription, error) in
            if let err = error{
                fatalError("❌ Loading of store failed:\(err)")
            }
        }

        return container
    }()
    private var writerBackgroundContext: NSManagedObjectContext!

    private init() {
        // - writer background context: use only for saving on persistentStore when mainContext is saved
        self.writerBackgroundContext = self.persistentContainer.newBackgroundContext()

        // - mainContext: use to get quick access to data on main thread
        // writerBackgroundContext is parent
        self.mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        self.mainContext.parent = self.writerBackgroundContext
        self.mainContext.automaticallyMergesChangesFromParent = true

        // - add notification observer for saving onto persistenStore when writerBackgroundContext's objects did change
        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextObjectsDidChange,
                                               object: self.writerBackgroundContext,
                                               queue: nil) { [weak self] _ in
            // print("Notification writerBackgroundContext did change")
            guard let self = self else { return }
            self.save(context: self.writerBackgroundContext)
        }
    }
}
