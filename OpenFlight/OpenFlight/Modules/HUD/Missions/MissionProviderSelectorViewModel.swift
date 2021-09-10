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

/// Delegate for mission provider selector VM
protocol MissionProviderSelectorViewModelDelegate: AnyObject {

    /// User did either select another mission or tap the current mission button
    func userDidTapAnyMission()

}

/// View Model for MissionProviderSelectorViewController
public class MissionProviderSelectorViewModel {

    private var cancellables = Set<AnyCancellable>()
    private weak var delegate: MissionProviderSelectorViewModelDelegate?
    private unowned var currentMissionManager: CurrentMissionManager
    private unowned var missionsStore: MissionsStore
    private var itemsSubject = CurrentValueSubject<[MissionItemCellModel], Never>([])

    init(currentMissionManager: CurrentMissionManager,
         missionsStore: MissionsStore,
         delegate: MissionProviderSelectorViewModelDelegate) {
        self.currentMissionManager = currentMissionManager
        self.missionsStore = missionsStore
        self.delegate = delegate
        listenCurrentMissionProvider()
    }
}

// MARK: Contract
public extension MissionProviderSelectorViewModel {

    /// Publisher for the list of items to display
    var itemsPublisher: AnyPublisher<[MissionItemCellModel], Never> { itemsSubject.eraseToAnyPublisher() }

    /// Handle tap on an item
    func userDidTap(on index: Int) {
        let provider = missionsStore.allMissions[index]
        currentMissionManager.set(provider: provider)
        currentMissionManager.set(mode: provider.mission.defaultMode)
        delegate?.userDidTapAnyMission()
    }
}

// MARK: Private functions
private extension MissionProviderSelectorViewModel {

    /// Listen to current mission provider to update the items list
    func listenCurrentMissionProvider() {
        currentMissionManager.providerPublisher.sink { [unowned self] provider in
            let currentMissionKey = currentMissionManager.provider.mission.key
            itemsSubject.value = missionsStore.allMissions.map {
                let isSelected = $0.mission.key == currentMissionKey
                return MissionItemCellModel(title: $0.mission.name,
                                            image: $0.mission.icon,
                                            isSelected: isSelected)
            }
        }
        .store(in: &cancellables)
    }
}
