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

extension ULogTag {
    static let databaseUpdate = ULogTag(name: "databaseUpdate")
}

// MARK: -
// MARK: - Service Protocol
public protocol DatabaseUpdateService {
    /// Boolean to know if database needs to updated
    var isDatabaseUpdateNeeded: Bool { get }
    var isDatabaseUpdateNeededPublisher: AnyPublisher<Bool, Never> { get }

    /// Publisher when database has finished updating
    var databaseUpdatedPublisher: AnyPublisher<Void, Never> { get }

    /// Check for obsolete fight plans in database
    func checkForObsoleteFlightPlans()

    /// Update flight plans with obsolete version to the latest version
    /// - Parameters:
    ///     - completion: closure called when finished
    /// - Description:
    /// Update in the persistent store flight plans with version considered obsolete in FlightPlanModelVersion.obsoletes
    func updateObsoleteFlightPlans(progress: ((_ totalCount: Int, _ updatedCount: Int) -> Void)?, completion: @escaping ((_ status: Bool) -> Void))

    func displayDatabaseUpdatePopUpController()
}

// MARK: -
// MARK: - Implementation
final class DatabaseUpdateServiceImpl: DatabaseUpdateService {
    var isDatabaseUpdateNeeded: Bool { isDatabaseUpdateNeededSubject.value }
    var isDatabaseUpdateNeededPublisher: AnyPublisher<Bool, Never> { isDatabaseUpdateNeededSubject.eraseToAnyPublisher() }
    internal let isDatabaseUpdateNeededSubject = CurrentValueSubject<Bool, Never>(false)

    var databaseUpdatedPublisher: AnyPublisher<Void, Never> { databaseUpdatedSubject.eraseToAnyPublisher() }
    internal let databaseUpdatedSubject = PassthroughSubject<Void, Never>()

    private var isDatabaseUpdating: Bool = false

    // - Properties
    private let repositories: Repositories!

    // MARK: __ Init
    init(repositories: Repositories) {
        self.repositories = repositories
    }
}

extension DatabaseUpdateServiceImpl {
    public func checkForObsoleteFlightPlans() {
        guard !isDatabaseUpdating else {
            ULog.i(.databaseUpdate, "Check for obsolete flight plans not available: database is updating...")
            return
        }
        isDatabaseUpdateNeededSubject.value = repositories.flightPlan.getFlightPlansCount(withVersions: FlightPlanModelVersion.obsoletes) > 0
        ULog.i(.databaseUpdate, "Check for obsolete flight plans to be updated if any: \(isDatabaseUpdateNeeded)")
        if isDatabaseUpdateNeeded {
            displayDatabaseUpdatePopUpController()
        }
    }

    public func updateObsoleteFlightPlans(progress: ((_ totalCount: Int, _ updatedCount: Int) -> Void)?,
                                          completion: @escaping ((_ status: Bool) -> Void)) {
        ULog.i(.databaseUpdate, "=== Update obsolete flight plans with version [\(FlightPlanModelVersion.obsoletes.joined(separator: ", "))] ===")
        guard !isDatabaseUpdating else {
            ULog.i(.databaseUpdate, "Database is already updating obsolete flight plans")
            return
        }
        isDatabaseUpdating = true
        repositories.flightPlan.getFlightPlans(withVersions: FlightPlanModelVersion.obsoletes) { [unowned self] flightPlans in
            guard !flightPlans.isEmpty else {
                ULog.i(.databaseUpdate, "Obsolete flight plans not found")
                isDatabaseUpdateNeededSubject.value = false
                isDatabaseUpdating = false
                databaseUpdatedSubject.send()
                completion(true)
                return
            }

            let toUpdateCount = flightPlans.count
            var updatedFlightPlans: [FlightPlanModel] = []

            ULog.i(.databaseUpdate, "\(toUpdateCount) obsolete flight plans to update")
            flightPlans.forEach {
                var flightPlan = $0
                flightPlan.updateToLatestVersionIfNeeded()
                updatedFlightPlans.append(flightPlan)
                progress?(toUpdateCount, updatedFlightPlans.count)
            }

            repositories.flightPlan.saveOrUpdateFlightPlans(
                updatedFlightPlans,
                byUserUpdate: true,
                toSynchro: true,
                withFileUploadNeeded: true,
                completion: { [unowned self] status in
                    ULog.i(.databaseUpdate, "\(toUpdateCount) obsolete flight plans updated to latest version with status: \(status)")
                    isDatabaseUpdateNeededSubject.value = false
                    isDatabaseUpdating = false
                    databaseUpdatedSubject.send()
                    completion(status)
                })
        }
    }

    public func displayDatabaseUpdatePopUpController() {
        let viewModel = FlightPlanVersionUpgraderViewModel(databaseUpdateService: self)
        let viewController = FlightPlanVersionUpgraderViewController.instantiate(viewModel: viewModel)
        UIApplication.topViewController()?.navigationController?.present(viewController, animated: true)
    }
}
