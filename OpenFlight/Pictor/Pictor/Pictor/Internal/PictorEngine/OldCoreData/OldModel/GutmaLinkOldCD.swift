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

struct OldGutmaLinkModel: OldModel {
    var _uuid: String { "\(cloudId)" }
    var _userUuid: String { apcId }

    var apcId: String!
    var flightUuid: String!
    var flightplanUuid: String!
    var dateExecutionFlight: Date!
    var synchroStatus: Int16
    var latestLocalModificationDate: Date?
    var latestSynchroStatusDate: Date?
    var cloudId: Int64
    var isLocalDeleted: Bool
    var synchroError: Int16
}

@objc(FlightPlanFlights)
class FlightPlanFlights: OldManagedObject {
    override var _uuid: String { "\(cloudId)" }
    override var _userUuid: String { apcId }

    func toModel() -> OldGutmaLinkModel {
        OldGutmaLinkModel(apcId: apcId,
                          flightUuid: flightUuid,
                          flightplanUuid: flightplanUuid,
                          dateExecutionFlight: dateExecutionFlight,
                          synchroStatus: synchroStatus,
                          latestLocalModificationDate: latestLocalModificationDate,
                          latestSynchroStatusDate: latestSynchroStatusDate,
                          cloudId: cloudId,
                          isLocalDeleted: isLocalDeleted,
                          synchroError: synchroError)
    }
}

extension FlightPlanFlights {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FlightPlanFlights> {
        return NSFetchRequest<FlightPlanFlights>(entityName: "FlightPlanFlights")
    }

    // MARK: Properties

    @NSManaged public var apcId: String!
    @NSManaged public var flightUuid: String!
    @NSManaged public var flightplanUuid: String!
    @NSManaged public var dateExecutionFlight: Date!
    @NSManaged public var synchroStatus: Int16
    @NSManaged public var latestLocalModificationDate: Date?
    @NSManaged public var latestSynchroStatusDate: Date?
    @NSManaged public var cloudId: Int64
    @NSManaged public var isLocalDeleted: Bool
    @NSManaged public var synchroError: Int16

    // MARK: - Relationship

    @NSManaged public var ofUserParrot: UserParrot?
    @NSManaged public var ofFlightPlan: FlightPlan?
    @NSManaged public var ofFlight: Flight?

}
