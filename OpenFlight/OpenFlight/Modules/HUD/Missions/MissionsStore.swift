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

import Foundation
import Combine
import GroundSdk

/// Stores and exposes all mission providers
public protocol MissionsStore: AnyObject {

    /// All available missions
    var allMissions: [MissionProvider] { get }

    /// All available mission publisher.
    var allMissionsPublisher: AnyPublisher<[MissionProvider], Never> { get }

    /// Presentable missions
    var presentableMissions: [MissionProvider] { get }

    /// Presentable missions
    var currentFlightPlanMission: Mission? { get }

    /// All presentable mission publisher.
    var presentableMissionsPublisher: AnyPublisher<[MissionProvider], Never> { get }

    /// Default mission
    var defaultMission: MissionProvider { get }

    /// Add missions to the store
    func add(missions: [MissionProvider])

    func missionFor(flightPlan: FlightPlanModel) -> (provider: MissionProvider, mission: MissionMode)?
}

public final class MissionsStoreImpl: MissionsStore {

    // MARK: - Internal Properties
    /// All available missions
    @Published public private(set) var allMissions: [MissionProvider] = []

    /// Presentable missions
    @Published public private(set) var presentableMissions: [MissionProvider] = []

    /// Presentable missions
    @Published public private(set) var currentFlightPlanMission: Mission?

    /// Default mission
    public let defaultMission: MissionProvider

    // MARK: - Private Properties
    private var cancellables: Set<AnyCancellable> = []
    private let missionsManager: AirSdkMissionsManager
    private let connectedDroneHolder: ConnectedDroneHolder
    private var missionManagerRef: Ref<MissionManager>?

    // MARK: - Init
    init(connectedDroneHolder: ConnectedDroneHolder,
         missionsManager: AirSdkMissionsManager) {
        self.connectedDroneHolder = connectedDroneHolder
        self.missionsManager = missionsManager
        let classicMission = ClassicMission(mission: Mission(key: String(describing: ClassicMission.self),
                                                             name: L10n.missionClassic,
                                                             icon: Asset.MissionModes.icClassicMissionMode.image,
                                                             logName: LogEvent.LogKeyHUDMissionProviderSelectorButton.classic,
                                                             mode: ClassicMission.manualMode))
        self.defaultMission = classicMission
        self.allMissions.insert(classicMission, at: 0)
        bind()

    }

    private func bind() {
        $allMissions.sink { [unowned self] missions in
            updatePresentableMissions(missions)
        }
        .store(in: &cancellables)
        connectedDroneHolder.dronePublisher
            .removeDuplicates()
            .sink { [unowned self] drone in
                listenMissionState(drone: drone)
            }
            .store(in: &cancellables)
    }

    func listenMissionState(drone: Drone?) {
        missionManagerRef = drone?.getPeripheral(Peripherals.missionManager) { [unowned self] _ in
            updatePresentableMissions(allMissions)
        }
        updatePresentableMissions(allMissions)
    }

    private func updatePresentableMissions(_ missions: [MissionProvider]) {
        presentableMissions = missions.filter { missionsManager.isPresentable($0) }
    }

    // MARK: - Public Funcs
    /// Add missions to mission list.
    ///
    /// - Parameters:
    ///    - missions: List of MissionProviders objects to add.
    public func add(missions: [MissionProvider]) {
        // use += to trigger publisher
        allMissions += missions
    }

    public func missionFor(flightPlan: FlightPlanModel) -> (provider: MissionProvider, mission: MissionMode)? {
        // Get mission matching flightPlan
        var missionProvider: MissionProvider?
        var missionMode: MissionMode?
        for provider in allMissions {
            if provider.mission.defaultMode.flightPlanProvider?.hasFlightPlanType(flightPlan.type) ?? false {
                missionProvider = provider
                missionMode = provider.mission.defaultMode
            }
        }
        guard let mProvider = missionProvider, let mMode = missionMode else { return nil }
        return (mProvider, mMode)
    }

    public var allMissionsPublisher: AnyPublisher<[MissionProvider], Never> {
        return $allMissions.eraseToAnyPublisher()
    }

    public var presentableMissionsPublisher: AnyPublisher<[MissionProvider], Never> {
        return $presentableMissions.eraseToAnyPublisher()
    }
}
