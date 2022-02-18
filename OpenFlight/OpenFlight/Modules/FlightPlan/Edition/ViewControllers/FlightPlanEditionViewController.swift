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
                                   backButtonPublisher: AnyPublisher<Void, Never>) -> FlightPlanEditionViewController {
        let viewController = StoryboardScene.FlightPlanEdition.initialScene.instantiate()
        viewController.viewModel = FlightPlanEditionViewModel(
            settingsProvider: flightPlanProvider?.settingsProvider,
            edition: flightPlanServices.edition,
            projectManager: flightPlanServices.projectManager,
            topBarService: Services.hub.ui.hudTopBarService)
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
        viewModel.$viewState
            .compactMap({ $0 })
            .sink { [unowned self] state in
                switch state {
                case .closeSettings:
                    closeSettings()
                case .showItemEdition:
                    showItemEdition()
                case .updateConstraint:
                    UIView.animate(withDuration: Style.shortAnimationDuration) {
                        settingsLeadConstraint.constant = editionSettingsContainer.frame.width
                        view.layoutIfNeeded()
                    }
                case .settingsLeadConstraint:
                    UIView.animate(withDuration: Style.shortAnimationDuration) {
                        settingsLeadConstraint.constant = 0.0
                        view.layoutIfNeeded()
                    }
                }
            }
            .store(in: &cancellables)

        backButtonPublisher?.sink { [unowned self] in
            reset()
        }.store(in: &cancellables)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Services.hub.ui.hudTopBarService.forbidTopBarDisplay()
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

    private func exitEdition() {
        navigationController?.popViewController(animated: true)
        mapViewController?.splitControls?.hideBottomBar(hide: false)
        mapViewController?.splitControls?.hideCameraSliders(hide: false)
        mapViewController?.flightPlanEditionViewControllerBackButton.isHidden = true
    }

    private func reset() {
        panelCoordinator?.resetPopupConfirmation { [unowned self] in
            viewModel.reset()
            exitEdition()
        }
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

    /// Closes settings panel.
    func closeSettings() {
        viewModel.closeSettings()
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
