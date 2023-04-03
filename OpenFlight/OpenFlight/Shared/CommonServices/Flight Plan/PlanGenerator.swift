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
import Pictor

private extension ULogTag {
    static let tag = ULogTag(name: "PlanFileGenerator")
}

/// The Plan Generation Result.
public struct PlanGenerationResult: CustomStringConvertible {
    /// The updated flight plan.
    public let flightPlan: FlightPlanModel
    /// The filesystem path of the `Plan` file (used to send the file to the Drone).
    public let path: String
    /// The mavlinks commands (used in Run Manager to compute some states).
    public let commands: [MavlinkStandard.MavlinkCommand]
    /// The `Plan` structure.
    public let plan: Plan

    /// Constructor.
    init(flightPlan: FlightPlanModel,
         path: String,
         commands: [MavlinkStandard.MavlinkCommand],
         plan: Plan) {
        self.flightPlan = flightPlan
        self.path = path
        self.commands = commands
        self.plan = plan
    }

    /// `CustomStringConvertible`
    public var description: String {
        "  Flight Plan uuid: \(flightPlan.uuid)\n"
        + "  Plan file path \(path)\n"
        + "  Mavlink commands count: \(commands.count)\n"
        + "  Mavlink is AMSL: \(plan.isAMSL)\n"
        + "  FP is AMSL: \(flightPlan.dataSetting?.isAMSL?.description ?? "-")\n"
        + "  Digital signature: \(plan.staticConfig?.digitalSignature?.description ?? "-")\n"
    }
}

/// The Plan Generation Errors
public enum PlanGenerationError: Error {
    case unableToSaveFlightPlanLocally
    case mavlinkGenerationProhibited
    case unknown
}

// MARK: - PlanFileGenerator Protocol
public protocol PlanFileGenerator {
    /// Generates a Plan file for a Flight Plan.
    ///
    /// - Parameter flightPlan: the flight plan
    /// - Returns the `PlanGenerationResult` containing generation status information.
    /// - Throws an error in case of generation failure.
    ///
    /// - Description: This method is intended to generate and store a `Plan` file used to be uploaded to the Drone.
    ///                Three cases can occur:
    ///                   1/ The filesystem already has a `Plan` file for this FP:
    ///                         -> Returns directly with the existing values.
    ///                   2/ The FP has a *standard* Mavlink file:
    ///                         -> Converts it to `Plan` file then writes it in filesystem.
    ///                   3/ Nothing exists:
    ///                         -> Generates a`Plan` file from the FP, then writes it in filesystem.
    ///                A `Plan` file is not persisted in the FP model. Only Mavlink file is stored in the FP while the `Plan` file
    ///                is generated when uploading it to the Drone.
    func generatePlan(for flightPlan: FlightPlanModel) async throws -> PlanGenerationResult
}

// MARK: - PlanFileGenerator Implementation
public class PlanFileGeneratorImpl {

    private let typeStore: FlightPlanTypeStore
    private let filesManager: FlightPlanFilesManager
    private let projectManager: ProjectManager
    private let currentDroneHolder: CurrentDroneHolder

    init(typeStore: FlightPlanTypeStore,
         filesManager: FlightPlanFilesManager,
         projectManager: ProjectManager,
         currentDroneHolder: CurrentDroneHolder) {
        self.typeStore = typeStore
        self.filesManager = filesManager
        self.projectManager = projectManager
        self.currentDroneHolder = currentDroneHolder
    }

    /// Saves a Flight Plan locally (async version).
    ///
    /// - Parameter flightPlan: the file path to persist
    /// - Throws an error in case of failure.
    func saveLocallyFlightPlan(_ flightPlan: FlightPlanModel) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let pictorContext = PictorContext.new()
            pictorContext.create([flightPlan.pictorModel])
            pictorContext.commit()
            continuation.resume()
        }
    }
}

// MARK: - Private Methods
private extension PlanFileGeneratorImpl {

    /// Generates a Plan for a Flight Plan.
    ///
    /// - Parameters:
    ///    - flightPlan: the flight plan
    ///    - commands: the mavlink commands
    /// - Returns the `PlanGenerationResult` containing generation status information.
    /// - Throws an error in case of failure.
    ///
    /// - Description: This method is intended to generate and store in filesystem a `Plan` file used to be uploaded to the Drone.
    ///                It's also responsible of locally storing the updated flight plan with Mavlink file and return it to the generation result.
    ///                The mavlink commands are either generated from a Mavlink file or the FP Model (using its Data Settings).
    func generatePlan(for flightPlan: FlightPlanModel,
                      with commands: [MavlinkStandard.MavlinkCommand]) async throws -> PlanGenerationResult {
        // The Plan file path.
        let fileUrl = filesManager.planFileUrl(for: flightPlan)
        // Generate Plan.
        ULog.i(.tag, "Generating Plan Model for FP '\(flightPlan.uuid)'")
        let mediaTag = projectManager.mediaTag(for: flightPlan)
        let staticConfig = flightPlan.planStaticConfig(with: mediaTag,
                                                       currentDroneHolder: currentDroneHolder)
        let items = [flightPlan.planStartConfigItem] + commands.planItems
        let plan = Plan(staticConfig: staticConfig,
                        items: items)
        // Generate Plan file.
        ULog.i(.tag, "Generating Plan File from Model")
        let fileData = try Plan.generate(plan: plan)
        // Store the Plan file in filesystem to let other services access it.
        ULog.i(.tag, "Write Plan file in filesystem")
        try filesManager.savePlanFile(of: flightPlan, with: fileData)

        // Store, if needed, the Mavlink file in FP Model.
        // (this step is not mandatory and must not throw an error in case of failure)
        var updatedFlightPlan = flightPlan
        if updatedFlightPlan.dataSetting?.mavlinkDataFile == nil,
           let mavlinkFileData = try? await generateMavlink(for: updatedFlightPlan,
                                                   with: commands) {
            updatedFlightPlan.dataSetting?.mavlinkDataFile = mavlinkFileData
            try? await saveLocallyFlightPlan(updatedFlightPlan)
        }

        let result = PlanGenerationResult(flightPlan: updatedFlightPlan,
                                          path: fileUrl.path,
                                          commands: plan.mavlinkCommands,
                                          plan: plan)
        ULog.i(.tag, "🛩️ Generation for '\(flightPlan.uuid)' ended with Result:\n\(result)")
        return result
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
                    currentTilt = nil   // Tilt is not managed while on poi.
                    lastPoiCommand = $0.poiCommand
                } else if lastPoiCommand != nil, $0.poiCommand == nil {
                    // Switching to no point of interest.
                    commands.append(MavlinkStandard.SetRoiNoneCommand())
                    commands.append($0.viewModeCommand)
                    currentViewMode = viewMode
                    lastPoiCommand = $0.poiCommand
                }
            }

            // -- Way Points' actions.
            $0.actions?.forEach {
                // Only send tilt command if new tilt is different from current.
                // Send tilt only for the first element of POI (before enabling POI).
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
                // A single waypoint mavlink does not require a media capture.
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

// MARK: - Public Methods
public extension PlanFileGeneratorImpl {

    /// Generates a Mavlink file for a Flight Plan.
    ///
    /// - Parameters:
    ///    - flightPlan: the flight plan
    ///    - commands: the mavlink commands (Optional: Will be generated if not passed as parameter).
    /// - Returns the Mavlink file `Data`.
    /// - Throws an error in case of generation failure.
    ///
    /// - Note: This method is declared as `public` to be accessible from Unit Tests.
    func generateMavlink(for flightPlan: FlightPlanModel,
                         with commands: [MavlinkStandard.MavlinkCommand]?) async throws -> Data {
        // Generate Mavlink commands if needed.
        let mavlinkCommands: [MavlinkStandard.MavlinkCommand]
        if let commands = commands {
            mavlinkCommands = commands
        } else {
            mavlinkCommands = generateMavlinkCommands(for: flightPlan)
        }
        // Generate the file from the commands.
        let mavlinkPath = filesManager.defaultUrl(flightPlan: flightPlan).path
        try? MavlinkStandard.MavlinkFiles.generate(filepath: mavlinkPath,
                                                   commands: mavlinkCommands)
        return try Data(contentsOf: URL(fileURLWithPath: mavlinkPath))
    }
}

// MARK: - PlanFileGenerator methods
extension PlanFileGeneratorImpl: PlanFileGenerator {

    public func generatePlan(for flightPlan: FlightPlanModel) async throws -> PlanGenerationResult {
        ULog.i(.tag, "Generating Plan for '\(flightPlan.uuid)'")
        // The Plan file url.
        let planFileUrl = filesManager.planFileUrl(for: flightPlan)

        // CASE 1: Check if the plan file already exists in filesystem.
        // It can occur when resuming a stopped FP.
        if let plan = try? Plan.parse(fileUrl: planFileUrl) {
            ULog.i(.tag, "Plan file for '\(flightPlan.uuid)' found in filesystem at \(planFileUrl.path)")
            return PlanGenerationResult(flightPlan: flightPlan,
                                        path: planFileUrl.path,
                                        commands: plan.mavlinkCommands,
                                        plan: plan)
        }

        // CASE 2: Check if flight plan has already a mavlink file stored in its model.
        // It can occur for imported Mavlink files.
        if let data = flightPlan.dataSetting?.mavlinkDataFile,
           let str = String(data: data, encoding: .utf8),
           let commands = try? MavlinkStandard.MavlinkFiles.parse(mavlinkString: str) {
            ULog.i(.tag, "Mavlink file for '\(flightPlan.uuid)' found in FP model. Need convertion...")
            return try await generatePlan(for: flightPlan, with: commands)
        }

        // CASE 3: Generate mavlink from Flight Plan, then convert it to Plan file.
        // Ensure the FP type is allowed to generate its Mavlink.
        guard typeStore.typeForKey(flightPlan.pictorModel.flightPlanType)?.canGenerateMavlink == true,
              !flightPlan.hasImportedMavlink else {
            ULog.e(.tag, "Trying to generate Mavlink file for a flight plan with type '\(flightPlan.pictorModel.flightPlanType)'")
            throw PlanGenerationError.mavlinkGenerationProhibited
        }
        ULog.i(.tag, "Generating Plan file from FP Model '\(flightPlan.uuid)'")
        let commands = generateMavlinkCommands(for: flightPlan)
        return try await generatePlan(for: flightPlan, with: commands)
    }
}

// MARK: - Extensions

/// Flight plan Data Settings.
extension FlightPlanDataSetting {

    /// The FP disconnection policy.
    var disconnectionPolicy: FlightPlanDisconnectionPolicy {
        disconnectionRth ? .returnToHome : .continue
    }

    /// The custom RTH altitude.
    /// - Note: Custom RTH must be enabled.
    var rthAltitude: Double? {
        guard let rthAltitude = rthHeight
        else { return nil }
        return Double(rthAltitude)
    }

    /// The custom RTH hovering altitude.
    /// - Note: Custom RTH must be enabled.
    var rthEndAltitude: Double? {
        guard let rthEndAltitude = rthHoveringHeight
        else { return nil }
        return Double(rthEndAltitude)
    }

    /// The RTH target.
    /// FP settings allows only two choices: *Take Off Location* or *Pilot Location*.
    var rthType: ReturnHomeTarget {
        rthReturnTarget ? .takeOffPosition : .controllerPosition
    }

    /// The FP RTH ending behavior.
    var rthEndingBehavior: ReturnHomeEndingBehavior {
        rthEndBehaviour ? .hovering : .landing
    }

    /// The FP's Photo Digital Signature setting.
    var photoDigitalSignature: Camera2DigitalSignature {
        guard !disablePhotoSignature else { return .none }
        return isPhotoSignatureEnabled ? .drone : .none
    }
}

/// Flight plan model.
extension FlightPlanModel {
    /// Returns the FP's Plan Static Config.
    ///
    /// - Parameters:
    ///   - mediaTag: the media tag used to link an execution and its media
    ///   - currentDroneHolder: the current drone holder used to retrieve some default values
    ///
    /// - Note: The `customId`/`customTitle` pair is used as meta data for the execution's media.
    ///         The config's `customTitle` is the name of the folder containing the media. It's composed
    ///         of the *project title* and the *execution name* (cf `mediaTag(for:) -> String?`)
    ///         If this parameter is `nil`, the execution name will be used.
    func planStaticConfig(with mediaTag: String?,
                          currentDroneHolder: CurrentDroneHolder) -> Plan.StaticConfig {
        var config = Plan.StaticConfig()
        let isCustomRthEnabled = dataSetting?.customRth ?? false
        config.customRth = isCustomRthEnabled
        config.customId = uuid
        config.customTitle = mediaTag ?? pictorModel.name
        config.digitalSignature = dataSetting?.photoDigitalSignature
        // Apply custom RTH settings if needed.
        if isCustomRthEnabled {
            config.rthType = dataSetting?.rthType
            // If RTH altitude is missing from data settings (e.g not changed explicitly by the user), to stay
            // consistent with the default value displayed in the UI, the RTH Pil.Itf's min altitude is used.
            config.rthAltitude = dataSetting?.rthAltitude
            ?? currentDroneHolder.drone.rthMinAltitude
            ?? RthPreset.defaultAltitude
            // `disconnectionPolicy` is currently not used as it's already sent in start FP command.
            config.disconnectionPolicy = nil
            config.rthEndingBehavior = dataSetting?.rthEndingBehavior
            if dataSetting?.rthEndingBehavior == .hovering {
                // If RTH hovering altitude is missing from data settings, to stay
                // consistent with the default value displayed in the UI, the RTH Pil.Itf's value is used.
                config.rthEndAltitude = dataSetting?.rthEndAltitude
                ?? currentDroneHolder.drone.rthEndingHoveringAltitude
                ?? RthPreset.defaultHoveringAltitude
            }
        }
        return config
    }

    /// The flight plan start configuration `Plan` item.
    var planStartConfigItem: Plan.Item {
        var config = Plan.Config()
        config.obstacleAvoidance = dataSetting?.obstacleAvoidanceActivated
        config.evCompensation = dataSetting?.exposure
        config.whiteBalance = dataSetting?.whiteBalanceMode
        config.videoResolution = dataSetting?.resolution
        config.photoResolution = dataSetting?.photoResolution
        config.frameRate = dataSetting?.framerate
        return Plan.Item.config(config)
    }
}

/// Plan.
extension Plan {
    /// Returns the Mavlink commands.
    var mavlinkCommands: [MavlinkStandard.MavlinkCommand] {
        items.compactMap {
            guard case .command(let command) = $0
            else { return nil }
            return command
        }
    }

    /// Whether the AMSL is enabled for this Plan.
    var isAMSL: Bool {
        // We currently support in the app only one frame for the whole FP.
        // Checking the first WP frame is sufficient to check the altitude frame.
        // Command frame set to `.global` means 'Above Mean Sea Level' is enabled for the FP.
        // All other values will be treated as 'relative to Home position' altitudes.
        mavlinkCommands
            .first(where: { $0 is MavlinkStandard.NavigateToWaypointCommand })?
            .frame == .global
    }
}

/// Drone.
extension Drone {
    /// The RTH ending hovering altitude.
    var rthEndingHoveringAltitude: Double? {
        getPilotingItf(PilotingItfs.returnHome)?.endingHoveringAltitude?.value
    }

    /// The RTH minimum altitude.
    var rthMinAltitude: Double? {
        getPilotingItf(PilotingItfs.returnHome)?.minAltitude?.value
    }
}

/// Mavlink.
extension Array where Element == MavlinkStandard.MavlinkCommand {
    /// Convert  *Mavlink* commands into *Plan Item* commands.
    var planItems: [Plan.Item] { map(Plan.Item.command) }
}
