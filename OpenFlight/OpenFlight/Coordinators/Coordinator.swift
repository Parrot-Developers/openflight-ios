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

// MARK: - Protocol
/// Definition of coordinator protocol.
public protocol Coordinator: AnyObject {
    /// Navigation controller to use in current context.
    var navigationController: NavigationController? { get set }

    /// Stack of all children coordinators.
    var childCoordinators: [Coordinator] { get set }

    /// Parent coordinator which triggers start().
    var parentCoordinator: Coordinator? { get set }

    /// Starts the current coordinator.
    func start()

    /// Starts child coordinator after adding it to the childCoordinators stack, and setting current navigation controller.
    /// Navigation Controller has an hidden Navigation Bar by default.
    ///
    /// - Parameters:
    ///    - coordinator: Coordinator to add to the stack
    func start(childCoordinator coordinator: Coordinator)

    /// Presents child coordinator on the current Navigation Controller after adding it to the childCoordinators stack.
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

    /// Presents view controller over full screen.
    ///
    /// - Parameters:
    ///    - viewController: view controller to display
    ///    - animated: Animate the present action
    ///    - completion: Completion closure called after the present action
    func presentModal(viewController: UIViewController,
                      animated: Bool,
                      completion: (() -> Void)?)

    /// Dismisses last child coordinator from the current Navigation Controller, and remove it from the childCoordinators stack.
    ///
    /// - Parameters:
    ///    - animated: Animate the dismiss coordinator action
    ///    - completion: Completion closure called after the dismiss action
    func dismissChildCoordinator(animated: Bool, completion: (() -> Void)?)

    /// Dismisses currently presented view controller.
    ///
    /// - Parameters:
    ///    - animated: animate the dismiss action
    ///    - completion: completion closure called after the dismiss action
    func dismiss(animated: Bool, completion: (() -> Void)?)

    /// Backs to previous view controller thanks to navigation controller.
    ///
    /// - Parameters:
    ///    - animated: Animate the back coordinator action. Default value is true
    func back(animated: Bool)

    /// Starts next view controller thanks to navigation controller.
    ///
    /// - Parameters:
    ///    - viewController: View Controller which will be pushed
    ///    - animated: Animate the back coordinator action. Default value is true
    func push(_ viewController: UIViewController, animated: Bool)

    /// Presents a coordinator with an animation.
    ///
    /// - Parameters:
    ///    - childCoordinator: coordinator to start
    ///    - transitionType: the transition type (`.push` by default)
    ///    - transitionSubtype: the transition subtype (`.fromRight` by default)
    ///    - completion: completion closure called after the transition
    func presentCoordinatorWithAnimator(childCoordinator: Coordinator,
                                        transitionType: CATransitionType,
                                        transitionSubtype: CATransitionSubtype,
                                        completion: (() -> Void)?)

    /// Presents a stack of coordinators.
    ///
    /// - Parameters:
    ///   - coordinators: an ordered (from parent to children) stack of coordinators to present
    ///   - transitionType: the transition type (`.push` by default)
    ///   - transitionSubtype: the transition subtype (`.fromRight` by default)
    ///   - snapshotView: a view to overlay during transition (if provided) in order to avoid potential visual glitches
    ///   - completion: completion closure called after the transition
    func presentCoordinatorsStack(coordinators: [Coordinator],
                                  transitionType: CATransitionType,
                                  transitionSubtype: CATransitionSubtype,
                                  snapshotView: UIView?,
                                  completion: (() -> Void)?)

    /// Dismisses a coordinator with an animation.
    ///
    /// - Parameters:
    ///    - transitionType: the transition type (`.push` by default)
    ///    - transitionSubtype: the transition subtype (`.fromLeft` by default)
    ///    - completion: completion when dismiss is done
    func dismissCoordinatorWithAnimator(transitionType: CATransitionType,
                                        transitionSubtype: CATransitionSubtype,
                                        completion: (() -> Void)?)

    /// Pops to root coordinator.
    ///
    /// - Parameters:
    ///    - coordinator: parent coordinator of self
    func popToRootCoordinator(coordinator: Coordinator?)

    /// Pops to root coordinator with animation.
    ///
    /// - Parameters:
    ///   - coordinator: parent coordinator of self
    ///   - isPresentedCoordinator: whether coordinator is presented on screen
    ///   - transitionType: the transition type (`.push` by default)
    ///   - transitionSubtype: the transition subtype (`.fromLeft` by default)
    ///   - completion: Completion closure called after the transition
    func popToRootCoordinatorWithAnimator(coordinator: Coordinator?,
                                          isPresentedCoordinator: Bool,
                                          transitionType: CATransitionType,
                                          transitionSubtype: CATransitionSubtype,
                                          completion: (() -> Void)?)

    /// Back to specified view controller index thanks to navigation controller.
    ///
    /// - Parameters:
    ///    - vcIndex: View Controller's index.
    ///    - animated: Animate the back coordinator action. Default value is true.
    func back(to vcIndex: Int, animated: Bool)
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
        navigationController?.present(coordinatorNavController, animated: animated, completion: completion)

        if AppUtils.isLayoutGridAuthorized {
            LayoutGridView().overlay(on: coordinatorNavController)
        }
    }

    func presentModal(viewController: UIViewController,
                      animated: Bool = true,
                      completion: (() -> Void)? = nil) {
        viewController.modalPresentationStyle = .overFullScreen
        navigationController?.present(viewController,
                                      animated: animated,
                                      completion: completion)
    }

    func dismissChildCoordinatorWithAnimator(transitionType: CATransitionType = .push,
                                             transitionSubtype: CATransitionSubtype,
                                             completion: (() -> Void)? = nil) {
        navigationController?.dismiss(transitionType: transitionType, transitionSubtype: transitionSubtype, completion: completion)
        _ = childCoordinators.popLast()
    }

    func dismissChildCoordinator(animated: Bool = true, completion: (() -> Void)? = nil) {
        navigationController?.dismiss(animated: animated, completion: completion)
        _ = childCoordinators.popLast()
    }

    func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        navigationController?.dismiss(animated: animated, completion: completion)
    }

    func back(animated: Bool = true) {
        navigationController?.popViewController(animated: animated)
    }

    /// Backs or dismisses according to parent and number of view controllers.
    func leave(animated: Bool = true) {
        let isTheOnlyViewController = (navigationController?.viewControllers.count == 1) == true

        if isTheOnlyViewController {
            parentCoordinator?.dismissChildCoordinator(animated: animated)
        } else {
            back(animated: animated)
        }
    }

    func back(_ number: Int, animated: Bool = true) {
        if let viewControllers: [UIViewController] = navigationController?.viewControllers,
           viewControllers.count > number {
            navigationController?.popToViewController(viewControllers[viewControllers.count - number], animated: animated)
        }
    }

    func back(to vcIndex: Int, animated: Bool = true) {
        guard let viewControllers = navigationController?.viewControllers else { return }
        if vcIndex < viewControllers.count - 1 {
            navigationController?.popToViewController(viewControllers[vcIndex], animated: animated)
        } else {
            navigationController?.popViewController(animated: animated)
        }
    }

    func backToRoot(animated: Bool = true) {
        navigationController?.popToRootViewController(animated: animated)
    }

    func push(_ viewController: UIViewController, animated: Bool = true) {
        navigationController?.pushViewController(viewController, animated: animated)
        if AppUtils.isLayoutGridAuthorized {
            LayoutGridView().overlay(on: viewController)
        }
    }

    func presentPopup(_ viewController: UIViewController, animated: Bool = true) {
        navigationController?.visibleViewController?.present(viewController, animated: animated, completion: nil)
    }

    func presentModallyCoordinatorWithAnimator(childCoordinator: Coordinator, completion: (() -> Void)? = nil) {
        presentCoordinatorWithAnimator(childCoordinator: childCoordinator,
                                       transitionType: .moveIn,
                                       transitionSubtype: .fromBottom,
                                       completion: completion)
    }

    func presentCoordinatorWithAnimator(childCoordinator: Coordinator,
                                        transitionType: CATransitionType = .push,
                                        transitionSubtype: CATransitionSubtype = .fromRight,
                                        completion: (() -> Void)? = nil) {
        childCoordinator.parentCoordinator = self
        childCoordinator.start()
        childCoordinators.append(childCoordinator)

        guard let childNavController = childCoordinator.navigationController else {
            return
        }

        // Prevents not fullscreen presentation style since iOS 13.
        childNavController.modalPresentationStyle = .fullScreen

        navigationController?.present(childNavController,
                                      transitionType: transitionType,
                                      transitionSubtype: transitionSubtype,
                                      completion: completion)

        if AppUtils.isLayoutGridAuthorized {
            LayoutGridView().overlay(on: childNavController)
        }
    }

    func presentCoordinatorsStack(coordinators: [Coordinator],
                                  transitionType: CATransitionType = .push,
                                  transitionSubtype: CATransitionSubtype = .fromRight,
                                  snapshotView: UIView? = nil,
                                  completion: (() -> Void)? = nil) {
        guard let coordinator = coordinators.first else { return }

        let coordinatorsStack = Array(coordinators.dropFirst())
        guard !coordinatorsStack.isEmpty else {
            // Last coordinator of the list => call final transition.
            presentCoordinatorWithAnimator(childCoordinator: coordinator,
                                           transitionType: transitionType,
                                           transitionSubtype: transitionSubtype) {
                // Remove snapshot from previous recursive call.
                snapshotView?.removeFromSuperview()
                coordinator.navigationController?.transitioningDelegate = nil
                completion?()
            }
            return
        }

        // Start coordinator.
        coordinator.parentCoordinator = self
        coordinator.start()
        guard let childNavController = coordinator.navigationController else { return }
        childCoordinators.append(coordinator)
        childNavController.modalPresentationStyle = .fullScreen

        // Add a snapshot of currently rendered screen in order to avoid any visual glitch
        // during transition controllers presentation.
        let newSnapshotView = navigationController?.view.snapshotView(afterScreenUpdates: false)
        childNavController.view.addSubview(newSnapshotView)

        navigationController?.present(childNavController, animated: false) {
            // Remove snapshot from previous recursive call.
            snapshotView?.removeFromSuperview()
            coordinator.presentCoordinatorsStack(coordinators: coordinatorsStack,
                                                 transitionType: transitionType,
                                                 transitionSubtype: transitionSubtype,
                                                 snapshotView: newSnapshotView,
                                                 completion: completion)
        }
    }

    func dismissModallyCoordinatorWithAnimator(completion: (() -> Void)? = nil) {
        dismissCoordinatorWithAnimator(transitionType: .reveal,
                                       transitionSubtype: .fromTop,
                                       completion: completion)
    }

    func dismissCoordinatorWithAnimator(transitionType: CATransitionType = .push,
                                        transitionSubtype: CATransitionSubtype = .fromLeft,
                                        completion: (() -> Void)? = nil) {
        parentCoordinator?.dismissChildCoordinatorWithAnimator(transitionType: transitionType,
                                                               transitionSubtype: transitionSubtype,
                                                               completion: completion)
    }

    func popToRootCoordinator(coordinator: Coordinator?) {
        if let newParentCoordinator = coordinator?.parentCoordinator {
            _ = childCoordinators.popLast()
            popToRootCoordinator(coordinator: newParentCoordinator)
        } else {
            coordinator?.dismissChildCoordinator()
        }
    }

    func popToRootCoordinatorWithAnimator(coordinator: Coordinator?,
                                          isPresentedCoordinator: Bool = true,
                                          transitionType: CATransitionType = .push,
                                          transitionSubtype: CATransitionSubtype = .fromLeft,
                                          completion: (() -> Void)? = nil) {
        guard let newParentCoordinator = coordinator?.parentCoordinator else {
            coordinator?.dismissChildCoordinatorWithAnimator(transitionType: transitionType, transitionSubtype: transitionSubtype, completion: completion)
            return
        }

        if isPresentedCoordinator {
            // Recursive call of `popToRootCoordinator` requires to be aware of currenlty
            // displayed VC. Destination view of current dismissal will indeed also be source
            // view of next recursive pop, and would therefore lead to transition inconsistency.
            // => Animate only top coordinator source view.
            newParentCoordinator.navigationController?.animatedViews = .src
            newParentCoordinator.navigationController?.transitionType = transitionType
            newParentCoordinator.navigationController?.transitionSubtype = transitionSubtype
            newParentCoordinator.navigationController?.presentedViewController?.transitioningDelegate = newParentCoordinator.navigationController
        }

        // Recursive call in order to reach root coordinator.
        popToRootCoordinatorWithAnimator(coordinator: newParentCoordinator,
                                         isPresentedCoordinator: false,
                                         transitionType: transitionType,
                                         transitionSubtype: transitionSubtype) {
            // Release child coordinators.
            newParentCoordinator.childCoordinators.removeAll()
            completion?()
        }
    }
}

// MARK: - Transitions
// TODO: Implement transitions classes
public extension Coordinator {
    func navigationControllerTransition(_ type: CATransitionType,
                                        direction animationDirection: CATransitionSubtype) -> CATransition {
        let transition = CATransition()
        transition.duration = Style.shortAnimationDuration
        transition.type = type
        transition.subtype = animationDirection
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        return transition
    }

    func navigationControllerPushTransition(direction animationDirection: CATransitionSubtype) -> CATransition {
        return navigationControllerTransition(.push, direction: animationDirection)
    }

    func navigationControllerMoveInTransition(direction animationDirection: CATransitionSubtype) -> CATransition {
        return navigationControllerTransition(.moveIn, direction: animationDirection)
    }

    func applyTransition(_ transition: CATransition,
                         to navigationController: NavigationController?) {
        navigationController?.view.window?.layer.add(transition,
                                                     forKey: kCATransition)
    }

    func applyTransition(type: CATransitionType,
                         direction animationDirection: CATransitionSubtype,
                         to navigationController: NavigationController?) {
        let transition  = navigationControllerTransition(type, direction: animationDirection)
        applyTransition(transition, to: navigationController)
    }

    func applyPushTransition(with animationDirection: CATransitionSubtype,
                             to navigationController: NavigationController?) {
        applyTransition(type: .push,
                        direction: animationDirection,
                        to: navigationController)
    }

    func applyMoveInTransition(with animationDirection: CATransitionSubtype,
                               to navigationController: NavigationController?) {
        applyTransition(type: .moveIn,
                        direction: animationDirection,
                        to: navigationController)
    }

    func firstCoordinator<CoordType>(ofType coordinatorType: CoordType.Type) -> CoordType? {
        var coordinator: Coordinator? = self
        while coordinator != nil,
              coordinator as? CoordType == nil {
            coordinator = coordinator?.parentCoordinator
        }
        return coordinator as? CoordType
    }
}
