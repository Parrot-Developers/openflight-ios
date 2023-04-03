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

fileprivate extension String {
    static let tag = "pictor.service.database-migration"
}

// MARK: - Access Pictor database
internal extension PictorDatabaseMigrationServiceImpl {
    /// Get records in new database.
    /// - Parameters:
    ///    - entityName: entity name of record to fetch in old database
    ///    - uuid: specified UUID to fetch
    ///    - serialNumber: specified serial number to fetch
    ///    - flightUuid: specified flight's UUID to fetch
    ///    - flightPlanUuid: specified flightPlan's UUID to fetch
    /// - Returns List of old records
    func getRecord(entityName: String, uuid: String? = nil, serialNumber: String? = nil, flightUuid: String? = nil, flightPlanUuid: String? = nil) -> PictorEngineManagedObject? {
        var result: PictorEngineManagedObject?
        do {
            let fetchRequest: NSFetchRequest<PictorEngineManagedObject> = NSFetchRequest(entityName: entityName)
            var subPredicateList: [NSPredicate] = []

            if let uuid = uuid {
                subPredicateList.append(NSPredicate(format: "uuid = %@", uuid))
            }
            if let serialNumber = serialNumber {
                subPredicateList.append(NSPredicate(format: "serialNumber = %@", serialNumber))
            }
            if let flightUuid = flightUuid {
                subPredicateList.append(NSPredicate(format: "flightUuid = %@", flightUuid))
            }
            if let flightPlanUuid = flightPlanUuid {
                subPredicateList.append(NSPredicate(format: "flightPlanUuid = %@", flightPlanUuid))
            }
            fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
            result = try childContext.fetch(fetchRequest).first
        } catch let error {
            PictorLogger.shared.e(.tag, "💾🔴 getRecord error: \(error)")
        }
        return result
    }

    /// Get count of all records from new database.
    /// - Parameters:
    ///    - entityName: entity name of record to fetch in new database
    /// - Returns Count of records
    func getCountRecords(entityName: String) -> Int {
        var result = 0
        do {
            let fetchRequest: NSFetchRequest<PictorEngineManagedObject> = NSFetchRequest(entityName: entityName)
            result = try childContext.count(for: fetchRequest)
        } catch let error {
            PictorLogger.shared.e(.tag, "💾🔴 getCountRecords error: \(error)")
        }
        return result
    }

    /// Log count of records in new database.
    func logMigratedDatabase() {
        childContext.performAndWait {
            PictorLogger.shared.d(.tag, """
                💾✅ Migrated database count
                    UserCD count = \(getCountRecords(entityName: UserCD.entityName))
                    DroneCD count = \(getCountRecords(entityName: DroneCD.entityName))
                    FlightCD count = \(getCountRecords(entityName: FlightCD.entityName))
                    ProjectCD count = \(getCountRecords(entityName: ProjectCD.entityName))
                    ProjectPix4dCD count = \(getCountRecords(entityName: ProjectPix4dCD.entityName))
                    FlightPlanCD count = \(getCountRecords(entityName: FlightPlanCD.entityName))
                    GutmaLinkCD count = \(getCountRecords(entityName: GutmaLinkCD.entityName))
            """)
        }
    }
}
