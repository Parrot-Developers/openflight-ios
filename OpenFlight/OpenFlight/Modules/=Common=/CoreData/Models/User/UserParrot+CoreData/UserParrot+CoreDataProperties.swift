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

extension UserParrot {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserParrot> {
        return NSFetchRequest<UserParrot>(entityName: UserParrot.entityName)
    }

    // MARK: - Properties

    @NSManaged public var agreementChanged: Bool
    @NSManaged public var apcId: String!
    @NSManaged public var apcToken: String?
    @NSManaged public var birthday: String?
    @NSManaged public var email: String!
    @NSManaged public var firstName: String?
    @NSManaged public var freemiumProjectCounter: Int16
    @NSManaged public var lang: String!
    @NSManaged public var lastName: String?
    @NSManaged public var newsletterOption: Bool
    @NSManaged public var isSynchronizeFlightData: Bool
    @NSManaged public var syncWithCloud: Bool
    @NSManaged public var tmpApcUser: Bool
    @NSManaged public var academyId: String?
    @NSManaged public var pilotNumber: String?
    @NSManaged public var isCaligoffEnabled: Bool
    @NSManaged public var userInfoChanged: Bool
    @NSManaged public var avatar: String?
    @NSManaged public var isSynchronizeFlightDataExtended: Bool
    @NSManaged public var isSynchronizeMedia: Bool
    @NSManaged public var isLocalDeleted: Bool
    @NSManaged public var latestCloudAvatarModificationDate: Date?
    @NSManaged public var synchroStatus: Int16
    @NSManaged public var latestSynchroStatusDate: Date?
    @NSManaged public var latestCloudModificationDate: Date?
    @NSManaged public var latestLocalModificationDate: Date?
    @NSManaged public var synchroError: Int16

    // MARK: - Relationship

    @NSManaged public var dronesDatas: NSSet?
    @NSManaged public var flightPlans: NSSet?
    @NSManaged public var flights: NSSet?
    @NSManaged public var pgyProjects: NSSet?
    @NSManaged public var projects: NSSet?
    @NSManaged public var thumbnails: NSSet?
    @NSManaged public var flightPlanFlights: NSSet?

}

// MARK: Generated accessors for dronesDatas
extension UserParrot {

    @objc(addDronesDatasObject:)
    @NSManaged public func addToDronesDatas(_ value: DronesData)

    @objc(removeDronesDatasObject:)
    @NSManaged public func removeFromDronesDatas(_ value: DronesData)

    @objc(addDronesDatas:)
    @NSManaged public func addToDronesDatas(_ values: NSSet)

    @objc(removeDronesDatas:)
    @NSManaged public func removeFromDronesDatas(_ values: NSSet)

}

// MARK: Generated accessors for flightPlans
extension UserParrot {

    @objc(addFlightPlansObject:)
    @NSManaged public func addToFlightPlans(_ value: FlightPlan)

    @objc(removeFlightPlansObject:)
    @NSManaged public func removeFromFlightPlans(_ value: FlightPlan)

    @objc(addFlightPlans:)
    @NSManaged public func addToFlightPlans(_ values: NSSet)

    @objc(removeFlightPlans:)
    @NSManaged public func removeFromFlightPlans(_ values: NSSet)

}

// MARK: Generated accessors for flights
extension UserParrot {

    @objc(addFlightsObject:)
    @NSManaged public func addToFlights(_ value: Flight)

    @objc(removeFlightsObject:)
    @NSManaged public func removeFromFlights(_ value: Flight)

    @objc(addFlights:)
    @NSManaged public func addToFlights(_ values: NSSet)

    @objc(removeFlights:)
    @NSManaged public func removeFromFlights(_ values: NSSet)

}

// MARK: Generated accessors for pgyProjects
extension UserParrot {

    @objc(addPgyProjectObject:)
    @NSManaged public func addToPgyProjects(_ value: PgyProject)

    @objc(removePgyProjectObject:)
    @NSManaged public func removeFromPgyProjects(_ value: PgyProject)

    @objc(addPgyProject:)
    @NSManaged public func addToPgyProjects(_ values: NSSet)

    @objc(removePgyProject:)
    @NSManaged public func removeFromPgyProjects(_ values: NSSet)

}

// MARK: Generated accessors for projects
extension UserParrot {

    @objc(addProjectsObject:)
    @NSManaged public func addToProjects(_ value: Project)

    @objc(removeProjectsObject:)
    @NSManaged public func removeFromProjects(_ value: Project)

    @objc(addProjects:)
    @NSManaged public func addToProjects(_ values: NSSet)

    @objc(removeProjects:)
    @NSManaged public func removeFromProjects(_ values: NSSet)

}

// MARK: Generated accessors for thumbnails
extension UserParrot {

    @objc(addThumbnailsObject:)
    @NSManaged public func addToThumbnails(_ value: Thumbnail)

    @objc(removeThumbnailsObject:)
    @NSManaged public func removeFromThumbnails(_ value: Thumbnail)

    @objc(addThumbnails:)
    @NSManaged public func addToThumbnails(_ values: NSSet)

    @objc(removeThumbnails:)
    @NSManaged public func removeFromThumbnails(_ values: NSSet)

}

// MARK: Generated accessors for flightPlanFlights
extension UserParrot {

    @objc(addFlightPlanFlightsObject:)
    @NSManaged public func addToFlightPlanFlights(_ value: FlightPlanFlights)

    @objc(removeFlightPlanFlightsObject:)
    @NSManaged public func removeFromFlightPlanFlights(_ value: FlightPlanFlights)

    @objc(addFlightPlanFlights:)
    @NSManaged public func addToFlightPlanFlights(_ values: NSSet)

    @objc(removeFlightPlanFlights:)
    @NSManaged public func removeFromFlightPlanFlights(_ values: NSSet)

}
