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

/// Button Cell Setting Model.
struct ButtonCellSetting {
    let title: String
    let buttonTitle: String
    let isEnabled: Bool
}

/// Settings Button Cell Delegate.
protocol SettingsButtonCellDelegate: class {
    /// Used to notify when button is touched.
    func settingsButtonCellDidTouchButton()
}

/// Settings Button Cell.
final class SettingsButtonCell: UITableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var settingsButton: UIButton!

    // MARK: - Internal Properties
    weak var delegate: SettingsButtonCellDelegate?

    // MARK: - Internal Funcs
    /// Configure button view.
    ///
    /// - Parameters:
    ///     - buttonCellSetting: button cell setting
    func configure(buttonCellSetting: ButtonCellSetting) {
        titleLabel.text = buttonCellSetting.title
        settingsButton.setTitle(buttonCellSetting.buttonTitle.uppercased(), for: .normal)
        settingsButton.isEnabled = buttonCellSetting.isEnabled
    }
}

// MARK: - Actions
private extension SettingsButtonCell {
    @IBAction func settingsButtonTouchedUpInside(_ sender: Any) {
        delegate?.settingsButtonCellDidTouchButton()
    }
}
