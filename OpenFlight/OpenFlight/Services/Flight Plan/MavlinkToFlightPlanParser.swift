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

import GroundSdk

private extension ULogTag {
    static let tag = ULogTag(name: "MavlinkParser")
}

/// MAVLink to Flight Plan parser.
final class MavlinkToFlightPlanParser {
    /// Generates FlightPlan from MAVLink file at given URL or MAVLink string (legacy).
    ///
    /// - Parameters:
    ///    - url: url of MAVLink file to parse
    ///    - mavlinkString: MAVLink string to parse
    ///    - flightPlan: the existing flight plan.
    ///
    /// - Returns: generated `FlightPlanModel` is operation succeeded, `nil` otherwise
    static func generateFlightPlanFromMavlinkLegacy(url: URL? = nil,
                                                    mavlinkString: String? = nil,
                                                    flightPlan: FlightPlanModel) -> FlightPlanModel? {

        var commands: [MavlinkCommand] = []

        if let strongUrl = url {
            commands = MavlinkFiles.parse(filepath: strongUrl.path)
        } else if let strongMavlinkString = mavlinkString {
            commands = MavlinkFiles.parse(mavlinkString: strongMavlinkString)
        }

        var takeOffActions = [Action]()
        var pois = [PoiPoint]()
        var waypoints = [WayPoint]()

        var currentWaypoint: WayPoint?
        var currentViewModeCommand = MavlinkStandard.SetViewModeCommand(mode: .absolute)
        var currentSpeedCommand: MavlinkStandard.ChangeSpeedCommand?

        for command in commands {
            switch command {
            case let roiCommand as SetRoiCommand:
                let newPoi = PoiPoint(roiMavLinkCommand: roiCommand.asStandard)
                pois.append(newPoi)

            case let viewModeCommand as SetViewModeCommand:
                currentWaypoint?.update(viewModeCommand: viewModeCommand.asStandard)
                currentViewModeCommand = viewModeCommand.asStandard

            case let speedModeCommand as ChangeSpeedCommand:
                currentWaypoint?.update(speedMavlinkCommand: speedModeCommand.asStandard)
                currentSpeedCommand = speedModeCommand.asStandard

            case let waypointCommand as NavigateToWaypointCommand:
                let newWaypoint = WayPoint(navigateToWaypointCommand: waypointCommand.asStandard,
                                           speedMavlinkCommand: currentSpeedCommand,
                                           viewModeCommand: currentViewModeCommand)
                waypoints.append(newWaypoint)
                currentWaypoint = newWaypoint

            default:
                guard let newAction = Action(mavLinkCommand: command) else { continue }

                if let currentWaypoint = currentWaypoint {
                    currentWaypoint.addAction(newAction)
                } else {
                    takeOffActions.append(newAction)
                }
            }
        }

        guard let newDataSetting = dataSetting(fromFlightPlan: flightPlan,
                                               takeOffActions: takeOffActions,
                                               pois: pois,
                                               waypoints: waypoints)
        else {
            ULog.e(.tag, "Unable to create flight plan data settings")
            return nil
        }
        return derivedFligthPlan(fromFlightPlan: flightPlan, dataSetting: newDataSetting)
    }

    /// Generates FlightPlan from MAVLink file at given URL or MAVLink string (standard).
    ///
    /// - Parameters:
    ///    - url: url of MAVLink file to parse
    ///    - mavlinkString: MAVLink string to parse
    ///    - flightPlan: the existing flight plan.
    ///
    /// - Returns: generated `FlightPlanModel` is operation succeeded, `nil` otherwise
    static func generateFlightPlanFromMavlinkStandard(
        url: URL? = nil,
        mavlinkString: String? = nil,
        flightPlan: FlightPlanModel) -> FlightPlanModel? {
            var commands: [MavlinkStandard.MavlinkCommand] = []

            if let strongUrl = url {
                commands = (try? MavlinkStandard.MavlinkFiles.parse(filepath: strongUrl.path)) ?? []
            } else if let strongMavlinkString = mavlinkString {
                commands = (try? MavlinkStandard.MavlinkFiles.parse(mavlinkString: strongMavlinkString)) ?? []
            }

            var captureModeEnum: FlightPlanCaptureMode = FlightPlanCaptureMode.defaultValue

            var takeOffActions = [Action]()
            var pois = [PoiPoint]()
            var waypoints = [WayPoint]()

            var currentWaypoint: WayPoint?
            var currentViewModeCommand = MavlinkStandard.SetViewModeCommand(mode: .absolute)
            var currentSpeedCommand: MavlinkStandard.ChangeSpeedCommand?
            var isAMSL: Bool = false
            if let command = commands.first {
                isAMSL = command.frame == .global
            }
            for command in commands {
                switch command {
                case is MavlinkStandard.StartVideoCaptureCommand:
                    captureModeEnum = .video
                case is MavlinkStandard.CameraTriggerDistanceCommand:
                    captureModeEnum = .gpsLapse
                case is MavlinkStandard.CameraTriggerIntervalCommand:
                    captureModeEnum = .timeLapse
                case is MavlinkStandard.StartPhotoCaptureCommand:
                    captureModeEnum = .timeLapse
                case let roiCommand as MavlinkStandard.SetRoiLocationCommand:
                    let newPoi = PoiPoint(roiMavLinkCommand: roiCommand)
                    pois.append(newPoi)

                case let viewModeCommand as MavlinkStandard.SetViewModeCommand:
                    currentWaypoint?.update(viewModeCommand: viewModeCommand)
                    currentViewModeCommand = viewModeCommand

                case let speedModeCommand as MavlinkStandard.ChangeSpeedCommand:
                    currentSpeedCommand = speedModeCommand

                case let waypointCommand as MavlinkStandard.NavigateToWaypointCommand:
                    let newWaypoint = WayPoint(navigateToWaypointCommand: waypointCommand,
                                               speedMavlinkCommand: currentSpeedCommand,
                                               viewModeCommand: currentViewModeCommand)
                    waypoints.append(newWaypoint)
                    currentWaypoint = newWaypoint

                default:
                    guard let newAction = Action(mavLinkCommand: command) else { continue }
                    if let currentWaypoint = currentWaypoint {
                        currentWaypoint.addAction(newAction)
                    } else {
                        takeOffActions.append(newAction)
                    }
                }
            }

            guard var newDataSetting = dataSetting(fromFlightPlan: flightPlan,
                                                   takeOffActions: takeOffActions,
                                                   pois: pois,
                                                   waypoints: waypoints)
            else {
                ULog.e(.tag, "Unable to create flight plan data settings")
                return nil
            }
            newDataSetting.captureMode = captureModeEnum.rawValue
            newDataSetting.isAMSL = isAMSL
            return derivedFligthPlan(fromFlightPlan: flightPlan, dataSetting: newDataSetting)
        }

    static private func dataSetting(fromFlightPlan flightPlan: FlightPlanModel,
                                    takeOffActions: [Action],
                                    pois: [PoiPoint],
                                    waypoints: [WayPoint]) -> FlightPlanDataSetting? {
        guard var newDataSetting = flightPlan.dataSetting
        else {
            ULog.e(.tag, "Missing flight plan data settings")
            return nil
        }
        newDataSetting.takeoffActions = takeOffActions
        newDataSetting.pois = pois
        newDataSetting.wayPoints = waypoints
        return newDataSetting
    }

    static private func derivedFligthPlan(fromFlightPlan flightPlan: FlightPlanModel,
                                          dataSetting: FlightPlanDataSetting) -> FlightPlanModel {
        FlightPlanModel(apcId: Services.hub.userService.currentUser.apcId,
                        type: flightPlan.type,
                        uuid: flightPlan.uuid,
                        version: flightPlan.version,
                        customTitle: flightPlan.customTitle,
                        thumbnailUuid: flightPlan.thumbnailUuid,
                        projectUuid: flightPlan.projectUuid,
                        dataStringType: flightPlan.dataStringType,
                        dataString: dataSetting.toJSONString(),
                        pgyProjectId: flightPlan.pgyProjectId,
                        state: flightPlan.state,
                        lastMissionItemExecuted: flightPlan.lastMissionItemExecuted,
                        mediaCount: flightPlan.mediaCount,
                        uploadedMediaCount: flightPlan.uploadedMediaCount,
                        lastUpdate: Date(),
                        synchroStatus: .notSync,
                        fileSynchroStatus: 0,
                        latestSynchroStatusDate: flightPlan.latestSynchroStatusDate,
                        cloudId: flightPlan.cloudId,
                        parrotCloudUploadUrl: flightPlan.parrotCloudUploadUrl,
                        isLocalDeleted: flightPlan.isLocalDeleted,
                        thumbnail: flightPlan.thumbnail,
                        flightPlanFlights: flightPlan.flightPlanFlights,
                        latestLocalModificationDate: flightPlan.latestLocalModificationDate,
                        synchroError: .noError)
    }
}

// MARK: - MAVLink Legacy to Standard Conversions
private extension SetRoiCommand {
    /// Returns `MavlinkStandard` value.
    var asStandard: MavlinkStandard.SetRoiLocationCommand {
        return MavlinkStandard.SetRoiLocationCommand(latitude: self.latitude,
                                                     longitude: self.longitude,
                                                     altitude: self.altitude)
    }
}

private extension SetViewModeCommand {
    /// Returns `MavlinkStandard` value.
    var asStandard: MavlinkStandard.SetViewModeCommand {
        let standardMode: MavlinkStandard.SetViewModeCommand.Mode
        switch self.mode {
        case .absolute:
            standardMode = .absolute
        case .continue:
            standardMode = .continue
        case .roi:
            standardMode = .roi
        }
        return MavlinkStandard.SetViewModeCommand(mode: standardMode,
                                                  roiIndex: self.roiIndex)
    }
}

private extension ChangeSpeedCommand {
    /// Returns `MavlinkStandard` value.
    var asStandard: MavlinkStandard.ChangeSpeedCommand {
        let speedType: MavlinkStandard.ChangeSpeedCommand.SpeedType
        switch self.speedType {
        case .airSpeed:
            speedType = .airSpeed
        case .groundSpeed:
            speedType = .groundSpeed
        }
        return MavlinkStandard.ChangeSpeedCommand(speedType: speedType,
                                                  speed: self.speed,
                                                  relative: false)
    }
}

private extension NavigateToWaypointCommand {
    /// Returns `MavlinkStandard` value.
    var asStandard: MavlinkStandard.NavigateToWaypointCommand {
        return MavlinkStandard.NavigateToWaypointCommand(latitude: self.latitude,
                                                         longitude: self.longitude,
                                                         altitude: self.altitude,
                                                         yaw: self.yaw,
                                                         holdTime: self.holdTime,
                                                         acceptanceRadius: self.acceptanceRadius)
    }
}

private extension Action {
    /// Init with legacy Mavlink command.
    ///
    /// - Parameters:
    ///    - mavLinkCommand: Mavlink command
    init?(mavLinkCommand: MavlinkCommand) {
        switch mavLinkCommand {
        case is TakeOffCommand:
            self.init(type: .takeOff)
        case is LandCommand:
            self.init(type: .landing)
        case let command as MountControlCommand:
            self.init(type: .tilt,
                      angle: command.tiltAngle)
        case let command as DelayCommand:
            self.init(type: .delay,
                      delay: command.delay)
        case let command as StartPhotoCaptureCommand:
            self.init(type: .imageStartCapture,
                      period: command.interval,
                      nbOfPictures: command.count)
            self.photoFormat = command.format.photoFormat
        case is StopPhotoCaptureCommand:
            self.init(type: .imageStopCapture)
        case is StartVideoCaptureCommand:
            self.init(type: .videoStartCapture)
        case is StopVideoCaptureCommand:
            self.init(type: .videoStopCapture)
        case let command as CreatePanoramaCommand:
            self.init(type: .panorama,
                      angle: command.horizontalAngle,
                      speed: command.horizontalSpeed)
        case let command as SetStillCaptureModeCommand:
            self.init(type: .stillCapture,
                      period: command.interval)
        default:
            // FIXME: Remove this print when all MavLink commands management will be approved.
            ULog.e(.tag, "Unknown mavlink command : \(mavLinkCommand)")
            return nil
        }
    }
}
