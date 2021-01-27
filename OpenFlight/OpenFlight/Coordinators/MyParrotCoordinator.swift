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

/// Coordinator for My Parrot screens.

final class MyParrotCoordinator: Coordinator {
    // MARK: - Properties
    var navigationController: NavigationController?
    var childCoordinators = [Coordinator]()
    var parentCoordinator: Coordinator?

    // MARK: - Public funcs
    func start() {
        let viewController = MyParrotBaseViewController.instantiate(coordinator: self)
        self.navigationController = NavigationController(rootViewController: viewController)
        self.navigationController?.isNavigationBarHidden = true
        // Prevents not fullscreen presentation style since iOS 13.
        self.navigationController?.modalPresentationStyle = .fullScreen
    }
}

// MARK: - MyParrotNavigation
extension MyParrotCoordinator {

    /// Used to come back to previous screen.
    func dismissMyParrot() {
        self.parentCoordinator?.dismissChildCoordinator()
    }

    /// Used to enter in Login screen.
    func startLogin() {
        let controller = MyParrotLoginViewController.instantiate(coordinator: self)
        self.navigationController?.push(controller)
    }

    /// Used to enter in Profile screen.
    func startProfile() {
        let controller = MyParrotProfileViewController.instantiate(coordinator: self)
        self.navigationController?.push(controller)
    }
}
