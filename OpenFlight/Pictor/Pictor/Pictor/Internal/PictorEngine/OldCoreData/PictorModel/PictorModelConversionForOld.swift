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

extension UserCD {
    func update(from oldModel: OldUserModel) {
        uuid = oldModel.apcId

        // - Information
        apcId = oldModel.apcId
        academyId = oldModel.academyId ?? ""
        email = oldModel.email
        firstName = oldModel.firstName ?? ""
        lastName = oldModel.lastName ?? ""
        isPrivateMode = NSNumber.from(boolValue: !oldModel.isSynchronizeFlightDataExtended)

        // - Account
        apcToken = oldModel.apcToken
        confirmed = true

        // - Optional
        // Info
        pilotNumber = NSNumber.from(intValue: Int(oldModel.pilotNumber ?? ""))
        gender = nil
        phone = nil
        country = nil
        language = nil
        company = nil
        vatNumber = nil
        registrationNumber = nil
        subIndustry = nil
        industry = nil
        store = nil
        isCaligoffEnabled = oldModel.isCaligoffEnabled

        nbFreemiumProjects = Int16(oldModel.freemiumProjectCounter)

        // - Local avatar image
        isAgreementChanged = oldModel.agreementChanged
        avatarImageData = nil

        // - Engine
        localCreationDate = Date()
        localModificationDate = nil

        // - Synchro properties
        synchroStatus = oldModel.synchroStatus
        synchroError = oldModel.synchroError
        synchroLatestUpdatedDate = oldModel.latestLocalModificationDate
        synchroLatestStatusDate = oldModel.latestSynchroStatusDate
        synchroIsDeleted = oldModel.isLocalDeleted
    }
}

extension DroneCD {
    func update(from oldModel: OldDroneModel) {
        // - Base model
        uuid = oldModel.droneSerial

        cloudId = Int64(oldModel.droneSerial) ?? 0
        serialNumber = oldModel.droneSerial
        commonName = oldModel.droneCommonName
        modelId = oldModel.modelId
        paired4G = oldModel.pairedFor4G

        // - Engine
        localCreationDate = Date()
        localModificationDate = nil

        // - Synchro properties
        synchroStatus = oldModel.synchroStatus
        synchroError = PictorEngineSynchroError.noError.rawValue
        synchroLatestUpdatedDate = oldModel.synchroDate
        synchroLatestStatusDate = nil
        synchroIsDeleted = false

        // - User UUID
        userUuid = oldModel.apcId
    }
}

extension FlightCD {
    func update(from oldModel: OldModel) {
        guard let oldModel = oldModel as? OldFlightModel else { return }
        // - User UUID
        userUuid = oldModel._userUuid
        // - Base model
        uuid = oldModel.uuid

        cloudId = Int64(oldModel.cloudId)
        formatVersion = oldModel.version
        title = oldModel.title
        parseError = false
        runDate = oldModel.startTime
        serial = ""
        firmware = ""
        modelId = ""
        gutmaFile = oldModel.gutmaFile
        photoCount = oldModel.photoCount
        videoCount = oldModel.videoCount
        let isUnknownCoordinate = (oldModel.startLatitude == 0 && oldModel.startLongitude == 0)
        startLatitude = isUnknownCoordinate ? GutmaConstants.unknownCoordinate : oldModel.startLatitude
        startLongitude = isUnknownCoordinate ? GutmaConstants.unknownCoordinate : oldModel.startLongitude
        batteryConsumption = oldModel.batteryConsumption
        distance = oldModel.distance
        duration = oldModel.duration

        thumbnailUuid = nil

        // - Engine
        localCreationDate = Date()
        localModificationDate = nil

        // - Engine base model
        cloudCreationDate = nil
        cloudModificationDate = oldModel.latestCloudModificationDate

        // - Synchro properties
        synchroStatus = oldModel.synchroStatus
        synchroError = oldModel.synchroError
        synchroLatestUpdatedDate = oldModel.latestLocalModificationDate
        synchroLatestStatusDate = oldModel.latestSynchroStatusDate
        synchroIsDeleted = oldModel.isLocalDeleted
    }
}

extension ProjectCD {
    func update(from oldModel: OldProjectModel) {
        // - Base model
        uuid = oldModel.uuid

        cloudId = Int64(oldModel.cloudId)
        title = oldModel.title ?? ""
        type = oldModel.type
        latestExecutionIndex = oldModel.latestExecutionRank
        lastUpdated = oldModel.lastUpdated
        lastOpened = oldModel.lastOpened

        // - Engine
        localCreationDate = Date()
        localModificationDate = nil

        // - Engine base model
        cloudCreationDate = nil
        cloudModificationDate = oldModel.latestCloudModificationDate

        // - Synchro properties
        synchroStatus = oldModel.synchroStatus
        synchroError = oldModel.synchroError
        synchroLatestUpdatedDate = oldModel.latestLocalModificationDate
        synchroLatestStatusDate = oldModel.latestSynchroStatusDate
        synchroIsDeleted = oldModel.isLocalDeleted

        // - User UUID
        userUuid = oldModel.apcId
    }
}

extension ProjectPix4dCD {
    func update(from oldModel: OldProjectPix4dModel) {
        // - Base model
        uuid = "\(oldModel.pgyProjectId)"

        cloudId = oldModel.pgyProjectId
        title = oldModel.name
        projectDate = oldModel.projectDate
        processingCalled = oldModel.processingCalled

        // - Engine
        localCreationDate = Date()
        localModificationDate = nil

        // - Synchro properties
        synchroStatus = oldModel.synchroStatus
        synchroError = oldModel.synchroError
        synchroLatestUpdatedDate = oldModel.latestLocalModificationDate
        synchroLatestStatusDate = oldModel.latestSynchroStatusDate
        synchroIsDeleted = oldModel.isLocalDeleted

        // - User UUID
        userUuid = oldModel.apcId
    }
}

extension FlightPlanCD {
    func update(from oldModel: OldFlightPlanModel) {
        // - Base model
        uuid = oldModel.uuid

        cloudId = Int64(oldModel.cloudId)
        name = oldModel.customTitle
        state = oldModel.state
        fileType = oldModel.dataStringType
        flightPlanType = oldModel.type
        mediaCount = Int64(oldModel.mediaCount)
        uploadedMediaCount = Int64(oldModel.uploadedMediaCount)
        lastMissionItemExecuted = Int64(oldModel.lastMissionItemExecuted)
        formatVersion = oldModel.version
        dataSetting = oldModel.dataString
        projectUuid = oldModel.projectUuid
        projectPix4dUuid = "\(oldModel.pgyProjectId)"
        thumbnailUuid = nil

        lastUpdated = oldModel.lastUpdate
        executionRank = oldModel.executionRank
        hasReachedFirstWaypoint = NSNumber.from(boolValue: oldModel.hasReachedFirstWayPoint)

        // - Engine
        localCreationDate = Date()
        localModificationDate = nil

        // - Engine base model
        cloudModificationDate = oldModel.latestCloudModificationDate

        // - Synchro properties
        synchroStatus = oldModel.synchroStatus
        synchroError = oldModel.synchroError
        synchroLatestUpdatedDate = oldModel.latestLocalModificationDate
        synchroLatestStatusDate = oldModel.latestSynchroStatusDate
        synchroIsDeleted = oldModel.isLocalDeleted

        // - User UUID
        userUuid = oldModel.apcId
    }
}

extension GutmaLinkCD {
    func update(from oldModel: OldGutmaLinkModel) {
        // - Base model
        uuid = UUID().uuidString

        flightUuid = oldModel.flightUuid
        flightPlanUuid = oldModel.flightplanUuid
        cloudId = Int64(oldModel.cloudId)
        executionDate = oldModel.dateExecutionFlight

        // - Engine
        localCreationDate = Date()
        localModificationDate = nil

        // - Synchro properties
        synchroStatus = oldModel.synchroStatus
        synchroError = oldModel.synchroError
        synchroLatestUpdatedDate = oldModel.latestLocalModificationDate
        synchroLatestStatusDate = oldModel.latestSynchroStatusDate
        synchroIsDeleted = oldModel.isLocalDeleted

        // - User UUID
        userUuid = oldModel.apcId
    }
}
