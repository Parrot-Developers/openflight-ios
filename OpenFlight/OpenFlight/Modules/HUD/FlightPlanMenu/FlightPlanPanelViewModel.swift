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

import GroundSdk
import Combine

/// View model for flight plan menu.
final class FlightPlanPanelViewModel {

    @Published private(set) var buttonsState: ButtonsInformation = ButtonsInformation.defaultInfo

    @Published private(set) var titleProject: String?

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
        listenSelectedProject()
    }

    // MARK: - Internal Funcs
    /// Sends currently loaded flight plan to drone and starts it.
    func startFlightPlan() {
        stateMachine?.start()
    }

    /// Stops current runnning flight plan.
    func stopFlightPlan() {
        stateMachine?.stop()
    }

    func pauseFlightPlan() {
        stateMachine?.pause()
    }

    func newFlightplan(flightPlanProvider: FlightPlanProvider) {
        let project = projectManager.newProject(flightPlanProvider: flightPlanProvider)
        projectManager.loadEverythingAndOpen(project: project)
    }

    func startEditionMode(_ open: Bool) {
        stateMachine?.forceEditable()
        coordinator?.startFlightPlanEdition(shouldCenter: open)
    }

    func replayFlightPlan() {
        guard let stateMachine = stateMachine, let flightPlan = stateMachine.currentFlightPlan else { return }
        stateMachine.open(flightPlan: flightPlan)
        stateMachine.forceEditable()
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
    }

    public func showMap() {
        splitControls?.forceStream = false
        splitControls?.displayMapOr3DasChild()
    }
}

// MARK: - Private Funcs
private extension FlightPlanPanelViewModel {

    func listenSelectedProject() {
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
    }

    func listenMissionMode() {
        currentMissionManager.modePublisher.sink { [unowned self] in

            createFirstTitle = $0.flightPlanProvider?.createFirstTitle
            newButtonTitle = $0.flightPlanProvider?.newButtonTitle
            listenStateMachine(missionMode: $0)
        }
        .store(in: &cancellables)

        currentMissionManager.modePublisher
            .combineLatest(runManager.statePublisher)
            .map { return ($0, $1.isActive) }
            .sink { [unowned self] missionMode, isActive in
                self.updateExtraViews(missionStatusView: missionMode.flightPlanProvider?.statusView, isActive: isActive)
            }
            .store(in: &cancellables)
    }

    private typealias State = (machine: FlightPlanStateMachineState,
                               run: FlightPlanRunningState,
                               customProgress: CustomFlightPlanProgress?)

    func listenStateMachine(missionMode: MissionMode) {
        self.stateMachine = missionMode.stateMachine
        let customProgressPublisher: AnyPublisher<CustomFlightPlanProgress?, Never>
            = missionMode.flightPlanProvider?.customProgressPublisher ?? Just(nil).eraseToAnyPublisher()
        stateMachineCancellable = missionMode.stateMachine?.statePublisher
            .combineLatest(runManager.statePublisher, customProgressPublisher)
            .combineLatest(runManager.distancePublisher,
                           runManager.durationPublisher,
                           runManager.progressPublisher)
            .sink { [unowned self] (state: State, distance, duration, progress) in

                self.updateButtonsInformation(state.machine, runState: state.run)
                self.updateImageRateInformation(state.machine)

                var hasHistory = false
                if let project = projectManager.currentProject {
                    hasHistory = !projectManager.executedFlightPlans(for: project).isEmpty
                }
                switch state.machine {
                case .machineStarted, .initialized:
                    break
                case .editable:
                    viewState = .edition(hasHistory: hasHistory)
                case .resumable:
                    viewState = .resumable(hasHistory: hasHistory)
                case let .startedNotFlying(_, mavlinkStatus):
                    switch mavlinkStatus {
                    case .sending, .generating:
                        break
                    }
                case .flying:
                    switch state.run {
                    case let .playing(_, _, rth) where rth:
                        viewState = .rth
                    case .paused:
                        viewState = .paused
                    default:
                        viewState = .playing(time: duration)
                    }
                case .end:
                    break
                }
                if let customProgress = state.customProgress {
                    progressModel = FlightPlanPanelProgressModel(mainText: customProgress.label,
                                                                 mainColor: customProgress.color,
                                                                 progress: customProgress.progress)
                } else {
                    progressModel = progressModel(runState: state.run,
                                                  statMachine: state.machine,
                                                  progress: progress,
                                                  distance: distance)
                }
            }
    }

    func progressModel(runState: FlightPlanRunningState,
                       statMachine: FlightPlanStateMachineState,
                       progress: Double,
                       distance: Double) -> FlightPlanPanelProgressModel {
        switch statMachine {
        case .flying:
            return flyingProgressModel(runState: runState, progress: progress, distance: distance)
        case .startedNotFlying:
            return FlightPlanPanelProgressModel(mainText: L10n.flightPlanInfoUploading)
        case .end:
            return FlightPlanPanelProgressModel(mainText: "")
        case let .resumable(_, startAvailability),
             let .editable(_, startAvailability):
            switch startAvailability {
            case .available:
                return FlightPlanPanelProgressModel(mainText: L10n.flightPlanInfoDroneReady)
            case let .unavailable(reason):
                switch reason {
                case .droneDisconnected:
                    return FlightPlanPanelProgressModel(mainText: L10n.commonDroneNotConnected,
                                                        mainColor: ColorName.redTorch.color,
                                                        hasError: true)
                case let .pilotingItfUnavailable(reasons):
                    return FlightPlanPanelProgressModel(mainText: reasons.errorText ?? L10n.error,
                                                        mainColor: ColorName.redTorch.color,
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
        let percentString: String = (progress * 100).asPercent(maximumFractionDigits: 0)
        let distanceString: String = UnitHelper.stringDistanceWithDouble(distance,
                                                                         spacing: false)
        switch runState {
        case let .playing(droneConnected, _, rth):
            if rth {
                return FlightPlanPanelProgressModel(mainText: L10n.commonReturnHome,
                                                    mainColor: ColorName.greySilver.color,
                                                    subColor: ColorName.whiteAlbescent.color,
                                                    progress: 1.0)
            } else {
                return FlightPlanPanelProgressModel(mainText: String(format: "%@・%@",
                                                                     percentString,
                                                                     distanceString),
                                                    mainColor: droneConnected ? ColorName.highlightColor.color : ColorName.defaultIconColor.color,
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
            let buttonsAreEnabled = startAvailability == .available && flightPlan.isEmpty == false
            buttonInfo = ButtonsInformation(startButtonState: .canPlay, areEnabled: buttonsAreEnabled)
        case .resumable(_, startAvailability: let startAvailability):
            buttonInfo = ButtonsInformation(startButtonState: .paused, areEnabled: startAvailability == .available)
        case .startedNotFlying:
            buttonInfo = ButtonsInformation(startButtonState: .canPlay, areEnabled: false)
        case .flying:
            switch runState {
            case .paused(_, let startAvailability):
                buttonInfo = ButtonsInformation(startButtonState: .paused, areEnabled: startAvailability == .available)
            case let .playing(droneConnected, _, _):
                buttonInfo = ButtonsInformation(startButtonState: .canPlay, areEnabled: droneConnected)
            default:
                buttonInfo = ButtonsInformation.defaultInfo
            }
        }
        self.buttonsState = buttonInfo
    }

    /// Updates extra views.
    ///
    /// - Parameters:
    ///     - isActive: tells if flight plan is active
    func updateExtraViews(missionStatusView: UIView?, isActive: Bool) {
        var extraViews: [UIView] = []
        if isActive {
            let counterView = FlightPlanPanelMediaCounterView()
            extraViews.append(counterView)
        }

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
    }

    struct ButtonsInformation {
        let startButtonState: StartButtonState
        let areEnabled: Bool

        static let defaultInfo = ButtonsInformation(startButtonState: .blockingIssue,
                                                    areEnabled: false)
    }

    enum ViewState: Equatable {
        case creation
        case edition(hasHistory: Bool)
        case playing(time: TimeInterval)
        case resumable(hasHistory: Bool)
        case paused
        case rth

        static func == (lhs: FlightPlanPanelViewModel.ViewState, rhs: FlightPlanPanelViewModel.ViewState) -> Bool {
            switch (lhs, rhs) {
            case (.creation, .creation),
                 (.resumable, .resumable),
                 (.playing, .playing),
                 (.paused, .paused),
                 (.rth, .rth):
                return true
            case let (.edition(hasHistoryLHS), .edition(hasHistoryRHS)):
                return hasHistoryLHS == hasHistoryRHS
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
