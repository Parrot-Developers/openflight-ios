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
import Pictor

/// Coordinator for Project Manager.
public final class ProjectManagerCoordinator: Coordinator {
    // MARK: - Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public weak var parentCoordinator: Coordinator?

    private let flightPlanServices: FlightPlanServices
    private let synchroService: SynchroService?
    private let uiServices: UIServices
    private var defaultSelectedProject: ProjectModel?

    /// Whether project manager has been opened from HUD.
    /// (HUD and Dashboard navigation stack handling differ.)
    private var isOpenFromHud: Bool {
        parentCoordinator is FlightPlanPanelCoordinator
    }

    init(flightPlanServices: FlightPlanServices,
         uiServices: UIServices,
         synchroService: SynchroService?,
         defaultSelectedProject: ProjectModel? = nil) {
        self.flightPlanServices = flightPlanServices
        self.uiServices = uiServices
        self.synchroService = synchroService
        self.defaultSelectedProject = defaultSelectedProject
    }

    // MARK: - Public Funcs
    public func start() {
        let viewModel = ProjectManagerViewModel(coordinator: self,
                                                manager: flightPlanServices.projectManager,
                                                synchroService: synchroService,
                                                projectManagerUiProvider: uiServices.projectManagerUiProvider,
                                                flightPlanStateMachine: flightPlanServices.stateMachine,
                                                canSelectProjectType: !isOpenFromHud)

        let viewController = ProjectManagerViewController.instantiate(coordinator: self,
                                                                      viewModel: viewModel,
                                                                      defaultSelectedProject: defaultSelectedProject)
        viewController.modalPresentationStyle = .fullScreen
        navigationController = NavigationController(rootViewController: viewController)
        navigationController?.isNavigationBarHidden = true
    }

    /// Dismisses project manager.
    ///
    /// - Parameters:
    ///    - animated: Animate the dismiss coordinator action.
    ///    - completion: Completion block.
    func dismissProjectManager(animated: Bool = true,
                               completion: (() -> Void)? = nil) {
        // Navigation stack is not updated when opening project manager from HUD.
        // => Update stack only if relevant.
        if !isOpenFromHud {
            uiServices.navigationStack.removeLast()
        }
        parentCoordinator?.dismissChildCoordinator(animated: animated, completion: completion)
    }

    /// Shows the user's account view.
    func startAccountView() {
        guard let currentAccount = AccountManager.shared.currentAccount,
              let loginCoordinator = currentAccount.destinationCoordinator else {
                  return
              }

        loginCoordinator.parentCoordinator = self
        currentAccount.startMyFlightsAccountView()
        present(childCoordinator: loginCoordinator)
    }

    /// Shows delete project confirmation popup.
    ///
    /// - Parameters:
    ///    - didTapDelete: completion block called when user taps on delete button
    func showDeleteProjectPopupConfirmation(didTapDelete: @escaping () -> Void) {
        let deleteAction = AlertAction(title: L10n.commonDelete,
                                       style: .destructive,
                                       actionHandler: { didTapDelete() })
        let cancelAction = AlertAction(title: L10n.cancel,
                                       style: .default2,
                                       actionHandler: {})
        let alert = AlertViewController.instantiate(title: L10n.alertDeleteProjectTitle,
                                                    message: L10n.alertDeleteProjectMessage,
                                                    cancelAction: cancelAction,
                                                    validateAction: deleteAction)
        presentModal(viewController: alert)
    }

    /// Opens a Project/Flight Plan view.
    ///
    /// - Parameters:
    ///    - project: a flightPlan project
    ///    - startEdition: `true` to start edition once opened, `false` otherwise
    ///    - isBrandNew: indicates whether a project has just been created or duplicated
    func open(project: ProjectModel, startEdition: Bool, isBrandNew: Bool) {
        flightPlanServices.projectManager
            .loadEverythingAndOpen(project: project, isBrandNew: isBrandNew)

        if isOpenFromHud {
            // Project manager has been opened from HUD right panel.
            // => Only need to dismiss coordinator in order to show HUD.
            // (No navigation stack operation required.)
            parentCoordinator?.dismissChildCoordinator {
                if startEdition {
                    self.flightPlanServices.projectManager.startEdition()
                }
            }

            return
        }

        // Update the navigation stack with the selected project
        uiServices.navigationStack.updateLast(with: .projectManager(selectedProject: project))
        popToRootCoordinatorWithAnimator(coordinator: self,
                                         transitionSubtype: .fromRight) {
            if startEdition {
                self.flightPlanServices.projectManager.startEdition()
            }
        }
    }

    /// Opens the current loaded project.
    /// This method returns to the HUD without loading anything.
    func showCurrentProject() {
        popToRootCoordinatorWithAnimator(coordinator: self,
                                         transitionSubtype: .fromRight,
                                         completion: nil)
    }
}
