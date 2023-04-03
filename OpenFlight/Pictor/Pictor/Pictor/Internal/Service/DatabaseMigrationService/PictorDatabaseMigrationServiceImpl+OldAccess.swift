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

// MARK: - Access old database
internal extension PictorDatabaseMigrationServiceImpl {
    /// Get records from old database.
    ///
    /// - Parameters:
    ///    - entityName: entity name of record to fetch in old database
    ///    - count: number of records to get
    /// - Returns List of old records
    func getFirstOldRecords(entityName: String, count: Int = Constants.fetchCount) -> [OldManagedObject] {
        var result: [OldManagedObject] = []
        self.coreDataOldService.writerBackgroundContext.performAndWait { [unowned self] in
            do {
                let fetchRequest: NSFetchRequest<OldManagedObject> = NSFetchRequest(entityName: entityName)
                fetchRequest.fetchOffset = 0
                fetchRequest.fetchLimit = max(count, 1)
                result = try coreDataOldService.writerBackgroundContext.fetch(fetchRequest)
            } catch let error {
                PictorLogger.shared.e(.tag, "💾🔴 getOldRecords error: \(error)")
            }
        }
        return result
    }

    /// Get count of all records from old database.
    ///
    /// - Parameters:
    ///    - entityName: entity name of record to fetch in old database
    /// - Returns Count of old records
    func getOldCountRecords(entityName: String) -> Int {
        var result = 0
        self.coreDataOldService.writerBackgroundContext.performAndWait { [unowned self] in
            do {
                let fetchRequest: NSFetchRequest<OldManagedObject> = NSFetchRequest(entityName: entityName)
                result = try coreDataOldService.writerBackgroundContext.count(for: fetchRequest)
            } catch let error {
                PictorLogger.shared.e(.tag, "💾🔴 getOldCountRecords error: \(error)")
            }
        }
        return result
    }

    /// Delete old record with specified UUID in specified list of old records.
    ///
    /// - Parameters:
    ///    - uuid: specified UUID to delete
    ///    - list: specified list of old records
    func deleteOldRecord(for uuid: String, in list: [OldManagedObject]) {
        self.coreDataOldService.writerBackgroundContext.performAndWait { [unowned self] in
            if let oldCD = list.first(where: { $0._uuid == uuid }) {
                do {
                    coreDataOldService.writerBackgroundContext.delete(oldCD)
                    try coreDataOldService.writerBackgroundContext.save()
                } catch(let error) {
                    PictorLogger.shared.e(.tag, "💾🔴 deleteOldRecord error: \(error)")
                }
            }
        }
    }
}
