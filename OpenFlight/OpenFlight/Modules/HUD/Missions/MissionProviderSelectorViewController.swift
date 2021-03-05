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

/// Class that manages mission launcher menu to choose between avaialable missions provider.
final class MissionProviderSelectorViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            titleLabel.makeUp(with: .largeMedium, and: .greenSpring)
            titleLabel.text = L10n.missionSelectLabel
        }
    }
    @IBOutlet private weak var tableView: UITableView! {
        didSet {
            tableView.register(cellType: MissionItemCell.self)
            tableView.tableFooterView = UIView() // Prevent extra separators
            tableView.separatorColor = ColorName.white20.color
        }
    }

    // MARK: - Internal Properties
    var viewModel: MissionLauncherViewModel? {
        didSet {
            updateModels()
        }
    }

    // MARK: - Private Properties
    private var models = [MissionLauncherState]() {
        didSet {
            tableView?.reloadData()
        }
    }
}

// MARK: - UITableViewDataSource
extension MissionProviderSelectorViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: MissionItemCell.self)
        let model = models[indexPath.row]
        cell.setup(with: model)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MissionProviderSelectorViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        LogEvent.logAppEvent(itemName: models[indexPath.row].title?.description,
                             logType: .simpleButton)
        let model = models[indexPath.row]
        if model.isSelected.value == true {
            // Special case when item is already currently selected.
            model.isSelected.set(false)
            model.isSelected.set(true)
        } else {
            model.isSelected.set(true)
        }
    }
}

// MARK: - Private Funcs
private extension MissionProviderSelectorViewController {
    /// Generate models for table view cells from viewModel modes.
    func updateModels() {
        guard let provider = viewModel?.state.value.provider else { return }

        models = MissionsManager.shared.allMissions.map {
            let itemState = MissionLauncherState(provider: $0,
                                                 isSelected: Observable(provider.mission.key == $0.mission.key))
            itemState.isSelected.valueChanged = { [weak self] isSelected in
                if isSelected, let provider = itemState.provider {
                    if provider.mission.modes.count == 1,
                       let mode = provider.mission.modes.first {
                        // Handle one mode case: auto select the unique mode.
                        self?.viewModel?.update(provider: provider)
                        self?.viewModel?.update(mode: mode)
                        self?.viewModel?.toggleSelectionState()
                    } else {
                        // Handle multiple modes case: present modes.
                        self?.addModeSelection(withMissionProvider: provider)
                    }
                    self?.updateModels()
                }
            }
            return itemState
        }
        tableView?.reloadData()
    }

    /// Add mission mode selection view controller as child.
    ///
    /// - Parameters:
    ///    - provider: parent provider for submode.
    func addModeSelection(withMissionProvider provider: MissionProvider?) {
        let missionModeVC = StoryboardScene.Missions.missionSelectorViewController.instantiate()
        missionModeVC.selectedProvider = provider
        missionModeVC.viewModel = viewModel
        add(missionModeVC)
        let transition = CATransition()
        transition.type = CATransitionType.reveal
        transition.subtype = CATransitionSubtype.fromRight
        view.layer.add(transition, forKey: nil)
        view.addWithConstraints(subview: missionModeVC.view)
        missionModeVC.didMove(toParent: self)
    }
}
