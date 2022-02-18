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

/// Custom view used in HUD bottom bar used to display modes.

public class BarButtonView: UIControl, NibOwnerLoadable {

    // MARK: - Outlets
    @IBOutlet private weak var title: UILabel! {
        didSet {
            title.makeUp(with: .caps, color: .defaultTextColor)
        }
    }
    @IBOutlet public weak var currentMode: UILabel! {
        didSet {
            currentMode.makeUp(with: .current, color: .defaultTextColor)
        }
    }
    @IBOutlet private weak var subTitle: UILabel! {
        didSet {
            subTitle.makeUp(and: .defaultTextColor)
        }
    }
    @IBOutlet private weak var modeView: UIView!
    @IBOutlet private weak var imageView: UIImageView!

    // MARK: - Internal Properties
    public var model: BarButtonState! {
        didSet {
            fill(with: model)
        }
    }

    /// Corners to round when view is selected.
    var roundedCorners: UIRectCorner = [.allCorners]

    // MARK: - Init
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        customInitBarButtonView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        customInitBarButtonView()
    }

    // MARK: - Override Properties
    open override var isEnabled: Bool {
        didSet {
            guard model != nil else { return }
            updateIcon()
            updateTextColor()
            updateBackgroundColor()
            updateModeView(with: model)
        }
    }

    // MARK: - Override Funcs
    open override var isSelected: Bool {
        didSet {
            updateBackgroundColor()
        }
    }
}

// MARK: - Private Funcs
private extension BarButtonView {
    /// Common init.
    func customInitBarButtonView() {
        loadNibContent()
    }

    /// Fills the UI elements of the view with given model.
    ///
    /// - Parameters:
    ///    - model: model representing the contents
    func fill(with viewModel: BarButtonState) {
        title.text = viewModel.title
        currentMode.text = viewModel.subtext
        subTitle.text = viewModel.subtitle
        updateModeView(with: viewModel)
        updateAlpha()
        updateIcon()
        updateTextColor()
        updateBackgroundColor()
        isUserInteractionEnabled = viewModel.enabled && !viewModel.singleMode
    }

    func updateAlpha() {
        let alpha: CGFloat = model.enabled ? 1 : 0.5
        title.alpha = alpha / 2
        currentMode.alpha = alpha
        subTitle.alpha = alpha
        imageView.alpha = alpha
    }

    func updateIcon() {
        imageView.image = model.subMode?.image ?? model.image
        imageView.isHidden = model.image == nil
        imageView.tintColor = isEnabled
                                ? model.isSelected.value
                                    ? .white
                                    : ColorName.defaultTextColor.color
                                : ColorName.disabledTextColor2.color
    }

    func updateTextColor() {
        let textColor = isEnabled
                        ? model.isSelected.value
                            ? .white
                            :ColorName.defaultTextColor.color
                        : ColorName.disabledTextColor2.color

        title.textColor = textColor
        currentMode.textColor = textColor
        subTitle.textColor = textColor
    }

    func updateBackgroundColor() {
        let backgroundColor = isEnabled
                                ? model.isSelected.value
                                    ? ColorName.highlightColor.color
                                    : ColorName.white90.color
                                : ColorName.disabledBgcolor.color

        customCornered(corners: roundedCorners,
                       radius: Style.largeCornerRadius,
                       backgroundColor: backgroundColor,
                       borderColor: .clear,
                       borderWidth: Style.noBorderWidth)
    }

    func updateModeView(with model: BarButtonState) {
        modeView.isHidden = !isEnabled
        || model.singleMode
        || (model.title?.isEmpty == true
            && model.subtext?.isEmpty == true
            && model.subtitle?.isEmpty == true)
    }
}
