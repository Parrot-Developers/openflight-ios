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
import Combine

public struct OldSessionData {
    // Connected user
    public var oldApcId: String?

    // Multisession
    public var msLatestBgDate: Date?
    public var msLatestSuccessfulDate: Date?
    public var msLatestTriedDate: Date?
    public var msLatestFlightPlanCloudDeletionDate: Date?
    public var msLatestFlightPlanDate: Date?
    public var msLatestGutmaCloudDeletionDate: Date?
    public var msLatestGutmaDate: Date?
    public var msLatestProjectCloudDeletionDate: Date?
    public var msLatestProjectDate: Date?

    // Incremental
    public var incShouldLaunch: Bool

    // Sanity check
    public var scLatestSuccessfulDate: Date?
    public var scLatestTriedDate: Date?
    public var scSkip: Bool

    public init(oldApcId: String?,
         msLatestBgDate: Date?,
         msLatestSuccessfulDate: Date?,
         msLatestTriedDate: Date?,
         msLatestFlightPlanCloudDeletionDate: Date?,
         msLatestFlightPlanDate: Date?,
         msLatestGutmaCloudDeletionDate: Date?,
         msLatestGutmaDate: Date?,
         msLatestProjectCloudDeletionDate: Date?,
         msLatestProjectDate: Date?,
         incShouldLaunch: Bool,
         scLatestSuccessfulDate: Date?,
         scLatestTriedDate: Date?,
         scSkip: Bool) {
        self.oldApcId = oldApcId
        self.msLatestBgDate = msLatestBgDate
        self.msLatestSuccessfulDate = msLatestSuccessfulDate
        self.msLatestTriedDate = msLatestTriedDate
        self.msLatestFlightPlanCloudDeletionDate = msLatestFlightPlanCloudDeletionDate
        self.msLatestFlightPlanDate = msLatestFlightPlanDate
        self.msLatestGutmaCloudDeletionDate = msLatestGutmaCloudDeletionDate
        self.msLatestGutmaDate = msLatestGutmaDate
        self.msLatestProjectCloudDeletionDate = msLatestProjectCloudDeletionDate
        self.msLatestProjectDate = msLatestProjectDate
        self.incShouldLaunch = incShouldLaunch
        self.scLatestSuccessfulDate = scLatestSuccessfulDate
        self.scLatestTriedDate = scLatestTriedDate
        self.scSkip = scSkip
    }
}

public protocol PictorDatabaseMigrationService {
    /// Setup service with old database for migration
    ///
    /// - Parameter withOldPersistentContainer: persistent container of old database
    func setup(withOldPersistentContainer: NSPersistentContainer)

    /// Get count of all records in old database
    ///
    /// - Returns count of all records
    func getOldRecordsCount() -> Int

    /// Start old database migration to Pictor database, migration will handle one record at a time for each entity in a specific order.
    ///
    /// - Parameters:
    ///    - oldSessionData: session data of old database
    ///    - didSaveFlightPlan: synchronous closure called when a new flight plan has been added to Pictor database
    ///    - progress: synchronous closure called on progression
    func start(oldSessionData: OldSessionData,
               didSaveFlightPlan: ((_ flightPlan: PictorFlightPlanModel) -> Void)?,
               progress: ((_ totalCount: Int, _ updatedCount: Int) -> Void)?)
}
