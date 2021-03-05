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

/// Delegate protocol for `SettingsNetworkSelectionCell`.
protocol SettingsNetworkSelectionDelegate: class {
    /// Tells when network selection segment did changes.
    func networkSelectionDidChange()
    /// Tells when user edit apn configuration value.
    func didStartSelectionEditing()
}

/// Settings cell for manual cellular mode.
/// Used for cellular mode selection.
/// User can change mode, end point, username and password for the selected cellular network.
final class SettingsNetworkSelectionCell: UITableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var accessNameTextField: UITextField!
    @IBOutlet private weak var usernameTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    @IBOutlet private weak var segmentedControl: UISegmentedControl!
    @IBOutlet private weak var bgView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var manualSelectionView: UIView!

    // MARK: - Internal Properties
    weak var delegate: SettingsNetworkSelectionDelegate?

    // MARK: - Private Properties
    private var viewModel: SettingsNetworkSelectionViewModel?

    // MARK: - Private Enums
    private enum Constants {
        static let segmentWidth: CGFloat = 78.0
        static let smallTextLength: Int = 10
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
private extension SettingsNetworkSelectionCell {
    @IBAction func segmentDidChange(_ sender: UISegmentedControl) {
        viewModel?.switchSelectionMode()
    }
}

// MARK: - Private Funcs
private extension SettingsNetworkSelectionCell {
    /// Inits the view.
    func initView() {
        self.contentView.backgroundColor = .clear
        titleLabel.makeUp()
        bgView.applyCornerRadius(Style.largeCornerRadius)
        bgView.backgroundColor = ColorName.white20.color
        [accessNameTextField, usernameTextField, passwordTextField].forEach { textField in
            textField?.makeUp(bgColor: .black40)
            textField?.delegate = self
        }
        accessNameTextField.attributedPlaceholder = NSAttributedString(string: L10n.settingsConnectionApn,
                                                                       attributes: [NSAttributedString.Key.foregroundColor: ColorName.white20.color])
        usernameTextField.attributedPlaceholder = NSAttributedString(string: L10n.settingsConnectionUserName,
                                                                     attributes: [NSAttributedString.Key.foregroundColor: ColorName.white20.color])
        passwordTextField.attributedPlaceholder = NSAttributedString(string: L10n.commonPassword,
                                                                     attributes: [NSAttributedString.Key.foregroundColor: ColorName.white20.color])

    }

    /// Inits segmented control.
    func initSegmentedControl() {
        segmentedControl.backgroundColor = .clear
        segmentedControl.layer.backgroundColor = UIColor.clear.cgColor
        segmentedControl.customMakeup(normalBackgroundColor: ColorName.clear,
                                      selectedBackgroundColor: ColorName.greenSpring20,
                                      selectedFontColor: ColorName.greenSpring)
        segmentedControl.roundCornered()
    }

    /// Inits the view model.
    func initViewModel() {
        viewModel = SettingsNetworkSelectionViewModel(stateDidUpdate: { [weak self] _ in
            self?.delegate?.networkSelectionDidChange()
            self?.updateView()
        })
        updateView()
    }

    /// Updates the view.
    func updateView() {
        accessNameTextField.text = viewModel?.state.value.networkUrl
        usernameTextField.text = viewModel?.state.value.username
        passwordTextField.text = viewModel?.state.value.password
        segmentedControl.removeAllSegments()
        titleLabel.text = viewModel?.settingEntry.title
        self.manualSelectionView.isHidden = viewModel?.state.value.selectionMode == .auto
        segmentedControl.isEnabled = viewModel?.state.value.isSelectionUpdating == false

        guard let segmentModel = viewModel?.settingEntry.segmentModel else { return }

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
extension SettingsNetworkSelectionCell: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.didStartSelectionEditing()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case accessNameTextField:
            viewModel?.updateManualValue(value: accessNameTextField.text,
                                         manualSelectionField: .apnUrl)
        case usernameTextField:
            viewModel?.updateManualValue(value: usernameTextField.text,
                                         manualSelectionField: .username)
        case passwordTextField:
            viewModel?.updateManualValue(value: passwordTextField.text,
                                         manualSelectionField: .password)
        default:
            break
        }

        textField.resignFirstResponder()

        return true
    }
}
