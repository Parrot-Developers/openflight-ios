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

import Foundation
import SwiftyUserDefaults
import GroundSdk

/// Some settings may have a reverse logique.
class ReversibleSettingEntry: SettingEntry {
    var isReversed: Bool = false
}

/// Defines a segment model.
public struct SettingsSegment {
    let title: String
    let disabled: Bool
    let image: UIImage?

    /// Init.
    ///
    /// - Parameters:
    ///   - title: the title
    ///   - disabled: boolean describing disabled state
    ///   - image: the image used
    public init(title: String, disabled: Bool, image: UIImage?) {
        self.title = title
        self.disabled = disabled
        self.image = image
    }
}

/// Defines a group of segment model.
public struct SettingsSegmentModel {
    let segments: [SettingsSegment]
    let selectedIndex: Int
    let isBoolean: Bool

    var nextIndex: Int {
        return (selectedIndex + 1) % segments.count
    }

    var previousIndex: Int {
        let previous = selectedIndex - 1
        return previous >= 0 ? previous : segments.count - 1
    }

    /// Init.
    ///
    /// - Parameters:
    ///   - segments: the list of segment
    ///   - selectedIndex: the default selected index
    ///   - isBoolean: boolean describing the type of segment
    public init(segments: [SettingsSegment], selectedIndex: Int, isBoolean: Bool) {
        self.segments = segments
        self.selectedIndex = selectedIndex
        self.isBoolean = isBoolean
    }
}

/// Defines a model for boolean settings. Used to provides custom names.
struct SettingsBoolChoice {
    let firstChoiceName: String
    let secondChoiceName: String
}

/// Define a model to add a range stepper on the slider
struct SettingStepperSlider {
    let limitIntervalChange: Float
    let leftIntervalStep: Float
    let rightIntervalStep: Float
}

/// Model defines to display setting in cells for specific settings.
class SettingEntry: Equatable {
    // MARK: - Internal Properties
    /// Type of the setting.
    var setting: Any?
    /// Title.
    var title: String?
    /// Subtitle.
    var subtitle: String?
    /// Value unit type.
    var unit: UnitType?
    /// Value limit.
    var overLimitValue: Float?
    /// Default value.
    var defaultValue: Float?
    /// Saved value.
    var savedValue: Float?
    /// Tells if setting is enabled.
    var isEnabled: Bool
    /// Subtitle color.
    var subtitleColor: UIColor
    /// Background color.
    var bgColor: UIColor?
    /// Tells if there is info to show.
    var showInfo: (() -> Void)?
    /// Info button text.
    var infoText: String?
    /// Setting image.
    var image: UIImage?
    /// Setting disabled image.
    var imageDisabled: UIImage?
    /// Item key for log.
    var itemLogKey: String?
    /// Choice names for boolean setting.
    var settingsBoolChoice: SettingsBoolChoice
    /// Setting Stepper slider
    var settingStepperSlider: SettingStepperSlider?

    // MARK: - Init
    init(setting: Any? = nil,
         title: String? = nil,
         subtitle: String? = nil,
         unit: UnitType? = nil,
         overLimitValue: Float? = nil,
         defaultValue: Float? = nil,
         savedValue: Float? = nil,
         isEnabled: Bool = true,
         subtitleColor: UIColor = ColorName.defaultTextColor.color,
         bgColor: UIColor? = nil,
         showInfo: (() -> Void)? = nil,
         infoText: String? = nil,
         image: UIImage? = nil,
         imageDisabled: UIImage? = nil,
         itemLogKey: String? = nil,
         settingsBoolChoice: SettingsBoolChoice = SettingsBoolChoice(firstChoiceName: L10n.commonNo, secondChoiceName: L10n.commonYes),
         settingStepperSlider: SettingStepperSlider? = nil
         ) {
        self.setting = setting
        self.title = title
        self.subtitle = subtitle
        self.unit = unit
        self.overLimitValue = overLimitValue
        self.defaultValue = defaultValue
        self.savedValue = savedValue
        self.isEnabled = isEnabled
        self.subtitleColor = subtitleColor
        self.bgColor = bgColor
        self.showInfo = showInfo
        self.infoText = infoText
        self.image = image
        self.imageDisabled = imageDisabled
        self.itemLogKey = itemLogKey
        self.settingsBoolChoice = settingsBoolChoice
        self.settingStepperSlider = settingStepperSlider
    }

    // MARK: - Equatable Implementation
    static func == (lhs: SettingEntry, rhs: SettingEntry) -> Bool {
        return lhs.title == rhs.title
            && lhs.subtitle == rhs.subtitle
            && lhs.unit == rhs.unit
            && lhs.overLimitValue == rhs.overLimitValue
    }

    // MARK: - Public helpers
    /// Turns SettingEntry into SettingsSegmentModel regardings its type.
    var segmentModel: SettingsSegmentModel? {
        let segments: [SettingsSegment]
        let selectedIndex: Int
        let isBool: Bool
        // BoolSetting.
        if let setting = setting as? BoolSetting {
            segments = [SettingsSegment(title: settingsBoolChoice.firstChoiceName, disabled: setting.updating, image: imageDisabled),
                        SettingsSegment(title: settingsBoolChoice.secondChoiceName, disabled: setting.updating, image: image)]
            var boolValue = setting.value
            if let reversibleSettingEntry = self as? ReversibleSettingEntry,
               reversibleSettingEntry.isReversed {
                boolValue.toggle()
            }
            selectedIndex = boolValue ? 1 : 0
            isBool = true
        } // DefaultsKey<Bool?>.
        else if let setting = setting as? DefaultsKey<Bool?> {
            segments = [SettingsSegment(title: settingsBoolChoice.firstChoiceName,
                                        disabled: false,
                                        image: imageDisabled),
                        SettingsSegment(title: settingsBoolChoice.secondChoiceName,
                                        disabled: false,
                                        image: image)]
            selectedIndex = (Defaults[key: setting] ?? true) ? 1 : 0
            isBool = true
        } // SettingEnum.Type.
        else if let setting = setting as? SettingEnum.Type {
            segments = setting.allValues.map({ SettingsSegment(title: $0.localized, disabled: false, image: $0.image) })
            selectedIndex = setting.selectedIndex
            isBool = false
        } // DroneSettingModel | DriSettingModel.
        else if let viewModel = setting as? DroneSettingModelProtocol {
            selectedIndex = viewModel.selectedIndex
            segments = viewModel.allValues.map { mode in
                let isModeSupported = viewModel.supportedValues.contains(where: { mode.key == $0.key })
                let isUpdating = viewModel.isUpdating
                let isSegmentDisabled = isUpdating || !isModeSupported || viewModel.forceDisabling

                return SettingsSegment(title: mode.localized, disabled: isSegmentDisabled, image: mode.image)
            }
            isBool = viewModel.allValues.first?.usedAsBool ?? false
        } else {
            return nil
        }
        return SettingsSegmentModel(segments: segments, selectedIndex: selectedIndex, isBoolean: isBool)
    }

    /// Save setting regarding its type.
    ///
    /// - Parameters:
    ///     - settingIndex: setting index
    func save(at settingIndex: Int) {
        // BoolSetting.
        if let setting = setting as? BoolSetting {
            setting.value = !setting.value
        } // DefaultsKey<Bool?>.
        else if let setting = setting as? DefaultsKey<Bool?> {
            Defaults[key: setting] = settingIndex == 0 ? false : true
        } // SettingEnum.Type.
        else if let setting = setting as? SettingEnum.Type,
                (0...setting.allValues.count - 1).contains(settingIndex) {
            Defaults[key: setting.defaultKey] = setting.allValues[settingIndex].rawValue
        } // DroneSettingModel | DriSettingModel.
        else if let setting = setting as? DroneSettingModelProtocol,
                (0...setting.allValues.count - 1).contains(settingIndex) {
            setting.onSelect?(setting.allValues[settingIndex])
        }
    }
}
