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
final class SettingsDriCell: SettingsSegmentedCell {
    // MARK: - Outlets
    @IBOutlet private weak var editStackView: UIStackView!
    @IBOutlet private weak var operatorTitleLabel: UILabel!
    @IBOutlet private weak var operatorNumberView: UIView!
    @IBOutlet private weak var operatorNumberLabel: UILabel!
    @IBOutlet private weak var driTitleLabel: UILabel!
    @IBOutlet private weak var editButton: ActionButton!

    var showEdition: (() -> Void)?

    override func initView () {
        super.initView()
        operatorTitleLabel.makeUp(with: .current, color: .defaultTextColor)
        operatorTitleLabel.text = L10n.settingsConnectionDriOperatorId
        operatorNumberView.layer.cornerRadius = Style.largeCornerRadius
        operatorNumberLabel.text = ""
        driTitleLabel.makeUp(with: .current, color: .defaultTextColor)
        driTitleLabel.text = L10n.settingsConnectionDroneSerialId
        editButton.setup(title: L10n.commonEdit, style: .default2)
    }

    // MARK: - Internal Funcs
    /// Configures cell.
    ///
    /// - Parameters:
    ///    - cellTitle: title
    ///    - segmentModel: settings segment model
    ///    - subtitle: sub title
    ///    - operatorId: DRI operator id
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
                       operatorId: String,
                       operatorColor: UIColor,
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
        operatorNumberLabel.text = operatorId
        operatorNumberLabel.textColor = operatorColor
        editStackView.isHidden = subtitle == nil
        editButton.addTarget(self, action: #selector(editButtonTouchedUpInside), for: .touchUpInside)
        backgroundColor = bgColor
    }

    /// Shows the DRI edition.
    @objc func editButtonTouchedUpInside() {
        showEdition?()
    }
}
