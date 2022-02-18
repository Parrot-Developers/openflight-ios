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

/// Cell with minus and plus buttons for settings update.
final class AdjustmentTableViewCell: MainTableViewCell, NibReusable, EditionSettingsCellModel {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var valueLabel: UILabel!
    @IBOutlet private weak var minusButton: UIButton!
    @IBOutlet private weak var plusButton: UIButton!
    @IBOutlet private weak var disableView: UIView!

    // MARK: - Internal Properties
    weak var delegate: EditionSettingsCellModelDelegate?

    // MARK: - Private Properties
    private var settingType: FlightPlanSettingType?

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        initView()
        resetView()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        resetView()
    }

    // MARK: - Internal Funcs
    func fill(with settingType: FlightPlanSettingType?) {
        titleLabel.text = settingType?.title
        self.settingType = settingType
        updateView()
    }

    func disableCell(_ mustDisable: Bool) {
        self.disableView.isHidden = !mustDisable
    }
}

// MARK: - Actions Funcs
private extension AdjustmentTableViewCell {
    @IBAction func minusButtonTouchedUpInside(_ sender: Any) {
        guard let currentValue = settingType?.currentValue else { return }

        updateSettingValue(with: currentValue - 1)
    }

    @IBAction func plusButtonTouchedUpInside(_ sender: Any) {
        guard let currentValue = settingType?.currentValue else { return }

        updateSettingValue(with: currentValue + 1)
    }
}

// MARK: - Private Funcs
private extension AdjustmentTableViewCell {
    /// Inits the view.
    func initView() {
        titleLabel.makeUp(and: .defaultTextColor)
        valueLabel.makeUp(and: ColorName.highlightColor)
        minusButton.roundCorneredWith(backgroundColor: ColorName.white20.color)
        plusButton.roundCorneredWith(backgroundColor: ColorName.white20.color)
    }

    /// Updates the view.
    func updateView() {
        guard let value = settingType?.currentValue,
              let description = settingType?.currentValueDescription,
              let currentValues = settingType?.allValues else { return }

        valueLabel?.text = description
        minusButton.isEnabled = currentValues.contains(value - 1)
        plusButton.isEnabled = currentValues.contains(value + 1)
    }

    /// Resets view.
    func resetView() {
        titleLabel.text = nil
        valueLabel.text = nil
        settingType = nil
    }

    /// Updates current setting value.
    ///
    /// - Parameters:
    ///     - value: new value
    func updateSettingValue(with value: Int) {
        guard let currentValues = settingType?.allValues,
              currentValues.contains(value) else {
            return
        }

        delegate?.updateSettingValue(for: settingType?.key, value: value)
        updateView()
    }
}
