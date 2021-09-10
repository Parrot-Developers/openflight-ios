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

/// Delegate protocol for `SettingsCellularDataCell`.
protocol SettingsCellularDataDelegate: AnyObject {
    /// Tells when a cellular segment did changes.
    func cellularDataDidChange()

    /// Tells when user edit apn configuration value.
    func didStartSelectionEditing()
}

/// Settings cell for cellular data.
/// User can configure cellular acces, network preference and network selection.
final class SettingsCellularDataCell: UITableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var cellularAccessAndNetworkModeStackView: UIStackView!
    @IBOutlet private weak var networkSelectionStackView: UIStackView!
    @IBOutlet private weak var accessNameTextField: UITextField!
    @IBOutlet private weak var usernameTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    @IBOutlet private weak var segmentedControl: UISegmentedControl!
    @IBOutlet private weak var bgView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var manualSelectionView: UIView!
    @IBOutlet private weak var networkSelectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var manualSelectionViewHeightConstraint: NSLayoutConstraint!

    // MARK: - Internal Properties
    weak var delegate: SettingsCellularDataDelegate?

    // MARK: - Private Properties
    private let viewModel = SettingsCellularDataViewModel()
    private var cellularAccessSegment: SettingsSegmentedCell = SettingsSegmentedCell.loadFromNib()
    private var connectionNetworkModeSegment: SettingsSegmentedCell = SettingsSegmentedCell.loadFromNib()

    // MARK: - Private Enums
    private enum Constants {
        static let segmentWidth: CGFloat = 78.0
        static let smallTextLength: Int = 10
        static let networkSelectionViewHeightConstraint: CGFloat = 62.0
        static let manualSelectionViewHeightConstraint: CGFloat = 88.0
    }

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        initView()
        initSegmentedControl()
        initViewModel()
    }
}

// MARK: - Actions
private extension SettingsCellularDataCell {
    @IBAction func segmentDidChange(_ sender: UISegmentedControl) {
        viewModel.switchSelectionMode()
    }
}

// MARK: - Private Funcs
private extension SettingsCellularDataCell {
    /// Inits the view.
    func initView() {
        configureCellularAccessCell()
        configureConnectionNetworkModeCell()
        configureConnectionNetworkSelectionCell()

        bgView.cornerRadiusedWith(backgroundColor: .white, radius: Style.largeCornerRadius)
        [accessNameTextField, usernameTextField, passwordTextField].forEach { textField in
            textField?.delegate = self
        }
        accessNameTextField.attributedPlaceholder = NSAttributedString(string: L10n.settingsConnectionApn,
                                                                       attributes: [NSAttributedString.Key.foregroundColor: ColorName.defaultTextColor80.color])
        usernameTextField.attributedPlaceholder = NSAttributedString(string: L10n.settingsConnectionUserName,
                                                                     attributes: [NSAttributedString.Key.foregroundColor: ColorName.defaultTextColor80.color])
        passwordTextField.attributedPlaceholder = NSAttributedString(string: L10n.commonPassword,
                                                                     attributes: [NSAttributedString.Key.foregroundColor: ColorName.defaultTextColor80.color])
    }

    /// Inits segmented control.
    func initSegmentedControl() {
        segmentedControl.applyCornerRadius(Style.largeCornerRadius)
        segmentedControl.customMakeup()
    }

    /// Inits the view model.
    func initViewModel() {
        viewModel.state.valueChanged = { [weak self] _ in
            self?.delegate?.cellularDataDidChange()
            self?.updateView()
        }
        updateView()
    }

    /// Updates the view when cellular data is off and when a sim card is inserted.
    func updateView() {
        // Adds/removes cell segments if cellular data access is activated/desactivated
        cellularAccessAndNetworkModeStackView.removeSubViews()
        cellularAccessAndNetworkModeStackView.addArrangedSubview(cellularAccessSegment.contentView)
        cellularAccessAndNetworkModeStackView.addArrangedSubview(connectionNetworkModeSegment.contentView)
        cellularAccessAndNetworkModeStackView.addSeparators(backColor: ColorName.defaultBgcolor.color)

        networkSelectionStackView.isHidden = false
        networkSelectionViewHeightConstraint.constant = Constants.networkSelectionViewHeightConstraint
        manualSelectionViewHeightConstraint.constant = Constants.manualSelectionViewHeightConstraint
        configureConnectionNetworkSelectionCell()

        self.segmentedControl.isEnabled = viewModel.state.value.isSelectionUpdating == false
    }

    /// Configures the cellular segment.
    func configureCellularAccessCell() {
        let settingCellularAccessEntry = viewModel.cellularAccessEntry

        if let settingCellularAccessSegment: SettingsSegmentModel = settingCellularAccessEntry.segmentModel {
            cellularAccessSegment.configureCell(cellTitle: settingCellularAccessEntry.title,
                                                segmentModel: settingCellularAccessSegment,
                                                subtitle: settingCellularAccessEntry.subtitle,
                                                subtitleColor: settingCellularAccessEntry.subtitleColor,
                                                atIndexPath: IndexPath(item: 0, section: 0),
                                                shouldShowBackground: false)
            cellularAccessSegment.delegate = self
        }
    }

    /// Configures the network mode segment.
    func configureConnectionNetworkModeCell() {
        let settingConnectionNetworkModeEntry = viewModel.connectionNetworkModeEntry

        if let settingConnectionNetworkModeSegment: SettingsSegmentModel = settingConnectionNetworkModeEntry.segmentModel {
            connectionNetworkModeSegment.configureCell(cellTitle: settingConnectionNetworkModeEntry.title,
                                                       segmentModel: settingConnectionNetworkModeSegment,
                                                       subtitle: settingConnectionNetworkModeEntry.subtitle,
                                                       subtitleColor: settingConnectionNetworkModeEntry.subtitleColor,
                                                       atIndexPath: IndexPath(item: 1, section: 0),
                                                       shouldShowBackground: false)
            connectionNetworkModeSegment.delegate = self
        }
    }

    /// Configures the network selection segment.
    func configureConnectionNetworkSelectionCell() {
        accessNameTextField.text = viewModel.state.value.networkUrl
        usernameTextField.text = viewModel.state.value.username
        passwordTextField.text = viewModel.state.value.password
        segmentedControl.removeAllSegments()
        titleLabel.text = viewModel.connectionNetworkSelectionEntry.title
        self.manualSelectionView.isHidden = viewModel.state.value.selectionMode == .auto

        guard let segmentModel = viewModel.connectionNetworkSelectionEntry.segmentModel else { return }

        for segmentItem: SettingsSegment in segmentModel.segments {
            segmentedControl.insertSegment(withTitle: segmentItem.title,
                                           at: self.segmentedControl.numberOfSegments,
                                           animated: false)
            segmentedControl.setEnabled(!segmentItem.disabled,
                                        forSegmentAt: self.segmentedControl.numberOfSegments - 1)
            // Set fixed size for small item to align items, automatic dimension will be set otherwise.
            if segmentItem.title.count < Constants.smallTextLength {
                segmentedControl.setWidth(Constants.segmentWidth, forSegmentAt: self.segmentedControl.numberOfSegments - 1)
            }

            segmentedControl.selectedSegmentIndex = segmentModel.selectedIndex
        }
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
            viewModel.updateManualValue(value: accessNameTextField.text,
                                        manualSelectionField: .apnUrl)
            usernameTextField.becomeFirstResponder()
        case usernameTextField:
            viewModel.updateManualValue(value: usernameTextField.text,
                                        manualSelectionField: .username)
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            viewModel.updateManualValue(value: passwordTextField.text,
                                        manualSelectionField: .password)
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
            viewModel.cellularAccessEntry.save(at: selectedSegmentIndex)
        case 1:
            viewModel.connectionNetworkModeEntry.save(at: selectedSegmentIndex)
        default:
            break
        }
    }
}
