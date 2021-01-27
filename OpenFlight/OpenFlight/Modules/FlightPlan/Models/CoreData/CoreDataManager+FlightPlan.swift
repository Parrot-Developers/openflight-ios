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
import GroundSdk
import CoreData

/// Helpers for Flight Plan data.
protocol FlightPlanDataProtocol {
    /// Returns all flight plan states.
    func loadAllFlightPlanViewModels(predicate: NSPredicate?) -> [FlightPlanViewModel]
    /// Removes flight plan regarding flight key.
    func removeFlightPlans(for key: [String])
    /// Provides flight plan object regarding key.
    func savedFlightPlan(for key: String) -> SavedFlightPlan?
    /// Persists flight plan file.
    func saveOrUpdate(state: FlightPlanState, flightPlan: SavedFlightPlan?)
    /// Returns last Flight Plan View Model.
    func loadLastFlightPlan(predicate: NSPredicate?) -> FlightPlanViewModel?
}

extension CoreDataManager: FlightPlanDataProtocol {
    /// Returns all flight plan view models.
    ///
    /// - Parameters:
    ///     - predicate: predicate used to filter Flight Plan if needed
    /// - Returns: All persisted Flight Plan States
    public func loadAllFlightPlanViewModels(predicate: NSPredicate?) -> [FlightPlanViewModel] {
        guard let managedContext = currentContext
            else {
                return []
        }
        // Sort flight plans by date.
        let fetchRequest: NSFetchRequest<FlightPlanModel> = FlightPlanModel.sortByDateRequest()
        if let predicate = predicate {
            fetchRequest.predicate = predicate
        }
        return (try? (managedContext.fetch(fetchRequest)))?
            .compactMap({ object -> FlightPlanViewModel in
                return FlightPlanViewModel(state: object.flightPlanState())
            }) ?? []
    }

    /// Returns all saved flight plans states.
    ///
    /// - Parameters:
    ///     - predicate: predicate used to filter flight plan if needed
    ///     - completion: All persisted flight plan states
    public func loadAllSavedFlightPlans(predicate: NSPredicate?,
                                        completion: ([FlightPlanState]) -> Void) {
        guard let managedContext = currentContext else {
            completion([])
            return
        }

        // Sort flight plans by date.
        let fetchRequest: NSFetchRequest<FlightPlanModel> = FlightPlanModel.sortByDateRequest()
        if let predicate = predicate {
            fetchRequest.predicate = predicate
        }

        managedContext.performAndWait {
            let results = (try? (managedContext.fetch(fetchRequest)))?
                .compactMap({ object -> FlightPlanState? in
                    return object.flightPlanState()
                }) ?? []
            completion(results)
        }
    }

    /// Persists flight plan file.
    ///
    /// - Parameters:
    ///     - state: flight plan state.
    ///     - flightPlan: optional flight plan.
    public func saveOrUpdate(state: FlightPlanState, flightPlan: SavedFlightPlan?) {
        // 1 - Prepare content to save.
        DispatchQueue.main.async {
            guard let managedContext = self.currentContext,
                let date = state.date,
                let uuid = state.uuid else {
                return
            }

            let longitude: Double = state.location?.longitude ?? 0.0
            let latitude: Double = state.location?.latitude ?? 0.0

            // 2 - Prepare core data context and entity.
            let fetchRequest: NSFetchRequest<FlightPlanModel> = FlightPlanModel.fetchRequest()
            guard let name = fetchRequest.entityName,
                let entity = NSEntityDescription.entity(forEntityName: name, in: managedContext)
                else {
                    return
            }

            fetchRequest.entity = entity
            let predicate = FlightPlanModel.fileKeyPredicate(sortValue: uuid)
            fetchRequest.predicate = predicate

            let flightData: NSManagedObject?

            // 3 - Check object if exists.
            if let object = try? (managedContext.fetch(fetchRequest)).first {
                // Use persisted object.
                flightData = object
                // Do not change
            } else {
                // Create new object.
                flightData = NSManagedObject(entity: entity, insertInto: managedContext)
            }
            guard let data = flightData as? FlightPlanModel else { return }

            // 4 - Write values in core data.
            data.setValue(date, forKeyPath: #keyPath(FlightPlanModel.date))
            data.setValue(state.lastModified, forKeyPath: #keyPath(FlightPlanModel.lastModified))
            data.setValue(uuid, forKeyPath: #keyPath(FlightPlanModel.uuid))
            data.setValue(longitude, forKeyPath: #keyPath(FlightPlanModel.longitude))
            data.setValue(latitude, forKeyPath: #keyPath(FlightPlanModel.latitude))
            data.setValue(state.type, forKeyPath: #keyPath(FlightPlanModel.type))

            if let title = state.title {
                data.setValue(title, forKeyPath: #keyPath(FlightPlanModel.title))
            }

            if let thumbnail = state.thumbnail,
                let imageData = thumbnail.pngData() {
                data.setValue(imageData, forKeyPath: #keyPath(FlightPlanModel.thumbnail))
            } else {
                data.setValue(nil, forKeyPath: #keyPath(FlightPlanModel.thumbnail))
            }

            if let flightPlanData = flightPlan?.asData {
                // Save full content.
                guard let name = (FlightPlanDataModel.fetchRequest() as NSFetchRequest<FlightPlanDataModel>).entityName,
                    let flightPlanDataEntity = NSEntityDescription.entity(forEntityName: name, in: managedContext)
                    else {
                        return
                }
                // Clean old data.
                if let oldData = data.flightPlanData {
                    managedContext.delete(oldData)
                }
                // Save new data.
                let dataObject = NSManagedObject(entity: flightPlanDataEntity, insertInto: managedContext)
                dataObject.setValue(data, forKeyPath: #keyPath(FlightPlanDataModel.flightPlan))
                dataObject.setValue(flightPlanData, forKeyPath: #keyPath(FlightPlanDataModel.flightPlanData))
                data.setValue(dataObject, forKey: #keyPath(FlightPlanModel.flightPlanData))
            }

            managedContext.performAndWait {
                DispatchQueue.main.async {
                    do {
                        try managedContext.save()
                    } catch let error {
                        print("Error saving flightplan \(String(describing: state.title)) with UUID \(uuid) => \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    /// Removes flight plans regarding keys.
    ///
    /// - Parameters:
    ///     - keys: flight plans keys to delete
    func removeFlightPlans(for keys: [String]) {
        guard let managedContext = currentContext else { return }

        // Remove flight plans
        let flightPlans = self.flightPlans(for: keys)
        flightPlans.forEach { model in
            if let flightPlanDataModel = model.flightPlanData {
                managedContext.delete(flightPlanDataModel)
            }
            managedContext.delete(model)
        }

        // Remove related executions.
        let relatedExecutions = self.executions(forFlightplanIds: keys)
        self.delete(executions: relatedExecutions)

        try? managedContext.save()
    }

    /// Returns flight plan states regarding keys.
    ///
    /// - Parameters:
    ///     - keys: flight plans keys
    func flightPlanStates(for keys: [String]) -> [FlightPlanState] {
        let flightPlanModels = self.flightPlans(for: keys)
        return flightPlanModels.map { $0.flightPlanState() }
    }

    /// Provides flight plan object regarding key.
    ///
    /// - Parameters:
    ///     - key: key to retrieve flightPlan
    /// - Returns: SavedFlightPlan object
    func savedFlightPlan(for key: String) -> SavedFlightPlan? {
        guard let flightPlanModel: FlightPlanModel = flightPlan(for: key),
            let flightPlanDataModel: FlightPlanDataModel = flightPlanModel.flightPlanData,
            let flightPlanData: Data = flightPlanDataModel.flightPlanData,
            let finalFlightPlan = flightPlanData.asFlightPlan() else {
                return nil
        }

        finalFlightPlan.lastModifiedDate = flightPlanModel.lastModified
        return finalFlightPlan
    }

    /// Provides last Flight Plan miew model.
    ///
    /// - Parameters:
    ///     - predicate: predicate used to filter Flight Plan if needed
    /// - Returns: Last persisted Flight Plan view model
    func loadLastFlightPlan(predicate: NSPredicate?) -> FlightPlanViewModel? {
        guard let managedContext = currentContext else { return nil }

        let fetchRequest: NSFetchRequest<FlightPlanModel> = FlightPlanModel.sortByDateRequest()

        if let predicate = predicate {
            fetchRequest.predicate = predicate
        }

        if let state = try? (managedContext.fetch(fetchRequest)).first?.flightPlanState() {
            return FlightPlanViewModel(state: state)
        } else {
            return nil
        }
    }
}

// MARK: - Private Funcs
private extension CoreDataManager {

    /// Returns flight plan regarding key.
    ///
    /// - Parameters:
    ///     - key: key to retrieve flight
    func flightPlan(for key: String?) -> FlightPlanModel? {
        guard let managedContext = currentContext,
            let key = key
            else {
                return nil
        }

        let fetchRequest: NSFetchRequest<FlightPlanModel> = FlightPlanModel.fetchRequest()
        let predicate = FlightPlanModel.fileKeyPredicate(sortValue: key)
        fetchRequest.predicate = predicate

        do {
            return try (managedContext.fetch(fetchRequest)).first
        } catch {
            return nil
        }
    }

    /// Returns flight plans regarding keys.
    ///
    /// - Parameters:
    ///     - keys: keys to retrieve flight plans
    func flightPlans(for keys: [String]) -> [FlightPlanModel] {
        guard let managedContext = currentContext
            else {
                return []
        }

        let fetchRequest: NSFetchRequest<FlightPlanModel> = FlightPlanModel.fetchRequest()
        let predicate = NSPredicate(format: "%K IN %@",
                                    #keyPath(FlightPlanModel.uuid),
                                    keys)
        fetchRequest.predicate = predicate

        do {
            return try (managedContext.fetch(fetchRequest))
        } catch {
            return []
        }
    }
}
