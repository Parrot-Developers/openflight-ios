//    Copyright (C) 2021 Parrot Drones SAS
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

enum SettingsMenuPosition {
    case top
    case center
    case bottom
}

/// Settings menu table view cell.
final class SettingsMenuTableViewCell: SettingsTableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var settingsBackground: UIView!
    @IBOutlet private weak var settingsKey: UILabel!
    @IBOutlet private weak var settingsValue: UILabel!

    private var spacing: CGFloat {
        Layout.tableViewCellContainerInset(isRegularSizeClass).bottom
    }

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        settingsKey.makeUp(with: .current, color: .defaultTextColor)
        settingsValue.makeUp(with: .medium, color: .secondaryTextColor)
    }
}

// MARK: - Internal Funcs
internal extension SettingsMenuTableViewCell {
    /// Setup cell.
    ///
    /// - Parameters:
    ///     - setting: flight plan setting
    ///     - index: indexPath row of the cell
    ///     - numberOfRows:  number of rows in the section where the cell is
    ///     - isEditable: whether the setting is editable
    ///     - inEditionMode: whether the setting is displayed in edition mode
    ///     - customRth: wether the custom rth setting is enabled
    func setup(setting: FlightPlanSetting, index: Int, numberOfRows: Int, isEditable: Bool, inEditionMode: Bool, customRth: Bool) {
        if setting.category == .rth && !customRth {
            let rthSettings = Services.hub.rthSettingsMonitor.getUserRthSettings()
            if setting.key == ClassicFlightPlanSettingType.rthHeight.key {
                setting.currentValue = Int(round(rthSettings.rthHeight))
            } else if setting.key == ClassicFlightPlanSettingType.rthHoveringHeight.key {
                setting.currentValue = Int(ceil(rthSettings.rthHoveringHeight))
            } else if setting.key == ClassicFlightPlanSettingType.rthReturnTarget.key {
                setting.currentValue = RthSettings.returnTargetValues.firstIndex(of: rthSettings.rthReturnTarget) ?? 0
            } else if setting.key == ClassicFlightPlanSettingType.rthEndBehaviour.key {
                setting.currentValue = RthSettings.returnEndBehaviors.firstIndex(of: rthSettings.rthEndBehaviour) ?? 0
            }
        }

        if setting.category == .altitudeRef {
            // In case of altitude reference display, in edition mode,
            // the setting key, already available in section title, is set
            // with its short version to avoid duplication.
            settingsKey.text = inEditionMode ? setting.shortTitle : setting.title
        } else {
            settingsKey.text = setting.shortTitle ?? setting.title
        }

        if let descriptions = setting.valueDescriptions,
           let current = setting.currentValue,
           descriptions.count > current {
            // Use valueDescriptions if setting is custom.
            settingsValue.text = descriptions[current]
        } else if let currentValueDescription = setting.currentValueDescription {
            settingsValue.text = currentValueDescription
        } else {
            settingsValue.text = Style.dash
        }

        if settingsValue.text == L10n.commonYes {
            settingsValue.textColor = ColorName.highlightColor.color
        } else {
            settingsValue.textColor = ColorName.secondaryTextColor.color
        }

        // Configure background view according to `isEditable` state:
        // - white shadowed inset background if editable,
        // - clear background otherwise.
        addShadow(shadowRadius: 1, condition: isEditable)
        layer.zPosition = CGFloat(index)
        settingsBackground.backgroundColor = isEditable ? UIColor.white : .clear

        guard inEditionMode else {
            settingsBackground.layoutMargins = UIEdgeInsets(top: 0, left: 0,
                                                            bottom: spacing, right: 0)
            return
        }

        guard isEditable else {
            let bottomSpacing = index < numberOfRows - 1
                ? spacing * 0.5
                : 0
            settingsBackground.layoutMargins = UIEdgeInsets(top: spacing * 0.5, left: 0,
                                                            bottom: bottomSpacing, right: 0)
            return
        }

        switch index {
        case 0:
            settingsBackground.customCornered(corners: [.topLeft, .topRight], radius: Style.mediumCornerRadius)
            settingsBackground.layoutMargins = UIEdgeInsets(top: spacing, left: spacing,
                                                            bottom: spacing * 0.5, right: spacing)
        case 1 ..< numberOfRows - 1:
            settingsBackground.layer.cornerRadius = 0
            settingsBackground.layoutMargins = UIEdgeInsets(top: spacing * 0.5, left: spacing,
                                                            bottom: spacing * 0.5, right: spacing)
        default:
            settingsBackground.customCornered(corners: [.bottomLeft, .bottomRight], radius: Style.mediumCornerRadius)
            settingsBackground.layoutMargins = UIEdgeInsets(top: spacing * 0.5, left: spacing,
                                                            bottom: spacing, right: spacing)
        }
    }
}
