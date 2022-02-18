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

// MARK: - Internal Structs
/// Model for `DeviceDetailsButtonView`.
struct DeviceDetailsButtonModel {
    var mainImage: UIImage?
    var title: String?
    var subImage: UIImage?
    var subtitle: String?
    var backgroundColor: ColorName?
    var mainImageTintColor: ColorName?
    var subimageTintColor: ColorName?
    var titleColor: ColorName?
    var subtitleColor: ColorName?

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - mainImage: button's main image
    ///    - title: button's title
    ///    - subImage: button's subtitle image
    ///    - subtitle: button's subtitle
    ///    - backgroundColor: button's background color
    ///    - mainImageTintColor: button's main image tint color
    ///    - titleColor: title's text color
    ///    - subtitleColor: subtitle's text color
    ///    - subimageTintColor: button's subtitle image tint color
    init(mainImage: UIImage?,
         title: String?,
         subImage: UIImage? = nil,
         subtitle: String? = Style.dash,
         backgroundColor: ColorName = .white,
         mainImageTintColor: ColorName = .defaultTextColor,
         titleColor: ColorName = .defaultTextColor,
         subtitleColor: ColorName = .defaultTextColor80,
         subimageTintColor: ColorName = .highlightColor
    ) {
        self.mainImage = mainImage
        self.title = title
        self.subImage = subImage
        self.subtitle = subtitle
        self.backgroundColor = backgroundColor
        self.mainImageTintColor = mainImageTintColor
        self.titleColor = titleColor
        self.subtitleColor = subtitleColor
        self.subimageTintColor = subimageTintColor
    }
}

/// Displays a custom button for drone or remote details.
final class DeviceDetailsButtonView: ActionControl, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var mainImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subImageView: UIImageView!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var subStackView: UIStackView!

    // MARK: - Internal Properties
    /// Device button Model which update the view.
    var model: DeviceDetailsButtonModel? {
        didSet {
            fill()
        }
    }

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.commonInitDeviceDetailsButtonView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.commonInitDeviceDetailsButtonView()
    }
}

// MARK: - Private Funcs
private extension DeviceDetailsButtonView {
    /// Common init.
    func commonInitDeviceDetailsButtonView() {
        self.loadNibContent()
    }

    /// Fills up the view with current model.
    func fill() {
        mainImageView.image = model?.mainImage
        mainImageView.layer.cornerRadius = Style.largeCornerRadius
        mainImageView.tintColor = model?.mainImageTintColor?.color
        titleLabel.text = model?.title
        subImageView.image = model?.subImage
        subImageView.tintColor = model?.subimageTintColor?.color
        subtitleLabel.text = model?.subtitle
        subStackView.isHidden = model?.subtitle == nil
        subImageView.isHidden = model?.subImage == nil
        titleLabel.textColor = model?.titleColor?.color
        subtitleLabel.textColor = model?.subtitleColor?.color
        backgroundColor = model?.backgroundColor?.color
    }
}
