//    Copyright (C) 2020 Parrot Drones SAS
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

import KeychainAccess
import Combine

// MARK: - Private Enums
/// Enum with some user informations keys for the keychain.
enum UserInformationKey {
    static let accountConnection = "AccountConnection"
    static let token = "token"
    static let apcId = "apcId"
}

public protocol UserInformation: AnyObject {
    /// User information keychain
    var keychain: Keychain { get }

    /// User information token
    var token: String { get set }
    var tokenPublisher: AnyPublisher<String, Never> { get }

    /// User information apcId
    var apcId: String { get set }
}

/// Class used to handle the storage of the user informations in the keychain.
public class UserInformationImpl: UserInformation {

    // MARK: - Public Properties

    public var keychain: Keychain {
        return Keychain(service: UserInformationKey.accountConnection)
    }

    private let tokenSubject = CurrentValueSubject<String, Never>("")
    public var tokenPublisher: AnyPublisher<String, Never> { tokenSubject.eraseToAnyPublisher() }

    public var token: String {
        get {
            keychain.get(UserInformationKey.token) ?? ""
        } set {
            keychain.set(key: UserInformationKey.token, newValue)
            self.tokenSubject.value = newValue
        }
    }

    public var apcId: String {
        get {
            return keychain.get(UserInformationKey.apcId) ?? User.anonymousId
        }
        set {
            keychain.set(key: UserInformationKey.apcId, newValue)
        }
    }

    private var storedCurrentUser: User?
    public var currentUser: User? {
        get {
            if storedCurrentUser == nil {
                if apcId != User.anonymousId {
                    storedCurrentUser = Services.hub.repos.user.getCurrentUser()
                } else {
                    storedCurrentUser = Services.hub.repos.user.getAnonymousUser()
                }
            }
            return storedCurrentUser
        }
        set {
            storedCurrentUser = newValue
        }
    }

    // MARK: - Init
    public init() {
        self.tokenSubject.value = token
    }
}
