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

import Foundation

/// Coordinator for ophtalmo.
open class OphtalmoCoordinator: Coordinator {
    // MARK: - Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public weak var parentCoordinator: Coordinator?

    public let services: ServiceHub

    public init(services: ServiceHub) {
        self.services = services
    }

    // MARK: - Public Funcs
    public func start() {
        let viewModel = StereoCalibrationViewModel(coordinator: self,
                                                   connectedDroneHolder: services.connectedDroneHolder,
                                                   ophtalmoService: services.drone.ophtalmoService,
                                                   handLaunchService: services.drone.handLaunchService)
        let controller = StereoCalibrationViewController.instantiate(viewModel: viewModel)
        navigationController = NavigationController(rootViewController: controller)
        navigationController?.isNavigationBarHidden = true
    }

    /// Starts settings coordinator.
    ///
    /// - Parameters:
    ///     - type: settings type
    open func startSettings(_ type: SettingsType?) {
        let settingsCoordinator = SettingsCoordinator(services: services)
        settingsCoordinator.startSettingType = type
        presentCoordinatorWithAnimator(childCoordinator: settingsCoordinator)
    }
}
