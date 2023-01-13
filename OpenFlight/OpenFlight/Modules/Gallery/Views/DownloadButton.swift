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

/// Dedicated Button with download style.

final class DownloadButton: HighlightableUIControl, NibOwnerLoadable {
    var model: DownloadButtonModel? {
        didSet {
            updateLayout()
        }
    }

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.commonInit()
    }
}

// MARK: - Private Funcs
private extension DownloadButton {
    func commonInit() {
        loadNibContent()

        titleLabel.makeUp()
        updateLayout()
    }

    func updateLayout() {
        isHidden = model == nil

        guard let model = model else { return }

        isUserInteractionEnabled = model.isUserInteractionEnabled
        backgroundColor = model.backgroundColor
        layer.cornerRadius = Style.mediumCornerRadius

        let state = model.state
        imageView.image = state.icon
        imageView.alphaWithEnabledState(model.isIconEnabled)
        imageView.tintColor = state.tintColor

        let title = state.title(model.title)
        titleLabel.text = title
        titleLabel.isHiddenInStackView = title == nil
        titleLabel.textColor = state.tintColor

        if state == .downloading || state == .deleting {
            imageView?.startRotate()
        } else {
            imageView?.stopRotate()
        }
    }
}

/// A model for generic download buttons.
class DownloadButtonModel {
    /// The title of the button.
    var title: String?
    /// The download state of the button.
    var state: GalleryMediaActionState
    /// Whether the button action is available.
    var isActionAvailable: Bool

    init(title: String? = nil,
         state: GalleryMediaActionState,
         isAvailable: Bool = true) {
        self.title = title
        self.state = state
        self.isActionAvailable = isAvailable
    }

    /// Whether button's user interaction is enabled according to its state and availability.
    var isUserInteractionEnabled: Bool {
        state.isUserInteractionEnabled(isAvailable: isActionAvailable)
    }

    /// The button's background color according to its state and availability.
    var backgroundColor: UIColor {
        state.backgroundColor(isAvailable: isActionAvailable)
    }

    /// Whether button's icon is enabled according to its state and availability.
    var isIconEnabled: Bool {
        state.isIconEnabled(isAvailable: isActionAvailable)
    }
}
