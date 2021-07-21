// Copyright (C) 2021 Parrot Drones SAS
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

public struct FlightPlanModell {

    // MARK: - Properties

    public var uuid: String
    public var customTitle: String
    public var thumbnailUuid: String?
    public var projectUuid: String
    public var dataStringType: String
    public var version: String
    public var dataString: String?
    public var pgyProjectId: Int64
    public var mediaCustomId: String?
    public var state: String?
    public var lastMissionItemExecuted: Int64
    public var recoveryId: String?
    public var mediaCount: Int16
    public var uploadedMediaCount: Int16
    public var uploadAttemptCount: Int16
    public var lastUploadAttempt: Date?

    // MARK: - Synchro Properties

    /// - lastUpdated: Last modification date
    public var lastUpdate: Date

    /// - parrotCloudId: Id of FlightPlan on server: Set only if synchronized
    public var parrotCloudId: Int64

    /// - parrotCloudToBeDeleted: Set True if a Delete Request was triguerred without success
    public var parrotCloudToBeDeleted: Bool?

    /// - synchroDate: Contains the Date of last synchro trying if is not succeeded
    public var synchroDate: Date?

    /// - synchroStatus: Contains 0 if not yet synchronized, 1 if yes
        /// statusCode if sync failed
    public var synchroStatus: Int16?

    /// - fileSynchroStatus: Contains 0 if not yet synchronized, 1 if yes
        /// statusCode if sync failed
    public var fileSynchroStatus: Int16?

    /// - parrotCloudUploadUrl: Contains S3 Upload URL of FlightPlan
    public var parrotCloudUploadUrl: String?

    /// - cloudLastUpdate: Last modification date of FlightPlan
    public var cloudLastUpdate: Date?

    // MARK: - Relationship

    public var thumbnail: ThumbnailModel?

    public var flightPlanFlights: [FlightPlanFlightsModel]?

    // MARK: - Public init

    public init(uuid: String,
                customTitle: String,
                thumbnailUuid: String?,
                projectUuid: String,
                dataStringType: String,
                version: String,
                dataString: String?,
                pgyProjectId: Int64?,
                mediaCustomId: String?,
                state: String?,
                lastMissionItemExecuted: Int64?,
                recoveryId: String?,
                mediaCount: Int16?,
                uploadedMediaCount: Int16?,
                lastUpdate: Date,
                synchroStatus: Int16 = 0,
                fileSynchroStatus: Int16 = 0,
                synchroDate: Date? = nil,
                parrotCloudId: Int64? = 0,
                parrotCloudUploadUrl: String? = nil,
                parrotCloudToBeDeleted: Bool = false,
                cloudLastUpdate: Date? = nil,
                uploadAttemptCount: Int16? = 0,
                lastUploadAttempt: Date? = nil,
                thumbnail: ThumbnailModel?,
                flightPlanFlights: [FlightPlanFlightsModel]? = nil) {

        self.dataStringType = dataStringType
        self.uuid = uuid
        self.version = version
        self.state = state
        self.customTitle = customTitle
        self.lastUpdate = lastUpdate
        self.dataString = dataString
        self.mediaCount = mediaCount ?? 0
        self.mediaCustomId = mediaCustomId
        self.lastMissionItemExecuted = lastMissionItemExecuted ?? 0
        self.projectUuid = projectUuid
        self.thumbnailUuid = thumbnailUuid
        self.pgyProjectId = pgyProjectId ?? 0
        self.recoveryId = recoveryId
        self.uploadedMediaCount = uploadedMediaCount ?? 0
        self.parrotCloudId = parrotCloudId ?? 0
        self.parrotCloudToBeDeleted = parrotCloudToBeDeleted
        self.parrotCloudUploadUrl = parrotCloudUploadUrl
        self.synchroDate = synchroDate
        self.synchroStatus = synchroStatus
        self.fileSynchroStatus = fileSynchroStatus
        self.cloudLastUpdate = cloudLastUpdate
        self.uploadAttemptCount = uploadAttemptCount ?? 0
        self.lastUploadAttempt = lastUploadAttempt
        self.thumbnail = thumbnail
        self.flightPlanFlights = flightPlanFlights
    }
}
