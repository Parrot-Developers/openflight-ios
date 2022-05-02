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
import CoreData

@objc(UserParrot)
public class UserParrot: NSManagedObject {
    // MARK: - Utils
    func model() -> User {
        return User(academyId: academyId,
                    firstName: firstName,
                    lastName: lastName,
                    birthday: birthday,
                    lang: lang,
                    email: email,
                    apcId: apcId,
                    apcToken: apcToken,
                    avatar: avatar,
                    latestCloudAvatarModificationDate: latestCloudAvatarModificationDate,
                    pilotNumber: pilotNumber,
                    tmpApcUser: tmpApcUser,
                    userInfoChanged: userInfoChanged,
                    syncWithCloud: syncWithCloud,
                    agreementChanged: agreementChanged,
                    isSynchronizeFlightDataExtended: isSynchronizeFlightDataExtended,
                    freemiumProjectCounter: Int(freemiumProjectCounter))
    }

    func update(fromUser user: User) {
        academyId = user.academyId
        firstName = user.firstName
        lastName = user.lastName
        birthday = user.birthday
        lang = user.lang
        email = user.email
        apcId = user.apcId
        apcToken = user.apcToken
        avatar = user.avatar
        latestCloudAvatarModificationDate = user.latestCloudAvatarModificationDate
        tmpApcUser = user.tmpApcUser
        userInfoChanged = user.userInfoChanged
        syncWithCloud = user.syncWithCloud
        agreementChanged = user.agreementChanged
        isSynchronizeFlightDataExtended = user.isSynchronizeFlightDataExtended
        freemiumProjectCounter = user.freemiumProjectCounter
        pilotNumber = user.pilotNumber
        // synchronization
        isLocalDeleted = user.isLocalDeleted
        latestSynchroStatusDate = user.latestSynchroStatusDate
        latestCloudModificationDate = user.latestCloudModificationDate
        latestLocalModificationDate = user.latestLocalModificationDate
        synchroStatus = user.synchroStatus?.rawValue ?? 0
        synchroError = user.synchroError?.rawValue ?? 0
    }
}
