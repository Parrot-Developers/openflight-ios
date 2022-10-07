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

import Reusable

/// Settings Segmented Cell.
final class SettingsShellAccessCell: SettingsSegmentedCell {
    // MARK: - Outlets
    @IBOutlet private weak var editStackView: UIStackView!
    @IBOutlet private weak var publicKeyTitleLabel: UILabel!
    @IBOutlet private weak var publicKeyNumberView: UIView!
    @IBOutlet private weak var publicKeyNumberLabel: UILabel!
    @IBOutlet private weak var editButton: ActionButton!

    var showEdition: (() -> Void)?

    override func initView () {
        super.initView()
        publicKeyTitleLabel.makeUp(with: .current, color: .defaultTextColor)
        publicKeyTitleLabel.text = L10n.settingsDeveloperPublicKey
        publicKeyNumberView.layer.cornerRadius = Style.largeCornerRadius
        publicKeyNumberLabel.makeUp(with: .current, color: .disabledTextColor)
        publicKeyNumberLabel.text = ""
        editButton.setup(title: L10n.commonEdit, style: .default2)
    }

    // MARK: - Internal Funcs
    /// Configures cell.
    ///
    /// - Parameters:
    ///    - cellTitle: title
    ///    - segmentModel: settings segment model
    ///    - subtitle: sub title
    ///    - showPublicKey: Tells if we must show the autopilot public key
    ///    - publicKey: autopilot public key
    ///    - isEnabled: is enabled
    ///    - subtitleColor: subtitle color
    ///    - subtitleBackgroundColor: subtitle background color
    ///    - showInfo: action handler to show info
    ///    - infoText: info button title
    ///    - indexPath: cell index path
    ///    - shouldShowBackground: tells if we must show the background
    ///    - bgColor: cell background color
    func configureCell(cellTitle: String?,
                       segmentModel: SettingsSegmentModel,
                       subtitle: String?,
                       showPublicKey: Bool = false,
                       publicKey: String,
                       isEnabled: Bool = true,
                       subtitleColor: UIColor = ColorName.defaultTextColor.color,
                       subtitleBackgroundColor: UIColor = ColorName.defaultBgcolor.color,
                       showInfo: (() -> Void)? = nil,
                       infoText: String? = nil,
                       atIndexPath indexPath: IndexPath,
                       shouldShowBackground: Bool = true,
                       bgColor: UIColor?) {
        super.configureCell(cellTitle: cellTitle,
                            segmentModel: segmentModel,
                            subtitle: subtitle,
                            isEnabled: isEnabled,
                            subtitleColor: subtitleColor,
                            subtitleBackgroundColor: subtitleBackgroundColor,
                            showInfo: showInfo,
                            infoText: infoText,
                            atIndexPath: indexPath,
                            shouldShowBackground: shouldShowBackground)
        publicKeyNumberLabel.text = publicKey
        editStackView.isHidden = !showPublicKey
        editButton.addTarget(self, action: #selector(editButtonTouchedUpInside), for: .touchUpInside)
        backgroundColor = bgColor
    }

    /// Shows the public key edition.
    @objc func editButtonTouchedUpInside() {
        showEdition?()
    }
}
