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
}

/// Manages Flight Plan edition settings.
final class EditionSettingsViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var deleteButton: UIButton!
    @IBOutlet private weak var tableViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var deleteButtonTrailingConstraint: NSLayoutConstraint! {
        didSet {
            handleTrailingDeleteButton()
        }
    }

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
    private var trailingConstraint: CGFloat {
        if UIApplication.shared.statusBarOrientation == .landscapeLeft {
            return UIApplication.shared.keyWindow?.safeAreaInsets.right ?? 0.0
        } else {
            return 0.0
        }
    }

    // MARK: - Private Enums
    private enum Constants {
        static let sectionNumber: Int = 2
        static let cellHeight: CGFloat = 80.0
        static let titleCellHeight: CGFloat = 60.0
        static let deleteButtonTrailing: CGFloat = 16.0
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
    func updateDataSource(with settingsProvider: FlightPlanSettingsProvider?, savedFlightPlan: SavedFlightPlan?) {
        self.settingsProvider = settingsProvider
        self.settingsProvider?.delegate = self
        self.savedFlightPlan = savedFlightPlan
        self.deleteButton.isHidden = savedFlightPlan != nil || settingsProvider is WayPointSegmentSettingsProvider

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

        self.tableView.reloadData()
    }

    /// Updates the top constraint of the tableview.
    ///
    /// - Parameters:
    ///     - value: contraint value
    func updateTopTableViewConstraint(_ value: CGFloat) {
        self.tableViewTopConstraint.constant = value
    }

    /// Refreshes table view data for Flight Plan estimation updates.
    func refreshEstimationsIfNeeded() {
        guard settingsProvider is ClassicFlightPlanSettingsProvider else { return }

        self.tableView.reloadData()
    }
}

// MARK: - Actions
private extension EditionSettingsViewController {
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
        tableView.backgroundColor = .clear
        tableView.register(cellType: AdjustmentTableViewCell.self)
        tableView.register(cellType: ModesChoiceTableViewCell.self)
        tableView.register(cellType: SettingValuesChoiceTableViewCell.self)
        tableView.register(cellType: CenteredRulerTableViewCell.self)
        tableView.register(cellType: FlightPlanSettingTitleCell.self)
        tableView.register(cellType: FlightPlanEstimationsTableViewCell.self)
        tableView.tableFooterView = UIView()
        tableView.alwaysBounceVertical = false

        deleteButton.cornerRadiusedWith(backgroundColor: ColorName.redTorch50.color,
                                        radius: Style.mediumCornerRadius)
        deleteButton.makeup(with: .regular,
                            color: .white,
                            and: .normal)
        deleteButton.setTitle(L10n.commonDelete, for: .normal)
    }

    /// Handles the trailing constraint of the delete button.
    func handleTrailingDeleteButton() {
        let constraint = trailingConstraint
        deleteButtonTrailingConstraint.constant = constraint == 0 ? Constants.deleteButtonTrailing : constraint
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
        handleTrailingDeleteButton()
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource
extension EditionSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Constants.sectionNumber
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return settingsProvider?.hasCustomType == true ? 2 : 1
        case 1:
            return fpSettings?.count ?? settingsProvider?.settings.count ?? 0
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return cellForFirstSection(indexPath: indexPath)
        } else {
            return cellForSecondSection(indexPath: indexPath)
        }
    }

    /// Returns cell for first section. Either a mode choice, or a simple title.
    ///
    /// - Parameters:
    ///    - indexPath: the index path
    /// - Returns: cell to display
    private func cellForFirstSection(indexPath: IndexPath) -> UITableViewCell {
        if settingsProvider?.hasCustomType == true, indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(for: indexPath) as ModesChoiceTableViewCell
            cell.fill(with: settingsProvider)
            cell.updateTrailingConstraint(trailingConstraint)
            cell.delegate = self
            cell.backgroundColor = .clear

            return cell
        } else {
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
                title = L10n.flightPlanSettingsTitle
            }
            cell.fill(with: title)
            cell.updateTrailingConstraint(trailingConstraint)

            return cell
        }
    }

    /// Returns cell for second section. Displays a setting.
    ///
    /// - Parameters:
    ///    - indexPath: the index path
    /// - Returns: cell to display
    private func cellForSecondSection(indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell & EditionSettingsCellModel
        let setting: FlightPlanSettingType? = self.fpSettings?[indexPath.row] ?? self.settingsProvider?.settings[indexPath.row]

        switch setting?.type {
        case .adjustement:
            cell = tableView.dequeueReusableCell(for: indexPath) as AdjustmentTableViewCell
        case .centeredRuler:
            cell = tableView.dequeueReusableCell(for: indexPath) as CenteredRulerTableViewCell
        case .choice:
            cell = tableView.dequeueReusableCell(for: indexPath) as SettingValuesChoiceTableViewCell
        case .estimations:
            let estimationsCell = tableView.dequeueReusableCell(for: indexPath) as FlightPlanEstimationsTableViewCell
            estimationsCell.fill(with: savedFlightPlan?.plan.estimations)
            estimationsCell.updateTrailingConstraint(trailingConstraint)

            return estimationsCell
        default:
            fatalError("Unhandled cell type")
        }

        cell.backgroundColor = .clear
        cell.fill(with: setting)
        cell.disableCell(setting?.isDisabled == true)
        cell.updateTrailingConstraint(trailingConstraint)
        cell.delegate = self

        return cell
    }
}

// MARK: - ModesChoiceTableViewCell
extension EditionSettingsViewController: ModesChoiceTableViewCellDelegate {
    func updateMode(tag: Int) {
        delegate?.updateMode(tag: tag)
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
        self.tableView.reloadData()
    }
}
