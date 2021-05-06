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

import GroundSdk

/// Handles flight plan settings related to the drone.
final class FlightPlanSettingsHandler {
    // MARK: - Private Properties
    private var initialObstacleAvoidance: ObstacleAvoidanceMode?
    private var initialCameraMode: Camera2Mode?
    private var initialResolution: Camera2RecordingResolution?
    private var initialFramerate: Camera2RecordingFramerate?
    private var initialWhiteBalance: Camera2WhiteBalanceMode?
    private var initialExposure: Camera2EvCompensation?
    private var initialPhotoResolution: Camera2PhotoResolution?
    private var initialPhotoFileFormat: Camera2PhotoFileFormat?
    private var initialPhotoFormat: Camera2PhotoFormat?
    private var drone: Drone?
    private weak var flightPlanViewModel: FlightPlanViewModel?

    // MARK: - Private Enums
    private enum Constants {
        // Default values to use while running a fligh plan.
        static let defaultPhotoFileFormat: Camera2PhotoFileFormat = .jpeg
        static let defaultPhotoFormat: Camera2PhotoFormat = .fullFrameStabilized
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///     - flightPlanViewModel: Flight Plan view model
    init(flightPlanViewModel: FlightPlanViewModel) {
        self.flightPlanViewModel = flightPlanViewModel
    }

    // MARK: - Internal Funcs
    /// Save initial drone settings.
    func saveDroneSettings(drone: Drone) {
        self.drone = drone
        saveCameraDroneSettings(drone: drone)
        saveObstacleAvoidance(drone: drone)
    }

    /// Restore drone to its setting.
    /// Should be called when flight plan run is done.
    func restoreSettings() {
        restoreCameraSettings()
        restoreObstacleAvoidanceSetting()
    }

    /// Apply flight plan settings.
    /// Should be called on flight plan's activation.
    func applyFlightPlanSetting() {
        applyFlightPlanCameraSetting()
        applyFlightPlanObstacleAvoidanceSetting()
    }
}

// MARK: - Camera Settings
private extension FlightPlanSettingsHandler {
    /// Save initial Camera drone settings.
    func saveCameraDroneSettings(drone: Drone) {
        guard let editor = drone.getPeripheral(Peripherals.mainCamera2)?.currentEditor else { return }

        initialCameraMode = editor[Camera2Params.mode]?.value
        initialFramerate = editor[Camera2Params.videoRecordingFramerate]?.value
        initialResolution = editor[Camera2Params.videoRecordingResolution]?.value
        initialWhiteBalance = editor[Camera2Params.whiteBalanceMode]?.value
        initialExposure = editor[Camera2Params.exposureCompensation]?.value
        initialPhotoResolution = editor[Camera2Params.photoResolution]?.value
        initialPhotoFormat = editor[Camera2Params.photoFormat]?.value
        initialPhotoFileFormat = editor[Camera2Params.photoFileFormat]?.value
    }

    /// Restore drone's camera to its setting.
    func restoreCameraSettings() {
        guard let resolution = initialResolution,
              let framerate = initialFramerate,
              let whiteBalance = initialWhiteBalance,
              let exposure = initialExposure,
              let photoResolution = initialPhotoResolution else {
            return
        }

        self.setCameraSettings(resolution: resolution,
                               framerate: framerate,
                               whiteBalance: whiteBalance,
                               exposure: exposure,
                               photoResolution: photoResolution,
                               photoFormat: initialPhotoFormat ?? Constants.defaultPhotoFormat,
                               photoFileFormat: initialPhotoFileFormat ?? Constants.defaultPhotoFileFormat,
                               mode: initialCameraMode)
    }

    /// Apply flight plan camera settings.
    func applyFlightPlanCameraSetting() {
        guard let flightPlanObject = flightPlanViewModel?.flightPlan?.plan else { return }

        let resolution: Camera2RecordingResolution = flightPlanObject.resolution
        let framerate: Camera2RecordingFramerate = flightPlanObject.framerate
        let whiteBalance: Camera2WhiteBalanceMode = flightPlanObject.whiteBalanceMode
        let exposure: Camera2EvCompensation = flightPlanObject.exposure
        let photoResolution: Camera2PhotoResolution = flightPlanObject.photoResolution

        self.setCameraSettings(resolution: resolution,
                               framerate: framerate,
                               whiteBalance: whiteBalance,
                               exposure: exposure,
                               photoResolution: photoResolution,
                               photoFormat: Constants.defaultPhotoFormat,
                               photoFileFormat: Constants.defaultPhotoFileFormat)
    }

    /// Set camera settings.
    ///
    /// - Parameters:
    ///     - resolution: resolution
    ///     - framerate: framerate
    ///     - whiteBalance: white balance
    ///     - exposure: exposure
    ///     - photoResolution: photo resolution
    ///     - photoFormat: photo format
    ///     - photoFileFormat: photo file format
    ///     - mode: camera mode, used for restoration (mode is handle thanks to Mavlink commands)
    func setCameraSettings(resolution: Camera2RecordingResolution,
                           framerate: Camera2RecordingFramerate,
                           whiteBalance: Camera2WhiteBalanceMode,
                           exposure: Camera2EvCompensation,
                           photoResolution: Camera2PhotoResolution,
                           photoFormat: Camera2PhotoFormat,
                           photoFileFormat: Camera2PhotoFileFormat,
                           mode: Camera2Mode? = nil) {
        guard let camera = drone?.getPeripheral(Peripherals.mainCamera2) else { return }

        let editor = camera.currentEditor
        editor[Camera2Params.videoRecordingFramerate]?.value = framerate
        editor[Camera2Params.videoRecordingResolution]?.value = resolution
        editor[Camera2Params.whiteBalanceMode]?.value = whiteBalance
        editor[Camera2Params.exposureCompensation]?.value = exposure
        editor[Camera2Params.photoResolution]?.value = photoResolution
        editor[Camera2Params.photoFormat]?.value = photoFormat
        editor[Camera2Params.photoFileFormat]?.value = photoFileFormat
        // Set optional params only if needed.
        if let mode = mode { editor[Camera2Params.mode]?.value = mode }
        // Save settings.
        editor.saveSettings(currentConfig: camera.config)
    }
}

// MARK: - Obstacle Avoidance
private extension FlightPlanSettingsHandler {
    /// Save initial obstacle avoidance drone setting.
    func saveObstacleAvoidance(drone: Drone) {
        if initialObstacleAvoidance == nil,
           let obstacleAvoidance = drone.getPeripheral(Peripherals.obstacleAvoidance)?.mode.preferredValue {
            initialObstacleAvoidance = obstacleAvoidance
        }
    }

    /// Set obstacle avoidance mode.
    ///
    /// - Parameters:
    ///     - mode: obstacle avoidance mode
    func setObstacleAvoidanceMode(_ mode: ObstacleAvoidanceMode) {
        drone?.getPeripheral(Peripherals.obstacleAvoidance)?.mode.preferredValue = mode
    }

    /// Restore drone's obstacle avoidance to its setting.
    func restoreObstacleAvoidanceSetting() {
        guard let oaMode = initialObstacleAvoidance else { return }

        setObstacleAvoidanceMode(oaMode)
    }

    /// Apply obstacle avoidance setting.
    func applyFlightPlanObstacleAvoidanceSetting() {
        if let obstacleAvoidanceActivated = flightPlanViewModel?.flightPlan?.obstacleAvoidanceActivated {
            let mode: ObstacleAvoidanceMode = obstacleAvoidanceActivated ? .standard : .disabled
            setObstacleAvoidanceMode(mode)
        }
    }
}
