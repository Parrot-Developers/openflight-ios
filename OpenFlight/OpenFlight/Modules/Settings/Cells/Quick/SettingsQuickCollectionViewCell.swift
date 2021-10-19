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
import SwiftyUserDefaults
import GroundSdk

// MARK: - Protocols
protocol SettingsQuickCollectionViewCellDelegate: AnyObject {
    /// Called when user did tap on a cell.
    ///
    /// - Parameters:
    ///     - indexPath: index path of the cell
    func settingsQuickCelldidTap(indexPath: IndexPath)
}

/// Settings Quick Collection View Cell.
final class SettingsQuickCollectionViewCell: UICollectionViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var settingImage: UIImageView!
    @IBOutlet private weak var pageControl: UIPageControl! {
        didSet {
            pageControl.isUserInteractionEnabled = false
            if #available(iOS 14.0, *) {
                pageControl.backgroundStyle = .minimal
            }
        }
    }
    @IBOutlet private weak var settingTitle: UILabel!

    // MARK: - Internal Properties
    weak var delegate: SettingsQuickCollectionViewCellDelegate?

    // MARK: - Private Properties
    private var indexPath: IndexPath?
    private var selectedItem: Int = 0
    private var isSwipeAllowed: Bool = false
    private var animationImage = UIImageView()
    private var nextImage: UIImage?
    private var previousImage: UIImage?
    private var isEnabled: Bool = false
    private weak var settingEntry: SettingEntry?

    // MARK: - Private Enums
    private enum Constants {
         static let animationDuration: TimeInterval = 0.2
    }

    // MARK: - Override Funcs
    override func prepareForReuse() {
        super.prepareForReuse()
        self.resetCellContent()
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        self.animationImage.frame = self.settingImage.frame
        self.addSubview(animationImage)
        self.resetCellContent()
        self.cornerRadiusedWith(backgroundColor: ColorName.whiteAlbescent.color,
                                borderColor: .clear,
                                radius: Style.largeCornerRadius,
                                borderWidth: Style.noBorderWidth)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap))
        self.addGestureRecognizer(tapRecognizer)
    }

    // MARK: - Internal Funcs
    /// Configure cell.
    ///
    /// - Parameters:
    ///    - settingEntry: cell setting entry.
    ///    - indexPath: index path
    ///    - delegate: Settings Segmented Cell Delegate
    func configureCell(settingEntry: SettingEntry, atIndexPath indexPath: IndexPath, delegate: SettingsQuickCollectionViewCellDelegate) {
        guard let segmentModel = settingEntry.segmentModel else { return }

        self.settingEntry = settingEntry
        self.delegate = delegate
        self.indexPath = indexPath
        self.isEnabled = settingEntry.isEnabled
        let selectedIndex = segmentModel.selectedIndex
        self.selectedItem = selectedIndex
        self.pageControl.isHidden = segmentModel.isBoolean

        self.settingImage.image = segmentModel.segments.elementAt(index: selectedIndex)?.image

        if segmentModel.isBoolean {
            let textColor = (selectedIndex == 0) ? ColorName.defaultTextColor : ColorName.defaultTextColor
            self.settingTitle.text = settingEntry.title
            self.contentView.backgroundColor = (selectedIndex == 0) ? ColorName.whiteAlbescent.color : ColorName.white.color
            self.settingImage.tintColor = textColor.color
            settingTitle.makeUp(and: textColor)
        } else {
            var title = segmentModel.segments.elementAt(index: selectedIndex)?.title ?? Style.dash
            if let cellTitle = settingEntry.title {
                title = "\(cellTitle) : " + title
            }
            self.settingTitle.text = title
            self.contentView.backgroundColor = ColorName.white.color
            self.settingImage.tintColor = ColorName.defaultTextColor.color
            self.pageControl.numberOfPages = segmentModel.segments.count
            self.pageControl.currentPage = selectedIndex
        }

        self.isSwipeAllowed = !segmentModel.isBoolean

        nextImage = segmentModel.segments.elementAt(index: segmentModel.nextIndex)?.image
        previousImage = segmentModel.segments.elementAt(index: segmentModel.previousIndex)?.image
    }
}

// MARK: - DELEGATE
// MARK: - Private Funcs
private extension SettingsQuickCollectionViewCell {
    /// Reset cell content.
    func resetCellContent() {
        self.settingTitle.text = ""
        self.settingImage.image = nil
        self.isEnabled = false
    }

    /// Called when cell is tapped.
    @objc func didTap(sender: UISwipeGestureRecognizer) {
        if let model = settingEntry?.segmentModel {
            guard let entry = settingEntry else { return }

            LogEvent.logAppEvent(itemName: settingEntry?.itemLogKey,
                                 newValue: LogEvent.formatNewValue(settingEntry: entry,
                                                                   index: model.nextIndex),
                                 logType: LogEvent.LogType.button)
        }

        guard isEnabled else { return }
        changeItem()
    }

    func changeItem() {
        guard let indexPath = self.indexPath else { return }
        self.delegate?.settingsQuickCelldidTap(indexPath: indexPath)
    }
}
