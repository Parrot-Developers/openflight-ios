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

/// Delegate protocol for `SettingsNetworkNameCell`.
protocol SettingsNetworkNameDelegate: AnyObject {
    /// Tells when user edits network name.
    func didStartNameEditing()
}

/// Settings network name cell. Used to choose a Wifi network.
final class SettingsNetworkNameCell: UITableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var bgView: UIView! {
        didSet {
            bgView.applyCornerRadius(Style.largeCornerRadius)
        }
    }
    @IBOutlet private weak var cellTitle: UILabel! {
        didSet {
            cellTitle.text = L10n.settingsConnectionNetworkName
        }
    }
    @IBOutlet private weak var textfield: UITextField!
    @IBOutlet private weak var passwordButton: UIButton! {
        didSet {
            passwordButton.makeup(with: .small, color: .defaultTextColor)
            passwordButton.makeup(with: .small, color: .defaultTextColor80, and: .disabled)
            passwordButton.setTitle(L10n.commonPassword.uppercased(), for: .normal)
            passwordButton.cornerRadiusedWith(backgroundColor: .white,
                                              borderColor: ColorName.defaultBgcolor.color,
                                              radius: Style.mediumCornerRadius,
                                              borderWidth: Style.mediumBorderWidth)
            passwordButton.addShadow(shadowColor: ColorName.whiteAlbescent.color)
        }
    }

    // MARK: - Internal Properties
    weak var delegate: SettingsNetworkNameDelegate?

    // MARK: - Private Properties
    private var showInfo: (() -> Void)?
    private var viewModel: SettingsNetworkViewModel?

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        self.textfield.delegate = self
    }

    // MARK: - Internal Funcs
    /// Configure cell.
    ///
    /// - Parameters:
    ///     - viewModel: Settings network view model
    ///     - showInfo: call back method
    func configureCell(viewModel: SettingsNetworkViewModel, showInfo: (() -> Void)? = nil) {
        self.showInfo = showInfo
        self.viewModel = viewModel
        self.textfield.text = viewModel.state.value.ssidName
        self.enableCell(viewModel.state.value.isEnabled)
    }
}

// MARK: - Actions
private extension SettingsNetworkNameCell {
    /// Password button touched.
    @IBAction func passwordTouchedUpInside(sender: AnyObject) {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyAdvancedSettings.networkPassword,
                             newValue: nil,
                             logType: .button)
        showInfo?()
    }
}

// MARK: - Private Funcs
private extension SettingsNetworkNameCell {
    /// Enable cell.
    ///
    /// - Parameters:
    ///     - isEnable: tells if we need to enable the cell
    func enableCell(_ isEnable: Bool) {
        isUserInteractionEnabled = isEnable
        textfield.isEnabled = isEnable
        passwordButton.isEnabled = isEnable
        textfield.alphaWithEnabledState(isEnable)
        passwordButton.alphaWithEnabledState(isEnable)
    }
}

// MARK: - UITextField Delegate
extension SettingsNetworkNameCell: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.didStartNameEditing()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let textFieldValue = textField.text {
            viewModel?.changeSsidName(textFieldValue)
        }

        textField.resignFirstResponder()

        return true
    }
}
