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

/// Model for `MissionItemCell`
public class MissionItemCellModel {
    let title: String
    let image: UIImage
    var isSelected: Bool
    let isSelectable: Bool
    let provider: MissionProvider

    init(title: String,
         image: UIImage,
         isSelected: Bool,
         isSelectable: Bool,
         provider: MissionProvider) {
        self.title = title
        self.image = image
        self.isSelected = isSelected
        self.isSelectable = isSelectable
        self.provider = provider
    }
}

/// TableView Cell to display a mission in launcher list.
final class MissionItemCell: MainTableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var missionLabel: UILabel! {
        didSet {
            missionLabel.makeUp()
        }
    }
    @IBOutlet private weak var missionImage: UIImageView!
    @IBOutlet private weak var customBackgroundView: UIView! {
        didSet {
            customBackgroundView.cornerRadiusedWith(backgroundColor: ColorName.white20.color,
                                                    borderColor: .clear,
                                                    radius: Style.largeCornerRadius)
        }
    }

    // MARK: - Init
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }

    // MARK: - Internal Funcs

    /// Setup cell UI with given model.
    ///
    /// - Parameters:
    ///     - model: model for mission launcher
    func setup(with model: MissionItemCellModel) {
        screenBorders = [.left] // Cell snaps to device's left border.
        missionLabel?.text = model.title
        missionLabel?.font = FontStyle.current.font(isRegularSizeClass)
        missionImage?.image = model.image
        let bgColor = model.isSelectable
                        ? model.isSelected ? ColorName.highlightColor.color : ColorName.white90.color
                        : ColorName.whiteAlbescent.color
        let textColor = model.isSelectable
                        ? model.isSelected ? .white : ColorName.defaultTextColor.color
                        : ColorName.defaultTextColor80.color
        customBackgroundView.backgroundColor = bgColor
        missionLabel?.accessibilityTraits.insert(.staticText)
        missionLabel?.accessibilityTraits.insert(model.isSelectable ? .selected : .notEnabled)
        missionLabel?.accessibilityTraits.remove(model.isSelectable ? .notEnabled : .selected)
        missionLabel?.textColor = textColor
        missionImage?.tintColor = textColor
        let opacity = model.isSelectable ? 1 : 0.5
        missionLabel.alpha = opacity
        missionImage.alpha = opacity
        customBackgroundView.alpha = opacity
    }
}
