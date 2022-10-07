//    Copyright (C) 2022 Parrot Drones SAS
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

/// Settings content sub class dedicated to developer settings.
final class SettingsDeveloperViewController: SettingsContentViewController {
    // MARK: - Private Properties
    private let developerViewModel = SettingsDeveloperViewModel(currentDroneHolder: Services.hub.currentDroneHolder)
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
        LogEvent.log(.simpleButton(LogEvent.LogKeyAdvancedSettings.resetDevelopperSettings))

        developerViewModel.resetSettings()
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
extension SettingsDeveloperViewController {
    /// Initializes view.
    func initView() {
        view.directionalLayoutMargins = Layout.mainContainerInnerMargins(isRegularSizeClass,
                                                                         screenBorders: [.top, .bottom])
        // Add tap observer to dismiss keyboard.
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
        developerViewModel.$isNotFlying
            .removeDuplicates()
            .combineLatest(developerViewModel.networkControlPublisher,
                           developerViewModel.debugShellPublisher)
            .combineLatest(developerViewModel.logControlPublisher,
                           developerViewModel.$isEditing)
            .sink { [weak self] (arg0, _, isEditing) in
                let (isNotFlying, _, _) = arg0
                guard let self = self else { return }

                if !isEditing {
                    self.updateDataSource(isNotFlying)
                }
            }
            .store(in: &cancellables)

        developerViewModel.$publicKeyEditionAsk
            .removeDuplicates()
            .sink { [weak self] in
                guard let self = self, $0 else { return }
                self.coordinator?.startPublicKeyEdition(viewModel: self.developerViewModel)
            }
            .store(in: &cancellables)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let cellType = cells[indexPath.row]

        switch cellType {
        case .shellAccess:
            cell = configureShellAccessCell(at: indexPath)
        default:
            cell = super.tableView(tableView, cellForRowAt: indexPath)
        }

        cell.selectionStyle = .none
        cell.backgroundColor = .clear

        return cell
    }
}

// MARK: - Private Funcs
private extension SettingsDeveloperViewController {

    /// Configure shell access Cell.
    ///
    /// - Parameters:
    ///     - indexPath: cell indexPath
    /// - Returns:
    ///     - UITableViewCell
    func configureShellAccessCell(at indexPath: IndexPath) -> UITableViewCell {
        let cell = settingsTableView.dequeueReusableCell(for: indexPath) as SettingsShellAccessCell
        cell.delegate = self
        let settingEntry = filteredSettings[indexPath.row]
        if let settingSegments: SettingsSegmentModel = settingEntry.segmentModel {
            cell.configureCell(cellTitle: settingEntry.title,
                               segmentModel: settingSegments,
                               subtitle: settingEntry.subtitle,
                               showPublicKey: !developerViewModel.isPublicKeyIsHidden,
                               publicKey: developerViewModel.publicFullKey,
                               isEnabled: settingEntry.isEnabled,
                               subtitleColor: ColorName.secondaryTextColor.color,
                               showInfo: settingEntry.showInfo,
                               infoText: settingEntry.infoText,
                               atIndexPath: indexPath,
                               bgColor: settingEntry.bgColor)
        }
        cell.showEdition = { [weak self] in
            self?.showPublicKeyEdition()
        }
        return cell
    }

    /// Update data source.
    ///
    /// - Parameters:
    ///     - isNotFlying: tells if the drone is not flying
    func updateDataSource(_ isNotFlying: Bool) {
        resetCellLabel = isNotFlying ? L10n.settingsDeveloperReset : nil
        settings = developerViewModel.settingEntries
    }

    /// Show public key edition view controller.
    func showPublicKeyEdition() {
        coordinator?.startPublicKeyEdition(viewModel: developerViewModel)
    }
}

// MARK: - Keyboard Helpers
private extension SettingsDeveloperViewController {
    /// Manages datasource update when keyboard will be displayed.
    @objc func keyboardWillShow(sender: NSNotification) {
        developerViewModel.isEditing(true)
    }

    /// Manages datasource update when keyboard will be hidden.
    @objc func keyboardWillHide(sender: NSNotification) {
        developerViewModel.isEditing(false)
    }

    /// Force the keyboard to dismiss.
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
