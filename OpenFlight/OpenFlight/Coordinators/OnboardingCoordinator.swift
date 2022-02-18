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

import UIKit
import SwiftyUserDefaults

/// Coordinator for onboarding screens.
open class OnboardingCoordinator: Coordinator {
    // MARK: - Public Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public weak var parentCoordinator: Coordinator?

    public let hudCoordinatorProvider: () -> HUDCoordinator

    // MARK: - Init
    /// Initializes coordinator.
    ///
    /// - Parameters:
    ///    - navigationController: the navigation controller to use
    ///    - hudCoordinatorProvider: the provider used to get HUD coordinator
    public init(navigationController: NavigationController? = nil,
                hudCoordinatorProvider: @escaping () -> HUDCoordinator) {
        self.hudCoordinatorProvider = hudCoordinatorProvider
        self.navigationController = navigationController
    }

    // MARK: - Public Funcs
    /// Classical way to start the coordinator with root view.
    open func start() {
        // AUTO ACCEPT TERM OF USE FOR OPENFLIGHT
        Defaults[key: DefaultsKeys.areOFTermsOfUseAccepted] = true
        showOnBoardingThirdScreen()
    }

    /// Shows terms of use screen.
    ///
    /// - Parameters:
    ///    - filename: Terms of use file name
    ///    - termsOfUseKey: Terms of use key that refers to default bool.
    open func showTermsOfUseScreen(filename: String,
                                   termsOfUseKey: DefaultsKey<Bool>) {
        let viewController = OnboardingTermsOfUseViewController.instantiate(coordinator: self,
                                                                            fileName: filename,
                                                                            termsOfUseKey: termsOfUseKey)
        navigationController?.viewControllers = [viewController]
    }

    /// Shows screen after localization access.
    open func showOnBoardingThirdScreen() {
        showHUDScreen()
    }
}

// MARK: - Onboarding Navigation
extension OnboardingCoordinator {
    /// Shows HUD from onboarding.
    func showHUDScreen() {
        let hudCoordinator = hudCoordinatorProvider()
        hudCoordinator.parentCoordinator = self
        start(childCoordinator: hudCoordinator)
    }
}
