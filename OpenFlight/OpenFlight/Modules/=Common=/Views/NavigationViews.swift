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

/// A UIStackView with file navigation view UI layout.
/// (Modularity purpose only: share `Layout` constants amongst different view controllers.)
public class NavigationStackView: BackgroundStackView {
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

    override func setupView() {
        super.setupView()
        heightAnchor.constraint(equalToConstant: Layout.fileNavigationBarHeight(isRegularSizeClass)).isActive = true
        directionalLayoutMargins = Layout.fileNavigationBarInnerMargins(isRegularSizeClass)
        insetsLayoutMarginsFromSafeArea = false
        isLayoutMarginsRelativeArrangement = true
        layer.zPosition = 1
    }
}

/// A UIStackView with file navigation view UI layout.
/// (Modularity purpose only: share `Layout` constants amongst different view controllers.)
public class FileNavigationStackView: NavigationStackView {
    override func setupView() {
        super.setupView()
        backgroundColor = .white
        addShadow()
    }
}

/// A UIView with file navigation view UI layout.
/// (Modularity purpose only: share `Layout` constants amongst different view controllers.)
class FileNavigationView: UIView {
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
        heightAnchor.constraint(equalToConstant: Layout.fileNavigationBarHeight(isRegularSizeClass)).isActive = true
        directionalLayoutMargins = Layout.fileNavigationBarInnerMargins(isRegularSizeClass)
        insetsLayoutMarginsFromSafeArea = false
        backgroundColor = .white
        layer.zPosition = 1
        addShadow()
    }
}

/// A UIView with device navigation view UI layout.
/// (Modularity purpose only: share `Layout` constants amongst different view controllers.)
class DeviceNavigationView: UIView {
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
        heightAnchor.constraint(equalToConstant: Layout.fileNavigationBarHeight(isRegularSizeClass)).isActive = true
        directionalLayoutMargins = Layout.fileNavigationBarInnerMargins(isRegularSizeClass)
        insetsLayoutMarginsFromSafeArea = false
    }
}

/// A UIStackView with side navigation view UI layout.
/// (Modularity purpose only: share `Layout` constants amongst different view controllers.)
class SideNavigationBarStackView: UIStackView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }

    private func setupView() {
        heightAnchor.constraint(equalToConstant: Layout.hudTopBarHeight(isRegularSizeClass)).isActive = true
        directionalLayoutMargins = Layout.sideNavigationBarInnerMargins(isRegularSizeClass)
        insetsLayoutMarginsFromSafeArea = false
        isLayoutMarginsRelativeArrangement = true
    }
}

/// A UIView with side navigation view UI layout.
/// (Modularity purpose only: share `Layout` constants amongst different view controllers.)
class SideNavigationBarView: UIView {
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
        heightAnchor.constraint(equalToConstant: Layout.hudTopBarHeight(isRegularSizeClass)).isActive = true
        directionalLayoutMargins = Layout.sideNavigationBarInnerMargins(isRegularSizeClass)
        insetsLayoutMarginsFromSafeArea = false
    }
}

/// A UIButton with an inset hit area.
/// Useful for small navigation bar buttons.
class InsetHitAreaButton: UIButton {
    var hitAreaInsets: UIEdgeInsets = .init(top: Constants.defaultInsetValue,
                                            left: Constants.defaultInsetValue,
                                            bottom: Constants.defaultInsetValue,
                                            right: Constants.defaultInsetValue)

    private enum Constants {
        static let defaultInsetValue: CGFloat = -20
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.inset(by: hitAreaInsets).contains(point)
    }
}
