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
final class SettingsSliderCell: UITableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var bgView: UIView!
    @IBOutlet private weak var settingImage: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            titleLabel.makeUp()
        }
    }
    @IBOutlet private weak var percentLabel: UILabel! {
        didSet {
            percentLabel.makeUp()
        }
    }
    @IBOutlet private weak var slider: SettingsSlider!
    /// Leading constraint used for the stack view.
    @IBOutlet private weak var stackViewLeadingConstraint: NSLayoutConstraint!
    /// Trailing constraint used for the slider.
    @IBOutlet private weak var sliderTrailingConstraint: NSLayoutConstraint!

    // MARK: - Internal Properties
    weak var delegate: SettingsSliderCellDelegate?

    // MARK: - Private Properties
    private weak var settingEntry: SettingEntry?
    private var currentUnit: UnitType?
    private var sliderOverLimitValue: Float?
    private var sliderDefaultValue: Float?
    private var indexPath: IndexPath!
    private var isEnabled: Bool = true {
        didSet {
            titleLabel.textColor = self.isEnabled ? ColorName.white.color : ColorName.white50.color
            updateSliderView()
            slider.isEnabled = self.isEnabled
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

    // MARK: - Private Enums
    private enum Constants {
        static let defaultLeadingConstraint: CGFloat = 16.0
    }

    // MARK: - Init
    override func awakeFromNib() {
        super.awakeFromNib()

        // Add double tap on cell to reset slider to default value.
        self.addGestureRecognizer(doubleTapGestureRecognizer())
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
    ///     - sideConstraint: leading and trailing constraint value
    func configureCell(settingEntry: SettingEntry,
                       atIndexPath indexPath: IndexPath,
                       shouldShowBackground: Bool = true,
                       sideConstraint: CGFloat = Constants.defaultLeadingConstraint) {
        setupBackground(shouldShow: shouldShowBackground)

        self.settingEntry = settingEntry
        self.titleLabel.text = settingEntry.title
        self.currentUnit = settingEntry.unit ?? UnitType.none
        self.indexPath = indexPath

        self.sliderOverLimitValue = settingEntry.overLimitValue
        self.slider.overLimitValue = settingEntry.overLimitValue
        self.sliderDefaultValue = settingEntry.defaultValue
        self.addImage(settingEntry.image)
        self.isEnabled = settingEntry.isEnabled
        self.slider.isEnabled = settingEntry.isEnabled

        if let setting = settingEntry.setting as? DoubleSetting {
            self.slider.maximumValue = Float(setting.max)
            self.slider.minimumValue = Float(setting.min)
            self.slider.value = settingEntry.savedValue ?? Float(setting.value)
        }

        stackViewLeadingConstraint.constant = sideConstraint
        sliderTrailingConstraint.constant = sideConstraint
        updateSliderView()
    }
}

// MARK: - Private Funcs
private extension SettingsSliderCell {
    /// Update label and slider view.
    func updateSliderView() {
        percentLabel.text = formattedValue

        if !isEnabled {
            percentLabel.textColor = ColorName.white50.color
        } else if let sliderOverLimitValue = sliderOverLimitValue,
                  slider.value >= sliderOverLimitValue {
            percentLabel.textColor = .orange
        } else {
            percentLabel.textColor = ColorName.greenSpring.color
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
            ? ColorName.white20.color
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
        delegate?.settingsSliderCellSliderDidFinishEditing(value: slider.value,
                                                           atIndexPath: indexPath)

        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.advanced,
                             itemName: settingEntry?.itemLogKey ?? "" + SettingsBehavioursMode.current.logKey ,
                             newValue: formattedValue,
                             logType: LogEvent.LogType.button)
    }

    @IBAction func sliderTouchCancelled(_ sender: Any) {
        delegate?.settingsSliderCellCancelled()
    }
}
