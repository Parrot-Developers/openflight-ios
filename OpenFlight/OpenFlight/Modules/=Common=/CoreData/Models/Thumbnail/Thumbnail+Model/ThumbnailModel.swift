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

public struct ThumbnailModel {

    // MARK: - Properties

    public var uuid: String
    public var thumbnailImage: UIImage?

    // MARK: - Synchro Properties

    /// - parrotCloudId: Id of project on server: Set only if synchronized
    public var parrotCloudId: Int64

    /// - synchroDate: Contains the Date of last synchro trying if is not succeeded
    public var synchroDate: Date?

    /// - synchroStatus: Contains 0 if not yet synchronized, 1 if yes
        /// statusCode if sync failed
    public var synchroStatus: Int16?

    /// - fileSynchroStatus: Contains 0 if not yet synchronized, 1 if yes
        /// statusCode if sync failed
    public var fileSynchroStatus: Int16?

    /// - cloudLastUpdate: remote last modification date of Thumbnail File
    public var cloudLastUpdate: Date?

    /// - parrotCloudToBeDeleted: Set True if a Delete Request was triguerred without success
    public var parrotCloudToBeDeleted: Bool?

    public var thumbnailImageData: Data? {
        return thumbnailImage?.pngData()
    }

    // MARK: - Relationship

    //public var ofFlightPlan: FlightPlanModell?

    // MARK: - Public init

    public init(uuid: String,
                thumbnailImage: UIImage?,
                synchroStatus: Int16 = 0,
                fileSynchroStatus: Int16 = 0,
                cloudLastUpdate: Date? = nil,
                synchroDate: Date? = nil,
                parrotCloudId: Int64 = 0,
                parrotCloudToBeDeleted: Bool = false) {

        self.uuid = uuid
        self.thumbnailImage = thumbnailImage
        self.synchroStatus = synchroStatus
        self.fileSynchroStatus = fileSynchroStatus
        self.cloudLastUpdate = cloudLastUpdate
        self.synchroDate = synchroDate
        self.parrotCloudId = parrotCloudId
        self.parrotCloudToBeDeleted = parrotCloudToBeDeleted
    }
}
