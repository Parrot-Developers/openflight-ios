// Copyright (C) 2019 Parrot Drones SAS
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

/// Helpers for MyFlights.
public protocol MyFlightProtocol {
    /// Returns stored flight count.
    func flightCount() -> Int
    /// Returns last flight as `FlightDataViewModel`.
    func lastFlight() -> FlightDataViewModel?
    /// Update local flights with Gutma urls.
    func updateLocalFlights(newFiles: [URL])
    /// Load all flight states.
    func loadAllFlightDataState(completion: ([FlightDataState]) -> Void)
    /// Remove flight data regarding flight key.
    func removeFlight(for key: String?)
}

/// CoreDataManager flight helpers (implements `MyFlightProtocol`).
extension CoreDataManager: MyFlightProtocol {
    /// Load all flight states.
    ///
    /// - Parameters:
    ///     - completion: All persisted flight states
    public func loadAllFlightDataState(completion: ([FlightDataState]) -> Void) {
        guard let managedContext = currentContext else {
            completion([])
            return
        }
        // Sort flights by date.
        let fetchRequest: NSFetchRequest<FlightDataModel> = FlightDataModel.sortByDateRequest()

        managedContext.performAndWait {
            let results = (try? (managedContext.fetch(fetchRequest)))?
                .compactMap({ object -> FlightDataState in
                    return object.flightDataState()
                }) ?? []
            completion(results)
        }
    }

    /// Returns stored flight count.
    public func flightCount() -> Int {
        guard let managedContext = currentContext else {
            return 0
        }
        let fetchRequest: NSFetchRequest<FlightDataModel> = FlightDataModel.fetchRequest()
        do {
            return try managedContext.count(for: fetchRequest)
        } catch {
            return 0
        }
    }

    /// Returns last flight as `FlightDataViewModel`.
    public func lastFlight() -> FlightDataViewModel? {
        if let state = loadLastFlight() {
            return FlightDataViewModel(state: state)
        }
        return nil
    }

    /// Update local flights with Gutma urls.
    ///
    /// - Parameters:
    ///     - newFiles: file list
    public func updateLocalFlights(newFiles: [URL]) {
        for url in newFiles where isFileNotPersisted(with: url) {
            persistGutma(withURL: url)
        }
    }

    /// Persist flight file.
    ///
    /// - Parameters:
    ///     - state: flight data state values, used to have a quick look to the flight
    ///     - gutma: gutma json data, used at the initial persist
    public func saveOrUpdate(state: FlightDataState, gutma: Data? = nil) {
        DispatchQueue.main.async {
            guard let managedContext = self.currentContext,
                let date = state.date,
                let gutmaFileKey = state.gutmaFileKey else {
                    return
            }
            let longitude: Double = state.location?.coordinate.longitude ?? 0.0
            let latitude: Double = state.location?.coordinate.latitude ?? 0.0

            let fetchRequest: NSFetchRequest<FlightDataModel> = FlightDataModel.fetchRequest()
            guard let name = fetchRequest.entityName,
                let entity = NSEntityDescription.entity(forEntityName: name, in: managedContext)
                else {
                    return
            }
            fetchRequest.entity = entity
            let predicate = FlightDataModel.fileKeyPredicate(sortValue: gutmaFileKey)
            fetchRequest.predicate = predicate

            let flightData: NSManagedObject?
            do {
                // Check object if exists.
                if let object = try (managedContext.fetch(fetchRequest)).first {
                    // Use persisted object.
                    flightData = object
                } else {
                    // Create new object.
                    flightData = NSManagedObject(entity: entity, insertInto: managedContext)
                }
            } catch {
                flightData = NSManagedObject(entity: entity, insertInto: managedContext)
            }
            guard let data = flightData else { return }
            // Save state content.
            if let title = state.flightDescription {
                data.setValue(title, forKeyPath: #keyPath(FlightDataModel.title))
            }
            data.setValue(date, forKeyPath: #keyPath(FlightDataModel.date))
            data.setValue(gutmaFileKey, forKeyPath: #keyPath(FlightDataModel.gutmaFileKey))
            data.setValue(longitude, forKeyPath: #keyPath(FlightDataModel.longitude))
            data.setValue(latitude, forKeyPath: #keyPath(FlightDataModel.latitude))
            data.setValue(state.lastModified, forKey: #keyPath(FlightDataModel.lastModified))
            data.setValue(state.duration, forKeyPath: #keyPath(FlightDataModel.duration))
            data.setValue(state.distance, forKeyPath: #keyPath(FlightDataModel.distance))
            if let cloudStatus = state.cloudStatus {
                data.setValue(cloudStatus, forKeyPath: #keyPath(FlightDataModel.cloudStatus))
            }
            if let thumbnail = state.thumbnail,
                let imageData = thumbnail.pngData() {
                data.setValue(imageData, forKeyPath: #keyPath(FlightDataModel.thumbnail))
            }
            data.setValue(state.hasIssues, forKey: #keyPath(FlightDataModel.hasIssues))
            data.setValue(state.checked, forKey: #keyPath(FlightDataModel.checked))
            if let gutmaData = gutma {
                // If a gutma is already linked to the flight.
                if let flightGutma = data.value(forKey: #keyPath(FlightDataModel.gutma)) as? GutmaDataModel {
                    // Update the gutma in local database.
                    flightGutma.setValue(gutmaData, forKey: #keyPath(GutmaDataModel.gutmaFile))
                } else {
                    // Create new gutma in local database.
                    guard let name = (GutmaDataModel.fetchRequest() as NSFetchRequest<GutmaDataModel>).entityName,
                        let gutmaEntity = NSEntityDescription.entity(forEntityName: name, in: managedContext) else {
                            return
                    }

                    let gutmaObject = NSManagedObject(entity: gutmaEntity, insertInto: managedContext)
                    gutmaObject.setValue(data, forKeyPath: #keyPath(GutmaDataModel.flightData))
                    gutmaObject.setValue(gutmaData, forKeyPath: #keyPath(GutmaDataModel.gutmaFile))
                    data.setValue(gutmaObject, forKey: #keyPath(FlightDataModel.gutma))
                }
            }

            managedContext.performAndWait {
                DispatchQueue.main.async {
                    do {
                        try managedContext.save()
                    } catch let error {
                        print("""
                            Error saving flight \(String(describing: state.flightLocationDescription))
                            with GutmaFileKey \(String(describing: state.gutmaFileKey))
                            => \(error.localizedDescription)
                            """)
                    }
                }
            }
        }
    }

    /// Remove flight data regarding flight key.
    ///
    /// - Parameters:
    ///     - key: key to retrieve flight
    public func removeFlight(for key: String?) {
        guard let key = key, let managedContext = currentContext else {
            return
        }
        if let flight = flight(for: key) {
            if let gutma = flight.gutma {
                managedContext.delete(gutma)
            }
            managedContext.delete(flight)
            try? managedContext.save()
        }
    }

    /// Provides Gutma object regarding key.
    ///
    /// - Parameters:
    ///     - key: key to retrieve gutma
    /// - Returns: Gutma object
    func gutma(for key: String) -> Gutma? {
        return flight(for: key)?.loadGutma()
    }
}

// MARK: - Private Funcs

private extension CoreDataManager {
    /// Persists Gutma from json file.
    ///
    /// - Parameters:
    ///    - url: url for Gutma json file to load
    func persistGutma(withURL url: URL) {
        if let jsonData = try? Data(contentsOf: url) {
            guard let gutma = jsonData.asGutma() else { return }
            // FIXME: hack for non-up to date drones. To be removed
            if gutma.flightId?.isEmpty ?? true {
                gutma.exchange?.message?.flightData?.flightID = url.lastPathComponent
            }
            let state = FlightDataState(gutmaData: gutma)
            saveOrUpdate(state: state, gutma: jsonData)
        }
    }

    /// Returns flight data regarding key.
    ///
    /// - Parameters:
    ///     - key: key to retrieve flight
    func flight(for key: String?) -> FlightDataModel? {
        guard let managedContext = currentContext, let key = key else {
            return nil
        }

        let fetchRequest: NSFetchRequest<FlightDataModel> = FlightDataModel.fetchRequest()
        let predicate = FlightDataModel.fileKeyPredicate(sortValue: key)
        fetchRequest.predicate = predicate

        do {
            return try (managedContext.fetch(fetchRequest)).first
        } catch {
            return nil
        }
    }

    /// Returns true if the file is not persisted.
    ///
    /// - Parameters:
    ///     - fileUrl: file url
    func isFileNotPersisted(with fileUrl: URL?) -> Bool {
        guard let key = fileUrl?.lastPathComponent else { return true }
        return flight(for: key) == nil
    }

    /// Returns last flight.
    func loadLastFlight() -> FlightDataState? {
        guard let managedContext = currentContext else { return nil }
        let fetchRequest: NSFetchRequest<FlightDataModel> = FlightDataModel.sortByDateRequest()
        return try? (managedContext.fetch(fetchRequest)).first?.flightDataState()
    }
}
