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
import CoreLocation
import GroundSdk

extension FlightPlanDataSetting {

    private enum Constants {
        static let readOnlyFreeSettingsKey = "read-only"
        static let pgyProjectDeletedKey = "pgy-project-deleted"
    }

    var pgyProjectDeleted: Bool {
        get {
            notPropagatedSettings[Constants.pgyProjectDeletedKey].map { Bool($0) ?? false } ?? false
        }
        set {
            notPropagatedSettings[Constants.pgyProjectDeletedKey] = newValue.description
        }
    }

    var readOnly: Bool {
        get {
            freeSettings[Constants.readOnlyFreeSettingsKey].map { Bool($0) ?? false } ?? false
        }
        set {
            freeSettings[Constants.readOnlyFreeSettingsKey] = newValue.description
        }
    }

    public var captureModeEnum: FlightPlanCaptureMode {
        get { FlightPlanCaptureMode(rawValue: captureMode) ?? FlightPlanCaptureMode.defaultValue }
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

    /// Gpslapse interval, in millimeters.
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

    private var delayReturnToLaunch: TimeInterval { 2 }

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

            return MavlinkStandard.CameraTriggerDistanceCommand(distance: Double(distance) / 1000,
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

    /// Return to launch MAVLink command.
    var delayReturnToLaunchCommand: MavlinkStandard.DelayCommand? {
        guard lastPointRth == true else { return nil }

        return MavlinkStandard.DelayCommand(delay: Double(delayReturnToLaunch))
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

    // MARK: - Public Funcs
    /// Sets up global continue mode.
    ///
    /// - Parameters:
    ///    - shouldContinue: whether global continue mode should be activated
    mutating func setShouldContinue(_ shouldContinue: Bool) {
        self.shouldContinue = shouldContinue
        // FIXME: for now, specific continue mode for each segment is not supported.
        self.wayPoints.forEach { $0.shouldContinue = shouldContinue }
    }

    /// Sets up return to home on last point setting.
    ///
    /// - Parameters:
    ///    - lastPointRth: whether drone should land on last waypoint
    public mutating func setLastPointRth(_ lastPointRth: Bool) {
        self.lastPointRth = lastPointRth
    }

    /// Sets up return to home on disconnection.
    ///
    /// - Parameters:
    ///    - disconnectionRth: whether drone should return to home on disconnection
    public mutating func setDisconnectionRth(_ disconnectionRth: Bool) {
        self.disconnectionRth = disconnectionRth
    }

    /// Sets up the use of custom return to home settings.
    ///
    /// - Parameters:
    ///    - customRth: whether drone should use custom return to home settings
    public mutating func setCustomRth(_ customRth: Bool) {
        self.customRth = customRth
    }

    /// Sets up return to home return target.
    ///
    /// - Parameters:
    ///    - rthReturnTarget: whether drone should return to take-off position or pilot position
    public mutating func setRthReturnTarget(_ rthReturnTarget: Bool) {
        self.rthReturnTarget = rthReturnTarget
    }

    /// Sets up return to home altitude.
    ///
    /// - Parameters:
    ///    - rthHeight: return to home altitude
    public mutating func setRthHeigh(_ rthHeight: Int) {
        self.rthHeight = rthHeight
    }

    /// Sets up return to home end behaviour.
    ///
    /// - Parameters:
    ///    - rthEndBehaviour: whether drone should do an hovering or a landing at the end of the return to home
    public mutating func setRthEndBehaviour(_ rthEndBehaviour: Bool) {
        self.rthEndBehaviour = rthEndBehaviour
    }

    /// Sets up return to home hovering altitude.
    ///
    /// - Parameters:
    ///    - rthHoveringHeight: hovering altitude
    public mutating func setRthHoveringHeight(_ rthHoveringHeight: Int) {
        self.rthHoveringHeight = rthHoveringHeight
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

    /// Updates capture setting.
    ///
    /// - Parameters:
    ///     - type: setting's type
    ///     - value: setting's value
    mutating func updateCaptureSetting(type: ClassicFlightPlanSettingType, value: String?) {
        guard let value = value else { return }

        // Init captureSettings if needed.
        if captureSettings == nil { captureSettings = [:] }
        // Save value.
        captureSettings?[type.rawValue] = value
    }

    var maxAltitude: Double {
        let maxWayPointAltitude = wayPoints.max { lhs, rhs in lhs.altitude < rhs.altitude }
        return maxWayPointAltitude?.altitude ?? 0.0
    }
}
