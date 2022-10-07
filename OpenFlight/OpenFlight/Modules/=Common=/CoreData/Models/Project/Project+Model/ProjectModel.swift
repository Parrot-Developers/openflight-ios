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

public enum ProjectType: String {
    case classic
    case pgy

    public init?(rawString: String?) {
        guard let rawValue = rawString else { return nil }
        self.init(rawValue: rawValue)
    }
}

public struct ProjectModel {
    // MARK: __ User's ID
    public var apcId: String

    // MARK: __ Academy
    public var cloudId: Int
    public var uuid: String
    public var title: String?
    public var type: ProjectType
    public var latestCloudModificationDate: Date?
    public var latestExecutionRank: Int?

    // MARK: __ Local
    public var lastUpdated: Date
    public var lastOpened: Date?
    public var isProjectExecuted: Bool

    // MARK: __ Relationship
    public var flightPlans: [FlightPlanModel]?

    // MARK: __ Synchronization
    ///  Boolean to know if it delete locally but needs to be deleted on server
    public var isLocalDeleted: Bool
    ///  Synchro status
    public var synchroStatus: SynchroStatus?
    ///  Synchro error
    public var synchroError: SynchroError?
    ///  Date of last tried synchro
    public var latestSynchroStatusDate: Date?
    ///  Date of local modification
    public var latestLocalModificationDate: Date?

    // MARK: __ Easy access
    public var isSimpleFlightPlan: Bool {
        self.type == ProjectType.classic
    }

    public var editableFlightPlan: FlightPlanModel? {
        flightPlans?.first { $0.state == .editable }
    }

    // MARK: - Public init
    public init(apcId: String,
                cloudId: Int,
                uuid: String,
                title: String?,
                type: ProjectType,
                flightPlans: [FlightPlanModel]?,
                latestCloudModificationDate: Date?,
                lastUpdated: Date,
                lastOpened: Date?,
                latestExecutionRank: Int?,
                isLocalDeleted: Bool,
                synchroStatus: SynchroStatus?,
                synchroError: SynchroError?,
                latestSynchroStatusDate: Date?,
                latestLocalModificationDate: Date?) {
        self.apcId = apcId

        self.cloudId = cloudId
        self.uuid = uuid
        self.title = title
        self.type = type
        self.latestCloudModificationDate = latestCloudModificationDate
        self.latestExecutionRank = latestExecutionRank

        self.lastUpdated = lastUpdated

        self.lastOpened = lastOpened

        self.flightPlans = flightPlans
        self.isProjectExecuted = false

        self.isLocalDeleted = isLocalDeleted
        self.latestSynchroStatusDate = latestSynchroStatusDate
        self.synchroStatus = synchroStatus
        self.latestLocalModificationDate = latestLocalModificationDate
        self.synchroError = synchroError
    }
}

extension ProjectModel {
    public init(apcId: String, uuid: String, title: String?, type: ProjectType) {
        self.init(apcId: apcId,
                  cloudId: 0,
                  uuid: uuid,
                  title: title,
                  type: type,
                  flightPlans: nil,
                  latestCloudModificationDate: nil,
                  lastUpdated: Date(),
                  lastOpened: nil,
                  latestExecutionRank: nil,
                  isLocalDeleted: false,
                  synchroStatus: .notSync,
                  synchroError: .noError,
                  latestSynchroStatusDate: nil,
                  latestLocalModificationDate: nil)
    }

    public init(apcId: String,
                cloudId: Int,
                uuid: String,
                title: String?,
                type: ProjectType,
                latestCloudModificationDate: Date?,
                latestExecutionRank: Int?) {
        self.init(apcId: apcId,
                  cloudId: cloudId,
                  uuid: uuid,
                  title: title,
                  type: type,
                  flightPlans: nil,
                  latestCloudModificationDate: latestCloudModificationDate,
                  lastUpdated: latestCloudModificationDate ?? Date(),
                  lastOpened: nil,
                  latestExecutionRank: latestExecutionRank,
                  isLocalDeleted: false,
                  synchroStatus: .synced,
                  synchroError: .noError,
                  latestSynchroStatusDate: Date(),
                  latestLocalModificationDate: nil)
    }

    public init(duplicateProject project: ProjectModel, withApcId: String, uuid: String, title: String?) {
        self.init(apcId: withApcId,
                  cloudId: 0,
                  uuid: uuid,
                  title: title,
                  type: project.type,
                  flightPlans: nil,
                  latestCloudModificationDate: Date(),
                  lastUpdated: Date(),
                  lastOpened: nil,
                  latestExecutionRank: nil,
                  isLocalDeleted: project.isLocalDeleted,
                  synchroStatus: .notSync,
                  synchroError: .noError,
                  latestSynchroStatusDate: nil,
                  latestLocalModificationDate: nil)
    }
}
