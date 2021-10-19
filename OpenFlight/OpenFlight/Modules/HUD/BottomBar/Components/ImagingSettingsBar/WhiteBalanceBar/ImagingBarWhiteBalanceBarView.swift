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
import GroundSdk

/// View that displays a `SegmentedBarView` with white balance.
final class ImagingBarWhiteBalanceBarView: UIView, NibOwnerLoadable, BarItemModeDisplayer {
    // MARK: - Outlets
    @IBOutlet private weak var segmentedBarContainer: UIView!
    @IBOutlet private weak var centeredRulerBarContainer: UIView!
    @IBOutlet private weak var autoButton: UIButton!
    @IBOutlet private weak var presetsLabel: UILabel! {
        didSet {
            presetsLabel.makeUp(with: .large, and: ColorName.defaultTextColor)
            presetsLabel.text = L10n.commonPresets
        }
    }
    @IBOutlet weak var whiteBalanceStackView: UIStackView!
    @IBOutlet weak var rulerStackView: UIStackView!
    @IBOutlet weak var presetsView: UIView!

    // MARK: - Internal Properties
    weak var viewModel: ImagingBarWhiteBalanceViewModel? {
        didSet {
            addSegmentedBar()
            addRulerBar()
            updateAutomaticMode(isAutomatic: viewModel?.state.value.mode as? Camera2WhiteBalanceMode == .automatic)
        }
    }

    var barId: String? { viewModel?.barId }

    // MARK: - Private Properties
    private var segmentedBarView: SegmentedBarView<ImagingBarState>?
    private var centeredRulerBarView: CenteredRulerBarView<ImagingBarState>?
    /// Secondary view model used to update button state.
    private let secondaryViewModel = ImagingBarWhiteBalanceViewModel()
    private var customWhiteBalanceViewModel = ImagingBarWhiteBalanceCustomViewModel()

    // MARK: - Private Enums
    private enum Constants {
        static let selectionDelay: TimeInterval = 0.2
        static let animationDuration: TimeInterval = 0.1
    }

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitImagingBarWhiteBalanceBarView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitImagingBarWhiteBalanceBarView()
    }
}

// MARK: - Actions
private extension ImagingBarWhiteBalanceBarView {
    @IBAction func autoButtonTouchedUpInside(_ sender: Any) {
        viewModel?.setAutomaticMode()
        segmentedBarView?.updateModels()
    }

    @IBAction func presetButtonTouchedUpInside(_ sender: Any) {
        updateBarMode(showCustom: false)
    }
}

// MARK: - Private Funcs
private extension ImagingBarWhiteBalanceBarView {
    /// Common init.
    func commonInitImagingBarWhiteBalanceBarView() {
        self.loadNibContent()
        self.layer.cornerRadius = Style.largeCornerRadius
        self.layer.masksToBounds = true
        secondaryViewModel.state.valueChanged = { [weak self] state in
            self?.updateAutomaticMode(isAutomatic: state.mode as? Camera2WhiteBalanceMode == .automatic)
            self?.segmentedBarView?.updateModels()
        }

        updateAutomaticMode(isAutomatic: secondaryViewModel.state.value.mode as? Camera2WhiteBalanceMode == .automatic)
        segmentedBarView?.updateModels()
    }

    /// Add segmented bar displaying current mode values.
    func addSegmentedBar() {
        segmentedBarView?.removeFromSuperview()
        let segmentedBarView = SegmentedBarView<ImagingBarState>()
        segmentedBarView.viewModel = viewModel
        segmentedBarView.delegate = self
        segmentedBarContainer.addWithConstraints(subview: segmentedBarView)
        self.segmentedBarView = segmentedBarView
    }

    /// Add ruler bar displaying custom temperature values.
    func addRulerBar() {
        centeredRulerBarView?.removeFromSuperview()
        let rulerBar = CenteredRulerBarView<ImagingBarState>()
        rulerBar.viewModel = customWhiteBalanceViewModel
        centeredRulerBarContainer.addWithConstraints(subview: rulerBar)
        self.centeredRulerBarView = rulerBar
    }

    /// Update UI with given automatic setting.
    ///
    /// - Parameters:
    ///    - isAutomatic: boolean describing if setting is monitored automatically.
    func updateAutomaticMode(isAutomatic: Bool) {
        autoButton.customCornered(corners: [.bottomLeft, .topLeft],
                                  radius: Style.largeCornerRadius,
                                  backgroundColor: isAutomatic ? ColorName.highlightColor.color : ColorName.white90.color,
                                  borderColor: .clear)
        autoButton.layer.masksToBounds = true
        autoButton.tintColor = isAutomatic ? .white : ColorName.defaultTextColor.color
        centeredRulerBarView?.isAutomatic = isAutomatic
    }

    /// Switches between white balance mode display and custom temperature ruler, animates changes.
    ///
    /// - Parameters:
    ///    - showCustom: boolean describing whether custom temperatures should be displayed.
    func updateBarMode(showCustom: Bool) {
        if showCustom == true {
            presetsView.isHidden = true
            rulerStackView.isHidden = false
        } else {
            rulerStackView.isHidden = true
            presetsView.isHidden = false
        }
    }
}

// MARK: - SegmentedBarViewDelegate
extension ImagingBarWhiteBalanceBarView: SegmentedBarViewDelegate {
    func didSelectWithoutAutoClosing(mode: BarItemMode) {
        if mode as? Camera2WhiteBalanceMode == .custom {
            // Show custom bar.
            updateBarMode(showCustom: true)
            // Switch to custom only if mode isn't automatic.
            if let currentMode = self.viewModel?.state.value.mode as? Camera2WhiteBalanceMode, currentMode != .automatic {
                self.viewModel?.update(mode: mode)
            }
        } else {
            self.viewModel?.update(mode: mode)
        }
        self.segmentedBarView?.updateModels()
    }
}
