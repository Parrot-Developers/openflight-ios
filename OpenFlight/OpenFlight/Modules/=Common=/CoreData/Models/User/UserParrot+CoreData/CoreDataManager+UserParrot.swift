// Copyright (C) 2021 Parrot Drones SAS
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
import GroundSdk
import CoreData

public protocol UserRepository: AnyObject {
    /// Persist or update User into CoreData
    /// - Parameters
    ///    - user to persist
    func persist(_ user: User)

    /// Load current logged User from CoreData
    /// return User
    func loadCurrentUser() -> User?

    /// Load Anonymous User from CoreData
    /// return User
    func loadAnonymousUser() -> User?

    /// Set new Token for AnonymousUser
    func updateTokenForAnonymousUser(_ token: String)
}

extension CoreDataServiceIml: UserRepository {

    public func persist(_ user: User) {
        // Prepare content to save.
        guard let managedContext = currentContext else { return }

        // Prepare new CoreData entity
        let fetchRequest: NSFetchRequest<UserParrot> = UserParrot.fetchRequest()
        guard let name = fetchRequest.entityName,
              let entity = NSEntityDescription.entity(forEntityName: name, in: managedContext)
        else {
            return
        }

        let userParrot: NSManagedObject?

        // Check object if exists.
        if let object = self.loadUser("email", user.email) {
            // Use persisted object.
            userParrot = object
        } else {
            // Create new object.
            userParrot = NSManagedObject(entity: entity, insertInto: managedContext)
        }

        guard let userParrotObject = userParrot as? UserParrot else { return }

        userParrotObject.firstName = user.firstName
        userParrotObject.lastName = user.lastName
        userParrotObject.birthday = user.birthday
        userParrotObject.lang = user.lang
        userParrotObject.email = user.email
        userParrotObject.apcId = user.apcId
        userParrotObject.apcToken = user.apcToken
        userParrotObject.tmpApcUser = user.tmpApcUser
        userParrotObject.userInfoChanged = user.userInfoChanged
        userParrotObject.syncWithCloud = user.syncWithCloud
        userParrotObject.agreementChanged = user.agreementChanged
        userParrotObject.newsletterOption = user.newsletterOption
        userParrotObject.shareDataOption = user.shareDataOption
        userParrotObject.freemiumProjectCounter = user.freemiumProjectCounter

        managedContext.perform {
            do {
                try managedContext.save()
            } catch let error {
                ULog.e(.dataModelTag, "Error during persist UserParrot : \(error.localizedDescription)")
            }
        }
    }

    public func loadCurrentUser() -> User? {
        return self.loadUser( "apcId", userInformation.apcId)?.model()
    }

    public func loadAnonymousUser() -> User? {
        var anonymousUser = self.loadUser("email", userInformation.anonymousString)?.model()

        // Create an Anonymous user if doesn't exist yet
        if anonymousUser == nil {
            let anonymousString = userInformation.anonymousString
            anonymousUser = User(firstName: nil,
                                 lastName: nil,
                                 birthday: nil,
                                 lang: nil,
                                 email: anonymousString,
                                 apcId: anonymousString,
                                 apcToken: nil,
                                 tmpApcUser: true,
                                 userInfoChanged: nil,
                                 syncWithCloud: true,
                                 agreementChanged: nil,
                                 newsletterOption: nil,
                                 shareDataOption: nil,
                                 freemiumProjectCounter: nil)

            if let anonymousUser = anonymousUser {
                persist(anonymousUser)
            }
        }
        return anonymousUser
    }

    public func updateTokenForAnonymousUser(_ token: String) {
        guard var anonymousUser = loadAnonymousUser() else { return }
        anonymousUser.apcToken = token
        persist(anonymousUser)
    }
}

// MARK: - Utils
private extension CoreDataServiceIml {

    private func loadUser(_ key: String, _ value: String) -> UserParrot? {
        guard let managedContext = currentContext else { return nil }

        let fetchRequest: NSFetchRequest<UserParrot> = UserParrot.fetchRequest()
        let predicate = NSPredicate(format: "%K == %@", key, value)
        fetchRequest.predicate = predicate
        do {
            return try (managedContext.fetch(fetchRequest)).first
        } catch let error {
            ULog.e(.dataModelTag, "No User found in Coredata : \(error.localizedDescription)")
            return nil
        }
    }
}
