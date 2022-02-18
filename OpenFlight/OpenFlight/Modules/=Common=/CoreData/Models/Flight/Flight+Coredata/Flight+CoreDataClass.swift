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

@objc(Flight)
public class Flight: NSManagedObject {
    // MARK: - Utils
    /// Return FlightModel from Flight
    public func model() -> FlightModel {
        return FlightModel(apcId: apcId,
                           cloudId: Int(cloudId),
                           uuid: uuid,
                           title: title,
                           version: version,
                           startTime: startTime,
                           latestCloudModificationDate: latestCloudModificationDate,
                           photoCount: photoCount,
                           videoCount: videoCount,
                           startLatitude: startLatitude,
                           startLongitude: startLongitude,
                           batteryConsumption: batteryConsumption,
                           distance: distance,
                           duration: duration,
                           gutmaFile: gutmaFile,
                           parrotCloudUploadUrl: parrotCloudUploadUrl,
                           isLocalDeleted: isLocalDeleted,
                           synchroStatus: SynchroStatus(status: synchroStatus),
                           synchroError: SynchroError(error: synchroError),
                           latestSynchroStatusDate: latestSynchroStatusDate,
                           latestLocalModificationDate: latestLocalModificationDate,
                           fileSynchroStatus: fileSynchroStatus,
                           fileSynchroDate: fileSynchroDate,
                           externalSynchroStatus: externalSynchroStatus,
                           externalSynchroDate: externalSynchroDate)
    }

    /// Update from flightModel
    /// - Parameters
    ///     - flightModel: specified FlightModel
    ///     - byUserUpdate: Boolean to know if it is updated by user interaction
    public func update(fromFlightModel flightModel: FlightModel) {
        apcId = flightModel.apcId
        title = flightModel.title
        uuid = flightModel.uuid
        version = flightModel.version
        photoCount = flightModel.photoCount
        videoCount = flightModel.videoCount
        startLatitude = flightModel.startLatitude
        startLongitude = flightModel.startLongitude
        startTime = flightModel.startTime
        batteryConsumption = flightModel.batteryConsumption
        distance = flightModel.distance
        duration = flightModel.duration
        gutmaFile = flightModel.gutmaFile
        cloudId = Int64(flightModel.cloudId)
        isLocalDeleted = flightModel.isLocalDeleted
        parrotCloudUploadUrl = flightModel.parrotCloudUploadUrl
        latestSynchroStatusDate = flightModel.latestSynchroStatusDate
        latestCloudModificationDate = flightModel.latestCloudModificationDate
        latestLocalModificationDate = flightModel.latestLocalModificationDate
        synchroStatus = flightModel.synchroStatus?.rawValue ?? 0
        synchroError = flightModel.synchroError?.rawValue ?? 0
        fileSynchroDate = flightModel.fileSynchroDate
        fileSynchroStatus = flightModel.fileSynchroStatus ?? 0
        externalSynchroDate = flightModel.externalSynchroDate
        externalSynchroStatus = flightModel.externalSynchroStatus ?? 0
    }
}
