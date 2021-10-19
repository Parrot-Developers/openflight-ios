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

/// A style for the gallery media title view.
enum GalleryMediaTitleStyle {
    case dark, light
}

/// A view for a gallery media title.
class GalleryMediaTitleView: UIView, NibOwnerLoadable {
    /// The view model.
    var model: GalleryMedia? {
        didSet {
            update(with: model)
        }
    }
    /// The view style.
    var style: GalleryMediaTitleStyle = .dark {
        didSet {
            updateStyle()
        }
    }

    // MARK: - Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    // MARK: - Convenience Computed Properties
    private var titleColorName: ColorName {
        switch style {
        case .dark: return .defaultTextColor
        case .light: return .white
        }
    }
    private var subtitleColorName: ColorName {
        switch style {
        case .dark: return .disabledTextColor
        case .light: return .white
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

private extension GalleryMediaTitleView {
    /// Basic init.
    func commonInit() {
        loadNibContent()

        updateStyle()
        updateSubtitleVisibility()
    }

    func updateStyle() {
        imageView.tintColor = titleColorName.color
        titleLabel.makeUp(with: .large, and: titleColorName)
        subtitleLabel.makeUp(with: .regular, and: subtitleColorName)
    }

    /// Update the UI for a specific view model.
    ///
    /// - Parameters:
    ///    - model: model for the view.
    func update(with model: GalleryMedia?) {
        imageView.image = model?.type.filterImage
        titleLabel.text = model?.displayTitle
        model?.mainMediaItem?.locationDetail { [weak self] locationDetail in
            self?.subtitleLabel.text = locationDetail

            UIView.animate(withDuration: Style.shortAnimationDuration, delay: 0, options: .curveEaseOut) {
                self?.updateSubtitleVisibility()
            }
        }
    }

    func updateSubtitleVisibility() {
        let isSubtitleLabelHidden = subtitleLabel.text?.isEmpty ?? true
        subtitleLabel.isHidden = isSubtitleLabelHidden
        subtitleLabel.alphaHidden(isSubtitleLabelHidden)
    }
}
