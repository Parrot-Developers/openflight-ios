//    Copyright (C) 2023 Parrot Drones SAS
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
import Reusable
import GroundSdk
import Combine

/// Cell used to display geo fence setting.
final class SettingsGeoFenceCell: MainTableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var bgView: UIView!
    @IBOutlet private weak var stackView: UIStackView!

    // MARK: - Private Properties
    private var viewModel: SettingsGeofenceViewModel!
    private var geoFenceSegmentedCell = SettingsSegmentedCell.loadFromNib()
    private var distanceSliderCell = SettingsSliderCell.loadFromNib()
    private var altitudeSliderCell = SettingsSliderCell.loadFromNib()
    private var cancellables = Set<AnyCancellable>()

    private enum Constants {
        static let altitudeIndex: Int = 1
        static let distanceIndex: Int = 2
        static let distanceMinRange: Float = 10
        static let distanceMaxRange: Float = 1000
        static let distanceHighlightedRangePercent: Float = 0.6
    }

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        initView()
    }

    /// Setup viewModel
    func setup(viewModel: SettingsViewModelProtocol?) {
        guard let viewModel = viewModel as? SettingsGeofenceViewModel else { return }
        self.viewModel = viewModel

        viewModel.isGeofenceActivatedPublisher
            .removeDuplicates()
            .combineLatest(viewModel.minDistancePublisher.removeDuplicates(),
                           viewModel.distancePublisher.removeDuplicates(),
                           viewModel.maxDistancePublisher.removeDuplicates())
            .combineLatest(viewModel.minAltitudePublisher.removeDuplicates(),
                           viewModel.altitudePublisher.removeDuplicates(),
                           viewModel.isUpdatingPublisher.removeDuplicates())
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.updateView()
            }
            .store(in: &cancellables)

        updateView()
    }
}

// MARK: - Private Funcs
private extension SettingsGeoFenceCell {
    /// Inits the view.
    func initView() {
        bgView.cornerRadiusedWith(backgroundColor: .white, radius: Style.largeCornerRadius)
        geoFenceSegmentedCell.delegate = self
        distanceSliderCell.delegate = self
        altitudeSliderCell.delegate = self
    }

    /// Updates view according to the view model state.
    func updateView() {
        stackView.removeSubViews()
        configureGeoFenceSegmentedCell()
        configureDistanceSliderCell()
        configureAltitudeSliderCell()
        stackView.addArrangedSubview(geoFenceSegmentedCell.contentView)
        stackView.addArrangedSubview(distanceSliderCell.contentView)
        stackView.addArrangedSubview(altitudeSliderCell.contentView)
        stackView.addSeparators(backColor: ColorName.defaultBgcolor.color)
    }

    /// Configures the segmented cell.
    func configureGeoFenceSegmentedCell() {
        let settingSegmentedEntry = viewModel.geoFenceModeEntry
        if let settingSliderSegment: SettingsSegmentModel = settingSegmentedEntry.segmentModel {
            geoFenceSegmentedCell.configureCell(cellTitle: settingSegmentedEntry.title,
                                        segmentModel: settingSliderSegment,
                                        subtitle: settingSegmentedEntry.subtitle,
                                        isEnabled: settingSegmentedEntry.isEnabled,
                                        subtitleColor: settingSegmentedEntry.subtitleColor,
                                        showInfo: settingSegmentedEntry.showInfo,
                                        atIndexPath: IndexPath(),
                                        shouldShowBackground: false)
            geoFenceSegmentedCell.enabledMargins = []
        }
    }

    /// Configures the distance slider cell.
    func configureDistanceSliderCell() {
        let settingSegmentedEntry = viewModel.geoFenceDistanceEntry
        let min = Float((settingSegmentedEntry.setting as? SliderSetting)?.min) ?? Constants.distanceMinRange
        let max = settingSegmentedEntry.settingStepperSlider?.limitIntervalChange ?? Constants.distanceMaxRange
        distanceSliderCell.configureCell(settingEntry: settingSegmentedEntry,
                                         atIndexPath: IndexPath(row: Constants.distanceIndex, section: 0),
                                         shouldShowBackground: false,
                                         highlightedRange: SliderHighlightedRange(min: min,
                                                                            max: max,
                                                                            percent: Constants.distanceHighlightedRangePercent))
        distanceSliderCell.enabledMargins = []
    }

    /// Configures the altitude slider cell.
    func configureAltitudeSliderCell() {
        let settingSegmentedEntry = viewModel.geoFenceAltitudeEntry
        altitudeSliderCell.configureCell(settingEntry: settingSegmentedEntry,
                                         atIndexPath: IndexPath(row: Constants.altitudeIndex, section: 0),
                                         shouldShowBackground: false)
        altitudeSliderCell.enabledMargins = []
    }
}

// MARK: - SettingsSliderCellDelegate
extension SettingsGeoFenceCell: SettingsSliderCellDelegate {
    func settingsSliderCellSliderDidFinishEditing(value: Float, atIndexPath indexPath: IndexPath) {
        let convertedValue = UnitHelper.roundedDistanceWithDouble(Double(value))

        switch indexPath.row {
        case Constants.altitudeIndex:
            if let setting = viewModel.geoFenceAltitudeEntry.setting as? SliderSetting {
                setting.value = convertedValue
                viewModel.saveGeofenceAltitude(convertedValue)
            }
        case Constants.distanceIndex:
            if let setting = viewModel.geoFenceDistanceEntry.setting as? SliderSetting {
                setting.value = convertedValue
                viewModel.saveGeofenceDistance(convertedValue)
            }
        default:
            break
        }
    }

    func settingsSliderCellStartEditing() { }

    func settingsSliderCellCancelled() { }
}

// MARK: - SettingsSegmentedCellDelegate
extension SettingsGeoFenceCell: SettingsSegmentedCellDelegate {
    func settingsSegmentedCellDidChange(selectedSegmentIndex: Int, atIndexPath indexPath: IndexPath) {
        viewModel.geoFenceModeEntry.save(at: selectedSegmentIndex)
    }
}
