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

// MARK: - Protocols
public protocol FlightPlanEditionViewControllerDelegate: class {
    /// Starts flight plan edition mode.
    func startFlightPlanEdition()

    /// Starts a new flight plan.
    ///
    /// - Parameters:
    ///    - flightPlanProvider: flight plan provider
    ///    - completion: call back that returns if a flight plan have been created
    func startNewFlightPlan(flightPlanProvider: FlightPlanProvider, creationCompletion: @escaping (_ createNewFp: Bool) -> Void)
}

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
    private weak var mapViewController: MapViewController?
    private weak var mapViewRestorer: MapViewRestorer?
    private var droneStateViewModel = DroneStateViewModel<DeviceConnectionState>()
    private var settingsDisplayed: Bool = false
    private var flightPlanListener: FlightPlanListener?
    private weak var flightPlanViewModel: FlightPlanViewModel? {
        didSet {
            flightPlanEditionMenuViewController?.flightPlanViewModel = flightPlanViewModel
        }
    }
    private weak var editionSettingsViewController: EditionSettingsViewController?
    private weak var flightPlanEditionMenuViewController: FlightPlanEditionMenuViewController?
    private var currentFlightPlan: FlightPlanObject? {
        return flightPlanViewModel?.flightPlan?.plan
    }
    private var settingsProvider: FlightPlanSettingsProvider? {
        guard let selectedGraphic = selectedGraphic else {
            return globalSettingsProvider
        }

        switch selectedGraphic {
        case let wayPointGraphic as FlightPlanWayPointGraphic:
            return wayPointGraphic.wayPoint?.settingsProvider
        case let poiPointGraphic as FlightPlanPoiPointGraphic:
            return poiPointGraphic.poiPoint?.settingsProvider
        case let wayPointLineGraphic as FlightPlanWayPointLineGraphic:
            return wayPointLineGraphic.destinationWayPoint?.segmentSettingsProvider
        default:
            return nil
        }
    }
    private var globalSettingsProvider: FlightPlanSettingsProvider?
    private var selectedGraphic: FlightPlanGraphic?
    private weak var graphicTapListener: GraphicTapListener?
    private weak var courseModificationListener: FlightPlanCourseModificationListener?
    private weak var povModificationListener: FlightPlanPointOfViewModificationListener?

    // MARK: - Setup
    /// Instantiate the view controller.
    ///
    /// - Parameters:
    ///    - coordinator: flight plan edition coordinator
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
                                   mapViewController: MapViewController?,
                                   mapViewRestorer: MapViewRestorer?,
                                   flightPlanProvider: FlightPlanProvider?) -> FlightPlanEditionViewController {
        let viewController = StoryboardScene.FlightPlanEdition.initialScene.instantiate()
        viewController.coordinator = coordinator
        viewController.mapViewController = mapViewController
        viewController.mapViewController?.setMapMode(.flightPlanEdition)
        viewController.mapViewRestorer = mapViewRestorer
        viewController.globalSettingsProvider = flightPlanProvider?.settingsProvider

        return viewController
    }

    // MARK: - Deinit
    deinit {
        FlightPlanManager.shared.unregister(flightPlanListener)
        flightPlanViewModel?.unregisterGraphicTapListener(graphicTapListener)
        flightPlanViewModel?.unregisterCourseModificationListener(courseModificationListener)
        flightPlanViewModel?.unregisterPOVModificationListener(povModificationListener)
        mapViewController?.flightPlanOverlay?.deselectAllGraphics()
    }

    // MARK: - Override Funcs
    override public func viewDidLoad() {
        super.viewDidLoad()

        if let mapView = mapViewController?.view {
            mapContainer.addWithConstraints(subview: mapView)
        }
        FlightPlanManager.shared.resetUndoStack()
        setDroneStateViewModel()

        flightPlanListener = FlightPlanManager.shared.register { [weak self] flightPlanViewModel in
            self?.flightPlanViewModel?.unregisterGraphicTapListener(self?.graphicTapListener)
            self?.flightPlanViewModel?.unregisterCourseModificationListener(self?.courseModificationListener)
            self?.flightPlanViewModel?.unregisterPOVModificationListener(self?.povModificationListener)
            self?.flightPlanViewModel = flightPlanViewModel

            if let type = flightPlanViewModel?.state.value.type {
                self?.globalSettingsProvider?.updateType(key: type)
                self?.editionSettingsViewController?.updateDataSource(with: self?.settingsProvider,
                                                                      savedFlightPlan: flightPlanViewModel?.flightPlan,
                                                                      selectedGraphic: self?.selectedGraphic)
            }

            self?.graphicTapListener = flightPlanViewModel?.registerGraphicTapListener(didChange: { [weak self] graphic in
                self?.handleFlightPlanItemSelection(graphic)
            })

            self?.courseModificationListener = flightPlanViewModel?.registerCourseModificationListener {
                flightPlanViewModel?.updateEstimations()
                FlightPlanManager.shared.appendUndoStack(with: flightPlanViewModel?.flightPlan)
                self?.flightPlanEditionMenuViewController?.refreshContent()
                if self?.settingsDisplayed == true {
                    self?.editionSettingsViewController?.refreshContent(categoryFilter: nil)
                }
            }

            self?.povModificationListener = flightPlanViewModel?.registerPOVModificationListener {
                FlightPlanManager.shared.appendUndoStack(with: flightPlanViewModel?.flightPlan)
                self?.flightPlanEditionMenuViewController?.refreshContent()
            }
        }
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
            settingsEditionVc.settingsProvider = settingsProvider
            settingsEditionVc.savedFlightPlan = flightPlanViewModel?.flightPlan
            settingsEditionVc.delegate = self
            editionSettingsViewController = settingsEditionVc
        } else if let menuViewController = segue.destination as? FlightPlanEditionMenuViewController {
            menuViewController.menuDelegate = self
            menuViewController.settingsDelegate = self
            menuViewController.settingsProvider = settingsProvider
            flightPlanEditionMenuViewController = menuViewController
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
    /// Show corner item edition.
    func showCornerEdition() {
        editionSettingsViewController?.updateDataSource(with: nil,
                                                        savedFlightPlan: nil,
                                                        selectedGraphic: FlightPlanGraphic())
        openSettings()
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
    /// End flight plan edition.
    func endEdition() {
        // Update flight plan informations.
        self.flightPlanViewModel?.updatePolygonPoints(points: mapViewController?.polygonPoints() ?? [])
        self.flightPlanViewModel?.updateFlightPlanExtraData()

        // Restore map back to its original container, then dismiss.
        mapViewController?.setMapMode(.standard)
        mapViewController?.editionViewClosed()
        mapViewRestorer?.restoreMapIfNeeded()
        mapViewController?.flightPlanEditionViewController = nil
        coordinator?.dismissFlightPlanEdition()
    }

    /// Sets up drone state view model.
    func setDroneStateViewModel() {
        droneStateViewModel.state.valueChanged = { [weak self] state in
            self?.updateUI(isDroneConnected: state.isConnected())
        }

        self.updateUI(isDroneConnected: droneStateViewModel.state.value.isConnected())
    }

    /// Updates the UI when the drone connection state changes.
    ///
    /// - Parameters:
    ///    - isDroneConnected: specify if the drone is connected
    func updateUI(isDroneConnected: Bool) {
        self.topBarContainer.isHidden = !isDroneConnected
        let topBarHeight = self.topBarContainterHeightConstraint.constant
        let height: CGFloat = isDroneConnected ? topBarHeight : 0.0
        self.editionSettingsViewController?.updateTopTableViewConstraint(height)
        self.flightPlanEditionMenuViewController?.updateTopTableViewConstraint(height)
    }

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
        if let selectedPoiPointGraphic = selectedGraphic as? FlightPlanPoiPointGraphic,
           let wayPointGraphic = graphic as? FlightPlanWayPointGraphic {
            // During point of interest edition, a tap on a waypoint toggles their relation.
            mapViewController?.flightPlanOverlay?.toggleRelation(between: wayPointGraphic,
                                                                 and: selectedPoiPointGraphic)
            mapViewController?.updateFlightPlanOverlaysIfNeeded()
            FlightPlanManager.shared.appendUndoStack(with: flightPlanViewModel?.flightPlan)
        } else if graphic == selectedGraphic {
            // Tap on current selection removes it and closes settings.
            closeSettings()
        } else if let insertWayPointGraphic = graphic as? FlightPlanInsertWayPointGraphic {
            insertWayPoint(with: insertWayPointGraphic)
            FlightPlanManager.shared.appendUndoStack(with: flightPlanViewModel?.flightPlan)
            flightPlanEditionMenuViewController?.refreshContent()
        } else if let graphic = graphic, graphic.itemType.selectable {
            deselectCurrentGraphic()
            selectGraphic(graphic)
        } else {
            closeSettings()
        }
    }

    /// Inserts a waypoint with given graphic.
    ///
    /// - Parameters:
    ///    - graphic: graphic for waypoint insertion
    func insertWayPoint(with graphic: FlightPlanInsertWayPointGraphic) {
        guard let mapPoint = graphic.mapPoint,
              let index = graphic.targetIndex,
              let wayPoint = flightPlanViewModel?.flightPlan?.plan.insertWayPoint(with: mapPoint,
                                                                                  at: index) else {
            return
        }

        // Update overlays.
        let wayPointGraphic = mapViewController?.flightPlanOverlay?.insertWayPoint(wayPoint,
                                                                                   at: index)
        mapViewController?.flightPlanLabelsOverlay?.insertWayPoint(wayPoint,
                                                                   at: index)
        deselectCurrentGraphic()
        mapViewController?.updateArrows()

        // Close settings.
        if let wpGraphic = wayPointGraphic {
            self.flightPlanViewModel?.didTapGraphicalItem(wpGraphic)
        } else {
            closeSettings()
        }
    }

    /// Select a graphic and display
    func selectGraphic(_ graphic: FlightPlanGraphic) {
        mapViewController?.flightPlanOverlay?.updateGraphicSelection(graphic,
                                                                     isSelected: true)
        mapViewController?.flightPlanLabelsOverlay?.updateGraphicSelection(graphic,
                                                                           isSelected: true)
        selectedGraphic = graphic
        showItemEdition()
    }

    /// Shows item edition for given graphical item.
    func showItemEdition() {
        self.editionSettingsViewController?.updateDataSource(with: self.settingsProvider,
                                                             savedFlightPlan: nil,
                                                             selectedGraphic: selectedGraphic)

        openSettings()
    }

    /// Opens settings panel.
    func openSettings(categoryFilter: FlightPlanSettingCategory? = nil) {
        guard !settingsDisplayed else { return }

        self.editionSettingsViewController?.refreshContent(categoryFilter: categoryFilter)
        self.settingsLeadConstraint.constant = editionSettingsContainer.frame.width
        self.settingsDisplayed = true
        self.view.layoutIfNeeded()
    }

    /// Closes settings panel.
    func closeSettings() {
        guard settingsDisplayed else { return }

        deselectCurrentGraphic()

        self.settingsLeadConstraint.constant = 0.0
        self.settingsDisplayed = false
        self.view.layoutIfNeeded()
    }

    /// Deselects currently selected graphic.
    func deselectCurrentGraphic() {
        if globalSettingsProvider?.hasCustomType == true {
            mapViewController?.didFinishCornerEdition()
        }

        if let graphic = selectedGraphic {
            mapViewController?.flightPlanOverlay?.updateGraphicSelection(graphic,
                                                                         isSelected: false)
            mapViewController?.flightPlanLabelsOverlay?.updateGraphicSelection(graphic,
                                                                               isSelected: false)
        }

        selectedGraphic = nil
        editionSettingsViewController?.updateDataSource(with: globalSettingsProvider,
                                                        savedFlightPlan: flightPlanViewModel?.flightPlan,
                                                        selectedGraphic: selectedGraphic)
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
    public func didTapOnUndo() {
        undoAction()
    }

    public func updateMode(tag: Int) {
        settingsProvider?.updateType(tag: tag)
        mapViewController?.settingsDelegate?.updateMode(tag: tag)
        editionSettingsViewController?.updateDataSource(with: settingsProvider,
                                                        savedFlightPlan: flightPlanViewModel?.flightPlan,
                                                        selectedGraphic: selectedGraphic)

        FlightPlanManager.shared.appendUndoStack(with: flightPlanViewModel?.flightPlan)
        flightPlanEditionMenuViewController?.refreshContent()
    }

    public func updateChoiceSetting(for key: String?, value: Bool) {
        guard let strongKey = key else { return }

        settingsProvider?.updateChoiceSetting(for: strongKey, value: value)
        mapViewController?.settingsDelegate?.updateChoiceSetting(for: strongKey, value: value)

        FlightPlanManager.shared.appendUndoStack(with: flightPlanViewModel?.flightPlan)

        editionSettingsViewController?.updateDataSource(with: self.settingsProvider,
                                                        savedFlightPlan: self.flightPlanViewModel?.flightPlan,
                                                        selectedGraphic: selectedGraphic)
    }

    public func updateSettingValue(for key: String?, value: Int) {
        guard let strongKey = key else { return }

        if let selectedGraphic = selectedGraphic {
            let altitude = Double(value)

            switch selectedGraphic {
            case let wayPointGraphic as FlightPlanWayPointGraphic:
                if let index = wayPointGraphic.wayPointIndex {
                    mapViewController?.flightPlanOverlay?.updateWayPointAltitude(at: index, altitude: altitude)
                    mapViewController?.flightPlanLabelsOverlay?.updateWayPointAltitude(at: index, altitude: altitude)
                }
            case let poiPointGraphic as FlightPlanPoiPointGraphic:
                if let index = poiPointGraphic.poiIndex {
                    mapViewController?.flightPlanOverlay?.updatePoiPointAltitude(at: index, altitude: altitude)
                    mapViewController?.flightPlanLabelsOverlay?.updatePoiPointAltitude(at: index, altitude: altitude)
                }
            default:
                break
            }
        }

        settingsProvider?.updateSettingValue(for: strongKey, value: value)
        mapViewController?.settingsDelegate?.updateSettingValue(for: strongKey, value: value)

        FlightPlanManager.shared.appendUndoStack(with: flightPlanViewModel?.flightPlan)

        editionSettingsViewController?.updateDataSource(with: self.settingsProvider,
                                                        savedFlightPlan: flightPlanViewModel?.flightPlan,
                                                        selectedGraphic: selectedGraphic)
    }

    public func didTapCloseButton() {
        closeSettings()
        flightPlanEditionMenuViewController?.refreshContent()
    }

    public func didTapDeleteButton() {
        if globalSettingsProvider?.hasCustomType == true {
            mapViewController?.didDeleteCorner()
        } else {
            switch selectedGraphic {
            case let wayPointGraphic as FlightPlanWayPointGraphic:
                if let index = wayPointGraphic.wayPointIndex {
                    self.mapViewController?.removeWayPoint(at: index)
                }
            case let poiPointGraphic as FlightPlanPoiPointGraphic:
                if let index = poiPointGraphic.poiIndex {
                    self.mapViewController?.removePOI(at: index)
                }
            default:
                break
            }
            self.mapViewController?.updateArrows()
        }

        flightPlanEditionMenuViewController?.refreshContent()

        closeSettings()
    }
}

// MARK: - FlightPlanEditionMenuDelegate
extension FlightPlanEditionViewController: FlightPlanEditionMenuDelegate {
    public func doneEdition() {
        endEdition()
    }

    public func undoAction() {
        mapViewController?.didTapOnUndo()
        editionSettingsViewController?.updateDataSource(with: self.settingsProvider,
                                                        savedFlightPlan: self.flightPlanViewModel?.flightPlan,
                                                        selectedGraphic: selectedGraphic)
    }

    public func showSettings(category: FlightPlanSettingCategory) {
        openSettings(categoryFilter: category)
    }

    public func showProjectManager() {
        FlightPlanManager.shared.persistCurrentFlightPlan()
        updateInterfaceVisibility(isHidden: true)
        coordinator?.startManagePlans()
    }

    public func showHistory() {
        if let flightPlanViewModel = flightPlanViewModel {
            coordinator?.startFlightPlanHistory(flightPlanViewModel: flightPlanViewModel)
        }
    }
}
