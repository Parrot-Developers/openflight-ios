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
import GroundSdk
import Combine

/// Settings content sub class dedicated to network settings.
final class SettingsNetworkViewController: SettingsContentViewController {
    // MARK: - Private Properties
    private let networkViewModel = SettingsNetworkViewModel(currentDroneHolder: Services.hub.currentDroneHolder)
    private var wifiNameIndex: Int?
    private var cellularDataIndex: Int?

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        setupViewModel()
    }

    /// Reset to default settings.
    override func resetSettings() {
        LogEvent.log(.simpleButton(LogEvent.LogKeyAdvancedSettings.resetNetworkSettings))

        networkViewModel.resetSettings()
    }

    override func settingsSegmentedCellDidChange(selectedSegmentIndex: Int, atIndexPath indexPath: IndexPath) {
        let settingEntry = filteredSettings[indexPath.row]
        if let logItem = settingEntry.itemLogKey {
            LogEvent.log(.button(item: logItem,
                                 value: LogEvent.formatNewValue(settingEntry: settingEntry,
                                                                index: selectedSegmentIndex)))
        }
        settingEntry.save(at: selectedSegmentIndex)
    }
}

// MARK: - UITableViewDataSource
extension SettingsNetworkViewController {
    /// Initializes view.
    func initView() {
        view.directionalLayoutMargins = Layout.mainContainerInnerMargins(isRegularSizeClass,
                                                                         screenBorders: [.top, .bottom])
        // Add tap observer to dismiss keyboard
        let touchGesture = UITapGestureRecognizer(target: self,
                                                  action: #selector(dismissKeyboard))
        view.addGestureRecognizer(touchGesture)

        // Add keyboard observers.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(sender:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(sender:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    /// Sets up view model.
    func setupViewModel() {
        networkViewModel.$isNotFlying
            .removeDuplicates()
            .combineLatest(networkViewModel.wifiAccessPointPublisher,
                           networkViewModel.wifiScannerPublisher)
            .combineLatest(networkViewModel.$isEditing,
                           networkViewModel.isChannelsEnabledPublisher,
                           networkViewModel.driPublisher)
            .sink { [weak self] (arg0, isEditing, _, _) in
                let (isNotFlying, _, _) = arg0
                guard let self = self else { return }
                if !isEditing {
                    self.updateDataSource(isNotFlying)
                }
            }
            .store(in: &cancellables)

        networkViewModel.infoHandler = { [weak self] _ in
            self?.coordinator?.startDriInfoScreen()
        }

        // Inital data source update.
        updateDataSource(networkViewModel.isNotFlying)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let cellType = cells[indexPath.row]

        switch cellType {
        case .networkName:
            cell = configureNetworkNameCell(atIndexPath: indexPath)
            wifiNameIndex = indexPath.row
        case .wifiChannels:
            cell = configureChannelCell(atIndexPath: indexPath)
        case .cellularData:
            cell = configureCellularDataCell(atIndexPath: indexPath)
            cellularDataIndex = indexPath.row
        case .dri:
            cell = configureDriCell(at: indexPath)
        default:
            cell = super.tableView(tableView, cellForRowAt: indexPath)
        }

        cell.selectionStyle = .none
        cell.backgroundColor = .clear

        return cell
    }
}

// MARK: - Private Funcs
private extension SettingsNetworkViewController {
    /// Configure network name cell.
    ///
    /// - Parameters:
    ///     - indexPath: cell indexPath
    /// - Returns: A table view cell.
    func configureNetworkNameCell(atIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = settingsTableView.dequeueReusableCell(for: indexPath) as SettingsNetworkNameCell
        cell.delegate = self
        cell.configureCell(viewModel: networkViewModel, showInfo: { [weak self] in
            self?.showPasswordEdition()
        })
        return cell
    }

    /// Configure channel cell.
    ///
    /// - Parameters:
    ///     - indexPath: cell indexPath
    /// - Returns: A table view cell.
    func configureChannelCell(atIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = settingsTableView.dequeueReusableCell(for: indexPath) as SettingsChooseChannelCell
        cell.configureCell(viewModel: networkViewModel)

        return cell
    }

    /// Configure cellular data cell.
    ///
    /// - Parameters:
    ///     - indexPath: cell indexPath
    /// - Returns: A table view cell.
    func configureCellularDataCell(atIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = settingsTableView.dequeueReusableCell(for: indexPath) as SettingsCellularDataCell
        cell.delegate = self

        return cell
    }

    /// Configure DRI Cell.
    ///
    /// - Parameters:
    ///     - indexPath: cell indexPath
    /// - Returns:
    ///     - UITableViewCell
    func configureDriCell(at indexPath: IndexPath) -> UITableViewCell {
        let cell = settingsTableView.dequeueReusableCell(for: indexPath) as SettingsDriCell
        cell.delegate = self
        let settingEntry = filteredSettings[indexPath.row]
        if let settingSegments: SettingsSegmentModel = settingEntry.segmentModel {
            cell.configureCell(cellTitle: settingEntry.title,
                               segmentModel: settingSegments,
                               subtitle: settingEntry.subtitle,
                               operatorTuple: networkViewModel.driOperatorFullId,
                               operatorColor: networkViewModel.driOperatorColor,
                               isEnabled: settingEntry.isEnabled,
                               subtitleColor: ColorName.secondaryTextColor.color,
                               showInfo: settingEntry.showInfo,
                               infoText: settingEntry.infoText,
                               atIndexPath: indexPath,
                               bgColor: settingEntry.bgColor)
        }
        cell.showEdition = { [weak self] in
            self?.showDriEdition()
        }
        return cell
    }

    /// Show password edition view controller.
    func showPasswordEdition() {
        coordinator?.startSettingDronePasswordEdition(viewModel: networkViewModel)
    }

    /// Show DRI edition view controller.
    func showDriEdition() {
        coordinator?.startDriEdition(viewModel: networkViewModel)
    }

    /// Update data source.
    ///
    /// - Parameters:
    ///     - state: Network state
    func updateDataSource(_ isNotFlying: Bool) {
        resetCellLabel = isNotFlying ? L10n.settingsConnectionReset : nil
        settings = networkViewModel.settingEntries
    }
}

// MARK: - Keyboard Helpers
private extension SettingsNetworkViewController {
    /// Manages datasource update when keyboard will be displayed.
    @objc func keyboardWillShow(sender: NSNotification) {
        networkViewModel.isEditing(true)
    }

    /// Manages datasource update when keyboard will be hidden.
    @objc func keyboardWillHide(sender: NSNotification) {
        networkViewModel.isEditing(false)
    }

    /// Force the keyboard to dismiss.
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - SettingsCellularDataDelegate
extension SettingsNetworkViewController: SettingsCellularDataDelegate {
    func cellularDataDidChange() {
        updateDataSource(networkViewModel.isNotFlying)
        settingsTableView?.reloadData()
    }

    func didStartSelectionEditing() {
        guard let strongCellularDataIndex = cellularDataIndex else { return }

        let indexPath = IndexPath(row: strongCellularDataIndex, section: 0)
        let cell = settingsTableView.dequeueReusableCell(for: indexPath) as SettingsCellularDataCell
        let height = cell.bounds.height
        settingsTableView.contentOffset = CGPoint(x: 0.0, y: height)
    }
}

// MARK: - SettingsNetworkNameDelegate
extension SettingsNetworkViewController: SettingsNetworkNameDelegate {
    func didStartNameEditing() {
        settingsTableView.scrollTo(at: wifiNameIndex)
    }
}
