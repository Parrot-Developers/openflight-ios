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
import SwiftyUserDefaults
import Combine

private extension DefaultsKeys {
    // MARK: - Edition Settings
    static let keySuffix = DefaultsKey<String?>("secure_key_storage_suffix")
}

public extension Keychain {
    /// This suffix stored in UserDefaults ensures that we don't access the keychain storage from
    /// a previous installation
    private var suffix: String {
        if let suffix = Defaults[key: DefaultsKeys.keySuffix] {
            return suffix
        }
        let suffix = UUID().uuidString
        Defaults[key: DefaultsKeys.keySuffix] = suffix
        return suffix

    }

    func get(_ key: String) -> String? {
        if let value = self[key + suffix] {
            self[key] = nil
            return value
        }
        // Backward compatibility fallback
        if let legacyValue = self[key] {
            self[key + suffix] = legacyValue
            self[key] = nil
            return legacyValue
        }
        return nil
    }

    func set(key: String, _ value: String?) {
        self[key + suffix] = value
    }
}

/// Handles the storage of the user informations in the keychain.
public class SecureKeyStorage {
    // MARK: - Public Properties
    /// Current keychain object.
    public static var current: SecureKeyStorage = SecureKeyStorage()

    /// Secure storage keychain.
    public let keychain = Keychain(service: Constants.secureKeyStorage)

    private let temporaryTokenSubject = CurrentValueSubject<String, Never>("")

    public var temporaryTokenPublisher: AnyPublisher<String, Never> { temporaryTokenSubject.eraseToAnyPublisher() }

    /// Secure storage temporary token.
    public var temporaryToken: String {
        get {
            return keychain.get(Constants.temporaryToken) ?? ""
        }
        set {
            keychain.set(key: Constants.temporaryToken, newValue)
            temporaryTokenSubject.value = newValue
        }
    }

    // MARK: - Internal Properties
    /// Returns true if a temporary account has been created.
    var isTemporaryAccountCreated: Bool {
        return !temporaryToken.isEmpty
    }

    // MARK: - Private Enums
    /// Stores some keys for the keychain.
    private enum Constants {
        /// Current service constant used to instantiate the keychain object.
        static let secureKeyStorage: String = "secureKeyStorage"
        static let temporaryToken: String = "temporaryToken"
    }

    // MARK: - Init
    public init() {
        temporaryTokenSubject.value = temporaryToken
    }
}
