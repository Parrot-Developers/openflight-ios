//    Copyright (C) 2021 Parrot Drones SAS
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

private extension ULogTag {
    static let tag = ULogTag(name: "MavlinkGenerator")
}

public struct MavlinkGenerationResult {
    public let flightPlan: FlightPlanModel
    public let path: String
    public let commands: [MavlinkStandard.MavlinkCommand]
}

public enum MavlinkGenerationError: Error {
    case parsingFromExistingFailed(Error)
    case generateFileFromCommandsFailed(Error)
    case cannotGenerateMavlinkAndNoData
    case unknown
}

public typealias MavlinkGenerationCompletion = (Result<MavlinkGenerationResult, MavlinkGenerationError>) -> Void

public protocol MavlinkGenerator {
    func generateMavlink(for flightPlan: FlightPlanModel, _ completion: @escaping MavlinkGenerationCompletion)
}

public class MavlinkGeneratorImpl {

    private let typeStore: FlightPlanTypeStore
    private let filesManager: FlightPlanFilesManager
    private let repo: FlightPlanRepository

    init(typeStore: FlightPlanTypeStore,
         filesManager: FlightPlanFilesManager,
         repo: FlightPlanRepository) {
        self.typeStore = typeStore
        self.filesManager = filesManager
        self.repo = repo
    }
}

extension MavlinkGeneratorImpl: MavlinkGenerator {

    public func generateMavlink(for flightPlan: FlightPlanModel, _ completion: @escaping MavlinkGenerationCompletion) {
        // Generate mavlink file from Flight Plan.
        let path = filesManager.defaultUrl(flightPlan: flightPlan).path
        let mainQueueCompletion = { (result: Result<MavlinkGenerationResult, MavlinkGenerationError>) in
            DispatchQueue.main.async {
                completion(result)
            }
        }
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            let commands: [MavlinkStandard.MavlinkCommand]
            let type = typeStore.typeForKey(flightPlan.type)
            let canGenerateMavlink = type?.canGenerateMavlink ?? false
            if FileManager.default.fileExists(atPath: path) {
                ULog.i(.tag, "Found mavlink in file system of '\(flightPlan.uuid)' at \(path)")
                do {
                    commands = try MavlinkStandard.MavlinkFiles.parse(filepath: path)
                } catch {
                    ULog.e(.tag, "Failed to parse existing mavlink file for flightPlan "
                           + " '\(flightPlan.uuid)' at path: \(path) Error: \(error)")
                    mainQueueCompletion(.failure(.parsingFromExistingFailed(error)))
                    return
                }
            } else if let data = flightPlan.dataSetting?.mavlinkDataFile,
                      let str = String(data: data, encoding: .utf8) {
                ULog.i(.tag, "Found mavlink in data model of '\(flightPlan.uuid)'")
                do {
                    commands = try MavlinkStandard.MavlinkFiles.parse(mavlinkString: str)
                    filesManager.writeFile(of: flightPlan)
                } catch {
                    ULog.e(.tag, "Failed to parse existing mavlink in data model for flightPlan"
                           + " '\(flightPlan.uuid)'. Error: \(error)")
                    mainQueueCompletion(.failure(.parsingFromExistingFailed(error)))
                    return
                }
            } else {
                ULog.i(.tag, "Flight plan \(flightPlan.uuid) mavlink file doesn't exist in file"
                       + " system or data model")
                guard canGenerateMavlink else {
                    ULog.e(.tag, "Failed mavlink generation of '\(flightPlan.type)'"
                           + " as it's missing from both the file system and the data model and the"
                           + " flightPlan is generatable."
                           + " Aborting mavlink generation.")
                    mainQueueCompletion(.failure(.cannotGenerateMavlinkAndNoData))
                    return
                }
                commands = generateMavlinkCommands(for: flightPlan)
                do {
                    try MavlinkStandard.MavlinkFiles.generate(filepath: path, commands: commands)
                    let data = try Data(contentsOf: URL(fileURLWithPath: path))
                    flightPlan.dataSetting?.mavlinkDataFile = data
                    repo.saveOrUpdateFlightPlan(flightPlan,
                                                byUserUpdate: true,
                                                toSynchro: true,
                                                withFileUploadNeeded: true)
                    ULog.i(.tag, "Generated mavlink of '\(flightPlan.uuid)' with \(commands.count) commands at \(path)")
                } catch {
                    ULog.e(.tag, "Failed mavlink generation '\(flightPlan.uuid)' at \(path). Error \(error)")
                    mainQueueCompletion(.failure(.generateFileFromCommandsFailed(error)))
                    return
                }
            }
            mainQueueCompletion(.success(MavlinkGenerationResult(flightPlan: flightPlan, path: path, commands: commands)))
        }
    }
}

private extension MavlinkGeneratorImpl {
    enum Constants {
        static let maxUploadWaitingTime: TimeInterval = 10
    }

    /// Generates MAVLink commands from given flightPlan.
    ///
    /// - Parameters:
    ///    - flightPlan: Flight Plan to generate to MAVLink
    /// - Returns: array of MAVLink commands
    func generateMavlinkCommands(for flightPlan: FlightPlanModel) -> [MavlinkStandard.MavlinkCommand] {
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

        // Stop capture if capture mode is different from video.
        // Recording should always continue during rth.
        if didAddStartCaptureCommand && flightPlan.dataSetting?.captureModeEnum != .video,
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

        // Stop capture if still in progress.
        if didAddStartCaptureCommand,
           let endCaptureCommand = flightPlan.dataSetting?.endCaptureCommand {
            commands.append(endCaptureCommand)
        }

        return commands
    }
}
