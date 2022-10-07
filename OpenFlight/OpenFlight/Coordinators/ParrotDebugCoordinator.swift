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

/// Coordinator for Parrot Debug part.
open class ParrotDebugCoordinator: Coordinator {
    // MARK: - Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public weak var parentCoordinator: Coordinator?

    public unowned var services: ServiceHub

    public init(services: ServiceHub) {
        self.services = services
    }

    // MARK: - Public Funcs
    open func start() {
        let viewModel = ParrotDebugViewModel()
        let viewController = ParrotDebugViewController.instantiate(coordinator: self, viewModel: viewModel)
        // Prevents not fullscreen presentation style since iOS 13.
        viewController.modalPresentationStyle = .fullScreen
        navigationController = NavigationController(rootViewController: viewController)
        navigationController?.isNavigationBarHidden = true
        navigationController?.modalPresentationStyle = .fullScreen
    }

    /// Shows custom mission debug screen
    open func showCustomMissionDebug() {}
}

// MARK: - Parrot Debug Navigation
extension ParrotDebugCoordinator {
    /// Shows DevToolbox screen.
    func showDevToolbox() {
        let controller = StoryboardScene.DevToolbox.devToolboxViewController.instantiate()
        navigationController?.isNavigationBarHidden = false
        push(controller)
    }

    /// Shows photogrammetry debug screen.
    func showPhotogrammetryDebug() {
        if let dashboardCoordinator = self.parentCoordinator as? DashboardCoordinator {
            dashboardCoordinator.startPhotogrammetryDebug()
        }
    }
}
