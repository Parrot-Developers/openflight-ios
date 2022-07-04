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

public struct ThumbnailModel {
    // MARK: __ User's ID
    public var apcId: String
    // MARK: __ Academy
    public var cloudId: Int
    public var uuid: String
    public var latestCloudModificationDate: Date?
    // MARK: __ Local
    public var lastUpdate: Date?
    /// Uuid of the flight associated with this thumbnail if any
    public var flightUuid: String?
    public var thumbnailImage: UIImage?
    /// - Return Thumbnail data type
    public var thumbnailImageData: Data? {
        return thumbnailImage?.pngData()
    }
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
    /// - Contains:
    ///     - 0 Not yet synchronized
    ///     - 1 Synchronized
    ///     - 2 Upload Url is taped
    ///     - StatusCode if sync failed
    public var fileSynchroStatus: Int16?
    /// - Date of synchro file
    public var fileSynchroDate: Date?

    // MARK: - Public init
    public init(apcId: String,
                cloudId: Int,
                uuid: String,
                latestCloudModificationDate: Date?,
                lastUpdate: Date?,
                flightUuid: String?,
                thumbnailImage: UIImage?,
                isLocalDeleted: Bool,
                synchroStatus: SynchroStatus?,
                synchroError: SynchroError?,
                latestSynchroStatusDate: Date?,
                latestLocalModificationDate: Date?,
                fileSynchroStatus: Int16?,
                fileSynchroDate: Date?) {
        /// User's ID
        self.apcId = apcId
        /// Academy
        self.cloudId = cloudId
        self.uuid = uuid
        self.latestCloudModificationDate = latestCloudModificationDate
        /// Local
        self.lastUpdate = lastUpdate
        self.flightUuid = flightUuid
        self.thumbnailImage = thumbnailImage
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

extension ThumbnailModel {
    public init(apcId: String,
                cloudId: Int,
                uuid: String,
                latestCloudModificationDate: Date?,
                thumbnailImage: UIImage?) {
        self.init(apcId: apcId,
                  cloudId: cloudId,
                  uuid: uuid,
                  latestCloudModificationDate: latestCloudModificationDate,
                  lastUpdate: latestCloudModificationDate,
                  flightUuid: nil,
                  thumbnailImage: thumbnailImage,
                  isLocalDeleted: false,
                  synchroStatus: .notSync,
                  synchroError: .noError,
                  latestSynchroStatusDate: nil,
                  latestLocalModificationDate: nil,
                  fileSynchroStatus: 0,
                  fileSynchroDate: nil)
    }

    public init(apcId: String,
                uuid: String,
                flightUuid: String?,
                thumbnailImage: UIImage?) {
        self.init(apcId: apcId,
                  cloudId: 0,
                  uuid: uuid,
                  latestCloudModificationDate: nil,
                  lastUpdate: Date(),
                  flightUuid: flightUuid,
                  thumbnailImage: thumbnailImage,
                  isLocalDeleted: false,
                  synchroStatus: .notSync,
                  synchroError: .noError,
                  latestSynchroStatusDate: nil,
                  latestLocalModificationDate: nil,
                  fileSynchroStatus: 0,
                  fileSynchroDate: nil)
    }
}

/// Extension for Equatable conformance.
extension ThumbnailModel: Equatable {
    public static func == (lhs: ThumbnailModel, rhs: ThumbnailModel) -> Bool {
        lhs.apcId == rhs.apcId
        && lhs.cloudId == rhs.cloudId
        && lhs.uuid == rhs.uuid
        && lhs.latestCloudModificationDate == rhs.latestCloudModificationDate
        && lhs.lastUpdate == rhs.lastUpdate
        && lhs.flightUuid == rhs.flightUuid
        && lhs.thumbnailImage == rhs.thumbnailImage
        && lhs.isLocalDeleted == rhs.isLocalDeleted
        && lhs.synchroStatus == rhs.synchroStatus
        && lhs.synchroError == rhs.synchroError
        && lhs.latestSynchroStatusDate == rhs.latestSynchroStatusDate
        && lhs.latestLocalModificationDate == rhs.latestLocalModificationDate
        && lhs.fileSynchroStatus == rhs.fileSynchroStatus
        && lhs.fileSynchroDate == rhs.fileSynchroDate
    }
}
