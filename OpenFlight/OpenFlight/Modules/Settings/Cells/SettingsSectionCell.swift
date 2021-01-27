// Copyright (C) 2020 Parrot Drones SAS
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

/// Settings cell which display its name and icon.
final class SettingsSectionCell: UITableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet fileprivate weak var iconImageView: UIImageView!
    @IBOutlet fileprivate weak var titleLabel: UILabel! {
        didSet {
            titleLabel.makeUp()
            titleLabel.adjustsFontSizeToFitWidth = true
        }
    }

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        // setup cell display.
        self.contentView.applyCornerRadius()
        self.selectionStyle = .none
    }

    // MARK: - Internal funcs
    /// configure cell with data.
    ///
    /// - Parameters:
    ///    - settingsSection: data to apply to the cell
    func configure(with settingsSection: SettingsSection) {
        titleLabel.text = settingsSection.title
        iconImageView.image = settingsSection.icon
    }

    /// Changes display regarding select state.
    ///
    /// - Parameters:
    ///    - isSelected: is selected
    func selectCell(_ isSelected: Bool) {
        if isSelected {
            contentView.backgroundColor = ColorName.white.color
            iconImageView.tintColor = ColorName.black.color
            titleLabel.textColor = ColorName.black.color
        } else {
            contentView.backgroundColor = ColorName.black.color
            iconImageView.tintColor = ColorName.white.color
            titleLabel.textColor = ColorName.white.color
        }
    }
}
