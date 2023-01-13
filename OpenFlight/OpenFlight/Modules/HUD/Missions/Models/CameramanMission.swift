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

/// Activation model for cameraman mission.
public class CameramanActivationModel: MissionActivationModel {

    var signature: AirSdkMissionSignature = DefaultMissionSignature()
    private var airSdkMissionsManager: AirSdkMissionsManager {
        Services.hub.drone.airsdkMissionsManager
    }

    public func startMission() {
        airSdkMissionsManager.activate(mission: CameramanMission().signature)
    }

    public func stopMissionIfNeeded() {
        // nothing to do
    }

    /// Whether the mission can be stop.
    public func canStopMission() -> Bool {
        return true
    }

    /// Whether the mission can be start.
    public func canStartMission() -> Bool {
        return true
    }

    public func showFailedActivationMessage() {
        // Nothing to do
    }

    public func showFailedDectivationMessage() {
        // Nothing to do
    }

    public func isActive() -> Bool {
        let drone = Services.hub.currentDroneHolder.drone
        guard let onboard = drone.getPeripheral(Peripherals.onboardTracker) else { return false }
        return onboard.trackingEngineState == .activated
    }

    public func getPriority() -> MissionPriority {
        return .middle
    }
}

/// Camera restrictions model for cameraman mission.
public class CameramanCameraRestrictionsModel: MissionCameraRestrictionsModel {

    enum Constants {
        /// Supported framerates in cameraman mode, by recording resolution.
        static let framerates: [Camera2RecordingResolution: Set<Camera2RecordingFramerate>] =
            [.res1080p: [.fps24, .fps25, .fps30, .fps48, .fps50, .fps60],
             .resUhd4k: [.fps24, .fps25, .fps30]]
    }

    public var supportedModes: [CameraCaptureMode] { [.video] }

    public var supportedFrameratesByResolution: [Camera2RecordingResolution: Set<Camera2RecordingFramerate>]? {
        Constants.framerates
    }
}

/// Cameraman mission provider.
public struct CameramanMission: MissionProvider {

    // MARK: - Public Properties
    public init() {}

    public var mission: OpenFlight.Mission {
        return Mission(mode: cameramanMissionMode())
    }

    public var signature: AirSdkMissionSignature = OFMissionSignatures.defaultMission

    /// Build Cameraman mission mode.
    ///
    /// - Returns: Cameraman mission mode object.
    func cameramanMissionMode() -> MissionMode {
        let configurator = MissionModeConfigurator(key: MissionsConstants.classicMissionCameramanKey,
                                                   name: L10n.missionModeCameraman,
                                                   icon: Asset.MissionModes.MissionSubModes.icCameramanMode.image,
                                                   logName: LogEvent.LogKeyHUDMissionProviderSelectorButton.manual,
                                                   preferredSplitMode: .split,
                                                   isMapRequired: false,
                                                   isRightPanelRequired: false,
                                                   isTrackingMode: true,
                                                   isAeLockEnabled: false,
                                                   isInstallationRequired: true,
                                                   isCameraShutterButtonEnabled: true,
                                                   isTargetOnStream: false)
        return MissionMode(configurator: configurator,
                           missionActivationModel: CameramanActivationModel(),
                           bottomBarLeftStack: { () -> [UIView] in
                            return [BehaviourModeView(),
                                    CameramanModeView()]
                           },
                           bottomBarRightStack: ImagingStackElement.classicStack,
                           cameraRestrictions: CameramanCameraRestrictionsModel())
    }
}
