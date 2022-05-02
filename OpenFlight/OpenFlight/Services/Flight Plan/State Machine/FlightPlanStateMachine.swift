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
    func updateSafely(flightPlan: FlightPlanModel, _ updateBlock: (FlightPlanModel) -> Void) -> FlightPlanModel

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

    func reset()

    /// Flight plan was edited
    func flightPlanWasEdited(flightPlan: FlightPlanModel)

    /// When a flight plan finish but the app was disconnected, we should at least update its state
    func handleFinishedOfflineFlightPlan(flightPlan: FlightPlanModel)
}

open class FlightPlanStateMachineImpl {

    public let manager: FlightPlanManager
    public let projectManager: ProjectManager
    public let runManager: FlightPlanRunManager
    public let mavlinkGenerator: MavlinkGenerator
    public let mavlinkSender: MavlinkDroneSender
    public let startAvailabilityWatcher: FlightPlanStartAvailabilityWatcher
    public let edition: FlightPlanEditionService

    private var cancellables = Set<AnyCancellable>()

    private var stateMachine: GKStateMachine = GKStateMachine(states: [])

    public init(manager: FlightPlanManager,
                projectManager: ProjectManager,
                runManager: FlightPlanRunManager,
                mavlinkGenerator: MavlinkGenerator,
                mavlinkSender: MavlinkDroneSender,
                startAvailabilityWatcher: FlightPlanStartAvailabilityWatcher,
                edition: FlightPlanEditionService) {
        self.manager = manager
        self.projectManager = projectManager
        self.runManager = runManager
        self.mavlinkGenerator = mavlinkGenerator
        self.mavlinkSender = mavlinkSender
        self.startAvailabilityWatcher = startAvailabilityWatcher
        self.edition = edition
        self.stateMachine = GKStateMachine(states: buildStates())
        statePrivate.sink {
            ULog.i(.tag, "Publishing state \($0)")
        }
        .store(in: &cancellables)
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
        open(flightPlan: flightPlan)
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
        if isCurrentFlightPlan {
            open(flightPlan: flightPlan)
        }
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
                                                          mavlinkGenerator: mavlinkGenerator,
                                                          mavlinkSender: mavlinkSender)
        let startedFlyingState = StartedFlyingState(delegate: self,
                                                    runManager: runManager,
                                                    flightPlanManager: manager,
                                                    projectManager: projectManager)
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

    func propagateUpdatedFlightPlan(_ flightPlan: FlightPlanModel) {
        ULog.i(.tag, "Propagate updated '\(flightPlan.uuid)' state '\(statePrivate.value)'")
        ULog.d(.tag, "FP propagated: '\(flightPlan)'")
        switch statePrivate.value {
        case .machineStarted, .initialized:
            break
        case .editable(_, startAvailability: let startAvailability):
            stateMachine.state(forClass: EditableState.self)?.flightPlanWasUpdated(flightPlan)
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

    open func handleMavlinkGenerationError(flightPlan: FlightPlanModel, _ error: MavlinkGenerationError) {
        ULog.e(.tag, "Mavlink generation error for '\(flightPlan.uuid)': \(error.localizedDescription)")
        goToEditableState(flightPlan: flightPlan)
    }

    open func handleMavlinkSendingError(flightPlan: FlightPlanModel, _ error: MavlinkDroneSenderError) {
        ULog.e(.tag, "Mavlink sending error for '\(flightPlan.uuid)': \(error.localizedDescription)")
        goToEditableState(flightPlan: flightPlan)
    }

    open func handleMavlinkSendingSuccess(flightPlan: FlightPlanModel, commands: [MavlinkStandard.MavlinkCommand]) {
        ULog.i(.tag, "Mavlink sending success for '\(flightPlan.uuid)'")
        guard stateMachine.canEnterState(StartedFlyingState.self),
              let startedFlyingState = stateMachine.state(forClass: StartedFlyingState.self) else { return }
        startedFlyingState.setup(flightPlan: flightPlan, commands: commands,
                                 lastMissionItemExecuted: nil, recoveryResourceId: nil, runningTime: 0)
        enter(StartedFlyingState.self)
    }

    open func mavlinkGenerationStarted(flightPlan: FlightPlanModel) {
        ULog.i(.tag, "Mavlink generation started for '\(flightPlan.uuid)'")
        statePrivate.send(.startedNotFlying(flightPlan, mavlinkStatus: .generating))
    }

    open func mavlinkSendingStarted(flightPlan: FlightPlanModel) {
        ULog.i(.tag, "Mavlink sending started for '\(flightPlan.uuid)'")
        statePrivate.send(.startedNotFlying(flightPlan, mavlinkStatus: .sending))
    }
}

extension FlightPlanStateMachineImpl: StartedFlyingStateDelegate {
}

extension FlightPlanStateMachineImpl: EndedStateDelegate {
    public func flightPlanEnded(flightPlan: FlightPlanModel, completed: Bool) {
        ULog.i(.tag, "Ended '\(flightPlan.uuid)'")
        statePrivate.send(.end(flightPlan))
        open(flightPlan: flightPlan)
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

    public func updateSafely(flightPlan: FlightPlanModel, _ updateBlock: (FlightPlanModel) -> Void) -> FlightPlanModel {
        ULog.d(.tag, "update safely '\(flightPlan.uuid)'")
        guard flightPlan.uuid == currentFlightPlan?.uuid else {
            let flightPlan = manager.flightPlan(uuid: flightPlan.uuid) ?? flightPlan
            updateBlock(flightPlan)
            // /!\ the FP storing in core data is async.
            // We can get an old non-updated version.
            return manager.flightPlan(uuid: flightPlan.uuid) ?? flightPlan
        }
        let flightPlan = currentFlightPlan ?? flightPlan
        updateBlock(flightPlan)
        if let flightPlan = manager.flightPlan(uuid: flightPlan.uuid) {
            propagateUpdatedFlightPlan(flightPlan)
            return flightPlan
        }
        return flightPlan
    }

    // MARK: - Initializing state

    public func open(flightPlan: FlightPlanModel) {
        ULog.i(.tag, "COMMAND: open '\(flightPlan.uuid)'")
        reset()
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
            case .unavailable, .alreadyRunning:
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
            goToEditableState(flightPlan: flightPlan)
        } else if state is ResumableState {
            goToEditableState(flightPlan: flightPlan)
        }
    }

    public func pause() {
        guard let startedFlyingState = stateMachine.currentState as? StartedFlyingState else { return }
        ULog.i(.tag, "COMMAND: pause '\(currentFlightPlan?.uuid ?? "")'")
        startedFlyingState.pause()
    }

    public func reset() {
        if let currentState = stateMachine.currentState {
            ULog.i(.tag, "COMMAND: reset currentState: '\(type(of: currentState))'"
                   + " currentFlightPlan: '\(currentFlightPlan?.uuid ?? "")'")
            if let startedNotFlying = currentState as? StartedNotFlyingState {
                startedNotFlying.stop()
            }
            if let startedFlying = currentState as? StartedFlyingState {
                startedFlying.stop()
            }
        } else {
            ULog.i(.tag, "COMMAND: reset currentState: 'nil'"
                   + " currentFlightPlan: '\(currentFlightPlan?.uuid ?? "")'")
        }
        enter(IdleState.self)
        statePrivate.value = .machineStarted
    }

    public func flightPlanWasEdited(flightPlan: FlightPlanModel) {
        guard let editableState = stateMachine.currentState as? EditableState,
              case .editable(_, let startAvailability) = statePrivate.value,
              currentFlightPlan?.uuid == flightPlan.uuid else { return }
        ULog.i(.tag, "Was edited '\(flightPlan.uuid)'")
        editableState.flightPlan = flightPlan
        statePrivate.send(.editable(flightPlan, startAvailability: startAvailability))
    }

    public func catchUp(flightPlan: FlightPlanModel, lastMissionItemExecuted: Int,
                        recoveryResourceId: String?, runningTime: TimeInterval) {
        ULog.i(.tag, "COMMAND: catchUp on '\(flightPlan.uuid)' last item: \(lastMissionItemExecuted) recoveryResourceId: \(recoveryResourceId ?? "nil")")
        if case let .flying(stateFp) = statePrivate.value, stateFp.uuid == flightPlan.uuid {
            // Run manager should catch up on latest validated waypoint and running time
            updateRun(lastMissionItemExecuted: lastMissionItemExecuted, recoveryResourceId: recoveryResourceId, runningTime: runningTime)
            return
        }
        reset()
        guard let commands = flightPlan.dataSetting?.mavlinkCommands else {
            ULog.e(.tag, "Can't catchUp '\(flightPlan.uuid)' that doesn't carry its mavlink commands")
            return
        }
        guard let flyingState = stateMachine.state(forClass: StartedFlyingState.self) else { return }
        flyingState.setup(flightPlan: flightPlan,
                          commands: commands,
                          lastMissionItemExecuted: lastMissionItemExecuted,
                          recoveryResourceId: recoveryResourceId,
                          runningTime: runningTime)
        enter(StartedFlyingState.self)
    }
}
