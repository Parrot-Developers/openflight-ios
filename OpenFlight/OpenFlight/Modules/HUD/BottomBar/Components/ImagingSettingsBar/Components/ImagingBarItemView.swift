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

/// Item displaying a setting inside imaging bar.

final class ImagingBarItemView: UIControl, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var itemImageView: UIImageView!
    @IBOutlet private weak var itemLabel: UILabel!

    // MARK: - Internal Properties
    var model: ImagingBarState? {
        didSet {
            fill()
        }
    }
    /// Corners to round when view is selected.
    var roundedCorners: UIRectCorner? {
        didSet {
            updateCorners()
        }
    }

    /// Background color to use when the view is selected.
    var selectedBackgroundColor: UIColor = ColorName.highlightColor.color {
        didSet {
            updateColors()
        }
    }

    /// Background color to use when the view is not selected.
    var unselectedBackgroundColor: UIColor = .white {
        didSet {
            updateColors()
        }
    }

    /// Text color to use when the view is selected.
    var selectedTextColor: UIColor = .white {
        didSet {
            updateColors()
        }
    }

    /// Text color to use when the view is not selected.
    var unselectedTextColor: UIColor = ColorName.defaultTextColor.color {
        didSet {
            updateColors()
        }
    }

    // MARK: - Override Properties
    override var isHighlighted: Bool {
        didSet {
            self.alpha = isHighlighted ? 0.7 : 1.0
        }
    }

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInitImagingBarItemView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInitImagingBarItemView()
    }
}

// MARK: - Private Funcs
private extension ImagingBarItemView {
    /// Common init.
    func commonInitImagingBarItemView() {
        loadNibContent()
        itemLabel.makeUp(with: .current, color: .defaultTextColor)
    }

    /// Updates the view with its current model.
    func fill() {
        guard let model = model else {
            return
        }
        isUserInteractionEnabled = model.enabled
        alphaWithEnabledState(model.enabled)
        itemImageView.image = model.mode?.image ?? model.image
        itemImageView.isHidden = model.mode?.image == nil && model.image == nil
        // Special case for white balance.
        if let mode = model.mode as? Camera2WhiteBalanceMode,
            let subMode = model.subMode as? Camera2WhiteBalanceTemperature {
            itemLabel.text = mode.altTitle ?? subMode.altTitle
            if mode.altTitle == nil {
                itemImageView.isHidden = true
            }
        } else if let mode = model.mode as? PhotoFormatMode {
            // Hides image for Photo format on bar level one
            itemLabel.text = mode.title
            itemImageView.isHidden = true
        } else {
            itemLabel.text = model.mode?.title ?? model.title
        }

        updateCorners()
        updateColors()
    }

    func updateColors() {
        guard let model = model else {
            return
        }
        backgroundColor = model.isSelected.value ? selectedBackgroundColor : unselectedBackgroundColor
        let color = model.isSelected.value ? selectedTextColor : unselectedTextColor
        itemLabel.textColor = color
        itemImageView.tintColor = color
    }

    func updateCorners() {
        if let roundedCorners = roundedCorners {
            customCornered(corners: roundedCorners, radius: Style.mediumCornerRadius)
        }
    }
}
