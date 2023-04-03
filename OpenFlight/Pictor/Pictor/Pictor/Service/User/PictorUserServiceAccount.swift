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

// MARK: - User Service Authentication Info Protocol
public struct PictorUserServiceAuthenticationInfo {
    /// The user email.
    public let email: String
    /// The password.
    public let password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

// MARK: - User Service Creation Info Protocol
public struct PictorUserServiceCreationInfo {
    /// The user email.
    public let email: String
    /// The password to use for authentication.
    public let password: String
    /// The user first name.
    public var firstName: String
    /// The user last name.
    public var lastName: String
    /// `true` if the user accept aprental consent, `false` otherwise.
    public var parentalConsent: Bool
    /// The user identifier given by external authentication (ie. googleId, appleId, ...).
    public let userId: String?
    /// `true` if the user is in private mode, `false` if is not in private mode and `nil` if no private mode selected.
    public var isPrivateMode: Bool?

    public init(email: String,
                password: String,
                firstName: String,
                lastName: String,
                parentalConsent: Bool,
                userId: String?,
                isPrivateMode: Bool?) {
        self.email = email
        self.password = password
        self.firstName = firstName
        self.lastName = lastName
        self.parentalConsent = parentalConsent
        self.userId = userId
        self.isPrivateMode = isPrivateMode
    }
}

// MARK: - User Service User Info
public struct PictorUserServiceUserInfo {
    /// The user first name.
    public let firstname: String
    /// The user last name.
    public let lastname: String
    /// The user pilot number.
    public let pilotNumber: Int?

    public init(firstname: String, lastname: String, pilotNumber: Int?) {
        self.firstname = firstname
        self.lastname = lastname
        self.pilotNumber = pilotNumber
    }
}

// MARK: - User Service Account Protocol
public protocol PictorUserServiceAccount: PictorUserServiceAppleAccount, PictorUserServiceGoogleAccount {
    /// Creates user and logs in auto
    ///
    /// - Parameters:
    ///   - creationInfo: the creation information
    ///   - completion: return a response if success, an error if something went wrong.
    func create(creationInfo: PictorUserServiceCreationInfo,
                completion: @escaping (_ error: PictorUserServiceError?) -> Void)

    ///  Logs in user from authentication informations.
    ///
    /// - Parameters:
    ///   - authenticationInfo: the authentication information
    ///   - completion: return a response if success, an error if something went wrong.
    func login(authenticationInfo: PictorUserServiceAuthenticationInfo,
               completion: @escaping (_ error: PictorUserServiceError?, _ isOldAccount: Bool) -> Void)

    /// Refreshes the current user.
    /// Updates profile, personal data and avatar of the current user.
    ///
    /// - Parameters:
    ///   - completion: return a response if success, an error if something went wrong.
    func refresh(completion: @escaping (_ error: PictorUserServiceError?) -> Void)

    /// Updates avatar
    ///
    /// - Parameters:
    ///   - data: the avatar data to update
    ///   - completion: return a response if success, an error if something went wrong.
    func updateAvatar(_ data: Data,
                      completion: @escaping (_ error: PictorUserServiceError?) -> Void)

    /// Deletes avatar
    ///
    /// - Parameters:
    ///   - completion: return a response if success, an error if something went wrong.
    func deleteAvatar(completion: @escaping (PictorUserServiceError?) -> Void)

    /// Updates user
    ///
    /// - Parameters:
    ///   - userInfo: the user information
    ///   - completion: return a response if success, an error if something went wrong.
    func updateUser(userInfo: PictorUserServiceUserInfo,
                    completion: @escaping (_ error: PictorUserServiceError?) -> Void)

    /// Checks if current user exist
    ///
    /// - Parameters:
    ///   - email: the email of the user
    ///   - completion: return a boolean if success, an error if something went wrong.
    func checkUserExists(from email: String,
                         completion: @escaping (_ userExists: Bool?, _ error: PictorUserServiceError?) -> Void)

    /// Deletes the current user
    ///
    /// - Parameters:
    ///   - completion: return a response if success, an error if something went wrong.
    func deleteUser(completion: @escaping (_ error: PictorUserServiceError?) -> Void)

    /// Deletes user cloud data
    func deleteUserCloudData(completion: @escaping (PictorUserServiceError?) -> Void)

    /// Updates user to private mode
    ///
    /// - Parameters:
    ///   - completion: return a response if success, an error if something went wrong.
    func updateToPrivateMode(completion: @escaping (_ error: PictorUserServiceError?) -> Void)

    /// Updates user to sharing mode
    ///
    /// - Parameters:
    ///   - completion: return a response if success, an error if something went wrong.
    func updateToSharingMode(completion: @escaping (_ error: PictorUserServiceError?) -> Void)

    /// Resets forgotten password.
    ///
    /// - Parameters:
    ///   - email: the email of user
    ///   - completion: return a response if success, an error if something went wrong.
    func resetForgottenPassword(with email: String,
                                completion: @escaping (_ error: PictorUserServiceError?) -> Void)

    /// Logs out user.
    ///
    /// - Parameters:
    ///   - completion: Callback closure when logged out.
    func logout(completion: @escaping () -> Void)
}
