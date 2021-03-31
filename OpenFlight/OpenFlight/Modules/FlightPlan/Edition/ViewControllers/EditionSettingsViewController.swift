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
}

/// Manages Flight Plan edition settings.
final class EditionSettingsViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var deleteButton: UIButton!
    @IBOutlet private weak var undoButton: UIButton!
    @IBOutlet private weak var tableViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var tableViewTrailingConstraint: NSLayoutConstraint!

    // MARK: - Internal Properties
    weak var delegate: EditionSettingsDelegate?
    /// Provider used to get the settings of the flight plan provider.
    var settingsProvider: FlightPlanSettingsProvider?
    /// The current flight plan which contains the settings.
    var savedFlightPlan: SavedFlightPlan? {
        didSet {
            guard let strongFlightPlan = savedFlightPlan else { return }

            self.fpSettings = settingsProvider?.settings(for: strongFlightPlan)
        }
    }

    // MARK: - Private Properties
    private var fpSettings: [FlightPlanSetting]?
    private var settingsCategoryFilter: FlightPlanSettingCategory?
    private var dataSource: [FlightPlanSetting] {
        let settings = self.fpSettings ?? self.settingsProvider?.settings ?? []
        if let filter = settingsCategoryFilter {
            return settings.filter({ $0.category == filter })
        } else {
            return settings
        }
    }
    private var trailingMargin: CGFloat {
        if UIApplication.shared.statusBarOrientation == .landscapeLeft {
            return UIApplication.shared.keyWindow?.safeAreaInsets.right ?? 0.0
        } else {
            return 0.0
        }
    }

    // MARK: - Private Enums
    private enum SectionsType: Int, CaseIterable {
        case header
        case settings
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        setupOrientationObserver()
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

    // MARK: - Internal Funcs
    /// Update collection view data.
    ///
    /// - Parameters:
    ///     - settingsProvider: current settings provider
    ///     - savedFlightPlan: current flight plan
    ///     - selectedGraphic: selected graphic
    func updateDataSource(with settingsProvider: FlightPlanSettingsProvider?,
                          savedFlightPlan: SavedFlightPlan?,
                          selectedGraphic: FlightPlanGraphic?) {
        self.settingsProvider = settingsProvider
        self.settingsProvider?.delegate = self
        self.savedFlightPlan = savedFlightPlan
        self.deleteButton.isHidden = selectedGraphic == nil

        switch settingsProvider {
        case is WayPointSettingsProvider,
             is PoiPointSettingsProvider,
             is WayPointSegmentSettingsProvider:
            self.fpSettings = settingsProvider?.settings
        case nil:
            self.fpSettings = []
        default:
            break
        }

        self.refreshContent(categoryFilter: settingsCategoryFilter)
    }

    /// Updates the top constraint of the tableview.
    ///
    /// - Parameters:
    ///     - value: contraint value
    func updateTopTableViewConstraint(_ value: CGFloat) {
        self.tableViewTopConstraint.constant = value
    }

    /// Refreshes view data.
    ///
    /// - Parameters:
    ///     - categoryFilter: allows to filter setting category
    func refreshContent(categoryFilter: FlightPlanSettingCategory?) {
        self.settingsCategoryFilter = categoryFilter
        self.tableView.reloadData()
        updateUndoButton()
    }
}

// MARK: - Actions
private extension EditionSettingsViewController {
    @IBAction func undoButtonTouchedUpInside(_ sender: Any) {
        delegate?.didTapOnUndo()
        refreshContent(categoryFilter: settingsCategoryFilter)
    }

    @IBAction func closeButtonTouchedUpInside(_ sender: Any) {
        delegate?.didTapCloseButton()
    }

    @IBAction func deleteButtonTouchedUpInside(_ sender: Any) {
        delegate?.didTapDeleteButton()
    }
}

// MARK: - Private Funcs
private extension EditionSettingsViewController {
    /// Inits the view.
    func initView() {
        tableView.register(cellType: AdjustmentTableViewCell.self)
        tableView.register(cellType: SettingValuesChoiceTableViewCell.self)
        tableView.register(cellType: CenteredRulerTableViewCell.self)
        tableView.register(cellType: FlightPlanSettingTitleCell.self)
        tableView.makeUp(backgroundColor: .clear)

        deleteButton.cornerRadiusedWith(backgroundColor: ColorName.redTorch50.color,
                                        radius: Style.mediumCornerRadius)
        deleteButton.makeup(with: .regular,
                            color: .white,
                            and: .normal)
        deleteButton.setTitle(L10n.commonDelete, for: .normal)

        undoButton.cornerRadiusedWith(backgroundColor: ColorName.white20.color,
                                      radius: Style.largeCornerRadius)
    }

    /// Updates undo button.
    func updateUndoButton() {
        undoButton.isEnabled = FlightPlanManager.shared.canUndo()
        undoButton.alphaWithEnabledState(undoButton.isEnabled)
    }

    /// Sets up observer for orientation change.
    func setupOrientationObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateSafeAreaConstraints),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }

    /// Updates safe area constraints.
    @objc func updateSafeAreaConstraints() {
        tableViewTrailingConstraint.constant = trailingMargin
    }
}

// MARK: - UITableViewDataSource
extension EditionSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return SectionsType.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch SectionsType(rawValue: section) {
        case .header:
            return 1
        case .settings:
            return dataSource.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch SectionsType(rawValue: indexPath.section) {
        case .header:
            return cellForHeaderSection(indexPath: indexPath)
        default:
            return cellForSettingsSection(indexPath: indexPath)
        }
    }

    /// Returns cell for header section.
    /// Setting(s) title is defined here.
    ///
    /// - Parameters:
    ///    - indexPath: the index path
    /// - Returns: cell to display
    private func cellForHeaderSection(indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as FlightPlanSettingTitleCell
        let title: String
        switch settingsProvider {
        case is WayPointSettingsProvider:
            title = L10n.commonWaypoint
        case is PoiPointSettingsProvider:
            title = L10n.commonPoi
        case is WayPointSegmentSettingsProvider,
             nil:
            title = ""
        default:
            title = settingsCategoryFilter?.title ?? L10n.flightPlanSettingsTitle
        }
        cell.fill(with: title)

        return cell
    }

    /// Returns cell for settings section. Displays a setting.
    ///
    /// - Parameters:
    ///    - indexPath: the index path
    /// - Returns: cell to display
    private func cellForSettingsSection(indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell & EditionSettingsCellModel
        let setting: FlightPlanSettingType? = self.dataSource[indexPath.row]

        switch setting?.type {
        case .adjustement:
            cell = tableView.dequeueReusableCell(for: indexPath) as AdjustmentTableViewCell
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

// MARK: - EditionSettingsCellModelDelegate
extension EditionSettingsViewController: EditionSettingsCellModelDelegate {
    func updateSettingValue(for key: String?, value: Int) {
        delegate?.updateSettingValue(for: key, value: value)
    }

    func updateChoiceSetting(for key: String?, value: Bool) {
        delegate?.updateChoiceSetting(for: key, value: value)
    }
}

// MARK: - FlightPlanSettingsProviderDelegate
extension EditionSettingsViewController: FlightPlanSettingsProviderDelegate {
    func didUpdateSettings() {
        refreshContent(categoryFilter: settingsCategoryFilter)
    }
}
