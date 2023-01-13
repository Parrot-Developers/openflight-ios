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

/// Delegate protocol for `SettingsCellularDataCell`.
protocol SettingsCellularDataDelegate: AnyObject {
    /// Tells when a cellular segment did changes.
    func cellularDataDidChange()

    /// Tells when user edit apn configuration value.
    func didStartSelectionEditing()
}

/// Settings cell for cellular data.
/// User can configure cellular acces, network preference and network selection.
final class SettingsCellularDataCell: MainTableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var cellularAccessAndNetworkModeStackView: UIStackView!
    @IBOutlet private weak var networkSelectionStackView: UIStackView!
    @IBOutlet private weak var accessNameTextField: UITextField!
    @IBOutlet private weak var usernameTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    @IBOutlet private weak var bgView: UIView!
    @IBOutlet private weak var fieldTextHeightConstraint: NSLayoutConstraint!

    // MARK: - Private Enums
    private enum Constants {
        static let fieldTextHeight: (compact: CGFloat, regular: CGFloat) = (35, 45)
    }

    // MARK: - Internal Properties
    weak var delegate: SettingsCellularDataDelegate?

    // MARK: - Private Properties
    private let viewModel = SettingsCellularDataViewModel(currentDroneHolder: Services.hub.currentDroneHolder)
    private var cancellables = Set<AnyCancellable>()
    private var cellularAccessSegment: SettingsSegmentedCell = SettingsSegmentedCell.loadFromNib()
    private var connectionNetworkModeSegment: SettingsSegmentedCell = SettingsSegmentedCell.loadFromNib()
    private var connectionNetworkSelectionSegment: SettingsSegmentedCell = SettingsSegmentedCell.loadFromNib()

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        initView()
        initViewModel()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Private Funcs
private extension SettingsCellularDataCell {
    /// Inits the view.
    func initView() {
        cellularAccessSegment.delegate = self
        connectionNetworkModeSegment.delegate = self
        connectionNetworkSelectionSegment.delegate = self
        fieldTextHeightConstraint.constant = isRegularSizeClass ? Constants.fieldTextHeight.regular : Constants.fieldTextHeight.compact
        bgView.cornerRadiusedWith(backgroundColor: .white, radius: Style.largeCornerRadius)
        accessNameTextField.delegate = self
        accessNameTextField.attributedPlaceholder = NSAttributedString(string: L10n.settingsConnectionApn,
                                                                       attributes: [NSAttributedString.Key.foregroundColor: ColorName.defaultTextColor80.color])
        usernameTextField.delegate = self
        usernameTextField.attributedPlaceholder = NSAttributedString(string: L10n.settingsConnectionUserName,
                                                                     attributes: [NSAttributedString.Key.foregroundColor: ColorName.defaultTextColor80.color])
        passwordTextField.delegate = self
        passwordTextField.attributedPlaceholder = NSAttributedString(string: L10n.commonPassword,
                                                                     attributes: [NSAttributedString.Key.foregroundColor: ColorName.defaultTextColor80.color])
        networkSelectionStackView.layoutMargins = Layout.tableViewCellContainerInset(isRegularSizeClass)
        networkSelectionStackView.isLayoutMarginsRelativeArrangement = true

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(sender:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    /// Inits the view model.
    func initViewModel() {
        viewModel.cellularAccessEntryPublisher
            .combineLatest(viewModel.connectionNetworkModeEntryPublisher,
                           viewModel.connectionNetworkSelectionEntryPublisher)
            .sink { [weak self] (cellularAccessEntry, connectionNetworkModeEntry, connectionNetworkSelectionEntry) in
                guard let self = self else { return }
                self.delegate?.cellularDataDidChange()
                self.updateView(cellularAccessEntry: cellularAccessEntry,
                                connectionNetworkModeEntry: connectionNetworkModeEntry,
                                connectionNetworkSelectionEntry: connectionNetworkSelectionEntry)
            }
            .store(in: &cancellables)

        viewModel.$cellularNetworkUrl
            .removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.accessNameTextField.text = $0
            }
            .store(in: &cancellables)

        viewModel.$cellularNetworkUsername
            .removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.usernameTextField.text = $0
            }
            .store(in: &cancellables)

        viewModel.$cellularNetworkPassword
            .removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.passwordTextField.text = $0
            }
            .store(in: &cancellables)

        viewModel.$cellularSelectionMode
            .removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.networkSelectionStackView.isHidden = $0 != .manual
            }
            .store(in: &cancellables)
    }

    /// Updates the view when cellular data is off and when a sim card is inserted.
    func updateView(cellularAccessEntry: SettingEntry?, connectionNetworkModeEntry: SettingEntry?, connectionNetworkSelectionEntry: SettingEntry?) {
        // Adds/removes cell segments if cellular data access is activated/desactivated
        cellularAccessAndNetworkModeStackView.removeSubViews()
        configureCellularAccessCell(cellularAccessEntry: cellularAccessEntry)
        configureConnectionNetworkModeCell(connectionNetworkModeEntry: connectionNetworkModeEntry)
        configureConnectionNetworkSelectionCell(connectionNetworkSelectionEntry: connectionNetworkSelectionEntry)
        cellularAccessAndNetworkModeStackView.addArrangedSubview(cellularAccessSegment.contentView)
        cellularAccessAndNetworkModeStackView.addArrangedSubview(connectionNetworkModeSegment.contentView)
        cellularAccessAndNetworkModeStackView.addArrangedSubview(connectionNetworkSelectionSegment.contentView)
        cellularAccessAndNetworkModeStackView.addSeparators(backColor: ColorName.defaultBgcolor.color)
    }

    /// Configures the cellular segment.
    func configureCellularAccessCell(cellularAccessEntry: SettingEntry?) {
        guard let settingCellularAccessEntry = cellularAccessEntry else { return }

        if let settingCellularAccessSegment: SettingsSegmentModel = settingCellularAccessEntry.segmentModel {
            cellularAccessSegment.configureCell(cellTitle: settingCellularAccessEntry.title,
                                                segmentModel: settingCellularAccessSegment,
                                                subtitle: settingCellularAccessEntry.subtitle,
                                                isEnabled: settingCellularAccessEntry.isEnabled,
                                                subtitleColor: settingCellularAccessEntry.subtitleColor,
                                                atIndexPath: IndexPath(item: 0, section: 0),
                                                shouldShowBackground: false)
            cellularAccessSegment.enabledMargins = []
        }
    }

    /// Configures the network mode segment.
    func configureConnectionNetworkModeCell(connectionNetworkModeEntry: SettingEntry?) {
        guard let settingConnectionNetworkModeEntry = connectionNetworkModeEntry else { return }
        if let settingConnectionNetworkModeSegment: SettingsSegmentModel = settingConnectionNetworkModeEntry.segmentModel {
            connectionNetworkModeSegment.configureCell(cellTitle: settingConnectionNetworkModeEntry.title,
                                                       segmentModel: settingConnectionNetworkModeSegment,
                                                       subtitle: settingConnectionNetworkModeEntry.subtitle,
                                                       isEnabled: settingConnectionNetworkModeEntry.isEnabled,
                                                       subtitleColor: settingConnectionNetworkModeEntry.subtitleColor,
                                                       atIndexPath: IndexPath(item: 1, section: 0),
                                                       shouldShowBackground: false)
            connectionNetworkModeSegment.enabledMargins = []
        }
    }

    /// Configures the network selection segment.
    func configureConnectionNetworkSelectionCell(connectionNetworkSelectionEntry: SettingEntry?) {
        guard let settingConnectionNetworkSelectionEntry = connectionNetworkSelectionEntry else { return }

        if let settingConnectionNetworkSelectionSegment: SettingsSegmentModel = settingConnectionNetworkSelectionEntry.segmentModel {
            connectionNetworkSelectionSegment.configureCell(cellTitle: settingConnectionNetworkSelectionEntry.title,
                                                            segmentModel: settingConnectionNetworkSelectionSegment,
                                                            subtitle: settingConnectionNetworkSelectionEntry.subtitle,
                                                            isEnabled: settingConnectionNetworkSelectionEntry.isEnabled,
                                                            subtitleColor: settingConnectionNetworkSelectionEntry.subtitleColor,
                                                            atIndexPath: IndexPath(item: 2, section: 0),
                                                            shouldShowBackground: false)
            connectionNetworkSelectionSegment.enabledMargins = []
        }

        // updates network selection view
        accessNameTextField.isEnabled = settingConnectionNetworkSelectionEntry.isEnabled
        accessNameTextField.alphaWithEnabledState(settingConnectionNetworkSelectionEntry.isEnabled)
        usernameTextField.isEnabled = settingConnectionNetworkSelectionEntry.isEnabled
        usernameTextField.alphaWithEnabledState(settingConnectionNetworkSelectionEntry.isEnabled)
        passwordTextField.isEnabled = settingConnectionNetworkSelectionEntry.isEnabled
        passwordTextField.alphaWithEnabledState(settingConnectionNetworkSelectionEntry.isEnabled)
    }

    /// Update values when the keyboard will hide.
    @objc func keyboardWillHide(sender: NSNotification) {
        viewModel.updateAllManualValues(url: accessNameTextField.text ?? "",
                                        username: usernameTextField.text ?? "",
                                        password: passwordTextField.text ?? "")
    }
}

// MARK: - UITextField Delegate
extension SettingsCellularDataCell: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.didStartSelectionEditing()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case accessNameTextField:
            usernameTextField.becomeFirstResponder()
        case usernameTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            textField.resignFirstResponder()
        default:
            break
        }

        return true
    }
}

// MARK: - SettingsCellularCellDelegate
extension SettingsCellularDataCell: SettingsSegmentedCellDelegate {
    func settingsSegmentedCellDidChange(selectedSegmentIndex: Int, atIndexPath indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            viewModel.cellularAccessEntryPublisher.value?.save(at: selectedSegmentIndex)
        case 1:
            viewModel.connectionNetworkModeEntryPublisher.value?.save(at: selectedSegmentIndex)
        case 2:
            viewModel.connectionNetworkSelectionEntryPublisher.value?.save(at: selectedSegmentIndex)
        default:
            break
        }
    }
}
