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

@objc(Thumbnail)
public class Thumbnail: NSManagedObject {
    // MARK: - Utils
    func model() -> ThumbnailModel {
        /// Load UIImage from Data if exist
        var thumbnailImage: UIImage?
        if let thumbnailData = thumbnailData {
            thumbnailImage = UIImage(data: thumbnailData)
        }
        return ThumbnailModel(apcId: apcId,
                              cloudId: Int(cloudId),
                              uuid: uuid,
                              latestCloudModificationDate: latestCloudModificationDate,
                              lastUpdate: latestCloudModificationDate,
                              flightUuid: ofFlight?.uuid,
                              thumbnailImage: thumbnailImage,
                              isLocalDeleted: isLocalDeleted,
                              synchroStatus: SynchroStatus(status: synchroStatus),
                              synchroError: .noError,
                              latestSynchroStatusDate: latestSynchroStatusDate,
                              latestLocalModificationDate: latestLocalModificationDate,
                              fileSynchroStatus: 0,
                              fileSynchroDate: nil)
    }

    func update(fromThumbnailModel thumbnailModel: ThumbnailModel, withFlight: Flight?) {
        apcId = thumbnailModel.apcId
        uuid = thumbnailModel.uuid
        thumbnailData = thumbnailModel.thumbnailImageData
        lastUpdate = thumbnailModel.lastUpdate
        latestSynchroStatusDate = thumbnailModel.latestSynchroStatusDate
        fileSynchroDate = thumbnailModel.fileSynchroDate
        latestCloudModificationDate = thumbnailModel.latestCloudModificationDate
        cloudId = thumbnailModel.cloudId > 0 ? Int64(thumbnailModel.cloudId) : cloudId
        isLocalDeleted = thumbnailModel.isLocalDeleted
        latestLocalModificationDate = thumbnailModel.latestLocalModificationDate
        synchroStatus = thumbnailModel.synchroStatus?.rawValue ?? 0
        synchroError = thumbnailModel.synchroError?.rawValue ?? 0
        fileSynchroStatus = thumbnailModel.fileSynchroStatus ?? 0

        if let flight = withFlight {
            ofFlight = flight
        }
    }
}
