//    Copyright (C) 2020 Parrot Drones SAS
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

private extension ULogTag {
    static let tag = ULogTag(name: "FlightPlanMission")
}

// MARK: - Internal Structs

/// FlightPlan mission provider struct.
public struct FlightPlanMission: MissionProvider {

    // MARK: - Public Properties
    public init() {}

    public var mission: Mission {
        return Mission(key: FlightPlanMissionMode.standard.rawValue,
                       name: L10n.commonFlightPlan,
                       icon: FlightPlanMissionMode.standard.icon,
                       logName: LogEvent.LogKeyHUDMissionProviderSelectorButton.flightPlan,
                       mode: FlightPlanMissionMode.standard.missionMode)
    }
    public var signature: AirSdkMissionSignature = OFMissionSignatures.defaultMission
}

public class FlightPlanActivationModel: MissionActivationModel {

    private var airSdkMissionsManager: AirSdkMissionsManager {
        Services.hub.drone.airsdkMissionsManager
    }

    public func startMission() {
        airSdkMissionsManager.activate(mission: FlightPlanMission().signature)

        // start default mission
        guard let projectType = FlightPlanMissionMode.standard.missionMode.flightPlanProvider?.projectType
        else {
            ULog.e(.tag, "Flight Plan Provider doesn't exist")
            return
        }
        let projectManager = Services.hub.flightPlan.projectManager
        projectManager.setLastOpenedProjectAsCurrent(type: projectType)
        guard let project = projectManager.currentProject,
              let flightPlan = projectManager.editableFlightPlan(for: project)
        else {
            if projectManager.currentProject == nil {
                ULog.i(.tag, "No project found")
            } else {
                ULog.e(.tag, "Project without editable Flight Plan")
            }
            return
        }
        // if editing  an FP (the editor is open in an edit state) avoid re-opening a stale one from
        // the database
        if Services.hub.flightPlan.edition.currentFlightPlanValue?.uuid != flightPlan.uuid {
            Services.hub.flightPlan.stateMachine.open(flightPlan: flightPlan)
        } else {
            ULog.i(.tag, "DON'T open flight plan '\(flightPlan.uuid)' (already opened)")
        }
    }

    public func stopMissionIfNeeded() {
        Services.hub.flightPlan.stateMachine.reset()
        Services.hub.flightPlan.projectManager.clearCurrentProject()
        Services.hub.flightPlan.edition.resetFlightPlan()
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
        let missionStore = Services.hub.missionsStore
        return missionStore.currentFlightPlanMission == FlightPlanMission().mission
    }

    public func getPriority() -> MissionPriority {
        .middle
    }
}

// MARK: - Internal Enums
/// Enum for FlightPlan mission modes.
enum FlightPlanMissionMode: String, CaseIterable {
    case standard = "flight_plan_standard_mode"

    func createFlightPlanPanelCoordinator(services: ServiceHub,
                                          splitControls: SplitControls,
                                          rightPanelContainerControls: RightPanelContainerControls) -> Coordinator? {
        let flightPlanPanelCoordinator = FlightPlanPanelCoordinator(services: Services.hub)
        flightPlanPanelCoordinator.start(splitControls: splitControls,
                                         rightPanelContainerControls: rightPanelContainerControls)
        return flightPlanPanelCoordinator
    }

    func newCustomMap() -> FlightPlanMapViewController {
        // TODO: Fix services injection.
        return FlightPlanMapViewController.instantiate(bamService: Services.hub.bamService,
                                                       missionsStore: Services.hub.missionsStore,
                                                       flightPlanEditionService: Services.hub.flightPlan.edition,
                                                       flightPlanRunManager: Services.hub.flightPlan.run,
                                                       memoryPressureMonitor: Services.hub.systemServices.memoryPressureMonitor)
    }

    var missionMode: MissionMode {
        let configurator = MissionModeConfigurator(key: self.rawValue,
                                                   name: self.title,
                                                   icon: self.icon,
                                                   logName: LogEvent.LogKeyHUDMissionModePanel.missionMode,
                                                   preferredSplitMode: self.preferredSplitMode,
                                                   isMapRequired: true,
                                                   isRightPanelRequired: self.isRightPanelRequired,
                                                   isTrackingMode: false,
                                                   isAeLockEnabled: false,
                                                   isInstallationRequired: true,
                                                   isCameraShutterButtonEnabled: false,
                                                   isTargetOnStream: false)
        return MissionMode(configurator: configurator,
                           flightPlanProvider: self.flightPlanProvider,
                           missionActivationModel: FlightPlanActivationModel(),
                           mapMode: .flightPlan,
                           customMapProvider: {
                            self.newCustomMap()
                           },
                           bottomBarLeftStack: {
                            self.bottomBarViews
                           },
                           bottomBarRightStack: [],
                           stateMachine: Services.hub.flightPlan.stateMachine,
                           hudRightPanelContentProvider: createFlightPlanPanelCoordinator(services:splitControls:rightPanelContainerControls:))
    }

    var icon: UIImage {
        return Asset.MissionModes.MissionSubModes.icFlightPlan.image
    }

    // MARK: - Private Properties
    private var title: String {
        return L10n.commonFlightPlan
    }

    private var preferredSplitMode: SplitScreenMode {
        return .secondary
    }

    private var isRightPanelRequired: Bool {
        return true
    }

    private var flightPlanProvider: ClassicFlightPlanProvider {
        return ClassicFlightPlanProvider()
    }

    private var bottomBarViews: [UIView] {
        return []
    }
}
