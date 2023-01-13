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

import UIKit

/// A UIStackView with a default spacing value defined by `Layout.mainSpacing`.
public class MainStackView: PassThroughBasicStackView {
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }

    // MARK: - Layout Configuration
    func setupView() {
        spacing = Layout.mainSpacing(isRegularSizeClass)
    }
}

/// A `MainStackView` with an additional backgroundView, useful for iOS 13.
public class BackgroundStackView: MainStackView {
    /// The stackView background color.
    public override var backgroundColor: UIColor? {
        willSet { updateBackgroundColor(newValue) }
    }

    /// The stackView corner radius.
    public var cornerRadius: CGFloat? {
        didSet { updateCornerRadius(cornerRadius ?? 0) }
    }

    // MARK: - Private Properties
    /// The backgroundView (stackView's background color only supported from iOS 14).
    private var backgroundView = UIView()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }

    // MARK: - Layout Configuration
    override func setupView() {
        super.setupView()
        addBackgroundView()
    }

    private func addBackgroundView() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(backgroundView, at: 0)
        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundView.topAnchor.constraint(equalTo: topAnchor)
        ])
        backgroundColor = .clear
    }

    private func updateBackgroundColor(_ color: UIColor?) {
        backgroundView.backgroundColor = color
    }

    private func updateCornerRadius(_ cornerRadius: CGFloat) {
        backgroundView.layer.cornerRadius = cornerRadius
        layer.cornerRadius = cornerRadius
    }
}

/// A general-purpose UIStackView container adjusting its margins according to its internal properties.
public class SubContainerStackView: MainStackView {
    /// The stackView margin borders that are enabled. Disabled borders have a margin set to 0.
    public var enabledMargins: [NSLayoutConstraint.Attribute] = [.left, .top, .right, .bottom] {
        didSet { updateMargins() }
    }
    /// The margins values.
    public var margins: NSDirectionalEdgeInsets = .zero {
        didSet { updateMargins() }
    }

    override func setupView() {
        super.setupView()

        insetsLayoutMarginsFromSafeArea = false
        isLayoutMarginsRelativeArrangement = true
        margins = Layout.mainContainerInnerMargins(isRegularSizeClass, screenBorders: [])
    }

    private func updateMargins() {
        directionalLayoutMargins = .init(top: enabledMargins.contains(.top) ? margins.top : 0,
                                         leading: enabledMargins.contains(.left) ? margins.leading : 0,
                                         bottom: enabledMargins.contains(.bottom) ? margins.bottom : 0,
                                         trailing: enabledMargins.contains(.right) ? margins.trailing : 0)
    }
}

/// A general-purpose UIStackView container adjusting its margins according to the screen borders.
public class MainContainerStackView: SubContainerStackView {
    /// The stackView borders that are connected to the device's screen. Used to correctly handle safe area offsets if needed.
    public var screenBorders: [NSLayoutConstraint.Attribute] = [.left, .top, .right, .bottom] {
        didSet { updateMargins() }
    }
    /// The left padding configuration:
    ///   - Minimal if `true` (left border snaps to safe are space as defined in `Layout`).
    ///   - Regular if `false` (adds default margin as defined in `Layout`).
    var hasMinLeftPadding = false {
        didSet { updateMargins() }
    }

    // MARK: - Layout Configuration
    override func setupView() {
        super.setupView()
        updateMargins()
    }

    private func updateMargins() {
        margins = Layout.mainContainerInnerMargins(isRegularSizeClass,
                                                   screenBorders: screenBorders,
                                                   hasMinLeftPadding: hasMinLeftPadding)
    }
}

/// A general-purpose UIView container adjusting its margins according to its internal properties.
class SubContainerView: UIView {
    /// The view margin borders that are enabled. Disabled borders have a margin set to 0.
    var enabledMargins: [NSLayoutConstraint.Attribute] = [.left, .top, .right, .bottom] {
        didSet { updateMargins() }
    }
    /// The margins values.
    var margins: NSDirectionalEdgeInsets = .zero {
        didSet { updateMargins() }
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

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }

    // MARK: - Layout Configuration
    func setupView() {
        insetsLayoutMarginsFromSafeArea = false
        margins = Layout.mainContainerInnerMargins(isRegularSizeClass, screenBorders: [])
    }

    private func updateMargins() {
        directionalLayoutMargins = .init(top: enabledMargins.contains(.top) ? margins.top : 0,
                                         leading: enabledMargins.contains(.left) ? margins.leading : 0,
                                         bottom: enabledMargins.contains(.bottom) ? margins.bottom : 0,
                                         trailing: enabledMargins.contains(.right) ? margins.trailing : 0)
    }
}

/// A general-purpose UIView container adjusting its margins according to the screen borders.
class MainContainerView: SubContainerView {
    /// The stackView borders that are connected to the device's screen. Used to correctly handle safe area offsets if needed.
    var screenBorders: [NSLayoutConstraint.Attribute] = [.left, .top, .right, .bottom] {
        didSet { updateMargins() }
    }
    /// The left padding configuration:
    ///   - Minimal if `true` (left border snaps to safe are space as defined in `Layout`).
    ///   - Regular if `false` (adds default margin as defined in `Layout`).
    var hasMinLeftPadding = false {
        didSet { updateMargins() }
    }

    // MARK: - Layout Configuration
    override func setupView() {
        super.setupView()
        updateMargins()
    }

    private func updateMargins() {
        margins = Layout.mainContainerInnerMargins(isRegularSizeClass,
                                                   screenBorders: screenBorders,
                                                   hasMinLeftPadding: hasMinLeftPadding)
    }
}

/// A UIView with default button's height constraint (defined by `Layout.buttonIntrinsicHeight`).
/// Used for action views.
public class ActionView: PassThroughView {
    public override var intrinsicContentSize: CGSize {
        .init(width: Layout.sidePanelWidth(isRegularSizeClass) - 2 * Layout.mainPadding(isRegularSizeClass),
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

    // MARK: - Layout Configuration
    func setupView() {
        heightAnchor.constraint(equalToConstant: Layout.buttonIntrinsicHeight(isRegularSizeClass)).isActive = true
    }
}

/// A `MainStackView` with default button's height constraint (defined by `Layout.buttonIntrinsicHeight`).
/// Used for action stackViews.
public class ActionStackView: MainStackView {
    public override var intrinsicContentSize: CGSize {
        .init(width: Layout.sidePanelWidth(isRegularSizeClass) - 2 * Layout.mainPadding(isRegularSizeClass),
              height: Layout.buttonIntrinsicHeight(isRegularSizeClass))
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }

    // MARK: - Layout Configuration
    override func setupView() {
        super.setupView()
        heightAnchor.constraint(equalToConstant: Layout.buttonIntrinsicHeight(isRegularSizeClass)).isActive = true
    }
}

/// A UIStackView with default text segments setting height (defined by `Layout.sidePanelSettingTextSegmentsHeight`).
class SettingTextSegmentContainerStackView: UIStackView {
    public override var intrinsicContentSize: CGSize {
        .init(width: super.intrinsicContentSize.width,
              height: Layout.sidePanelSettingTextSegmentsHeight(isRegularSizeClass)
        )
    }
}

/// A UIStackView with default short picto segments setting height (defined by `Layout.sidePanelSettingShortPictoSegmentsHeight`).
class SettingPictoSegmentContainerStackView: UIStackView {
    public override var intrinsicContentSize: CGSize {
        .init(width: super.intrinsicContentSize.width,
              height: Layout.sidePanelSettingShortPictoSegmentsHeight(isRegularSizeClass)
        )
    }
}

/// A UIView with default slider setting height (defined by `Layout.sidePanelSettingSliderHeight`).
class SidePanelSettingRulerView: UIView {
    public override var intrinsicContentSize: CGSize {
        .init(width: super.intrinsicContentSize.width,
              height: Layout.sidePanelSettingSliderHeight(isRegularSizeClass))
    }
}

/// A Side Panel Setting UIStackView container adjusting its constraints.
class SidePanelSettingContainerStackView: UIStackView {
    public override var intrinsicContentSize: CGSize {
        .init(width: super.intrinsicContentSize.width,
              height: Layout.sidePanelSettingTextSegmentsHeight(isRegularSizeClass)
        )
    }

    /// The setting type.
    var settingType: SidePanelSettingType = .textSegments {
        didSet { updateHeight() }
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }

    // MARK: - Layout Configuration
    private func setupView() {
        updateHeight()
    }

    private func updateHeight() {
        // Disable all height constraints already configured (previously or via the storyboard)
        constraints
            .filter { $0.firstAttribute == .height }
            .forEach { $0.isActive = false }
        // Activate the new constraint if needed
            heightAnchor
                .constraint(equalToConstant: settingType.height(isRegularSizeClass))
                .isActive = true
    }
}

/// A Side Panel Setting Cell UIStackView container adjusting its constraints.
class SidePanelSettingCellContainerStackView: UIStackView {

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }

    // MARK: - Layout Configuration
    private func setupView() {
        spacing = Layout.mainSpacing(isRegularSizeClass)
    }
}
