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

import GroundSdk
import Reusable
import SwiftyUserDefaults

/// Generic class to manage advanced settings.
class SettingsContentViewController: UIViewController, StoryboardBased {
    // MARK: - Outlets
    @IBOutlet internal weak var settingsTableView: UITableView!

    // MARK: - Internal Properties
    var coordinator: SettingsCoordinator?
    var cells: [SettingsCellType] = [] {
        didSet {
            settingsTableView?.reloadData()
        }
    }
    var settings: [SettingEntry] = [] {
        didSet {
            generateCells()
        }
    }
    var filteredSettings: [SettingEntry] {
        return settings.filter({ $0.setting != nil })
    }
    /// Reset cell label.
    var resetCellLabel: String?
    /// Settings view model.
    var viewModel: SettingsViewModelProtocol?

    // MARK: - Private Properties
    private var droneStateViewModel: DroneStateViewModel<DeviceConnectionState>?

    // MARK: - Private Enums
    private enum Constants {
        static let estimatedRowHeight: CGFloat = 50.0
        static let tableViewTopInset: CGFloat = 8.0
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .clear

        setupTableView()

        droneStateViewModel = DroneStateViewModel(stateDidUpdate: { [weak self] state in
            self?.updateInputViews(state)
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        settingsTableView.flashScrollIndicators()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - Internal Funcs
    /// Resets settings.
    func resetSettings() {
        viewModel?.resetSettings()
    }

    /// Saves settings.
    func saveSettings() {
        viewModel?.saveSettings()
    }

    /// Returns all setting entries.
    func settingEntries() -> [SettingEntry]? {
        return viewModel?.settingEntries
    }

    /// Updates the data source.
    ///
    /// - Parameters:
    ///     - state: device connection state
    func updateDataSource(_ state: DeviceConnectionState = DeviceConnectionState()) {
        guard let updatedSettings = settingEntries() else { return }

        settings = updatedSettings
    }
}

// MARK: - Private Funcs
private extension SettingsContentViewController {
    /// Reloads Input Views in drone change its state.
    ///
    /// - Parameters:
    ///     - state: device connection state
    func updateInputViews(_ state: DeviceConnectionState = DeviceConnectionState()) {
        self.reloadInputViews()
    }

    /// Setup tableView.
    func setupTableView() {
        settingsTableView.register(cellType: SettingsNetworkNameCell.self)
        settingsTableView.register(cellType: SettingsChooseChannelCell.self)
        settingsTableView.register(cellType: SettingsControlModeCell.self)
        settingsTableView.register(cellType: SettingsSegmentedCell.self)
        settingsTableView.register(cellType: SettingsResetAllButtonCell.self)
        settingsTableView.register(cellType: SettingsSliderCell.self)
        settingsTableView.register(cellType: SettingsButtonCell.self)
        settingsTableView.register(cellType: SettingsRthCell.self)
        settingsTableView.register(cellType: SettingsTitleCell.self)
        settingsTableView.register(cellType: SettingsGridTableViewCell.self)
        settingsTableView.register(cellType: SettingsNetworkSelectionCell.self)
        settingsTableView.register(cellType: SettingsEndHoveringCell.self)
        settingsTableView.estimatedRowHeight = Constants.estimatedRowHeight
        settingsTableView.delaysContentTouches = false
        settingsTableView.contentInset.top = Constants.tableViewTopInset
        settingsTableView.contentInset.bottom = Constants.tableViewTopInset
        settingsTableView.backgroundColor = .clear
    }

    /// Builds cells regarding there type.
    func generateCells() {
        var cells: [SettingsCellType] = filteredSettings
            .compactMap {
                switch $0.setting {
                case is DoubleSetting, is IntSetting:
                    return .slider
                case is BoolSetting, is DefaultsKey<Bool?>, is SettingEnum.Type, is DroneSettingModel:
                    return .segmented
                case is UIImage:
                    return .title
                default:
                    return $0.setting as? SettingsCellType
                }
            }

        // Do not display reset cell if title is not set.
        if resetCellLabel?.isEmpty == false {
            cells.append(.resetAllSettingsButton)
        }
        self.cells = cells
    }

    /// Configure Slider Cell.
    ///
    /// - Parameters:
    ///     - indexPath: cell indexPath
    /// - Returns:
    ///     - UITableViewCell
    func configureSliderCell(at indexPath: IndexPath) -> UITableViewCell {
        let cell = settingsTableView.dequeueReusableCell(for: indexPath) as SettingsSliderCell

        let settingEntry = filteredSettings[indexPath.row]

        cell.configureCell(settingEntry: settingEntry,
                           atIndexPath: indexPath)
        cell.delegate = self
        cell.backgroundColor = settingEntry.bgColor

        return cell
    }

    /// Configure Segmented Cell.
    ///
    /// - Parameters:
    ///     - indexPath: cell indexPath
    /// - Returns:
    ///     - UITableViewCell
    func configureSegmentedCell(at indexPath: IndexPath) -> UITableViewCell {
        let cell = settingsTableView.dequeueReusableCell(for: indexPath) as SettingsSegmentedCell
        cell.delegate = self
        let settingEntry = filteredSettings[indexPath.row]
        if let settingSegments: SettingsSegmentModel = settingEntry.segmentModel {
            cell.configureCell(cellTitle: settingEntry.title,
                               segmentModel: settingSegments,
                               subtitle: settingEntry.subtitle,
                               isEnabled: settingEntry.isEnabled,
                               alpha: settingEntry.cellAlpha,
                               subtitleColor: settingEntry.subtitleColor,
                               showInfo: settingEntry.showInfo,
                               infoText: settingEntry.infoText,
                               atIndexPath: indexPath,
                               isSubmode: settingEntry.isSubMode)
        }

        cell.backgroundColor = settingEntry.bgColor

        return cell
    }

    /// Configure Title Cell.
    ///
    /// - Parameters:
    ///     - indexPath: cell indexPath
    /// - Returns: UITableViewCell
    func configureTitleCell(at indexPath: IndexPath) -> UITableViewCell {
        let cell = settingsTableView.dequeueReusableCell(for: indexPath) as SettingsTitleCell
        let settingEntry = filteredSettings[indexPath.row]
        cell.configureCell(cellTitle: settingEntry.title, cellImage: settingEntry.setting as? UIImage)

        return cell
    }

    /// Configure Reset All Button Cell.
    ///
    /// - Parameters:
    ///     - indexPath: cell indexPath
    /// - Returns: UITableViewCell
    func configureResetAllButtonCell(at indexPath: IndexPath) -> UITableViewCell {
        let cell = settingsTableView.dequeueReusableCell(for: indexPath) as SettingsResetAllButtonCell
        cell.delegate = self
        cell.configureCell(title: resetCellLabel?.uppercased() ?? "")

        return cell
    }
}

// MARK: - UITableView DataSource
extension SettingsContentViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let cellType = cells[indexPath.row]

        switch cellType {
        case .slider:
            cell = configureSliderCell(at: indexPath)
        case .segmented:
            cell = configureSegmentedCell(at: indexPath)
        case .resetAllSettingsButton:
            cell = configureResetAllButtonCell(at: indexPath)
        case .title:
            cell = configureTitleCell(at: indexPath)
        default:
            cell = UITableViewCell()
        }

        cell.selectionStyle = .none

        return cell
    }
}

// MARK: - Settings Slider Cell Delegate
extension SettingsContentViewController: SettingsSliderCellDelegate {
    func settingsSliderCellSliderDidFinishEditing(value: Float, atIndexPath indexPath: IndexPath) {
        let settingEntry = filteredSettings[indexPath.row]
        if let setting = settingEntry.setting as? DoubleSetting {
            setting.value = Double(value)
        }

        saveSettings()
    }
}

// MARK: - Settings Reset All Button Cell Delegate
extension SettingsContentViewController: SettingsResetAllButtonCellDelegate {
    func settingsResetAllButtonCellButtonTouchUpInside() {
        resetSettings()
    }
}

// MARK: - Settings Segmented Cell Delegate
extension SettingsContentViewController: SettingsSegmentedCellDelegate {
    @objc func settingsSegmentedCellDidChange(selectedSegmentIndex: Int, atIndexPath indexPath: IndexPath) {
        let settingEntry = filteredSettings[indexPath.row]
        guard let logKey = settingEntry.itemLogKey else { return }

        // TODO: Add others key when logs will be added
        var newValue: String = ""
        if logKey.contains(LogEvent.LogKeyAdvancedSettings.geofence) {
            newValue = settingEntry.isEnabled.logValue
        } else {
            newValue = LogEvent.formatNewValue(settingEntry: settingEntry,
                                               index: selectedSegmentIndex)
        }

        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.advanced.name,
                             itemName: settingEntry.itemLogKey,
                             newValue: newValue,
                             logType: LogEvent.LogType.button)

        viewModel?.saveSettingsEntry(settingEntry, at: selectedSegmentIndex)

        saveSettings()
    }
}
