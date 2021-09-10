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
                       modes: FlightPlanMissionMode.allMissionItems,
                       defaultMode: FlightPlanMissionMode.standard.missionMode)
    }
    public var signature: ProtobufMissionSignature = DefaultMissionSignature()
}

public class FlightPlanActivationModel: MissionActivationModel {
    public func startMission() {
        guard let projectType = FlightPlanMissionMode.standard.missionMode.flightPlanProvider?.projectType else { return }
        let projectManager = Services.hub.flightPlan.projectManager
        projectManager.setLastOpenedProjectAsCurrent(type: projectType)
        guard let project = projectManager.currentProject,
              let flightPlan = projectManager.lastFlightPlan(for: project) else { return }
        Services.hub.flightPlan.stateMachine.open(flightPlan: flightPlan)
    }

    public func stopMissionIfNeeded() {
        Services.hub.flightPlan.stateMachine.reset()
        Services.hub.flightPlan.projectManager.clearCurrentProject()
        Services.hub.flightPlan.edition.resetFlightPlan()
    }
}

// MARK: - Internal Enums
/// Enum for FlightPlan mission modes.
enum FlightPlanMissionMode: String, CaseIterable {
    case standard = "flight_plan_standard_mode"

    // MARK: - Internal Properties
    static var allMissionItems: [MissionMode] = FlightPlanMissionMode.allCases.map({$0.missionMode})

    var missionMode: MissionMode {
        let configurator = MissionModeConfigurator(key: self.rawValue,
                                                   name: self.title,
                                                   icon: self.icon,
                                                   logName: LogEvent.LogKeyHUDMissionModePanel.missionMode,
                                                   preferredSplitMode: self.preferredSplitMode,
                                                   isMapRequired: true,
                                                   isFlightPlanPanelRequired: self.isFlightPlanPanelRequired,
                                                   isTrackingMode: false)
        return MissionMode(configurator: configurator,
                           flightPlanProvider: self.flightPlanProvider,
                           missionActivationModel: FlightPlanActivationModel(),
                           bottomBarLeftStack: {
                            self.bottomBarViews
                           },
                           bottomBarRightStack: [],
                           stateMachine: Services.hub.flightPlan.stateMachine)
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

    private var isFlightPlanPanelRequired: Bool {
        return true
    }

    private var flightPlanProvider: ClassicFlightPlanProvider {
        return ClassicFlightPlanProvider()
    }

    private var bottomBarViews: [UIView] {
        return []
    }
}
