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

extension Project {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Project> {
        return NSFetchRequest<Project>(entityName: Self.entityName)
    }

    // MARK: - Properties

    @NSManaged public var apcId: String!
    @NSManaged public var uuid: String!
    @NSManaged public var title: String?
    @NSManaged public var type: String!
    @NSManaged public var lastUpdated: Date!
    @NSManaged public var latestCloudModificationDate: Date?
    @NSManaged public var cloudId: Int64
    @NSManaged public var isLocalDeleted: Bool
    @NSManaged public var latestSynchroStatusDate: Date?
    @NSManaged public var synchroStatus: Int16
    @NSManaged public var latestLocalModificationDate: Date?
    @NSManaged public var synchroError: Int16
    @NSManaged public var lastOpened: Date?
    @NSManaged public var latestExecutionRank: NSNumber?

    // MARK: - Relationship

    @NSManaged public var flightPlans: Set<FlightPlan>?
    @NSManaged public var ofUserParrot: UserParrot?

}

// MARK: Generated accessors for flightPlan
extension Project {

    @objc(addFlightPlansObject:)
    @NSManaged public func addToFlightPlans(_ value: FlightPlan)

    @objc(removeFlightPlansObject:)
    @NSManaged public func removeFromFlightPlans(_ value: FlightPlan)

    @objc(addFlightPlans:)
    @NSManaged public func addToFlightPlans(_ values: NSSet)

    @objc(removeFlightPlans:)
    @NSManaged public func removeFromFlightPlans(_ values: NSSet)

}
