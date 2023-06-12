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
import GroundSdk

/// Cell used to display Return Home end hovering setting.
final class SettingsEndHoveringCell: MainTableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var bgView: UIView!
    @IBOutlet private weak var stackView: UIStackView!

    // MARK: - Private Properties
    private let viewModel = SettingsEndHoveringViewModel(rthSettingsMonitor: Services.hub.rthSettingsMonitor)
    private var segmentedCell: SettingsSegmentedCell = SettingsSegmentedCell.loadFromNib()
    private var sliderCell: SettingsSliderCell = SettingsSliderCell.loadFromNib()

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        initView()
        initViewModel()
    }
}

// MARK: - Private Funcs
private extension SettingsEndHoveringCell {
    /// Inits the view.
    func initView() {
        bgView.cornerRadiusedWith(backgroundColor: .white, radius: Style.largeCornerRadius)
        segmentedCell.delegate = self
        sliderCell.delegate = self
    }

    /// Inits the hovering mode view model.
    func initViewModel() {
        viewModel.state.valueChanged = { [weak self] _ in
            self?.updateView()
        }
        updateView()
    }

    /// Updates view according to the view model state.
    func updateView() {
        stackView.removeSubViews()
        configureSegmentedCell()
        configureSliderCell()
        stackView.addArrangedSubview(segmentedCell.contentView)
        stackView.addArrangedSubview(sliderCell.contentView)
        stackView.addSeparators(backColor: ColorName.defaultBgcolor.color)
    }

    /// Configures the segmented cell.
    func configureSegmentedCell() {
        let settingSegmentedEntry = viewModel.endHoveringModeEntry
        if let settingSliderSegment: SettingsSegmentModel = settingSegmentedEntry.segmentModel {
            segmentedCell.configureCell(cellTitle: settingSegmentedEntry.title,
                                        segmentModel: settingSliderSegment,
                                        subtitle: settingSegmentedEntry.subtitle,
                                        isEnabled: settingSegmentedEntry.isEnabled,
                                        subtitleColor: settingSegmentedEntry.subtitleColor,
                                        showInfo: settingSegmentedEntry.showInfo,
                                        atIndexPath: IndexPath(),
                                        shouldShowBackground: false)
            segmentedCell.enabledMargins = []
        }
    }

    /// Configures the slider cell.
    func configureSliderCell() {
        let settingSliderEntry = viewModel.endHoveringAltitudeEntry
        sliderCell.configureCell(settingEntry: settingSliderEntry,
                                 atIndexPath: IndexPath(),
                                 shouldShowBackground: false)
        sliderCell.enabledMargins = []
    }
}

// MARK: - SettingsSliderCellDelegate
extension SettingsEndHoveringCell: SettingsSliderCellDelegate {
    func settingsSliderCellSliderDidFinishEditing(value: Float, atIndexPath indexPath: IndexPath) {
        if let setting = viewModel.endHoveringAltitudeEntry.setting as? SliderSetting {
            setting.value = Double(value)
            let userPreferredRthSettings = viewModel.rthSettingsMonitor.getUserRthSettings()
            let rthSettings = RthSettings(rthReturnTarget: userPreferredRthSettings.rthReturnTarget,
                                          rthHeight: userPreferredRthSettings.rthHeight,
                                          rthEndBehaviour: userPreferredRthSettings.rthEndBehaviour,
                                          rthHoveringHeight: setting.value)
            viewModel.rthSettingsMonitor.updateUserRthSettings(rthSettings: rthSettings)
        }
    }

    func settingsSliderCellStartEditing() { }

    func settingsSliderCellCancelled() { }
}

// MARK: - SettingsSegmentedCellDelegate
extension SettingsEndHoveringCell: SettingsSegmentedCellDelegate {
    func settingsSegmentedCellDidChange(selectedSegmentIndex: Int, atIndexPath indexPath: IndexPath) {
        viewModel.endHoveringModeEntry.save(at: selectedSegmentIndex)
    }
}
