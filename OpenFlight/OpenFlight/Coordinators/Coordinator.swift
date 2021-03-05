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

import UIKit

/// Definition of coordinator protocol.

// MARK: - Protocol
public protocol Coordinator: class {
    /// Navigation controller to use in current context.
    var navigationController: NavigationController? { get set }

    /// Stack of all children coordinators.
    var childCoordinators: [Coordinator] { get set }

    /// Parent coordinator which triggers start().
    var parentCoordinator: Coordinator? { get set }

    /// Start the current coordinator.
    func start()

    /// Start child coordinator after adding it to the childCoordinators stack, and setting current navigation controller.
    /// Navigation Controller has an hidden Navigation Bar by default.
    ///
    /// - Parameters:
    ///    - coordinator: Coordinator to add to the stack
    func start(childCoordinator coordinator: Coordinator)

    /// Present child coordinator on the current Navigation Controller after adding it to the childCoordinators stack.
    ///
    /// - Parameters:
    ///    - coordinator: Coordinator to add to the stack
    ///    - animated: Animate the present coordinator action
    ///    - overFullScreen: Whether child navigation controller should be displayed over current screen
    ///    - completion: Completion closure called after the present action
    func present(childCoordinator coordinator: Coordinator,
                 animated: Bool,
                 overFullScreen: Bool,
                 completion: (() -> Void)?)

    /// Present view controller over full screen.
    ///
    /// - Parameters:
    ///    - viewController: view controller to display
    ///    - animated: Animate the present action
    ///    - completion: Completion closure called after the present action
    func presentModal(viewController: UIViewController,
                      animated: Bool,
                      completion: (() -> Void)?)

    /// Dismiss last child coordinator from the current Navigation Controller, and remove it from the childCoordinators stack.
    ///
    /// - Parameters:
    ///    - animated: Animate the dismiss coordinator action
    ///    - completion: Completion closure called after the dismiss action
    func dismissChildCoordinator(animated: Bool, completion: (() -> Void)?)

    /// Dismiss currently presented view controller.
    ///
    /// - Parameters:
    ///    - animated: animate the dismiss action
    ///    - completion: completion closure called after the dismiss action
    func dismiss(animated: Bool, completion: (() -> Void)?)

    /// Back to previous view controller thanks to navigation controller.
    ///
    /// - Parameters:
    ///    - animated: Animate the back coordinator action. Default value is true
    func back(animated: Bool)

    /// Start next view controller thanks to navigation controller.
    ///
    /// - Parameters:
    ///    - vc: View Controller which will be pushed
    ///    - animated: Animate the back coordinator action. Default value is true
    func push(_ viewController: UIViewController, animated: Bool)

    /// Presents a coordinator with an animation.
    ///
    /// - Parameters:
    ///     - childCoordinator: coordinator to start
    ///     - animationDirection: direction of the animation
    func presentCoordinatorWithAnimation(childCoordinator: Coordinator, animationDirection: CATransitionSubtype)

    /// Dismisses a coordinator with an animation.
    ///
    /// - Parameters:
    ///     - animationDirection: direction of the animation
    func dismissCoordinatorWithAnimation(animationDirection: CATransitionSubtype)
}

// MARK: - Default Implementation
public extension Coordinator {
    func start(childCoordinator coordinator: Coordinator) {
        childCoordinators.append(coordinator)
        coordinator.navigationController = navigationController
        coordinator.navigationController?.isNavigationBarHidden = true
        coordinator.start()
    }

    func present(childCoordinator coordinator: Coordinator,
                 animated: Bool = true,
                 overFullScreen: Bool = false,
                 completion: (() -> Void)? = nil) {
        guard let coordinatorNavController = coordinator.navigationController else { return }
        childCoordinators.append(coordinator)
        coordinatorNavController.modalPresentationStyle = overFullScreen ? .overFullScreen : .fullScreen
        self.navigationController?.present(coordinatorNavController, animated: animated, completion: completion)
    }

    func presentModal(viewController: UIViewController,
                      animated: Bool = true,
                      completion: (() -> Void)? = nil) {
        viewController.modalPresentationStyle = .overFullScreen
        self.navigationController?.present(viewController,
                                           animated: animated,
                                           completion: completion)
    }

    func dismissChildCoordinator(animated: Bool = true, completion: (() -> Void)? = nil) {
        self.navigationController?.dismiss(animated: animated, completion: completion)
        _ = childCoordinators.popLast()
    }

    func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        self.navigationController?.dismiss(animated: animated, completion: completion)
    }

    func back(animated: Bool = true) {
        self.navigationController?.popViewController(animated: animated)
    }

    func back(_ number: Int, animated: Bool = true) {
        if let viewControllers: [UIViewController] = self.navigationController?.viewControllers {
            guard viewControllers.count > number else { return }
            self.navigationController?.popToViewController(viewControllers[viewControllers.count - number], animated: animated)
        }
    }

    func backToRoot(animated: Bool = true) {
        self.navigationController?.popToRootViewController(animated: animated)
    }

    func push(_ viewController: UIViewController, animated: Bool = true) {
        self.navigationController?.pushViewController(viewController, animated: animated)
    }

    func presentCoordinatorWithAnimation(childCoordinator: Coordinator, animationDirection: CATransitionSubtype) {
        childCoordinator.parentCoordinator = self
        childCoordinator.start()
        childCoordinators.append(childCoordinator)

        guard let childNavController = childCoordinator.navigationController else {
            return
        }

        // Prevents not fullscreen presentation style since iOS 13.
        childNavController.modalPresentationStyle = .fullScreen

        let transition = CATransition()
        transition.duration = Style.shortAnimationDuration
        transition.type = CATransitionType.push
        transition.subtype = animationDirection
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        self.navigationController?.view.window?.layer.add(transition,
                                                          forKey: kCATransition)
        self.navigationController?.present(childNavController,
                                           animated: false,
                                           completion: nil)
    }

    func dismissCoordinatorWithAnimation(animationDirection: CATransitionSubtype) {
        let transition = CATransition()
        transition.duration = Style.shortAnimationDuration
        transition.type = CATransitionType.push
        transition.subtype = animationDirection
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        self.navigationController?.view.window?.layer.add(transition,
                                                          forKey: kCATransition)
        parentCoordinator?.dismissChildCoordinator(animated: false,
                                                   completion: nil)
    }
}
