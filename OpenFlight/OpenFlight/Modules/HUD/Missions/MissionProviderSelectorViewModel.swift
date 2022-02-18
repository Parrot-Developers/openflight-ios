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
import GroundSdk

/// Delegate for mission provider selector VM
protocol MissionProviderSelectorViewModelDelegate: AnyObject {

    /// Hide mission menu.
    func hideMissionMenu()
    /// Show bottom bar.
    func showBottomBar()

}

/// View Model for MissionProviderSelectorViewController
public class MissionProviderSelectorViewModel {

    private var cancellables = Set<AnyCancellable>()
    private weak var delegate: MissionProviderSelectorViewModelDelegate?
    private unowned var currentMissionManager: CurrentMissionManager
    private unowned var missionsStore: MissionsStore
    @Published private var currentItems = [MissionItemCellModel]()
    private let missionsManager: AirSdkMissionsManager
    private let connectedDroneHolder: ConnectedDroneHolder
    private var activatingMission: String?
    private var missionManagerRef: Ref<MissionManager>?

    init(currentMissionManager: CurrentMissionManager,
         missionsStore: MissionsStore,
         delegate: MissionProviderSelectorViewModelDelegate,
         missionsManager: AirSdkMissionsManager,
         connectedDroneHolder: ConnectedDroneHolder) {
        self.currentMissionManager = currentMissionManager
        self.missionsStore = missionsStore
        self.delegate = delegate
        self.missionsManager = missionsManager
        self.connectedDroneHolder = connectedDroneHolder
        bind()
    }

    /// Publisher for the list of items to display
    var itemsPublisher: AnyPublisher<[MissionItemCellModel], Never> { $currentItems.eraseToAnyPublisher() }

    /// Handle tap on an item
    func userDidTap(on index: Int) {
        let selectedItem = currentItems[index]
        guard selectedItem.isSelectable else { return }
        if currentMissionManager.canDeactivateCurrentMode() {
            let provider = missionsStore.presentableMissions[index]
            if provider.mission.defaultMode.missionActivationModel.canStartMission() {
                selectMission(withProvider: provider)
            } else {
                provider.mission.defaultMode.missionActivationModel.showFailedActivationMessage()
            }
        } else {
            currentMissionManager.showFailedDectivationMessage()
        }
        delegate?.hideMissionMenu()
    }
}

// MARK: Private functions
private extension MissionProviderSelectorViewModel {

    private func selectMission(withProvider provider: MissionProvider) {
        currentMissionManager.storeLastHudSelection(provider: provider, mode: provider.mission.defaultMode)
        currentMissionManager.set(provider: provider)
        currentMissionManager.set(mode: provider.mission.defaultMode)
        ensureSelectItem(forProvider: provider)
    }

    private func ensureSelectItem(forProvider provider: MissionProvider) {
        guard let selectedIndex = currentItems.firstIndex(where: { $0.provider.mission.key == provider.mission.key }) else {
            return
        }
        // update selected values and trigger publisher
        for item in currentItems {
            item.isSelected = false
        }
        let selectedItem = currentItems[selectedIndex]
        selectedItem.isSelected = true
        currentItems[selectedIndex] = selectedItem
    }

    /// Switch to a presentable mission if the current is not
    func checkIfCurrentMissionIsPresentable() {
        if !missionsManager.isPresentable(currentMissionManager.provider) {
            // then select the default mission
            selectMission(withProvider: missionsStore.defaultMission)
        }
    }

    /// Get the model of the mission cell
    func getMissionItemCellModel(for mission: MissionProvider, isSelectable: Bool) -> MissionItemCellModel {
        let currentMissionKey = currentMissionManager.provider.mission.key
        let isSelected = mission.mission.key == currentMissionKey
        return MissionItemCellModel(title: mission.mission.name,
                                    image: mission.mission.icon,
                                    isSelected: isSelected,
                                    isSelectable: isSelectable,
                                    provider: mission)
    }

    /// Bind the drone connection state
    func bind() {
        missionsStore.presentableMissionsPublisher
            .sink { [unowned self] presentableMissions in
                presentableMissionDidUpdate(presentableMissions)
            }
            .store(in: &cancellables)

        connectedDroneHolder.dronePublisher
            .sink { [unowned self] drone in
                listenMissionState(drone: drone)
                listenMissionManager(drone: drone)
            }
            .store(in: &cancellables)
    }

    /// Listen mission state, and redirect to current one if necessary.
    ///
    /// - Note: it will activate the current mission if there is no redirection.
    func listenMissionState(drone: Drone?) {
        guard let drone = drone else { return }
        var missionToPush: MissionItemCellModel?
        for mission in currentItems {
            let priority = mission.provider.mission.defaultMode.missionActivationModel.getPriority()
            let isActive = mission.provider.mission.defaultMode.missionActivationModel.isActive()

            if isActive {
                if let priorityToPush = missionToPush?.provider.mission.defaultMode.missionActivationModel.getPriority() {
                    if priority > priorityToPush {
                        missionToPush = mission
                    }
                } else {
                    missionToPush = mission
                }
            }
        }
        if let mission = missionToPush {
            if mission.provider.mission.defaultMode.missionActivationModel.getPriority() > .none {
                selectMission(withProvider: mission.provider)
                delegate?.showBottomBar()
                Services.hub.ui.hudTopBarService.allowTopBarDisplay()
            } else {
                let missionManager = drone.getPeripheral(Peripherals.missionManager)
                if let activeMissionResult = missionManager?.missions.filter({ $0.value.state == .active }),
                    !activeMissionResult.isEmpty, let activeMission = activeMissionResult.first {
                    if activeMission.key == DefaultMissionSignature().missionUID {
                        // Redirection to default menu if the drone is already flying
                        if drone.getInstrument(Instruments.flyingIndicators)?.state != .landed {
                            if let missionItem = currentItems.first(where: { $0.provider.signature.missionUID == DefaultMissionSignature().missionUID }) {
                                selectMission(withProvider: missionItem.provider)
                            }
                        } else {
                            currentMissionManager.provider.mission.defaultMode.missionActivationModel.startMission()
                        }

                    }
                }
            }
        }
    }

    /// Listen mission manager, to redirect menu to current mission if the activation failed.
    ///
    /// - Note: it will redirect to current mission if there is a failed activation.
    func listenMissionManager(drone: Drone?) {
        guard let drone = drone else {
            activatingMission = nil
            return
        }

        missionManagerRef = drone.getPeripheral(Peripherals.missionManager) { [unowned self] missionManager in

            guard let missionManager = missionManager else { return }

            for mission in missionManager.missions where mission.value.state == .activating {
                activatingMission = mission.key
                return
            }

            guard let activatingMission = activatingMission else { return }

            if missionManager.missions[activatingMission]?.state == .active {
                self.activatingMission = nil
            } else if missionManager.missions[activatingMission]?.state != .activating {
                // redirect to current mission activated
                if let mission = missionManager.missions.first(where: { $0.value.state == .active}) {
                    if let missionItem = currentItems.first(where: { $0.provider.signature.missionUID == mission.value.uid }) {
                        selectMission(withProvider: missionItem.provider)
                    }
                }
                self.activatingMission = nil
            }
        }
    }

    func presentableMissionDidUpdate(_ presentableMissions: [MissionProvider]) {
        currentItems = presentableMissions.map {
            getMissionItemCellModel(for: $0, isSelectable: missionsManager.isSelectable($0))
        }
        checkIfCurrentMissionIsPresentable()
    }
}
