//    Copyright (C) 2023 Parrot Drones SAS
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

struct OldFlightModel: OldModel {
    var _uuid: String { uuid }
    var _userUuid: String { apcId }

    var apcId: String!
    var title: String?
    var uuid: String!
    var version: String!
    var videoCount: Int16
    var photoCount: Int16
    var batteryConsumption: Int16
    var distance: Double
    var duration: Double
    var gutmaFile: Data!
    var startLatitude: Double
    var startLongitude: Double
    var startTime: Date?
    var cloudId: Int64
    var isLocalDeleted: Bool
    var parrotCloudUploadUrl: String?
    var latestSynchroStatusDate: Date?
    var synchroStatus: Int16
    var fileSynchroStatus: Int16
    var fileSynchroDate: Date?
    var latestCloudModificationDate: Date?
    var latestLocalModificationDate: Date?
    var synchroError: Int16
}

@objc(Flight)
class Flight: OldManagedObject {
    override var _uuid: String { uuid }
    override var _userUuid: String { apcId }

    func toModel() -> OldFlightModel {
        OldFlightModel(apcId: apcId,
                       title: title,
                       uuid: uuid,
                       version: version,
                       videoCount: videoCount,
                       photoCount: photoCount,
                       batteryConsumption: batteryConsumption,
                       distance: distance,
                       duration: duration,
                       gutmaFile: gutmaFile,
                       startLatitude: startLatitude,
                       startLongitude: startLongitude,
                       startTime: startTime,
                       cloudId: cloudId,
                       isLocalDeleted: isLocalDeleted,
                       parrotCloudUploadUrl: parrotCloudUploadUrl,
                       latestSynchroStatusDate: latestSynchroStatusDate,
                       synchroStatus: synchroStatus,
                       fileSynchroStatus: fileSynchroStatus,
                       fileSynchroDate: fileSynchroDate,
                       latestCloudModificationDate: latestCloudModificationDate,
                       latestLocalModificationDate: latestLocalModificationDate,
                       synchroError: synchroError)
    }
}

extension Flight {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Flight> {
        return NSFetchRequest<Flight>(entityName: Self.entityName)
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
    @NSManaged public var cloudId: Int64
    @NSManaged public var isLocalDeleted: Bool
    @NSManaged public var parrotCloudUploadUrl: String?
    @NSManaged public var latestSynchroStatusDate: Date?
    @NSManaged public var synchroStatus: Int16
    @NSManaged public var fileSynchroStatus: Int16
    @NSManaged public var fileSynchroDate: Date?
    @NSManaged public var latestCloudModificationDate: Date?
    @NSManaged public var latestLocalModificationDate: Date?
    @NSManaged public var synchroError: Int16

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