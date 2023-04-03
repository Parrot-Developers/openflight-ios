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
import Combine

fileprivate extension String {
    static let tag = "pictor.service.database-migration"
}

fileprivate protocol PictorUserServiceMigration {
    /// Allows to set the current user.
    /// - Parameters:
    ///    - engineUser: `PictorEngineUserModel` to set
    func setCurrentUser(_ engineUser: PictorEngineUserModel)
}

extension PictorUserServiceImpl: PictorUserServiceMigration {
    func setCurrentUser(_ engineUser: PictorEngineUserModel) {
        currentUserSubject.value = engineUser
        userEventSubject.send(.didLogin(false))
    }
}

class PictorDatabaseMigrationServiceImpl: PictorDatabaseMigrationService {
    // MARK: Properties
    enum Constants {
        static let fetchCount: Int = 1
    }

    internal var childContext: NSManagedObjectContext!
    private var startDate: Date?
    // - Dependencies
    internal var coreDataService: CoreDataService
    internal var coreDataOldService: CoreDataOldService
    private var userService: PictorUserService

    // MARK: Init
    init(coreDataService: CoreDataService, coreDataOldService: CoreDataOldService, userService: PictorUserService) {
        self.coreDataService = coreDataService
        self.coreDataOldService = coreDataOldService
        self.userService = userService
    }

    // MARK: Pictor Database Migration Service Protocol
    func setup(withOldPersistentContainer: NSPersistentContainer) {
        childContext = coreDataService.newChildContext()
        coreDataOldService.setup(withPersistentContainer: withOldPersistentContainer)
    }

    func getOldRecordsCount() -> Int {
        var result = 0

        coreDataOldService.writerBackgroundContext.performAndWait { [unowned self] in
            let oldUserCount = getOldCountRecords(entityName: UserParrot.entityName)
            let oldDroneCount = getOldCountRecords(entityName: DronesData.entityName)
            let oldFlightCount = getOldCountRecords(entityName: Flight.entityName)
            let oldProjectCount = getOldCountRecords(entityName: Project.entityName)
            let oldProjectPix4dCount = getOldCountRecords(entityName: PgyProject.entityName)
            let oldFlightPlanCount = getOldCountRecords(entityName: FlightPlan.entityName)
            let oldGutmaLinksCount = getOldCountRecords(entityName: FlightPlanFlights.entityName)
            let oldThumbnailCount = getOldCountRecords(entityName: Thumbnail.entityName)

            PictorLogger.shared.i(.tag, """
                💾🔵 Old record found count
                UserParrot count = \(oldUserCount)
                Drone count = \(oldDroneCount)
                Flight count = \(oldFlightCount)
                Project count = \(oldProjectCount)
                PgyProject count = \(oldProjectPix4dCount)
                FlightPlan count = \(oldFlightPlanCount)
                FlightPlanFlight count = \(oldGutmaLinksCount)
                Thumbnail count = \(oldThumbnailCount)
            """)

            result = oldUserCount
            + oldDroneCount
            + oldFlightCount
            + oldProjectCount
            + oldProjectPix4dCount
            + oldFlightPlanCount
            + oldGutmaLinksCount
            + oldThumbnailCount

            // - If any old records are found, add connecting user migration step as last step
            if result > 0 {
                result += 1
            }
        }
        return result
    }

    func start(oldSessionData: OldSessionData,
               didSaveFlightPlan: ((_ flightPlan: PictorFlightPlanModel) -> Void)?,
               progress: ((_ totalCount: Int, _ updatedCount: Int) -> Void)?) {
        PictorLogger.shared.i(.tag, "💾🔵 Start database migration")
        startDate = Date()
        coreDataOldService.writerBackgroundContext.performAndWait { [unowned self] in
            // - Get count of all old records
            let oldTotalCount = getOldRecordsCount()
            var updateCount = 0

            guard oldTotalCount > 0 else {
                progress?(1, 1)
                return
            }

            progress?(oldTotalCount, updateCount)

            // - Migration should be this order as database has relationships
            // Thumbnail - GutmaLink - Flight - FlightPlan - Project - ProjectPix4d - Drone - User
            let handleProgress = {
                updateCount += 1
                progress?(oldTotalCount, updateCount)
            }
            migrateThumbnails {
                handleProgress()
            }
            migrateGutmaLinks() {
                handleProgress()
            }
            migrateFlights {
                handleProgress()
            }
            migrateFlightPlans(didSaveFlightPlan: didSaveFlightPlan) {
                handleProgress()
            }
            migrateProjects {
                handleProgress()
            }
            migrateProjectPix4ds {
                handleProgress()
            }
            migrateDrones {
                handleProgress()
            }
            migrateUsers {
                handleProgress()
            }

            connectOldUser(oldSessionData)
            handleProgress()
        }

        logDuration()
        logMigratedDatabase()
    }
}

// MARK: - Private
private extension PictorDatabaseMigrationServiceImpl {
    /// Log duration of migration
    func logDuration() {
        guard let startDate = startDate else { return }
        let duration = Date().timeIntervalSince(startDate)
        let milliseconds = Int((duration*1000).truncatingRemainder(dividingBy: 1000))
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        let minutes = Int((duration/60).truncatingRemainder(dividingBy: 60))
        let hours = Int((duration/3600).truncatingRemainder(dividingBy: 3600))
        let timeStr = String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
        PictorLogger.shared.i(.tag, "💾🟢 Database migration done in \(timeStr)")
    }

    // MARK: Migration handlers
    /// Connect user in PictorUserService if any connected user is found in old database.
    ///
    /// - Parameter oldSessionData: session data of old database
    func connectOldUser(_ oldSessionData: OldSessionData) {
        guard let oldApcId = oldSessionData.oldApcId,
              !oldApcId.isEmpty,
              oldApcId != PictorUserModel.Constants.anonymousId else {
            PictorLogger.shared.i(.tag, "💾🟢 Database migration - no need to connect old user with apcId: \(oldSessionData.oldApcId ?? "nil")")
            return
        }

        childContext.performAndWait {
            guard let userCD = getRecord(entityName: UserCD.entityName, uuid: oldApcId) as? UserCD else {
                PictorLogger.shared.i(.tag, "💾🔵 Database migration - no user found for connecting old user with apcId: \(oldApcId)")
                return
            }
            guard let sessionCD = coreDataService.getCurrentSessionCD(in: childContext) else {
                PictorLogger.shared.i(.tag, "💾🔵 Database migration - no session found for connecting old user with apcId: \(oldApcId)")
                return
            }

            // User UUID
            sessionCD.userUuid = userCD.uuid
            // Multisession
            sessionCD.msLatestBgDate = oldSessionData.msLatestBgDate
            sessionCD.msLatestSuccessfulDate = oldSessionData.msLatestSuccessfulDate
            sessionCD.msLatestTriedDate = oldSessionData.msLatestTriedDate
            sessionCD.msLatestFlightPlanCloudDeletionDate = oldSessionData.msLatestFlightPlanCloudDeletionDate
            sessionCD.msLatestFlightPlanDate = oldSessionData.msLatestFlightPlanDate
            sessionCD.msLatestGutmaCloudDeletionDate = oldSessionData.msLatestGutmaCloudDeletionDate
            sessionCD.msLatestGutmaDate = oldSessionData.msLatestGutmaDate
            sessionCD.msLatestProjectCloudDeletionDate = oldSessionData.msLatestProjectCloudDeletionDate
            sessionCD.msLatestProjectDate = oldSessionData.msLatestProjectDate
            // Incremental
            sessionCD.incShouldLaunch = oldSessionData.incShouldLaunch
            // Sanity check
            sessionCD.scLatestSuccessfulDate = oldSessionData.scLatestSuccessfulDate
            sessionCD.scLatestTriedDate = oldSessionData.scLatestTriedDate
            sessionCD.scSkip = oldSessionData.scSkip

            coreDataService.saveChildContext(childContext)

            let user = PictorUserModel(record: userCD)
            let engineUser = PictorEngineUserModel(model: user, record: userCD)
            (userService as? PictorUserServiceMigration)?.setCurrentUser(engineUser)
            PictorLogger.shared.i(.tag, "💾🟢 Database migration - user is now connected with apcId: \(oldApcId)")
        }
    }

    /// Migrate old users.
    ///
    /// - Parameters:
    ///    - didMigrateRecord: callback closure called when a record has been fully migrated (deleted in old database)
    func migrateUsers(_ didMigrateRecord: (() -> Void)?) {
        PictorLogger.shared.i(.tag, "💾🔵 Migrating users...")
        while let oldCDs = getFirstOldRecords(entityName: UserParrot.entityName) as? [UserParrot], !oldCDs.isEmpty {
            let oldModels: [OldUserModel] = oldCDs.compactMap { $0.toModel() }
            // - Migrate old record to pictor database
            childContext.performAndWait { [unowned self] in
                for oldModel in oldModels {
                    // - Create new record if not found
                    if getRecord(entityName: UserCD.entityName, uuid: oldModel.apcId) as? UserCD == nil {
                        let modelCD = UserCD(context: self.childContext)
                        modelCD.update(from: oldModel)
                        coreDataService.saveChildContext(childContext)
                    }

                    // - Delete old record
                    deleteOldRecord(for: oldModel._uuid, in: oldCDs)

                    didMigrateRecord?()
                }
            }
        }
        PictorLogger.shared.i(.tag, "💾🟢 Migrating users")
    }

    /// Migrate old drones.
    ///
    /// - Parameters:
    ///    - didMigrateRecord: callback closure called when a record has been fully migrated (deleted in old database)
    func migrateDrones(_ didMigrateRecord: (() -> Void)?) {
        PictorLogger.shared.i(.tag, "💾🔵 Migrating drones...")
        while let oldCDs = getFirstOldRecords(entityName: DronesData.entityName) as? [DronesData], !oldCDs.isEmpty {
            let oldModels: [OldDroneModel] = oldCDs.compactMap { $0.toModel() }
            // - Migrate old record to pictor database
            childContext.performAndWait { [unowned self] in
                for oldModel in oldModels {
                    // - Create new record if not found
                    if getRecord(entityName: DroneCD.entityName, serialNumber: oldModel.droneSerial) as? DroneCD == nil {
                        let modelCD = DroneCD(context: self.childContext)
                        modelCD.update(from: oldModel)
                        coreDataService.saveChildContext(childContext)
                    }

                    // - Delete old record
                    deleteOldRecord(for: oldModel._uuid, in: oldCDs)

                    didMigrateRecord?()
                }
            }
        }
        PictorLogger.shared.i(.tag, "💾🟢 Migrating drones")
    }

    /// Migrate old flights.
    ///
    /// - Parameter didMigrateRecord: callback closure called when a record has been fully migrated (deleted in old database)
    func migrateFlights(_ didMigrateRecord: (() -> Void)?) {
        PictorLogger.shared.i(.tag, "💾🔵 Migrating flights...")
        while let oldCDs = getFirstOldRecords(entityName: Flight.entityName) as? [Flight], !oldCDs.isEmpty {
            let oldModels: [OldFlightModel] = oldCDs.compactMap { $0.toModel() }
            // - Migrate old record to pictor database
            childContext.performAndWait { [unowned self] in
                for oldModel in oldModels {
                    // - Create new record if not found
                    if getRecord(entityName: FlightCD.entityName, uuid: oldModel.uuid) as? FlightCD == nil {
                        let modelCD = FlightCD(context: self.childContext)
                        modelCD.update(from: oldModel)
                        coreDataService.saveChildContext(childContext)
                    }

                    // - Delete old record
                    deleteOldRecord(for: oldModel._uuid, in: oldCDs)

                    didMigrateRecord?()
                }
            }
        }
        PictorLogger.shared.i(.tag, "💾🟢 Migrating flights")
    }

    /// Migrate old projects.
    ///
    /// - Parameter didMigrateRecord: callback closure called when a record has been fully migrated (deleted in old database)
    func migrateProjects(_ didMigrateRecord: (() -> Void)?) {
        PictorLogger.shared.i(.tag, "💾🔵 Migrating projects...")

        while let oldCDs = getFirstOldRecords(entityName: Project.entityName) as? [Project], !oldCDs.isEmpty {
            let oldModels: [OldProjectModel] = oldCDs.compactMap { $0.toModel() }
            // - Migrate old record to pictor database
            childContext.performAndWait { [unowned self] in
                for oldModel in oldModels {
                    // - Create new record if not found
                    var projectCD = getRecord(entityName: ProjectCD.entityName, uuid: oldModel.uuid) as? ProjectCD
                    if projectCD == nil {
                        projectCD = ProjectCD(context: self.childContext)
                        projectCD?.update(from: oldModel)
                        coreDataService.saveChildContext(childContext)
                    }
                    // - Update project from related flight plans
                    if let projectCD = projectCD {
                        let projectModel = PictorProjectModel(record: projectCD, editableFlightPlan: nil, latestExecutedFlightPlan: nil)
                        let pictorContext = PictorContext.new()
                        pictorContext.updateLocal([projectModel])
                        pictorContext.commit()
                    }

                    // - Delete old record
                    deleteOldRecord(for: oldModel._uuid, in: oldCDs)

                    didMigrateRecord?()
                }
            }
        }
        PictorLogger.shared.i(.tag, "💾🟢 Migrating projects")
    }

    /// Migrate old project pix4d.
    ///
    /// - Parameter didMigrateRecord: callback closure called when a record has been fully migrated (deleted in old database)
    func migrateProjectPix4ds(_ didMigrateRecord: (() -> Void)?) {
        PictorLogger.shared.i(.tag, "💾🔵 Migrating projects pgy...")
        while let oldCDs = getFirstOldRecords(entityName: PgyProject.entityName) as? [PgyProject], !oldCDs.isEmpty {
            let oldModels: [OldProjectPix4dModel] = oldCDs.compactMap { $0.toModel() }
            // - Migrate old record to pictor database
            childContext.performAndWait { [unowned self] in
                for oldModel in oldModels {
                    // - Create new record if not found
                    if getRecord(entityName: ProjectPix4dCD.entityName, uuid: "\(oldModel.pgyProjectId)") as? ProjectPix4dCD == nil {
                        let modelCD = ProjectPix4dCD(context: self.childContext)
                        modelCD.update(from: oldModel)
                        coreDataService.saveChildContext(childContext)
                    }

                    // - Delete old record
                    deleteOldRecord(for: oldModel._uuid, in: oldCDs)

                    didMigrateRecord?()
                }
            }
        }
        PictorLogger.shared.i(.tag, "💾🟢 Migrating projects pgy")
    }

    /// Migrate old flight plans.
    ///
    /// - Parameters:
    ///    - didSavedFlightPlan: callback closure called when a flight plan has been saved to database
    ///    - didMigrateRecord: callback closure called when a record has been fully migrated (deleted in old database)
    func migrateFlightPlans(didSaveFlightPlan: ((_ flightPlan: PictorFlightPlanModel) -> Void)?, _ didMigrateRecord: (() -> Void)?) {
        PictorLogger.shared.i(.tag, "💾🔵 Migrating flight plans...")
        while let oldCDs = getFirstOldRecords(entityName: FlightPlan.entityName) as? [FlightPlan], !oldCDs.isEmpty {
            let oldModels: [OldFlightPlanModel] = oldCDs.compactMap { $0.toModel() }

            // - Migrate old record to pictor database
            childContext.performAndWait { [unowned self] in
                for oldModel in oldModels {
                    // - Create new record if not found
                    if getRecord(entityName: FlightPlanCD.entityName, uuid: oldModel._uuid) as? FlightPlanCD == nil {
                        let modelCD = FlightPlanCD(context: self.childContext)
                        modelCD.update(from: oldModel)
                        coreDataService.saveChildContext(childContext)

                        // - No need of relations
                        didSaveFlightPlan?(PictorFlightPlanModel(record: modelCD, thumbnail: nil, gutmaLinks: []))
                    }

                    // - Delete old record
                    deleteOldRecord(for: oldModel._uuid, in: oldCDs)

                    didMigrateRecord?()
                }
            }
        }
        PictorLogger.shared.i(.tag, "💾🟢 Migrating flight plans")
    }

    /// Migrate old gutma links.
    ///
    /// - Parameter didMigrateRecord: callback closure called when a record has been fully migrated (deleted in old database)
    func migrateGutmaLinks(_ didMigrateRecord: (() -> Void)?) {
        PictorLogger.shared.i(.tag, "💾🔵 Migrating gutma links...")
        while let oldCDs = getFirstOldRecords(entityName: FlightPlanFlights.entityName) as? [FlightPlanFlights], !oldCDs.isEmpty {
            let oldModels: [OldGutmaLinkModel] = oldCDs.compactMap { $0.toModel() }
            // - Migrate old record to pictor database
            childContext.performAndWait { [unowned self] in
                for oldModel in oldModels {
                    // - Create new record if not found
                    if getRecord(entityName: GutmaLinkCD.entityName,
                                 flightUuid: oldModel.flightUuid,
                                 flightPlanUuid: oldModel.flightplanUuid) as? GutmaLinkCD == nil {
                        let modelCD = GutmaLinkCD(context: self.childContext)
                        modelCD.update(from: oldModel)
                        coreDataService.saveChildContext(childContext)
                    }

                    // - Delete old record
                    deleteOldRecord(for: oldModel._uuid, in: oldCDs)

                    didMigrateRecord?()
                }
            }
        }
        PictorLogger.shared.i(.tag, "💾🟢 Migrating gutma links")
    }

    /// Migrate old thumbnails.
    ///
    /// - Parameter didMigrateRecord: callback closure called when a record has been fully migrated (deleted in old database)
    func migrateThumbnails(_ didMigrateRecord: (() -> Void)?) {
        PictorLogger.shared.i(.tag, "💾🔵 Migrating thumbnails...")
        while let oldCDs = getFirstOldRecords(entityName: Thumbnail.entityName) as? [Thumbnail], !oldCDs.isEmpty {
            // - Migrate old record to pictor database
            coreDataOldService.writerBackgroundContext.performAndWait { [unowned self] in
                for oldCD in oldCDs {
                    do {
                        coreDataOldService.writerBackgroundContext.delete(oldCD)
                        try coreDataOldService.writerBackgroundContext.save()
                    } catch(let error) {
                        PictorLogger.shared.e(.tag, "💾🔴 Migrating thumbnails error: \(error)")
                    }

                    didMigrateRecord?()
                }
            }
        }
        PictorLogger.shared.i(.tag, "💾🟢 Migrating thumbnails")
    }
}
