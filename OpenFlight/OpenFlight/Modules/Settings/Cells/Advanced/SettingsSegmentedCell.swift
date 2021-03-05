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

/// Settings Segmented Cell Delegate.
protocol SettingsSegmentedCellDelegate: class {
    /// Used to notify which segment in selected of which indexPath.
    func settingsSegmentedCellDidChange(selectedSegmentIndex: Int, atIndexPath indexPath: IndexPath)
}

/// Settings Segmented Cell.
final class SettingsSegmentedCell: UITableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var bgView: UIView!
    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            titleLabel.makeUp()
        }
    }
    @IBOutlet private weak var infoLabel: UILabel!
    @IBOutlet private weak var viewContentInfos: UIView!
    @IBOutlet private weak var segmentControl: UISegmentedControl! {
        didSet {
            segmentControl.backgroundColor = .clear
            segmentControl.layer.backgroundColor = UIColor.clear.cgColor
            segmentControl.customMakeup(normalBackgroundColor: ColorName.clear,
                                        selectedBackgroundColor: ColorName.greenSpring20,
                                        selectedFontColor: ColorName.greenSpring)
            segmentControl.roundCornered()
        }
    }
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var subtitleLabelHeight: NSLayoutConstraint!

    /// Leading constraint which changes if setting is a submode.
    @IBOutlet private weak var bgViewLeadingConstraint: NSLayoutConstraint!
    /// Leading constraint used for the stack view.
    @IBOutlet private weak var stackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var segmentControlTrailingConstraint: NSLayoutConstraint!

    // MARK: - Internal Properties
    weak var delegate: SettingsSegmentedCellDelegate?

    // MARK: - Private Properties
    private var indexPath: IndexPath!
    private var showInfo: (() -> Void)?
    private var infoTapGestureRecognizer: UITapGestureRecognizer?

    // MARK: - Private Enums
    private enum Constants {
        static let defaultSubtitleHeight: CGFloat = 35.0
        static let segmentWidth: CGFloat = 78.0
        static let smallTextLength: Int = 10
        static let defaultLeadingConstraint: CGFloat = 16.0
        static let defaultTrailingConstraint: CGFloat = 8.0
        static let submodeLeadingConstraint: CGFloat = 52.0
    }

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        self.contentView.backgroundColor = .clear
        self.infoTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(infoLabelTouchedUpInside(sender:)))
        if let infoTapGestureRecognizer = self.infoTapGestureRecognizer {
            self.infoLabel.addGestureRecognizer(infoTapGestureRecognizer)
        }
    }

    // MARK: - Internal Funcs
    /// Configure cell.
    ///
    /// - Parameters:
    ///    - cellTitle: title
    ///    - segmentModel: Settings Segment Model
    ///    - subtitle: sub title
    ///    - isEnabled: is enabled
    ///    - alpha: cell alpha
    ///    - subtitleColor: subtitle color
    ///    - showInfo: action handler to show info
    ///    - infoText: info button title
    ///    - indexPath: cell index path
    ///    - segmentSize: segment size
    ///    - isSubmode: tells if the cell is a submode of a setting
    ///    - shouldShowBackground: tells if we must show the background
    ///    - leadingConstraint: leading constraint for the stack view which contains information labels
    ///    - trailingConstraint: trailing constraint for the segment control
    func configureCell(cellTitle: String?,
                       segmentModel: SettingsSegmentModel,
                       subtitle: String?,
                       isEnabled: Bool = true,
                       alpha: CGFloat = 1.0,
                       subtitleColor: UIColor = ColorName.white.color,
                       showInfo: (() -> Void)? = nil,
                       infoText: String? = nil,
                       atIndexPath indexPath: IndexPath,
                       segmentSize: CGFloat? = Constants.segmentWidth,
                       isSubmode: Bool? = false,
                       shouldShowBackground: Bool = true,
                       leadingConstraint: CGFloat = Constants.defaultLeadingConstraint,
                       trailingConstraint: CGFloat = Constants.defaultTrailingConstraint) {
        setupBackground(shouldShow: shouldShowBackground)
        titleLabel.text = cellTitle
        self.indexPath = indexPath
        for view in contentView.subviews {
            view.alpha = alpha
        }

        self.showInfo = showInfo
        segmentControl.removeAllSegments()
        for segmentItem: SettingsSegment in segmentModel.segments {
            segmentControl.insertSegment(withTitle: segmentItem.title,
                                         at: self.segmentControl.numberOfSegments,
                                         animated: false)
            segmentControl.setEnabled(!segmentItem.disabled,
                                      forSegmentAt: self.segmentControl.numberOfSegments - 1)
            // Set fixed size for small item to align items, automatic dimension will be set otherwise.
            if segmentItem.title.count < Constants.smallTextLength {
                segmentControl.setWidth(Constants.segmentWidth,
                                        forSegmentAt: self.segmentControl.numberOfSegments - 1)
            }

        }

        if showInfo != nil {
            let attrs: [NSAttributedString.Key: Any] = [.font: ParrotFontStyle.regular.font,
                                                        .underlineStyle: NSUnderlineStyle.single.rawValue,
                                                        .foregroundColor: ColorName.white.color,
                                                        .underlineColor: ColorName.white.color]
            let attributeString = NSMutableAttributedString(string: infoText ?? L10n.commonInfos, attributes: attrs)
            infoLabel.attributedText = attributeString
        } else {
            viewContentInfos.isHidden = true
            viewContentInfos.invalidateIntrinsicContentSize()
        }

        if (0...segmentModel.segments.count - 1).contains(segmentModel.selectedIndex) {
            segmentControl.selectedSegmentIndex = segmentModel.selectedIndex
        }

        segmentControl.isEnabled = isEnabled
        subtitleLabel.text = subtitle
        subtitleLabel.textColor = subtitleColor
        subtitleLabelHeight.constant = subtitle == nil ? 0 : Constants.defaultSubtitleHeight
        bgViewLeadingConstraint.constant = isSubmode == true ? Constants.submodeLeadingConstraint : Constants.defaultLeadingConstraint
        stackViewLeadingConstraint.constant = leadingConstraint
        segmentControlTrailingConstraint.constant = trailingConstraint
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
private extension SettingsSegmentedCell {
    @IBAction func infoLabelTouchedUpInside(sender: AnyObject) {
        showInfo?()
    }

    /// UISegmentedControl's segment changed.
    @IBAction func segmentDidChange(_ sender: UISegmentedControl) {
        delegate?.settingsSegmentedCellDidChange(selectedSegmentIndex: sender.selectedSegmentIndex,
                                                 atIndexPath: indexPath)
    }
}
