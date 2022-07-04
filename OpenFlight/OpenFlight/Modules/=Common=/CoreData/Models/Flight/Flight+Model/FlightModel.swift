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

public struct FlightModel {
    // MARK: __ User's ID
    public var apcId: String

    // MARK: __ Academy
    ///  Academy ID
    public var cloudId: Int
    ///  Local generated ID
    public var uuid: String
    public var title: String?
    public var version: String
    public var startTime: Date?
    public var latestCloudModificationDate: Date?

    // MARK: __ Local
    public var photoCount: Int16
    public var videoCount: Int16
    public var startLatitude: Double
    public var startLongitude: Double
    public var batteryConsumption: Int16
    public var distance: Double
    public var duration: Double
    public var gutmaFile: Data?
    public var thumbnail: ThumbnailModel?
    ///  Url to upload Gutma File
    public var parrotCloudUploadUrl: String?

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
    ///  fileSynchroStatus contains:
    ///     0 Not yet synchronized
    ///     1 Synchronized
    ///     2 Upload Url is taped
    ///     StatusCode if sync failed
    public var fileSynchroStatus: Int16?
    ///  fileSynchroDate: Date of synchro file
    public var fileSynchroDate: Date?

    // MARK: - Public init
    public init(apcId: String,
                cloudId: Int,
                uuid: String,
                title: String?,
                version: String,
                startTime: Date?,
                latestCloudModificationDate: Date?,
                photoCount: Int16,
                videoCount: Int16,
                startLatitude: Double,
                startLongitude: Double,
                batteryConsumption: Int16,
                distance: Double,
                duration: Double,
                gutmaFile: Data?,
                thumbnail: ThumbnailModel?,
                parrotCloudUploadUrl: String?,
                isLocalDeleted: Bool,
                synchroStatus: SynchroStatus?,
                synchroError: SynchroError?,
                latestSynchroStatusDate: Date?,
                latestLocalModificationDate: Date?,
                fileSynchroStatus: Int16?,
                fileSynchroDate: Date?) {
        /// User's Id
        self.apcId = apcId
        /// Academy
        self.cloudId = cloudId
        self.uuid = uuid
        self.title = title
        self.version = version
        self.photoCount = photoCount
        self.videoCount = videoCount
        self.latestCloudModificationDate = latestCloudModificationDate
        /// Local
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        self.startTime = startTime
        self.batteryConsumption = batteryConsumption
        self.distance = distance
        self.duration = duration
        self.gutmaFile = gutmaFile
        self.parrotCloudUploadUrl = parrotCloudUploadUrl
        self.thumbnail = thumbnail
        /// Synchronization
        self.isLocalDeleted = isLocalDeleted
        self.synchroStatus = synchroStatus
        self.synchroError = synchroError
        self.latestSynchroStatusDate = latestSynchroStatusDate
        self.latestLocalModificationDate = latestLocalModificationDate
        self.fileSynchroStatus = fileSynchroStatus
        self.fileSynchroDate = fileSynchroDate
    }
}

extension FlightModel {
    public init(apcId: String,
                cloudId: Int,
                uuid: String,
                title: String?,
                version: String,
                startTime: Date?,
                latestCloudModificationDate: Date?) {
        self.init(apcId: apcId,
                  cloudId: cloudId,
                  uuid: uuid,
                  title: title,
                  version: version,
                  startTime: startTime,
                  latestCloudModificationDate: latestCloudModificationDate,
                  photoCount: 0,
                  videoCount: 0,
                  startLatitude: 0,
                  startLongitude: 0,
                  batteryConsumption: 0,
                  distance: 0,
                  duration: 0,
                  gutmaFile: nil,
                  thumbnail: nil,
                  parrotCloudUploadUrl: nil,
                  isLocalDeleted: false,
                  synchroStatus: nil,
                  synchroError: nil,
                  latestSynchroStatusDate: nil,
                  latestLocalModificationDate: nil,
                  fileSynchroStatus: nil,
                  fileSynchroDate: nil)
    }

    public init(apcId: String,
                uuid: String,
                version: String,
                startTime: Date?,
                photoCount: Int16,
                videoCount: Int16,
                startLatitude: Double,
                startLongitude: Double,
                batteryConsumption: Int16,
                distance: Double,
                duration: Double,
                gutmaFile: Data?) {
        self.init(apcId: apcId,
                  cloudId: 0,
                  uuid: uuid,
                  title: nil,
                  version: version,
                  startTime: startTime,
                  latestCloudModificationDate: nil,
                  photoCount: photoCount,
                  videoCount: videoCount,
                  startLatitude: startLatitude,
                  startLongitude: startLongitude,
                  batteryConsumption: batteryConsumption,
                  distance: distance,
                  duration: duration,
                  gutmaFile: gutmaFile,
                  thumbnail: nil,
                  parrotCloudUploadUrl: nil,
                  isLocalDeleted: false,
                  synchroStatus: nil,
                  synchroError: nil,
                  latestSynchroStatusDate: nil,
                  latestLocalModificationDate: nil,
                  fileSynchroStatus: nil,
                  fileSynchroDate: nil)
    }
}
