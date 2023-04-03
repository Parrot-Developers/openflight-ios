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

protocol PictorEngineBaseSessionModel: PictorEngineBaseModel {
    var sessionModel: PictorSessionModel { get }
    var userUuid: String { get set }

    // - Synchro
    // Incremental
    var incShouldLaunch: Bool { get set }

    // Multisession
    var msLatestBgDate: Date? { get set }
    var msLatestSuccessfulDate: Date? { get set }
    var msLatestTriedDate: Date? { get set }

    var msLatestFlightPlanCloudDeletionDate: Date? { get set }
    var msLatestFlightPlanDate: Date? { get set }
    var msLatestGutmaCloudDeletionDate: Date? { get set }
    var msLatestGutmaDate: Date? { get set }
    var msLatestProjectCloudDeletionDate: Date? { get set }
    var msLatestProjectDate: Date? { get set }

    // Sanity check
    var scLatestSuccessfulDate: Date? { get set }
    var scLatestTriedDate: Date? { get set }
    var scSkip: Bool { get set }
}

struct PictorEngineSessionModel: PictorEngineBaseSessionModel {
    var uuid: String { baseModel.uuid }

    // MARK: - Engine base model
    var baseModel: PictorBaseModel { sessionModel }
    var sessionModel: PictorSessionModel
    var localCreationDate: Date?
    var localModificationDate: Date?

    // MARK: - Engine session base model
    // - Synchro
    // Incremental
    var incShouldLaunch: Bool

    // Multisession
    var msLatestBgDate: Date?
    var msLatestSuccessfulDate: Date?
    var msLatestTriedDate: Date?
    var msLatestFlightPlanCloudDeletionDate: Date?
    var msLatestFlightPlanDate: Date?
    var msLatestGutmaCloudDeletionDate: Date?
    var msLatestGutmaDate: Date?
    var msLatestProjectCloudDeletionDate: Date?
    var msLatestProjectDate: Date?

    // Sanity check
    var scLatestSuccessfulDate: Date?
    var scLatestTriedDate: Date?
    var scSkip: Bool

    // RelationShip
    var userUuid: String

    // MARK: - Init
    init(sessionModel: PictorSessionModel,
         localCreationDate: Date? = nil,
         localModificationDate: Date? = nil,
         incShouldLaunch: Bool = false,
         msLatestBgDate: Date? = nil,
         msLatestSuccessfulDate: Date? = nil,
         msLatestTriedDate: Date? = nil,
         msLatestFlightPlanCloudDeletionDate: Date? = nil,
         msLatestFlightPlanDate: Date? = nil,
         msLatestGutmaCloudDeletionDate: Date? = nil,
         msLatestGutmaDate: Date? = nil,
         msLatestProjectCloudDeletionDate: Date? = nil,
         msLatestProjectDate: Date? = nil,
         scLatestSuccessfulDate: Date? = nil,
         scLatestTriedDate: Date? = nil,
         scSkip: Bool = false,
         userUuid: String) {
        self.sessionModel = sessionModel
        self.localCreationDate = localCreationDate
        self.localModificationDate = localModificationDate
        self.incShouldLaunch = incShouldLaunch
        self.msLatestBgDate = msLatestBgDate
        self.msLatestSuccessfulDate = msLatestSuccessfulDate
        self.msLatestTriedDate = msLatestTriedDate
        self.msLatestFlightPlanCloudDeletionDate = msLatestFlightPlanCloudDeletionDate
        self.msLatestFlightPlanDate = msLatestFlightPlanDate
        self.msLatestGutmaCloudDeletionDate = msLatestGutmaCloudDeletionDate
        self.msLatestGutmaDate = msLatestGutmaDate
        self.msLatestProjectCloudDeletionDate = msLatestProjectCloudDeletionDate
        self.msLatestProjectDate = msLatestProjectDate
        self.scLatestSuccessfulDate = scLatestSuccessfulDate
        self.scLatestTriedDate = scLatestTriedDate
        self.scSkip = scSkip
        self.userUuid = userUuid
    }

    init(model: PictorSessionModel, record: SessionCD) {
        self.init(sessionModel: model,
                  localCreationDate: record.localCreationDate,
                  localModificationDate: record.localModificationDate,
                  incShouldLaunch: record.incShouldLaunch,
                  msLatestBgDate: record.msLatestBgDate,
                  msLatestSuccessfulDate: record.msLatestSuccessfulDate,
                  msLatestTriedDate: record.msLatestTriedDate,
                  msLatestFlightPlanCloudDeletionDate: record.msLatestFlightPlanCloudDeletionDate,
                  msLatestFlightPlanDate: record.msLatestFlightPlanDate,
                  msLatestGutmaCloudDeletionDate: record.msLatestGutmaCloudDeletionDate,
                  msLatestGutmaDate: record.msLatestGutmaDate,
                  msLatestProjectCloudDeletionDate: record.msLatestProjectCloudDeletionDate,
                  msLatestProjectDate: record.msLatestProjectDate,
                  scLatestSuccessfulDate: record.scLatestSuccessfulDate,
                  scLatestTriedDate: record.scLatestTriedDate,
                  scSkip: record.scSkip,
                  userUuid: record.userUuid)
    }
}

extension PictorEngineSessionModel: Equatable {
    static func == (lhs: PictorEngineSessionModel, rhs: PictorEngineSessionModel) -> Bool {
        return lhs.sessionModel == rhs.sessionModel
            && lhs.localCreationDate == rhs.localCreationDate
            && lhs.localModificationDate == rhs.localModificationDate
            && lhs.userUuid == rhs.userUuid
            && lhs.incShouldLaunch == rhs.incShouldLaunch
            && lhs.msLatestBgDate == rhs.msLatestBgDate
            && lhs.msLatestSuccessfulDate == rhs.msLatestSuccessfulDate
            && lhs.msLatestTriedDate == rhs.msLatestTriedDate
            && lhs.msLatestFlightPlanCloudDeletionDate == rhs.msLatestFlightPlanCloudDeletionDate
            && lhs.msLatestFlightPlanDate == rhs.msLatestFlightPlanDate
            && lhs.msLatestGutmaCloudDeletionDate == rhs.msLatestGutmaCloudDeletionDate
            && lhs.msLatestGutmaDate == rhs.msLatestGutmaDate
            && lhs.msLatestProjectCloudDeletionDate == rhs.msLatestProjectCloudDeletionDate
            && lhs.msLatestProjectDate == rhs.msLatestProjectDate
            && lhs.scLatestSuccessfulDate == rhs.scLatestSuccessfulDate
            && lhs.scLatestTriedDate == rhs.scLatestTriedDate
            && lhs.scSkip == rhs.scSkip
    }
}
