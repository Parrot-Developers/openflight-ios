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
import Combine
import GroundSdk
import Pictor
import KeychainAccess
import SwiftyUserDefaults

extension ULogTag {
    static let databaseUpdate = ULogTag(name: "databaseUpdate")
}

private protocol ThumbnailGeneratorServiceMigration {
    /// Refreshes all thumbnail.
    func generateAllThumbnails()
}

extension ThumbnailGeneratorServiceImpl: ThumbnailGeneratorServiceMigration {
    func generateAllThumbnails() {
        refreshAllThumbnail()
    }
}

// MARK: - Service Protocol
public protocol DatabaseUpdateService {
    /// Check if database needs to be updated.
    func checkForUpdate()

    /// Start database migration.
    /// - Parameters:
    ///     - progress: closure called for progression
    /// - Description:
    /// Migrate all records from old database to new.
    func startUpdate(_ progress: @escaping (_ totalCount: Int, _ updatedCount: Int) -> Void)
}

// MARK: - Implementation
final class DatabaseUpdateServiceImpl: DatabaseUpdateService {
    private enum Constants {
        static let userService = "userService"
        static let apcId = "apcId"
    }
    private var keychain: Keychain

    private var isDatabaseUpdating: Bool = false
    private var isDatabaseUpdateNeeded: Bool = false

    // - Properties
    private let repositories: Repositories!
    private let userService: PictorUserService!
    private let synchroService: SynchroService!
    private let databaseMigrationService: PictorDatabaseMigrationService!
    private let thumbnailGeneratorService: ThumbnailGeneratorService!
    private var cancellables: Set<AnyCancellable> = []

    // MARK: __ Init
    init(repositories: Repositories,
         userService: PictorUserService,
         synchroService: SynchroService,
         databaseMigrationService: PictorDatabaseMigrationService,
         thumbnailGeneratorService: ThumbnailGeneratorService) {
        self.repositories = repositories
        self.keychain = Keychain(service: Constants.userService)
        self.userService = userService
        self.synchroService = synchroService
        self.databaseMigrationService = databaseMigrationService
        self.thumbnailGeneratorService = thumbnailGeneratorService

        // - Update Flight Plans with obsolete version during synchro multi-session
        repositories.flightPlan.didCreatePublisher
            .combineLatest(synchroService.statusPublisher)
            .sink { uuids, synchroStatus in
                guard case .syncing(let step) = synchroStatus, step == .multiSession else {
                    return
                }
                let obsoleteFlightPlans = repositories.flightPlan.get(byUuids: uuids).filter { !$0.hasLatestFormatVersion }

                if !obsoleteFlightPlans.isEmpty {
                    var flightPlanModels: [FlightPlanModel] = []
                    let uuids = obsoleteFlightPlans.compactMap { $0.uuid }
                    ULog.i(.databaseUpdate, "Found obsolete FlightPlans to update to latest version during synchro \(uuids.joined(separator: ", "))")

                    obsoleteFlightPlans.forEach {
                        var flightPlanModel = $0.flightPlanModel
                        flightPlanModel.updateToLatestVersionIfNeeded()
                        flightPlanModels.append(flightPlanModel)
                    }

                    let pictorContext = PictorContext.new()
                    pictorContext.update(flightPlanModels.compactMap { $0.pictorModel })
                    pictorContext.commit()
                }
            }.store(in: &cancellables)

        userService.userEventPublisher
            .sink { [unowned self] userEvent in
                switch userEvent {
                case .didCreateAccount, .didLogin:
                    checkForUpdate()
                default:
                    break
                }
            }.store(in: &cancellables)
    }
}

// MARK: - Database Update Service Protocol
extension DatabaseUpdateServiceImpl {
    public func checkForUpdate() {
        guard !isDatabaseUpdating else {
            ULog.i(.databaseUpdate, "Check for update not available: database is updating...")
            return
        }
        if databaseMigrationService.getOldRecordsCount() > 0
            || repositories.flightPlan.count(formatVersions: FlightPlanModelVersion.obsoletes) > 0 {
            isDatabaseUpdateNeeded = true
            ULog.i(.databaseUpdate, "Check for update: database migration needed")
        }

        if isDatabaseUpdateNeeded {
            ULog.i(.databaseUpdate, "Check for update needed: display update page...")
            synchroService.isEnabled = false
            DispatchQueue.main.async {
                self.displayDatabaseUpdatePopUpController()
            }
        } else {
            synchroService.isEnabled = true
            ULog.i(.databaseUpdate, "Check for update: not needed")
        }
    }

    public func startUpdate(_ progress: @escaping (_ totalCount: Int, _ updatedCount: Int) -> Void) {
        ULog.i(.databaseUpdate, "=== Database update ===")
        guard !isDatabaseUpdating else {
            ULog.i(.databaseUpdate, "Database update is already running")
            return
        }

        isDatabaseUpdating = true
        synchroService.isEnabled = false
        Task {
            let obsoleteFlightPlanCount = repositories.flightPlan.count(formatVersions: FlightPlanModelVersion.obsoletes)
            let oldRecordCount = databaseMigrationService.getOldRecordsCount()
            let totalCount = oldRecordCount + obsoleteFlightPlanCount
            var updatedCount = 0

            progress(totalCount, updatedCount)

            if oldRecordCount > 0 {
                databaseMigrationService.start(oldSessionData: getOldSessionData(),
                                               didSaveFlightPlan: { pictorFlightPlan in
                    if !pictorFlightPlan.hasLatestFormatVersion {
                        var flightPlan = pictorFlightPlan.flightPlanModel
                        flightPlan.updateToLatestVersionIfNeeded()
                        let pictorContext = PictorContext.new()
                        pictorContext.update([flightPlan.pictorModel])
                        pictorContext.commit()
                    }
                }, progress: { total, updated in
                    progress(totalCount, updatedCount + updated)
                    if updated >= total {
                        updatedCount += total
                    }
                })
            }

            if obsoleteFlightPlanCount > 0 {
                updateObsoleteFlightPlans({ total, updated in
                    progress(totalCount, updatedCount + updated)
                    if updated >= total {
                        updatedCount += total
                    }
                })
            }

            isDatabaseUpdating = false
            isDatabaseUpdateNeeded = false
            synchroService.isEnabled = true
            if userService.currentUser.isAnonymous {
                (self.thumbnailGeneratorService as? ThumbnailGeneratorServiceMigration)?.generateAllThumbnails()
            }
        }
    }
}

// MARK: - Private
private extension DatabaseUpdateServiceImpl {
    func displayDatabaseUpdatePopUpController() {
        let viewModel = FlightPlanVersionUpgraderViewModel(databaseUpdateService: self)
        let viewController = FlightPlanVersionUpgraderViewController.instantiate(viewModel: viewModel)
        viewController.modalPresentationStyle = .fullScreen
        UIApplication.topViewController()?.navigationController?.present(viewController, animated: true)
    }

    func getOldSessionData() -> OldSessionData {
        OldSessionData(oldApcId: keychain.get(Constants.apcId),
                       msLatestBgDate: Defaults.latestBackgroundSynchroMultiSessionDate,
                       msLatestSuccessfulDate: Defaults.latestSuccessfulSynchroMultiSessionDate,
                       msLatestTriedDate: Defaults.latestTriedSynchroMultiSessionDate,
                       msLatestFlightPlanCloudDeletionDate: Defaults.latestFlightPlanCloudDeletionDate,
                       msLatestFlightPlanDate: Defaults.latestFlightPlanSynchroDate,
                       msLatestGutmaCloudDeletionDate: Defaults.latestGutmaCloudDeletionDate,
                       msLatestGutmaDate: Defaults.latestGutmaSynchroDate,
                       msLatestProjectCloudDeletionDate: Defaults.latestProjectCloudDeletionDate,
                       msLatestProjectDate: Defaults.latestProjectSynchroDate,
                       incShouldLaunch: Defaults.shouldLaunchSynchroIncremental,
                       scLatestSuccessfulDate: Defaults.latestSuccessfulSanityCheckDate,
                       scLatestTriedDate: Defaults.latestTriedSanityCheckDate,
                       scSkip: Defaults.skipSanityCheck)
    }

    private func updateObsoleteFlightPlans(_ progress: @escaping (_ totalCount: Int, _ updatedCount: Int) -> Void) {
        let flightPlans = repositories.flightPlan.get(formatVersions: FlightPlanModelVersion.obsoletes)
        guard !flightPlans.isEmpty else {
            ULog.i(.databaseUpdate, "Obsolete flight plans not found")
            DispatchQueue.main.async {
                progress(0, 0)
            }
            return
        }

        let toUpdateCount = flightPlans.count
        var updatedFlightPlans: [FlightPlanModel] = []

        ULog.i(.databaseUpdate, "\(toUpdateCount) obsolete flight plans to update")
        flightPlans.forEach {
            var flightPlan = $0.flightPlanModel
            flightPlan.updateToLatestVersionIfNeeded()
            updatedFlightPlans.append(flightPlan)
            let updatedFlightPlanCount = updatedFlightPlans.count
            DispatchQueue.main.async {
                progress(toUpdateCount, updatedFlightPlanCount)
            }
        }

        let pictorFlightPlans = updatedFlightPlans.compactMap { $0.pictorModel }
        let pictorContext = PictorContext.new()
        pictorContext.update(pictorFlightPlans)
        pictorContext.commit()

        let updatedFlightPlanCount = updatedFlightPlans.count
        DispatchQueue.main.async {
            progress(updatedFlightPlanCount, updatedFlightPlanCount)
        }
    }
}
