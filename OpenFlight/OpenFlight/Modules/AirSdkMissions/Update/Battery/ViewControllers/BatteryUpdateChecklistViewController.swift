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

import UIKit
import Combine

/// Interface for the check list before battery update.
///
/// The battery gauge update cannot be started before some requirements are met.
/// This view shows the missing requirements to the user and enables the update when ready.
final class BatteryUpdateChecklistViewController: UIViewController {

    // MARK: - Private Enums
    enum Constants {
        static let tableViewHeightRegular: CGFloat = 40.0
        static let tableViewHeightCompact: CGFloat = 35.0
    }

    // MARK: - Outlets
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var continueButton: ActionButton!

    // MARK: - Private Properties
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    private weak var coordinator: DroneFirmwaresCoordinator?
    private var viewModel: BatteryUpdateChecklistViewModel!

    // MARK: - Setup
    static func instantiate(coordinator: DroneFirmwaresCoordinator, viewModel: BatteryUpdateChecklistViewModel) -> BatteryUpdateChecklistViewController {
        let viewController = StoryboardScene.BatteryUpdateChecklist.initialScene.instantiate()
        viewController.coordinator = coordinator
        viewController.viewModel = viewModel
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        setupTableView()
        listenBatteryUpdater()
    }

    /// Inits the UI.
    func initUI() {
        cancelButton.setTitle(L10n.cancel, for: .normal)
        continueButton.setup(title: L10n.commonContinue, style: .action1)
        titleLabel.text = L10n.batteryUpdateChecklistTitle
        instructionLabel.text = L10n.batteryUpdateChecklistInstruction
    }

    /// Sets up the table view.
    func setupTableView() {
        tableView.allowsSelection = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView = UIView()
        tableView.separatorColor = .clear
        tableView.register(cellType: BatteryUpdateReasonsCell.self)
    }

    /// Listens to the battery updater peripheral in order to display the missing requirements.
    func listenBatteryUpdater() {
        viewModel.datasourcePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)

        viewModel.$unavailabilityReasons
            .receive(on: RunLoop.main)
            .sink { [weak self] unavailabilityReasons in
                self?.toggleContinueButton(isEnabled: unavailabilityReasons.isEmpty)
            }
            .store(in: &cancellables)
    }

    /// Enables or disables the continue button.
    func toggleContinueButton(isEnabled: Bool) {
        continueButton.isEnabled = isEnabled
    }

    // MARK: - IBActions
    @IBAction func onContinueButtonTouchUpInside() {
        coordinator?.goToBatteryUpdate()
    }

    @IBAction func onCancelButtonTouchUpInside() {
        coordinator?.back()
    }
}

// MARK: - UITableViewDelegate
extension BatteryUpdateChecklistViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return isRegularSizeClass ? Constants.tableViewHeightRegular : Constants.tableViewHeightCompact
    }
}

// MARK: - UITableViewDataSource
extension BatteryUpdateChecklistViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.datasource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as BatteryUpdateReasonsCell
        cell.setup(content: viewModel.datasource[indexPath.row])
        return cell
    }
}
