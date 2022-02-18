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

/// Cell which displays a centered ruler.
public class CenteredRulerTableViewCell: SidePanelSettingTableViewCell, NibReusable, EditionSettingsCellModel {
    // MARK: - Outlets
    @IBOutlet private(set) weak var titleLabel: UILabel!
    @IBOutlet private(set) weak var settingValueRulerViewContainer: UIView!
    @IBOutlet private weak var disableView: UIView!

    // MARK: - Internal Properties
    public weak var delegate: EditionSettingsCellModelDelegate?

    // MARK: - Private Properties
    private(set) var settingType: FlightPlanSettingType?
    private(set) var centeredRulerBarView: SettingValueRulerView!

    // MARK: - Override Funcs
    public override func awakeFromNib() {
        super.awakeFromNib()
        initView()
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        settingValueRulerViewContainer.removeSubViews()
        initView()
    }

    // MARK: - Internal Funcs
    public func fill(with settingType: FlightPlanSettingType?) {
        titleLabel.text = settingType?.title.uppercased()
        self.settingType = settingType
        setupRulerModel()
    }

    public func disableCell(_ mustDisable: Bool) {
        self.disableView.isHidden = !mustDisable
    }

    /// Inits the view.
    public func initView() {
        cellSettingType = .slider
        titleLabel.makeUp(with: .small, and: .defaultTextColor)
        let ruler = SettingValueRulerView(orientation: .horizontal)
        ruler.delegate = self
        centeredRulerBarView = ruler
        settingValueRulerViewContainer.addWithConstraints(subview: ruler)
    }

    /// Set ruler bar model displaying custom values.
    public func setupRulerModel() {
        let displayType: RulerDisplayType = .string
        var divider = 1.0
        if let dividerSetting = settingType?.divider, dividerSetting < 1.0 {
            divider = dividerSetting
        }
        let allValues = settingType?.allValues.map({Double($0) * divider}) ?? []
        let currentValue = Double(settingType?.currentValue ?? 0) * divider

        centeredRulerBarView.model =
            SettingValueRulerModel(value: Double(currentValue),
                                   range: allValues,
                                   rangeDescriptions: settingType?.valueDescriptions ?? [],
                                   rangeImages: settingType?.valueImages ?? [],
                                   unit: settingType?.unit ?? .distance,
                                   orientation: .horizontal,
                                   displayType: displayType)
    }
}

// MARK: - SettingValueRulerViewDelegate
extension CenteredRulerTableViewCell: SettingValueRulerViewDelegate {
    public func valueDidChange(_ value: Double) {
        var finalValue = Int(value)
        if let divider = settingType?.divider, divider < 1.0 {
            finalValue = Int(value / divider)
        }
        delegate?.updateSettingValue(for: settingType?.key,
                                     value: finalValue)
    }
}
