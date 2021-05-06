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
    ///     - execution: flight plan execution
    ///     - isFromRun: Saved from a run or not
    public func saveOrUpdate(execution: FlightPlanExecution, isFromRun: Bool = false) {
        // 1 - Prepare content to save.
        guard let managedContext = currentContext else { return }

        // 2 - Prepare core data context and entity.
        let fetchRequest: NSFetchRequest<FlightPlanExecutionDataModel> = FlightPlanExecutionDataModel.fetchRequest()
        guard let name = fetchRequest.entityName,
              let entity = NSEntityDescription.entity(forEntityName: name, in: managedContext)
        else {
            return
        }

        fetchRequest.entity = entity
        let predicate = FlightPlanExecutionDataModel.fileKeyPredicate(sortValue: execution.executionId)
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

        // Merge old settings with new settings to avoid losing some settings.
        var finalSettings: [FlightPlanLightSetting] = []

        if let oldSettings = data.lightSettings,
           !oldSettings.isEmpty {
            finalSettings = oldSettings

            for newSetting in execution.settings ?? [] {
                if let index = oldSettings.firstIndex(where: { $0.key == newSetting.key }) {
                    finalSettings[index] = newSetting
                } else {
                    finalSettings.append(newSetting)
                }
            }
        } else {
            finalSettings = execution.settings ?? []
        }

        execution.settings = finalSettings

        if execution.state == .initialized, isFromRun == false {
            // State should not be nil (ex: sync from server)
            // except if a execution has just been started.
            execution.state = .error
        }

        data.setValue(execution.startDate, forKeyPath: #keyPath(FlightPlanExecutionDataModel.startDate))
        data.setValue(execution.endDate, forKeyPath: #keyPath(FlightPlanExecutionDataModel.endDate))
        data.setValue(execution.flightId, forKeyPath: #keyPath(FlightPlanExecutionDataModel.flightId))
        data.setValue(execution.flightPlanId, forKeyPath: #keyPath(FlightPlanExecutionDataModel.flightPlanId))
        data.setValue(execution.executionId, forKeyPath: #keyPath(FlightPlanExecutionDataModel.executionId))
        data.setValue(execution.endDate, forKeyPath: #keyPath(FlightPlanExecutionDataModel.endDate))
        data.setValue(execution.state.rawValue, forKeyPath: #keyPath(FlightPlanExecutionDataModel.state))
        data.setValue(execution.settingsForPersistance, forKeyPath: #keyPath(FlightPlanExecutionDataModel.settings))
        data.setValue(execution.latestItemExecutedForPersistance, forKeyPath: #keyPath(FlightPlanExecutionDataModel.latestItemExecuted))
        data.setValue(execution.flightPlanRecoveryId, forKeyPath: #keyPath(FlightPlanExecutionDataModel.flightPlanRecoveryId))

        managedContext.performAndWait {
            try? managedContext.save()
        }
    }

    /// Deletes flight plan executions.
    ///
    /// - Parameters:
    ///     - execution: flight plan execution
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
    ///     - forFlightplanId: flight plan id
    /// - Returns: Flight plan executions.
    func executions(forFlightplanIds: [String]) -> [FlightPlanExecution] {
        return executions(key: #keyPath(FlightPlanExecutionDataModel.flightPlanId),
                          values: forFlightplanIds)
    }

    /// Returns flight plan's executions related to a flight.
    ///
    /// - Parameters:
    ///     - forFlightId: flight id
    /// - Returns: Flight plan executions.
    func executions(forFlightId: String) -> [FlightPlanExecution] {
        return executions(key: #keyPath(FlightPlanExecutionDataModel.flightId),
                          values: [forFlightId])
    }

    /// Returns flight plan's execution related to an execution id.
    ///
    /// - Parameters:
    ///     - forExecutionId: execution id
    /// - Returns: Flight plan execution.
    public func execution(forExecutionId: String) -> FlightPlanExecution? {
        return executions(key: #keyPath(FlightPlanExecutionDataModel.executionId),
                          values: [forExecutionId]).first
    }

    /// Returns flight plan's executions related to a recovery id.
    ///
    /// - Parameters:
    ///     - forRecoveryId: recovery id
    /// - Returns: Flight plan execution.
    public func executions(forRecoveryId: String) -> [FlightPlanExecution] {
        return executions(key: #keyPath(FlightPlanExecutionDataModel.flightPlanRecoveryId),
                          values: [forRecoveryId])
    }
}

// MARK: - Private Funcs
private extension CoreDataManager {
    /// Returns flight plans's executions regarding key/value, sorted by start date.
    ///
    /// - Parameters:
    ///     - key: key
    ///     - values: values
    /// - Returns: Flight plan execution.
    func executions(key: String, values: [String]) -> [FlightPlanExecution] {
        guard let managedContext = currentContext else { return [] }

        let fetchRequest: NSFetchRequest<FlightPlanExecutionDataModel> = FlightPlanExecutionDataModel.fetchRequest()
        let predicate = NSPredicate(format: "%K IN %@", key, values)
        let sort = NSSortDescriptor(key: #keyPath(FlightPlanExecutionDataModel.startDate), ascending: false)
        fetchRequest.sortDescriptors = [sort]
        fetchRequest.predicate = predicate

        do {
            let executionDataModels = try (managedContext.fetch(fetchRequest))
            return executionDataModels.map { $0.asFlightPlanExecution }
        } catch {
            return []
        }
    }

    /// Returns flight plan executions.
    ///
    /// - Parameters:
    ///     - keys: flight plan execution ids
    /// - Returns: Flight plan execution data models.
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
