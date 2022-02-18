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

/// Class which manage device orientation.

public final class NavigationController: UINavigationController {
    var animator: Animator?
    var transitionDuration: TimeInterval?
    var transitionType: CATransitionType = .push
    var transitionSubtype: CATransitionSubtype = .fromRight
    var animatedViews: Animator.AnimatedViews = .both

    // MARK: - Override Funcs
    public override var shouldAutorotate: Bool {
        return topViewController?.shouldAutorotate ?? super.shouldAutorotate
    }

    // MARK: - Navigation

    /// Presents a view controller using navigation controller animated transitioning object.
    ///
    /// - Parameters:
    ///    - viewControllerToPresent: the view controller to present
    ///    - transitionDuration: the transition duration
    ///    - transitionType: the transition type
    ///    - transitionSubtype: the transition subtype
    ///    - completion: the completion block
    public func present(_ viewControllerToPresent: NavigationController,
                        transitionDuration: TimeInterval? = nil,
                        transitionType: CATransitionType = .push,
                        transitionSubtype: CATransitionSubtype = .fromRight,
                        completion: (() -> Void)? = nil) {
        viewControllerToPresent.transitioningDelegate = self
        self.transitionDuration = transitionDuration
        self.transitionType = transitionType
        self.transitionSubtype = transitionSubtype
        self.animatedViews = .both
        present(viewControllerToPresent, animated: true, completion: completion)
    }

    /// Dismisses presented view controller using navigation controller animated transitioning object.
    ///
    /// - Parameters:
    ///    - transitionDuration: the transition duration
    ///    - transitionType: the transition type
    ///    - transitionSubtype: the transition subtype
    ///    - completion: the completion block
    public func dismiss(transitionDuration: TimeInterval? = nil,
                        transitionType: CATransitionType = .push,
                        transitionSubtype: CATransitionSubtype = .fromRight,
                        completion: (() -> Void)? = nil) {
        presentedViewController?.transitioningDelegate = self
        self.transitionDuration = transitionDuration
        self.transitionType = transitionType
        self.transitionSubtype = transitionSubtype
        self.animatedViews = .both
        dismiss(animated: true, completion: completion)
    }
}

// MARK: - Transitioning Delegate
extension NavigationController: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController,
                                    source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator = Animator(duration: transitionDuration, type: transitionType, subtype: transitionSubtype, animatedViews: animatedViews)
        return animator
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator = Animator(duration: transitionDuration, type: transitionType, subtype: transitionSubtype, animatedViews: animatedViews)
        return animator
    }
}
