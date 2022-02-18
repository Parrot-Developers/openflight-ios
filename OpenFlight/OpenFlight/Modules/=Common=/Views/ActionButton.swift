//    Copyright (C) 2021 Parrot Drones SAS
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

/// A generic action button with a configurable style defined by its model `ActionButtonModel`.
public class ActionButton: UIButton {
    public var model: ActionButtonModel? {
        didSet { updateLayout() }
    }

    // Overriden Properties
    public override var isEnabled: Bool {
        didSet { updateEnabledState() }
    }
    public override var intrinsicContentSize: CGSize {
        .init(width: super.intrinsicContentSize.width,
              height: Layout.buttonIntrinsicHeight(isRegularSizeClass))
    }

    // Constants
    private enum Constants {
        static let contentPadding: CGFloat = 10
        static let imageTitlePadding: CGFloat = 10
        static let contentEdgeInsets = UIEdgeInsets(top: Constants.contentPadding,
                                                    left: Constants.contentPadding,
                                                    bottom: Constants.contentPadding,
                                                    right: Constants.contentPadding)
    }

    // MARK: - Convenience Setup Functions

    /// Configures button's model with image and style parameters.
    /// Model can be directly configured by caller if a finer configuration level is required.
    ///
    /// - Parameters:
    ///    - image: The image of the button.
    ///    - style: The style of the button.
    public func setup(image: UIImage,
                      style: ActionButtonStyle) {
        var newModel = model ?? ActionButtonModel()
        newModel.image = image
        newModel.updateWithStyle(style)
        model = newModel
    }

    /// Configures button's model with title and style parameters.
    /// Model can be directly configured by caller if a finer configuration level is required.
    ///
    /// - Parameters:
    ///    - title: The title of the button.
    ///    - style: The style of the button.
    public func setup(title: String,
                      style: ActionButtonStyle) {
        model = ActionButtonModel(title: title, style: style)
    }

    /// Configures button's model with title, image and style parameters.
    /// Model can be directly configured by caller if a finer configuration level is required.
    ///
    /// - Parameters:
    ///    - title: The title of the button.
    ///    - image: The image of the button.
    ///    - style: The style of the button.
    public func setup(title: String,
                      image: UIImage,
                      style: ActionButtonStyle) {
        model = ActionButtonModel(image: image, title: title, style: style)
    }

    /// Configures button's model with most commonly used parameters.
    /// Model can be directly configured by caller if a finer configuration level is required.
    ///
    /// - Parameters:
    ///    - image: The image of the button.
    ///    - title: The title of the button.
    ///    - style: The style of the button.
    ///    - alignment: The content alignement of the button.
    func setup(image: UIImage? = nil,
               title: String? = nil,
               style: ActionButtonStyle,
               alignment: UIControl.ContentHorizontalAlignment = .center) {
        model = ActionButtonModel(image: image,
                                  title: title,
                                  contentHorizontalAlignment: alignment,
                                  style: style)
    }

    /// Updates button's image.
    ///
    /// - Parameters:
    ///    - image: The image of the button.
    func updateImage(_ image: UIImage?) {
        model?.image = image
    }

    /// Updates button's title.
    ///
    /// - Parameters:
    ///    - title: The title of the button.
    func updateTitle(_ title: String?) {
        model?.title = title
    }

    /// Updates button's style.
    ///
    /// - Parameters:
    ///    - style: The style of the button.
    func updateStyle(_ style: ActionButtonStyle) {
        model?.updateWithStyle(style)
        updateLayout()
    }
}

// MARK: - Private Layout Configuration
private extension ActionButton {
    /// Updates the button's layout according to its model.
    func updateLayout() {
        layer.borderWidth = 1
        layer.cornerRadius = Style.largeCornerRadius

        updateTitleLayout()
        updateColors()
        updateShadow()
    }

    /// Updates the title elements of the button (including image and text).
    func updateTitleLayout() {
        guard let model = model else { return }

        setInsets(contentEdgeInsets: Constants.contentEdgeInsets,
                  imageTitlePadding: model.image != nil && !(model.title?.isEmpty ?? true) ? Constants.imageTitlePadding : 0)
        tintColor = model.tintColor
        setTitleColor(model.tintColor, for: .normal)
        setImage(model.image, for: .normal)
        setTitle(model.title, for: .normal)
        titleLabel?.textAlignment = model.labelHorizontalAlignment ?? model.defaultLabelHorizontalAlignment
        titleLabel?.font = model.fontStyle.font(isRegularSizeClass, monospacedDigits: model.isMonospacedDigitsFont)
        titleLabel?.lineBreakMode = .byWordWrapping
        contentHorizontalAlignment = model.contentHorizontalAlignment
    }

    /// Updates the colors of the button.
    func updateColors() {
        guard let model = model else { return }
        backgroundColor = model.backgroundColor
        layer.borderColor = model.borderColor.cgColor
    }

    /// Updates the shadow of the button.
    func updateShadow() {
        addShadow(condition: isEnabled && model?.hasShadow ?? false)
    }

    /// Updates the enabled state of the button.
    func updateEnabledState() {
        updateShadow()
        alphaWithEnabledState(self.isEnabled)
    }
}
