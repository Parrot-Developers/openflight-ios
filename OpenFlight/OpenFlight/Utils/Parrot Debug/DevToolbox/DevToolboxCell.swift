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
import GroundSdk
import Reusable

/// Parrot DevToolbox cell to show DevToolbox content.
class DevToolboxCell: UITableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var textField: UITextField!
    @IBOutlet private weak var boolSwitch: UISwitch!
    @IBOutlet private weak var sliderView: UISlider!

    // MARK: - Private Properties
    private var entry: DebugSetting?

    // MARK: - Public Funcs
    /// Update content from DebugSetting value.
    ///
    /// - Parameters:
    ///    - entry: DebugSetting entry
    func update(withEntry entry: DebugSetting) {
        self.entry = entry
        nameLabel.text = entry.name
        textField.isEnabled = !entry.updating
        boolSwitch.isEnabled = !entry.updating
        textField.isUserInteractionEnabled = !entry.readOnly
        boolSwitch.isUserInteractionEnabled = !entry.readOnly
        textField.isHidden = true
        boolSwitch.isHidden = true
        sliderView.isHidden = true
        switch entry {
        case let setting as BoolDebugSetting:
            boolSwitch.isHidden = false
            boolSwitch.isOn = setting.value
        case let setting as TextDebugSetting:
            textField.isHidden = false
            textField.text = setting.value
            textField.keyboardType = .default
        case let setting as NumericDebugSetting:
            textField.isHidden = false
            if let range = setting.range, !setting.readOnly {
                textField.isUserInteractionEnabled = false
                sliderView.isHidden = false
                sliderView.minimumValue = Float(range.lowerBound)
                sliderView.maximumValue = Float(range.upperBound)
                sliderView.setValue(Float(setting.value), animated: true)
            }
            textField.text = setting.displayString
            textField.keyboardType = .numbersAndPunctuation
        default:
            textField.text = "Unknown type" // Should not be localized
        }
    }
}

// MARK: - Actions
private extension DevToolboxCell {
    @IBAction func switchDidChange(_ sender: Any) {
        (entry as? BoolDebugSetting)?.value = boolSwitch.isOn
    }
}

// MARK: - TextField delegate methods
extension DevToolboxCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let text = textField.text {
            if let setting = entry as? TextDebugSetting {
                setting.value = text
            } else if let setting = entry as? NumericDebugSetting,
                let value = Double(text) {
                setting.value = value
            }
        }
        return true
    }
}
