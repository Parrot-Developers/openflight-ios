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
import Reusable
import Combine

// MARK: - Protocols
public protocol EditionSettingsDelegate: EditionSettingsCellModelDelegate {
    /// Updates current flight plan mode.
    ///
    /// - Parameters:
    ///     - tag: mode identifier
    func updateMode(tag: Int)

    /// User tapped settings close button.
    func didTapCloseButton()

    /// User tapped settings delete button.
    func didTapDeleteButton()

    /// User tapped undo button.
    ///
    /// - Parameters:
    ///   - action: Any action to execute before displaying the flight plan.
    func didTapOnUndo(action: (() -> Void)?)

    /// User can undo changes
    func canUndo() -> Bool
}

/// Manages Flight Plan edition settings.
final class EditionSettingsViewController: UIViewController {
    weak var coordinator: Coordinator?
    // MARK: - Outlets
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var topBarContainer: UIView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var deleteButton: ActionButton!
    @IBOutlet private weak var undoButton: ActionButton!
    @IBOutlet private weak var buttonsStackView: MainContainerStackView!
    @IBOutlet private weak var bottomGradientView: BottomGradientView!

    // MARK: - Internal Properties
    weak var delegate: EditionSettingsDelegate?
    var viewModel: EditionSettingsViewModel!
    private var topbar: FlightPlanTopBarViewController?
    private var cancellables = [AnyCancellable]()

    // MARK: - Private Enums
    private enum SectionsType: Int, CaseIterable {
        case settings
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier == "topBarSegue" {
            topbar = segue.destination as? FlightPlanTopBarViewController
        }
    }
}

// MARK: - Actions
private extension EditionSettingsViewController {
    @IBAction func undoButtonTouchedUpInside(_ sender: Any) {
        delegate?.didTapOnUndo(action: nil)
        viewModel.refreshContent()
    }

    @IBAction func deleteButtonTouchedUpInside(_ sender: Any) {
        delegate?.didTapDeleteButton()
    }
}

// MARK: - Private Funcs
private extension EditionSettingsViewController {
    /// Inits the view.
    func initView() {
        tableView.insetsContentViewsToSafeArea = false
        tableView.register(cellType: AdjustmentTableViewCell.self)
        tableView.register(cellType: SettingValuesChoiceTableViewCell.self)
        tableView.register(cellType: CenteredRulerTableViewCell.self)
        tableView.register(cellType: FlightPlanSettingInfoCell.self)
        tableView.register(FlightPlanSettingSeparatorCell.self,
                           forCellReuseIdentifier: FlightPlanSettingSeparatorCell.reuseIdentifier)
        tableView.makeUp(backgroundColor: .clear)

        deleteButton.setup(title: L10n.commonDelete, style: .destructive)
        deleteButton.isHidden = true

        undoButton.setup(title: L10n.commonUndo, style: .default1)

        buttonsStackView.screenBorders = [.bottom, .right]

        updateTopBarTitle()
        topbar?.backButton.addTarget(self, action: #selector(backAction), for: .touchUpInside)

        // Keeps the topBar shadow above the tableView
        stackView.bringSubviewToFront(topBarContainer)

        bottomGradientView.isHidden = true
    }

    func bindViewModel() {
        viewModel.$viewState
            .compactMap({ $0 })
            .sink { [unowned self] state in
                switch state {
                case let .updateUndo(categoryFilter):
                    self.undoButton.isHidden = categoryFilter == .common || categoryFilter == .image
                    self.updateUndoButton()
                case let .selectedGraphic(selectedGraphic):
                    self.deleteButton.isHidden = selectedGraphic?.deletable != true
                case .reload:
                    updateTopBarTitle()
                    self.tableView.reloadData()
                }
                bottomGradientView.isHidden = deleteButton.isHidden && undoButton.isHidden
            }
            .store(in: &cancellables)
    }

    /// Updates undo button.
    func updateUndoButton() {
        undoButton.isEnabled = delegate.map({ $0.canUndo() }) ?? false
    }

    @objc func backAction() {
        delegate?.didTapCloseButton()
    }

    func updateTopBarTitle() {
        let title: String
        switch viewModel.settingsProvider {
        case is WayPointSettingsProvider:
            title = L10n.commonWaypoint
        case is PoiPointSettingsProvider:
            title = L10n.commonPoi
        case is WayPointSegmentSettingsProvider,
            nil:
            title = L10n.flightPlanSegmentSettingsTitle
        default:
            title = viewModel.settingsCategoryFilter?.title ?? L10n.flightPlanSettingsTitle
        }
        topbar?.set(title: title)
    }
}

// MARK: - UITableViewDataSource
extension EditionSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return SectionsType.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell & EditionSettingsCellModel
        let setting: EditionSettingsViewModel.Setting = viewModel.dataSource[indexPath.row]

        switch setting {
        case .separator:
            return tableView.dequeueReusableCell(withIdentifier: FlightPlanSettingSeparatorCell.reuseIdentifier,
                                                 for: indexPath)
        case .setting(let setting):
            switch setting.type {
            case .adjustement:
                switch setting.unit {
                case .centimeterPerpixel:
                    cell = tableView.dequeueReusableCell(for: indexPath) as FlightPlanSettingInfoCell
                default:
                    cell = tableView.dequeueReusableCell(for: indexPath) as AdjustmentTableViewCell
                }
            case .centeredRuler:
                cell = tableView.dequeueReusableCell(for: indexPath) as CenteredRulerTableViewCell
            case .choice:
                cell = tableView.dequeueReusableCell(for: indexPath) as SettingValuesChoiceTableViewCell
            default:
                fatalError("Unhandled cell type")
            }
            cell.fill(with: setting)
            cell.disableCell(setting.isDisabled == true)
        }

        cell.backgroundColor = .clear
        cell.delegate = self
        return cell
    }
}

// MARK: - EditionSettingsCellModelDelegate
extension EditionSettingsViewController: EditionSettingsCellModelDelegate {

    func updateSettingValue(for key: String?, value: Int) {
        delegate?.updateSettingValue(for: key, value: value)
    }

    func updateChoiceSetting(for key: String?, value: Bool) {
        delegate?.updateChoiceSetting(for: key, value: value)
    }
}
