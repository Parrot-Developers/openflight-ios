//
//  Copyright (C) 2021 Parrot Drones SAS.
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
import Combine
import SwiftyUserDefaults

/// Flight plan camera settings handler: manages saving, restoring and disabling controls of camera settings
/// during a flight plan
public protocol FlightPlanCameraSettingsHandler: AnyObject {

    /// Flag indicating when the flight plan execution forbids changing camera settings
    var forbidCameraSettingsChange: Bool { get }
}

// Add Codable conformance to all types of interest
extension Camera2Mode: Codable {}
extension Camera2RecordingResolution: Codable {}
extension Camera2RecordingFramerate: Codable {}
extension Camera2WhiteBalanceMode: Codable {}
extension Camera2EvCompensation: Codable {}
extension Camera2PhotoResolution: Codable {}
extension Camera2PhotoFileFormat: Codable {}
extension Camera2PhotoFormat: Codable {}
extension Camera2DigitalSignature: Codable {}

/// Camera settings that should be saved during flight plan override then restored
private struct CameraSettings: Codable {
    let cameraMode: Camera2Mode?
    let resolution: Camera2RecordingResolution
    let framerate: Camera2RecordingFramerate
    let whiteBalance: Camera2WhiteBalanceMode
    let exposure: Camera2EvCompensation
    let photoResolution: Camera2PhotoResolution
    let photoFileFormat: Camera2PhotoFileFormat
    let photoFormat: Camera2PhotoFormat
    let photoSignature: Camera2DigitalSignature?
}

// MARK: ULogTag
private extension ULogTag {
    /// Tag for this file
    static let tag = ULogTag(name: "FlightPlanCameraSettingsHandler")
}

/// User defaults keys for this handler
private extension DefaultsKeys {
    var cameraSettings: DefaultsKey<Data?> { .init("key_cameraSettingsToRestoreAfterFlightPlan") }
}

/// Implementation of `FlightPlanCameraSettingsHandler`
class FlightPlanCameraSettingsHandlerImpl {

    /// State type for the service
    private enum State {
        case unknown
        // No activating or active flight plan
        case noActiveFlightPlan
        // Activating or active flight plan
        case activeFlightPlan
    }

    /// Constants
    private enum Constants {
        // Default values to use while running a fligh plan.
        static let defaultPhotoFileFormat: Camera2PhotoFileFormat = .jpeg
        static let defaultPhotoFormat: Camera2PhotoFormat = .rectilinear
    }

    /// Current drone holder
    private unowned var droneHolder: CurrentDroneHolder
    /// Cancellables
    private var cancellables = Set<AnyCancellable>()
    /// State
    private var state: State = .unknown

    /// UserDefaults storage for camera settings during flight plan
    private var storedSettings: CameraSettings? {
        get {
            guard let data = Defaults[\.cameraSettings] else { return nil }
            return try? JSONDecoder().decode(CameraSettings.self, from: data)
        }
        set {
            Defaults.cameraSettings = try? JSONEncoder().encode(newValue)
        }
    }

    /// Init
    /// - Parameters:
    ///   - activeFlightPlanWatcher: the active flight plan watcher
    ///   - currentDroneHolder: the current drone holder
    init(activeFlightPlanWatcher: ActiveFlightPlanExecutionWatcher, currentDroneHolder: CurrentDroneHolder) {
        droneHolder = currentDroneHolder
        activeFlightPlanWatcher.activeFlightPlanAndRecoveryIdPublisher
            .combineLatest(activeFlightPlanWatcher.activatingFlightPlan)
            .sink { [unowned self] (activeFlightPlanCouple, activatingFlightPlan) in
            if let flightPlan = activatingFlightPlan {
                // Switch to active flight plan and save user settings
                // and send the FP camera settings when the FP is activating
                handleActiveFlightPlan(flightPlan.plan)
            } else if activeFlightPlanCouple == nil {
                // Restore user settings when there's no activating or active flight plan
                handleNoActiveFlightPlan()
            }
        }
        .store(in: &cancellables)
    }
}

// MARK: Private functions
private extension FlightPlanCameraSettingsHandlerImpl {
    /// Manage when there's no active flight plan
    func handleNoActiveFlightPlan() {
        switch state {
        case .unknown:
            state = .noActiveFlightPlan
        case .noActiveFlightPlan:
            return
        case .activeFlightPlan:
            // We previously had an active flight plan, let's restore the potentially saved settings
            restoreSavedCameraSettings()
            state = .noActiveFlightPlan
        }
    }

    /// Manage when there's an active flight plan
    func handleActiveFlightPlan(_ flightPlan: FlightPlanObject) {
        switch state {
        case .unknown:
            state = .activeFlightPlan
        case .activeFlightPlan:
            return
        case .noActiveFlightPlan:
            saveCameraSettings()
            setFlightPlanCameraSettingsToDrone(flightPlan)
            state = .activeFlightPlan
        }
    }

    /// Save the current camera settings
    func saveCameraSettings() {
        guard let config = droneHolder.drone.getPeripheral(Peripherals.mainCamera2)?.config,
              let framerate = config[Camera2Params.videoRecordingFramerate]?.value,
              let resolution = config[Camera2Params.videoRecordingResolution]?.value,
              let whiteBalance = config[Camera2Params.whiteBalanceMode]?.value,
              let exposure = config[Camera2Params.exposureCompensation]?.value,
              let photoResolution = config[Camera2Params.photoResolution]?.value,
              let photoFormat = config[Camera2Params.photoFormat]?.value,
              let photoFileFormat = config[Camera2Params.photoFileFormat]?.value else { return }
        let cameraMode = config[Camera2Params.mode]?.value
        // Photo signature may be overriden by the drone during the FP even if we don't explicitely change
        // it because of compatibility checks on other settings (typically timelapse)
        let photoSignature = config[Camera2Params.photoDigitalSignature]?.value
        let settings = CameraSettings(cameraMode: cameraMode,
                                      resolution: resolution,
                                      framerate: framerate,
                                      whiteBalance: whiteBalance,
                                      exposure: exposure,
                                      photoResolution: photoResolution,
                                      photoFileFormat: photoFileFormat,
                                      photoFormat: photoFormat,
                                      photoSignature: photoSignature)
        ULog.i(.tag, "Saving settings \(settings)")
        storedSettings = settings
    }

    /// Send flight plan's camera settings to drone
    /// - Parameter flightPlan: the flight plan
    func setFlightPlanCameraSettingsToDrone(_ flightPlan: FlightPlanObject) {
        let resolution: Camera2RecordingResolution = flightPlan.resolution
        let framerate: Camera2RecordingFramerate = flightPlan.framerate
        let whiteBalance: Camera2WhiteBalanceMode = flightPlan.whiteBalanceMode
        let exposure: Camera2EvCompensation = flightPlan.exposure
        let photoResolution: Camera2PhotoResolution = flightPlan.photoResolution

        let settings = CameraSettings(cameraMode: nil,
                                      resolution: resolution,
                                      framerate: framerate,
                                      whiteBalance: whiteBalance,
                                      exposure: exposure,
                                      photoResolution: photoResolution,
                                      photoFileFormat: Constants.defaultPhotoFileFormat,
                                      photoFormat: Constants.defaultPhotoFormat,
                                      photoSignature: nil)
        setCameraSettings(settings)
    }

    /// Restore saved camera settings after flight plan execution
    func restoreSavedCameraSettings() {
        guard let settings = storedSettings else { return }
        ULog.i(.tag, "Restauring settings \(settings)")
        setCameraSettings(settings)
        storedSettings = nil
    }

    /// Set camera settings to the drone
    /// - Parameter settings: the settings to apply
    func setCameraSettings(_ settings: CameraSettings) {
        guard let camera = droneHolder.drone.getPeripheral(Peripherals.mainCamera2) else { return }
        // Edit camera configuration from scratch.
        let editor = camera.config.edit(fromScratch: true)
        editor[Camera2Params.videoRecordingFramerate]?.value = settings.framerate
        editor[Camera2Params.videoRecordingResolution]?.value = settings.resolution
        editor[Camera2Params.whiteBalanceMode]?.value = settings.whiteBalance
        editor[Camera2Params.exposureCompensation]?.value = settings.exposure
        editor[Camera2Params.photoResolution]?.value = settings.photoResolution
        editor[Camera2Params.photoFormat]?.value = settings.photoFormat
        editor[Camera2Params.photoFileFormat]?.value = settings.photoFileFormat
        // Set optional params only if needed.
        if let mode = settings.cameraMode { editor[Camera2Params.mode]?.value = mode }
        if let signature = settings.photoSignature { editor[Camera2Params.photoDigitalSignature]?.value = signature }
        // Apply camera configuration.
        // Empty configuration fields will be filled with current configuration values when available.
        editor.saveSettings(currentConfig: camera.config)
    }
}

// MARK: FlightPlanCameraSettingsHandler conformance
extension FlightPlanCameraSettingsHandlerImpl: FlightPlanCameraSettingsHandler {
    var forbidCameraSettingsChange: Bool {
        return state == .activeFlightPlan
    }

}
