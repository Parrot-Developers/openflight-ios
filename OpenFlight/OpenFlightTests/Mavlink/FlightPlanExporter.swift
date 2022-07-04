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
}

/// Use this class to export flight plans as files used for unit tests.
class FlightPlanExporter {

    /// Exports all flight plans currently in the repository.
    /// Stores them as files in the document directory of the app
    static func export() {
        let flightPlans = Services.hub.repos.flightPlan.getAllFlightPlans()
        for flightPlan in flightPlans {
            var flightPlan = flightPlan
            // if no mavlink data yet, try to generate it
            if flightPlan.dataSetting?.mavlinkDataFile == nil {
                guard let data = FlightPlanExporter.generateMavlink(for: flightPlan) else {
                    continue
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
                url.appendPathComponent("\(fpExport.uuid).flightplan")
                try data.write(to: url)
            } catch { }
        }
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

    private static func generateMavlinkCommands(for flightPlan: FlightPlanModel) -> [MavlinkStandard.MavlinkCommand] {
        var commands = [MavlinkStandard.MavlinkCommand]()
        var currentSpeed: Double?
        var currentTilt: Double?
        var currentViewMode: MavlinkStandard.SetViewModeCommand.Mode?
        var lastRoiCommand: MavlinkStandard.SetRoiLocationCommand?
        var didAddStartCaptureCommand = false
        var shouldAddRoi = false

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

            // Point of interest & View mode.
            let viewMode = $0.viewModeCommand.mode
            if $0.poiCommand != lastRoiCommand {
                // Request ROI, but only add it on second point
                // to preserve the previous view mode during translation.
                // This ensures that the POI only starts on the requested waypoint.
                shouldAddRoi = $0.poiCommand != nil

                if lastRoiCommand != nil {
                    // Switching to no point of interest.
                    // Even between POIs, we want the ViewMode to be respected between them.
                    commands.append(MavlinkStandard.SetRoiNoneCommand())
                    commands.append($0.viewModeCommand)
                    currentViewMode = viewMode
                }

                lastRoiCommand = $0.poiCommand
                currentTilt = nil   // Tilt is not managed while on poi
            } else if $0.poiCommand != nil {
                // If poiCommand is still active and the same try to add the poiCommand
                if let poiCommand = $0.poiCommand, shouldAddRoi {
                    commands.append(poiCommand)
                    shouldAddRoi = false
                }
            } else if viewMode != currentViewMode {
                // Update view mode if needed when no point of interest is set.
                commands.append($0.viewModeCommand)
                currentViewMode = $0.viewModeCommand.mode
            }

            // Insert navigate to waypoint command.
            commands.append($0.wayPointMavlinkCommand)

            $0.actions?.forEach {
                // Only send tilt command if new tilt is different from current.
                // Send tilt only for the first element of POI (before enabling POI)
                guard $0.type == .tilt &&
                        (lastRoiCommand == nil || shouldAddRoi) &&
                        $0.angle != currentTilt else {
                            return
                        }
                // Insert all waypoint actions commands.
                commands.append($0.mavlinkCommand)

                if $0.type == .tilt {
                    // Update current tilt.
                    currentTilt = $0.angle
                }
            }

            // Start capture if needed.
            if !didAddStartCaptureCommand,
               let captureCommand = flightPlan.dataSetting?.startCaptureCommand {
                // Add delay command before starting capture.
                let delay = Action.delayAction(delay: 0.0)
                commands.append(delay.mavlinkCommand)

                // Add start capture command.
                commands.append(captureCommand)
                didAddStartCaptureCommand = true
            }
        }

        // Stop capture if started
        if didAddStartCaptureCommand,
           let endCaptureCommand = flightPlan.dataSetting?.endCaptureCommand {
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
