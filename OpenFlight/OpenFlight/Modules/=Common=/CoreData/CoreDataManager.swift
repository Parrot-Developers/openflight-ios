// Copyright (C) 2020 Parrot Drones SAS
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

public protocol CoreDataService: AnyObject {

    /// Publisher notifys new object to remove from Server and Coredata
    var objectToRemovePublisher: AnyPublisher<Any, Never> { get }

    /// Publisher notifys new object to upload to Server
    var objectToUploadPublisher: AnyPublisher<Any, Never> { get }

    /// Batch delete all stored data entities in CoreData
    /// to use only when switch between users accounts
    /// - Parameters:
    ///     - removeUserEntity: Boolean to indicate if should keep the User entity with data or not
    func batchDeleteData(_ removeUserEntity: Bool)
}

/// CoreData Service
public class CoreDataServiceImpl: CoreDataService {

    // MARK: - Public Properties
    /// Returns current Managed Object Context.
    public var currentContext: NSManagedObjectContext?
    /// Returns current PersistentContainer.
    private let persistentContainer: NSPersistentContainer
    /// User information service
    public var userInformation: UserInformation
    /// Returns array of `ProjectModel` subject
    public var projects = CurrentValueSubject<[ProjectModel], Never>([])

    /// Contains a given object to remove from Server and Coredata
    var objectToRemove = PassthroughSubject<Any, Never>()

    /// Publisher notifies new object to remove from Server and Coredata
    public var objectToRemovePublisher: AnyPublisher<Any, Never> {
        objectToRemove.eraseToAnyPublisher()
    }

    /// Contains a given object to upload to Server
    var objectToUpload = PassthroughSubject<Any, Never>()

    /// Publisher notifies new object to upload to Server
    public var objectToUploadPublisher: AnyPublisher<Any, Never> {
        objectToUpload.eraseToAnyPublisher()
    }

    // MARK: - Public Funcs
    public init(with persistentContainer: NSPersistentContainer, userInformation: UserInformation) {
        self.userInformation = userInformation
        self.persistentContainer = persistentContainer
        currentContext = persistentContainer.viewContext
        currentContext?.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(managedObjectContextDidChange),
                                               name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                               object: currentContext)
    }
}

extension CoreDataServiceImpl {

    public func batchDeleteData(_ removeUserEntity: Bool) {
        guard let managedContext = currentContext else {
            return
        }

        var entityNames = persistentContainer.managedObjectModel.entities.compactMap({ $0.name })

        if !removeUserEntity,
           let indexOfUserEntity = entityNames.firstIndex(of: UserParrot.userParrotEntityName) {
            entityNames.remove(at: indexOfUserEntity)
        }

        entityNames.forEach { entityName in
            let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)

            do {
                try managedContext.execute(deleteRequest)
                try managedContext.save()
            } catch {
                ULog.e(.dataModelTag, "An error is occured when batch delete entity in CoreData")
            }
        }
    }
}

extension CoreDataServiceImpl {

    /// Migrate anonymous data to current logged user
    /// - Parameters:
    ///     - entityName: Name of the entity contains the data to migrate
    ///     - completion: Empty block indicates when the process is finished
    internal func migrateAnonymousDataToLoggedUser(for entityName: String,
                                                   _ completion: @escaping () -> Void) {
        guard let managedContext = currentContext else {
            completion()
            return
        }
        guard userInformation.apcId != userInformation.anonymousString else {
            ULog.e(.dataModelTag, "User must be logged in")
            completion()
            return
        }

        let entity = NSEntityDescription.entity(forEntityName: entityName, in: managedContext)
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = entity
        let predicate = NSPredicate(format: "%K == %@", "apcId", userInformation.anonymousString)
        request.predicate = predicate

        do {
            if let fetchResults = try managedContext.fetch(request) as? [NSManagedObject] {
                if !fetchResults.isEmpty {
                    fetchResults.forEach { managedObject in
                        managedObject.setValue(userInformation.apcId, forKey: "apcId")
                    }
                    try managedContext.save()
                } else {
                    ULog.i(.dataModelTag, "No ANONYMOUS data found in: \(entityName)")
                }
            }
            completion()

        } catch let error as NSError {
            ULog.e(.dataModelTag, "Migrate ANONYMOUS \(entityName) data to current logged User failed with error: \(error.userInfo)")
            completion()
        }
    }

    /// Migrate logged user data to Anonymous
    /// - Parameters:
    ///     - entityName: Name of the entity contains the data to migrate
    ///     - completion: Empty block indicates when the process is finished
    internal func migrateLoggedToAnonymous(for entityName: String,
                                           _ completion: @escaping () -> Void) {
        guard let managedContext = currentContext else {
            completion()
            return
        }
        let apcId = userInformation.apcId
        let entity = NSEntityDescription.entity(forEntityName: entityName, in: managedContext)
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = entity
        let predicate = NSPredicate(format: "%K == %@", "apcId", apcId)
        request.predicate = predicate

        do {
            if let fetchResults = try managedContext.fetch(request) as? [NSManagedObject] {
                if !fetchResults.isEmpty {
                    fetchResults.forEach { managedObject in
                        managedObject.setValue(userInformation.anonymousString, forKey: "apcId")
                    }
                    try managedContext.save()
                } else {
                    ULog.i(.dataModelTag, "No data found in: \(entityName) for user apcId: \(apcId)")
                }
            }
            completion()

        } catch let error as NSError {
            ULog.e(.dataModelTag, "Migrate Data of user apcId \(apcId) for object: \(entityName) to current ANONYMOUS user failed with error \(error.userInfo)")
            completion()
        }
    }
}
