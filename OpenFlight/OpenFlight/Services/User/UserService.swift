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
import KeychainAccess
import Combine
import GroundSdk

extension ULogTag {
    static let userServiceTag = ULogTag(name: "userService")
}

public enum UserEvent: Equatable {
    /// User did create account
    case didCreateAccount
    /// User did login, boolean to know if log user is different from previous
    case didLogin(Bool)
    /// User did logout
    case didLogout
    /// User did change private mode
    case didChangePrivateMode
    /// User did refresh information from network
    case didRefreshUser
}

public protocol UserService {

    /// The current user in core data
    var currentUser: User { get set }

    /// The publisher of `currentUser` value
    var currentUserPublisher: AnyPublisher<User, Never> { get }

    /// The publisher of event user
    var userEventPublisher: AnyPublisher<UserEvent, Never> { get }

    /// Refreshes the current anonymous token if needed
    ///
    /// - Parameters:
    ///   - completion: return nil if success, an error if something went wrong.
    func refreshAnonymousToken(completion: @escaping (_ error: Error?) -> Void)

    /// Method to send a new user event
    func sendUserEvent(_ userEvent: UserEvent)
}

public class UserServiceImpl: UserService {

    /// Enum with some user informations keys for the keychain.
    private enum UserServiceKey {
        static let userService = "userService"
        static let apcId = "apcId"
    }

    private var userRepo: UserRepository!
    private var currentUserSubject: CurrentValueSubject<User, Never>!
    private var userEventSubject = PassthroughSubject<UserEvent, Never>()
    private var keychain: Keychain!
    private let apcApiManager: APCApiManager

    private var apcId: String {
        get {
            return keychain.get(UserServiceKey.apcId) ?? User.anonymousId
        }
        set {
            keychain.set(key: UserServiceKey.apcId, newValue)
        }
    }

    public var currentUser: User {
        get {
            return currentUserSubject.value
        }
        set {
            currentUserSubject.value = newValue
            apcId = newValue.apcId
        }
    }

    public var currentUserPublisher: AnyPublisher<User, Never> {
        currentUserSubject.eraseToAnyPublisher()
    }

    public var userEventPublisher: AnyPublisher<UserEvent, Never> {
        userEventSubject.eraseToAnyPublisher()
    }

    public init(apcApiManager: APCApiManager) {
        self.keychain = Keychain(service: UserServiceKey.userService)
        self.apcApiManager = apcApiManager
    }

    public func setup(userRepo: UserRepository) {
        self.userRepo = userRepo
        let apcId = keychain.get(UserServiceKey.apcId) ?? User.anonymousId
        currentUserSubject = CurrentValueSubject(userRepo.getUser(from: apcId) ?? userRepo.getAnonymousUser())
    }

    public func sendUserEvent(_ userEvent: UserEvent) {
        ULog.d(.userServiceTag, "User event send \(userEvent)")
        userEventSubject.send(userEvent)
    }

    public func refreshAnonymousToken(completion: @escaping (_ error: Error?) -> Void) {
        apcApiManager.createTemporaryAccount { [weak self] isAccountCreated, token, error in
            DispatchQueue.main.async {
                guard error == nil,
                      isAccountCreated == true,
                      let token = token,
                      !token.isEmpty else {
                          ULog.e(.userServiceTag, "Error while creating account \(String(describing: error?.localizedDescription))")
                          completion(error)
                          return
                      }
                self?.saveAnonymousToken(token: token)
                completion(nil)
            }
        }
    }
}

private extension UserServiceImpl {
    func saveAnonymousToken(token: String) {
        currentUser.apcToken = token
        userRepo.saveOrUpdateUser(currentUser) { status in
            guard status else {
                ULog.e(.userServiceTag, "Save database error")
                return
            }
        }
    }
}
