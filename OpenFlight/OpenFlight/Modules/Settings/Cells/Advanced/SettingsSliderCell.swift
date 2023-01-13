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

import Reusable
import GroundSdk

/// Settings Slider Cell Delegate.
protocol SettingsSliderCellDelegate: AnyObject {
    /// Notify when slider value changed.
    ///
    /// - Parameters:
    ///     - value: new value of the slider
    ///     - indexPath: IndexPath of the slider cell
    func settingsSliderCellSliderDidFinishEditing(value: Float, atIndexPath indexPath: IndexPath)

    /// Notify when slider in currently editing.
    func settingsSliderCellStartEditing()

    /// Notify when cancel event happened.
    func settingsSliderCellCancelled()
}

/// Common settings slider cell.
final class SettingsSliderCell: MainTableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var bgView: UIView!
    @IBOutlet private weak var settingImage: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var percentLabel: UILabel!
    @IBOutlet private weak var slider: SettingsSlider!

    // MARK: - Internal Properties
    weak var delegate: SettingsSliderCellDelegate?

    // MARK: - Private Properties
    private var settingEntry: SettingEntry?
    private var currentUnit: UnitType?
    private var sliderOverLimitValue: Float?
    private var sliderDefaultValue: Float?
    private var currentValueIntervalStep: Float = 0.05
    private var currentValueStepped: Float = 0.0
    private var indexPath: IndexPath!
    private var isEnabled: Bool = true {
        didSet {
            slider.isEnabled = isEnabled
            titleLabel.isEnabled = isEnabled
        }
    }

    /// Returns formated value according to setting unit.
    private var formattedValue: String {
        switch currentUnit {
        case .percent?:
            return currentUnit?.value(withFloat: slider.value.percentValue(min: slider.minimumValue, max: slider.maximumValue)) ?? ""
        default:
            return currentUnit?.value(withFloat: slider.value) ?? ""
        }
    }

    // MARK: - Init
    override func awakeFromNib() {
        super.awakeFromNib()

        // Add double tap on cell to reset slider to default value.
        addGestureRecognizer(doubleTapGestureRecognizer())
    }

    // MARK: - Override Funcs
    override func prepareForReuse() {
        super.prepareForReuse()

        slider.value = 0.0
        titleLabel.text = nil
        percentLabel.text = nil
    }

    // MARK: - Internal Funcs
    /// Configure cell.
    ///
    /// - Parameters:
    ///     - settingEntry: cell setting entry
    ///     - indexPath: indexPath
    ///     - shouldShowBackground: tells if we must show the background
    func configureCell(settingEntry: SettingEntry,
                       atIndexPath indexPath: IndexPath,
                       shouldShowBackground: Bool = true) {
        setupBackground(shouldShow: shouldShowBackground)

        self.settingEntry = settingEntry
        self.indexPath = indexPath
        titleLabel.text = settingEntry.title
        currentUnit = settingEntry.unit ?? UnitType.none

        sliderOverLimitValue = settingEntry.overLimitValue
        slider.overLimitValue = settingEntry.overLimitValue
        slider.maximumTrackTintColor = settingEntry.bgColor ?? ColorName.defaultTextColor.color
        sliderDefaultValue = settingEntry.defaultValue
        addImage(settingEntry.image)

        if let setting = settingEntry.setting as? DoubleSetting {
            slider.maximumValue = Float(setting.max)
            slider.minimumValue = Float(setting.min)
            slider.value = settingEntry.savedValue ?? Float(setting.value)
        }

        isEnabled = settingEntry.isEnabled
        updateSliderView()
    }
}

// MARK: - Private Funcs
private extension SettingsSliderCell {
    /// Add A range to slider
    ///
    /// - Parameters:
    ///     - settingStepperSlider: setting stepper to add
    func actionStepperSlider(_ settingStepperSlider: SettingStepperSlider) {
        let minValueSlider = slider.minimumValue
        let maxValueSlider = slider.maximumValue
        let limitIntervalChange = settingStepperSlider.limitIntervalChange
        let leftIntervalStep = settingStepperSlider.leftIntervalStep
        let rightIntervalStep = settingStepperSlider.rightIntervalStep
        var currentValueSlider = slider.value
        if (minValueSlider...limitIntervalChange).contains(currentValueSlider) {
            currentValueIntervalStep = leftIntervalStep
        } else {
            currentValueIntervalStep = rightIntervalStep
        }
        currentValueSlider = currentValueSlider <= minValueSlider ? minValueSlider : currentValueSlider
        currentValueSlider = currentValueSlider >= maxValueSlider ? maxValueSlider : currentValueSlider
        let newCurrentValueStepped = roundf(currentValueSlider / currentValueIntervalStep) * currentValueIntervalStep
        currentValueStepped = newCurrentValueStepped
        percentLabel.text = currentUnit?.value2f(withFloat: newCurrentValueStepped)
    }

    /// Update label and slider view.
    func updateSliderView() {
        if let settingStepperSlider = settingEntry?.settingStepperSlider {
            actionStepperSlider(settingStepperSlider)
        } else {
            // no Stepper available
            percentLabel.text = formattedValue
        }

        if !isEnabled {
            percentLabel.textColor = ColorName.disabledHighlightColor.color
        } else if let sliderOverLimitValue = sliderOverLimitValue,
                  slider.value >= sliderOverLimitValue {
            percentLabel.textColor = ColorName.warningColor.color
        } else {
            percentLabel.textColor = ColorName.highlightColor.color
        }
    }

    /// Add image to settingImage.
    ///
    /// - Parameters:
    ///     - image: image to add
    func addImage(_ image: UIImage?) {
        settingImage.isHidden = image == nil
        settingImage.image = image
    }

    /// Provides double tap gesture recognizer.
    func doubleTapGestureRecognizer() -> UITapGestureRecognizer {
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                                action: #selector(onDoubleTap))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2

        return doubleTapGestureRecognizer
    }

    /// Called when number of required taps are reached.
    @objc func onDoubleTap() {
        guard let defaultValue = sliderDefaultValue else { return }

        slider.value = defaultValue
        didFinishEditing(slider)
    }

    /// Sets up background.
    ///
    /// - Parameters:
    ///     - shouldShow: tells if we must show the background
    func setupBackground(shouldShow: Bool) {
        bgView.applyCornerRadius(Style.largeCornerRadius)
        bgView.backgroundColor = shouldShow
        ? ColorName.white.color
        : .clear
    }
}

// MARK: - Actions
private extension SettingsSliderCell {
    @IBAction func sliderValueChanged(_ sender: AnyObject) {
        delegate?.settingsSliderCellStartEditing()
        updateSliderView()
    }

    @IBAction func didFinishEditing(_ sender: AnyObject) {
        if (settingEntry?.settingStepperSlider) != nil {
            guard let unwSettingStepperSlider = sender as? UISlider else { return }
            unwSettingStepperSlider.setValue(currentValueStepped, animated: true)
        }

        delegate?.settingsSliderCellSliderDidFinishEditing(value: slider.value,
                                                           atIndexPath: indexPath)

        LogEvent.log(.button(item: settingEntry?.itemLogKey ?? "" + SettingsBehavioursMode.current.logKey ,
                             value: formattedValue))
    }

    @IBAction func sliderTouchCancelled(_ sender: Any) {
        delegate?.settingsSliderCellCancelled()
    }
}
