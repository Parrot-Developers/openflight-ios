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
    /// Persist or update current logged User into CoreData
    /// - Parameters
    ///    - user to persist
    func persist(_ user: User)

    /// Load current logged User from CoreData
    /// return User
    func loadCurrentUser() -> User?
}

extension CoreDataManager: UserRepository {

    /// Persists User.
    ///
    /// - Parameters:
    ///     - user: the current logged User
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
        if let object = self.loadUser() {
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

        managedContext.performAndWait {
            do {
                try managedContext.save()
            } catch let error {
                ULog.e(.dataModelTag, "Error during persist UserParrot : \(error.localizedDescription)")
            }
        }
    }

    /// Load current persisted User from CoreData.
    ///
    /// - Return :
    ///    - User if exist into CoreData
    public func loadCurrentUser() -> User? {
        return self.loadUser()?.model()
    }
}

// MARK: - Utils
private extension CoreDataManager {

    private func loadUser() -> UserParrot? {
        guard let managedContext = currentContext else { return nil }

        let fetchRequest: NSFetchRequest<UserParrot> = UserParrot.fetchRequest()

        do {
            return try (managedContext.fetch(fetchRequest)).first
        } catch let error {
            ULog.e(.dataModelTag, "No User found in Coredata : \(error.localizedDescription)")
            return nil
        }
    }
}
