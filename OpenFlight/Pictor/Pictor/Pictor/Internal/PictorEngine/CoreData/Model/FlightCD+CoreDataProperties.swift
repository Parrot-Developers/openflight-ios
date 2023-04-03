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

extension FlightCD {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FlightCD> {
        return NSFetchRequest<FlightCD>(entityName: "FlightCD")
    }

    @NSManaged public var uuid: String
    @NSManaged public var localCreationDate: Date?
    @NSManaged public var localModificationDate: Date?

    // - Academy
    @NSManaged public var cloudId: Int64
    @NSManaged public var formatVersion: String?
    @NSManaged public var title: String?
    @NSManaged public var parseError: Bool
    @NSManaged public var runDate: Date?
    @NSManaged public var serial: String?
    @NSManaged public var firmware: String?
    @NSManaged public var modelId: String?
    @NSManaged public var gutmaFile: Data
    @NSManaged public var photoCount: Int16
    @NSManaged public var videoCount: Int16
    @NSManaged public var startLatitude: Double
    @NSManaged public var startLongitude: Double
    @NSManaged public var batteryConsumption: Int16
    @NSManaged public var distance: Double
    @NSManaged public var duration: Double

    // - Relationship
    @NSManaged public var userUuid: String
    @NSManaged public var thumbnailUuid: String?
    
    // - Engine
    @NSManaged public var cloudCreationDate: Date?
    @NSManaged public var cloudModificationDate: Date?

    // - Engine Synchro
    @NSManaged public var synchroStatus: Int16
    @NSManaged public var synchroError: Int16
    @NSManaged public var synchroLatestUpdatedDate: Date?
    @NSManaged public var synchroLatestStatusDate: Date?
    @NSManaged public var synchroIsDeleted: Bool
}

// MARK: Generated accessors for gutmaLink
extension FlightCD {

    @objc(addGutmaLinkObject:)
    @NSManaged public func addToGutmaLink(_ value: GutmaLinkCD)

    @objc(removeGutmaLinkObject:)
    @NSManaged public func removeFromGutmaLink(_ value: GutmaLinkCD)

    @objc(addGutmaLink:)
    @NSManaged public func addToGutmaLink(_ values: NSSet)

    @objc(removeGutmaLink:)
    @NSManaged public func removeFromGutmaLink(_ values: NSSet)

}

extension FlightCD : Identifiable {

}
