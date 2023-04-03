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

public enum PairingAction {
    case pairUser
    case unpairUser
}

// MARK: - Protocol
public protocol AcademyApiDroneService: AcademyErrorService {
    /// Gets paired drones list.
    ///
    /// - Parameters:
    ///    - completion: callback which returns the paired drones list
    func getPairedDroneList(completion: @escaping (Result<[AcademyDroneResponse], Error>) -> Void)

    /// Performs the challenge request.
    ///
    /// - Parameters:
    ///     - action: create a challenge with our selected action (pair or unpair)
    ///     - completion: callback which returns challenge request result and error
    func performChallengeRequest(action: PairingAction,
                                 completion: @escaping (Result<String, Error>) -> Void)

    /// Performs the pairing association request.
    ///
    /// - Parameters:
    ///     - token: the json string signed by the drone divided in three base64 part
    ///     - completion: callback which returns the result of the association process
    func performAssociationRequest(token: String,
                                   completion: @escaping (Result<Bool, Error>) -> Void)

    /// Unpairs current associated 4G drone.
    ///
    /// - Parameters:
    ///     - commonName: drone common name
    ///     - completion: callback which returns data and error
    func unpairDrone(commonName: String,
                     completion: @escaping (Result<Data, Error>) -> Void)

    /// Unpairs all users associated to the current drone except the authenticated one.
    ///
    /// - Parameters:
    ///     - token: the json string signed by the drone divided in three base64 part
    ///     - completion: callback which returns data and error
    func unpairAllUsers(token: String,
                        completion: @escaping (Result<Data, Error>) -> Void)

    /// Gets paired users count for a selected drone.
    ///
    /// - Parameters:
    ///     - commonName: drone common name
    ///     - completion: callback which returns number of paired users and a potential error
    func pairedUsersCount(commonName: String,
                          completion: @escaping (Result<Int?, Error>) -> Void)
}
