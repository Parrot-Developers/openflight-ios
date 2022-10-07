//    Copyright (C) 2021 Parrot Drones SAS
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

// MARK: - Repository protocol
public protocol UserRepository: AnyObject {
    // MARK: __ Save or update
    /// Save or update User into CoreData
    /// - Parameters:
    ///    - user: User to save or update
    ///    - completion: The callback returning the status.
    func saveOrUpdateUser(_ user: User, completion: ((_ status: Bool) -> Void)?)
    func saveOrUpdateUser(_ user: User)

    /// Set new Token for AnonymousUser
    func updateTokenForAnonymousUser(_ token: String)

    // MARK: __ Get
    /// Get user from CoreData
    /// - Parameters:
    ///    - apcId: the apcId of the user to get
    /// - Returns
    ///     - The user with given apcId
    func getUser(from apcId: String) -> User?

    /// Load Anonymous User from CoreData
    /// - Returns
    ///     - Anonymous user
    func getAnonymousUser() -> User

    /// Boolean to know if user in core data is new from previous logged one
    /// - Parameters:
    ///     - apcId: ApcId of new user to check
    /// - Returns
    ///     - Boolean to know if logged user ApcId is different than previous one
    func isNewUserFromPrevious(withApcId apcId: String) -> Bool

    /// Delete all users except for anonymous user
    func deleteAllUsersExceptAnonymous(completion: ((_ status: Bool) -> Void)?)

    /// Delete all other users from apcId except for anonymous user
    /// - Parameters:
    ///     - apcId: ApcId to check other users
    func deleteAllOtherUsersExceptAnonymous(fromApcId apcId: String)
}

// MARK: - Implementation
extension CoreDataServiceImpl: UserRepository {
    // MARK: __ Save or update
    public func saveOrUpdateUser(_ user: User, completion: ((_ status: Bool) -> Void)?) {
        performAndSave({ [unowned self] _ in
            var userParrotObj: UserParrot?
            if let existingUserParrot = getUserCD(fromEmail: user.email) {
                userParrotObj = existingUserParrot
            } else if let newUserParrot = insertNewObject(entityName: UserParrot.entityName) as? UserParrot {
                userParrotObj = newUserParrot
            }

            guard let userParrot = userParrotObj else {
                completion?(false)
                return false
            }

            userParrot.update(fromUser: user)

            return true
        }, { result in
            switch result {
            case .success:
                completion?(true)
            case .failure(let error):
                ULog.e(.dataModelTag, "Error saveOrUpdateUser with apcId \(user.apcId): \(error.localizedDescription)")
                completion?(false)
            }
        })
    }

    public func saveOrUpdateUser(_ user: User) {
        saveOrUpdateUser(user, completion: nil)
    }

    public func updateTokenForAnonymousUser(_ token: String) {
        var anonymousUser = getAnonymousUser()
        anonymousUser.apcToken = token
        saveOrUpdateUser(anonymousUser)
    }

    // MARK: __ Get
    public func getUser(from apcId: String) -> User? {
        getUserCD(fromApcId: apcId)?.model()
    }

    public func getAnonymousUser() -> User {
        guard let anonymousUser = getUserCD(fromApcId: User.anonymousId)?.model() else {
            let anonymousUser = User.createAnonymous(withToken: nil)
            saveOrUpdateUser(anonymousUser)
            return anonymousUser
        }

        return anonymousUser
    }

    public func isNewUserFromPrevious(withApcId apcId: String) -> Bool {
        let fetchRequest = UserParrot.fetchRequest()
        let apcIdPredicate = NSPredicate(format: "apcId != %@", apcId)
        let anonymousPredicate = NSPredicate(format: "apcId != %@", User.anonymousId)

        let subPredicateList: [NSPredicate] = [apcIdPredicate, anonymousPredicate]
        let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
        fetchRequest.predicate = compoundPredicates

        let usersCount = fetchCount(request: fetchRequest)
        return (usersCount > 0)
    }

    // MARK: __ Delete
    public func deleteAllUsersExceptAnonymous(completion: ((_ status: Bool) -> Void)?) {
        let fetchRequest = UserParrot.fetchRequest()
        let anonymousPredicate = NSPredicate(format: "apcId != %@", User.anonymousId)
        fetchRequest.predicate = anonymousPredicate

        let users = fetch(request: fetchRequest)
        deleteObjects(users, completion: { result in
            if case .success = result {
                completion?(true)
            } else {
                completion?(false)
            }
        })
    }

    public func deleteAllOtherUsersExceptAnonymous(fromApcId apcId: String) {
        let fetchRequest = UserParrot.fetchRequest()
        let apcIdPredicate = NSPredicate(format: "apcId != %@", apcId)
        let anonymousPredicate = NSPredicate(format: "apcId != %@", User.anonymousId)

        let subPredicateList: [NSPredicate] = [apcIdPredicate, anonymousPredicate]
        let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
        fetchRequest.predicate = compoundPredicates

        let users = fetch(request: fetchRequest)
        delete(users) { error in
            ULog.e(.dataModelTag, "Error deleteAllUsersExceptAnonymous: \(error.localizedDescription)")
        }
    }
}

// MARK: - Internal
internal extension CoreDataServiceImpl {
    func getUserCD(fromApcId apcId: String) -> UserParrot? {
        let fetchRequest = UserParrot.fetchRequest()
        let apcIdPredicate = NSPredicate(format: "apcId == %@", apcId)
        fetchRequest.predicate = apcIdPredicate
        fetchRequest.fetchLimit = 1

        return fetch(request: fetchRequest).first
    }

    func getUserCD(fromEmail email: String) -> UserParrot? {
        let fetchRequest = UserParrot.fetchRequest()
        let apcIdPredicate = NSPredicate(format: "email == %@", email)
        fetchRequest.predicate = apcIdPredicate
        fetchRequest.fetchLimit = 1

        return fetch(request: fetchRequest).first
    }
}
