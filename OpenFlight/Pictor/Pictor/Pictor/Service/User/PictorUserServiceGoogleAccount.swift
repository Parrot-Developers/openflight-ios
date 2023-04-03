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

// MARK: - User Service Google Account
public struct PictorUserServiceGoogleAuthenticationInfo {
    /// The authentication token.
    public let token: String

    public init(token: String) {
        self.token = token
    }
}

public protocol PictorUserServiceGoogleAccount {
    /// Creates user and logs in auto from google
    ///
    /// - Parameters:
    ///   - creationInfo: the creation information
    ///   - completion: return a response if success, an error if something went wrong.
    func googleCreate(creationInfo: PictorUserServiceCreationInfo,
                      completion: @escaping (_ error: PictorUserServiceError?, _ isLogged: Bool) -> Void)

    ///  Logs in user from google.
    ///
    /// - Parameters:
    ///   - authenticationInfo: the authentication information
    ///   - completion: return a response if success, an error if something went wrong.
    func googleLogin(authenticationInfo: PictorUserServiceGoogleAuthenticationInfo,
                     completion: @escaping (_ error: PictorUserServiceError?, _ isLogged: Bool) -> Void)
}
