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
import CoreData

extension SessionCD {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SessionCD> {
        return NSFetchRequest<SessionCD>(entityName: "SessionCD")
    }

    @NSManaged public var uuid: String
    @NSManaged public var userUuid: String
    @NSManaged public var localCreationDate: Date?
    @NSManaged public var localModificationDate: Date?

    // - Pix4d
    @NSManaged public var pix4dEmail: String
    @NSManaged public var pix4dAccessToken: String?
    @NSManaged public var pix4dRefreshToken: String?
    @NSManaged public var pix4dPremiumTokenExpirationDate: Date?
    @NSManaged public var pix4dPremiumAccountScopes: String?
    @NSManaged public var pix4dPremiumAccountTokenType: String?
    @NSManaged public var pix4dPremiumProjectsCountLastSyncDate: Date?
    @NSManaged public var pix4dFreemiumProjectsCountLastSyncDate: Date?
    @NSManaged public var permanentRemainingPix4dProjects: Int16
    @NSManaged public var temporaryRemainingPix4dProjects: Int16

    // - Synchro
    // Incremental
    @NSManaged public var incShouldLaunch: Bool

    // Multisession
    @NSManaged public var msLatestBgDate: Date?
    @NSManaged public var msLatestSuccessfulDate: Date?
    @NSManaged public var msLatestTriedDate: Date?

    @NSManaged public var msLatestFlightPlanCloudDeletionDate: Date?
    @NSManaged public var msLatestFlightPlanDate: Date?
    @NSManaged public var msLatestGutmaCloudDeletionDate: Date?
    @NSManaged public var msLatestGutmaDate: Date?
    @NSManaged public var msLatestProjectCloudDeletionDate: Date?
    @NSManaged public var msLatestProjectDate: Date?

    // Sanity check
    @NSManaged public var scLatestSuccessfulDate: Date?
    @NSManaged public var scLatestTriedDate: Date?
    @NSManaged public var scSkip: Bool
}

extension SessionCD : Identifiable {

}
