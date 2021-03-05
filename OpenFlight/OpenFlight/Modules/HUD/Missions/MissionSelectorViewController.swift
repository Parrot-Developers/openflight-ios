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

/// Class that manages mission launcher menu to choose between avaialable missions modes.

final class MissionSelectorViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var headerView: CurrentMissionItemModeView!
    @IBOutlet private weak var tableView: UITableView! {
        didSet {
            tableView.register(cellType: MissionItemCell.self)
            tableView.tableFooterView = UIView() // Prevent extra separators
        }
    }

    // MARK: - Internal Properties
    var viewModel: MissionLauncherViewModel? {
        didSet {
            updateModels()
        }
    }

    var selectedProvider: MissionProvider? {
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

    // MARK: - Private Enums
    private enum Constants {
        static let selectionDelay: TimeInterval = 0.2
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        headerView.model = MissionProviderState(provider: selectedProvider, mode: nil)
        listenViewModel()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - UITableViewDataSource
extension MissionSelectorViewController: UITableViewDataSource {
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
extension MissionSelectorViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = models[indexPath.row]

        LogEvent.logAppEvent(itemName: LogEvent.formatItemName(missionModeState: model),
                             newValue: model.title?.description,
                             logType: .button)

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
private extension MissionSelectorViewController {
    /// Listens the view model.
    func listenViewModel() {
        viewModel?.state.valueChanged = { [weak self] _ in
            self?.updateModels()
        }
    }

    /// Generate models for table view cells from viewModel subModes.
    func updateModels() {
        guard let provider = selectedProvider,
            let subMode = viewModel?.state.value.mode else {
                return
        }

        models = provider.mission.modes.map {
            let itemState = MissionLauncherState(provider: provider,
                                                 mode: $0,
                                                 isSelected: Observable(subMode.key == $0.key))
            itemState.isSelected.valueChanged = { [weak self] isSelected in
                if isSelected, let subMode = itemState.mode {
                    self?.viewModel?.update(provider: provider)
                    self?.viewModel?.update(mode: subMode)
                    self?.tableView?.isUserInteractionEnabled = false // Prevents double tap issues.
                    DispatchQueue.main.asyncAfter(deadline: .now() + Constants.selectionDelay) {
                        self?.viewModel?.toggleSelectionState()
                        self?.tableView?.isUserInteractionEnabled = true // Prevents double tap issues.
                    }
                }
            }
            return itemState
        }

        tableView?.reloadData()
    }

    /// Remove current view controller from parent.
    func removeFromParentVC() {
        willMove(toParent: nil)
        let transition = CATransition()
        transition.type = CATransitionType.moveIn
        transition.subtype = CATransitionSubtype.fromLeft
        view.superview?.layer.add(transition, forKey: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}

// MARK: - Actions
private extension MissionSelectorViewController {
    @IBAction func didTouchHeaderView(sender: Any) {
        removeFromParentVC()
    }
}
