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
import SwiftyUserDefaults
import GroundSdk

private extension ULogTag {
    static let tag = ULogTag(name: "SettingsQuickCollectionViewCell")
}

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
    @IBOutlet private weak var settingTitle: UILabel!

    // MARK: - Internal Properties
    weak var delegate: SettingsQuickCollectionViewCellDelegate?

    // MARK: - Private Properties
    private var indexPath: IndexPath?
    private var selectedItem: Int = 0
    private var animationImage = UIImageView()
    private var nextImage: UIImage?
    private var previousImage: UIImage?
    private var isEnabled: Bool = false
    private weak var settingEntry: SettingEntry?

    // MARK: - Override Funcs
    override func prepareForReuse() {
        super.prepareForReuse()
        resetCellContent()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        initView()
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
        isEnabled = settingEntry.isEnabled
        let selectedIndex = segmentModel.selectedIndex
        selectedItem = selectedIndex

        settingImage.image = segmentModel.segments.elementAt(index: selectedIndex)?.image
        if segmentModel.isBoolean {
            settingTitle.accessibilityValue = selectedIndex == 0 ? "Off" : "On"
            let textColor = (selectedIndex == 0) ? ColorName.defaultTextColor : ColorName.defaultTextColor
            settingTitle.text = settingEntry.title
            contentView.backgroundColor = (selectedIndex == 0) ? ColorName.whiteAlbescent.color : ColorName.white.color
            settingImage.tintColor = textColor.color
        } else {
            var title = segmentModel.segments.elementAt(index: selectedIndex)?.title ?? Style.dash
            if let cellTitle = settingEntry.title {
                title = "\(cellTitle) : " + title
            }
            settingTitle.text = title
            contentView.backgroundColor = ColorName.white.color
            settingImage.tintColor = ColorName.defaultTextColor.color
        }

        nextImage = segmentModel.segments.elementAt(index: segmentModel.nextIndex)?.image
        previousImage = segmentModel.segments.elementAt(index: segmentModel.previousIndex)?.image
    }
}

// MARK: - DELEGATE
// MARK: - Private Funcs
private extension SettingsQuickCollectionViewCell {
    /// Inits view.
    func initView() {
        animationImage.frame = settingImage.frame
        addSubview(animationImage)
        resetCellContent()
        cornerRadiusedWith(backgroundColor: ColorName.whiteAlbescent.color,
                           borderColor: .clear,
                           radius: Style.largeCornerRadius,
                           borderWidth: Style.noBorderWidth)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tapRecognizer)
    }

    /// Reset cell content.
    func resetCellContent() {
        settingTitle.text = ""
        settingImage.image = nil
        isEnabled = false
    }

    /// Called when cell is tapped.
    @objc func didTap(sender: UISwipeGestureRecognizer) {
        if let model = settingEntry?.segmentModel {
            guard let entry = settingEntry else { return }

            if let logItem = settingEntry?.itemLogKey {
                LogEvent.log(.button(item: logItem,
                                     value: LogEvent.formatNewValue(settingEntry: entry,
                                                                    index: model.nextIndex)))
            }
        }

        guard isEnabled else {
            ULog.e(.tag, "settings button is disabled : \(settingEntry?.title ?? "unknown")")
            return
        }
        changeItem()
    }

    func changeItem() {
        guard let indexPath = indexPath else { return }
        delegate?.settingsQuickCelldidTap(indexPath: indexPath)
    }
}
