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

// MARK: - Protocols
/// Stop view protocol.
public protocol StopViewDelegate: AnyObject {
    /// Should be called when user click on stop view.
    func didClickOnStop()
}

// MARK: - Internal Enums
/// Enum for different style of stop views.
public enum StopViewStyle {
    case classic
    case bottomBar
    case panorama
    case cancelAlert

    /// Returns true if the current style is cancel alert.
    var isCancelAlert: Bool {
        return self == .cancelAlert
    }
}

/// Custom view that display a stop sign.
public final class StopView: UIView, NibOwnerLoadable {

    // MARK: - Outlets
    @IBOutlet private weak var backView: UIView!
    @IBOutlet private weak var redView: UIView!
    @IBOutlet private weak var centerView: UIView!
    @IBOutlet private weak var cancelImageView: UIImageView!
    @IBOutlet private weak var redViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var redViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var redViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var redViewTrailingConstraint: NSLayoutConstraint!

    // MARK: - Public Properties
    public weak var delegate: StopViewDelegate?
    public var style: StopViewStyle = .classic {
        didSet {
            updateStyle()
        }
    }

    // MARK: - Private Enums
    private enum Constants {
        static let insetSpacePanorama: CGFloat = 3.0
    }

    // MARK: - Override Funcs
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInitStopView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInitStopView()
    }
}

// MARK: - Private Funcs
private extension StopView {

    /// Basic init for the view.
    func commonInitStopView() {
        loadNibContent()
        initUI()
    }

    /// Initalize UI for the view.
    func initUI() {
        accessibilityIdentifier = "StopView"
        backView.backgroundColor = ColorName.black.color
        redView.backgroundColor = ColorName.errorColor.color
        centerView.cornerRadiusedWith(backgroundColor: ColorName.white.color,
                                      borderColor: .clear,
                                      radius: Style.tinyCornerRadius)
        updateStyle()
    }

    /// Update the UI depending on the currentStyle.
    func updateStyle() {
        updateRedViewConstraints()
        cancelImageView.isHidden = !style.isCancelAlert
        centerView.isHidden = style.isCancelAlert
        redView.backgroundColor = style.isCancelAlert ? .clear : ColorName.errorColor.color

        switch style {
        case .classic:
            backView.cornerRadiusedWith(backgroundColor: ColorName.black.color,
                                        borderColor: ColorName.white.color,
                                        radius: Style.largeCornerRadius,
                                        borderWidth: Style.mediumBorderWidth)
            redView.applyCornerRadius(Style.mediumCornerRadius)
        case .bottomBar:
            customCornered(corners: [.topRight, .bottomRight],
                           radius: Style.largeCornerRadius,
                           backgroundColor: ColorName.errorColor.color,
                           borderColor: .clear)
        case .panorama:
            backView.cornerRadiusedWith(backgroundColor: ColorName.black.color,
                                        borderColor: ColorName.white.color,
                                        radius: Style.largeCornerRadius,
                                        borderWidth: Style.mediumBorderWidth)
            redView.applyCornerRadius(Style.mediumCornerRadius)
        case .cancelAlert:
            redView.applyCornerRadius(Style.mediumCornerRadius)
            backView.cornerRadiusedWith(backgroundColor: .white,
                                        radius: Style.largeCornerRadius)
        }
    }

    /// Update contraints for the red view.
    func updateRedViewConstraints() {
        let inset = (style == .panorama ? Constants.insetSpacePanorama : 0.0)
        redViewTopConstraint.constant = inset
        redViewBottomConstraint.constant = inset
        redViewLeadingConstraint.constant = inset
        redViewTrailingConstraint.constant = inset
    }
}

// MARK: - Actions
private extension StopView {
    /// Function called when user click on stop view.
    @IBAction func stopButtonTouchedUpInside() {
        delegate?.didClickOnStop()
    }
}
