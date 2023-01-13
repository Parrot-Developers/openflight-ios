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
import GroundSdk

struct FlightPlanTestModel: Codable {
    var uuid: String
    var type: String
    var dataSetting: FlightPlanDataSetting?

    func flightPlanModel() -> FlightPlanModel {
        var fpm = FlightPlanModel(apcId: "", type: type, uuid: uuid,
                                  version: "", customTitle: "", thumbnailUuid: nil,
                                  projectUuid: "", dataStringType: "",
                                  dataString: nil, pgyProjectId: nil,
                                  state: .unknown, lastMissionItemExecuted: nil,
                                  mediaCount: nil, uploadedMediaCount: nil,
                                  lastUpdate: Date(), synchroStatus: nil,
                                  fileSynchroStatus: 0, fileSynchroDate: nil,
                                  latestSynchroStatusDate: nil, cloudId: nil,
                                  parrotCloudUploadUrl: nil, isLocalDeleted: false,
                                  latestCloudModificationDate: nil,
                                  uploadAttemptCount: nil, lastUploadAttempt: nil,
                                  thumbnail: nil, flightPlanFlights: nil,
                                  latestLocalModificationDate: nil,
                                  synchroError: nil)
        var dataSetting = self.dataSetting
        dataSetting?.mavlinkDataFile = nil
        fpm.dataSetting = dataSetting
        return fpm
    }
}

/// Use this class to export flight plans as files used for unit tests.
class FlightPlanExporter {
    /// Recreates the test files for the mavlink generator.
    ///
    /// Reads each .flightplan file and recreates its mavlink data.
    /// Exports the files to a new flightplan folder that can be used to replace the old one.
    static func reexport() {
        let flightPlanFilesManager = Services.hub.flightPlan.filesManager

        // urls for test data
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "flightplan", subdirectory: "") else { return }
        for url in urls {
            do {
                let data = try Data(contentsOf: url)
                var flightPlan = try JSONDecoder().decode(FlightPlanTestModel.self, from: data)
                // Delete previously generated mavlink
                flightPlanFilesManager.deleteMavlink(of: flightPlan.flightPlanModel())
                flightPlan.dataSetting?.mavlinkDataFile = nil
                FlightPlanExporter.export(flightPlan: flightPlan.flightPlanModel(), filename: url.lastPathComponent)
            } catch {}
        }

    }

    /// Exports all flight plans currently in the repository.
    /// Stores them as files in the document directory of the app
    static func exportRepository() {
    let flightPlans = Services.hub.repos.flightPlan.getAllFlightPlans()
    for flightPlan in flightPlans {
        FlightPlanExporter.export(flightPlan: flightPlan)
        }
    }

    /// Export a flightplan to a file for tests.
    static func export(flightPlan: FlightPlanModel, filename: String? = nil) {
        var flightPlan = flightPlan
        // if no mavlink data yet, try to generate it
        if flightPlan.dataSetting?.mavlinkDataFile == nil {
            guard let data = FlightPlanExporter.generateMavlink(for: flightPlan) else {
                return
            }
            flightPlan.dataSetting?.mavlinkDataFile = data
        }
        let fpExport = FlightPlanTestModel(
            uuid: flightPlan.uuid,
            type: flightPlan.type,
            dataSetting: flightPlan.dataSetting)
        do {
            let data = try JSONEncoder().encode(fpExport)
            var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            url.appendPathComponent("flightplans")
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)

            let filename = filename ?? "\(fpExport.uuid).flightplan"
            url.appendPathComponent(filename)
            try data.write(to: url)
        } catch { }
    }

    private static func generateMavlink(for flightPlan: FlightPlanModel) -> Data? {
        let typeStore = Services.hub.flightPlan.typeStore
        let filesManager = Services.hub.flightPlan.filesManager
        let path = filesManager.defaultUrl(flightPlan: flightPlan).path
        let commands: [MavlinkStandard.MavlinkCommand]
        let type = typeStore.typeForKey(flightPlan.type)
        let canGenerateMavlink = type?.canGenerateMavlink ?? false
        guard canGenerateMavlink else {
            return nil
        }
        commands = FlightPlanExporter.generateMavlinkCommands(for: flightPlan)
        do {
            try MavlinkStandard.MavlinkFiles.generate(filepath: path, commands: commands)
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            return data
        } catch {
            return nil
        }
    }

    /// Generates MAVLink commands from given flightPlan.
    ///
    /// - Parameters:
    ///    - flightPlan: Flight Plan to generate to MAVLink
    /// - Returns: array of MAVLink commands
    private static func generateMavlinkCommands(for flightPlan: FlightPlanModel) -> [MavlinkStandard.MavlinkCommand] {
        var commands = [MavlinkStandard.MavlinkCommand]()
        var currentSpeed: Double?
        var currentTilt: Double?
        var currentViewMode: MavlinkStandard.SetViewModeCommand.Mode?
        var lastPoiCommand: MavlinkStandard.SetRoiLocationCommand?
        var didAddStartCaptureCommand = false

        // Insert first speed command based on first waypoint speed.
        if let firstSpeedCommand = flightPlan.dataSetting?.wayPoints.first?.speedMavlinkCommand {
            commands.append(firstSpeedCommand)
            currentSpeed = firstSpeedCommand.speed
        }

        // Insert take off actions.
        flightPlan.dataSetting?.takeoffActions.forEach {
            commands.append($0.mavlinkCommand)
        }

        flightPlan.dataSetting?.wayPoints.forEach {
            let speed = $0.speedMavlinkCommand.speed
            if speed != currentSpeed {
                // Insert new speed command.
                commands.append($0.speedMavlinkCommand)
                currentSpeed = speed
            }

            // POI & View mode affect the behavior of the trajectory so they are treated first.
            let viewMode = $0.viewModeCommand.mode
            if viewMode != currentViewMode {
                // Update view mode if needed when no point of interest is set.
                commands.append($0.viewModeCommand)
                currentViewMode = $0.viewModeCommand.mode
            }

            // Insert navigate to waypoint command.
            commands.append($0.wayPointMavlinkCommand)

            // POI changes must be added after waypoint has been reached.
            // This preserves the previous view mode during translation and
            // ensures that the POI only starts on the requested waypoint.
            if $0.poiCommand != lastPoiCommand {
                if let poiCommand = $0.poiCommand {
                    commands.append(poiCommand)
                    currentTilt = nil   // Tilt is not managed while on poi
                    lastPoiCommand = $0.poiCommand
                } else if lastPoiCommand != nil, $0.poiCommand == nil {
                    // Switching to no point of interest.
                    commands.append(MavlinkStandard.SetRoiNoneCommand())
                    commands.append($0.viewModeCommand)
                    currentViewMode = viewMode
                    lastPoiCommand = $0.poiCommand
                }
            }

            $0.actions?.forEach {
                // Only send tilt command if new tilt is different from current.
                // Send tilt only for the first element of POI (before enabling POI)
                if $0.type == .tilt {
                    // Ensure the tilt command must be sent.
                    if lastPoiCommand != nil || $0.angle == currentTilt { return }
                    // Update current tilt.
                    currentTilt = $0.angle
                }
                // Insert the action command.
                commands.append($0.mavlinkCommand)
            }

            // Start capture if needed.
            if !didAddStartCaptureCommand {
                // A single waypoint mavlink does not require a media capture
                if let wptCount = flightPlan.dataSetting?.wayPoints.count,
                   wptCount > 1 {
                    if let captureCommand = flightPlan.dataSetting?.startCaptureCommand {
                        // Add delay command before starting capture.
                        let delay = Action.delayAction(delay: 0.0)
                        commands.append(delay.mavlinkCommand)

                        // Add start capture command.
                        commands.append(captureCommand)
                    }
                }
                didAddStartCaptureCommand = true
            }
        }

        // Stop capture is necessary even if no media has been started.
        // As openflight does not allow a FP without media capture,
        // it requires a stop media to signal the type of media requested.
        if let endCaptureCommand = flightPlan.dataSetting?.endCaptureCommand {
            commands.append(endCaptureCommand)
            didAddStartCaptureCommand = false
        }

        if let returnToLaunchCommand = flightPlan.dataSetting?.returnToLaunchCommand,
           let delayReturnToLaunchCommand = flightPlan.dataSetting?.delayReturnToLaunchCommand {
            // Insert return to launch command if FlightPlan is buckled.
            commands.append(delayReturnToLaunchCommand)
            commands.append(returnToLaunchCommand)
        }

        return commands
    }
}
