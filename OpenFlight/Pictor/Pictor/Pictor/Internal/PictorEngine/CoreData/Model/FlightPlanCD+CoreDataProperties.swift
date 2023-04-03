//    Copyright (C) 2022 Parrot Drones SAS
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

extension FlightPlanCD {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FlightPlanCD> {
        return NSFetchRequest<FlightPlanCD>(entityName: "FlightPlanCD")
    }

    @NSManaged public var uuid: String
    @NSManaged public var localCreationDate: Date?
    @NSManaged public var localModificationDate: Date?

    // - Academy
    @NSManaged public var cloudId: Int64
    @NSManaged public var name: String?
    @NSManaged public var state: String?
    @NSManaged public var fileType: String?
    @NSManaged public var flightPlanType: String?
    @NSManaged public var mediaCount: Int64
    @NSManaged public var uploadedMediaCount: Int64
    @NSManaged public var lastMissionItemExecuted: Int64
    @NSManaged public var formatVersion: String?
    @NSManaged public var dataSetting: Data?

    // - Local
    @NSManaged public var lastUpdated: Date
    @NSManaged public var hasReachedFirstWaypoint: NSNumber?
    @NSManaged public var executionRank: NSNumber?

    // - Relationships
    @NSManaged public var userUuid: String
    @NSManaged public var projectUuid: String?
    @NSManaged public var projectPix4dUuid: String?
    @NSManaged public var thumbnailUuid: String?

    // - Engine
    @NSManaged public var cloudModificationDate: Date?

    // - Engine Synchro
    @NSManaged public var synchroStatus: Int16
    @NSManaged public var synchroError: Int16
    @NSManaged public var synchroLatestUpdatedDate: Date?
    @NSManaged public var synchroLatestStatusDate: Date?
    @NSManaged public var synchroIsDeleted: Bool

}

// MARK: Generated accessors for gutmaLink
extension FlightPlanCD {

    @objc(addGutmaLinkObject:)
    @NSManaged public func addToGutmaLinks(_ value: GutmaLinkCD)

    @objc(removeGutmaLinkObject:)
    @NSManaged public func removeFromGutmaLinks(_ value: GutmaLinkCD)

    @objc(addGutmaLink:)
    @NSManaged public func addToGutmaLinks(_ values: NSSet)

    @objc(removeGutmaLink:)
    @NSManaged public func removeFromGutmaLinks(_ values: NSSet)

}

extension FlightPlanCD : Identifiable {

}
