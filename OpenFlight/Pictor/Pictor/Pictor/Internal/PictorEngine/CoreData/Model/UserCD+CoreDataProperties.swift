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

extension UserCD {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserCD> {
        return NSFetchRequest<UserCD>(entityName: "UserCD")
    }

    @NSManaged public var uuid: String
    @NSManaged public var localCreationDate: Date?
    @NSManaged public var localModificationDate: Date?

    // - Info
    @NSManaged public var apcId: String
    @NSManaged public var academyId: String
    @NSManaged public var email: String
    @NSManaged public var firstName: String
    @NSManaged public var lastName: String
    @NSManaged public var isPrivateMode: NSNumber?

    // - Account
    @NSManaged public var apcToken: String?
    @NSManaged public var sessionId: String?
    @NSManaged public var confirmed: Bool

    // - Optional
    // Info
    @NSManaged public var pilotNumber: NSNumber?
    @NSManaged public var gender: String?
    @NSManaged public var phone: String?
    @NSManaged public var country: String?
    @NSManaged public var language: String?
    @NSManaged public var company: String?
    @NSManaged public var vatNumber: NSNumber?
    @NSManaged public var registrationNumber: NSNumber?
    @NSManaged public var subIndustry: String?
    @NSManaged public var industry: String?
    @NSManaged public var store: String?
    @NSManaged public var isCaligoffEnabled: Bool

    // - Local
    @NSManaged public var isAgreementChanged: Bool
    @NSManaged public var avatarImageData: Data?

    // - Pix4d
    @NSManaged public var nbFreemiumProjects: Int16

    // - Synchro
    @NSManaged public var synchroStatus: Int16
    @NSManaged public var synchroError: Int16
    @NSManaged public var synchroLatestStatusDate: Date?
    @NSManaged public var synchroLatestUpdatedDate: Date?
    @NSManaged public var synchroIsDeleted: Bool
}

// MARK: Generated accessors for drones
extension UserCD {

    @objc(addDronesObject:)
    @NSManaged public func addToDrones(_ value: DroneCD)

    @objc(removeDronesObject:)
    @NSManaged public func removeFromDrones(_ value: DroneCD)

    @objc(addDrones:)
    @NSManaged public func addToDrones(_ values: NSSet)

    @objc(removeDrones:)
    @NSManaged public func removeFromDrones(_ values: NSSet)

}

// MARK: Generated accessors for flightPlans
extension UserCD {

    @objc(addFlightPlansObject:)
    @NSManaged public func addToFlightPlans(_ value: FlightPlanCD)

    @objc(removeFlightPlansObject:)
    @NSManaged public func removeFromFlightPlans(_ value: FlightPlanCD)

    @objc(addFlightPlans:)
    @NSManaged public func addToFlightPlans(_ values: NSSet)

    @objc(removeFlightPlans:)
    @NSManaged public func removeFromFlightPlans(_ values: NSSet)

}

// MARK: Generated accessors for flights
extension UserCD {

    @objc(addFlightsObject:)
    @NSManaged public func addToFlights(_ value: FlightCD)

    @objc(removeFlightsObject:)
    @NSManaged public func removeFromFlights(_ value: FlightCD)

    @objc(addFlights:)
    @NSManaged public func addToFlights(_ values: NSSet)

    @objc(removeFlights:)
    @NSManaged public func removeFromFlights(_ values: NSSet)

}

// MARK: Generated accessors for gutmaLinks
extension UserCD {

    @objc(addGutmaLinksObject:)
    @NSManaged public func addToGutmaLinks(_ value: GutmaLinkCD)

    @objc(removeGutmaLinksObject:)
    @NSManaged public func removeFromGutmaLinks(_ value: GutmaLinkCD)

    @objc(addGutmaLinks:)
    @NSManaged public func addToGutmaLinks(_ values: NSSet)

    @objc(removeGutmaLinks:)
    @NSManaged public func removeFromGutmaLinks(_ values: NSSet)

}

// MARK: Generated accessors for projectPix4ds
extension UserCD {

    @objc(addProjectPix4dsObject:)
    @NSManaged public func addToProjectPix4ds(_ value: ProjectPix4dCD)

    @objc(removeProjectPix4dsObject:)
    @NSManaged public func removeFromProjectPix4ds(_ value: ProjectPix4dCD)

    @objc(addProjectPix4ds:)
    @NSManaged public func addToProjectPix4ds(_ values: NSSet)

    @objc(removeProjectPix4ds:)
    @NSManaged public func removeFromProjectPix4ds(_ values: NSSet)

}

// MARK: Generated accessors for projects
extension UserCD {

    @objc(addProjectsObject:)
    @NSManaged public func addToProjects(_ value: ProjectCD)

    @objc(removeProjectsObject:)
    @NSManaged public func removeFromProjects(_ value: ProjectCD)

    @objc(addProjects:)
    @NSManaged public func addToProjects(_ values: NSSet)

    @objc(removeProjects:)
    @NSManaged public func removeFromProjects(_ values: NSSet)

}

// MARK: Generated accessors for thumbnails
extension UserCD {

    @objc(addThumbnailsObject:)
    @NSManaged public func addToThumbnails(_ value: ThumbnailCD)

    @objc(removeThumbnailsObject:)
    @NSManaged public func removeFromThumbnails(_ value: ThumbnailCD)

    @objc(addThumbnails:)
    @NSManaged public func addToThumbnails(_ values: NSSet)

    @objc(removeThumbnails:)
    @NSManaged public func removeFromThumbnails(_ values: NSSet)

}

extension UserCD : Identifiable {

}
