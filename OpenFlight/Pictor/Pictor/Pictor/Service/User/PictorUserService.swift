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
import Combine

// MARK: - User Service Event
public enum PictorUserEvent: Equatable {
    /// User did create account
    case didCreateAccount
    /// User did login, boolean to know if log user is different from previous
    case didLogin(Bool)
    /// User did logout
    case didLogout
    /// User did change private mode locally
    case didChangePrivateMode
    /// User did change private mode from cloud
    case didChangeCloudPrivateMode
    /// User did update informations
    case didChangeInfo
    /// User did refresh information from network
    case didRefreshUser
}

// MARK: - User Service Protocol
public protocol PictorUserService: PictorUserServiceConfiguration, PictorUserServiceAccount {
    /// The current user
    var currentUser: PictorUserModel { get }

    /// The publisher of `currentUser` value
    var currentUserPublisher: AnyPublisher<PictorUserModel, Never> { get }

    /// The publisher of event user
    var userEventPublisher: AnyPublisher<PictorUserEvent, Never> { get }

    /// The default number of freemium project.
    var nbFreemiumProjectsDefault: Int { get }
}
