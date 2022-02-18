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

// MARK: - Protocols
protocol ModesChoiceTableViewCellDelegate: AnyObject {
    /// Update current flight plan mode.
    ///
    /// - Parameters:
    ///     - tag: mode identifier
    func updateMode(tag: Int)
}

/// Cell which manage flight plan modes.

final class ModesChoiceTableViewCell: MainTableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var modesStackView: UIStackView!
    @IBOutlet private weak var modeLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var modesBackgroundView: UIView!

    // MARK: - Internal Properties
    weak var delegate: ModesChoiceTableViewCellDelegate?

    // MARK: - Override Funcs
    override func awakeFromNib() {
        resetView()
        initView()
        super.awakeFromNib()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        resetView()
    }
}

// MARK: - Actions Funcs
private extension ModesChoiceTableViewCell {
    /// Observes touched up inside action on flight plan type button.
    ///
    /// - Parameters:
    ///     - sender: selected flight plan type button
    @objc func editionModeButtonTouchedUpInside(sender: UIButton) {
        updateType(tag: sender.tag)
        delegate?.updateMode(tag: sender.tag)
    }
}

// MARK: - Private Funcs
private extension ModesChoiceTableViewCell {
    /// Inits the view.
    func initView() {
        backgroundColor = .clear
        modeLabel.makeUp(and: .highlightColor)
        titleLabel.makeUp(with: .small, and: .disabledTextColor)
        titleLabel.text = L10n.commonMode.uppercased()
        modesBackgroundView.layer.cornerRadius = Style.largeCornerRadius
    }

    /// Resets view.
    func resetView() {
        modesStackView.safelyRemoveArrangedSubviews()
    }

    /// Updates type's view background color.
    ///
    /// - Parameters:
    ///     - tag: type tag
    func updateType(tag: Int?) {
        guard let tag = tag else { return }
        modesStackView?.arrangedSubviews.forEach { view in
            let isSelected = modesStackView?.arrangedSubviews.firstIndex(of: view) == tag
            let backgroundColor = isSelected ? ColorName.highlightColor.color : .clear
            let borderColor = isSelected ? ColorName.highlightColor.color : .clear

            view.cornerRadiusedWith(backgroundColor: backgroundColor,
                                    borderColor: borderColor,
                                    radius: Style.largeCornerRadius,
                                    borderWidth: Style.mediumBorderWidth)
            view.addShadow()
            let colorText = isSelected ? ColorName.white.color : ColorName.defaultTextColor.color
            view.tintColor = colorText
        }
    }
}

// MARK: - Internal Funcs
extension ModesChoiceTableViewCell {
    /// Sets up the view with the corresponding type.
    ///
    /// - Parameters:
    ///     - settingsProvider: current settings provider
    func fill(with settingsProvider: FlightPlanSettingsProvider?) {
        settingsProvider?.allTypes.forEach { item in
            let button = UIButton(type: UIButton.ButtonType.custom)
            button.tag = item.tag
            button.setImage(item.icon.withRenderingMode(.alwaysTemplate), for: .normal)
            button.addTarget(self,
                             action: #selector(editionModeButtonTouchedUpInside),
                             for: .touchUpInside)
            modesStackView.addArrangedSubview(button)
        }
        modeLabel.text = settingsProvider?.currentType?.title
        updateType(tag: settingsProvider?.currentType?.tag)
    }
}
