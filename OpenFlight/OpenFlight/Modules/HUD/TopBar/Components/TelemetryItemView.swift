// Copyright (C) 2020 Parrot Drones SAS
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

/// Model representing the contents of a TelemetryItemView.
struct TelemetryItemModel {
    /// Image representing the displayed metric.
    var image: UIImage?
    /// Label displaying the value of the metric.
    var label: String
    /// Background color of the item (used for warnings/alerts display).
    var backgroundColor: UIColor
}

/// View displaying a specific metric inside TelemetryBar.

final class TelemetryItemView: HighlightableUIControl, NibOwnerLoadable {

    // MARK: - Outlets
    @IBOutlet private weak var itemImageView: UIImageView!
    @IBOutlet private weak var itemLabel: UILabel!
    @IBOutlet private weak var alertBackgroundView: UIView! {
        didSet {
            alertBackgroundView.applyCornerRadius(Style.mediumCornerRadius)
        }
    }

    // MARK: - Internal Properties
    var model: TelemetryItemModel? {
        didSet {
            fill(with: model)
        }
    }

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadNibContent()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
    }
}

// MARK: - Private Funcs
private extension TelemetryItemView {
    /// Fills the UI elements of the view with given model
    ///
    /// - Parameters:
    ///    - viewModel: model representing the contents
    func fill(with model: TelemetryItemModel?) {
        let valueFont: UIFont = ParrotFontStyle.regular.font
        let unitFont: UIFont = ParrotFontStyle.tiny.font

        let attributedString = NSMutableAttributedString(string: model?.label ?? Style.dash)
        attributedString.valueUnitFormatted(valueFont: valueFont, unitFont: unitFont)
        itemLabel.attributedText = attributedString
        itemImageView.image = model?.image
        alertBackgroundView.backgroundColor = model?.backgroundColor
    }
}
