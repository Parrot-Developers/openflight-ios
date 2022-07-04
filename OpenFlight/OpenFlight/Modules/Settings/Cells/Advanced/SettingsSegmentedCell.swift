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

/// Settings Segmented Cell Delegate.
protocol SettingsSegmentedCellDelegate: AnyObject {
    /// Used to notify which segment in selected of which indexPath.
    func settingsSegmentedCellDidChange(selectedSegmentIndex: Int, atIndexPath indexPath: IndexPath)
}

/// Settings Segmented Cell.
class SettingsSegmentedCell: MainTableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var bgView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var infoLabel: UILabel!
    @IBOutlet private weak var segmentControl: SettingsSegmentedControl!
    @IBOutlet private weak var subtitleView: UIView!
    @IBOutlet private weak var subtitleLabel: UILabel!

    // MARK: - Internal Properties
    weak var delegate: SettingsSegmentedCellDelegate?

    // MARK: - Private Properties
    private var indexPath: IndexPath!
    private var showInfo: (() -> Void)?
    private var infoTapGestureRecognizer: UITapGestureRecognizer?

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        initView()
    }

    /// Initializes view.
    func initView() {
        subtitleView.layer.cornerRadius = Style.largeCornerRadius
        segmentControl.delegate = self
        infoTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(infoLabelTouchedUpInside(sender:)))
        if let infoTapGestureRecognizer = infoTapGestureRecognizer {
            infoLabel.addGestureRecognizer(infoTapGestureRecognizer)
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
    ///    - subtitleColor: subtitle color
    ///    - showInfo: action handler to show info
    ///    - infoText: info button title
    ///    - indexPath: cell index path
    ///    - shouldShowBackground: tells if we must show the background
    func configureCell(cellTitle: String?,
                       segmentModel: SettingsSegmentModel,
                       subtitle: String?,
                       isEnabled: Bool = true,
                       subtitleColor: UIColor = ColorName.defaultTextColor.color,
                       subtitleBackgroundColor: UIColor = ColorName.defaultBgcolor.color,
                       showInfo: (() -> Void)? = nil,
                       infoText: String? = nil,
                       atIndexPath indexPath: IndexPath,
                       shouldShowBackground: Bool = true) {
        setupBackground(shouldShow: shouldShowBackground)
        titleLabel.text = cellTitle
        self.indexPath = indexPath
        self.showInfo = showInfo

        // updates segments
        segmentControl.segmentModel = segmentModel

        // updates enabled state
        segmentControl.isEnabled = isEnabled
        titleLabel.isEnabled = isEnabled
        infoLabel.isEnabled = isEnabled
        subtitleLabel.isEnabled = isEnabled

        // displays show info
        if showInfo != nil {
            let attrs: [NSAttributedString.Key: Any] = [.font: ParrotFontStyle.regular.font,
                                                        .underlineStyle: NSUnderlineStyle.single.rawValue,
                                                        .foregroundColor: ColorName.defaultTextColor.color,
                                                        .underlineColor: ColorName.defaultTextColor.color]
            let attributeString = NSMutableAttributedString(string: infoText ?? L10n.commonInfos, attributes: attrs)
            infoLabel.attributedText = attributeString
        }
        infoLabel.isHidden = showInfo == nil

        subtitleLabel.text = subtitle
        subtitleLabel.textColor = subtitleColor
        subtitleView.backgroundColor = subtitleBackgroundColor
        subtitleView.isHidden = subtitle == nil
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
private extension SettingsSegmentedCell {
    @IBAction func infoLabelTouchedUpInside(sender: AnyObject) {
        showInfo?()
    }
}

// MARK: - SettingsSegmentedControlDelegate
extension SettingsSegmentedCell: SettingsSegmentedControlDelegate {
    func settingsSegmentedControlDidChange(sender: SettingsSegmentedControl, selectedSegmentIndex: Int) {
        delegate?.settingsSegmentedCellDidChange(selectedSegmentIndex: selectedSegmentIndex,
                                                 atIndexPath: indexPath)
    }
}
