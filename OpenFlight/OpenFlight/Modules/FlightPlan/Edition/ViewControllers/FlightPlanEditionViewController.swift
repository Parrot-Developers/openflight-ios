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
public protocol FlightPlanEditionViewControllerDelegate: EditionSettingsDelegate {
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
    @IBOutlet private weak var okButton: UIButton! {
        didSet {
            okButton.makeup(with: .large, color: .greenSpring)
            okButton.backgroundColor = ColorName.greenPea.color
            okButton.applyCornerRadius(Style.largeCornerRadius)
            okButton.setTitle(L10n.ok.uppercased(), for: .normal)
        }
    }
    @IBOutlet private weak var editionSettingsContainer: UIView!
    @IBOutlet private weak var topBarContainer: UIView!
    @IBOutlet private var allIntefaceViews: [UIView]!
    @IBOutlet private weak var settingsLeadConstraint: NSLayoutConstraint!
    @IBOutlet private weak var okButtonTopConstraint: NSLayoutConstraint!

    // MARK: - Private Properties
    private weak var coordinator: FlightPlanEditionCoordinator?
    private weak var mapViewController: MapViewController?
    private weak var mapViewRestorer: MapViewRestorer?
    private var droneStateViewModel = DroneStateViewModel<DeviceConnectionState>()
    private var settingsPanelWidth: CGFloat {
        return self.view.frame.width * Constants.settingsPanelWidthMultiplier
    }
    private var settingsAlwaysDisplayed: Bool = false
    private var settingsDisplayed: Bool = false
    private var flightPlanListener: FlightPlanListener?
    private weak var flightPlanViewModel: FlightPlanViewModel?
    private weak var editionSettingsViewController: EditionSettingsViewController?
    private weak var bottomBarViewController: FlightPlanEditionBottomBarViewController?
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

    // MARK: - Private Enums
    private enum Constants {
        static let settingsPanelWidthMultiplier: CGFloat = 175.0 / 640.0
        static let okButtonTopConstraint: CGFloat = 15.0
    }

    /// Enum which stores messages to log.
    private enum EventLoggerConstants {
        static let screenMessage: String = "FlightPlan/Editor"
    }

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
        viewController.settingsAlwaysDisplayed = flightPlanProvider?.settingsAlwaysDisplayed ?? false
        viewController.settingsDisplayed = viewController.settingsAlwaysDisplayed

        return viewController
    }

    // MARK: - Deinit
    deinit {
        FlightPlanManager.shared.unregister(flightPlanListener)
        flightPlanViewModel?.unregisterGraphicTapListener(graphicTapListener)
        flightPlanViewModel?.unregisterCourseModificationListener(courseModificationListener)
        mapViewController?.flightPlanOverlay?.deselectAllGraphics()
    }

    // MARK: - Override Funcs
    override public func viewDidLoad() {
        super.viewDidLoad()

        if let mapView = mapViewController?.view {
            mapContainer.addWithConstraints(subview: mapView)
        }

        setDroneStateViewModel()
        initSettingsPanel()

        flightPlanListener = FlightPlanManager.shared.register { [weak self] flightPlanViewModel in
            self?.flightPlanViewModel?.unregisterGraphicTapListener(self?.graphicTapListener)
            self?.flightPlanViewModel?.unregisterCourseModificationListener(self?.courseModificationListener)
            self?.flightPlanViewModel = flightPlanViewModel

            if let type = flightPlanViewModel?.state.value.type {
                self?.globalSettingsProvider?.updateType(key: type)
                self?.editionSettingsViewController?.updateDataSource(with: self?.settingsProvider, savedFlightPlan: flightPlanViewModel?.flightPlan)
            }

            self?.graphicTapListener = flightPlanViewModel?.registerGraphicTapListener(didChange: { [weak self] graphic in
                self?.handleFlightPlanItemSelection(graphic)
            })

            self?.courseModificationListener = flightPlanViewModel?.registerCourseModificationListener {
                guard self?.settingsDisplayed == true else { return }

                self?.editionSettingsViewController?.refreshEstimationsIfNeeded()
            }
        }
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        logScreen(logMessage: EventLoggerConstants.screenMessage)
    }

    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let topBarVc = segue.destination as? HUDTopBarViewController {
            topBarVc.context = .flightPlanEdition
        } else if let bottomBarVc = segue.destination as? FlightPlanEditionBottomBarViewController {
            bottomBarViewController = bottomBarVc
            bottomBarVc.delegate = self
            bottomBarVc.showUndo = settingsProvider?.hasCustomType == true
            bottomBarVc.showSettingsButton = !settingsAlwaysDisplayed
        } else if let settingsEditionVc = segue.destination as? EditionSettingsViewController {
            settingsEditionVc.settingsProvider = settingsProvider
            settingsEditionVc.savedFlightPlan = flightPlanViewModel?.flightPlan
            settingsEditionVc.delegate = self
            editionSettingsViewController = settingsEditionVc
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
                                                        savedFlightPlan: nil)
        openSettings()
    }
}

// MARK: - Actions
private extension FlightPlanEditionViewController {
    @IBAction func okButtonTouchedUpInside(_ sender: Any) {
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
}

// MARK: - Private Funcs
private extension FlightPlanEditionViewController {
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
        self.okButtonTopConstraint.constant = isDroneConnected ? 0.0 : Constants.okButtonTopConstraint
        self.editionSettingsViewController?.updateTopTableViewConstraint(isDroneConnected: isDroneConnected)
    }

    /// Inits edition settings view.
    func initSettingsPanel() {
        settingsLeadConstraint.constant = settingsAlwaysDisplayed ? settingsPanelWidth : 0.0
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
    func handleFlightPlanItemSelection(_ graphic: FlightPlanGraphic) {
        if let selectedPoiPointGraphic = selectedGraphic as? FlightPlanPoiPointGraphic,
           let wayPointGraphic = graphic as? FlightPlanWayPointGraphic {
            // During point of interest edition, a tap on a waypoint toggles their relation.
            mapViewController?.flightPlanOverlay?.toggleRelation(between: wayPointGraphic,
                                                                 and: selectedPoiPointGraphic)
            mapViewController?.updateFlightPlanOverlaysIfNeeded()
        } else if graphic == selectedGraphic {
            // Tap on current selection removes it and closes settings.
            closeSettings()
        } else if let insertWayPointGraphic = graphic as? FlightPlanInsertWayPointGraphic {
            insertWayPoint(with: insertWayPointGraphic)
        } else {
            // Tap on another selectable graphic replaces selection.
            deselectCurrentGraphic()
            selectGraphic(graphic)
        }
    }

    /// Inserts a waypoint with given graphic.
    ///
    /// - Parameters:
    ///    - graphic: graphic for waypoint insertion
    func insertWayPoint(with graphic: FlightPlanInsertWayPointGraphic) {
        guard let mapPoint = graphic.mapPoint,
              let index = graphic.itemIndex,
              let wayPoint = flightPlanViewModel?.flightPlan?.plan.insertWayPoint(with: mapPoint,
                                                                                      at: index) else {
            return
        }

        // Update overlays.
        mapViewController?.flightPlanOverlay?.insertWayPoint(wayPoint,
                                                             at: index)
        mapViewController?.flightPlanLabelsOverlay?.insertWayPoint(wayPoint,
                                                                   at: index)
        deselectCurrentGraphic()
        mapViewController?.updateArrows()

        // Close settings.
        closeSettings()
    }

    /// Select a graphic and display
    func selectGraphic(_ graphic: FlightPlanGraphic) {
        mapViewController?.flightPlanOverlay?.updateGraphicSelection(graphic,
                                                                     isSelected: true)
        selectedGraphic = graphic
        showItemEdition()
    }

    /// Shows item edition for given graphical item.
    func showItemEdition() {
        self.editionSettingsViewController?.updateDataSource(with: self.settingsProvider,
                                                             savedFlightPlan: nil)

        openSettings()
    }

    /// Opens settings panel.
    func openSettings() {
        guard !settingsDisplayed else { return }

        self.editionSettingsViewController?.refreshEstimationsIfNeeded()
        self.bottomBarViewController?.showSettingsButton = false
        self.settingsLeadConstraint.constant = settingsPanelWidth
        self.settingsDisplayed = true
        self.view.layoutIfNeeded()
    }

    /// Closes settings panel.
    func closeSettings() {
        guard settingsDisplayed else { return }

        deselectCurrentGraphic()

        guard settingsAlwaysDisplayed == false else { return }

        self.bottomBarViewController?.showSettingsButton = true
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
        }

        selectedGraphic = nil
        editionSettingsViewController?.updateDataSource(with: globalSettingsProvider,
                                                        savedFlightPlan: flightPlanViewModel?.flightPlan)
    }
}

// MARK: - FlightPlanEditionBottomBarViewControllerDelegate
extension FlightPlanEditionViewController: FlightPlanEditionBottomBarViewControllerDelegate {
    func centerMap() {
        mapViewController?.centerMapOnDroneOrUser()
    }

    func showManagePlans() {
        FlightPlanManager.shared.persistCurrentFlightPlan()
        updateInterfaceVisibility(isHidden: true)
        coordinator?.startManagePlans()
    }

    func showHistory(flightPlanViewModel: FlightPlanViewModel?) {
        coordinator?.startFlightPlanHistory(flightPlanViewModel: flightPlanViewModel)
    }

    func didTapSettingsButton() {
        openSettings()
    }

    func didTapOnUndo() {
        mapViewController?.didTapOnUndo()
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
    public func updateMode(tag: Int) {
        settingsProvider?.updateType(tag: tag)
        mapViewController?.editionDelegate?.updateMode(tag: tag)
        editionSettingsViewController?.updateDataSource(with: settingsProvider, savedFlightPlan: flightPlanViewModel?.flightPlan)
    }

    public func updateChoiceSetting(for key: String?, value: Bool) {
        guard let strongKey = key else { return }

        settingsProvider?.updateChoiceSetting(for: strongKey, value: value)
        mapViewController?.editionDelegate?.updateChoiceSetting(for: strongKey, value: value)
    }

    public func updateSettingValue(for key: String?, value: Int) {
        guard let strongKey = key else { return }

        if let selectedGraphic = selectedGraphic,
           let index = selectedGraphic.itemIndex {
            let altitude = Double(value)

            switch selectedGraphic {
            case is FlightPlanWayPointGraphic:
                mapViewController?.flightPlanOverlay?.updateWayPointAltitude(at: index, altitude: altitude)
                mapViewController?.flightPlanLabelsOverlay?.updateWayPointAltitude(at: index, altitude: altitude)
            case is FlightPlanPoiPointGraphic:
                mapViewController?.flightPlanOverlay?.updatePoiPointAltitude(at: index, altitude: altitude)
                mapViewController?.flightPlanLabelsOverlay?.updatePoiPointAltitude(at: index, altitude: altitude)
            default:
                break
            }
        }

        settingsProvider?.updateSettingValue(for: strongKey, value: value)
        mapViewController?.editionDelegate?.updateSettingValue(for: strongKey, value: value)
    }

    public func didTapCloseButton() {
        closeSettings()
    }

    public func didTapDeleteButton() {
        if globalSettingsProvider?.hasCustomType == true {
            mapViewController?.didDeleteCorner()
        } else if let index = selectedGraphic?.itemIndex {
            switch selectedGraphic {
            case is FlightPlanWayPointGraphic:
                currentFlightPlan?.removeWaypoint(at: index)
                self.mapViewController?.flightPlanOverlay?.removeWayPoint(at: index)
                self.mapViewController?.flightPlanLabelsOverlay?.removeWayPoint(at: index)
            case is FlightPlanPoiPointGraphic:
                currentFlightPlan?.removePoiPoint(at: index)
                self.mapViewController?.flightPlanOverlay?.removePoiPoint(at: index)
                self.mapViewController?.flightPlanLabelsOverlay?.removePoiPoint(at: index)
            default:
                break
            }
            self.mapViewController?.updateArrows()
        }

        closeSettings()
    }
}
