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

/// An empty view with a flexible width (useful in stackViews).
class HSpacerView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear
        widthAnchor.constraint(greaterThanOrEqualToConstant: 0).isActive = true
    }
}

/// An empty view with a flexible height (useful in stackViews).
class VSpacerView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear
        heightAnchor.constraint(greaterThanOrEqualToConstant: 0).isActive = true
    }
}

/// A view with linear bottom to top gradient of defaultBgcolor
public class BottomGradientView: UIView {

    private enum Constants {
        static let fullGradientStartPoint = CGPoint(x: 0.5, y: 1)
        static let mediumGradientStartPoint = CGPoint(x: 0.5, y: 0.5)
        static let shortGradientStartPoint = CGPoint(x: 0.5, y: 0.25)
        static let endPoint = CGPoint(x: 0.5, y: 0)
    }

    private var gradient: CAGradientLayer?

    public override var frame: CGRect {
        didSet {
            gradient?.frame = bounds
        }
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradient?.frame = bounds
    }

    // MARK: - Setup UI
    private func setupView() {
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        let color = ColorName.defaultBgcolor.color
        gradient.colors = [color, color.withAlphaComponent(0)]
            .map { $0.cgColor }
        gradient.startPoint = Constants.fullGradientStartPoint
        gradient.endPoint = Constants.endPoint
        layer.insertSublayer(gradient, at: 0)
        self.gradient = gradient
    }

    // MARK: - Public functions
    /// Draws a gradient from the bottom to the top.
    public func fullGradient() {
        gradient?.startPoint = Constants.fullGradientStartPoint
    }
    /// Draws a gradient from the middle to the top.
    public func mediumGradient() {
        gradient?.startPoint = Constants.mediumGradientStartPoint
    }
    /// Draws a 25% view's size gradient on the top.
    public func shortGradient() {
        gradient?.startPoint = Constants.shortGradientStartPoint
    }
}

/// A tile UIView with default background, corners and shadow parameters.
public class MainTileView: UIView {
    public var cornerRadius: CGFloat = Style.largeCornerRadius {
        didSet { updateCornerRadius() }
    }

    public var hasShadow: Bool = true {
        didSet { updateShadow() }
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }

    // MARK: - Private
    private func setupView() {
        backgroundColor = .white
        clipsToBounds = false
        updateCornerRadius()
        updateShadow()
    }

    /// Updates the cornerRadius of the view.
    private func updateCornerRadius() {
        layer.cornerRadius = cornerRadius
    }

    /// Updates the shadow of the view.
    private func updateShadow() {
        addShadow(condition: hasShadow)
    }
}

/// A generic `HighlightableUIControl` with default background, corners and shadow parameters.
public class ActionControl: HighlightableUIControl {
    public var cornerRadius: CGFloat = Style.largeCornerRadius {
        didSet { updateCornerRadius() }
    }

    public var hasShadow: Bool = true {
        didSet { updateShadow() }
    }

    // Overriden Properties
    public override var isEnabled: Bool {
        didSet { updateEnabledState() }
    }
    public override var intrinsicContentSize: CGSize {
        .init(width: super.intrinsicContentSize.width,
              height: Layout.buttonIntrinsicHeight(isRegularSizeClass))
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }

    // MARK: - Private
    private func setupView() {
        backgroundColor = .white
        clipsToBounds = false
        updateCornerRadius()
        updateShadow()
    }

    /// Updates the cornerRadius of the control.
    private func updateCornerRadius() {
        layer.cornerRadius = cornerRadius
    }

    /// Updates the shadow of the control.
    private func updateShadow() {
        addShadow(condition: isEnabled && hasShadow)
    }

    /// Updates the enabled state of the control.
    private func updateEnabledState() {
        UIView.animate(withDuration: Style.shortAnimationDuration) {
            self.updateShadow()
            self.alphaWithEnabledState(self.isEnabled)
        }
    }
}
