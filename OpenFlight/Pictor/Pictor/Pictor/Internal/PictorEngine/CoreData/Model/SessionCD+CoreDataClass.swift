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

@objc(SessionCD)
class SessionCD: PictorEngineManagedObject {
    override internal var _uuid: String { uuid }

    override func update(_ model: PictorBaseModel) {
        if let model = model as? PictorBaseSessionModel {
            updateBaseModel(model)
        } else if let model = model as? PictorEngineBaseSessionModel {
            updateEngineModel(model)
        }
    }
}

private extension SessionCD {

    func updateBaseModel(_ model: PictorBaseSessionModel) {
        uuid = model.uuid

        pix4dEmail = model.pix4dEmail
        pix4dAccessToken = model.pix4dAccessToken
        pix4dRefreshToken = model.pix4dRefreshToken
        pix4dPremiumTokenExpirationDate = model.pix4dPremiumTokenExpirationDate
        pix4dPremiumAccountScopes = model.pix4dPremiumAccountScopes
        pix4dPremiumAccountTokenType = model.pix4dPremiumAccountTokenType
        pix4dPremiumProjectsCountLastSyncDate = model.pix4dPremiumProjectsCountLastSyncDate
        pix4dFreemiumProjectsCountLastSyncDate = model.pix4dFreemiumProjectsCountLastSyncDate
        permanentRemainingPix4dProjects = Int16(model.permanentRemainingPix4dProjects)
        temporaryRemainingPix4dProjects = Int16(model.temporaryRemainingPix4dProjects)
    }

    func updateEngineModel(_ model: PictorEngineBaseSessionModel) {
        // - Base model
        updateBaseModel(model.sessionModel)
        localCreationDate = model.localCreationDate
        localModificationDate = model.localModificationDate

        // - Synchro
        // Incremental
        incShouldLaunch = model.incShouldLaunch

        // Multisession
        msLatestBgDate = model.msLatestBgDate
        msLatestSuccessfulDate = model.msLatestSuccessfulDate
        msLatestTriedDate = model.msLatestTriedDate
        msLatestFlightPlanCloudDeletionDate = model.msLatestFlightPlanCloudDeletionDate
        msLatestFlightPlanDate = model.msLatestFlightPlanDate
        msLatestGutmaCloudDeletionDate = model.msLatestGutmaCloudDeletionDate
        msLatestGutmaDate = model.msLatestGutmaDate
        msLatestProjectCloudDeletionDate = model.msLatestProjectCloudDeletionDate
        msLatestProjectDate = model.msLatestProjectDate

        // Sanity check
        scLatestSuccessfulDate = model.scLatestSuccessfulDate
        scLatestTriedDate = model.scLatestTriedDate
        scSkip = model.scSkip

        // User
        userUuid = model.userUuid
    }
}
