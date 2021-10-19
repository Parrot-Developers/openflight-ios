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
import Combine
import SwiftyUserDefaults

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

    /// Change the current mission provider
    func set(provider: MissionProvider)

    /// Change the current mission mode
    func set(mode: MissionMode)

    /// Update active mission mode regarding active mission Uid when relevant
    ///
    /// - Parameters:
    ///     - activeMissionUid: active mission Uid
    func updateActiveMissionIfNeeded(activeMissionUid: String)
}

public class CurrentMissionManagerImpl {

    /// The missions store
    private let store: MissionsStore

    /// Current mission provider subject
    private var providerSubject: CurrentValueSubject<MissionProvider, Never>
    /// Current mission mode subject
    private var modeSubject: CurrentValueSubject<MissionMode, Never>

    init(store: MissionsStore) {
        self.store = store
        providerSubject = CurrentValueSubject(store.defaultMission)
        modeSubject = CurrentValueSubject(store.defaultMission.mission.defaultMode)
    }
}

extension CurrentMissionManagerImpl: CurrentMissionManager {
    public var provider: MissionProvider { providerSubject.value }

    public var mode: MissionMode { modeSubject.value }

    public var providerPublisher: AnyPublisher<MissionProvider, Never> { providerSubject.eraseToAnyPublisher() }

    public var modePublisher: AnyPublisher<MissionMode, Never> { modeSubject.eraseToAnyPublisher() }

    public func set(provider: MissionProvider) {
        providerSubject.value = provider
    }

    public func set(mode: MissionMode) {
        guard mode.key != modeSubject.value.key else { return }
        // Stops current mission if needed.
        modeSubject.value.missionActivationModel.stopMissionIfNeeded()
        modeSubject.value = mode
        // Starts new mission if needed.
        mode.missionActivationModel.startMission()

    }

    public func updateActiveMissionIfNeeded(activeMissionUid: String) {
        if !providerSubject.value.isCompatibleWith(missionUid: activeMissionUid),
           let missionProvider = store.allMissions.first(where: { $0.signature.missionUID ==  activeMissionUid }) {
            set(provider: missionProvider)
            set(mode: missionProvider.mission.defaultMode)
        }
    }
}
