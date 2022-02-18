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

import GameKit
import Combine
import GroundSdk

public protocol StartedFlyingStateDelegate: AnyObject {
    func flightPlanRunWillBegin(flightPlan: FlightPlanModel)
    func flightPlanRunDidTimeout(flightPlan: FlightPlanModel)
    func flightPlanRunDidBegin(flightPlan: FlightPlanModel)
    func flightPlanRunDidPause(flightPlan: FlightPlanModel)
    func flightPlanRunDidFinish(flightPlan: FlightPlanModel, completed: Bool)
}

private extension ULogTag {
    static let tag = ULogTag(name: "FPStartedFlyingState")
}

open class StartedFlyingState: GKState {

    private enum Constants {
        static let activationTimerInterval: TimeInterval = 1
        static let activationTimeout: TimeInterval = 10
    }

    private enum State {
        case activating
        case running
        case error
        case finished
    }

    private weak var delegate: StartedFlyingStateDelegate?
    public let runManager: FlightPlanRunManager
    public let flightPlanManager: FlightPlanManager
    public let projectManager: ProjectManager
    private var activateTimer: Timer?
    var flightPlan: FlightPlanModel!
    var commands: [MavlinkStandard.MavlinkCommand]!
    private var runState = FlightPlanRunningState.noFlightPlan
    private var cancellables = Set<AnyCancellable>()
    private var state = State.activating
    private var lastMissionItemExecutedOnStart: Int?
    private var recoveryResourceId: String?
    private var durationOnStart: TimeInterval?

    required public init(delegate: StartedFlyingStateDelegate,
                         runManager: FlightPlanRunManager,
                         flightPlanManager: FlightPlanManager,
                         projectManager: ProjectManager) {
        self.delegate = delegate
        self.runManager = runManager
        self.flightPlanManager = flightPlanManager
        self.projectManager = projectManager
        super.init()
    }

    open override func didEnter(from previousState: GKState?) {
        // If it's not a resume, update the customTitle to add the execution index.
        if flightPlan.state == .editable {
            flightPlan = projectManager.updateExecutionCustomTitle(for: flightPlan)
        }
        flightPlan = flightPlanManager.update(flightplan: flightPlan, with: .flying)
        delegate?.flightPlanRunWillBegin(flightPlan: flightPlan)
        runManager.setup(flightPlan: flightPlan, mavlinkCommands: commands)
        let oldState = state
        if lastMissionItemExecutedOnStart != nil {
            state = .running
        } else {
            state = .activating
        }
        ULog.i(.tag, "state changed to '\(state)' from '\(oldState)'")
        runManager.statePublisher.sink { [unowned self] newState in
            runState = newState
            // Keep FP up to date
            if let flightPlan = runState.flightPlan {
                self.flightPlan = flightPlan
            }
            switch state {
            case .activating:
                // if the runState failed to activate, firing the timer will create an infinite
                // recursion that will provoke a stack overflow and crash the application.
                if case .activationError = newState {
                    break
                }
                activateTimer?.fire()
            case .running:
                handleRunUpdate()
            case .error, .finished:
                break
            }
        }
        .store(in: &cancellables)
        if let lastMissionItemExecuted = self.lastMissionItemExecutedOnStart,
           let duration = self.durationOnStart {
            runManager.catchUp(lastMissionItemExecuted: lastMissionItemExecuted,
                               recoveryResourceId: recoveryResourceId,
                               duration: duration)
        } else {
            activate()
        }
    }

    private func activate() {
        let startDate = Date()
        runManager.play()
        activateTimer = Timer.scheduledTimer(withTimeInterval: Constants.activationTimerInterval, repeats: true) { [unowned self] _ in
            if Date().timeIntervalSince(startDate) > Constants.activationTimeout {
                activateTimer?.invalidate()
                state = .error
                delegate?.flightPlanRunDidTimeout(flightPlan: flightPlan)
                return
            }
            switch runState {
            case let .playing(_, flightPlan, _):
                activateTimer?.invalidate()
                // Up to date flight plan
                self.flightPlan = flightPlan
                delegate?.flightPlanRunDidBegin(flightPlan: flightPlan)
                state = .running
            case let .activationError(reason):
                if reason == .cannotTakeOff {
                    activateTimer?.invalidate()
                    state = .error
                    delegate?.flightPlanRunDidTimeout(flightPlan: flightPlan)
                } else {
                    // Retry
                    runManager.play()
                }
            case .idle:
                // Transient state
                break
            case .noFlightPlan, .ended, .paused:
                activateTimer?.invalidate()
                ULog.w(.tag, "Inconsistent runState while activating runState: '\(runState)' state: '\(state)'")
            }
        }
        activateTimer?.tolerance = FlightPlanConstants.timerTolerance
        activateTimer?.fire()
    }

    private func handleRunUpdate() {
        switch runState {
        case .playing:
            // Ok, still running
            break
        case .paused(flightPlan: let flightPlan, startAvailability: _):
            // Informs the State Machine Flight Plan is paused.
            delegate?.flightPlanRunDidPause(flightPlan: flightPlan)
        case .noFlightPlan, .activationError, .idle:
            ULog.w(.tag, "Inconsistent runState while running runState: '\(runState)' state: '\(state)'")
        case .ended(let completed, flightPlan: let flightPlan):
            state = .finished
            self.flightPlan = flightPlan
            delegate?.flightPlanRunDidFinish(flightPlan: flightPlan, completed: completed)
        }
    }

    open func setup(flightPlan: FlightPlanModel, commands: [MavlinkStandard.MavlinkCommand],
                    lastMissionItemExecuted: Int?, recoveryResourceId: String?, runningTime: TimeInterval?) {
        self.flightPlan = flightPlan
        self.commands = commands
        if let lastMissionItemExecuted = lastMissionItemExecuted {
            lastMissionItemExecutedOnStart = lastMissionItemExecuted
            state = .running
        } else {
            lastMissionItemExecutedOnStart = nil
            state = .activating
        }
        self.recoveryResourceId = recoveryResourceId

        if let duration = runningTime {
            durationOnStart = duration
        } else {
            durationOnStart = 0
        }
    }

    open func stop() {
        runManager.stop()
    }

    open func pause() {
        runManager.pause()
    }

    open func resumePausedRun() {
        runManager.unpause()
    }

    open func updateRun(lastMissionItemExecuted: Int, recoveryResourceId: String?, runningTime: TimeInterval) {
        runManager.catchUp(lastMissionItemExecuted: lastMissionItemExecuted,
                           recoveryResourceId: recoveryResourceId,
                           duration: runningTime)
    }

    open func flightPlanWasUpdated(_ flightPlan: FlightPlanModel) {
        self.flightPlan = flightPlan
        runManager.flightPlanWasUpdated(flightPlan)
    }

    open override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is EndedState.Type
            || stateClass is IdleState.Type
    }

    open override func willExit(to nextState: GKState) {
        cancellables = []
        activateTimer?.invalidate()
        runManager.reset()
    }

}
