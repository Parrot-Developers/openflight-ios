//    Copyright (C) 2022 Parrot Drones SAS
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

/// An info banner view model for gerenal purpose info views.
struct MainBannerInfoViewModel {
    /// The banner icon.
    var icon: UIImage?
    /// The icon tint color.
    var iconTintColor: UIColor?
    /// The banner title.
    var title: String?
    /// The title color.
    var titleColor: UIColor?
    /// The title font.
    var titleFont: UIFont?
    /// The banner background color.
    var backgroundColor: UIColor?
    /// The banner padding (for inner padding and icon/title spacing).
    var padding: CGFloat?
    /// The banner corner radius.
    var cornerRadius: CGFloat?
}

/// An info banner view.
class MainBannerInfoView: UIView, NibOwnerLoadable {

    // MARK: - Outlets
    @IBOutlet private weak var stackView: BackgroundStackView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!

    // MARK: - Internal Properties
    var model: MainBannerInfoViewModel? {
        didSet {
            fill()
        }
    }

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
}

// MARK: - Private Funcs
private extension MainBannerInfoView {
    /// Inits view.
    func commonInit() {
        loadNibContent()
        backgroundColor = .clear
        stackView.isLayoutMarginsRelativeArrangement = true
    }

    /// Fills view according to VM.
    func fill() {
        guard let model = model else { return }
        let color = model.titleColor ?? .white
        imageView.image = model.icon
        imageView.tintColor = model.iconTintColor ?? color
        imageView.isHidden = model.icon == nil
        titleLabel.text = model.title
        titleLabel.textColor = color
        titleLabel.font = model.titleFont ?? FontStyle.readingText.font(isRegularSizeClass)
        stackView.backgroundColor = model.backgroundColor

        let padding = model.padding ?? Layout.mainSpacing(isRegularSizeClass)
        stackView.spacing = padding
        stackView.directionalLayoutMargins = .init(top: padding, leading: padding, bottom: padding, trailing: padding)
        applyCornerRadius(model.cornerRadius ?? Style.largeCornerRadius)
    }
}
