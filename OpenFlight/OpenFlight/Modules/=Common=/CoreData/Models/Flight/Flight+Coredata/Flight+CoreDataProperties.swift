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
import CoreData

extension Flight {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Flight> {
        return NSFetchRequest<Flight>(entityName: "Flight")
    }

    // MARK: - Properties

    @NSManaged public var apcId: String!
    @NSManaged public var title: String?
    @NSManaged public var uuid: String!
    @NSManaged public var version: String!
    @NSManaged public var videoCount: Int16
    @NSManaged public var photoCount: Int16
    @NSManaged public var batteryConsumption: Int16
    @NSManaged public var distance: Double
    @NSManaged public var duration: Double
    @NSManaged public var gutmaFile: Data!
    @NSManaged public var startLatitude: Double
    @NSManaged public var startLongitude: Double
    @NSManaged public var startTime: Date?
    @NSManaged public var parrotCloudId: Int64
    @NSManaged public var parrotCloudToBeDeleted: Bool
    @NSManaged public var parrotCloudUploadUrl: String?
    @NSManaged public var synchroDate: Date?
    @NSManaged public var synchroStatus: Int16
    @NSManaged public var fileSynchroStatus: Int16
    @NSManaged public var fileSynchroDate: Date?
    @NSManaged public var cloudLastUpdate: Date?
    @NSManaged public var externalSynchroStatus: Int16
    @NSManaged public var externalSynchroDate: Date?

    // MARK: - Relationship

    @NSManaged public var ofUserParrot: UserParrot?
    @NSManaged public var thumbnail: Thumbnail?
    @NSManaged public var flightPlanFlights: Set<FlightPlanFlights>?

}

// MARK: Generated accessors for flightPlanFlights
extension Flight {

    @objc(addFlightPlanFlightsObject:)
    @NSManaged public func addToFlightPlanFlights(_ value: FlightPlanFlights)

    @objc(removeFlightPlanFlightsObject:)
    @NSManaged public func removeFlightPlanFlights(_ value: FlightPlanFlights)

    @objc(addFlightPlanFlights:)
    @NSManaged public func addToFlightPlanFlights(_ values: NSSet)

    @objc(removeFlightPlanFlights:)
    @NSManaged public func removeFromFlightPlanFlights(_ values: NSSet)

}

// MARK: - Utils
extension Flight {

    /// Return FlightModel from Flight type of NSManagedObject
    func model() -> FlightModel {
        return FlightModel(apcId: apcId,
                           title: title,
                           uuid: uuid,
                           version: version,
                           photoCount: photoCount,
                           videoCount: videoCount,
                           startLatitude: startLatitude,
                           startLongitude: startLongitude,
                           startTime: startTime,
                           batteryConsumption: batteryConsumption,
                           distance: distance,
                           duration: duration,
                           gutmaFile: String(decoding: gutmaFile, as: UTF8.self),
                           parrotCloudId: parrotCloudId,
                           parrotCloudToBeDeleted: parrotCloudToBeDeleted,
                           parrotCloudUploadUrl: parrotCloudUploadUrl,
                           synchroDate: synchroDate,
                           synchroStatus: synchroStatus,
                           cloudLastUpdate: cloudLastUpdate,
                           fileSynchroStatus: fileSynchroStatus,
                           fileSynchroDate: fileSynchroDate,
                           externalSynchroStatus: externalSynchroStatus,
                           externalSynchroDate: externalSynchroDate)
    }
}
