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

/// Manage all missions.

public final class MissionsManager {
    // MARK: - Shared Instance
    public static let shared = MissionsManager()

    // MARK: - Internal Properties
    /// Add all MissionProviders to allMissions array.
    var allMissions: [MissionProvider] = [FlightPlanMission()]

    // MARK: - Private Properties
    private var classicMission = ClassicMission(mission: Mission(key: String(describing: ClassicMission.self),
                                                         name: L10n.missionClassic,
                                                         icon: Asset.MissionModes.icClassicMissionMode.image,
                                                         logName: LogEvent.LogKeyHUDMissionProviderSelectorButton.classic,
                                                         modes: [ClassicMission.manualMode]))

    // MARK: - Init
    init() {
        self.allMissions.insert(classicMission, at: 0)
    }

    // MARK: - Public Funcs
    /// Add missions to mission list.
    ///
    /// - Parameters:
    ///    - missions: List of MissionProviders objects to add.
    public func addMissions(_ missions: [MissionProvider]) {
        allMissions.append(contentsOf: missions)
    }

    /// Add mission modes to the Classic mission.
    ///
    /// - Parameters:
    ///    - modes: List of MissionMode objects to add.
    public func addClassicMissionMode(_ modes: [MissionMode]) {
        guard let index = allMissions.firstIndex(where: {$0.mission.key == classicMission.mission.key }) else {
            return
        }
        classicMission.mission.modes.append(contentsOf: modes)
        allMissions.remove(at: index)
        allMissions.insert(classicMission, at: index)
    }
}

// MARK: - Internal Funcs
extension MissionsManager {
    /// Get mission from its key.
    ///
    /// - Parameters:
    ///    - key: key for searched mission.
    ///
    /// - Returns: MissionProvider if found.
    func missionFor(key: String) -> MissionProvider? {
        return allMissions.first { $0.mission.key == key }
    }

    /// Get mission submode from its key.
    ///
    /// - Parameters:
    ///    - key: key for searched submode.
    ///
    /// - Returns: MissionMode if found.
    func missionSubModeFor(key: String) -> MissionMode? {
        return allMissions
            .flatMap { $0.mission.modes }
            .first(where: { $0.key == key })
    }
}
