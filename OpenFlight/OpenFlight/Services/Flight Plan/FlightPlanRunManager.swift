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

import Combine
import GroundSdk

private extension ULogTag {
    static let tag = ULogTag(name: "FlightPlanRunManager")
}

public protocol FlightPlanRunManager {

    /// Total number of waypoint for the current flightplan
    var totalNumberWayPoint: Int { get }

    /// Current publisher completion progress (from 0.0 to 1.0).
    var progressPublisher: AnyPublisher<Double, Never> { get }

    /// Current publisher running duration.
    var durationPublisher: AnyPublisher<TimeInterval, Never> { get }

    /// Flight Plan run state publisher.
    var statePublisher: AnyPublisher<FlightPlanRunningState, Never> { get }

    /// Ran distance publisher
    var distancePublisher: AnyPublisher<Double, Never> { get }

    /// Start an execution or resume an interrupted one (for resuming a paused execution see unpause)
    /// The manager will try to resume if the latestMissionItemExecuted of the flightPlan provided via `setup` is > 0
    func play()

    /// Pause a running execution
    func pause()

    /// Resume a paused execution
    func unpause()

    /// Stop a running execution
    func stop()

    /// Set the flightplan to run
    func setup(flightPlan: FlightPlanModel, mavlinkCommands: [MavlinkStandard.MavlinkCommand])

    /// Try to catch up on already running flight plan
    func catchUp(lastMissionItemExecuted: Int)

    /// Forgets any previously loaded Flight Plan and stops updating itself
    func reset()

    /// In case any external process updates synchronously and safely the running flight plan, this function should be called
    /// to notify this manager
    ///
    /// - Parameter flightPlan: the updated flight plan
    func flightPlanWasUpdated(_ flightPlan: FlightPlanModel)
}

public enum FlightPlanActivationFailureReason: Equatable {
    case noFlightPlan
    case droneNotReady
    case activationError(FlightPlanActivationError)
}

public enum FlightPlanRunningState: CustomStringConvertible {
    case noFlightPlan
    case idle(flightPlan: FlightPlanModel, startAvailability: FlightPlanStartAvailability)
    case activationError(FlightPlanActivationFailureReason)
    case playing(droneConnected: Bool, flightPlan: FlightPlanModel, rth: Bool)
    case paused(flightPlan: FlightPlanModel, startAvailability: FlightPlanStartAvailability)
    case ended(completed: Bool, flightPlan: FlightPlanModel)

    public var description: String {
        switch self {
        case .noFlightPlan:
            return "noFlightPlan"
        case .idle(flightPlan: let flightPlan, startAvailability: let startAvailability):
            return "idle(fp: \(flightPlan.uuid), startAvailability: \(startAvailability))"
        case .activationError(let reasons):
            return "activationError(reasons: \(reasons))"
        case .playing(droneConnected: let droneConnected, flightPlan: let flightPlan, rth: let rth):
            return "playing(fp: \(flightPlan.uuid), droneConnected: \(droneConnected), rth: \(rth))"
        case .paused(flightPlan: let flightPlan, startAvailability: let startAvailability):
            return "paused(fp: \(flightPlan.uuid), startAvailability: \(startAvailability))"
        case .ended(completed: let completed, flightPlan: let flightPlan):
            return "ended(fp: \(flightPlan.uuid), completed: \(completed))"
        }
    }

    public var flightPlan: FlightPlanModel? {
        switch self {
        case .noFlightPlan:
            return nil
        case .idle(flightPlan: let flightPlan, _):
            return flightPlan
        case .activationError(_):
            return nil
        case .playing(_, flightPlan: let flightPlan, _):
            return flightPlan
        case .paused(flightPlan: let flightPlan, _):
            return flightPlan
        case .ended(_, flightPlan: let flightPlan):
            return flightPlan
        }
    }

    var isActive: Bool {
        switch self {
        case .playing,
             .paused:
            return true
        default:
            return false
        }
    }
}

public class FlightPlanRunManagerImpl {

    private enum WantedState {
        case none
        case playing
        case paused
        case stopped
    }

    // MARK: - Private Properties
    private let activeFlightPlanWatcher: ActiveFlightPlanExecutionWatcher
    private let typeStore: FlightPlanTypeStore
    private let projectRepo: ProjectRepository
    private let flightPlanManager: FlightPlanManager
    private unowned var currentDroneHolder: CurrentDroneHolder
    private var flightPlanTypeStore: FlightPlanTypeStore?

    private var flightPlanPilotingRef: Ref<FlightPlanPilotingItf>?
    private var cancellables = Set<AnyCancellable>()
    private var runningTimer: Timer?
    private var flightPlan: FlightPlanModel?
    private var wantedState = WantedState.none

    // MARK: Utility properties
    /// Flight Plan running duration.
    private var durationSubject = CurrentValueSubject<TimeInterval, Never>(0.0)
    /// Flight Plan run state.
    private var stateSubject = CurrentValueSubject<FlightPlanRunningState, Never>(.noFlightPlan)

    // MARK: SDK properties
    /// Latest mission item executed.
    private(set) var latestItemExecuted: Int?
    /// MAVLink commands.
    private var mavlinkCommands: [MavlinkStandard.MavlinkCommand] = []
    /// Current completion progress (from 0.0 to 1.0).
    private var progressSubject = CurrentValueSubject<Double, Never>(0.0)
    /// Traveled distance.
    private var distanceSubject = CurrentValueSubject<Double, Never>(0.0)

    private var startAvailability: FlightPlanStartAvailability = .available

    private var connectionStateRef: Ref<DeviceState>?

    /// Returns last passed waypoint index.
    private var lastPassedWayPointIndex: Int? {
        guard let latestItem = self.latestItemExecuted else { return nil }

        return mavlinkCommands
            .prefix(latestItem + 1)
            .filter { $0 is MavlinkStandard.NavigateToWaypointCommand }
            .count - 1
    }

    // MARK: - Private Enums
    private enum Constants {
        static let timerDelay: Double = 1.0
        static let progressRoundPrecision: Int = 2
    }

    init(typeStore: FlightPlanTypeStore,
         projectRepo: ProjectRepository,
         currentDroneHolder: CurrentDroneHolder,
         activeFlightPlanWatcher: ActiveFlightPlanExecutionWatcher,
         flightPlanManager: FlightPlanManager,
         startAvailabilityWatcher: FlightPlanStartAvailabilityWatcher) {
        self.typeStore = typeStore
        self.projectRepo = projectRepo
        self.currentDroneHolder = currentDroneHolder
        self.activeFlightPlanWatcher = activeFlightPlanWatcher
        self.flightPlanManager = flightPlanManager
        startAvailabilityWatcher.availabilityForRunningPublisher.sink { [unowned self] in
            startAvailability = $0
            if case let .paused(flightPlan, _) = stateSubject.value {
                updateState(.paused(flightPlan: flightPlan, startAvailability: startAvailability))
            }
            if case let .idle(flightPlan, _) = stateSubject.value {
                updateState(.idle(flightPlan: flightPlan, startAvailability: startAvailability))
            }
        }
        .store(in: &cancellables)
        self.currentDroneHolder.dronePublisher.sink { [unowned self] drone in
            listenFlightPlanPiloting(drone: drone)
            listenConnectionState(drone: drone)
        }
        .store(in: &cancellables)
    }
}

private extension FlightPlanRunManagerImpl {

    func updateState(_ state: FlightPlanRunningState) {
        ULog.i(.tag, "State updated to \(state)")
        stateSubject.value = state
    }

    func listenConnectionState(drone: Drone) {
        self.connectionStateRef = drone.getState { [unowned self] deviceState in
            let isConnected = deviceState?.connectionState == .connected
            switch stateSubject.value {
            case let .playing(oldIsConnected, flightPlan, rth):
                if oldIsConnected != isConnected {
                    updateState(.playing(droneConnected: isConnected, flightPlan: flightPlan, rth: rth))
                }
            default:
                break
            }
        }
    }

    func listenFlightPlanPiloting(drone: Drone) {
        flightPlanPilotingRef = drone.getPilotingItf(PilotingItfs.flightPlan) { [unowned self] flightPlanPiloting in
            guard let pilotingItf = flightPlanPiloting, let flightPlan = flightPlan else { return }
            updateLatestItem(itf: pilotingItf)
            ULog.i(.tag, "PilotingItf.state changed to \(pilotingItf.state), wantedState = \(wantedState), run state = \(stateSubject.value)")
            switch pilotingItf.state {
            // When the itf is not active
            case .idle, .unavailable:
                stopRunningTimer()
                switch stateSubject.value {
                case .playing:
                    // Current state is playing: not consistent with itf state
                    switch wantedState {
                    case .none:
                        break
                    case .playing:
                        // Idle but not user initiated, means the flight plan stopped on its own
                        handleFlightEnds(flightPlan: flightPlan) // State is updated here
                    case .paused:
                        // Pause did succeed
                        updateState(.paused(flightPlan: flightPlan, startAvailability: startAvailability))
                    case .stopped:
                        // Stop asked, and it happened
                        handleFlightEnds(flightPlan: flightPlan) // State is updated here
                    }
                case .activationError, .ended, .noFlightPlan, .paused, .idle:
                    // Consistent with the current state = nothing changed
                    break
                }
            case .active:
                startRunningTimer()
                switch stateSubject.value {
                case .activationError, .paused, .idle:
                    // Current state is not playing: not consistent with itf state
                    switch wantedState {
                    case .none:
                        break
                    case .playing:
                        playDidStart(flightPlan: flightPlan) // State is updated here
                    case .paused, .stopped:
                        // We want to deactivate the itf, let's try again
                        _ = pilotingItf.deactivate()
                    }
                case .playing:
                    // Consistent with the current state = nothing changed
                    break
                case .noFlightPlan, .ended:
                    // Should never happen, don't handle
                    break
                }
            }
        }
    }

    func isInRth() -> Bool {
        if hasRth,
           let latestItemExecuted = latestItemExecuted,
           mavlinkCommands.contains(where: { $0 is MavlinkStandard.ReturnToLaunchCommand }),
           latestItemExecuted >= (mavlinkCommands.firstIndex(where: { $0 is MavlinkStandard.ReturnToLaunchCommand }) ?? Int.max) - 1 {
            return true
        }
        return false
    }

    func updateLatestItem(itf: FlightPlanPilotingItf) {
        // Find largest mavlink index between latest skipped and executed items
        var largestMissionItem: Int?
        if let latestSkipped = itf.latestMissionItemSkipped {
            largestMissionItem = latestSkipped
        }
        if let latestExecuted = itf.latestMissionItemExecuted {
            largestMissionItem = max(largestMissionItem ?? -1, latestExecuted)
        }

        // Update latest item executed only if received idx is greater than current idx
        if let largestMissionItem = largestMissionItem,
           largestMissionItem > self.latestItemExecuted ?? 0 {
            self.latestItemExecuted = largestMissionItem
        }
        if case let .playing(droneConnected, flightPlan, _) = stateSubject.value {
            updateState(.playing(droneConnected: droneConnected, flightPlan: flightPlan, rth: isInRth()))
        }
    }

    /// Return the index of the last mavlink command
    var lastMavlinkCommandIndex: Int {
        var lastIndex = mavlinkCommands.count - 1
        // mavlinkCommands is an ordered list. Search for the first RTH in the list and use the
        // previous index as the last mavlink command item. Note: A potential flightplan
        // with more than one RTH will be marked as completed as long as the first one of them
        // was reached.
        if let firstRthIndex = mavlinkCommands.firstIndex(where: { $0 is MavlinkStandard.ReturnToLaunchCommand }) {
            lastIndex = firstRthIndex - 1
        }
        return lastIndex
    }

    // MARK: - Helpers
    /// Helper to retrieve current FlightPlanPilotingItf in a safe way.
    /// - Returns: FlightPlanPilotingItf as optional
    func getPilotingItf() -> FlightPlanPilotingItf? {
        return self.currentDroneHolder.drone.getPilotingItf(PilotingItfs.flightPlan)
    }

    func handleFlightEnds(flightPlan: FlightPlanModel) {
        var completed = false
        var flightPlan = flightPlan
        if let latestItemExecuted = latestItemExecuted {
            if latestItemExecuted >= lastMavlinkCommandIndex {
                completed = true
            }
            flightPlan = flightPlanManager.update(flightPlan: flightPlan, lastMissionItemExecuted: latestItemExecuted)
            self.flightPlan = flightPlan
        }
        activeFlightPlanWatcher.flightPlanDidStop(flightPlan)
        updateState(.ended(completed: completed, flightPlan: flightPlan))
    }

    // MARK: - Timer
    /// Starts timer for running time.
    func startRunningTimer() {
        guard runningTimer == nil else { return }
        runningTimer = Timer.scheduledTimer(withTimeInterval: Constants.timerDelay,
                                            repeats: true,
                                            block: { [weak self] _ in
                                                self?.updateDuration()
                                                self?.updateProgress()
                                            })
        runningTimer?.fire()
    }

    /// Stops timer for running time.
    func stopRunningTimer() {
        runningTimer?.invalidate()
        runningTimer = nil
    }

    /// Updates Flight Plan's duration.
    func updateDuration() {
        durationSubject.value += Constants.timerDelay
    }

    /// Updates Flight Plan's completion progress.
    func updateProgress() {
        guard let currentLocation = currentDroneHolder.drone.getInstrument(Instruments.gps)?.lastKnownLocation,
              let lastPassedWayPointIndex = lastPassedWayPointIndex,
              let dataSetting = flightPlan?.dataSetting else { return }

        let newProgress = dataSetting.completionProgress(with: currentLocation.agsPoint,
                                                         lastWayPointIndex: lastPassedWayPointIndex).rounded(toPlaces: Constants.progressRoundPrecision)

        progressSubject.value = newProgress
        // TODO: implement a real traveled distance calculator instead of this.
        distanceSubject.value = newProgress * (dataSetting.estimations.distance ?? 0.0)
    }

    func playDidStart(flightPlan: FlightPlanModel) {
        let flightPlan = flightPlan
        activeFlightPlanWatcher.flightPlanActivationSucceeded(flightPlan)
        stateSubject.value = .playing(droneConnected: true, flightPlan: flightPlan, rth: isInRth())
    }
}

extension FlightPlanRunManagerImpl: FlightPlanRunManager {

    public var totalNumberWayPoint: Int {
        lastMavlinkCommandIndex
    }

    private var hasRth: Bool {
        mavlinkCommands
            .contains(where: { $0 is MavlinkStandard.ReturnToLaunchCommand })
    }

    public var progressPublisher: AnyPublisher<Double, Never> { progressSubject.eraseToAnyPublisher() }

    public var durationPublisher: AnyPublisher<TimeInterval, Never> { durationSubject.eraseToAnyPublisher() }

    public var statePublisher: AnyPublisher<FlightPlanRunningState, Never> { stateSubject.eraseToAnyPublisher() }

    public var distancePublisher: AnyPublisher<Double, Never> { distanceSubject.eraseToAnyPublisher() }

    public func play() {
        ULog.i(.tag, "Command: play()")
        guard let interface = self.getPilotingItf() else {
            updateState(.activationError(.droneNotReady))
            return
        }
        guard let flightPlan = flightPlan else {
            updateState(.activationError(.noFlightPlan))
            return
        }
        // Check interpreter.
        var interpreter: FlightPlanInterpreter = .standard
        let fpStringType = flightPlan.type
        if let flightPlanType = flightPlanTypeStore?.typeForKey(fpStringType) {
            interpreter = flightPlanType.mavLinkType
        }

        // Let the FP watcher know the FP will be activated
        activeFlightPlanWatcher.flightPlanWillBeActivated(flightPlan)

        wantedState = .playing
        let result: Bool
        // Start run.
        ULog.i(.tag, "Activate with:\n"
               + "- latestItemExecuted = \(String(describing: latestItemExecuted))\n"
                + "- activateAtMissionItemSupported = \(interface.activateAtMissionItemSupported)\n")
        if let latestItemExecuted = latestItemExecuted,
           latestItemExecuted > 0,
           interface.activateAtMissionItemSupported {
            // Resume flight plan at missionItem.
            result = interface.activate(restart: true,
                                        interpreter: interpreter,
                                        missionItem: latestItemExecuted)
        } else {
            // Start flight plan from its begining.
            result = interface.activate(restart: true,
                                        interpreter: interpreter,
                                        missionItem: 0)
        }
        if !result {
            activeFlightPlanWatcher.flightPlanActivationFailed(flightPlan)
        }
    }

    public func unpause() {
        ULog.i(.tag, "Command: unpause()")
        guard let interface = self.getPilotingItf(), interface.isPaused else {
            updateState(.activationError(.droneNotReady))
            return
        }
        guard let flightPlan = flightPlan else {
            updateState(.activationError(.noFlightPlan))
            return
        }
        guard case .paused = stateSubject.value else {
            ULog.w(.tag, "Unpause asked while not in pause. Current state: \(stateSubject.value)")
            return
        }
        var interpreter: FlightPlanInterpreter = .standard
        let fpStringType = flightPlan.type
        if let flightPlanType = flightPlanTypeStore?.typeForKey(fpStringType) {
            interpreter = flightPlanType.mavLinkType
        }
        wantedState = .playing
        _ = interface.activate(restart: false,
                               interpreter: interpreter,
                               missionItem: latestItemExecuted ?? 0)
    }

    public func catchUp(lastMissionItemExecuted: Int) {
        guard let flightPlan = flightPlan else { return }
        wantedState = .playing
        self.latestItemExecuted = lastMissionItemExecuted
        startRunningTimer()
        playDidStart(flightPlan: flightPlan)
    }

    public func pause() {
        ULog.i(.tag, "Command: pause")
        // Ensure the running timer is stopped (the itf update may not be triggered)
        stopRunningTimer()
        guard case .playing = stateSubject.value else {
            ULog.w(.tag, "Cannot pause with state \(stateSubject.value)")
            return
        }
        guard flightPlan != nil else { return }
        wantedState = .paused
        _ = getPilotingItf()?.deactivate()
    }

    public func stop() {
        ULog.i(.tag, "Command: stop")
        // Ensure the running timer is stopped (the itf update may not be triggered)
        stopRunningTimer()
        guard let flightPlan = flightPlan else { return }
        wantedState = .none
        _ = getPilotingItf()?.deactivate()
        handleFlightEnds(flightPlan: flightPlan)
    }

    public func setup(flightPlan: FlightPlanModel, mavlinkCommands: [MavlinkStandard.MavlinkCommand]) {
        ULog.i(.tag, "Command: setup \(flightPlan.uuid)")
        reset()
        self.flightPlan = flightPlan
        self.mavlinkCommands = mavlinkCommands
        if flightPlan.lastMissionItemExecuted > 0 {
            latestItemExecuted = Int(flightPlan.lastMissionItemExecuted)
        }
        updateState(.idle(flightPlan: flightPlan, startAvailability: startAvailability))
    }

    public func flightPlanWasUpdated(_ flightPlan: FlightPlanModel) {
        guard flightPlan.uuid == self.flightPlan?.uuid else { return }
        self.flightPlan = flightPlan
        // Make sure the state holds the right flight plan value
        switch stateSubject.value {
        case .noFlightPlan:
            break
        case .idle(_, let startAvailability):
            stateSubject.value = .idle(flightPlan: flightPlan, startAvailability: startAvailability)
        case .activationError:
            break
        case .playing(let droneConnected, _, let rth):
            stateSubject.value = .playing(droneConnected: droneConnected, flightPlan: flightPlan, rth: rth)
        case .paused(_, let startAvailability):
            stateSubject.value = .paused(flightPlan: flightPlan, startAvailability: startAvailability)
        case .ended(let completed, let flightPlan):
            stateSubject.value = .ended(completed: completed, flightPlan: flightPlan)
        }
    }

    public func reset() {
        ULog.i(.tag, "Command: Reset")
        self.flightPlan = nil
        self.wantedState = .none
        self.mavlinkCommands = []
        self.distanceSubject.value = 0
        self.durationSubject.value = 0
        self.latestItemExecuted = -1
        self.progressSubject.value = 0
        updateState(.noFlightPlan)
    }
}
