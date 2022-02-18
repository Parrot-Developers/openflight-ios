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

/// An animator used to customize view controllers transitions.
public final class Animator: NSObject, UIViewControllerAnimatedTransitioning {
    /// The transition duration (automatically determined according to `subtype` parameter if `nil`).
    private let duration: TimeInterval?
    /// The transition type.
    private let type: CATransitionType
    /// The transition subtype (ignored if `type` is `.fade`).
    private let subtype: CATransitionSubtype
    /// The views participating to the transition animation.
    private let animatedViews: AnimatedViews
    public enum AnimatedViews {
        case both, src, dst
    }

    // MARK: - Init
    init?(duration: TimeInterval?,
          type: CATransitionType,
          subtype: CATransitionSubtype,
          animatedViews: AnimatedViews) {
        self.duration = duration
        self.type = type
        self.subtype = subtype
        self.animatedViews = animatedViews
    }

    // MARK: - Transitioning
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        transitionDuration
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        guard let toView = transitionContext.view(forKey: .to),
              let fromView = transitionContext.view(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }

        // Determine animated views offset according to transition parameters.
        let xOffset = transitionOffsetFactor.x * containerView.bounds.width
        let yOffset = transitionOffsetFactor.y * containerView.bounds.height

        // Check if destination view belongs to transition.
        if animatedViews != .src {
            if type == .reveal {
                containerView.insertSubview(toView, belowSubview: fromView)
            } else {
                toView.transform = .init(translationX: xOffset, y: yOffset)
                containerView.addSubview(toView)
            }
        }

        if type == .fade {
            toView.alpha = 0
        }

        // Animate transition.
        UIView.animate(withDuration: transitionDuration, delay: 0, options: .curveEaseOut) {
            toView.transform = .identity
            toView.alpha = 1
            if self.animatedViews != .dst && self.type != .moveIn {
                fromView.transform = .init(translationX: -xOffset, y: -yOffset)
            }
        } completion: { _ in
            fromView.transform = .identity
            transitionContext.completeTransition(true)
        }
    }

    // MARK: - Convenience computed properties for transition parameters computation.

    private var transitionOffsetFactor: CGPoint {
        if type == .fade { return .zero }
        switch subtype {
        case .fromLeft: return .init(x: -1, y: 0)
        case .fromRight: return .init(x: 1, y: 0)
        case .fromTop: return .init(x: 0, y: -1)
        case .fromBottom: return .init(x: 0, y: 1)
        default: return .zero
        }
    }

    private var transitionDuration: TimeInterval {
        duration ?? (subtype == .fromBottom || subtype == .fromTop
        ? Style.shortAnimationDuration
        : Style.transitionAnimationDuration)
    }
}
