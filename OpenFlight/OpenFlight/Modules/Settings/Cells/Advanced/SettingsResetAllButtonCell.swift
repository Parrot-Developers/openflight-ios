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

import Reusable

/// Settings Reset All Button Cell Delegate.
protocol SettingsResetAllButtonCellDelegate: AnyObject {
    /// Notifies when the reset button is touched.
    func settingsResetAllButtonCellButtonTouchUpInside()
}

/// Settings Reset All Button Cell.
final class SettingsResetAllButtonCell: UITableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var resetButton: UIButton! {
        didSet {
            resetButton.roundCornered()
            resetButton.backgroundColor = ColorName.white12.color
            resetButton.makeup(with: .regular, color: ColorName.white)
            resetButton.setTitleColor(ColorName.white.color, for: .normal)
            resetButton.setTitleColor(ColorName.white30.color, for: .disabled)
        }
    }
    @IBOutlet private weak var topConstraint: NSLayoutConstraint!

    // MARK: - Private Enums
    private enum Constants {
        static let topMargin: CGFloat = 40.0
    }

    // MARK: - Internal Properties
    weak var delegate: SettingsResetAllButtonCellDelegate?

    // MARK: - Internal Funcs
    /// Configure cell.
    ///
    /// - Parameters:
    ///    - title: cell title
    ///    - isEnabled: whether reset button is enabled
    ///    - hasNoMargin: tells if there are margins
    func configureCell(title: String, isEnabled: Bool, hasNoMargin: Bool = false) {
        topConstraint.constant = hasNoMargin ? 0.0 : Constants.topMargin
        resetButton.setTitle(title, for: .normal)
        resetButton.setTitle(title, for: .highlighted)
        resetButton.setTitle(title, for: .disabled)
        resetButton.setTitle(title, for: .selected)
        resetButton.isEnabled = isEnabled
    }
}

// MARK: - Actions
private extension SettingsResetAllButtonCell {
    @IBAction func resetButtonTouchedUpInside(_ sender: AnyObject) {
        delegate?.settingsResetAllButtonCellButtonTouchUpInside()
    }
}
