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

/// Coordinator for Settings part.
public final class SettingsCoordinator: Coordinator {
    // MARK: - Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public weak var parentCoordinator: Coordinator?

    // This optional parameter allows to start settings view controller on a specific type of settings.
    var startSettingType: SettingsType?

    // MARK: - Public Funcs
    public func start() {
        let viewController = SettingsViewController.instantiate(coordinator: self, settingType: startSettingType)
        navigationController = NavigationController(rootViewController: viewController)
        navigationController?.isNavigationBarHidden = true
    }

    /// Dismisses settings.
    func dismissSettings() {
        if parentCoordinator is DashboardCoordinator {
            leave()
        } else {
            dismissCoordinatorWithAnimator()
        }
    }

    /// Starts banked turn setting info.
    func startSettingInfoBankedTurn() {
        let viewController = SettingsInfoViewController.instantiate(coordinator: self, infoType: .bankedTurn)
        presentModal(viewController: viewController)
    }

    /// Starts horizontal gimbal setting info.
    func startSettingInfoHorizontal() {
        let viewController = SettingsInfoViewController.instantiate(coordinator: self, infoType: .horizonLine)
        presentModal(viewController: viewController)
    }

    /// Starts drone password edition.
    ///
    /// - Parameters:
    ///    - viewModel: Settings network viewModel
    func startSettingDronePasswordEdition(viewModel: SettingsNetworkViewModel?) {
        let viewController = SettingsPasswordEditionViewController.instantiate(
            coordinator: self,
            viewModel: viewModel,
            orientation: .all)
        presentModal(viewController: viewController)
    }

    /// Starts DRI info screen.
    func startDriInfoScreen() {
        let viewController = SettingsDRIViewController.instantiate(coordinator: self)
        presentModal(viewController: viewController)
    }

    /// Starts DRI edition screen.
    func startDriEdition(viewModel: SettingsNetworkViewModel) {
        let viewController = EditionDRIViewController.instantiate(coordinator: self,
                                                                  viewModel: viewModel)
        presentModal(viewController: viewController)
    }

    /// Starts public key edition screen.
    func startPublicKeyEdition(viewModel: SettingsDeveloperViewModel) {
        let viewController = EditionPublicKeyViewController.instantiate(coordinator: self,
                                                                        viewModel: viewModel)
        presentModal(viewController: viewController)
    }
}
