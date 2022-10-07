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

extension FlightPlan {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FlightPlan> {
        return NSFetchRequest<FlightPlan>(entityName: Self.entityName)
    }

    // MARK: Properties

    @NSManaged public var apcId: String!
    @NSManaged public var uuid: String!
    @NSManaged public var type: String!
    @NSManaged public var customTitle: String!
    @NSManaged public var thumbnailUuid: String?
    @NSManaged public var projectUuid: String!
    @NSManaged public var dataStringType: String!
    @NSManaged public var version: String!
    @NSManaged public var dataString: Data?
    @NSManaged public var pgyProjectId: Int64
    @NSManaged public var mediaCustomId: String?
    @NSManaged public var state: String!
    @NSManaged public var lastMissionItemExecuted: Int64
    @NSManaged public var mediaCount: Int16
    @NSManaged public var uploadedMediaCount: Int16
    @NSManaged public var lastUpdate: Date!
    @NSManaged public var hasReachedFirstWayPoint: Bool
    @NSManaged public var hasReachedLastWayPoint: Bool
    @NSManaged public var lastPassedWayPointIndex: NSNumber?
    @NSManaged public var percentCompleted: Double
    @NSManaged public var synchroStatus: Int16
    @NSManaged public var fileSynchroStatus: Int16
    @NSManaged public var fileSynchroDate: Date?
    @NSManaged public var latestSynchroStatusDate: Date?
    @NSManaged public var cloudId: Int64
    @NSManaged public var parrotCloudUploadUrl: String?
    @NSManaged public var isLocalDeleted: Bool
    @NSManaged public var latestCloudModificationDate: Date?
    @NSManaged public var uploadAttemptCount: Int16
    @NSManaged public var lastUploadAttempt: Date?
    @NSManaged public var latestLocalModificationDate: Date?
    @NSManaged public var synchroError: Int16
    @NSManaged public var executionRank: NSNumber?

    // MARK: - Relationship

    @NSManaged public var ofProject: Project?
    @NSManaged public var ofUserParrot: UserParrot?
    @NSManaged public var thumbnail: Thumbnail?
    @NSManaged public var flightPlanFlights: Set<FlightPlanFlights>?

}

// MARK: Generated accessors for flightPlanFlights
extension FlightPlan {

    @objc(addFlightPlanFlightsObject:)
    @NSManaged public func addToFlightPlanFlights(_ value: FlightPlanFlights)

    @objc(removeFlightPlanFlightsObject:)
    @NSManaged public func removeFromFlightPlanFlights(_ value: FlightPlanFlights)

    @objc(addFlightPlanFlights:)
    @NSManaged public func addToFlightPlanFlights(_ values: NSSet)

    @objc(removeFlightPlanFlights:)
    @NSManaged public func removeFromFlightPlanFlights(_ values: NSSet)

}
