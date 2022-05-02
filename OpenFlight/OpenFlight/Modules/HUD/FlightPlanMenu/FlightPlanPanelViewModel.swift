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

import GroundSdk
import Combine

/// View model for flight plan menu.
final class FlightPlanPanelViewModel {

    @Published private(set) var buttonsState: ButtonsInformation = ButtonsInformation.defaultInfo

    @Published private(set) var titleProject: String?

    @Published private(set) var titleExecution: String?

    @Published private(set) var newButtonTitle: String?

    @Published private(set) var createFirstTitle: String?

    @Published private(set) var viewState: ViewState = .creation

    @Published private(set) var progressModel: FlightPlanPanelProgressModel?

    @Published private(set) var extraViews: [UIView] = []

    @Published private(set) var imageRate: ImageRateProvider?

    private weak var coordinator: FlightPlanPanelCoordinator?
    private weak var splitControls: SplitControls?

    // MARK: - Private Properties

    private var projectManager: ProjectManager
    private var currentMissionManager: CurrentMissionManager
    private var stateMachine: FlightPlanStateMachine?
    private(set) var runManager: FlightPlanRunManager

    /// Cancellables
    private var cancellables = Set<AnyCancellable>()
    private var stateMachineCancellable: AnyCancellable?

    // MARK: - Override Funcs
    init(projectManager: ProjectManager,
         runStateProgress: FlightPlanRunManager,
         currentMissionManager: CurrentMissionManager,
         coordinator: FlightPlanPanelCoordinator,
         splitControls: SplitControls) {
        self.projectManager = projectManager
        self.runManager = runStateProgress
        self.currentMissionManager = currentMissionManager
        self.coordinator = coordinator
        self.splitControls = splitControls
        listenMissionMode()
        listenProjectManager()
    }

    // MARK: - Internal Funcs
    /// Sends currently loaded flight plan to drone and starts it.
    func startFlightPlan() {
        stateMachine?.start()
    }

    /// Stops current running flight plan.
    func stopFlightPlan() {
        stateMachine?.stop()
    }

    func newFlightplan(flightPlanProvider: FlightPlanProvider) {
        projectManager.newProject(flightPlanProvider: flightPlanProvider) { [weak self] project in
            guard let project = project else { return }
            self?.projectManager.loadEverythingAndOpen(project: project, isBrandNew: true)
        }
    }

    func startEditionMode(_ centerMapOnDroneOrUser: Bool) {
        stateMachine?.forceEditable()
        coordinator?.startFlightPlanEdition(centerMapOnDroneOrUser: centerMapOnDroneOrUser)
    }

    func getFlightPlanProvider() -> FlightPlanProvider? {
        currentMissionManager.mode.flightPlanProvider
    }

    func getProjectModel() -> ProjectModel? {
        projectManager.currentProject
    }

    func historyTouchUpInside() {
        if let projectModel = getProjectModel() {
            coordinator?.startFlightPlanHistory(projectModel: projectModel)
        }
    }

    /// Project button touched up inside.
    func projectTouchUpInside() {
        coordinator?.startManagePlans()
    }

    /// Play button touched up inside.
    func playButtonTouchedUpInside() {
        startFlightPlan()
    }

    /// Edit button touched up inside.
    @IBAction func editButtonTouchedUpInside() {
        if getProjectModel().map(projectManager.lastFlightPlan) == nil,
           let flightPlanProvider = getFlightPlanProvider() {
            // There are not already flight plans, create a new project and go to edition
            newFlightplan(flightPlanProvider: flightPlanProvider)
            startEditionMode(true)
        } else {
            // Edit current project
            startEditionMode(false)
        }
    }

    public func showStream() {
        splitControls?.forceStream = true
        splitControls?.displayMapOr3DasChild()
        splitControls?.updateCenterMapButtonStatus()
    }

    public func showMap() {
        splitControls?.forceStream = false
        splitControls?.displayMapOr3DasChild()
        splitControls?.updateCenterMapButtonStatus()
    }
}

// MARK: - Private Funcs
private extension FlightPlanPanelViewModel {

    func listenProjectManager() {
        projectManager.currentProjectPublisher
            .sink { [unowned self] project in
                if let newProject = project {
                    self.titleProject = newProject.title
                } else {
                    imageRate = nil
                    progressModel = nil
                    viewState = .creation
                }
            }.store(in: &cancellables)

        projectManager.startEditionPublisher
            .sink { [unowned self] _ in
                startEditionMode(true)
            }
            .store(in: &cancellables)
    }

    func listenMissionMode() {
        currentMissionManager.modePublisher.sink { [unowned self] in

            createFirstTitle = $0.flightPlanProvider?.createFirstTitle
            newButtonTitle = $0.flightPlanProvider?.newButtonTitle
            listenStateMachine(missionMode: $0)
        }
        .store(in: &cancellables)

        // Update the 'extraViews' according the current Mission Mode and Flight Plan state.
        currentMissionManager.modePublisher
            .sink { [weak self] missionMode in
                guard let self = self else { return }
                let flightPlanProvider = missionMode.flightPlanProvider
                self.updateExtraViews(missionStatusView: flightPlanProvider?.statusView)
            }
            .store(in: &cancellables)
    }

    private typealias State = (machine: FlightPlanStateMachineState,
                               run: FlightPlanRunningState,
                               customProgress: CustomFlightPlanProgress?)

    private typealias FlightPlanProgress = (progress: Double,
                                            duration: TimeInterval,
                                            distance: Double)

    func listenStateMachine(missionMode: MissionMode) {
        self.stateMachine = missionMode.stateMachine
        let customProgressPublisher: AnyPublisher<CustomFlightPlanProgress?, Never>
            = missionMode.flightPlanProvider?.customProgressPublisher ?? Just(nil).eraseToAnyPublisher()
        // Combine the Flight Plan Progress Publishers
        let flightPlanProgressPublisher = runManager.progressPublisher
            .combineLatest(runManager.durationPublisher,
                           runManager.distancePublisher)
        stateMachineCancellable = missionMode.stateMachine?.statePublisher
            .combineLatest(runManager.statePublisher, customProgressPublisher)
            .combineLatest(runManager.navigatingToStartingPointPublisher,
                           flightPlanProgressPublisher)
            .sink { [unowned self] (state: State, isNavigatingToStartingPoint, fpProgress: FlightPlanProgress) in

                self.updateButtonsInformation(state.machine, runState: state.run)
                self.updateImageRateInformation(state.machine)

                var hasHistory = false
                if let project = projectManager.currentProject {
                    hasHistory = !projectManager.executedFlightPlans(for: project).isEmpty
                }
                switch state.machine {
                case .machineStarted, .initialized:
                    break
                case .editable(let flightPlan, startAvailability: _):
                    viewState = .edition(hasHistory: hasHistory, canEdit: flightPlan.dataSetting?.readOnly != true)
                case .resumable:
                    viewState = .resumable(hasHistory: hasHistory)
                case let .startedNotFlying(_, mavlinkStatus):
                    switch mavlinkStatus {
                    case .sending, .generating:
                        break
                    }
                case .flying:
                    self.titleExecution = runManager.playingFlightPlan?.customTitle
                    switch state.run {
                    case let .playing(_, _, rth) where rth:
                        if viewState == .rth { return }
                        viewState = .rth
                    case .paused:
                        viewState = .paused
                    default:
                        // Check if drone is currently flying to the first (or last executed) way point.
                        if isNavigatingToStartingPoint {
                            // If the view state is already in the correct state,
                            // do nothing to keep the animation running correctly.
                            if viewState == .navigatingToStartingPoint { return }
                            viewState = .navigatingToStartingPoint
                       } else { viewState = .playing(time: fpProgress.duration) }
                    }
                case .end:
                    break
                }

                switch state.machine {
                case .flying:
                    // when flying always show the flight progress even if there is a customProgress
                    // associated with the state
                    progressModel = isNavigatingToStartingPoint ?
                    navigatingToStartingPointProgressModel() :
                    progressModel(runState: state.run,
                                  stateMachine: state.machine,
                                  progress: fpProgress.progress,
                                  distance: fpProgress.distance)
                default:
                    if let customProgress = state.customProgress {
                        // Check if a FP unavailability must be shown instead of the progress view.
                        let unavailabilityReasons = pilotingIterfaceUnavailabilityReasons(for: state.run)
                        if !unavailabilityReasons.isEmpty {
                            progressModel = FlightPlanPanelProgressModel(mainText: unavailabilityReasons.errorText ?? L10n.error,
                                                                         mainColor: ColorName.errorColor.color,
                                                                         hasError: true)
                        } else {
                            progressModel = FlightPlanPanelProgressModel(mainText: customProgress.label,
                                                                         mainColor: customProgress.color,
                                                                         progress: customProgress.progress)
                        }
                    } else {
                        progressModel = progressModel(runState: state.run,
                                                      stateMachine: state.machine,
                                                      progress: fpProgress.progress,
                                                      distance: fpProgress.distance)
                    }
                }
            }
    }

    /// Returns whether or not there is some FP unavailability reasons.
    ///
    ///  - Parameters:
    ///     - runState: The current FP running state.
    ///
    ///  - Returns:
    ///     - A set of existing `FlightPlanUnavailabilityReason`.
    func pilotingIterfaceUnavailabilityReasons(for runState: FlightPlanRunningState)
    -> Set<FlightPlanUnavailabilityReason> {
        // Ensure needed conditions are meet:
        //   • FP running state machine: `.unavailable`
        //   • Unavailability reason: `.pilotingItfUnavailable`
        guard case .paused(_, .unavailable(.pilotingItfUnavailable(let reasons))) = runState
        else { return Set() }
        return reasons
    }

    func progressModel(runState: FlightPlanRunningState,
                       stateMachine: FlightPlanStateMachineState,
                       progress: Double,
                       distance: Double) -> FlightPlanPanelProgressModel {
        switch stateMachine {
        case .flying:
            // State machine is in .flying state
            // Check the FP running state in case of FP paused by a Drone's event.
            let unavailabilityReasons = pilotingIterfaceUnavailabilityReasons(for: runState)
            if !unavailabilityReasons.isEmpty {
                return FlightPlanPanelProgressModel(mainText: unavailabilityReasons.errorText ?? L10n.error,
                                                    mainColor: ColorName.errorColor.color,
                                                    hasError: true)
            }
            return flyingProgressModel(runState: runState, progress: progress, distance: distance)
        case .startedNotFlying:
            return FlightPlanPanelProgressModel(mainText: L10n.flightPlanInfoUploading)
        case .end:
            return FlightPlanPanelProgressModel(mainText: "")
        case let .resumable(_, startAvailability),
             let .editable(_, startAvailability):
            switch startAvailability {
            case let .available(isRthActive):
                return FlightPlanPanelProgressModel(mainText: isRthActive ? "" : L10n.flightPlanInfoDroneReady)
            case let .unavailable(reason):
                switch reason {
                case .droneDisconnected:
                    return FlightPlanPanelProgressModel(mainText: L10n.commonDroneNotConnected,
                                                        mainColor: ColorName.errorColor.color,
                                                        hasError: true)
                case let .pilotingItfUnavailable(reasons):
                    return FlightPlanPanelProgressModel(mainText: reasons.errorText ?? L10n.error,
                                                        mainColor: ColorName.errorColor.color,
                                                        hasError: true)
                }
            case .alreadyRunning:
                return FlightPlanPanelProgressModel(mainText: "")
            }
        case .machineStarted, .initialized:
            return FlightPlanPanelProgressModel(mainText: "")
        }
    }

    func flyingProgressModel(runState: FlightPlanRunningState,
                             progress: Double,
                             distance: Double) -> FlightPlanPanelProgressModel {
        let effectiveProgress = getEffectiveProgress(progress, distance)
        let percentString: String = (effectiveProgress * 100).asPercent(maximumFractionDigits: 0)
        let distanceString: String = UnitHelper.stringDistanceWithDouble(distance,
                                                                         spacing: false)
        switch runState {
        case let .playing(droneConnected, _, rth):
            if rth {
                return FlightPlanPanelProgressModel(mainText: L10n.commonReturnHome,
                                                    mainColor: ColorName.highlightColor.color,
                                                    subColor: ColorName.whiteAlbescent.color,
                                                    progress: nil)
            } else {
                return FlightPlanPanelProgressModel(mainText: String(format: "%@・%@",
                                                                     percentString,
                                                                     distanceString),
                                                    mainColor: droneConnected ? ColorName.highlightColor.color : ColorName.defaultTextColor.color,
                                                    subColor: ColorName.whiteAlbescent.color,
                                                    progress: progress)
            }
        case .paused:
            return FlightPlanPanelProgressModel(mainText: L10n.flightPlanAlertStoppedAt(String(format: "%@・%@",
                                                                                               percentString,
                                                                                               distanceString)),
                                                mainColor: ColorName.warningColor.color,
                                                subColor: ColorName.whiteAlbescent.color,
                                                progress: progress)
        default:
            return FlightPlanPanelProgressModel(mainText: "")
        }
    }

    /// Progress render during the navigation to the first (or last executed) Flight Plan's way point.
    func navigatingToStartingPointProgressModel() -> FlightPlanPanelProgressModel {
        // An indeterminate progress animation (like for RTH) is shown.
        // This animation is set and started automatically by passing `progress` = nil.
        FlightPlanPanelProgressModel(mainText: L10n.droneNavigatingToFlightPlanStartingPoint,
                                     mainColor: ColorName.highlightColor.color,
                                     subColor: ColorName.whiteAlbescent.color,
                                     progress: nil)
    }

    /// Limit the progress displayed between 1% and 99% while the flightplan is still
    /// being executed.
    /// - Parameters:
    ///     - progress: current flightplan progress
    ///     - distance: current distance traveled by the drone during the flightplan
    func getEffectiveProgress(_ progress: Double, _ distance: Double) -> Double {
        if distance > 0 && progress < 0.01 {
            return 0.01
        } else if progress >= 0.99 {
            return 0.99
        } else {
            return progress
        }
    }

    func updateImageRateInformation(_ machineState: FlightPlanStateMachineState) {
        switch machineState {
        case let .editable(flightPlan, _),
             let .end(flightPlan),
             let .flying(flightPlan),
             let .resumable(flightPlan, _),
             let .startedNotFlying(flightPlan, _):
            let settingsProvider = Services.hub.currentMissionManager.mode.flightPlanProvider?.settingsProvider
            imageRate = ImageRateProvider(
                dataSettings: flightPlan.dataSetting,
                settings: settingsProvider?.settings(for: flightPlan))
        default:
            imageRate = nil
        }
    }

    func updateButtonsInformation(_ machineState: FlightPlanStateMachineState, runState: FlightPlanRunningState) {
        var buttonInfo: ButtonsInformation
        switch machineState {
        case .machineStarted, .initialized, .end:
            buttonInfo = .defaultInfo
        case let .editable(flightPlan, startAvailability):
            let buttonsAreEnabled = startAvailability == .available(false) && flightPlan.isEmpty == false
            buttonInfo = ButtonsInformation(startButtonState: .canPlay, areEnabled: buttonsAreEnabled)
        case .resumable(_, startAvailability: let startAvailability):
            var areEnabled = false
            if case .available = startAvailability { areEnabled = true }
            buttonInfo = ButtonsInformation(startButtonState: .paused, areEnabled: areEnabled)
        case .startedNotFlying:
            buttonInfo = ButtonsInformation(startButtonState: .canPlay, areEnabled: false)
        case .flying:
            switch runState {
            case .paused(_, let startAvailability):
                var areEnabled = false
                if case .available = startAvailability { areEnabled = true }
                buttonInfo = ButtonsInformation(startButtonState: .paused, areEnabled: areEnabled)
            case let .playing(droneConnected, _, _):
                buttonInfo = ButtonsInformation(startButtonState: .canPlay, areEnabled: droneConnected)
            default:
                buttonInfo = ButtonsInformation.defaultInfo
            }
        }
        self.buttonsState = buttonInfo
    }

    /// Updates extra views.
    /// Extra views are views added in a stackview located to the right side, above the progress bar.
    /// They display flight plan additional informations like current video recording time, photo upload state...
    ///
    /// - Parameters:
    ///    - missionStatusView: an optional mission's status view.
    func updateExtraViews(missionStatusView: UIView?) {
        var extraViews: [UIView] = []

        // `missionStatusView` is a mission specific status view (e.g. photo upload state)
        if let statusView = missionStatusView {
            extraViews.append(statusView)
        }

        self.extraViews = extraViews
    }
}

extension FlightPlanPanelViewModel {

    enum StartButtonState {
        case canPlay
        case blockingIssue
        case paused

        var style: ActionButtonStyle {
            switch self {
            case .canPlay, .paused:
                return .validate
            case .blockingIssue:
                return .destructive
            }
        }

        var icon: UIImage? {
            switch self {
            case .canPlay, .blockingIssue:
                return Asset.Common.Icons.play.image
            case .paused:
                return Asset.Common.Icons.icResume.image
            }
        }
    }

    struct ButtonsInformation {
        let startButtonState: StartButtonState
        let areEnabled: Bool

        static let defaultInfo = ButtonsInformation(startButtonState: .blockingIssue,
                                                    areEnabled: false)
    }

    /// Enumeration of the different bottom view states.
    ///
    /// • `creation`: No project available. User is invited to create one.
    /// • `edition`: Project's current Flight Plan is in editable mode.
    ///            User can start / edit the current Flight Plan, or show the executions history.
    /// • `navigatingToStartingPoint`: The drone navigating to the first (or last executed) Waypoint.
    /// • `playing`: The Flight Plan execution is running. The execution state is displayed.
    /// • `resumable`:  The Flight Plan is resumable (stopped and partially executed).
    ///               User can resume but cannot edit  it.
    /// • `paused`: The Flight Plan execution is running (flying) but has been paused.
    ///           User can resume or stop it (can't edit it).
    /// • `rth`: The Flight Plan execution ended and the drone returning home.
    enum ViewState: Equatable {
        case creation
        case edition(hasHistory: Bool, canEdit: Bool)
        case navigatingToStartingPoint
        case playing(time: TimeInterval)
        case resumable(hasHistory: Bool)
        case paused
        case rth

        static func == (lhs: FlightPlanPanelViewModel.ViewState, rhs: FlightPlanPanelViewModel.ViewState) -> Bool {
            switch (lhs, rhs) {
            case (.creation, .creation),
                (.resumable, .resumable),
                (.navigatingToStartingPoint, .navigatingToStartingPoint),
                (.playing, .playing),
                (.paused, .paused),
                (.rth, .rth):
                return true
            case let (.edition(hasHistoryLHS, canEditLHS), .edition(hasHistoryRHS, canEditRHS)):
                return hasHistoryLHS == hasHistoryRHS && canEditLHS == canEditRHS
            default:
                return false
            }
        }
    }

    struct ImageRateProvider {
        let dataSettings: FlightPlanDataSetting?
        let settings: [FlightPlanSetting]?

        init?(dataSettings: FlightPlanDataSetting?,
              settings: [FlightPlanSetting]?) {
            guard
                let dataSettings = dataSettings,
                let settings = settings
            else { return nil }
            self.dataSettings = dataSettings
            self.settings = settings
        }
    }
}
