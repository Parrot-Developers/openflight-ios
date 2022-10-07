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

/// Coordinator for Flight Plan edition menu.
public final class EditionSettingsCoordinator: Coordinator {
    // MARK: - Public Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public weak var parentCoordinator: Coordinator?

    var viewModel: EditionSettingsViewModel?
    weak var flightPlanEditionViewController: FlightPlanEditionViewController?
    weak var buildingHeightPickerViewController: UIViewController?

    // MARK: - Public Funcs
    public func start() {
        assert(false) // Forbidden start
    }

    public func start(navigationController: NavigationController,
                      parentCoordinator: Coordinator?) {
        self.navigationController = navigationController
        self.parentCoordinator = parentCoordinator
        if let editionSettingsViewController = navigationController.viewControllers.first as? EditionSettingsViewController {
            editionSettingsViewController.coordinator = self
        }
    }

    /// Dismisses building height picker panel if needed.
    /// Also closes settings panel (on which building height picker is pushed) if required.
    ///
    /// - Parameter closeSettings: whether the settings panel should be closed (`true` by default)
    public func dismissBuildingHeightPickerIfNeeded(closeSettings: Bool = true) {
        guard buildingHeightPickerViewController != nil else { return }

        // Dismiss VC.
        back()
        buildingHeightPickerViewController = nil

        // Close settings panel if required.
        if closeSettings {
            flightPlanEditionViewController?.closeSettings()
        }
    }
}

extension EditionSettingsCoordinator {

    public func showBuildingHeightPicker(delegate: BuildingHeightMenuViewControllerDelagate) {
        if let viewController = navigationController?.topViewController as? BuildingHeightMenuViewController {
            viewController.viewModel = viewModel
            return
        }
        guard let viewModel = viewModel,
              let viewController = BuildingHeightMenuViewController
                .instantiate(viewModel: viewModel,
                             coordinator: self,
                             delegate: delegate) else {
                    return
                }
        navigationController?.pushViewController(viewController, animated: true)
        buildingHeightPickerViewController = viewController
    }
}
