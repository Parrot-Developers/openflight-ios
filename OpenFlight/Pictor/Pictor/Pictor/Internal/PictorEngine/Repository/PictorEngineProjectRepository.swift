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
import CoreData

fileprivate extension String {
    static let tag = "pictor.engine.repository.project"
}

// MARK: - Protocol
protocol PictorEngineBaseProjectRepository: PictorEngineBaseRepository where PictorEngineModelType == PictorEngineProjectModel {
    /// Get odd projects with empty flight plans, or multiple editable flight plans, or no editable flightplans
    ///
    /// - Parameters:
    ///    - pictorContext: PIctorContext to fetch
    /// - Returns: list of `PictorEngineProjectModel`
    func getOdds(in pictorContext: PictorContext) -> [PictorEngineProjectModel]

    /// Get odd projects with empty flight plans, or multiple editable flight plans, or no editable flightplans
    ///
    /// - Parameters:
    ///    - completion: callback closure called when finished
    func getOdds(in pictorContext: PictorContext, completion: @escaping ((Result<[PictorEngineProjectModel], PictorEngineError>) -> Void))
}

// MARK: - Implementation
class PictorEngineProjectRepository: PictorEngineRepository<PictorEngineProjectModel>, PictorEngineBaseProjectRepository  {
    // MARK: Override PictorEngineBaseRepository
    override var entityName: String { ProjectCD.entityName }

    // MARK: Pictor Engine Base Project Repository Protocol
    func getOdds(in pictorContext: PictorContext) -> [PictorEngineProjectModel] {
        var result: [PictorEngineProjectModel] = []

        pictorContext.performAndWait { [unowned self] contextCD in
            if case let .success(models) = self.getOdds(contextCD: contextCD) {
                result = models
            }
        }

        return result
    }

    func getOdds(in pictorContext: PictorContext, completion: @escaping ((Result<[PictorEngineProjectModel], PictorEngineError>) -> Void)) {
        pictorContext.perform { [unowned self] contextCD in
            completion(self.getOdds(contextCD: contextCD))
        }
    }

    override func convertToModel(_ record: PictorEngineManagedObject, context: NSManagedObjectContext) -> PictorEngineProjectModel? {
        guard let record = record as? ProjectCD else {
            PictorLogger.shared.e(.tag, "❌💾🗂 Bad managed object of \(entityName)")
            return nil
        }

        let flightPlans = (try? repositories.flightPlan.get(contextCD: context, byProjectUuid: record.uuid).get()) ?? []
        let editableFlightPlan = flightPlans.first { $0.flightPlanModel.state == .editable }?.flightPlanModel
        let latestExecutedFlightPlan = flightPlans
            .filter { $0.flightPlanModel.hasReachedFirstWaypoint == true }
            .sorted { $0.flightPlanModel.lastUpdated > $1.flightPlanModel.lastUpdated }
            .first?.flightPlanModel
        let model = PictorProjectModel(record: record,
                                       editableFlightPlan: editableFlightPlan,
                                       latestExecutedFlightPlan: latestExecutedFlightPlan)
        return PictorEngineProjectModel(model: model, record: record)
    }
}

private extension PictorEngineProjectRepository {
    private func getOdds(contextCD: NSManagedObjectContext) -> Result<[PictorEngineProjectModel], PictorEngineError> {
        do {
            let editableState = PictorFlightPlanModel.State.editable.rawValue
            let projectsRequest = ProjectCD.fetchRequest()
            let projects = try contextCD.fetch(projectsRequest)
                .filter({ project in
                    let editablesRequest = FlightPlanCD.fetchRequest()
                    editablesRequest.predicate = NSPredicate(format: "projectUuid == %@ AND state == %@", project.uuid, editableState)
                    return try contextCD.count(for: editablesRequest) != 1
                })
            let models = projects.compactMap { self.convertToModel($0, context: contextCD) }
            return .success(models)
        } catch let error {
            return .failure(.fetchError(error))
        }
    }
}
