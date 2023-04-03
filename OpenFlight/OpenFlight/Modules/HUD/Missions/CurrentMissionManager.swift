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
import Combine
import SwiftyUserDefaults
import GroundSdk

extension ULogTag {
    static let currentMissionManager = ULogTag(name: "CurrentMissionManager")
}

/// Current mission manager is responsible for centralizing the selected mission mode and provider
public protocol CurrentMissionManager: AnyObject {

    /// Current mission provider
    var provider: MissionProvider { get }
    /// Publisher for current mission provider
    var providerPublisher: AnyPublisher<MissionProvider, Never> { get }
    /// Current mission mode
    var mode: MissionMode { get }
    /// Mode for current mission mode
    var modePublisher: AnyPublisher<MissionMode, Never> { get }
    /// Last mission selected in the HUD
    var hudLatestSelection: (provider: MissionProvider, mode: MissionMode) { get }
    /// Last mission selected in the HUD Publisher
    var hudLatestSelectionPublisher: AnyPublisher<(provider: MissionProvider, mode: MissionMode), Never> { get }

    /// Change the current mission provider
    func set(provider: MissionProvider)

    /// Change the current mission mode
    func set(mode: MissionMode)

    /// Store the current mission as the latest selected in the HUD.
    func storeCurrentMissionAsLatestHudSelection()

    /// Restore the latest mission selected in the HUD.
    func restoreLatestHudSelection()

    /// Update active mission mode regarding active mission Uid when relevant
    ///
    /// - Parameters:
    ///     - activeMissionUid: active mission Uid
    func updateActiveMissionIfNeeded(activeMissionUid: String)

    /// Whether the current mode can be deactivated.
    ///
    /// - Returns: can be deactivated
    func canDeactivateCurrentMode() -> Bool

    /// Whether the current mode can be activated.
    ///
    /// - Returns: can be activated
    func canActivateCurrentMode() -> Bool

    /// Show failed activation message.
    func showFailedActivationMessage()

    /// Show failed deactivation message.
    func showFailedDectivationMessage()
}

public class CurrentMissionManagerImpl {

    /// The missions store
    private let store: MissionsStore

    /// Current mission provider subject
    private var providerSubject: CurrentValueSubject<MissionProvider, Never>
    /// Current mission mode subject
    private var modeSubject: CurrentValueSubject<MissionMode, Never>
    /// Latest mission selected in the HUD subject
    private var hudLatestSelectionSubject: CurrentValueSubject<(provider: MissionProvider, mode: MissionMode), Never>
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()

    init(store: MissionsStore) {
        self.store = store
        providerSubject = CurrentValueSubject(store.defaultMission)
        modeSubject = CurrentValueSubject(store.defaultMission.mission.defaultMode)
        hudLatestSelectionSubject = CurrentValueSubject((store.defaultMission, store.defaultMission.mission.defaultMode))

        providerPublisher
            .sink { ULog.i(.currentMissionManager, "Provider updated to '\($0.mission.name)'") }
            .store(in: &cancellables)
    }
}

extension CurrentMissionManagerImpl: CurrentMissionManager {
    public var provider: MissionProvider { providerSubject.value }

    public var mode: MissionMode { modeSubject.value }

    public var hudLatestSelection: (provider: MissionProvider, mode: MissionMode) { hudLatestSelectionSubject.value }

    public var providerPublisher: AnyPublisher<MissionProvider, Never> { providerSubject.eraseToAnyPublisher() }

    public var modePublisher: AnyPublisher<MissionMode, Never> { modeSubject.eraseToAnyPublisher() }

    public var hudLatestSelectionPublisher: AnyPublisher<(provider: MissionProvider, mode: MissionMode), Never> {
        hudLatestSelectionSubject.eraseToAnyPublisher()
    }

    public func set(provider: MissionProvider) {
        providerSubject.value = provider
    }

    public func set(mode: MissionMode) {
        guard mode.key != modeSubject.value.key else { return }
        // If ophtalmo mission is active there is no need to stop the mission.
        if Services.hub.drone.ophtalmoService.ophtalmoLastMissionState != .active {
            ULog.i(.currentMissionManager, "stop current mission if needed")
            // Stops current mission if needed.
            modeSubject.value.missionActivationModel.stopMissionIfNeeded()
        }
        modeSubject.value = mode
        ULog.i(.currentMissionManager, "set mode '\(mode.name)'")
        // If ophtalmo mission is active, then do not start another mission.
        // Start mission will be called when ophtalmo is dismissed.
        if Services.hub.drone.ophtalmoService.ophtalmoLastMissionState != .active {
            ULog.i(.currentMissionManager, "start active mission")
            // Starts new mission if needed.
            mode.missionActivationModel.startMission()
        }
    }

    public func canDeactivateCurrentMode() -> Bool {
        return modeSubject.value.missionActivationModel.canStopMission()
    }

    public func canActivateCurrentMode() -> Bool {
        return modeSubject.value.missionActivationModel.canStartMission()
    }

    public func showFailedActivationMessage() {
        modeSubject.value.missionActivationModel.showFailedActivationMessage()
    }

    public func showFailedDectivationMessage() {
        modeSubject.value.missionActivationModel.showFailedDectivationMessage()
    }

    public func storeCurrentMissionAsLatestHudSelection() {
        hudLatestSelectionSubject.value = (provider, mode)
    }

    public func restoreLatestHudSelection() {
        ULog.i(.currentMissionManager, "Restore latest hud selection, mode: '\(hudLatestSelectionSubject.value.mode.name)'")
        set(provider: hudLatestSelectionSubject.value.provider)
        set(mode: hudLatestSelectionSubject.value.mode)
    }

    public func updateActiveMissionIfNeeded(activeMissionUid: String) {
    }
}
