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
import GameKit
import GroundSdk
import Combine

private extension ULogTag {
    static let tag = ULogTag(name: "FPStateMachine")
}

public enum FlightPlanStateMachineState: CustomStringConvertible {
    case machineStarted
    case initialized
    case editable(FlightPlanModel, startAvailability: FlightPlanStartAvailability)
    case resumable(FlightPlanModel, startAvailability: FlightPlanStartAvailability)
    case startedNotFlying(FlightPlanModel, mavlinkStatus: MavlinkStatus)
    case flying(FlightPlanModel)
    case end(FlightPlanModel)

    public var description: String {
        switch self {
        case .machineStarted:
            return ".machineStarted"
        case .initialized:
            return ".initialized"
        case let .editable(flightPlan, startAvailability: availability):
            return ".editable(\(flightPlan), startAvailability: \(availability))"
        case let .resumable(flightPlan, startAvailability: availability):
            return ".resumable(\(flightPlan), startAvailability: \(availability))"
        case let .startedNotFlying(flightPlan, mavlinkStatus: mavlinkStatus):
            return ".startedNotFlying(\(flightPlan), mavlinkStatus: \(mavlinkStatus))"
        case let .flying(flightPlan):
            return ".flying(\(flightPlan))"
        case let .end(flightPlan):
            return ".end(\(flightPlan))"
        }
    }
}

public enum MavlinkStatus: CustomStringConvertible {
    case generating
    case sending

    public var description: String {
        switch self {
        case .generating:
            return ".generating"
        case .sending:
            return ".sending"
        }
    }
}

extension FlightPlanStateMachineState: Equatable {
    public static func == (lhs: FlightPlanStateMachineState, rhs: FlightPlanStateMachineState) -> Bool {
        return false // Let's assume any change is worth notifying
    }
}

public protocol FlightPlanStateMachine {

    /// Current flight plan
    var currentFlightPlan: FlightPlanModel? { get }

    /// Current flight plan publisher
    var currentFlightPlanPublisher: AnyPublisher<FlightPlanModel?, Never> { get }

    /// This function should be called from parallel processes to update safely a flight plan.
    ///
    /// Based on the `flightPlan` parameter it will provide an up-to-date version of the flight plan that
    /// should be used as a base for `updateBlock`. Once the update is complete, the state machine will
    /// fetch the updated version of the flight plan in the persistence layer and propagate it to the relevant other services.
    /// - Parameters:
    ///   - flightPlan: the flight plan to update. May be an old version.
    ///   - updateBlock: the block performing the update
    @discardableResult
    func updateSafely(flightPlan: FlightPlanModel, _ updateBlock: (FlightPlanModel) -> FlightPlanModel) -> FlightPlanModel

    /// Publisher gives the current step of the state machine
    ///
    var statePublisher: AnyPublisher<FlightPlanStateMachineState, Never> { get }

    /// State of the state machine
    var state: FlightPlanStateMachineState { get }

    // MARK: Initializing state

    /// Open an existing flight plan
    ///
    /// - Parameters:
    ///     - flightPlan: flight plan to be opened
    func open(flightPlan: FlightPlanModel)

    /// When a flight plan is already being executed by the drone, the state machine can catch up using this function
    ///
    /// - Parameters:
    ///   - flightPlan: flight plan
    ///   - lastMissionItemExecuted: index of the latest mission item completed
    ///   - recoveryResourceId: first resource identifier of media captured after the latest reached waypoint
    ///   - runningTime: running time of the flightplan being executed
    func catchUp(flightPlan: FlightPlanModel, lastMissionItemExecuted: Int, recoveryResourceId: String?, runningTime: TimeInterval)

    /// In ResumableState, duplicates the FP and set it editable
    func forceEditable()

    /// Process the Flightplan.
    /// Move to state **StartedNotFlying**, when user wants to resume the flightplan where it was left
    func start()

    func stop()

    func pause()

    func reset(isSameProject: Bool)

    /// Flight plan was edited
    func flightPlanWasEdited(flightPlan: FlightPlanModel)

    /// When a flight plan finish but the app was disconnected, we should at least update its state
    func handleFinishedOfflineFlightPlan(flightPlan: FlightPlanModel)

    /// Update the Cloud Synchro Watcher.
    ///
    /// - Parameter cloudSynchroWatcher: the cloudSynchroWatcher to update
    ///
    /// - Note:
    ///     If the cloud synchro watcher service is not yet instatiated during this service's init,
    ///     this method can be called to update and configure his watcher.
    func updateCloudSynchroWatcher(_ cloudSynchroWatcher: CloudSynchroWatcher?)
}

open class FlightPlanStateMachineImpl {

    public let manager: FlightPlanManager
    public let projectManager: ProjectManager
    public let runManager: FlightPlanRunManager
    public let planFileGenerator: PlanFileGenerator
    public let planFileSender: PlanFileDroneSender
    public let filesManager: FlightPlanFilesManager
    public let startAvailabilityWatcher: FlightPlanStartAvailabilityWatcher
    public let edition: FlightPlanEditionService
    public var cloudSynchroWatcher: CloudSynchroWatcher?
    public let locationTracker: LocationsTracker

    private var synchroWatcherSubscriber: AnyCancellable?

    private var cancellables = Set<AnyCancellable>()

    private var stateMachine: GKStateMachine = GKStateMachine(states: [])

    public init(manager: FlightPlanManager,
                projectManager: ProjectManager,
                runManager: FlightPlanRunManager,
                planFileGenerator: PlanFileGenerator,
                planFileSender: PlanFileDroneSender,
                filesManager: FlightPlanFilesManager,
                startAvailabilityWatcher: FlightPlanStartAvailabilityWatcher,
                edition: FlightPlanEditionService,
                cloudSynchroWatcher: CloudSynchroWatcher?,
                locationTracker: LocationsTracker) {
        self.manager = manager
        self.projectManager = projectManager
        self.runManager = runManager
        self.planFileGenerator = planFileGenerator
        self.planFileSender = planFileSender
        self.filesManager = filesManager
        self.startAvailabilityWatcher = startAvailabilityWatcher
        self.edition = edition
        self.locationTracker = locationTracker
        self.stateMachine = GKStateMachine(states: buildStates())
        statePrivate.sink {
            ULog.i(.tag, "Publishing state \($0)")
        }
        .store(in: &cancellables)
        updateCloudSynchroWatcher(cloudSynchroWatcher)
    }

    open func updateCloudSynchroWatcher(_ cloudSynchroWatcher: CloudSynchroWatcher?) {
        self.cloudSynchroWatcher = cloudSynchroWatcher
        listenCloudStateUpdates()
    }

    open var currentFlightPlan: FlightPlanModel? {
        flightPlanFrom(state: statePrivate.value)
    }

    var statePrivate = CurrentValueSubject<FlightPlanStateMachineState, Never>(.machineStarted)

    // MARK: - StartedFlyingStateDelegate conformance
    // Declared here to be overridable

    open func flightPlanRunWillBegin(flightPlan: FlightPlanModel) {
        ULog.i(.tag, "Will begin run '\(flightPlan.uuid)'")
        statePrivate.send(.flying(flightPlan))
    }

    open func flightPlanRunDidFinish(flightPlan: FlightPlanModel, completed: Bool) {
        ULog.i(.tag, "Did finish '\(flightPlan.uuid)' completed: \(completed)")
        guard stateMachine.canEnterState(EndedState.self),
              let endedState = stateMachine.state(forClass: EndedState.self) else { return }
        endedState.flightPlan = flightPlan
        endedState.completed = completed
        enter(EndedState.self)
    }

    public func flightPlanRunDidTimeout(flightPlan: FlightPlanModel) {
        ULog.i(.tag, "Timeout '\(flightPlan.uuid)' resetting everything")
        runManager.handleTimeout(flightPlan: flightPlan)
        flightPlanRunDidFinish(flightPlan: flightPlan, completed: false)
    }

    public func flightPlanRunDidBegin(flightPlan: FlightPlanModel) {
        ULog.i(.tag, "Did begin '\(flightPlan.uuid)'")
    }

    open func flightPlanRunDidPause(flightPlan: FlightPlanModel) {
        ULog.i(.tag, "Did pause '\(flightPlan.uuid)'")
        // Update the flight plan state
        statePrivate.send(.flying(flightPlan))
    }

    open func handleFinishedOfflineFlightPlan(flightPlan: FlightPlanModel) {
        switch flightPlan.state {
        case .editable, .stopped, .flying:
            break
        case .completed, .uploading, .processing, .processed, .unknown:
            // Already finished
            return
        }
        ULog.i(.tag, "Handling offline-finished '\(flightPlan.uuid)'")
        let isCurrentFlightPlan = currentFlightPlan?.uuid == flightPlan.uuid
        if isCurrentFlightPlan {
            reset()
        }
        let flightPlan = manager.update(flightplan: flightPlan, with: .completed)
    }
}

private extension FlightPlanStateMachineImpl {

    func buildStates() -> [GKState] {
        let idleState = IdleState()
        let initializingState = InitializingState(delegate: self)
        let editableState = EditableState(delegate: self,
                                          flightPlanManager: manager,
                                          projectManager: projectManager,
                                          startAvailabilityWatcher: startAvailabilityWatcher,
                                          edition: edition)
        let resumableState = ResumableState(delegate: self, startAvailabilityWatcher: startAvailabilityWatcher, edition: edition)
        let startedNotFlyingState = StartedNotFlyingState(delegate: self,
                                                          flightPlanManager: manager,
                                                          projectManager: projectManager,
                                                          planFileGenerator: planFileGenerator,
                                                          planFileSender: planFileSender,
                                                          filesManager: filesManager,
                                                          locationTracker: locationTracker)
        let startedFlyingState = StartedFlyingState(delegate: self,
                                                    runManager: runManager,
                                                    flightPlanManager: manager)
        let endState = EndedState(delegate: self, flightPlanManager: manager)

        return [idleState,
                initializingState,
                editableState,
                resumableState,
                startedNotFlyingState,
                startedFlyingState,
                endState
        ]
    }

    func flightPlanFrom(state: FlightPlanStateMachineState) -> FlightPlanModel? {
        switch state {
        case .machineStarted, .initialized:
            return nil
        case .editable(let flightPlan, _),
             .resumable(let flightPlan, _),
             .startedNotFlying(let flightPlan, _),
             .flying(let flightPlan),
             .end(let flightPlan):
            return flightPlan
        }
    }

    @discardableResult
    func enter(_ stateClass: AnyClass) -> Bool {
        ULog.i(.tag, "Entering state: '\(stateClass)'")
        return stateMachine.enter(stateClass)
    }

    func goToStartedNotFlying() {
        guard stateMachine.canEnterState(StartedNotFlyingState.self),
              let flightPlan = currentFlightPlan,
              let startedNotFlyingState = stateMachine.state(forClass: StartedNotFlyingState.self) else {
            ULog.e(.tag, "Unable to go to StartedNotFlyingState '\(currentFlightPlan?.uuid ?? "")'")
            return
        }
        startedNotFlyingState.flightPlan = flightPlan
        enter(StartedNotFlyingState.self)
    }

    func goToEditableState(flightPlan: FlightPlanModel) {
        guard stateMachine.canEnterState(EditableState.self),
              let editableState = stateMachine.state(forClass: EditableState.self) else { return }
        editableState.flightPlan = flightPlan
        enter(EditableState.self)
    }

    func propagateUpdatedFlightPlan(_ flightPlan: FlightPlanModel, propagateToEditionService: Bool = true) {
        ULog.i(.tag, "Propagate updated '\(flightPlan.uuid)' state '\(statePrivate.value)', propagateToEditionService: \(propagateToEditionService)")
        ULog.d(.tag, "FP propagated: '\(flightPlan)'")
        switch statePrivate.value {
        case .machineStarted, .initialized:
            break
        case .editable(_, startAvailability: let startAvailability):
            // During editing, to avoid unwanted behavior such as a keyboard dismissal,
            // we don't want to propagate the updated flight plan to the edition service.
            stateMachine.state(forClass: EditableState.self)?.flightPlanWasUpdated(flightPlan,
                                                                                   propagateToEditionService: propagateToEditionService)
            statePrivate.value = .editable(flightPlan, startAvailability: startAvailability)
        case .resumable(_, startAvailability: let startAvailability):
            stateMachine.state(forClass: ResumableState.self)?.flightPlanWasUpdated(flightPlan)
            statePrivate.value = .resumable(flightPlan, startAvailability: startAvailability)
        case .startedNotFlying(_, let mavlinkStatus):
            stateMachine.state(forClass: StartedNotFlyingState.self)?.flightPlanWasUpdated(flightPlan)
            statePrivate.value = .startedNotFlying(flightPlan, mavlinkStatus: mavlinkStatus)
        case .flying:
            stateMachine.state(forClass: StartedFlyingState.self)?.flightPlanWasUpdated(flightPlan)
            statePrivate.value = .flying(flightPlan)
        case .end:
            stateMachine.state(forClass: EndedState.self)?.flightPlanWasUpdated(flightPlan)
            statePrivate.value = .end(flightPlan)
        }
    }

    /// Listen when a Flight Plan has been updated by a server response.
    func listenCloudStateUpdates() {
        synchroWatcherSubscriber?.cancel()
        synchroWatcherSubscriber = cloudSynchroWatcher?.flightPlanCloudStateUpdatedPublisher?
            .receive(on: RunLoop.main)
            .sink { [unowned self] in
                // Ensure the updated FP is the current state machine's one.
                guard var updatedFlightPlan = currentFlightPlan,
                      updatedFlightPlan.uuid == $0.uuid else { return }
                // Update the Cloud sate.
                updatedFlightPlan.updateCloudState(with: $0)
                // Propagate it.
                // The Edition Service is responsible to update the Cloud state on its side.
                propagateUpdatedFlightPlan(updatedFlightPlan,
                                           propagateToEditionService: false)
            }
    }
}

extension FlightPlanStateMachineImpl: InitializingStateDelegate {
    public func initializingFlightPlanIsResumable(_ flightPlan: FlightPlanModel) {
        guard stateMachine.canEnterState(ResumableState.self),
              let resumableState = stateMachine.state(forClass: ResumableState.self) else { return }
        ULog.i(.tag, "Initializing: '\(flightPlan.uuid)' is resumable")
        resumableState.flightPlan = flightPlan
        enter(ResumableState.self)
    }

    public func initializingFlightPlanIsNotResumable(_ flightPlan: FlightPlanModel) {
        guard stateMachine.canEnterState(EditableState.self),
              stateMachine.state(forClass: EditableState.self) != nil else { return }
        ULog.i(.tag, "Initializing: '\(flightPlan.uuid)' is NOT resumable."
               + " Reasons state: '\(flightPlan.state)' firstWP(\(flightPlan.hasReachedFirstWayPoint)) lastWP(\(flightPlan.hasReachedLastWayPoint))")
        goToEditableState(flightPlan: flightPlan)
    }
}

extension FlightPlanStateMachineImpl: ResumableStateDelegate {
    public func flightPlanIsResumable(_ flightPlan: FlightPlanModel, startAvailability: FlightPlanStartAvailability) {
        ULog.i(.tag, "In resumable state '\(flightPlan.uuid)' with availability \(startAvailability)")
        statePrivate.send(.resumable(flightPlan, startAvailability: startAvailability))
    }
}

extension FlightPlanStateMachineImpl: EditableStateDelegate {
    public func flightPlanIsEditable(_ flightPlan: FlightPlanModel, startAvailability: FlightPlanStartAvailability) {
        ULog.i(.tag, "In editable state '\(flightPlan.uuid)' with availability \(startAvailability)")
        statePrivate.send(.editable(flightPlan, startAvailability: startAvailability))
    }
}

extension FlightPlanStateMachineImpl: StartedNotFlyingStateDelegate {

    public func handleMavlinkGenerationError(flightPlan: FlightPlanModel, _ error: Error) {
        ULog.e(.tag, "Mavlink generation error for '\(flightPlan.uuid)': \(error.localizedDescription)")
        goToEditableState(flightPlan: flightPlan)
    }

    public func handleStartProhibited(for flightPlan: FlightPlanModel, reason: StartProhibitedReason) {
        ULog.e(.tag, "Start prohibited for '\(flightPlan.uuid)': \(reason)")
        // Inform `startAvailabilityWatcher` about the blocker.
        startAvailabilityWatcher.enableFirstWayPointTooFarBlocker(true)
        goToEditableState(flightPlan: flightPlan)
    }

    public func handleMavlinkSendingError(flightPlan: FlightPlanModel, _ error: Error) {
        ULog.e(.tag, "Mavlink sending error for '\(flightPlan.uuid)': \(error.localizedDescription)")
        goToEditableState(flightPlan: flightPlan)
    }

    public func handleMavlinkSendingSuccess(flightPlan: FlightPlanModel, commands: [MavlinkStandard.MavlinkCommand]) {
        ULog.i(.tag, "Mavlink sending success for '\(flightPlan.uuid)'")
        guard stateMachine.canEnterState(StartedFlyingState.self),
              let startedFlyingState = stateMachine.state(forClass: StartedFlyingState.self) else { return }
        startedFlyingState.setup(flightPlan: flightPlan, commands: commands,
                                 lastMissionItemExecuted: nil, recoveryResourceId: nil, runningTime: 0)
        enter(StartedFlyingState.self)
    }

    public func mavlinkGenerationStarted(flightPlan: FlightPlanModel) {
        ULog.i(.tag, "Mavlink generation started for '\(flightPlan.uuid)'")
        statePrivate.send(.startedNotFlying(flightPlan, mavlinkStatus: .generating))
    }

    public func mavlinkSendingStarted(flightPlan: FlightPlanModel) {
        ULog.i(.tag, "Mavlink sending started for '\(flightPlan.uuid)'")
        statePrivate.send(.startedNotFlying(flightPlan, mavlinkStatus: .sending))
    }
}

extension FlightPlanStateMachineImpl: StartedFlyingStateDelegate {
    public func flightPlanRunDidUpdate(flightPlan: FlightPlanModel) {
        ULog.i(.tag, "flightPlanRunDidUpdate for '\(flightPlan.uuid)', lastMissionItemExecuted : \(flightPlan.lastMissionItemExecuted)")
        statePrivate.send(.flying(flightPlan))
    }
}

extension FlightPlanStateMachineImpl: EndedStateDelegate {
    public func flightPlanEnded(flightPlan: FlightPlanModel, completed: Bool) {
        ULog.i(.tag, "Ended '\(flightPlan.uuid)'")
        statePrivate.send(.end(flightPlan))
        // If the FP is completed, the Plan file is no more needed, it can be removed from the filesystem.
        if completed { try? filesManager.removePlanFile(of: flightPlan) }
        // If the current project has changed (e.g. mission switched) we don't wan't to update the
        // state machine with a wrong flight plan.
        if let projectId = projectManager.currentProject?.uuid,
           projectId != flightPlan.projectUuid {
            ULog.i(.tag, "Project has been changed. Don't enter in Editable mode for ended FP.")
            return
        }
        // Entering `EndedState` means FP is stopped (not paused).
        // When stopped, we must load the project's editable FP to be able to start an new exacution.
        // 1 - Reset state machine.
        // 2 - Open Editable FP.
        reset()
        goToEditableState(flightPlan: flightPlan)
    }
}

extension FlightPlanStateMachineImpl: FlightPlanStateMachine {

    public var statePublisher: AnyPublisher<FlightPlanStateMachineState, Never> { statePrivate.eraseToAnyPublisher() }

    public var state: FlightPlanStateMachineState { statePrivate.value }

    public var currentFlightPlanPublisher: AnyPublisher<FlightPlanModel?, Never> {
        statePrivate
            .map { [unowned self] in flightPlanFrom(state: $0) }
            .eraseToAnyPublisher()
    }

    public func updateSafely(flightPlan: FlightPlanModel, _ updateBlock: (FlightPlanModel) -> FlightPlanModel) -> FlightPlanModel {
        ULog.d(.tag, "update safely '\(flightPlan.uuid)'")
        // If it's not the current FP, get the Core Data version.
        guard flightPlan.uuid == currentFlightPlan?.uuid else {
            let flightPlan = manager.flightPlan(uuid: flightPlan.uuid) ?? flightPlan
            return  updateBlock(flightPlan)
        }
        let flightPlan = currentFlightPlan ?? flightPlan
        let updatedFlightPlan = updateBlock(flightPlan)
        propagateUpdatedFlightPlan(updatedFlightPlan)
        return updatedFlightPlan
    }

    // MARK: - Initializing state

    public func open(flightPlan: FlightPlanModel) {
        ULog.i(.tag, "COMMAND: open '\(flightPlan.uuid)'")
        // Handling opening an FP while an execution is ongoing.
        if case .flying(let flyingFlightPlan) = statePrivate.value {
            if flyingFlightPlan.uuid == flightPlan.uuid {
                // Prevent to open a Flight Plan which is already running.
                // Resetting it will ask Run Manager to stop and reopen it with an updated FP.
                ULog.i(.tag, "Trying to open an already running flight plan '\(flightPlan.uuid)'")
                reset()
                return
            } else {
                // In case of another FP is trying to be opened,
                // stop the current playing flight plan before opening the new one.
                stop()
            }
        }
        // In all cases, perform a reset of the state machine to start from a clean state.
        reset(isSameProject: flightPlan.projectUuid == currentFlightPlan?.projectUuid)
        // Ensure we are in a state from we can enter in InitializingState.
        guard stateMachine.canEnterState(InitializingState.self),
              let initialState = stateMachine.state(forClass: InitializingState.self) else { return }
        statePrivate.value = .initialized
        // share the flight plan to be opened with the Initializing State
        initialState.flightPlan = flightPlan
        enter(InitializingState.self)
    }

    // MARK: - Resumable state

    public func forceEditable() {
        guard case .resumable(let flightPlan, _) = statePrivate.value,
              stateMachine.canEnterState(EditableState.self),
              let editableState = stateMachine.state(forClass: EditableState.self) else { return }
        ULog.i(.tag, "COMMAND: forceEditable '\(flightPlan.uuid)'")
        editableState.flightPlan = flightPlan
        enter(EditableState.self)
    }

    // MARK: Started not flying state

    public func start() {
        ULog.i(.tag, "COMMAND: start with state '\(statePrivate.value)'")
        switch statePrivate.value {
        case .machineStarted, .initialized, .end, .startedNotFlying:
            ULog.e(.tag, "COMMAND: start not possible with state '\(statePrivate.value)'")
        case .editable(_, let startAvailability),
             .resumable(_, let startAvailability):
            switch startAvailability {
            case .available:
                // Good to go
                goToStartedNotFlying()
            case .unavailable, .alreadyRunning, .firstWayPointTooFar:
                ULog.w(.tag, "COMMAND: start not possible with state '\(statePrivate.value)'")
            }
        case .flying:
            // The run may be paused, let's try to resume it
            guard let state = stateMachine.currentState as? StartedFlyingState else {
                ULog.e(.tag, "COMMAND: inconsistency between exposed state '\(statePrivate.value)' and machine state != StartedFlyingState")
                return
            }
            state.resumePausedRun()
        }
    }

    // MARK: Started flying state

    public func updateRun(lastMissionItemExecuted: Int, recoveryResourceId: String?, runningTime: TimeInterval) {
        guard let startedFlyingState = stateMachine.currentState as? StartedFlyingState else { return }
        startedFlyingState.updateRun(lastMissionItemExecuted: lastMissionItemExecuted,
                                     recoveryResourceId: recoveryResourceId,
                                     runningTime: runningTime)
    }

    public func stop() {
        // Stop preparing or flying
        guard let state = stateMachine.currentState,
              let flightPlan = currentFlightPlan else { return }
        ULog.i(.tag, "COMMAND: stop '\(flightPlan.uuid)'")
        if let startedNotFlying = state as? StartedNotFlyingState {
            startedNotFlying.stop()
            goToEditableState(flightPlan: flightPlan)
        } else if let startedFlying = state as? StartedFlyingState {
            startedFlying.stop()
            // Do not force to editableState in case an RTH is necessary
        } else if state is ResumableState {
            goToEditableState(flightPlan: flightPlan)
        }
    }

    public func pause() {
        guard let startedFlyingState = stateMachine.currentState as? StartedFlyingState else { return }
        ULog.i(.tag, "COMMAND: pause '\(currentFlightPlan?.uuid ?? "")'")
        startedFlyingState.pause()
    }

    public func reset(isSameProject: Bool) {
        if let currentState = stateMachine.currentState {
            ULog.i(.tag, "COMMAND: reset currentState: '\(type(of: currentState))'"
                   + " currentFlightPlan: '\(currentFlightPlan?.uuid ?? "")'")
            if let startedNotFlying = currentState as? StartedNotFlyingState {
                startedNotFlying.stop()
            }
            if let startedFlying = currentState as? StartedFlyingState {
                // In case of a reset, we don't want to execute the RTH (`forced` = true).
                startedFlying.stop(forced: true)
                // If the reset is initiated by the re-opening of the editable of the stopped FP,
                // `StartedFlyingState.stop()` will stop the FP then reopen/reset it.
                // We should not continue to prevent overwritting the state with Idle.
                if isSameProject { return }
            }
        } else {
            ULog.i(.tag, "COMMAND: reset currentState: 'nil'"
                   + " currentFlightPlan: '\(currentFlightPlan?.uuid ?? "")'")
        }
        // Reset the 'first way point too far' blocker.
        startAvailabilityWatcher.enableFirstWayPointTooFarBlocker(false)

        enter(IdleState.self)
        statePrivate.value = .machineStarted
    }

    public func flightPlanWasEdited(flightPlan: FlightPlanModel) {
        guard let editableState = stateMachine.currentState as? EditableState,
              case .editable(_, let startAvailability) = statePrivate.value,
              currentFlightPlan?.uuid == flightPlan.uuid else { return }
        ULog.i(.tag, "Was edited '\(flightPlan.uuid)'")

        // Reset the 'first way point too far' blocker. The edited FP will be checked at next launch.
        startAvailabilityWatcher.enableFirstWayPointTooFarBlocker(false)

        editableState.flightPlan = flightPlan
        statePrivate.send(.editable(flightPlan, startAvailability: startAvailability))
    }

    public func catchUp(flightPlan: FlightPlanModel, lastMissionItemExecuted: Int,
                        recoveryResourceId: String?, runningTime: TimeInterval) {
        ULog.i(.tag, "COMMAND: catchUp on '\(flightPlan.uuid)' last item: \(lastMissionItemExecuted) recoveryResourceId: \(recoveryResourceId ?? "nil")")
        // If the state machine is already in the correct state (`.flying` the FP catched up),
        // we just have to update the Run Manager with the up to date information.
        if case let .flying(stateFp) = statePrivate.value, stateFp.uuid == flightPlan.uuid {
            // Run manager should catch up on latest validated waypoint and running time
            updateRun(lastMissionItemExecuted: lastMissionItemExecuted, recoveryResourceId: recoveryResourceId, runningTime: runningTime)
            return
        }
        // Start by resetting the state machine.
        reset()
        // Ensure catched FP has valid mavlink commands.
        guard let commands = flightPlan.mavlinkCommands else {
            ULog.e(.tag, "Can't catchUp '\(flightPlan.uuid)' that doesn't carry its mavlink commands")
            return
        }
        // Create the flying state dedicated to handle the FP execution process.
        guard let flyingState = stateMachine.state(forClass: StartedFlyingState.self) else {
            ULog.e(.tag, "Unable to create `StartedFlyingState`")
            return
        }
        // Update the EditionService's current FP.
        // This allows to update the map with the correct FP.
        edition.setupFlightPlan(flightPlan)
        // Setup and enter the flying state.
        flyingState.setup(flightPlan: flightPlan,
                          commands: commands,
                          lastMissionItemExecuted: lastMissionItemExecuted,
                          recoveryResourceId: recoveryResourceId,
                          runningTime: runningTime)
        enter(StartedFlyingState.self)
    }
}

/// `FlightPlanStateMachine` protocol helpers to add default values.
extension FlightPlanStateMachine {
    public func reset() { reset(isSameProject: true) }
}
