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

public struct User {

    // MARK: - Properties
    public static let anonymousId: String = "ANONYMOUS"

    /// Default values.
    public enum DefaultValues {
        static let syncWithCloudDefault          = true
        static let userInfoChangedDefault        = false
        static let agreementChangedDefault       = false
        static let newsletterOptionDefault       = false
        static let shareDataOptionDefault        = false
        static let tempApcUserDefault            = false
        static let langDefault                   = "en"
        static let freemiumProjectCounterDefault = 3
    }

    public var academyId: String?
    public var firstName: String?
    public var lastName: String?
    public var birthday: String?
    public var lang: String
    public var email: String
    public var apcId: String
    public var apcToken: String?
    public var avatar: String?
    public var tmpApcUser: Bool
    public var userInfoChanged: Bool
    public var syncWithCloud: Bool
    public var agreementChanged: Bool
    public var isSynchronizeFlightDataExtended: Bool
    public var freemiumProjectCounter: Int16
    public var pilotNumber: String?

    // MARK: - Public init

    public init(academyId: String?,
                firstName: String?,
                lastName: String?,
                birthday: String?,
                lang: String?,
                email: String,
                apcId: String,
                apcToken: String?,
                avatar: String?,
                pilotNumber: String?,
                tmpApcUser: Bool?,
                userInfoChanged: Bool?,
                syncWithCloud: Bool?,
                agreementChanged: Bool?,
                isSynchronizeFlightDataExtended: Bool?,
                freemiumProjectCounter: Int?) {

        self.academyId = academyId
        self.firstName = firstName
        self.lastName = lastName
        self.birthday = birthday
        self.lang = lang ?? DefaultValues.langDefault
        self.email = email
        self.apcId = apcId
        self.apcToken = apcToken
        self.avatar = avatar
        self.pilotNumber = pilotNumber
        self.tmpApcUser = tmpApcUser ?? DefaultValues.tempApcUserDefault
        self.userInfoChanged = userInfoChanged ?? DefaultValues.userInfoChangedDefault
        self.syncWithCloud = syncWithCloud ?? DefaultValues.syncWithCloudDefault
        self.agreementChanged = agreementChanged ?? DefaultValues.agreementChangedDefault
        self.isSynchronizeFlightDataExtended = isSynchronizeFlightDataExtended ?? DefaultValues.shareDataOptionDefault
        self.freemiumProjectCounter = Int16(freemiumProjectCounter ?? DefaultValues.freemiumProjectCounterDefault)
    }

    public static func createAnonymous(withToken: String?) -> User {
        return User(academyId: nil,
                    firstName: nil,
                    lastName: nil,
                    birthday: nil,
                    lang: nil,
                    email: anonymousId,
                    apcId: anonymousId,
                    apcToken: withToken,
                    avatar: nil,
                    pilotNumber: nil,
                    tmpApcUser: true,
                    userInfoChanged: nil,
                    syncWithCloud: true,
                    agreementChanged: nil,
                    isSynchronizeFlightDataExtended: true,
                    freemiumProjectCounter: nil)
    }
}
