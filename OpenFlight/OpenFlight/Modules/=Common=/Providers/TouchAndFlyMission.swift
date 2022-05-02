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
import UIKit

/// Touch and Fly activation model
public struct TouchAndFlyActivationModel: MissionActivationModel {

    private var airSdkMissionsManager: AirSdkMissionsManager {
        Services.hub.drone.airsdkMissionsManager
    }

    public func startMission() {
        airSdkMissionsManager.activate(mission: TouchAndFlyMission().signature)
    }

    public func stopMissionIfNeeded() {
        _ = Services.hub.connectedDroneHolder.drone?.getPilotingItf(PilotingItfs.pointOfInterest)?.deactivate()
        _ = Services.hub.connectedDroneHolder.drone?.getPilotingItf(PilotingItfs.guided)?.deactivate()
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
        let poi = Services.hub.connectedDroneHolder.drone?.getPilotingItf(PilotingItfs.pointOfInterest)
        let guided = Services.hub.connectedDroneHolder.drone?.getPilotingItf(PilotingItfs.guided)
        guard let poi = poi, let guided = guided else { return false }
        return poi.state == .active || guided.state == .active
    }

    public func getPriority() -> MissionPriority {
        .middle
    }
}

/// Touch and Fly mission provider struct.
public struct TouchAndFlyMission: MissionProvider {

    // MARK: - Public Properties
    public init() {}

    // MissionsConstants.classicMissionTouchAndFlyKey
    // MARK: - Internal Properties
    public var mission: OpenFlight.Mission {
        let touchAndFlyModeConf = MissionModeConfigurator(key: MissionsConstants.classicMissionTouchAndFlyKey,
                                                          name: L10n.missionModeTouchNFly,
                                                          icon: Asset.MissionModes.MissionSubModes.icTouchFlyMode.image,
                                                          logName: LogEvent.LogKeyHUDMissionProviderSelectorButton.touchAndFly,
                                                          preferredSplitMode: .secondary,
                                                          isMapRequired: true,
                                                          isRightPanelRequired: true,
                                                          isTrackingMode: false,
                                                          isAeLockEnabled: false,
                                                          isInstallationRequired: true,
                                                          isCameraShutterButtonEnabled: true)
        let missionMode = MissionMode(
            configurator: touchAndFlyModeConf,
            missionActivationModel: TouchAndFlyActivationModel(),
            bottomBarLeftStack: { () -> [UIView] in
                return []
            },
            bottomBarRightStack: ImagingStackElement.classicStack,
            hudRightPanelContentProvider: createTouchAndFlyPanelCoordinator(services:splitControls:rightPanelContainerControls:))

        return OpenFlight.Mission(
            key: MissionsConstants.classicMissionTouchAndFlyKey,
            name: L10n.missionModeTouchNFly,
            icon: Asset.MissionModes.MissionSubModes.icTouchFlyMode.image,
            logName: LogEvent.LogKeyHUDMissionProviderSelectorButton.touchAndFly,
            mode: missionMode)
    }

    public var signature: AirSdkMissionSignature = OFMissionSignatures.defaultMission

    public func createTouchAndFlyPanelCoordinator(services: ServiceHub,
                                                  splitControls: SplitControls,
                                                  rightPanelContainerControls: RightPanelContainerControls) -> Coordinator? {
        rightPanelContainerControls.splitControls = splitControls
        let coordinator = TouchAndFlyCoordinator(services: services, splitControls: splitControls)
        coordinator.start()
        return coordinator
    }
}
