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

import UIKit
import Combine

public protocol BuildingHeightMenuViewControllerDelagate: AnyObject {
    func buildingHeightSettingUpdated(value: Int)
}

/// Building height edition menu.
final class BuildingHeightMenuViewController: UIViewController {
    weak var coordinator: EditionSettingsCoordinator?
    // MARK: - IBOutlets
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var topBarContainer: UIView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var doneButton: ActionButton!
    @IBOutlet private weak var buttonsStackView: MainContainerStackView!
    @IBOutlet private weak var bottomGradientView: BottomGradientView!

    // MARK: - Public Properties
    var viewModel: EditionSettingsViewModel!
    private var cancellables = [AnyCancellable]()
    private var topbar: FlightPlanTopBarViewController?

    // MARK: - Private Enums
    private enum Constants {
        static let cellheight: CGFloat = 164.0
    }

    private weak var delegate: BuildingHeightMenuViewControllerDelagate?

    static func instantiate(viewModel: EditionSettingsViewModel,
                            coordinator: EditionSettingsCoordinator,
                            delegate: BuildingHeightMenuViewControllerDelagate) -> BuildingHeightMenuViewController? {
        guard let viewController = StoryboardScene.FlightPlanEdition.storyboard
            .instantiateViewController(identifier: "BuildingHeightMenuViewController") as? BuildingHeightMenuViewController
        else {
            return nil
        }
        viewController.viewModel = viewModel
        viewController.coordinator = coordinator
        viewController.delegate = delegate
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
    }

    private func bindViewModel() {
        viewModel.$viewState
            .compactMap({ $0 })
            .sink { [unowned self] state in
                switch state {
                case .selectedGraphic:
                    break
                case .reload:
                    tableView.reloadData()
                }
            }
            .store(in: &cancellables)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier == "topBarSegue" {
            topbar = segue.destination as? FlightPlanTopBarViewController
        }
    }
}

// MARK: - Actions
private extension BuildingHeightMenuViewController {

    @IBAction func doneTouchUpInside(_ sender: Any) {
        coordinator?.dismissBuildingHeightPickerIfNeeded()
    }
}

// MARK: - Private Funcs
private extension BuildingHeightMenuViewController {
    /// Inits the view.
    func initView() {
        tableView.insetsContentViewsToSafeArea = false
        tableView.register(cellType: WarningCenteredRulerTableViewCell.self)
        tableView.dataSource = self
        tableView.estimatedRowHeight = Constants.cellheight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset.top = Layout.mainPadding(isRegularSizeClass)
        tableView.contentInset.bottom = Layout.mainContainerInnerMargins(isRegularSizeClass).bottom +
        Layout.mainPadding(isRegularSizeClass) +
        Layout.buttonIntrinsicHeight(isRegularSizeClass)
        tableView.makeUp(backgroundColor: .clear)

        doneButton.setup(title: L10n.flightPlanSettingBuildingHeightAction, style: .action1)
        buttonsStackView.screenBorders = [.bottom, .right]

        // Keeps the topBar shadow above the tableView
        stackView.bringSubviewToFront(topBarContainer)
        topbar?.set(projectTitle: viewModel.savedFlightPlan?.pictorModel.name)
        topbar?.set(title: L10n.flightPlanSettingBuildingHeightTitle)
        topbar?.set(backbuttonVisibility: false)
    }
}

// MARK: - UITableViewDataSource
extension BuildingHeightMenuViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as WarningCenteredRulerTableViewCell
        let setting = viewModel.dataSource.compactMap { (setting: EditionSettingsViewModel.Setting) -> FlightPlanSetting? in
            if case let EditionSettingsViewModel.Setting.setting(flightPlanSetting) = setting,
               flightPlanSetting.key == "buildingHeight" { return flightPlanSetting }
            return nil
        }.first
        cell.backgroundColor = .clear
        cell.fill(with: setting)
        cell.titleLabel.text = L10n.flightPlanSettingBuildingHeightDescription
        cell.disableCell(setting?.isDisabled == true)
        cell.delegate = self
        return cell
    }
}

// MARK: - EditionSettingsCellModelDelegate
extension BuildingHeightMenuViewController: EditionSettingsCellModelDelegate {

    func updateSettingValue(for key: String?, value: Int) {
        guard let key = key else { return }
        updateSetting(forKey: key, withValue: value)
    }
}

// MARK: - Private Funcs
extension BuildingHeightMenuViewController {
    private func updateSetting(forKey key: String, withValue value: Int) {
        delegate?.buildingHeightSettingUpdated(value: value)
    }
}
