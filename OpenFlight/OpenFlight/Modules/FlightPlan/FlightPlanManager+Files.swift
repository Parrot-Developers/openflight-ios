// Copyright (C) 2020 Parrot Drones SAS
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
import SwiftyUserDefaults
import GroundSdk

extension FlightPlanManager {
    /// Load FlightPlan from json file.
    ///
    /// - Parameters:
    ///    - url: url for FlightPlan json file to load
    ///
    /// - Returns: `SavedFlightPlan` object if available, nil otherwise
    func loadFlightPlan(withURL url: URL) -> SavedFlightPlan? {
        guard let jsonData = try? Data(contentsOf: url)
            else {
                return nil
        }
        if url.pathExtension.lowercased() == FlightPlanConstants.mavlinkExtension,
           let flightPlan = MavlinkToFlightPlanParser.generateFlightPlanFromMavlinkStandard(url: url,
                                                                                            mavlinkString: nil,
                                                                                            title: url.deletingPathExtension().lastPathComponent,
                                                                                            type: nil,
                                                                                            uuid: nil,
                                                                                            settings: [],
                                                                                            polygonPoints: nil,
                                                                                            version: FlightPlanConstants.defaultFlightPlanVersion,
                                                                                            model: FlightPlanConstants.defaultDroneModel) {
            // Remove mavlink.
            try? FileManager.default.removeItem(at: url)
            // Save flight plan made with mavlink.
            let urlToSave = url
                .deletingPathExtension()
                .appendingPathExtension(FlightPlanConstants.jsonExtension)
            _ = saveFlightPlan(flightPlan, toURL: urlToSave)
            return flightPlan
        } else if url.pathExtension.lowercased() == FlightPlanConstants.jsonExtension {
            return try? jsonDecoder.decode(SavedFlightPlan.self, from: jsonData)
        } else {
            return nil
        }
    }

    /// Gets URLs of all json files inside Flight Plans directory.
    ///
    /// - Parameters:
    ///     - afterDate: filter flights after provided date. Default value means no filter.
    /// - Returns: array with all URLs
    func getAllFlightPlanURLs(afterDate: Date? = nil) -> [URL] {
        guard let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }
        let flightPlanDirectoryURL = documentsDirectoryURL.appendingPathComponent(FlightPlanConstants.flightPlanDirectory)
        let urls = try? FileManager.default.contentsOfDirectory(at: flightPlanDirectoryURL,
                                                                includingPropertiesForKeys: nil,
                                                                options: [])
        if urls?.isEmpty ?? true {
            // Returns demo flights.
            return demoContentURLs()
        } else if let date = afterDate,
            flightPlanDirectoryURL.fileModificationDate ?? Date() < date { // If folder has change (ex: remove case), return all.
            // Return only changed files.
            return urls?.filter({ $0.fileModificationDate ?? Date() > date }) ?? []
        } else {
            // Returns all flights.
            return urls ?? []
        }
    }

    /// Returns all Flight Plans.
    ///
    /// - Parameters:
    ///     - afterDate: filter flights after provided date. Default value means no filter.
    /// - Returns: Flight Plans array
    func loadAllFlightPlans(afterDate: Date? = nil) -> [SavedFlightPlan] {
        return getAllFlightPlanURLs(afterDate: afterDate)
            .compactMap { return loadFlightPlan(withURL: $0) }
    }

    /// Save FlightPlan to given file URL.
    ///
    /// - Parameters:
    ///    - flightPlan: FlightPlan to save
    ///    - url: destination file url for FlightPlan to save
    ///
    /// - Returns: `true` is operation succeeded, `false` otherwise
    func saveFlightPlan(_ flightPlan: SavedFlightPlan, toURL url: URL) -> Bool {
        guard let jsonData = try? jsonEncoder.encode(flightPlan) else { return false }

        // Create directory if it doesn't exist.
        let directoryURL = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }

        // Write json file.
        do {
            try jsonData.write(to: url)
        } catch {
            return false
        }
        return true
    }

    /// Synchronize persisted FlightPlans with File content.
    ///
    /// - Parameters:
    ///     - persistedFlightPlans: Persisted FlightPlanViewModel array
    ///     - completionHandler: Synchronized FlightPlanViewModel array
    func syncFlightPlansWithFiles(persistedFlightPlans: [FlightPlanViewModel],
                                  completionHandler: @escaping (_ result: Bool) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            // Update flight plan from documents directory
            // It could take long: do it in a background thread.
            let flightPlans = self?.loadAllFlightPlans(afterDate: Defaults.flightPlanLastSyncDate)
                .map({ plan -> FlightPlanViewModel in
                    if let existingFlightPlan = persistedFlightPlans
                        .first(where: { $0.state.value.uuid == plan.uuid }) {
                        // Update existing flight plan.
                        let state = existingFlightPlan.state.value.updated(flightPlan: plan)
                        existingFlightPlan.state.set(state)
                        existingFlightPlan.save()
                        return existingFlightPlan
                    } else {
                        // Create new flight plan.
                        let viewModel = FlightPlanViewModel(flightPlan: plan)
                        viewModel.save()
                        return viewModel
                    }
                }).sorted { (fp1, fp2) -> Bool in
                    // Sort flight plans by date.
                    fp1.state.value.date ?? Date() > fp2.state.value.date ?? Date()
                } ?? []

            if flightPlans.isEmpty == false {
                // Filter persisted flight plan(s) to remove.
                let uuidsToRemove = persistedFlightPlans
                    .compactMap({ $0.state.value.uuid })
                    .filter { uuid -> Bool in
                        flightPlans.contains(where: { $0.state.value.uuid == uuid }) == false
                }
                // Remove flight plans if needed.
                DispatchQueue.main.async {
                    CoreDataManager.shared.removeFlightPlans(for: uuidsToRemove)
                }
            }
            DispatchQueue.main.async {
                Defaults.flightPlanLastSyncDate = Date()
                completionHandler(true)
            }
        }
    }
}

// MARK: - Mavlink Helpers
extension FlightPlanManager {
    /// Generates MAVLink commands from given `SavedFlightPlan`.
    ///
    /// - Parameters:
    ///    - flightPlan: Flight Plan to generate to MAVLink
    /// - Returns: array of MAVLink commands
    func generateMavlinkCommands(for flightPlan: SavedFlightPlan) -> [MavlinkStandard.MavlinkCommand] {
        var commands = [MavlinkStandard.MavlinkCommand]()
        var currentSpeed: Double = 0.0
        var currentViewMode = MavlinkStandard.SetViewModeCommand.Mode.absolute
        var lastPoiIndex: Int = 0

        // Insert all POI commands
        flightPlan.plan.pois.forEach {
            commands.append($0.mavlinkCommand)
        }

        // Insert first speed command based on first waypoint speed.
        if let firstSpeedCommand = flightPlan.plan.wayPoints.first?.speedMavlinkCommand {
            commands.append(firstSpeedCommand)
            currentSpeed = firstSpeedCommand.speed
        }

        // Insert take off actions.
        flightPlan.plan.takeoffActions.forEach {
            commands.append($0.mavlinkCommand)
        }

        flightPlan.plan.wayPoints.forEach {
            let speed = $0.speedMavlinkCommand.speed
            if speed != currentSpeed {
                // Insert new speed command.
                commands.append($0.speedMavlinkCommand)
                currentSpeed = speed
            }

            // Insert navigate to waypoint command.
            commands.append($0.wayPointMavlinkCommand)

            let viewMode = $0.viewModeCommand.mode
            let poiIndex = $0.viewModeCommand.roiIndex

            if viewMode != currentViewMode || lastPoiIndex != poiIndex {
                // Insert new view mode command.
                commands.append($0.viewModeCommand)
                currentViewMode = viewMode
                lastPoiIndex = poiIndex
            }

            $0.actions?.forEach {
                guard !(currentViewMode == MavlinkStandard.SetViewModeCommand.Mode.roi && $0.type == .tilt) else { return } // No tilt during poi
                // Insert all waypoint actions commands.
                commands.append($0.mavlinkCommand)
            }
        }

        if let returnToLaunchCommand = flightPlan.plan.returnToLaunchCommand {
            // Insert return to launch command if FlightPlan is buckled.
            commands.append(returnToLaunchCommand)
        }

        return commands
    }
}
