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

/// Settings Segmented Control Delegate.
public protocol SettingsSegmentedControlDelegate: AnyObject {
    /// Used to notify which segment in selected of which indexPath.
    ///
    /// - Parameters:
    ///     - sender: the segmented control called
    ///     - selectedSegmentIndex: the selected segment index
    func settingsSegmentedControlDidChange(sender: SettingsSegmentedControl,
                                           selectedSegmentIndex: Int)
}

/// Custom settings segment with the imageView placed above the label
public class SettingsSegmentedControl: BackgroundStackView {

    // MARK: - Private Enums
    private enum Constants {
        static let segmentWidth: (compact: CGFloat, regular: CGFloat) = (90, 115)
    }

    // MARK: - Internal Properties
    public weak var delegate: SettingsSegmentedControlDelegate?

    public var segmentModel: SettingsSegmentModel? {
        didSet {
            fill()
        }
    }

    public var minSegmentWidth:  (compact: CGFloat, regular: CGFloat) = Constants.segmentWidth {
        didSet {
            fill()
        }
    }

    public var isEnabled: Bool = true {
        didSet {
            fill()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
}

private extension SettingsSegmentedControl {

    /// Initializes segment.
    func initView() {
        backgroundColor = ColorName.defaultBgcolor.color
        cornerRadius = Style.largeCornerRadius
        spacing = 0
    }

    /// Fills segments.
    func fill() {
        guard let segmentModel = segmentModel else {
            isHidden = true
            return
        }

        isHidden = false
        safelyRemoveArrangedSubviews()
        for (index, segment) in segmentModel.segments.enumerated() {
            let button = SettingsButton(type: UIButton.ButtonType.custom)
            button.tag = index
            if segmentModel.isBoolean {
                button.setTitle(index == 0 ? L10n.commonNo : L10n.commonYes, for: .normal)
                button.setImage(nil, for: .normal)
            } else {
                button.setTitle(segment.title, for: .normal)
                button.setImage(segment.image, for: .normal)
            }

            // disables button if segmented control is enabled and the segment is disabled
            let segmentIsEnabled = isEnabled && !segment.disabled
            button.isUserInteractionEnabled = segmentIsEnabled
            button.alphaWithEnabledState(segmentIsEnabled)

            // updates normal style
            button.makeup(with: FontStyle.current, color: .defaultTextColor, and: .normal)

            // updates margin and constraint
            button.contentEdgeInsets = Layout.tableViewCellContentInset(isRegularSizeClass)
            let constant = isRegularSizeClass ? minSegmentWidth.regular : minSegmentWidth.compact
            button.addConstraint(NSLayoutConstraint(item: button,
                                                    attribute: .width,
                                                    relatedBy: .greaterThanOrEqual,
                                                    toItem: nil,
                                                    attribute: .notAnAttribute,
                                                    multiplier: 1.0,
                                                    constant: constant))
            button.addTarget(self,
                             action: #selector(segmentButtonTouchedUpInside),
                             for: .touchUpInside)
            addArrangedSubview(button)
        }
        updateSegment(tag: segmentModel.selectedIndex)
    }

    /// Updates button's view background color.
    ///
    /// - Parameters:
    ///     - tag: button tag
    func updateSegment(tag: Int?) {
        guard let tag = tag else { return }

        arrangedSubviews
            .compactMap { $0 as? UIButton }
            .forEach { button in
                let isSelected = arrangedSubviews.firstIndex(of: button) == tag
                button.isSelected = isSelected
                let buttonTitle = button.title(for: .selected)
                let isOffButton = [L10n.commonNo, L10n.commonOff].contains(buttonTitle)
                let selectedBackgroundColor = isOffButton ? ColorName.white.color : ColorName.highlightColor.color
                let selectedBorderColor = isOffButton ? ColorName.defaultBgcolor.color : .clear
                button.makeup(with: FontStyle.current,
                              color: isOffButton ? .defaultTextColor : .white,
                              and: .selected)
                button.tintColor = button.titleColor(for: .selected)
                button.addShadow(condition: isSelected)
                button.cornerRadiusedWith(backgroundColor: isSelected ? selectedBackgroundColor : .clear,
                                          borderColor: isSelected ? selectedBorderColor : .clear,
                                          radius: Style.largeCornerRadius,
                                          borderWidth: Style.largeBorderWidth)
            }
    }
}

// MARK: - Actions
private extension SettingsSegmentedControl {

    /// Observes touched up inside on value.
    ///
    /// - Parameters:
    ///     - sender: selected value for the current setting
    @objc func segmentButtonTouchedUpInside(sender: UIButton) {
        guard !sender.isSelected else {
            return
        }
        updateSegment(tag: sender.tag)
        segmentModel?.selectedIndex = sender.tag
        delegate?.settingsSegmentedControlDidChange(sender: self,
                                                    selectedSegmentIndex: sender.tag)
    }
}
