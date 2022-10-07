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
import ArcGIS
import Combine

/// Manages flight plan edition view.
public class FlightPlanEditionViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var editionSettingsContainer: UIView!
    @IBOutlet private weak var settingsLeadConstraint: NSLayoutConstraint!

    // MARK: - Private Properties
    private weak var panelCoordinator: FlightPlanPanelCoordinator?
    public var menuCoordinator: FlightPlanEditionMenuCoordinator?
    public var editionSettingsCoordinator: EditionSettingsCoordinator?
    private weak var mapViewController: MapViewController?
    private var cancellables = [AnyCancellable]()
    private var viewModel: FlightPlanEditionViewModel!
    private var hasFlightPlanObject: Bool {
        viewModel.hasFlightPlanObject
    }
    private var backButtonPublisher: AnyPublisher<Void, Never>?

    // MARK: - Setup
    /// Instantiate the view controller.
    ///
    /// - Parameters:
    ///    - panelCoordinator: flight plan panel coordinator
    ///    - mapViewController: controller for the map
    ///    - flightPlanProvider: flight plan provider
    ///    - backButtonPublisher: the back button publisher that is triggered when the user wants to
    ///      discard the current changes.
    /// - Returns: FlightPlanEditionViewController
    public static func instantiate(panelCoordinator: FlightPlanPanelCoordinator,
                                   flightPlanServices: FlightPlanServices,
                                   mapViewController: MapViewController?,
                                   flightPlanProvider: FlightPlanProvider?,
                                   navigationStack: NavigationStackService,
                                   backButtonPublisher: AnyPublisher<Void, Never>) -> FlightPlanEditionViewController {
        let viewController = StoryboardScene.FlightPlanEdition.initialScene.instantiate()
        viewController.viewModel = FlightPlanEditionViewModel(
            settingsProvider: flightPlanProvider?.settingsProvider,
            edition: flightPlanServices.edition,
            projectManager: flightPlanServices.projectManager,
            topBarService: Services.hub.ui.hudTopBarService,
            navigationStack: navigationStack,
            panelCoordinator: panelCoordinator)
        viewController.panelCoordinator = panelCoordinator
        viewController.mapViewController = mapViewController
        viewController.mapViewController?.setMapMode(.flightPlanEdition)
        viewController.viewModel.mapDelegate = mapViewController
        viewController.backButtonPublisher = backButtonPublisher
        mapViewController?.flightDelegate = viewController.viewModel
        panelCoordinator.flightPlanEditionViewController = viewController
        return viewController
    }

    // MARK: - Deinit
    deinit {
        viewModel.deselectAllGraphics()
    }

    // MARK: - Override Funcs
    override public func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }

    private func bindViewModel() {
        viewModel.viewStatePublisher
            .compactMap({ $0 })
            .sink { [unowned self] state in
                switch state {
                case .closeSettings:
                    closeSettings()
                case .showItemEdition:
                    showItemEdition()
                case .updateConstraint:
                    UIView.animate(withDuration: Style.shortAnimationDuration) { [weak self] in
                        guard let self = self else { return }
                        self.settingsLeadConstraint.constant = self.editionSettingsContainer.frame.width
                        self.view.layoutIfNeeded()
                    }
                case .settingsLeadConstraint:
                    UIView.animate(withDuration: Style.shortAnimationDuration) { [weak self] in
                        guard let self = self else { return }
                        self.settingsLeadConstraint.constant = 0.0
                        self.view.layoutIfNeeded()
                    }
                }
            }
            .store(in: &cancellables)

        // Listen to back button publisher.
        backButtonPublisher?.sink { [weak self] in
            guard let self = self else { return }
            if let viewState = self.viewModel.viewState,
               viewState != .closeSettings,
               viewState != .settingsLeadConstraint {
                // Edition view state differs from main panel.
                // => Close setting.
                self.closeSettings()
            } else {
                // Main panel => quit edition mode.
                self.reset()
            }
        }
        .store(in: &cancellables)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        LogEvent.log(.screen(LogEvent.Screen.flightPlanEditor))
    }

    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let topBarVc = segue.destination as? HUDTopBarViewController {
            topBarVc.context = .flightPlanEdition
        } else if segue.identifier == "EditionSettingsViewController",
                  let navigationController = segue.destination as? NavigationController,
                  let settingsEditionVc = navigationController.viewControllers.first as? EditionSettingsViewController {
            editionSettingsCoordinator = EditionSettingsCoordinator()
            let settingsViewModel = viewModel.updateSettingViewModel()
            editionSettingsCoordinator?.viewModel = settingsViewModel
            editionSettingsCoordinator?.flightPlanEditionViewController = self
            settingsEditionVc.delegate = self
            settingsEditionVc.viewModel = settingsViewModel
            settingsEditionVc.viewModel.settingsProvider = viewModel.settingsProvider
            settingsEditionVc.viewModel.savedFlightPlan = viewModel.currentFlightPlanModel()
            editionSettingsCoordinator?.start(navigationController: navigationController,
                                              parentCoordinator: panelCoordinator)
        } else if segue.identifier == "FlightPlanEditionMenuViewController",
                  let navigationController = segue.destination as? NavigationController,
                  let menuViewController = navigationController.viewControllers.first as? FlightPlanEditionMenuViewController {
            menuCoordinator = FlightPlanEditionMenuCoordinator()
            menuViewController.menuDelegate = self
            menuViewController.settingsDelegate = self
            menuViewController.settingsProvider = viewModel.settingsProvider
            menuViewController.viewModel = viewModel.updateEditionMenuViewModel()
            menuCoordinator?.start(navigationController: navigationController,
                                   parentCoordinator: panelCoordinator)
        }
    }

    override public var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override public var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - Public Funcs
    /// Show custom graphic item edition.
    ///
    /// - Parameters:
    ///    - graphic: graphic to display in edition
    func showCustomGraphicEdition(_ graphic: EditableAGSGraphic) {
        viewModel.showCustomGraphicEdition(graphic)
        openSettings()
    }

    /// End flight plan edition.
    func endEdition() {
        // Update flight plan informations.
        viewModel.endEdition()
        // update UI
        exitEdition()
    }

    /// Closes settings panel.
    public func closeSettings() {
        // Close building height picker if needed.
        // This is required in order to prevent picker from being presented on
        // non-PGY settings panels (e.g. `.image`, `.rth`…).
        editionSettingsCoordinator?.dismissBuildingHeightPickerIfNeeded(closeSettings: false)
        viewModel.closeSettings()
    }

    private func exitEdition() {
        navigationController?.popViewController(animated: true)
        panelCoordinator?.showHudControls(show: true)
    }

    private func reset() {
        // The block called when the editing mode is leaved without saving.
        let leaveWhitoutSave = { [weak self] in
            guard let self = self else { return }
            // Restore the previous Flight Plan settings.
            self.viewModel.reset()
            // Exit the edition mode.
            self.exitEdition()
        }

        // Check if FP has been edited.
        guard viewModel.hasChanges else {
            // No change made, just leave the editing mode.
            leaveWhitoutSave()
            return
        }

        let saveChanges = { [weak self] in
            guard let self = self else { return }
            self.viewModel.endEdition()
            self.exitEdition()
        }

        // User attempts to leave the view with pending changes.
        // A confirmation popup is shown asking to wants to save, abandon modifications, or stay in the editor.
        saveChangesPopup(leaveWithoutSave: leaveWhitoutSave, validate: saveChanges)
    }

    /// Shows alert asking if the user wants to save, not save or stay in the editor
    ///
    ///  - Parameters:
    ///    - leaveWithoutSave: executed when the user chooses to leave edition without saving
    ///    - validate: executed when the user chooses to save
    private func saveChangesPopup(leaveWithoutSave: @escaping () -> Void, validate: @escaping () -> Void) {
        let cancelAction = AlertAction(title: L10n.cancel,
                                       style: .default2) // do nothing, stay in the editor
        let validateAction = AlertAction(title: L10n.commonSave,
                                         style: .validate,
                                         actionHandler: validate)
        let secondaryAction = AlertAction(title: L10n.commonDoNotSave,
                                          style: .destructive,
                                          actionHandler: leaveWithoutSave)

        showAlert(title: L10n.flightPlanDiscardChangesTitle,
                  message: L10n.flightPlanDiscardChangesDescription,
                  cancelAction: cancelAction,
                  validateAction: validateAction,
                  secondaryAction: secondaryAction)
    }
}

// MARK: - Actions
private extension FlightPlanEditionViewController {
    @IBAction func okButtonTouchedUpInside(_ sender: Any) {
        endEdition()
    }
}

// MARK: - Private Funcs
private extension FlightPlanEditionViewController {

    /// Handles selection of a new item from map.
    ///
    /// - Parameters:
    ///    - graphics: selected graphics collection
    func handleFlightPlanItemSelection(_ graphic: FlightPlanGraphic?) {
        viewModel.handleFlightPlanItemSelection(graphic)
    }

    /// Inserts a waypoint with given graphic.
    ///
    /// - Parameters:
    ///    - graphic: graphic for waypoint insertion
    func insertWayPoint(with graphic: FlightPlanInsertWayPointGraphic) {
        viewModel.insertWayPoint(with: graphic)
    }

    /// Shows item edition for given graphical item.
    func showItemEdition() {
        viewModel.updateSettingsDataSource()
        openSettings()
    }

    /// Opens settings panel.
    func openSettings(categoryFilter: FlightPlanSettingCategory? = nil) {
        self.viewModel?.refreshContentSettings(categoryFilter: categoryFilter)
    }

    /// Deselects currently selected graphic.
    func deselectCurrentGraphic() {
        viewModel.deselectCurrentGraphic()
    }
}

// MARK: - EditionSettingsDelegate
extension FlightPlanEditionViewController: EditionSettingsDelegate {
    public func canUndo() -> Bool {
        viewModel.canUndo()
    }

    public func didTapOnUndo(action: (() -> Void)?) {
        undoAction()
    }

    public func updateMode(tag: Int) {
        viewModel.updateMode(tag: tag)
    }

    public func updateChoiceSetting(for key: String?, value: Bool) {
        viewModel.updateChoiceSetting(for: key, value: value)
    }

    public func updateSettingValue(for key: String?, value: Int) {
        viewModel.updateSettingValue(for: key, value: value)
    }

    public func isUpdatingSetting(for key: String?, isUpdating: Bool) {
        // nothing to do
    }

    public func didTapCloseButton() {
        closeSettings()
        viewModel.refreshMenuViewModel()
    }

    public func didTapDeleteButton() {
        viewModel.didTapDeleteButton()
        closeSettings()
    }
}

// MARK: - FlightPlanEditionMenuDelegate
extension FlightPlanEditionViewController: FlightPlanEditionMenuDelegate {
    public func resetUndoStack() {
        viewModel.resetUndoStack()
    }

    public func doneEdition(_ flightPlan: FlightPlanModel) {
        endEdition()
    }

    public func undoAction() {
        viewModel.undoAction()
    }

    public func showSettings(category: FlightPlanSettingCategory) {
        openSettings(categoryFilter: category)
    }

    public func showProjectManager() {
        panelCoordinator?.startManagePlans()
    }
}
