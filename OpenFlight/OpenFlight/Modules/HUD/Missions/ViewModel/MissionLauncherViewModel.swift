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
import SwiftyUserDefaults

/// State for `MissionLauncherViewModel`.
public final class MissionLauncherState: MissionButtonState, EquatableState, Copying {
    // MARK: - Public Properties
    public var title: String? {
        if let mode = mode {
            return mode.name
        } else {
            return provider?.mission.name
        }
    }
    public var image: UIImage? {
        if let mode = mode {
            return mode.icon
        } else {
            return provider?.mission.icon
        }
    }
    public var provider: MissionProvider?
    public var mode: MissionMode?
    public var isSelected: Observable<Bool> = Observable(false)

    // MARK: - Init
    required public init() {
        provider = MissionsManager.shared.missionFor(key: Defaults.userMissionProvider)
        mode = MissionsManager.shared.missionSubModeFor(key: Defaults.userMissionMode)
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - provider: current provider
    ///    - mode: current mode
    ///    - isSelected: observable for item selection
    init(provider: MissionProvider?,
         mode: MissionMode? = nil,
         isSelected: Observable<Bool>) {
        self.provider = provider
        self.mode = mode
        self.isSelected = isSelected
    }

    // MARK: - Copying
    public func copy() -> MissionLauncherState {
        return MissionLauncherState(provider: provider,
                                    mode: self.mode,
                                    isSelected: isSelected)
    }

    // MARK: - Equatable
    public func isEqual(to other: MissionLauncherState) -> Bool {
        return self.provider?.mission.key == other.provider?.mission.key
            && self.mode?.key == other.mode?.key
            && self.isSelected.value == other.isSelected.value
    }
}

/// View model to manage mission widget in HUD Bottom bar.
public final class MissionLauncherViewModel: MissionLauncherButtonViewModel<MissionLauncherState> {
    // MARK: - Private Properties
    private var defaultsDisposables = [DefaultsDisposable]()

    // MARK: - Init
    public override init(stateDidUpdate: ((MissionLauncherState) -> Void)? = nil) {
        super.init(stateDidUpdate: stateDidUpdate)
        listenDefaults()
    }

    // MARK: - Deinit
    deinit {
        defaultsDisposables.forEach {
            $0.dispose()
        }
        defaultsDisposables.removeAll()
    }

    // MARK: - Override Funcs
    public override func listenDrone(drone: Drone) {}

    public override func update(provider: MissionProvider) {
        guard Defaults.userMissionProvider != provider.mission.key else { return }

        Defaults.userMissionProvider = provider.mission.key
    }

    public override func update(mode: MissionMode) {
        guard Defaults.userMissionMode != mode.key else { return }

        // Stops current mission if needed.
        state.value.mode?.missionActivationModel.stopMissionIfNeeded()
        // Updates mode with the new one.
        Defaults.userMissionMode = mode.key
        // Starts new mission if needed.
        mode.missionActivationModel.startMission()
    }
}

// MARK: - Internal Funcs
extension MissionLauncherViewModel {
    /// Update active mission regarding active mission Uid.
    ///
    /// - Parameters:
    ///     - activeMissionUid: active mission Uid
    func updateActiveMissionIfNeeded(activeMissionUid: String) {
        if state.value.provider?.signature.missionUID != activeMissionUid,
           let missionProvider = MissionsManager.shared.allMissions
            .first(where: { $0.signature.missionUID ==  activeMissionUid}),
           let mode = missionProvider.mission.defaultMode {
            self.update(mode: mode)
        }
    }
}

// MARK: - Private Funcs
private extension MissionLauncherViewModel {
    /// Listen updates on user defaults to detect mission mode changes.
    func listenDefaults() {
        // UserMissionMode is the only user default observed to prevent from double notification.
        // Could be improve by replacing defaults with a specific manager.
        defaultsDisposables.append(Defaults.observe(\.userMissionMode, options: [.new]) { [weak self] _ in
            DispatchQueue.userDefaults.async {
                let copy = self?.state.value.copy()
                let newMode = MissionsManager.shared.missionSubModeFor(key: Defaults.userMissionMode)
                copy?.mode = newMode
                // Also update provider here because it can be changed.
                let newProvider = MissionsManager.shared.missionFor(key: Defaults.userMissionProvider)
                copy?.provider = newProvider
                self?.state.set(copy)
            }
        })
    }
}
