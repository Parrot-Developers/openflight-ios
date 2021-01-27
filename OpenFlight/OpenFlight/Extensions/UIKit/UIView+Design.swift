// Copyright (C) 2020 Parrot Drones SAS
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
                            borderWidth: CGFloat = 0.0) {
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
                           borderWidth: CGFloat = 0.0) {
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

    /// Apply Corner radius so the view's corners are custom defined.
    ///
    /// - Parameters:
    ///    - corners: The corners to modify
    ///    - radius: The radius to apply
    @discardableResult
    func customCornered(corners: UIRectCorner, radius: CGFloat) -> CAShapeLayer {
        let mask = CAShapeLayer()
        let width = radius
        let cornerRadii = CGSize(width: width, height: 0)
        let path = UIBezierPath(roundedRect: self.bounds,
                                byRoundingCorners: corners,
                                cornerRadii: cornerRadii)
        mask.path = path.cgPath
        self.layer.mask = mask
        self.layer.masksToBounds = true
        return mask
    }

    /// Apply Corner radius so the view's corners are custom defined, with custom background and border.
    ///
    /// - Parameters:
    ///     - corners: The corners to modify
    ///     - radius: The radius to apply
    ///     - backgroundColor: The background color
    ///     - borderColor: The border color
    func customCornered(corners: UIRectCorner, radius: CGFloat, backgroundColor: UIColor, borderColor: UIColor, borderWidth: CGFloat = 1.0) {
        // Remove previous CustomShapeLayers
        self.layer.sublayers?.forEach {
            if $0 is CustomShapeLayer {
                $0.removeFromSuperlayer()
            }
        }
        // Create path for mask and custom layer.
        let mask = customCornered(corners: corners, radius: radius)

        let frameLayer = CustomShapeLayer()
        frameLayer.path =  mask.path // Reuse the Bezier path
        frameLayer.strokeColor = borderColor.cgColor
        frameLayer.fillColor = nil
        frameLayer.lineWidth = borderWidth
        self.backgroundColor = backgroundColor
        self.layer.insertSublayer(frameLayer, at: 0)
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

    /// Apply shadow to view.
    func addShadow() {
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 1)
        self.layer.shadowOpacity = 1
        self.layer.shadowRadius = 2.0
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
    func addGradient(startAlpha: CGFloat, endAlpha: CGFloat = 0.0, superview: UIView) {
        // Remove previous CustomGradientLayer
        self.layer.sublayers?.forEach {
            if $0 is CustomGradientLayer {
                $0.removeFromSuperlayer()
            }
        }

        let gradient = CustomGradientLayer()
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
    func alphaWithEnabledState(_ isEnabled: Bool) {
        self.alpha = isEnabled ? 1.0 : 0.3
    }

    /// Hides/shows the view using alpha and removes user interaction.
    ///
    /// - Parameters:
    ///    - isHidden: whether view should be hidden (default: true)
    func alphaHidden(_ isHidden: Bool = true) {
        self.alpha = isHidden ? 0.0 : 1.0
        self.isUserInteractionEnabled = !isHidden
    }
}

/// Custom class used to identify custom layers created by customCornered that needs to be removed.
class CustomShapeLayer: CAShapeLayer {
}

/// Custom class used to identify custom layers created by `addGradient` that needs to be removed.
class CustomGradientLayer: CAGradientLayer {
}
