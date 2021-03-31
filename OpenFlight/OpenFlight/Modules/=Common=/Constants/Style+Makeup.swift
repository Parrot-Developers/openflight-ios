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

import UIKit

/// Extension for UI elements dedicated to style purpose.

// MARK: - UILabel
public extension UILabel {
    /// Makingup label using style and color.
    ///
    /// - Parameters:
    ///     - style: font style
    ///     - color: color of the text
    final func makeUp(with style: ParrotFontStyle = .regular, and color: ColorName = .white) {
        self.font = UIFont.font(with: style)
        self.textColor = color.color
    }
}

// MARK: - UIButton
public extension UIButton {
    // TODO: For each use, remove default parameters if needed.
    /// Makingup UIButton using style and color.
    ///
    /// - Parameters:
    ///     - style: font style
    ///     - color: color of the button text
    ///     - state: text state
    final func makeup(with style: ParrotFontStyle = .regular,
                      color: ColorName = .white,
                      and state: UIControl.State = UIControl.State.normal) {
        self.titleLabel?.font = UIFont.font(with: style)
        self.setTitleColor(color.color, for: state)
    }
}

// MARK: - UISegmentedControl
public extension UISegmentedControl {
    /// Apply styles for different states.
    ///
    /// - Parameters:
    ///     - normalBackgroundColor: background color for normal state
    ///     - selectedBackgroundColor: background color for selected state
    ///     - normalFontColor: font color for normal state
    ///     - selectedFontColor: font color for selected state
    final func customMakeup(normalBackgroundColor: ColorName = ColorName.black,
                            selectedBackgroundColor: ColorName = ColorName.white,
                            normalFontColor: ColorName = ColorName.white,
                            selectedFontColor: ColorName = ColorName.black) {
        if #available(iOS 13.0, *) {
            self.backgroundColor = normalBackgroundColor.color
            self.selectedSegmentTintColor = selectedBackgroundColor.color
        } else {
            // iOS 13 prior special case
            self.setBackgroundImage(normalBackgroundColor.color.asImage(),
                                    for: .normal,
                                    barMetrics: .default)
            self.setBackgroundImage(selectedBackgroundColor.color.asImage(),
                                    for: .selected,
                                    barMetrics: .default)
            self.layer.cornerRadius = 4.0
            self.clipsToBounds = true
        }
        self.setDividerImage(UIImage(),
                             forLeftSegmentState: .normal,
                             rightSegmentState: .normal,
                             barMetrics: .default)
        self.makeup(with: ParrotFontStyle.regular,
                    color: normalFontColor,
                    and: .normal)
        self.makeup(with: ParrotFontStyle.regular,
                    color: selectedFontColor,
                    and: .selected)
    }

    /// Makingup UISegmentedControl using style and color.
    ///
    /// - Parameters:
    ///     - style: font style
    ///     - color: color of text
    ///     - state: text state
    final func makeup(with style: ParrotFontStyle = ParrotFontStyle.regular,
                      color: ColorName = .white,
                      and state: UIControl.State = UIControl.State.normal) {
        self.setTitleTextAttributes([.font: style.font,
                                     .foregroundColor: color.color], for: state)
    }
}

// MARK: - UIView
public extension UIView {
    /// Add blur effect to the view.
    ///
    /// - Parameters:
    ///     - style: blur effect
    ///     - cornerRadius: radius of the view
    final func addBlurEffect(with style: UIBlurEffect.Style = .dark,
                             cornerRadius: CGFloat = Style.largeCornerRadius) {
        // Remove old visual effect views first.
        removeBlurEffect()
        let blurEffect = UIBlurEffect(style: style)
        let blurredEffectView = UIVisualEffectView(effect: blurEffect)
        blurredEffectView.isUserInteractionEnabled = false
        blurredEffectView.layer.cornerRadius = cornerRadius
        blurredEffectView.clipsToBounds = true
        addWithConstraints(subview: blurredEffectView)
        sendSubviewToBack(blurredEffectView)
    }

    /// Add blur effect to the view with two rounded corners.
    ///
    /// - Parameters:
    ///     - style: blur effect
    ///     - firstCorner: first corner to round
    ///     - secondCorner: second corner to round
    final func addBlurEffectWithTwoCorners(with style: UIBlurEffect.Style = .dark, firstCorner: CACornerMask, secondCorner: CACornerMask) {
        // Remove old visual effect views first.
        removeBlurEffect()
        let blurEffect = UIBlurEffect(style: style)
        let blurredEffectView = UIVisualEffectView(effect: blurEffect)
        blurredEffectView.isUserInteractionEnabled = false
        blurredEffectView.layer.cornerRadius = Style.mediumCornerRadius
        blurredEffectView.layer.maskedCorners = [firstCorner, secondCorner]
        blurredEffectView.clipsToBounds = true
        addWithConstraints(subview: blurredEffectView)
        sendSubviewToBack(blurredEffectView)
    }

    /// Remove blur effect to the view.
    func removeBlurEffect() {
        subviews.forEach {
            if $0 is UIVisualEffectView {
                $0.removeFromSuperview()
            }
        }
    }
}

// MARK: - UITextField
public extension UITextField {
    /// Makingup UITextField using style and color.
    ///
    /// - Parameters:
    ///     - style: font style
    ///     - textColor: color of the text
    ///     - bgColor: background color
    func makeUp(style: ParrotFontStyle = .regular,
                textColor: ColorName = .white,
                bgColor: ColorName = .black60) {
        self.backgroundColor = bgColor.color
        self.font = style.font
        self.textColor = textColor.color
        self.layer.borderColor = bgColor.color.cgColor
    }
}

// MARK: - UITableView
public extension UITableView {
    /// Makingup UITableView.
    ///
    /// - Parameters:
    ///     - backgroundColor: optinal background color
    ///     - showsVerticalScrollIndicator: shows vertical scroll indicator
    func makeUp(backgroundColor: UIColor? = nil,
                showsVerticalScrollIndicator: Bool = false) {
        if let backgroundColor = backgroundColor {
            self.backgroundColor = backgroundColor
        }
        self.tableFooterView = UIView() // Prevents form extra separators
        self.showsVerticalScrollIndicator = showsVerticalScrollIndicator
        self.separatorInset = UIEdgeInsets.zero
    }
}
