//
//  Copyright (C) 2020 Parrot Drones SAS.
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

/// CoreDataManager Flight plan execution utilities.
extension CoreDataManager {
    /// Persists flight plan execution.
    ///
    /// - Parameters:
    ///     - execution: flight plan execution.
    public func saveOrUpdate(execution: FlightPlanExecution) {
        // 1 - Prepare content to save.
        guard let managedContext = currentContext,
              let executionId = execution.executionId else { return }

        // 2 - Prepare core data context and entity.
        let fetchRequest: NSFetchRequest<FlightPlanExecutionDataModel> = FlightPlanExecutionDataModel.fetchRequest()
        guard let name = fetchRequest.entityName,
              let entity = NSEntityDescription.entity(forEntityName: name, in: managedContext)
        else {
            return
        }

        fetchRequest.entity = entity
        let predicate = FlightPlanExecutionDataModel.fileKeyPredicate(sortValue: executionId)
        fetchRequest.predicate = predicate

        let executionData: NSManagedObject?

        // 3 - Check object if exists.
        if let object = try? (managedContext.fetch(fetchRequest)).first {
            // Use persisted object.
            executionData = object
            // Do not change
        } else {
            // Create new object.
            executionData = NSManagedObject(entity: entity, insertInto: managedContext)
        }

        // 4 - Write values in core data.
        guard let data = executionData as? FlightPlanExecutionDataModel else { return }

        data.setValue(execution.startDate, forKeyPath: #keyPath(FlightPlanExecutionDataModel.startDate))
        data.setValue(execution.endDate, forKeyPath: #keyPath(FlightPlanExecutionDataModel.endDate))
        data.setValue(execution.flightId, forKeyPath: #keyPath(FlightPlanExecutionDataModel.flightId))
        data.setValue(execution.flightPlanId, forKeyPath: #keyPath(FlightPlanExecutionDataModel.flightPlanId))
        data.setValue(execution.executionId, forKeyPath: #keyPath(FlightPlanExecutionDataModel.executionId))
        data.setValue(execution.endDate, forKeyPath: #keyPath(FlightPlanExecutionDataModel.endDate))
        data.setValue(execution.projectIdForPersistance, forKeyPath: #keyPath(FlightPlanExecutionDataModel.projectId))
        data.setValue(execution.stateForPersistance, forKeyPath: #keyPath(FlightPlanExecutionDataModel.state))
        data.setValue(execution.settingsForPersistance, forKeyPath: #keyPath(FlightPlanExecutionDataModel.settings))

        managedContext.performAndWait {
            do {
                try managedContext.save()
            } catch let error {
                print("Error saving execution with id \(executionId) => \(error.localizedDescription)")
            }
        }
    }

    /// Deletes flight plan executions.
    ///
    /// - Parameters:
    ///     - execution: flight plan execution.
    func delete(executions: [FlightPlanExecution]) {
        guard let managedContext = currentContext else { return }

        let keys = executions.compactMap { $0.executionId }

        let executions = self.executions(for: keys)
        executions.forEach { model in
            managedContext.delete(model)
        }
        try? managedContext.save()
    }

    /// Returns flight plan's executions related to a flight plan.
    ///
    /// - Parameters:
    ///     - forFlightplanId: flight plan id.
    func executions(forFlightplanIds: [String]) -> [FlightPlanExecution] {
        return executions(key: #keyPath(FlightPlanExecutionDataModel.flightPlanId),
                          values: forFlightplanIds)
    }

    /// Returns flight plan's executions related to a flight.
    ///
    /// - Parameters:
    ///     - forFlightId: flight id.
    func executions(forFlightId: String) -> [FlightPlanExecution] {
        return executions(key: #keyPath(FlightPlanExecutionDataModel.flightId),
                          values: [forFlightId])
    }
}

// MARK: - Private Funcs
private extension CoreDataManager {
    /// Returns flight plans's executions regarding key/value.
    ///
    /// - Parameters:
    ///     - key: key.
    ///     - values: values.
    func executions(key: String, values: [String]) -> [FlightPlanExecution] {
        guard let managedContext = currentContext else { return [] }

        let fetchRequest: NSFetchRequest<FlightPlanExecutionDataModel> = FlightPlanExecutionDataModel.fetchRequest()
        let predicate = NSPredicate(format: "%K IN %@", key, values)
        fetchRequest.predicate = predicate

        do {
            let executionDataModels = try (managedContext.fetch(fetchRequest))
            return executionDataModels.map { $0.asFlightPlanExecution }
        } catch {
            return []
        }
    }

    /// Returns flight plan executions
    ///
    /// - Parameters:
    ///     - keys: flight plan execution ids.
    func executions(for keys: [String]) -> [FlightPlanExecutionDataModel] {
        guard let managedContext = currentContext else { return [] }

        let fetchRequest: NSFetchRequest<FlightPlanExecutionDataModel> = FlightPlanExecutionDataModel.fetchRequest()
        let predicate = NSPredicate(format: "%K IN %@",
                                    #keyPath(FlightPlanExecutionDataModel.executionId),
                                    keys)
        fetchRequest.predicate = predicate

        do {
            return try (managedContext.fetch(fetchRequest))
        } catch {
            return []
        }
    }
}
