//
//  MissionProviderSelectorViewModel.swift
//  OpenFlight
//
//  Created by Pierre Mardon on 21/06/2021.
//  Copyright © 2021 Parrot Drones SAS. All rights reserved.
//

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
