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

/// Camera settings that should be saved during flight plan override then restored
private struct CameraSettings: Codable {
    let cameraMode: Camera2Mode?
    let photoMode: Camera2PhotoMode?
    let resolution: Camera2RecordingResolution
    let framerate: Camera2RecordingFramerate
    let whiteBalance: Camera2WhiteBalanceMode
    let exposure: Camera2EvCompensation
    let photoResolution: Camera2PhotoResolution
    let photoFileFormat: Camera2PhotoFileFormat
    let photoFormat: Camera2PhotoFormat
    let photoSignature: Camera2DigitalSignature?
    let timelapseInterval: Double?
    let gpslapseInterval: Double?
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
        // Activating flight plan
        case activatingFlightPlan
        // Active flight plan
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

    /// Project manager
    private let projectManager: ProjectManager

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
    ///   - projectManager: the project manager
    init(activeFlightPlanWatcher: ActiveFlightPlanExecutionWatcher,
         currentDroneHolder: CurrentDroneHolder,
         projectManager: ProjectManager) {
        droneHolder = currentDroneHolder
        self.projectManager = projectManager
        activeFlightPlanWatcher.activeFlightPlanPublisher
            .combineLatest(activeFlightPlanWatcher.activatingFlightPlanPublisher)
            .sink { [unowned self] (activeFlightPlan, activatingFlightPlan) in
                if let flightPlan = activatingFlightPlan {
                    // Save user settings
                    // and send the FP camera settings when the FP is activating
                    handleActivatingFlightPlan(flightPlan)
                } else if let activeFlightPlan = activeFlightPlan {
                    handleActiveFlightPlan(activeFlightPlan)
                } else {
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
        case .activatingFlightPlan, .activeFlightPlan:
            resetMediaMetadata()
            // We previously had an active flight plan, let's restore the potentially saved settings
            restoreSavedCameraSettings()
            state = .noActiveFlightPlan
        }
    }

    /// Manage when there's an activating flight plan
    func handleActivatingFlightPlan(_ flightPlan: FlightPlanModel) {
        switch state {
        case .unknown:
            state = .activatingFlightPlan
        case .activatingFlightPlan, .activeFlightPlan:
            return
        case .noActiveFlightPlan:
            saveCameraSettings()
            if let dataSetting = flightPlan.dataSetting {
                setFlightPlanCameraSettingsToDrone(dataSetting)
            }
            setMediaMetadata(flightPlan)
            state = .activatingFlightPlan
        }
    }

    func handleActiveFlightPlan(_ flightPlan: FlightPlanModel) {
        // Currently nothing to be done 
        state = .activeFlightPlan
    }

    func setMediaMetadata(_ flightPlan: FlightPlanModel) {
        guard let mediaMetadata = droneHolder.drone.getPeripheral(Peripherals.mainCamera2)?.mediaMetadata else {
            ULog.w(.tag, "setMediaMetadata: Unable to get mediaMetadata")
            return
        }
        // Sets the custom Id and the custom title of the drone media metadata for the flight plan execution.
        // To get media title + index that belong to the flight plan execution.
        var executions = 0
        if let project = projectManager.project(for: flightPlan) {
            executions = projectManager.executedFlightPlans(for: project).count
        }
        mediaMetadata.customId = flightPlan.uuid
        mediaMetadata.customTitle = "\(flightPlan.customTitle)" + " (\(executions))"
    }

    func resetMediaMetadata() {
        droneHolder.drone.getPeripheral(Peripherals.mainCamera2)?.resetCustomMediaMetadata()
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
        let photoMode = config[Camera2Params.photoMode]?.value
        let photoSignature = config[Camera2Params.photoDigitalSignature]?.value
        let timelapseInterval = config[Camera2Params.photoTimelapseInterval]?.value
        let gpslapseInterval = config[Camera2Params.photoGpslapseInterval]?.value
        let settings = CameraSettings(cameraMode: cameraMode,
                                      photoMode: photoMode,
                                      resolution: resolution,
                                      framerate: framerate,
                                      whiteBalance: whiteBalance,
                                      exposure: exposure,
                                      photoResolution: photoResolution,
                                      photoFileFormat: photoFileFormat,
                                      photoFormat: photoFormat,
                                      photoSignature: photoSignature,
                                      timelapseInterval: timelapseInterval,
                                      gpslapseInterval: gpslapseInterval)
        ULog.i(.tag, "Saving settings \(settings)")
        storedSettings = settings
    }

    /// Send flight plan's camera settings to drone
    /// - Parameter flightPlan: the flight plan
    func setFlightPlanCameraSettingsToDrone(_ flightPlanData: FlightPlanDataSetting) {
        // camera mode and photo mode, deduced from capture mode
        var cameraMode: Camera2Mode
        var photoMode: Camera2PhotoMode?
        switch flightPlanData.captureModeEnum {
        case .video:
            cameraMode = .recording
        case .timeLapse:
            cameraMode = .photo
            photoMode = .timeLapse
        case .gpsLapse:
            cameraMode = .photo
            photoMode = .gpsLapse
        }

        // timelapse value in seconds
        let timelapseInterval = flightPlanData.timeLapseCycle.map { Double($0) / 1000 }

        // gpslapse value in meters
        let gpslapseInterval = flightPlanData.gpsLapseDistance.map { Double($0) }

        // get current signature configuration
        var photoSignature = droneHolder.drone.getPeripheral(Peripherals.mainCamera2)?
            .config[Camera2Params.photoDigitalSignature]?.value

        // disablePhotoSignature is coming from the libPigeon
        // it decides whether the signature is technically possible or not
        if flightPlanData.disablePhotoSignature {
            photoSignature = Camera2DigitalSignature.none
            ULog.i(.tag, "Photo signature disabled")
        }

        let settings = CameraSettings(cameraMode: cameraMode,
                                      photoMode: photoMode,
                                      resolution: flightPlanData.resolution,
                                      framerate: flightPlanData.framerate,
                                      whiteBalance: flightPlanData.whiteBalanceMode,
                                      exposure: flightPlanData.exposure,
                                      photoResolution: flightPlanData.photoResolution,
                                      photoFileFormat: Constants.defaultPhotoFileFormat,
                                      photoFormat: Constants.defaultPhotoFormat,
                                      photoSignature: photoSignature,
                                      timelapseInterval: timelapseInterval,
                                      gpslapseInterval: gpslapseInterval)
        ULog.i(.tag, "Sending settings \(settings)")
        setCameraSettings(settings)
    }

    /// Restore saved camera settings after flight plan execution
    func restoreSavedCameraSettings() {
        guard let settings = storedSettings else { return }
        ULog.i(.tag, "Restoring settings \(settings)")
        setCameraSettings(settings)
        storedSettings = nil
    }

    /// Set camera settings to the drone
    /// - Parameter settings: the settings to apply
    func setCameraSettings(_ settings: CameraSettings) {
        guard let camera = droneHolder.drone.getPeripheral(Peripherals.mainCamera2) else { return }
        // Edit camera configuration from scratch.
        let editor = camera.config.edit(fromScratch: true)
        editor.applyValueNotForced(Camera2Params.mode, settings.cameraMode)
        editor.applyValueNotForced(Camera2Params.photoMode, settings.photoMode)
        editor.applyValueNotForced(Camera2Params.videoRecordingFramerate, settings.framerate)
        editor.applyValueNotForced(Camera2Params.videoRecordingResolution, settings.resolution)
        editor.applyValueNotForced(Camera2Params.whiteBalanceMode, settings.whiteBalance)
        editor.applyValueNotForced(Camera2Params.exposureCompensation, settings.exposure)
        editor.applyValueNotForced(Camera2Params.photoResolution, settings.photoResolution)
        editor.applyValueNotForced(Camera2Params.photoFormat, settings.photoFormat)
        editor.applyValueNotForced(Camera2Params.photoFileFormat, settings.photoFileFormat)
        editor.applyValueNotForced(Camera2Params.photoTimelapseInterval, settings.timelapseInterval)
        editor.applyValueNotForced(Camera2Params.photoGpslapseInterval, settings.gpslapseInterval)
        // last parameter applied is photo signature, in order to set signature mode only if
        // compatible with previously applied parameters
        editor.applyValueNotForced(Camera2Params.photoDigitalSignature, settings.photoSignature)
        // Apply camera configuration.
        // Empty configuration fields will be filled with current configuration values when available.
        editor.saveSettings(currentConfig: camera.config, saveParams: false)
    }
}

// MARK: FlightPlanCameraSettingsHandler conformance
extension FlightPlanCameraSettingsHandlerImpl: FlightPlanCameraSettingsHandler {
    var forbidCameraSettingsChange: Bool {
        return state == .activeFlightPlan
    }

}
