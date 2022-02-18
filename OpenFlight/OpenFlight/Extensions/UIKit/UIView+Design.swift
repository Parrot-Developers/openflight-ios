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

import QuartzCore
import UIKit

/// Design/customization extension for `UIView`

public extension UIView {

    /// Apply a simple border to view.
    ///
    /// - Parameters:
    ///    - borderColor: The border color
    ///    - borderWidth: The border width
    func setBorder(borderColor: UIColor, borderWidth: CGFloat) {
        self.layer.borderColor = borderColor.cgColor
        self.layer.borderWidth = borderWidth
    }

    /// Apply Corner radius to view with specific colors for border and background.
    ///
    /// - Parameters:
    ///    - backgroundColor: The background color
    ///    - borderColor: The border color
    ///    - radius: The angle radius
    ///    - borderWidth: The border width
    func cornerRadiusedWith(backgroundColor: UIColor,
                            borderColor: UIColor = .clear,
                            radius: CGFloat,
                            borderWidth: CGFloat = Style.noBorderWidth) {
        self.layer.cornerRadius = radius
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = borderColor.cgColor
        self.backgroundColor = backgroundColor
    }

    /// Apply Corner radius so the view's corner are full rounded with specific colors for border and background.
    ///
    /// - Parameters:
    ///    - backgroundColor: The background color
    ///    - borderColor: The border color
    func roundCorneredWith(backgroundColor: UIColor,
                           borderColor: UIColor = .clear,
                           borderWidth: CGFloat = Style.noBorderWidth) {
        self.layer.cornerRadius = self.frame.height / 2
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = borderColor.cgColor
        self.backgroundColor = backgroundColor
    }

    /// Apply corner radius so the view's corner are rounded.
    func roundCornered() {
        // Use minimum between width and height to always provide
        // a rounded shape on any type of rectangle.
        self.layer.cornerRadius = min(self.frame.width, self.frame.height) / 2
    }

    /// Applies corner radius so the view's corners are custom defined.
    ///
    /// - Parameters:
    ///     - corners: The corners to modify
    ///     - radius: The radius to apply
    func customCornered(corners: UIRectCorner, radius: CGFloat) {
        var layerCorners: CACornerMask = CACornerMask()
        if corners.contains(.topLeft) {
            layerCorners.insert(.layerMinXMinYCorner)
        }
        if corners.contains(.topRight) {
            layerCorners.insert(.layerMaxXMinYCorner)
        }
        if corners.contains(.bottomLeft) {
            layerCorners.insert(.layerMinXMaxYCorner)
        }
        if corners.contains(.bottomRight) {
            layerCorners.insert(.layerMaxXMaxYCorner)
        }
        self.layer.maskedCorners = layerCorners
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }

    /// Applies corner radius so the view's corners are custom defined, with custom background and border.
    ///
    /// - Parameters:
    ///     - corners: The corners to modify.
    ///     - radius: The radius to apply.
    ///     - backgroundColor: The background color.
    ///     - borderColor: The border color.
    ///     - borderWidth: The border width.
    func customCornered(corners: UIRectCorner,
                        radius: CGFloat,
                        backgroundColor: UIColor,
                        borderColor: UIColor,
                        borderWidth: CGFloat = Style.mediumBorderWidth) {
        self.backgroundColor = backgroundColor
        self.setBorder(borderColor: borderColor, borderWidth: borderWidth)
        customCornered(corners: corners, radius: radius)
    }

    /// Apply Corner radius and animates changes.
    ///
    /// - Parameters:
    ///    - toValue: Expected layer corner radius
    ///    - duration: Animation duration
    func addCornerRadiusAnimation(toValue: CGFloat, duration: CFTimeInterval) {
        let animation = CABasicAnimation(keyPath: "cornerRadius")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.fromValue = layer.cornerRadius
        animation.toValue = toValue
        animation.duration = duration
        layer.add(animation, forKey: "cornerRadius")
        layer.cornerRadius = toValue
    }

    /// Applies a shadow to the view. Allows full parameters customization.
    ///
    /// - Parameters:
    ///    - shadowColor: The color of the shadow.
    ///    - shadowOffset: The offset of the shadow.
    ///    - shadowOpacity: The opacity of the shadow.
    ///    - shadowRadius: The radius of the shadow.
    ///    - condition: Apply shadow only if `condition` is `true`.
    func addShadow(shadowColor: UIColor = ColorName.shadowColor.color,
                   shadowOffset: CGSize = Style.shadowOffset,
                   shadowOpacity: Float = Style.shadowOpacity,
                   shadowRadius: CGFloat = Style.shadowRadius,
                   condition: Bool = true) {
        guard condition else {
            layer.shadowColor = UIColor.clear.cgColor
            return
        }

        layer.shadowColor = shadowColor.cgColor
        layer.shadowOffset = shadowOffset
        layer.shadowOpacity = shadowOpacity
        layer.shadowRadius = shadowRadius
    }

    /// Apply default corner radius to a view.
    ///
    /// - Parameters:
    ///    - cornerRadius: corner tadius to apply
    ///    - maskedCorners: corners to mask
    func applyCornerRadius(_ cornerRadius: CGFloat = Style.smallCornerRadius,
                           maskedCorners: CACornerMask? = nil) {
        if let maskedCorners = maskedCorners {
            self.layer.maskedCorners = maskedCorners
        }
        self.layer.cornerRadius = cornerRadius
        self.clipsToBounds = true
    }

    /// Add gradient layer from black to clear color.
    /// - Parameters:
    ///  - alpha: black color alpha to start gradient
    ///  - superview: view to compute gradient layer width
    func addGradient(startAlpha: CGFloat = 1.0, endAlpha: CGFloat = 0.0, superview: UIView? = nil) {
        // Remove previous CustomGradientLayer
        self.layer.sublayers?.forEach {
            if $0 is CustomGradientLayer {
                $0.removeFromSuperlayer()
            }
        }

        let gradient = CustomGradientLayer()
        let superview = superview ?? self
        gradient.frame = CGRect(x: 0.0, y: 0.0,
                                width: superview.bounds.size.width, height: superview.bounds.size.height)
        gradient.colors = [UIColor.black.withAlphaComponent(startAlpha).cgColor,
                           UIColor.black.withAlphaComponent(endAlpha).cgColor]
        layer.insertSublayer(gradient, at: 0)
    }

    /// Apply alpha to view according to given enabled state.
    ///
    /// - Parameters:
    ///    - isEnabled: boolean describing enabled state
    ///    - withAlpha: View's opacity value when enabled (1 by default).
    func alphaWithEnabledState(_ isEnabled: Bool, withAlpha alpha: CGFloat = 1) {
        self.alpha = isEnabled ? alpha : Style.disabledAlpha
    }

    /// Hides/shows the view using alpha and removes user interaction.
    ///
    /// - Parameters:
    ///    - isHidden: whether view should be hidden (default: true)
    ///    - withAlpha: View's opacity value when visible (1 by default).
    func alphaHidden(_ isHidden: Bool = true, withAlpha alpha: CGFloat = 1) {
        self.alpha = isHidden ? 0.0 : alpha
        self.isUserInteractionEnabled = !isHidden
    }
}

/// Custom class used to identify custom layers created by `addGradient` that needs to be removed.
class CustomGradientLayer: CAGradientLayer {
}
