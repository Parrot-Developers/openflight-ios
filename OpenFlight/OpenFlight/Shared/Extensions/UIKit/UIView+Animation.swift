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

/// Animation extension for `UIView`.

public extension UIView {
    private enum Constants {
        static let slightScale: CGFloat = 0.8
    }

    // Start rotation animation on a UIView.
    func startRotate() {
        let rotation: CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = 1
        rotation.isCumulative = true
        rotation.repeatCount = Float.greatestFiniteMagnitude
        self.layer.add(rotation, forKey: "rotationAnimation")
    }

    // Stop rotation animation on a UIView.
    func stopRotate() {
        self.layer.removeAnimation(forKey: "rotationAnimation")
    }

    // Fade out animation on a UIView.
    func fadeOut(_ duration: TimeInterval?, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration ?? 0.0,
                       animations: { self.alpha = 0.0 },
                       completion: {_ in
                        self.isHidden = true
                        if let complete = completion { complete() }
                       })
    }

    /// Animates fade in.
    ///
    /// - Parameters:
    ///    - duration: the fade in animation duration
    ///    - delay: the delay before trigger the fade in animation
    ///    - fromAlpha: the view's opacity to animate from
    ///    - toAlpha: the view's opacity to animate to
    ///    - completion (optional): the completion block
    func fadeIn(_ duration: TimeInterval = Style.shortAnimationDuration,
                delay: TimeInterval = 0,
                from fromAlpha: CGFloat = 0,
                to toAlpha: CGFloat = 1,
                completion: ((Bool) -> Void)? = nil) {
        alpha = fromAlpha
        UIView.animate(withDuration: duration, delay: delay, options: .curveEaseOut, animations: {
            self.alpha = toAlpha
        }, completion: completion)
    }

    /// Adds a temporary snapshot of currently rendered view and fades it out after some delay.
    ///
    /// - Parameter duration: the delay before fading out the snapshot
    func addTransitionSnapshot(for duration: TimeInterval = Style.shortAnimationDuration) {
        let snapshot = snapshotView(afterScreenUpdates: false)
        addSubview(snapshot)
        UIView.animate(withDuration: Style.fastAnimationDuration, delay: duration, options: .curveEaseOut) {
            snapshot?.alpha = 0
        } completion: { _ in
            snapshot?.removeFromSuperview()
        }
    }

    /// Animates showing/hiding of the view from one of its edges.
    ///
    /// - Parameters:
    ///    - edge: edge to animate the view from/to
    ///    - offset: an optional offset to add the the translation
    ///    - show: show view if `true`, hide it otherwise
    ///    - fadeFrom: view's opacity will be animated from 0 to `fadeFrom` value if not nil
    ///    - animate: animate showing/hiding if `true`, directly apply transform otherwise
    ///    - duration: animation duration
    ///    - delay: delay for the animation
    ///    - initialTransform: translation transform will be concatenated to `initialTransform` if specified
    ///    - completion: the completion block
    func showFromEdge(_ edge: UIRectEdge,
                      offset: CGFloat = 0,
                      show: Bool,
                      fadeFrom: CGFloat? = nil,
                      animate: Bool = true,
                      duration: TimeInterval = Style.shortAnimationDuration,
                      delay: TimeInterval = 0,
                      initialTransform: CGAffineTransform = .identity,
                      completion: (() -> Void)? = nil) {
        let translation: CGPoint

        switch edge {
        case .top: translation = .init(x: 0, y: -bounds.height - offset)
        case .bottom: translation = .init(x: 0, y: bounds.height + offset)
        case .left: translation = .init(x: -bounds.width - offset, y: 0)
        case .right: translation = .init(x: bounds.width + offset, y: 0)
        default: translation = .zero
        }

        let transformBlock = {
            self.transform = show
                ? initialTransform
                : initialTransform.translatedBy(x: translation.x, y: translation.y)
            if let fadeFrom = fadeFrom {
                self.alpha = show ? fadeFrom : 0
            }
        }

        if animate {
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
                transformBlock()
            } completion: { _ in
                completion?()
            }
        } else {
            transformBlock()
            completion?()
        }
    }

    /// Animates view with pre-defined parameters (convenience function).
    ///
    /// - Parameters:
    ///    - duration: Animation duration.
    ///    - delay: Delay for the animation.
    ///    - options: Animation options.
    ///    - animations: The animation block.
    ///    - completion: The completion block.
    static func animate(_ duration: TimeInterval = Style.shortAnimationDuration,
                        delay: TimeInterval = 0,
                        options: UIView.AnimationOptions = [.curveEaseOut],
                        animations: @escaping () -> Void,
                        completion: ((Bool) -> Void)? = nil) {
        animate(withDuration: duration, delay: delay, options: options, animations: animations, completion: completion)

    }

    /// Animates isHidden with pre-defined parameters (convenience function).
    ///
    /// - Parameters:
    ///    - isHidden: `isHidden` property value of the view.
    ///    - withAlpha: Animates view's opacity from/to `withAlpha` value if not nil (1 by default).
    ///    - duration: Animation duration.
    ///    - delay: Delay for the animation.
    ///    - options: Animation options.
    ///    - completion: The completion block.
    func animateIsHidden(_ isHidden: Bool,
                         withAlpha alpha: CGFloat? = 1,
                         duration: TimeInterval = Style.shortAnimationDuration,
                         delay: TimeInterval = 0,
                         options: UIView.AnimationOptions = [.curveEaseOut],
                         completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: delay, options: options, animations: {
            self.isHidden = isHidden
            if let alpha = alpha {
                self.alphaHidden(isHidden, withAlpha: alpha)
            }
        }, completion: completion)
    }

    /// Animates isHiddenInStackView with pre-defined parameters (convenience function).
    ///
    /// - Parameters:
    ///    - isHidden: `isHiddenInStackView` property value of the view.
    ///    - withAlpha: Animates view's opacity from/to `withAlpha` value if not nil (1 by default).
    ///    - duration: Animation duration.
    ///    - delay: Delay for the animation.
    ///    - options: Animation options.
    ///    - completion: The completion block.
    func animateIsHiddenInStackView(_ isHidden: Bool,
                                    withAlpha alpha: CGFloat? = 1,
                                    duration: TimeInterval = Style.shortAnimationDuration,
                                    delay: TimeInterval = 0,
                                    options: UIView.AnimationOptions = [.curveEaseOut],
                                    completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: delay, options: options, animations: {
            self.isHiddenInStackView = isHidden
            if let alpha = alpha {
                self.alphaHidden(isHidden, withAlpha: alpha)
            }
        }, completion: completion)
    }

    /// Animates view showing/hiding with opacity and slight scale.
    ///
    /// - Parameter show: whether the view should be shown or hidden
    func animateScaleAndAlpha(show: Bool) {
        UIView.animate {
            self.transform = show ? .identity : .init(scaleX: Constants.slightScale, y: Constants.slightScale)
            self.alphaHidden(!show)
        }
    }
}
