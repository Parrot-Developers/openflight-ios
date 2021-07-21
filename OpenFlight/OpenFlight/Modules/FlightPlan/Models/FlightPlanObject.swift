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

import UIKit
import GroundSdk
import CoreLocation

public enum FlightPlanCaptureMode: String, CaseIterable {
    case video
    case timeLapse
    case gpsLapse

    static var defaultValue: FlightPlanCaptureMode {
        return .video
    }

    var title: String {
        switch self {
        case .video:
            return L10n.cameraModeVideo
        case .timeLapse:
            return L10n.cameraModeTimelapse
        case .gpsLapse:
            return L10n.cameraModeGpslapse
        }
    }

    var image: UIImage {
        switch self {
        case .video:
            return Asset.Common.Icons.iconCamera.image
        case .timeLapse:
            return Asset.BottomBar.CameraModes.icCameraModeTimeLapse.image
        case .gpsLapse:
            return Asset.BottomBar.CameraModes.icCameraModeGpsLapse.image
        }
    }
}

/// Class representing a FlightPlan structure including waypoints, POIs, etc.
public final class FlightPlanObject: Codable {
    // MARK: - Public Properties
    public var takeoffActions: [Action]
    public var pois: [PoiPoint]
    public var wayPoints: [WayPoint]
    // FIXME: unsused for now, check if it might get relevant at some point.
    public var isBuckled: Bool?
    public var shouldContinue: Bool? = true
    public var lastPointRth: Bool? = true
    public var captureMode: String?
    public var captureSettings: [String: String]?

    public var captureModeEnum: FlightPlanCaptureMode {
        get {
            guard let mode = captureMode,
                  let enumValue = FlightPlanCaptureMode(rawValue: mode) else { return FlightPlanCaptureMode.defaultValue }

            return enumValue
        }
        set { captureMode = newValue.rawValue }
    }

    var framerate: Camera2RecordingFramerate {
        get {
            guard let value = captureSettings?[ClassicFlightPlanSettingType.framerate.rawValue],
                  let framerateSetting = Camera2RecordingFramerate(rawValue: value) else {
                return Camera2RecordingFramerate.defaultFramerate
            }

            return framerateSetting
        }
        set {
            updateCaptureSetting(type: .framerate,
                                 value: newValue.rawValue)
        }
    }

    var resolution: Camera2RecordingResolution {
        get {
            guard let value = captureSettings?[ClassicFlightPlanSettingType.resolution.rawValue],
                  let resolutionSetting = Camera2RecordingResolution(rawValue: value) else {
                return Camera2RecordingResolution.defaultResolution
            }

            return resolutionSetting
        }
        set {
            updateCaptureSetting(type: .resolution,
                                 value: newValue.rawValue)
        }
    }

    public var photoResolution: Camera2PhotoResolution {
        get {
            guard let value = captureSettings?[ClassicFlightPlanSettingType.photoResolution.rawValue],
                  let resolutionSetting = Camera2PhotoResolution(rawValue: value) else {
                return Camera2PhotoResolution.defaultResolution
            }

            return resolutionSetting
        }
        set {
            updateCaptureSetting(type: .photoResolution,
                                 value: newValue.rawValue)
        }
    }

    public var exposure: Camera2EvCompensation {
        get {
            guard let value = captureSettings?[ClassicFlightPlanSettingType.exposure.rawValue],
                  let exposureSetting = Camera2EvCompensation(rawValue: value) else {
                return Camera2EvCompensation.defaultValue
            }

            return exposureSetting
        }
        set {
            updateCaptureSetting(type: .exposure,
                                 value: newValue.rawValue)
        }
    }

    public var whiteBalanceMode: Camera2WhiteBalanceMode {
        get {
            guard let value = captureSettings?[ClassicFlightPlanSettingType.whiteBalance.rawValue],
                  let whiteBalanceModeSetting = Camera2WhiteBalanceMode(rawValue: value) else {
                return Camera2WhiteBalanceMode.defaultMode
            }

            return whiteBalanceModeSetting
        }
        set {
            updateCaptureSetting(type: .whiteBalance,
                                 value: newValue.rawValue)
        }
    }

    /// Timelapse interval, in milliseconds.
    var timeLapseCycle: Int? {
        get {
            guard let value = captureSettings?[ClassicFlightPlanSettingType.timeLapseCycle.rawValue] else {
                return TimeLapseMode.preset.value
            }

            return Int(value)
        }
        set {
            if let value = newValue {
                updateCaptureSetting(type: .timeLapseCycle,
                                     value: "\(value)")
            }
        }
    }

    var gpsLapseDistance: Int? {
        get {
            guard let value = captureSettings?[ClassicFlightPlanSettingType.gpsLapseDistance.rawValue] else {
                return GpsLapseMode.preset.value
            }

            return Int(value)
        }
        set {
            if let value = newValue {
                updateCaptureSetting(type: .gpsLapseDistance,
                                     value: "\(value)")
            }
        }
    }

    // MARK: - Internal Properties
    /// Capture MAVLink command.
    var startCaptureCommand: MavlinkStandard.MavlinkCommand? {
        switch captureModeEnum {
        case .video:
            return MavlinkStandard.StartVideoCaptureCommand()
        case .timeLapse:
            guard let triggerCycle = timeLapseCycle else { return nil }

            // Set triggerCycle in milliseconds.
            return MavlinkStandard.CameraTriggerIntervalCommand(triggerCycle: triggerCycle)
        case .gpsLapse:
            guard let distance = gpsLapseDistance else { return nil }

            return MavlinkStandard.CameraTriggerDistanceCommand(distance: Double(distance),
                                                                triggerOnceImmediately: true)
        }
    }

    /// End capture MAVLink command.
    var endCaptureCommand: MavlinkStandard.MavlinkCommand {
        switch captureModeEnum {
        case .video:
            return MavlinkStandard.StopVideoCaptureCommand()
        case .timeLapse,
             .gpsLapse:
            return MavlinkStandard.StopPhotoCaptureCommand()
        }
    }

    /// Return to launch MAVLink command, if FlightPlan is buckled.
    var returnToLaunchCommand: MavlinkStandard.ReturnToLaunchCommand? {
        guard lastPointRth == true else { return nil }

        return MavlinkStandard.ReturnToLaunchCommand()
    }

    /// Returns Flight Plan photo count.
    var photoCount: Int {
        wayPoints
            .compactMap({ $0.actions })
            .reduce([], +)
            .filter({ $0.type == ActionType.imageStartCapture })
            .count
    }

    /// Returns Flight Plan video count.
    var videoCount: Int {
        wayPoints
            .compactMap({ $0.actions })
            .reduce([], +)
            .filter({ $0.type == ActionType.videoStartCapture })
            .count
    }

    // MARK: - Internal Enums
    enum CodingKeys: String, CodingKey {
        case takeoffActions = "takeoff"
        case wayPoints
        case pois = "poi"
        case isBuckled = "buckled"
        case shouldContinue = "continue"
        case lastPointRth = "RTH"
        case captureMode
        case captureSettings
    }

    // MARK: - Init
    /// Init.
    init() {
        self.takeoffActions = []
        self.pois = []
        self.wayPoints = []
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - takeoffActions: actions to start on takeOff
    ///    - pois: POIs contained in FlightPlan
    ///    - wayPoints: wayPoints contained in FlightPlan
    public init(takeoffActions: [Action],
                pois: [PoiPoint],
                wayPoints: [WayPoint]) {
        self.takeoffActions = takeoffActions
        self.pois = pois
        self.wayPoints = wayPoints
    }

    // MARK: - Public Funcs
    /// Sets up global continue mode.
    ///
    /// - Parameters:
    ///    - shouldContinue: whether global continue mode should be activated
    func setShouldContinue(_ shouldContinue: Bool) {
        self.shouldContinue = shouldContinue
        // FIXME: for now, specific continue mode for each segment is not supported.
        self.wayPoints.forEach { $0.shouldContinue = shouldContinue }
    }

    /// Sets up return to home on last point setting.
    ///
    /// - Parameters:
    ///    - lastPointRth: whether drone should land on last waypoint
    func setLastPointRth(_ lastPointRth: Bool) {
        self.lastPointRth = lastPointRth
    }

    /// Adds a waypoint at the end of the Flight Plan.
    func addWaypoint(_ wayPoint: WayPoint) {
        let previous = wayPoints.last
        self.wayPoints.append(wayPoint)
        wayPoint.previousWayPoint = previous
        previous?.nextWayPoint = wayPoint
        wayPoint.updateYawAndRelations()
    }

    /// Adds a point of interest to the Flight Plan.
    func addPoiPoint(_ poiPoint: PoiPoint) {
        self.pois.append(poiPoint)
    }

    /// Removes waypoint at given index.
    ///
    /// - Parameters:
    ///    - index: waypoint index
    /// - Returns: removed waypoint, if any
    @discardableResult
    func removeWaypoint(at index: Int) -> WayPoint? {
        guard index < self.wayPoints.count else { return nil }

        let wayPoint = self.wayPoints.remove(at: index)
        // Update previous and next waypoint yaw.
        let previous = wayPoint.previousWayPoint
        let next = wayPoint.nextWayPoint
        previous?.nextWayPoint = next
        next?.previousWayPoint = previous
        previous?.updateYaw()
        next?.updateYaw()

        return wayPoint
    }

    /// Removes point of interest at given index.
    ///
    /// - Parameters:
    ///    - index: point of interest index
    /// - Returns: removed point of interest, if any
    @discardableResult
    func removePoiPoint(at index: Int) -> PoiPoint? {
        guard index < self.pois.count else {
            return nil
        }
        wayPoints.forEach {
            guard let poiIndex = $0.poiIndex else { return }

            switch poiIndex {
            case index:
                $0.poiIndex = nil
                $0.poiPoint = nil
            case let supIdx where supIdx > index:
                $0.poiIndex = poiIndex - 1
            default:
                break
            }
        }
        return self.pois.remove(at: index)
    }

    /// Sets up initial relations between Flight Plan's objects.
    /// Should be called after creation.
    func setRelations() {
        var previousWayPoint: WayPoint?

        for index in (0...pois.count) {
            pois.elementAt(index: index)?.addIndex(index: index)
        }

        wayPoints.forEach { wayPoint in
            wayPoint.previousWayPoint = previousWayPoint
            if let poiIndex = wayPoint.poiIndex {
                let poiPoint = pois.elementAt(index: poiIndex)
                wayPoint.poiPoint = poiPoint
                poiPoint?.assignWayPoint(wayPoint: wayPoint)
            }
            previousWayPoint?.nextWayPoint = wayPoint
            previousWayPoint = wayPoint
        }
    }

    /// Clear all waypoints and points of interest.
    func clearPoints() {
        self.wayPoints.removeAll()
        self.pois.removeAll()
    }
}

// MARK: - Privates Funcs
private extension FlightPlanObject {
    /// Updates capture setting.
    ///
    /// - Parameters:
    ///     - type: setting's type
    ///     - value: setting's value
    func updateCaptureSetting(type: ClassicFlightPlanSettingType, value: String?) {
        guard let value = value else { return }

        // Init captureSettings if needed.
        if captureSettings == nil { captureSettings = [:] }
        // Save value.
        captureSettings?[type.rawValue] = value
    }
}
