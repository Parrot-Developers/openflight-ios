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
import ArcGIS
import Combine

/// Manages flight plan edition view.
public class FlightPlanEditionViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var mapContainer: UIView!
    @IBOutlet private weak var editionSettingsContainer: UIView!
    @IBOutlet private weak var topBarContainer: UIView!
    @IBOutlet private weak var topBarContainterHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var allIntefaceViews: [UIView]!
    @IBOutlet private weak var settingsLeadConstraint: NSLayoutConstraint!

    // MARK: - Private Properties
    private weak var coordinator: FlightPlanEditionCoordinator?
    private weak var panelCoordinator: FlightPlanPanelCoordinator?
    private weak var mapViewController: MapViewController?
    private weak var mapViewRestorer: MapViewRestorer?
    private var cancellables = [AnyCancellable]()
    private var viewModel: FlightPlanEditionViewModel!
    private var hasFlightPlanObject: Bool {
        viewModel.hasFlightPlanObject
    }

    // MARK: - Setup
    /// Instantiate the view controller.
    ///
    /// - Parameters:
    ///    - coordinator: flight plan edition coordinator
    ///    - panelCoordinator: flight plan panel coordinator
    ///    - mapViewController: controller for the map
    ///    - mapViewRestorer: restorer for the map
    ///    - flightPlanProvider: flight plan provider
    /// - Returns: FlightPlanEditionViewController
    ///
    /// Note: these parameters are needed because, when entering
    /// Flight Plan edition, map view is transferred to the new
    /// view controller. Map is restored back to its original
    /// container afterwards with `MapViewRestorer` protocol.
    public static func instantiate(coordinator: FlightPlanEditionCoordinator,
                                   panelCoordinator: FlightPlanPanelCoordinator,
                                   flightPlanServices: FlightPlanServices,
                                   mapViewController: MapViewController?,
                                   mapViewRestorer: MapViewRestorer?,
                                   flightPlanProvider: FlightPlanProvider?) -> FlightPlanEditionViewController {
        let viewController = StoryboardScene.FlightPlanEdition.initialScene.instantiate()
        viewController.coordinator = coordinator
        viewController.viewModel = FlightPlanEditionViewModel(
            settingsProvider: flightPlanProvider?.settingsProvider,
            edition: flightPlanServices.edition,
            flightPlanProject: flightPlanServices.projectManager,
            topBarService: Services.hub.ui.hudTopBarService)
        viewController.panelCoordinator = panelCoordinator
        viewController.mapViewController = mapViewController
        viewController.mapViewController?.setMapMode(.flightPlanEdition)
        viewController.viewModel.mapDelegate = mapViewController
        mapViewController?.flightDelegate = viewController.viewModel
        viewController.mapViewRestorer = mapViewRestorer
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

        if let mapView = mapViewController?.view {
            mapContainer.addWithConstraints(subview: mapView)
        }
        bindViewModel()
    }

    private func bindViewModel() {
        viewModel.$viewState
            .compactMap({ $0 })
            .sink { [unowned self] state in
                switch state {
                case .closeSettings:
                    self.closeSettings()
                case .showItemEdition:
                    self.showItemEdition()
                case .updateConstraint:
                    self.settingsLeadConstraint.constant = editionSettingsContainer.frame.width
                    self.view.layoutIfNeeded()
                case .settingsLeadConstraint:
                    self.settingsLeadConstraint.constant = 0.0
                    self.view.layoutIfNeeded()
                }
            }
            .store(in: &cancellables)
        viewModel.showTopBarPublisher
            .sink { [weak self] in
                self?.topBarContainer.isHidden = !$0
            }
            .store(in: &cancellables)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.flightPlanEditor,
                             logType: .screen)
    }

    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let topBarVc = segue.destination as? HUDTopBarViewController {
            topBarVc.context = .flightPlanEdition
        } else if let settingsEditionVc = segue.destination as? EditionSettingsViewController {
            settingsEditionVc.delegate = self
            settingsEditionVc.viewModel = viewModel.updateSettingViewModel()
            settingsEditionVc.viewModel.settingsProvider = viewModel.settingsProvider
            settingsEditionVc.viewModel.savedFlightPlan = viewModel.currentFlightPlanModel()
        } else if let menuViewController = segue.destination as? FlightPlanEditionMenuViewController {
            menuViewController.menuDelegate = self
            menuViewController.settingsDelegate = self
            menuViewController.settingsProvider = viewModel.settingsProvider
            menuViewController.viewModel = viewModel.updateEditionMenuViewModel()
        }
    }

    override public var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
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

        // Restore map back to its original container, then dismiss.
        mapViewRestorer?.restoreMapIfNeeded()
        coordinator?.dismissFlightPlanEdition()
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

    /// Shows or hides the interface.
    ///
    /// - Parameters:
    ///    - isHidden: whether interface should be hidden
    func updateInterfaceVisibility(isHidden: Bool) {
        UIView.animate(withDuration: Style.shortAnimationDuration) {
            self.allIntefaceViews.forEach {
                $0.alphaHidden(isHidden)
            }
        }
    }

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

    /// Select a graphic and display
    func selectGraphic(_ graphic: FlightPlanGraphic) {
        viewModel.selecteGraphic(graphic)
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

// MARK: - OverContextModalDelegate
extension FlightPlanEditionViewController: OverContextModalDelegate {
    func willDismissModal() {
        updateInterfaceVisibility(isHidden: false)
    }
}

// MARK: - EditionSettingsDelegate
extension FlightPlanEditionViewController: EditionSettingsDelegate {
    public func canUndo() -> Bool {
        viewModel.canUndo()
    }

    public func didTapOnUndo() {
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
        updateInterfaceVisibility(isHidden: true)
        panelCoordinator?.startManagePlans()
    }
}
