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
//

import Combine
import ArcGIS

// MARK: - Protocols
public protocol MapViewEditionControllerDelegate: AnyObject {
    var polygonPointsValue: [AGSPoint] { get }

    /// Inserts way point on map controller.
    ///
    /// - Parameters:
    ///    - wayPoint: Waypoint
    ///    - index: position on array
    func insertWayPoint(_ wayPoint: WayPoint, index: Int) -> FlightPlanWayPointGraphic?

    /// Toggles relation betewwn waypoint and pointGraphic on map.
    ///
    /// - Parameters:
    ///    - wayPointGraphic: waypoint
    ///    - selectedPoiPointGraphic: poi point graphic
    func toggleRelation(between wayPointGraphic: FlightPlanWayPointGraphic,
                        and selectedPoiPointGraphic: FlightPlanPoiPointGraphic)

    /// Updates elevation visibility.
    func updateVisibility()

    /// Updates graphic selection.
    ///
    /// - Parameters:
    ///    - graphic: flight plan graphic
    ///    - isSelected: boolean
    func updateGraphicSelection(_ graphic: FlightPlanGraphic, isSelected: Bool)

    /// Updates mode settings at sspecific tag.
    ///
    /// - Parameters:
    ///    - tag: Integer
    func updateModeSettings(tag: Int)

    /// Updates altitude of poi Point.
    ///
    /// - Parameters:
    ///    - index: Integer
    ///    - altitude: double that determine new altitude
    func updatePoiPointAltitude(at index: Int, altitude: Double)

    /// Updates altitude of wayPoint.
    ///
    /// - Parameters:
    ///    - index: Integer
    ///    - altitude: double that determine new altitude
    func updateWayPointAltitude(at index: Int, altitude: Double)

    /// Notifys finishing of edition on corner.
    func didFinishCornerEditionMode()

    /// Removes wayPoint at sepecific index.
    ///
    /// - Parameters:
    ///    - index: Integer
    func removeWayPoint(at index: Int)

    /// Removes poi at sepecific index.
    ///
    /// - Parameters:
    ///    - index: Integer
    func removePOI(at index: Int)

    /// Notifys when delete corner.
    func didTapDeleteCorner()

    /// Updates settings with new choice.
    ///
    /// - Parameters:
    ///    - key: determine name of new choice
    ///    - value: determine `Bool` of new choice
    func updateChoiceSettings(for key: String?, value: Bool)

    /// Updates settings with new value.
    ///
    /// - Parameters:
    ///    - key: determine name of new choice
    ///    - value: determine `Int` of new choice
    func updateSettingsValue(for key: String?, value: Int)

    /// finishs edition
    func endEdition()

    /// Restor map on the original container when finish updating.
    func restoreMapToOriginalContainer()

    /// Last manually selected graphic object.
    func lastManuallySelectedGraphic()

    /// Deselects all graphics objects.
    func deselectAllGraphics()

    /// Comes back to previous modifications
    func undoAction()

    func displayFlightPlan(_ flightPlan: FlightPlanModel, shouldReloadCamera: Bool)
}

// MARK: - Protocols
public protocol FlightEditionDelegate: AnyObject {

    /// Notifys tap on graphic item.
    ///
    /// - Parameters:
    ///    - graphic: optionel flight plan graphic
    func didTapGraphicalItem(_ graphic: FlightPlanGraphic?)

    /// Notifys change Point on view.
    func didChangePointOfView()

    /// Notifys change course on view.
    func didChangeCourse()

    func reset()
}

// MARK: - FlightPlanEditionViewModel
public class FlightPlanEditionViewModel {
    /// The view state reflecting current subject value. Private setter.
    private(set) var viewState: ViewState? {
        get { viewStateSubject.value }
        set { viewStateSubject.value = newValue }
    }
    /// The view state publisher.
    var viewStatePublisher: AnyPublisher<ViewState?, Never> { viewStateSubject.eraseToAnyPublisher() }

    // MARK: - Private Properties
    private var edition: FlightPlanEditionService!
    private var projectManager: ProjectManager!
    private let topBarService: HudTopBarService
    private let navigationStack: NavigationStackService
    private weak var panelCoordinator: FlightPlanPanelCoordinator?
    private var settingsDisplayed: Bool = false
    private var flightPlanEditionMenuViewModel: FlightPlanEditionMenuViewModel?
    private(set) var editionSettingsViewModel: EditionSettingsViewModel?
    private(set) var selectedGraphic: FlightPlanGraphic?
    private var globalSettingsProvider: FlightPlanSettingsProvider?
    private var cancellables = [AnyCancellable]()
    /// The view state subject.
    private let viewStateSubject = CurrentValueSubject<ViewState?, Never>(nil)

    // MARK: - Public Properties
    weak var mapDelegate: MapViewEditionControllerDelegate?
    var settingsProvider: FlightPlanSettingsProvider? {
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

    var hasFlightPlanObject: Bool {
        guard let dataSettings = edition.currentFlightPlanValue?.dataSetting else { return false }
        let hasWaPoints = !dataSettings.wayPoints.isEmpty
        let hasTakeOfAction = !dataSettings.takeoffActions.isEmpty
        let hasPois = !dataSettings.pois.isEmpty
        return (hasWaPoints || hasTakeOfAction || hasPois )
    }

    /// Whether the current Flight Plan has been edited from his initial state.
    var hasChanges: Bool { edition.hasChanges }

    init(settingsProvider: FlightPlanSettingsProvider?,
         edition: FlightPlanEditionService,
         projectManager: ProjectManager,
         topBarService: HudTopBarService,
         navigationStack: NavigationStackService,
         panelCoordinator: FlightPlanPanelCoordinator) {
        self.globalSettingsProvider = settingsProvider
        self.edition = edition
        self.projectManager = projectManager
        self.topBarService = topBarService
        self.navigationStack = navigationStack
        self.panelCoordinator = panelCoordinator
        edition.currentFlightPlanPublisher
            .sink(receiveValue: { [unowned self] flightPlan in
                guard let flightPlan = flightPlan else { return }
                self.globalSettingsProvider?.updateType(key: flightPlan.pictorModel.flightPlanType)
                self.flightPlanEditionMenuViewModel?.updateModel(flightPlan)
                guard editionSettingsViewModel?.settingsCategoryFilter != .custom(L10n.flightPlanSegmentSettingsTitle) else {
                    closeSettings()
                    return
                }
                self.editionSettingsViewModel?.updateDataSource(with: self.settingsProvider,
                                                                savedFlightPlan: flightPlan,
                                                                selectedGraphic: self.selectedGraphic)
            })
            .store(in: &cancellables)
    }

    // MARK: - Public Funcs
    func selecteGraphic(_ graphic: FlightPlanGraphic) {
        mapDelegate?.updateGraphicSelection(graphic,
                                            isSelected: true)
        selectedGraphic = graphic
        viewState = .showItemEdition
    }

    private func updateUndoStack() {
        edition.appendCurrentStateToUndoStack()
        refreshMenuViewModel()
    }
}

// MARK: - FlightPlanEditionViewModel
/// Communication with child viewModel `EditionSettingsViewModel`
extension FlightPlanEditionViewModel {

    func updateSettingViewModel() -> EditionSettingsViewModel? {
        editionSettingsViewModel = EditionSettingsViewModel(editionService: edition)
        return editionSettingsViewModel
    }

    func refreshContentSettings(categoryFilter: FlightPlanSettingCategory?) {
        editionSettingsViewModel?.refreshContent(categoryFilter: categoryFilter)

        guard !settingsDisplayed else { return }

        settingsDisplayed = true
        viewState = .updateConstraint
    }

    func updateSettingsDataSource() {
        editionSettingsViewModel?.updateDataSource(with: settingsProvider,
                                                   savedFlightPlan: edition.currentFlightPlanValue,
                                                   selectedGraphic: selectedGraphic)
    }

    public func updateSettingValue(for key: String?, value: Int) {
        guard let strongKey = key else { return }

        if let selectedGraphic = selectedGraphic,
           key == AltitudeSettingType().key {
            let altitude = Double(value)

            switch selectedGraphic {
            case let wayPointGraphic as FlightPlanWayPointGraphic:
                if let index = wayPointGraphic.wayPointIndex {
                    mapDelegate?.updateWayPointAltitude(at: index, altitude: altitude)
                }
            case let poiPointGraphic as FlightPlanPoiPointGraphic:
                if let index = poiPointGraphic.poiIndex {
                    mapDelegate?.updatePoiPointAltitude(at: index, altitude: altitude)
                }
            default:
                break
            }
        }

        settingsProvider?.updateSettingValue(for: strongKey, value: value)
        mapDelegate?.updateSettingsValue(for: strongKey, value: value)

        editionSettingsViewModel?.updateDataSource(with: settingsProvider,
                                                   savedFlightPlan: edition.currentFlightPlanValue,
                                                   selectedGraphic: selectedGraphic)

        // do not propagate settings updates in the undo stack for other types of FPs.
        guard currentFlightPlanModel()?.pictorModel.flightPlanType == ClassicFlightPlanType.standard.key else {
            return
        }
        if selectedGraphic != nil {
            edition.appendCurrentStateToUndoStack()
        } else {
            edition.updateGlobalSettings(with: edition.currentFlightPlanValue?.dataSetting)
        }
    }

    public func updateChoiceSetting(for key: String?, value: Bool) {
        guard let strongKey = key else { return }

        settingsProvider?.updateChoiceSetting(for: strongKey, value: value)
        mapDelegate?.updateChoiceSettings(for: strongKey, value: value)

        editionSettingsViewModel?.updateDataSource(with: settingsProvider,
                                                   savedFlightPlan: edition.currentFlightPlanValue,
                                                   selectedGraphic: selectedGraphic)

        // do not propagate settings updates in the undo stack for other types of FPs.
        guard currentFlightPlanModel()?.pictorModel.flightPlanType == ClassicFlightPlanType.standard.key else {
            return
        }
        if selectedGraphic != nil {
            edition.appendCurrentStateToUndoStack()
        } else {
            edition.updateGlobalSettings(with: edition.currentFlightPlanValue?.dataSetting)
        }
    }

    public func currentFlightPlanModel() -> FlightPlanModel? {
        edition.currentFlightPlanValue
    }
}

// MARK: - FlightPlanEditionViewModel
/// Communication with child viewModel `FlightPlanEditionMenuViewModel`
extension FlightPlanEditionViewModel {

    func updateEditionMenuViewModel() -> FlightPlanEditionMenuViewModel? {
        if flightPlanEditionMenuViewModel == nil {
            flightPlanEditionMenuViewModel = FlightPlanEditionMenuViewModel(editionService: edition,
                                                                            panelCoordinator: panelCoordinator,
                                                                            projectManager: projectManager)
        }
        flightPlanEditionMenuViewModel?.updateModel(currentFlightPlanModel())
        return flightPlanEditionMenuViewModel
    }

    func refreshMenuViewModel() {
        flightPlanEditionMenuViewModel?.refreshContent()
    }

    /// Show custom graphic item edition.
    ///
    /// - Parameters:
    ///    - graphic: graphic to display in edition
    func showCustomGraphicEdition(_ graphic: EditableAGSGraphic) {
        editionSettingsViewModel?.updateDataSource(with: nil,
                                                   savedFlightPlan: nil,
                                                   selectedGraphic: graphic)
    }

    func canUndo() -> Bool {
        return edition.canUndo()
    }

    func undoAction() {
        mapDelegate?.undoAction()
        editionSettingsViewModel?.updateDataSource(with: settingsProvider,
                                                   savedFlightPlan: currentFlightPlanModel(),
                                                   selectedGraphic: selectedGraphic)
        flightPlanEditionMenuViewModel?.refreshContent()
    }

    public func resetUndoStack() {
        edition.resetUndoStack()
    }

    /// Restore the previous Flight Plan settings.
    public func reset() {
        // Ensure there is a project to reset.
        guard let project = projectManager.currentProject else {
            // Restore map back to its original container.
            mapDelegate?.restoreMapToOriginalContainer()
            return
        }
        // Check if the project freshly created.
        if projectManager.isCurrentProjectBrandNew {
            // User leave the edition of a new project without editing it: remove it.
            projectManager.delete(project: project) { [weak self] _ in
                guard let self = self else {
                    return
                }
                // Return to the previous view if needed.
                self.returnToPreviousView()
                // Restore map back to its original container.
                self.mapDelegate?.restoreMapToOriginalContainer()
            }
        } else if let flightPlan = projectManager.editableFlightPlan(for: project) {
            // reload last state of flightPlan that contains no modifications.
            edition.setupFlightPlan(flightPlan)
            edition.resetUndoStack()
            mapDelegate?.displayFlightPlan(flightPlan, shouldReloadCamera: false)
            // Restore map back to its original container.
            mapDelegate?.restoreMapToOriginalContainer()
        }
    }

    public func didTapDeleteButton() {
        if globalSettingsProvider?.hasCustomType == true {
            mapDelegate?.didTapDeleteCorner()
        } else {
            switch selectedGraphic {
            case let wayPointGraphic as FlightPlanWayPointGraphic:
                if let index = wayPointGraphic.wayPointIndex {
                    mapDelegate?.removeWayPoint(at: index)
                }
            case let poiPointGraphic as FlightPlanPoiPointGraphic:
                if let index = poiPointGraphic.poiIndex {
                    mapDelegate?.removePOI(at: index)
                }
            default:
                break
            }
            refreshMenuViewModel()
        }
    }

    /// Deselects currently selected graphic.
    func deselectCurrentGraphic() {
        if globalSettingsProvider?.hasCustomType == true {
            mapDelegate?.didFinishCornerEditionMode()
        }

        if let graphic = selectedGraphic {
            mapDelegate?.updateGraphicSelection(graphic,
                                                isSelected: false)
        }

        selectedGraphic = nil
        editionSettingsViewModel?.updateDataSource(with: globalSettingsProvider,
                                                   savedFlightPlan: edition.currentFlightPlanValue,
                                                   selectedGraphic: selectedGraphic)
    }

    public func updateMode(tag: Int) {
        settingsProvider?.updateType(tag: tag)
        mapDelegate?.updateModeSettings(tag: tag)
        editionSettingsViewModel?.updateDataSource(with: settingsProvider,
                                                   savedFlightPlan: edition.currentFlightPlanValue,
                                                   selectedGraphic: selectedGraphic)

        refreshMenuViewModel()
    }

    /// Handles selection of a new item from map.
    ///
    /// - Parameters:
    ///    - graphics: selected graphics collection
    func handleFlightPlanItemSelection(_ graphic: FlightPlanGraphic?) {
        if let selectedPoiPointGraphic = selectedGraphic as? FlightPlanPoiPointGraphic,
           let wayPointGraphic = graphic as? FlightPlanWayPointGraphic {
            // During point of interest edition, a tap on a waypoint toggles their relation.
            mapDelegate?.toggleRelation(between: wayPointGraphic,
                                        and: selectedPoiPointGraphic)
            mapDelegate?.updateVisibility()
            edition.appendCurrentStateToUndoStack()
        } else if graphic == selectedGraphic {
            // Tap on current selection removes it and closes settings.
            viewState = .closeSettings
        } else if let insertWayPointGraphic = graphic as? FlightPlanInsertWayPointGraphic {
            insertWayPoint(with: insertWayPointGraphic)
            updateUndoStack()
        } else if let graphic = graphic, graphic.itemType.selectable {
            deselectCurrentGraphic()
            selecteGraphic(graphic)
        } else {
            viewState = .closeSettings
        }
    }

    /// Inserts a waypoint with given graphic.
    ///
    /// - Parameters:
    ///    - graphic: graphic for waypoint insertion
    func insertWayPoint(with graphic: FlightPlanInsertWayPointGraphic) {
        guard let mapPoint = graphic.mapPoint,
              let index = graphic.targetIndex,
              let wayPoint = edition?.insertWayPoint(with: mapPoint, at: index)
        else {
            return
        }

        // Deselect line.
        deselectCurrentGraphic()

        // Update overlays.
        let wayPointGraphic = mapDelegate?.insertWayPoint(wayPoint, index: index)

        // Close settings.
        if let wpGraphic = wayPointGraphic {
            handleFlightPlanItemSelection(wpGraphic)
        } else {
            viewState = .closeSettings
        }
    }

    /// End flight plan edition.
    func endEdition() {
        // Update flight plan informations.
        projectManager.isCurrentProjectBrandNew = false
        edition?.updatePolygonPoints(points: mapDelegate?.polygonPointsValue ?? [])
        refreshMenuViewModel()
        if settingsDisplayed {
            editionSettingsViewModel?.refreshContent()
        }
        let mapDelegate = self.mapDelegate
        edition?.endEdition {
            // Restore map back to its original container, then dismiss.
            mapDelegate?.restoreMapToOriginalContainer()
        }
    }

    func closeSettings() {
        guard settingsDisplayed else { return }

        mapDelegate?.lastManuallySelectedGraphic()

        deselectCurrentGraphic()

        settingsDisplayed = false
        viewState = .settingsLeadConstraint
    }

    func deselectAllGraphics() {
        mapDelegate?.deselectAllGraphics()
    }

    enum ViewState {
        case closeSettings
        case showItemEdition
        case updateConstraint
        case settingsLeadConstraint
    }
}

// MARK: Private methods
private extension FlightPlanEditionViewModel {

    /// Allows to return in the needed state after a cancelled edition.
    /// In some cases (e.g. cancelling a project creation), exiting the edition mode is not sufficient, we need to return to previous view.
    private func returnToPreviousView() {
        // Ensure there the navigation stack is not empty.
        // If the creation has been initiated via the HUD, we don't want to leave it.
        guard !navigationStack.stack.isEmpty else {
            // If there is no selected project, this means it was a "First creation". Just stay in HUD.
            guard projectManager.currentProject != nil else { return }
            // In oter cases, we come from the HUD's project manager: Re-open it.
            panelCoordinator?.startManagePlans()
            return
        }

        // remove selected project of project manager in stack because it has been deleted.
        navigationStack.updateLast(with: .projectManager(selectedProject: nil))

        // Ask the HUD's top bar to leave the view.
        topBarService.goBack()
    }
}

// MARK: - FlightEditionDelegate
// Communicate with map view Controller
extension FlightPlanEditionViewModel: FlightEditionDelegate {
    public func didTapGraphicalItem(_ graphic: FlightPlanGraphic?) {
        handleFlightPlanItemSelection(graphic)
    }

    public func didChangePointOfView() {
        updateUndoStack()

        // Update the edition service's modifiedFlightPlan to handle changes.
        if let flightPlan = edition.currentFlightPlanValue {
            edition.updateModifiedFlightPlan(with: flightPlan)
        }
    }

    public func didChangeCourse() {
        /// TODO update estimation
        //        self.estimations = edition.currentFlightPlanValue?.dataSetting?.estimations ?? FlightPlanEstimationsModel()
        updateUndoStack()
        if settingsDisplayed {
            editionSettingsViewModel?.refreshContent()
        }

        // Update the edition service's modifiedFlightPlan to handle changes.
        if let flightPlan = edition.currentFlightPlanValue {
            edition.updateModifiedFlightPlan(with: flightPlan)
        }
    }
}
