//
//  Copyright (C) 2021 Parrot Drones SAS.
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

public enum FlightPlanStateMachineState {
    case machineStarted
    case initialized
    case editable(FlightPlanModel, startAvailability: FlightPlanStartAvailability)
    case resumable(FlightPlanModel, startAvailability: FlightPlanStartAvailability)
    case startedNotFlying(FlightPlanModel, MavlinkStatus)
    case flying(FlightPlanModel)
    case end(FlightPlanModel)
}

public enum MavlinkStatus {
    case generating
    case sending
}

extension FlightPlanStateMachineState: Equatable {
    public static func == (lhs: FlightPlanStateMachineState, rhs: FlightPlanStateMachineState) -> Bool {
        return false // Let's assume any change is worth notifying
    }
}

public protocol FlightPlanStateMachine {

    /// Current flight plan
    var currentFlightPlan: FlightPlanModel? { get }

    /// This function should be called from parallel processes to update safely a flight plan.
    ///
    /// Based on the `flightPlan` parameter it will provide an up-to-date version of the flight plan that
    /// should be used as a base for `updateBlock`. Once the update is complete, the state machine will
    /// fetch the updated version of the flight plan in the persistence layer and propagate it to the relevant other services.
    /// - Parameters:
    ///   - flightPlan: the flight plan to update. May be an old version.
    ///   - updateBlock: the block performing the update
    func updateSafely(flightPlan: FlightPlanModel, _ updateBlock: (FlightPlanModel) -> Void)

    /// Publisher gives the current step of the state machine
    ///
    var state: AnyPublisher<FlightPlanStateMachineState, Never> { get }

    // MARK: Initializing state

    /// Open an existing flight plan
    ///
    /// - Parameters:
    ///     - flightPlan: flight plan to be opened
    ///
    func open(flightPlan: FlightPlanModel)

    /// When a flight plan is already being executed by the drone, the state machine can catch up using this function
    /// - Parameter flightPlan: flight plan
    func catchUp(flightPlan: FlightPlanModel, lastMissionItemExecuted: Int)

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
}

open class FlightPlanStateMachineImpl {

    public let manager: FlightPlanManager
    public let runManager: FlightPlanRunManager
    public let mavlinkGenerator: MavlinkGenerator
    public let mavlinkSender: MavlinkDroneSender
    public let startAvailabilityWatcher: FlightPlanStartAvailabilityWatcher
    public let edition: FlightPlanEditionService

    private var cancellables = Set<AnyCancellable>()

    public init(manager: FlightPlanManager,
                runManager: FlightPlanRunManager,
                mavlinkGenerator: MavlinkGenerator,
                mavlinkSender: MavlinkDroneSender,
                startAvailabilityWatcher: FlightPlanStartAvailabilityWatcher,
                edition: FlightPlanEditionService) {
        self.manager = manager
        self.runManager = runManager
        self.mavlinkGenerator = mavlinkGenerator
        self.mavlinkSender = mavlinkSender
        self.startAvailabilityWatcher = startAvailabilityWatcher
        self.edition = edition
        statePrivate.sink {
            ULog.i(.tag, "Publishing state \($0)")
        }
        .store(in: &cancellables)
    }

    open var currentFlightPlan: FlightPlanModel? {
        switch statePrivate.value {
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

    var statePrivate = CurrentValueSubject<FlightPlanStateMachineState, Never>(.machineStarted)

    open var stateMachine: GKStateMachine = GKStateMachine(states: [])

    open func flightPlanRunWillBegin(flightPlan: FlightPlanModel) {
        ULog.i(.tag, "Flight plan run will begin")
        statePrivate.send(.flying(flightPlan))
    }
}

private extension FlightPlanStateMachineImpl {

    func buildStates() {
        let initializingState = InitializingState(delegate: self)
        let editableState = EditableState(delegate: self,
                                          flightPlanManager: manager,
                                          startAvailabilityWatcher: startAvailabilityWatcher,
                                          edition: edition)
        let resumableState = ResumableState(delegate: self, startAvailabilityWatcher: startAvailabilityWatcher, edition: edition)
        let startedNotFlyingState = StartedNotFlyingState(delegate: self,
                                                          mavlinkGenerator: mavlinkGenerator,
                                                          mavlinkSender: mavlinkSender)
        let startedFlyingState = StartedFlyingState(delegate: self, runManager: runManager, flightPlanManager: manager)
        let endState = EndedState(delegate: self, flightPlanManager: manager)

        let states = [initializingState,
                       editableState,
                       resumableState,
                       startedNotFlyingState,
                       startedFlyingState,
                       endState
        ]
        stateMachine = GKStateMachine(states: states)
    }

    @discardableResult
    func enter(_ stateClass: AnyClass) -> Bool {
        ULog.i(.tag, "Entering state \(stateClass)")
        return stateMachine.enter(stateClass)
    }

    func goToStartedNotFlying() {
        guard stateMachine.canEnterState(StartedNotFlyingState.self),
              let flightPlan = currentFlightPlan,
              let startedNotFlyingState = stateMachine.state(forClass: StartedNotFlyingState.self) else {
            ULog.w(.tag, "Unable to go to StartedNotFlyingState")
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
            statePrivate.value = .startedNotFlying(flightPlan, mavlinkStatus)
        case .flying:
            stateMachine.state(forClass: StartedFlyingState.self)?.flightPlanWasUpdated(flightPlan)
            statePrivate.value = .flying(flightPlan)
        case .end(_):
            stateMachine.state(forClass: EndedState.self)?.flightPlanWasUpdated(flightPlan)
            statePrivate.value = .end(flightPlan)
        }
    }
}

extension FlightPlanStateMachineImpl: InitializingStateDelegate {
    public func initializingFlightPlanIsResumable(_ flightPlan: FlightPlanModel) {
        guard stateMachine.canEnterState(ResumableState.self),
              let resumableState = stateMachine.state(forClass: ResumableState.self) else { return }
        ULog.i(.tag, "Initializing flight plan is resumable")
        resumableState.flightPlan = flightPlan
        enter(ResumableState.self)
    }

    public func initializingFlightPlanIsNotResumable(_ flightPlan: FlightPlanModel) {
        guard stateMachine.canEnterState(EditableState.self),
              let editableState = stateMachine.state(forClass: EditableState.self) else { return }
        ULog.i(.tag, "Initializing flight plan is NOT resumable")
        editableState.flightPlan = flightPlan
        enter(EditableState.self)
    }
}

extension FlightPlanStateMachineImpl: ResumableStateDelegate {
    public func flightPlanIsResumable(_ flightPlan: FlightPlanModel, startAvailability: FlightPlanStartAvailability) {
        ULog.i(.tag, "Flight plan is in resumable state with availability \(startAvailability)")
        statePrivate.send(.resumable(flightPlan, startAvailability: startAvailability))
    }
}

extension FlightPlanStateMachineImpl: EditableStateDelegate {
    public func flightPlanIsEditable(_ flightPlan: FlightPlanModel, startAvailability: FlightPlanStartAvailability) {
        ULog.i(.tag, "Flight plan is in editable state with availability \(startAvailability)")
        statePrivate.send(.editable(flightPlan, startAvailability: startAvailability))
    }
}

extension FlightPlanStateMachineImpl: StartedNotFlyingStateDelegate {

    open func handleMavlinkGenerationError(flightPlan: FlightPlanModel, _ error: MavlinkGenerationError) {
        ULog.e(.tag, "Mavlink generation error: \(error.localizedDescription)")
        goToEditableState(flightPlan: flightPlan)
    }

    open func handleMavlinkSendingError(flightPlan: FlightPlanModel, _ error: MavlinkDroneSenderError) {
        ULog.e(.tag, "Mavlink sending error: \(error.localizedDescription)")
        goToEditableState(flightPlan: flightPlan)
    }

    open func handleMavlinkManagementSuccess(flightPlan: FlightPlanModel, commands: [MavlinkStandard.MavlinkCommand]) {
        ULog.i(.tag, "Mavlink management success")
        guard stateMachine.canEnterState(StartedFlyingState.self),
              let startedFlyingState = stateMachine.state(forClass: StartedFlyingState.self) else { return }
        startedFlyingState.setup(flightPlan: flightPlan, commands: commands, lastMissionItemExecuted: nil)
        enter(StartedFlyingState.self)
    }

    open func mavlinkGenerationStarted(flightPlan: FlightPlanModel) {
        ULog.i(.tag, "Mavlink generation started")
        statePrivate.send(.startedNotFlying(flightPlan, .generating))
    }

    open func mavlinkSendingStarted(flightPlan: FlightPlanModel) {
        ULog.i(.tag, "Mavlink sending started")
        statePrivate.send(.startedNotFlying(flightPlan, .sending))
    }
}

extension FlightPlanStateMachineImpl: StartedFlyingStateDelegate {
    open func flightPlanRunDidFinish(flightPlan: FlightPlanModel, completed: Bool) {
        ULog.i(.tag, "Flight plan run did finish, completed: \(completed)")
        guard stateMachine.canEnterState(EndedState.self),
              let endedState = stateMachine.state(forClass: EndedState.self) else { return }
        endedState.flightPlan = flightPlan
        endedState.completed = completed
        enter(EndedState.self)
    }


    public func flightPlanRunDidTimeout(flightPlan: FlightPlanModel) {
        ULog.i(.tag, "Flight plan run did timeout, resetting everything")
        open(flightPlan: flightPlan)
    }

    public func flightPlanRunDidBegin(flightPlan: FlightPlanModel) {
        ULog.i(.tag, "Flight plan run did begin")
    }
}

extension FlightPlanStateMachineImpl: EndedStateDelegate {
    public func flightPlanEnded(flightPlan: FlightPlanModel, completed: Bool) {
        ULog.i(.tag, "Flight plan ended")
        statePrivate.send(.end(flightPlan))
        open(flightPlan: flightPlan)
    }
}

extension FlightPlanStateMachineImpl: FlightPlanStateMachine {

    public var state: AnyPublisher<FlightPlanStateMachineState, Never> {
        statePrivate.eraseToAnyPublisher()
    }

    public func updateSafely(flightPlan: FlightPlanModel, _ updateBlock: (FlightPlanModel) -> Void) {
        guard flightPlan.uuid == currentFlightPlan?.uuid else {
            let flightPlan = manager.flightPlan(uuid: flightPlan.uuid) ?? flightPlan
            updateBlock(flightPlan)
            return
        }
        let flightPlan = currentFlightPlan ?? flightPlan
        updateBlock(flightPlan)
        if let flightPlan = manager.flightPlan(uuid: flightPlan.uuid) {
            propagateUpdatedFlightPlan(flightPlan)
        }

    }

    // MARK: - Initializing state

    public func open(flightPlan: FlightPlanModel) {
        ULog.i(.tag, "COMMAND: open")
        reset()
        statePrivate.value = .machineStarted
        guard stateMachine.canEnterState(InitializingState.self),
              let initialState = stateMachine.state(forClass: InitializingState.self) else { return }
        // share the flight plan to be opened with the Initializing State
        initialState.flightPlan = flightPlan
        enter(InitializingState.self)
    }

    // MARK: - Resumable state

    public func forceEditable() {
        guard case .resumable(let flightPlan, _) = statePrivate.value,
              stateMachine.canEnterState(EditableState.self),
              let editableState = stateMachine.state(forClass: EditableState.self) else { return }
        ULog.i(.tag, "COMMAND: forceEditable")
        editableState.flightPlan = flightPlan
        enter(EditableState.self)
    }

    // MARK: Started not flying state

    public func start() {
        ULog.i(.tag, "COMMAND: start with state \(statePrivate.value)")
        switch statePrivate.value {
        case .machineStarted, .initialized, .end, .startedNotFlying:
            ULog.w(.tag, "COMMAND: start not possible with state \(statePrivate.value)")
        case .editable(_, let startAvailability),
             .resumable(_, let startAvailability):
            switch startAvailability {
            case .available:
                // Good to go
                goToStartedNotFlying()
            case .unavailable, .alreadyRunning:
                ULog.w(.tag, "COMMAND: start not possible with state \(statePrivate.value)")
            }
        case .flying:
            // The run may be paused, let's try to resume it
            guard let state = stateMachine.currentState as? StartedFlyingState else {
                ULog.w(.tag, "COMMAND: inconsistency between exposed state \(statePrivate.value) and machine state != StartedFlyingState")
                return
            }
            state.resumePausedRun()
        }
    }

    // MARK: Started flying state

    public func stop() {
        // Stop preparing or flying
        guard let state = stateMachine.currentState,
              let flightPlan = currentFlightPlan else { return }
        ULog.i(.tag, "COMMAND: stop")
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
        ULog.i(.tag, "COMMAND: pause")
        startedFlyingState.pause()
    }

    public func reset() {
        ULog.i(.tag, "COMMAND: reset")
        if let currentState = stateMachine.currentState {
            if let startedNotFlying = currentState as? StartedNotFlyingState {
                startedNotFlying.stop()
            }
            if let startedFlying = currentState as? StartedFlyingState {
                startedFlying.stop()
            }
        }
        buildStates()
    }

    public func flightPlanWasEdited(flightPlan: FlightPlanModel) {
        guard let editableState = stateMachine.currentState as? EditableState,
              case .editable(_, let startAvailability) = statePrivate.value,
              currentFlightPlan?.uuid == flightPlan.uuid else { return }
        editableState.flightPlan = flightPlan
        statePrivate.send(.editable(flightPlan, startAvailability: startAvailability))
    }

    public func catchUp(flightPlan: FlightPlanModel, lastMissionItemExecuted: Int) {
        ULog.i(.tag, "COMMAND: catch up on flight plan \(flightPlan.uuid), last item: \(lastMissionItemExecuted)")
        if case let .flying(stateFp) = statePrivate.value, stateFp.uuid == flightPlan.uuid {
            // Run manager has already the FP loaded, it should catch up on its own
            return
        }
        reset()
        mavlinkGenerator.generateMavlink(for: flightPlan) { [unowned self] result in
            guard let flyingState = stateMachine.state(forClass: StartedFlyingState.self) else { return }
            guard case let .success(mavlinkResult) = result else {
                ULog.w(.tag, "catch up: failed to get mavlink commands of FP \(flightPlan.uuid)")
                return
            }
            flyingState.setup(flightPlan: flightPlan, commands: mavlinkResult.commands, lastMissionItemExecuted: lastMissionItemExecuted)
            enter(StartedFlyingState.self)
        }
    }
}
