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
    func didTapOnUndo()

    /// User can undo changes
    func canUndo() -> Bool
}

/// Manages Flight Plan edition settings.
final class EditionSettingsViewController: UIViewController {
    weak var coordinator: Coordinator?
    // MARK: - Outlets
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var deleteButton: UIButton!
    @IBOutlet private weak var undoButton: UIButton! {
        didSet {
            undoButton.cornerRadiusedWith(backgroundColor: ColorName.white.color,
                                          radius: Style.largeCornerRadius)
            undoButton.makeup(color: .defaultTextColor)
            undoButton.setTitle(L10n.commonUndo, for: .normal)
        }
    }

    // MARK: - Internal Properties
    weak var delegate: EditionSettingsDelegate?
    var viewModel: EditionSettingsViewModel!
    private var cancellables = [AnyCancellable]()
    private var trailingMargin: CGFloat {
        if UIApplication.shared.statusBarOrientation == .landscapeLeft {
            return UIApplication.shared.keyWindow?.safeAreaInsets.right ?? 0.0
        } else {
            return 0.0
        }
    }

    // MARK: - Private Enums
    private enum SectionsType: Int, CaseIterable {
        case settings
    }

    // MARK: - Private Enums
    private enum Constants {
        static let tableViewHeaderHeight: CGFloat = 42
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
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

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension EditionSettingsViewController {
    @IBAction func undoButtonTouchedUpInside(_ sender: Any) {
        delegate?.didTapOnUndo()
        self.viewModel.refreshContent()
    }

    @IBAction func deleteButtonTouchedUpInside(_ sender: Any) {
        delegate?.didTapDeleteButton()
    }
}

// MARK: - Private Funcs
private extension EditionSettingsViewController {
    /// Inits the view.
    func initView() {
        tableView.insetsContentViewsToSafeArea = false // Safe area is handled in this VC, not in content
        tableView.register(cellType: AdjustmentTableViewCell.self)
        tableView.register(cellType: SettingValuesChoiceTableViewCell.self)
        tableView.register(cellType: CenteredRulerTableViewCell.self)
        tableView.register(cellType: FlightPlanSettingInfoCell.self)
        tableView.register(headerFooterViewType: FlightPlanSettingTitleCell.self)
        tableView.delegate = self
        tableView.makeUp(backgroundColor: .clear)

        deleteButton.cornerRadiusedWith(backgroundColor: ColorName.errorColor.color,
                                        radius: Style.mediumCornerRadius)
        deleteButton.makeup()
        deleteButton.setTitle(L10n.commonDelete, for: .normal)
        deleteButton.isHidden = true

        undoButton.cornerRadiusedWith(backgroundColor: ColorName.white.color,
                                      radius: Style.largeCornerRadius)
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
                    self.tableView.reloadData()
                }
            }
            .store(in: &cancellables)
    }

    /// Updates undo button.
    func updateUndoButton() {
        undoButton.isEnabled = delegate.map({ $0.canUndo() }) ?? false
        undoButton.alphaWithEnabledState(undoButton.isEnabled)
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
        let setting: FlightPlanSettingType? = viewModel.dataSource[indexPath.row]

        switch setting?.type {
        case .adjustement:
            switch setting?.unit {
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

        cell.backgroundColor = .clear
        cell.fill(with: setting)
        cell.disableCell(setting?.isDisabled == true)
        cell.delegate = self
        return cell
    }
}

// MARK: - UITableViewDelegate
extension EditionSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let identifier = FlightPlanSettingTitleCell.reuseIdentifier
        guard let cell = self.tableView.dequeueReusableHeaderFooterView(withIdentifier: identifier) as? FlightPlanSettingTitleCell
        else { return nil }

        let title: String
        let isImageHidden: Bool = false
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
        cell.fill(with: title, and: isImageHidden)
        cell.delegate = self
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Constants.tableViewHeaderHeight
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

extension EditionSettingsViewController: FlightPlanSettingTitleDelegate {
    func dismiss() {
        delegate?.didTapCloseButton()
    }
}
