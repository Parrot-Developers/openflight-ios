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

/// Cell which gives value choices for updating the setting.
final class SettingValuesChoiceTableViewCell: UITableViewCell, NibReusable, EditionSettingsCellModel {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var settingValuesStackView: UIStackView!
    @IBOutlet private weak var disableView: UIView!

    // MARK: - Internal Properties
    weak var delegate: EditionSettingsCellModelDelegate?

    // MARK: - Private Properties
    private var settingType: FlightPlanSettingType?

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()
        initView()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        resetView()
    }

    // MARK: - Internal Funcs
    func fill(with settingType: FlightPlanSettingType?) {
        self.settingType = settingType
        titleLabel.text = settingType?.valueToDisplay().uppercased()

        settingType?.allValues.forEach { value in
            let button = SettingsButton(type: UIButton.ButtonType.custom)
            button.tag = value
            if let customTitle = settingType?.valueDescriptions?.elementAt(index: value) {
                button.setTitle(customTitle, for: .normal)
            } else {
                button.setTitle(value == 0 ? L10n.commonYes : L10n.commonNo, for: .normal)
            }

            let buttonTitle = button.titleLabel?.text ?? ""
            if buttonTitle == L10n.commonNo {
                button.setTitleColor(ColorName.defaultTextColor.color, for: .selected)
            } else {
                button.setTitleColor(ColorName.white.color, for: .selected)
            }

            button.makeup(color: .defaultTextColor)
            button.contentEdgeInsets = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10)
            button.addTarget(self,
                             action: #selector(settingValueButtonTouchedUpInside),
                             for: .touchUpInside)
            settingValuesStackView.addArrangedSubview(button)
            if let image = self.settingType?.valueImages?.elementAt(index: value) {
                button.setImage(image, for: .normal)
            } else {
                button.setImage(nil, for: .normal)
            }
        }

        if let value = settingType?.currentValue {
            updateType(tag: value)
        }
    }

    func disableCell(_ mustDisable: Bool) {
        self.disableView.isHidden = !mustDisable
    }
}

// MARK: - Actions Funcs
private extension SettingValuesChoiceTableViewCell {
    /// Observes touched up inside on value.
    ///
    /// - Parameters:
    ///     - sender: selected value for the current setting
    @objc func settingValueButtonTouchedUpInside(sender: UIButton) {
        updateType(tag: sender.tag)
        guard let key = settingType?.key else { return }
        
        switch key {
        case ClassicFlightPlanSettingType.imageMode.key,
             ClassicFlightPlanSettingType.resolution.key,
             ClassicFlightPlanSettingType.photoResolution.key,
             ClassicFlightPlanSettingType.whiteBalance.key:
            delegate?.updateSettingValue(for: settingType?.key, value: sender.tag)
        default:
            delegate?.updateChoiceSetting(for: settingType?.key, value: sender.tag == 0)
        }
    }
}

// MARK: - Private Funcs
private extension SettingValuesChoiceTableViewCell {
    /// Inits the view.
    func initView() {
        titleLabel.makeUp(with: .small, and: .defaultTextColor)
        settingValuesStackView.layer.cornerRadius = Style.largeCornerRadius
    }

    /// Resets view.
    func resetView() {
        settingValuesStackView.safelyRemoveArrangedSubviews()
        titleLabel.text = nil
    }

    /// Updates button's view background color.
    ///
    /// - Parameters:
    ///     - tag: button tag
    func updateType(tag: Int?) {
        guard let tag = tag else { return }

        settingValuesStackView?.arrangedSubviews
            .compactMap { $0 as? UIButton}
            .forEach { button in
            let isSelected = settingValuesStackView?.arrangedSubviews.firstIndex(of: button) == tag
                var backgroundColor = UIColor.clear
                if isSelected {
                    let buttonTitle = button.titleLabel?.text ?? ""
                    if buttonTitle == L10n.commonNo {
                        backgroundColor = ColorName.white.color
                    } else {
                        backgroundColor = ColorName.highlightColor.color
                    }
                }
            button.cornerRadiusedWith(backgroundColor: backgroundColor,
                                      radius: Style.largeCornerRadius,
                                      borderWidth: Style.largeBorderWidth)
            button.isSelected = isSelected
            button.tintColor = button.isSelected ? .white : ColorName.defaultTextColor.color
        }
    }
}
