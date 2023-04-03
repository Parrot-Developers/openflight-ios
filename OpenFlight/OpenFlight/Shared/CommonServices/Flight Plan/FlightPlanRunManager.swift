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

// swiftlint:disable file_length

import Combine
import GroundSdk
import Pictor

private extension ULogTag {
    static let tag = ULogTag(name: "FPRunManager")
}

public protocol FlightPlanRunManager: AnyObject {

    /// Total number of waypoint for the current flightplan
    var totalNumberWayPoint: Int { get }

    /// Current publisher completion progress (from 0.0 to 1.0).
    var progressPublisher: AnyPublisher<Double, Never> { get }

    /// Current publisher running duration.
    var durationPublisher: AnyPublisher<TimeInterval, Never> { get }

    /// The Drone is navigating to the first or last executed  way point.
    var navigatingToStartingPointPublisher: AnyPublisher<Bool, Never> { get }

    /// Flight Plan run state publisher.
    var statePublisher: AnyPublisher<FlightPlanRunningState, Never> { get }

    /// Flight Plan run state.
    var state: FlightPlanRunningState { get }

    /// The Drone is ready to receive commands.
    var interfaceReadyPublisher: AnyPublisher<Bool, Never> { get }

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
    ///
    /// - Parameter forced: whether the FP RTH, if enabled, must also be aborted
    ///
    /// - Description:
    ///     There are some cases (as switching to another mission) where we need to handle the FP as ended and stop, if needed, its RTH.
    ///     This prevents to let the Run Manager and State Machine in incorrect states.
    ///     By default this value will be `false`, but when called from a `reset` command, it will be set to `true`
    ///     forcing the end of the FP and its RTH.
    func stop(forced: Bool)

    ///  Performs dedicated actions after an activation timeout.
    func handleTimeout(flightPlan: FlightPlanModel)

    /// Set the flightplan to run
    func setup(flightPlan: FlightPlanModel, mavlinkCommands: [MavlinkStandard.MavlinkCommand])

    /// Tries to catch up on already running flight plan.
    ///
    /// - Parameters:
    ///   - lastMissionItemExecuted: index of the latest mission item completed
    ///   - recoveryResourceId: first resource identifier of media captured after the latest reached waypoint
    ///   - duration: running time of the flightplan
    func catchUp(lastMissionItemExecuted: Int, recoveryResourceId: String?, duration: TimeInterval)

    /// Forgets any previously loaded Flight Plan and stops updating itself
    func reset()

    /// In case any external process updates synchronously and safely the running flight plan, this function should be called
    /// to notify this manager
    ///
    /// - Parameter flightPlan: the updated flight plan
    func flightPlanWasUpdated(_ flightPlan: FlightPlanModel)

    /// Current playing Flight Plan.
    var playingFlightPlan: FlightPlanModel? { get }

    /// Current playing Flight Plan publisher.
    var playingFlightPlanPublisher: AnyPublisher<FlightPlanModel?, Never> { get }
}

public enum FlightPlanActivationFailureReason: Equatable {
    case noFlightPlan
    case droneNotReady
    case cannotTakeOff
    case activationError(FlightPlanActivationError)
}

public enum FlightPlanRunningState: CustomStringConvertible {
    case noFlightPlan
    case idle(flightPlan: FlightPlanModel, startAvailability: FlightPlanStartAvailability)
    case activationError(FlightPlanActivationFailureReason)
    case playing(droneConnected: Bool, flightPlan: FlightPlanModel, rth: Bool)
    case rth(flightPlan: FlightPlanModel)
    case paused(droneConnected: Bool, flightPlan: FlightPlanModel, startAvailability: FlightPlanStartAvailability)
    case ended(completed: Bool, flightPlan: FlightPlanModel)

    public var description: String {
        switch self {
        case .noFlightPlan:
            return "noFlightPlan"
        case .idle(flightPlan: let flightPlan, startAvailability: let startAvailability):
            return "idle('\(flightPlan.uuid)', startAvailability: \(startAvailability))"
        case .activationError(let reasons):
            return "activationError(reasons: \(reasons))"
        case .playing(droneConnected: let droneConnected, flightPlan: let flightPlan, rth: let rth):
            return "playing('\(flightPlan.uuid)', droneConnected: \(droneConnected), rth: \(rth))"
        case .rth(flightPlan: let flightPlan):
            return "rth('\(flightPlan.uuid)')"
        case .paused(droneConnected: let droneConnected, flightPlan: let flightPlan,
                     startAvailability: let startAvailability):
            return "paused('\(flightPlan.uuid)', droneConnected: \(droneConnected), startAvailability: \(startAvailability))"
        case .ended(completed: let completed, flightPlan: let flightPlan):
            return "ended('\(flightPlan.uuid)', completed: \(completed))"
        }
    }

    public var flightPlan: FlightPlanModel? {
        switch self {
        case .noFlightPlan:
            return nil
        case .idle(flightPlan: let flightPlan, _):
            return flightPlan
        case .activationError:
            return nil
        case .playing(_, flightPlan: let flightPlan, _):
            return flightPlan
        case .rth(flightPlan: let flightPlan):
            return flightPlan
        case .paused(_, flightPlan: let flightPlan, _):
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

    /// Whether the Run Manager is in `.rth` state.
    ///
    /// - Note: This property returns `true` only when the Run Manager state is set to `.rth`,
    ///         but not when its state is `.playing` with its `rth` parameter set to `true`.
    ///         The FP RTH behavior is not correctly defined yet. The RTH UI can be displayed by a
    ///         change on the piloting Interface of the RTH or a change of the FP piloting interface when it has
    ///         reached the last way point.
    // TODO: Clarify and clean the flight plan rth behavior.
    var isRthState: Bool {
        guard case .rth = self else { return false }
        return true
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
    private let projectRepository: PictorProjectRepository
    private let flightPlanManager: FlightPlanManager
    private unowned var currentDroneHolder: CurrentDroneHolder
    private var flightPlanTypeStore: FlightPlanTypeStore?
    private let criticalAlertService: CriticalAlertService

    private var flightPlanPilotingRef: Ref<FlightPlanPilotingItf>?
    private var returnHomeRef: Ref<ReturnHomePilotingItf>?
    private var cancellables = Set<AnyCancellable>()
    private var runningTimer: Timer?
    private var fpConfigTimer: Timer?
    private var fpConfigTimerRestart: Bool
    private var flightPlan: FlightPlanModel?
    private var wantedState = WantedState.none

    // MARK: Utility properties
    /// Flight Plan running duration.
    private var durationSubject = CurrentValueSubject<TimeInterval, Never>(0.0)
    /// Flight Plan run state.
    private var stateSubject = CurrentValueSubject<FlightPlanRunningState, Never>(.noFlightPlan)
    /// Flight Plan run state.
    private var interfaceReadySubject = CurrentValueSubject<Bool, Never>(false)
    /// Current playing Flight Plan.
    private var playingFlightPlanSubject = CurrentValueSubject<FlightPlanModel?, Never>(nil)

    // MARK: SDK properties
    /// Latest mission item executed.
    public var latestItemExecuted: Int?
    /// First resource identifier of media captured after the latest reached waypoint.
    private var recoveryResourceId: String?
    /// MAVLink commands.
    private var mavlinkCommands: [MavlinkStandard.MavlinkCommand] = []
    /// Current completion progress (from 0.0 to 1.0).
    private var progressSubject = CurrentValueSubject<Double, Never>(0.0)
    /// Traveled distance.
    private var distanceSubject = CurrentValueSubject<Double, Never>(0.0)
    /// Informs when drone's navigating to Flight Plan's starting position.
    private var navigatingToStartingPointSubject = CurrentValueSubject<Bool, Never>(false)

    private var startAvailability: FlightPlanStartAvailability = .available(false)

    private var connectionStateRef: Ref<DeviceState>?

    /// Returns last passed waypoint index.
    private var lastPassedWayPointIndex: Int? {
        guard let latestItem = latestItemExecuted else { return nil }
        // Get the waypoints before last mavlink item executed.
        let passedWayPoints = mavlinkCommands
            .prefix(latestItem + 1)
            .filter { $0 is MavlinkStandard.NavigateToWaypointCommand }
        // Ensure at least one waypoint passed.
        guard !passedWayPoints.isEmpty else { return nil }
        // Returns the index.
        return passedWayPoints.count - 1
    }

    // MARK: - Private Enums
    private enum Constants {
        static let timerDelay: Double = 1.0
        static let timerTolerance: Double = 0.1
        static let fpConfigTimerDelay: Double = 0.2
        static let progressRoundPrecision: Int = 4
    }

    init(typeStore: FlightPlanTypeStore,
         projectRepository: PictorProjectRepository,
         currentDroneHolder: CurrentDroneHolder,
         activeFlightPlanWatcher: ActiveFlightPlanExecutionWatcher,
         flightPlanManager: FlightPlanManager,
         startAvailabilityWatcher: FlightPlanStartAvailabilityWatcher,
         criticalAlertService: CriticalAlertService) {
        self.typeStore = typeStore
        self.projectRepository = projectRepository
        self.currentDroneHolder = currentDroneHolder
        self.activeFlightPlanWatcher = activeFlightPlanWatcher
        self.flightPlanManager = flightPlanManager
        self.criticalAlertService = criticalAlertService
        self.fpConfigTimerRestart = false
        startAvailabilityWatcher.availabilityForRunningPublisher.sink { [unowned self] in
            startAvailability = $0
            if case let .paused(droneConnected, flightPlan, _) = stateSubject.value {
                // Check unavailability reason
                if case .unavailable(let pilotingItfReasons) = startAvailability,
                   case .pilotingItfUnavailable(let unavailabilityReasons) = pilotingItfReasons,
                   unavailabilityReasons.contains(.missingFlightPlanFile) {
                    // If missing flightplan file during a pause,
                    // assume the drone was turned off and treat it as a stop
                    handleFlightEnds(flightPlan: flightPlan)
                    return
                }
                updateState(.paused(droneConnected: droneConnected,
                                    flightPlan: flightPlan,
                                    startAvailability: startAvailability))
            }
            if case let .idle(flightPlan, _) = stateSubject.value {
                updateState(.idle(flightPlan: flightPlan, startAvailability: startAvailability))
            }
        }
        .store(in: &cancellables)
        currentDroneHolder.dronePublisher.sink { [unowned self] drone in
            listenFlightPlanPiloting(drone: drone)
            listenToRth(drone: drone)
            listenConnectionState(drone: drone)
        }
        .store(in: &cancellables)
    }
}

private extension FlightPlanRunManagerImpl {

    func updateState(_ state: FlightPlanRunningState) {
        ULog.i(.tag, "State updated to '\(state)' from '\(stateSubject.value)'")
        stateSubject.value = state
        switch state {
        case .playing(_, flightPlan: let flightPlan, _),
                .paused(_, flightPlan: let flightPlan, _),
                .rth(flightPlan: let flightPlan):
            playingFlightPlanSubject.value = flightPlan
        default:
            playingFlightPlanSubject.value = nil
        }
        // Update the `activeFlightPlanWatcher` Flight Plan.
        activeFlightPlanWatcher.flightPlanDidUpdate(playingFlightPlanSubject.value)
    }

    func listenConnectionState(drone: Drone) {
        connectionStateRef = drone.getState { [unowned self] deviceState in
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

    func handlePausedFlightPlan(_ flightPlan: FlightPlanModel) {
        // Get an up to date flight plan state.
        let flightPlan = updatedFlightPlan(flightPlan)
        // When paused, even during an RTH, we don't want to handle the FP has completed.
        // This allows to resume the RTH.
        updateState(.paused(droneConnected: true, flightPlan: flightPlan, startAvailability: startAvailability))
    }

    func handleFlightPlanPilotingActiveState(pilotingItf: FlightPlanPilotingItfs.ApiProtocol) {
        guard let flightPlan = flightPlan else { return }
        switch stateSubject.value {
        case .activationError, .paused, .idle:
            // Current state is not playing: not consistent with itf state
            switch wantedState {
            case .none:
                break
            case .playing:
                playDidStart(flightPlan: flightPlan) // State is updated here
            case .paused:
                // We want to deactivate the itf, let's try again
                _ = pilotingItf.deactivate()
            case .stopped:
                // We want to stop the itf, let's try again
                _ = pilotingItf.stop()
            }
        case .playing, .rth:
            // Consistent with the current state = nothing changed
            break
        case .noFlightPlan, .ended:
            // If a flight plan is stopped during is activation,
            // the stop is not treated by the Piloting Interface.
            // As soon as the Piloting Interface becomes active
            // we ask it to stop then reset the Run Manager state.
            if case .stopped = wantedState {
                _ = pilotingItf.stop()
                reset()
            }
        }
    }

    func handleFlightPlanPilotingNotActiveState(pilotingItf: FlightPlanPilotingItfs.ApiProtocol) {
        guard let flightPlan = flightPlan else { return }
        // Piloting Interface is not active. Reset the 'navigating to starting point' flag if needed.
        navigatingToStartingPointSubject.value = false
        stopRunningTimer()
        switch stateSubject.value {
        case .playing, .rth:
            // Current state is playing: not consistent with itf state
            switch wantedState {
            case .none:
                break
            case .playing:
                // Idle but not user initiated, means the flight plan stopped on its own
                if pilotingItf.isPaused {
                    handlePausedFlightPlan(flightPlan)
                } else {
                    handleFlightEnds(flightPlan: flightPlan) // State is updated here
                }
            case .paused:
                // Pause did succeed
                handlePausedFlightPlan(flightPlan)
            case .stopped:
                // Stop asked, and it happened
                handleFlightEnds(flightPlan: flightPlan) // State is updated here
            }
        case .paused:
            // If FP has been previously paused and a new event is received informing that the
            // piloting interface state changed, check the interface's `isPaused` status to know
            // wether the FP must be stopped.
            guard !pilotingItf.isPaused else { return }
            ULog.i(.tag, "Flight Plan '\(flightPlan.uuid)' stopped after being paused.")
            handleFlightEnds(flightPlan: flightPlan)
        case .activationError, .ended, .noFlightPlan, .idle:
            // Consistent with the current state = nothing changed
            break
        }

    }

    func listenFlightPlanPiloting(drone: Drone) {
        flightPlanPilotingRef = drone.getPilotingItf(PilotingItfs.flightPlan) { [unowned self] flightPlanPiloting in
            guard let pilotingItf = flightPlanPiloting else { return }
            interfaceReadySubject.send(pilotingItf.state != .unavailable)
            updateLatestItem(itf: pilotingItf)
            ULog.i(.tag, "PilotingItf changed to '\(pilotingItf.state)', wantedState = '\(wantedState)', runState = '\(stateSubject.value)'")
            switch pilotingItf.state {
                // When the itf is not active
            case .idle, .unavailable:
                handleFlightPlanPilotingNotActiveState(pilotingItf: pilotingItf)
            case .active:
                handleFlightPlanPilotingActiveState(pilotingItf: pilotingItf)
            }
        }
    }

    func listenToRth(drone: Drone) {
        returnHomeRef = drone.getPilotingItf(PilotingItfs.returnHome) {  [unowned self]  returnHome in
            guard let returnHome = returnHome else { return }

            if returnHome.reason == .flightplan {
                switch stateSubject.value {
                case .playing(let droneConnected, let flightPlan, _), .paused(let droneConnected, let flightPlan, _):
                    if droneConnected {
                        updateState(.rth(flightPlan: flightPlan))
                    }
                case .rth:
                    // If rth is already active when the event arrives, no need to do anything.
                    break
                case .noFlightPlan,
                        .idle,
                        .activationError,
                        .ended:
                    // In all other cases, if the `wantedState`is not `.playing`,
                    // there is an RTH initiated by an FP which should not be executed.
                    // Stopping the FP piloting interface will stop its RTH.
                    guard wantedState != .playing
                    else { return }
                    ULog.i(.tag, "Stop current FP RTH from Run Manager state: '\(stateSubject.value)' and wantedState = '\(wantedState)'")
                    _ = getPilotingItf()?.stop()
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
        // Get the FlightPlan's lastMissionItemExecuted.
        let flightPlanLatestItemExecuted = flightPlan?.pictorModel.lastMissionItemExecuted

        // Find largest mavlink index between latest skipped and executed items
        var largestMissionItem: Int?
        if let latestSkipped = itf.latestMissionItemSkipped {
            largestMissionItem = Int(latestSkipped)
        }
        if let latestExecuted = itf.latestMissionItemExecuted {
            largestMissionItem = max(largestMissionItem ?? -1, Int(latestExecuted))
        }

        // Update latest item executed only if received idx is greater than current idx
        // and is greater or equal to FP's lastMissionItemExecuted (for resumed executions)
        guard let largestMissionItem = largestMissionItem,
              largestMissionItem > latestItemExecuted ?? -1,
              largestMissionItem >= flightPlanLatestItemExecuted ?? 0
        else {
            ULog.i(.tag,
                   "Skipping item."
                   + " largestMissionItem: \(largestMissionItem?.description ?? "nil")"
                   + "/ latestItemExecuted: \(latestItemExecuted?.description ?? "nil")"
                   + "/ flightPlanLatestItemExecuted: \(flightPlanLatestItemExecuted?.description ?? "nil")")
            return
        }

        latestItemExecuted = largestMissionItem

        if case let .playing(droneConnected, flightPlan, _) = stateSubject.value {
            // Update the Flight Plan state.
            var newFlight = flightPlan
            newFlight.pictorModel.lastMissionItemExecuted = latestItemExecuted ?? 0
            updateCompletionState(for: &newFlight)
            // Update current state.
            updateState(.playing(droneConnected: droneConnected, flightPlan: newFlight, rth: isInRth()))
        }
    }

    /// Updates the completion state properties of the flight plan passed in parameter.
    ///
    /// - Parameter flightPlan: the flight plan to update
    func updateCompletionState(for flightPlan: inout FlightPlanModel) {
        let itemIndex = Int(flightPlan.pictorModel.lastMissionItemExecuted)
        flightPlan.hasReachedFirstWayPoint = mavlinkCommands.hasReachedFirstWayPoint(index: itemIndex)
        flightPlan.hasReachedLastWayPoint = mavlinkCommands.hasReachedLastWayPoint(index: itemIndex)
        flightPlan.lastPassedWayPointIndex = mavlinkCommands.lastPassedWayPointIndex(for: itemIndex)
        // The latest item executed has been changed, percentCompleted needs to be computed.
        let percentCompleted = mavlinkCommands.percentCompleted(for: itemIndex, flightPlan: flightPlan)
        flightPlan.percentCompleted = percentCompleted
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
        return currentDroneHolder.drone.getPilotingItf(PilotingItfs.flightPlan)
    }

    /// Returns if an Updated Flight Plan with the last `latestItemExecuted` value.
    ///
    ///  - Parameters:
    ///     - flightPlan: `FlightPlanModel`to treat.
    ///
    ///  - Returns:
    ///     - The updated `FlightPlanModel`.
    ///
    ///  - Note: The local `flightPlan` property and the Core Data FP are also updated.
    func updatedFlightPlan(_ flightPlan: FlightPlanModel) -> FlightPlanModel {
        var flightPlan = flightPlan
        if let latestItemExecuted = latestItemExecuted {
            // Save the updated FP in core data
            flightPlan = flightPlanManager.update(flightPlan: flightPlan,
                                                  lastMissionItemExecuted: latestItemExecuted,
                                                  recoveryResourceId: recoveryResourceId)
            // Update the completion state.
            updateCompletionState(for: &flightPlan)
            // Update local Flight Plan
            self.flightPlan = flightPlan
        }
        return flightPlan
    }

    /// Returns if a Flight Plan is completed or not.
    ///
    ///  - Parameters:
    ///     - flightPlan: `FlightPlanModel`to handle.
    ///
    ///  - Returns:
    ///     - `true` if completed (reached the last way point), or `false`.
    ///
    ///  - Note: An up to date FP must be passed in parameter.
    ///          This method is not responsible to update the FP with les current local `latestItemExecuted`property.
    func isFlightCompleted(flightPlan: FlightPlanModel) -> Bool {
        flightPlan.hasReachedLastWayPoint
    }

    /// Handles ended Flight Plan (completed or not).
    ///
    ///  - Parameters:
    ///     - flightPlan: `FlightPlanModel`to handle.
    func handleFlightEnds(flightPlan: FlightPlanModel) {
        // Get an up to date flight plan state.
        let flightPlan = updatedFlightPlan(flightPlan)
        // Get completion state.
        let completed = flightPlan.hasReachedLastWayPoint
        // Inform the active FP watcher that FP did stop.
        activeFlightPlanWatcher.flightPlanDidStop(flightPlan)
        // Update current state
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
        runningTimer?.tolerance = Constants.timerTolerance
        runningTimer?.fire()
    }

    /// Stops timer for running time.
    func stopRunningTimer() {
        runningTimer?.invalidate()
        runningTimer = nil
    }

    /// Starts timer to wait for media configuration.
    /// - Parameters:
    ///   - restart: should restart interface after media config is finished.
    ///              If false, the interface is resumed instead.
    func startFpConfigTimer(restart: Bool) {
        guard fpConfigTimer == nil else { return }
        fpConfigTimerRestart = restart
        fpConfigTimer = Timer.scheduledTimer(withTimeInterval: Constants.fpConfigTimerDelay,
                                             repeats: true,
                                             block: { [weak self] _ in
            self?.checkFpConfig()
        })
        fpConfigTimer?.tolerance = Constants.timerTolerance
        fpConfigTimer?.fire()
    }

    /// Stops timer for running time.
    func stopFpConfigTimer() {
        fpConfigTimer?.invalidate()
        fpConfigTimer = nil
    }

    /// Check if flightplan media configuration has finished and activate flightplans
    func checkFpConfig() {
        // If camera is not available, continue waiting...
        guard let camera = currentDroneHolder.drone.getPeripheral(Peripherals.mainCamera2) else {
            ULog.i(.tag, "checkFpConfig: mainCamera2 is unavailable")
            return
        }

        // If drone is currently updating the camera config, continue waiting...
        guard !camera.config.updating else {
            ULog.i(.tag, "checkFpConfig: mainCamera2 is updating config")
            return
        }

        // If camera's media meta data component is not available, continue waiting...
        guard let mediaMetadata = camera.mediaMetadata else {
            ULog.i(.tag, "checkFpConfig: mainCamera2's mediaMetadata is unavailable")
            return
        }

        // If drone is currently updating the camera's media meta data, continue waiting...
        guard !mediaMetadata.updating else {
            ULog.i(.tag, "checkFpConfig: mainCamera2's mediaMetadata is updating")
            return
        }

        // Activate Piloting Interface.
        stopFpConfigTimer()
        if fpConfigTimerRestart {
            doActivate()
        } else {
            doResume()
        }
    }

    /// Updates Flight Plan's duration.
    func updateDuration() {
        durationSubject.value += Constants.timerDelay
    }

    /// Updates Flight Plan's completion progress.
    func updateProgress() {
        // Ensure Flight Plan exists and has data settings.
        guard var dataSetting = flightPlan?.dataSetting else { return }
        // Check if execution has already passed a Flight Plan way point.
        guard let lastPassedWayPointIndex = lastPassedWayPointIndex else {
            // No way point reached yet.
            // Inform drone is navigating to the starting way point.
            navigatingToStartingPointSubject.value = true
            return
        }

        // The execution is flying trough the Flight Plan's way points.
        navigatingToStartingPointSubject.value = false

        let currentLocation = currentDroneHolder.drone.getInstrument(Instruments.gps)?.lastKnownLocation
        // Update the last known Drone position into the Flight Plan Data Settings.
        dataSetting.lastDroneLocation = currentLocation
        // Calculate the new progress.
        let newProgress = dataSetting.completionProgress(with: currentLocation?.agsPoint,
                                                         lastWayPointIndex: lastPassedWayPointIndex)
        // Update the `percentCompleted` property into the Flight Plan Data Settings.
        dataSetting.percentCompleted = newProgress.rounded(toPlaces: Constants.progressRoundPrecision) * 100.0
        // Update FP's Data Settings.
        flightPlan?.dataSetting = dataSetting

        if newProgress.rounded(toPlaces: Constants.progressRoundPrecision) <= progressSubject.value {
            return
        }

        // TODO: implement a real traveled distance calculator instead of this.
        progressSubject.value = newProgress.rounded(toPlaces: Constants.progressRoundPrecision)
        distanceSubject.value = newProgress * (dataSetting.estimations.distance ?? 0.0)
    }

    func doResume() {
        guard let interface = getPilotingItf(), interface.isPaused else {
            updateState(.activationError(.droneNotReady))
            return
        }

        guard let flightPlan = flightPlan else {
            updateState(.activationError(.noFlightPlan))
            return
        }
        var interpreter: FlightPlanInterpreter = .standard
        let fpStringType = flightPlan.pictorModel.flightPlanType
        if let flightPlanType = flightPlanTypeStore?.typeForKey(fpStringType) {
            interpreter = flightPlanType.mavLinkType
        }
        wantedState = .playing
        let lastMissionItemExecuted = flightPlan.pictorModel.lastMissionItemExecuted >= 0
        ? UInt(flightPlan.pictorModel.lastMissionItemExecuted)
        : 0
        activate(pilotingInterface: interface, flightPlan: flightPlan, interpreter: interpreter,
                 missionItem: Int(lastMissionItemExecuted), restart: false)
    }

    func doActivate() {
        guard let flightPlan = flightPlan else {
            updateState(.activationError(.noFlightPlan))
            return
        }

        guard let interface = getPilotingItf() else {
            updateState(.activationError(.droneNotReady))
            return
        }

        if currentDroneHolder.drone.isStateLanded {
            NotificationCenter.default.post(name: .takeOffRequestedDidChange,
                                            object: nil,
                                            userInfo: [HUDCriticalAlertConstants.takeOffRequestedNotificationKey: true])
            guard criticalAlertService.canTakeOff else {
                updateState(.activationError(.cannotTakeOff))
                return
            }
        }

        var interpreter: FlightPlanInterpreter = .standard

        // Check interpreter.
        let fpStringType = flightPlan.pictorModel.flightPlanType
        if let flightPlanType = flightPlanTypeStore?.typeForKey(fpStringType) {
            interpreter = flightPlanType.mavLinkType
        }

        wantedState = .playing

        // Start run.
        let latestMissionItemExecuted = Int(flightPlan.pictorModel.lastMissionItemExecuted)
        if latestMissionItemExecuted > 0,
           interface.activateAtMissionItemSupported {
            if let recoveryResourceId = flightPlan.recoveryResourceId, !recoveryResourceId.isEmpty {
                // Clean resources.
                ULog.i(.tag, "Clean resources before activation '\(flightPlan.uuid)' with:"
                       + " resourceId(\(recoveryResourceId))")
                _ = interface.cleanBeforeRecovery(customId: flightPlan.uuid,
                                                  resourceId: recoveryResourceId) { [unowned self] result in
                    ULog.i(.tag, "Clean resources for '\(flightPlan.uuid)' result: \(result.description)")
                    // Prevent asking an activation if the start has been canceled.
                    guard wantedState == .playing else {
                        ULog.i(.tag, "Skip activation. Execution has been stopped. wantedState: \(wantedState) / state: \(state)")
                        return
                    }

                    if result == .canceled {
                        activeFlightPlanWatcher.flightPlanActivationFailed(flightPlan)
                    } else {
                        // Resume flight plan at missionItem.
                        activate(pilotingInterface: interface, flightPlan: flightPlan,
                                       interpreter: interpreter, missionItem: latestMissionItemExecuted, restart: true)
                    }
                }
            } else {
                // Resume flight plan at missionItem.
                activate(pilotingInterface: interface, flightPlan: flightPlan,
                         interpreter: interpreter, missionItem: latestMissionItemExecuted, restart: true)
            }
        } else {
            // Start flight plan from its begining.
            activate(pilotingInterface: interface, flightPlan: flightPlan, interpreter: interpreter,
                     missionItem: 0, restart: true)
        }
    }

    /// Activates a flight plan.
    ///
    /// - Parameters:
    ///   - pilotingInterface: flight plan piloting interface
    ///   - flightPlan: flight plan to activate
    ///   - interpreter: how the flight plan must be interpreted by the drone
    ///   - missionItem: index of mission item where the flight plan should start
    ///   - restart: should restart flight plan
    func activate(pilotingInterface: FlightPlanPilotingItf, flightPlan: FlightPlanModel,
                  interpreter: FlightPlanInterpreter, missionItem: Int, restart: Bool) {
        ULog.i(.tag, "Activate '\(flightPlan.uuid)' with:"
               + " missionItem(\(missionItem))"
               + " activateAtMissionItemSupported(\(pilotingInterface.activateAtMissionItemSupported))"
               + " activateAtMissionItemV2Supported(\(pilotingInterface.activateAtMissionItemV2Supported))")
        let disconnectionPolicy: FlightPlanDisconnectionPolicy = flightPlan.dataSetting?.disconnectionRth == false
            ? .continue
            : .returnToHome
        let result = pilotingInterface.activate(restart: restart,
                                                interpreter: interpreter,
                                                missionItem: UInt(missionItem),
                                                disconnectionPolicy: disconnectionPolicy)
        if !result {
            ULog.e(.tag, "Failed to activate '\(flightPlan.uuid)'")
            activeFlightPlanWatcher.flightPlanActivationFailed(flightPlan)
        }
    }

    func playDidStart(flightPlan: FlightPlanModel) {
        let flightPlan = flightPlan
        startRunningTimer()
        activeFlightPlanWatcher.flightPlanActivationSucceeded(flightPlan)
        updateState(.playing(droneConnected: true, flightPlan: flightPlan, rth: isInRth()))
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

    public var navigatingToStartingPointPublisher: AnyPublisher<Bool, Never> { navigatingToStartingPointSubject.eraseToAnyPublisher() }

    public var statePublisher: AnyPublisher<FlightPlanRunningState, Never> { stateSubject.eraseToAnyPublisher() }

    public var state: FlightPlanRunningState { stateSubject.value }

    public var interfaceReadyPublisher: AnyPublisher<Bool, Never> { interfaceReadySubject.eraseToAnyPublisher() }

    public var distancePublisher: AnyPublisher<Double, Never> { distanceSubject.eraseToAnyPublisher() }

    public var playingFlightPlan: FlightPlanModel? { playingFlightPlanSubject.value }

    public var playingFlightPlanPublisher: AnyPublisher<FlightPlanModel?, Never> { playingFlightPlanSubject.eraseToAnyPublisher() }

    public func play() {
        ULog.i(.tag, "COMMAND: play '\(flightPlan?.uuid ?? "")'")
        guard let flightPlan = flightPlan else {
            updateState(.activationError(.noFlightPlan))
            return
        }

        guard let interface = getPilotingItf() else {
            updateState(.activationError(.droneNotReady))
            return
        }

        // Let drone know a FP will be activated
        interface.prepareForFlightPlanActivation()

        // Let the FP watcher know the FP will be activated
        activeFlightPlanWatcher.flightPlanWillBeActivated(flightPlan)

        // Check if camera settings are updated.
        let camera = currentDroneHolder.drone.getPeripheral(Peripherals.mainCamera2)
        if let camera = camera, !camera.config.updating {
            doActivate()
            return
        }

        // Camera is not available or is currently updating his settings, wait before activating the flightplan.
        ULog.i(.tag, "Drone is being configured. Wait before activating flightplan '\(flightPlan.uuid)'")
        if camera == nil { ULog.w(.tag, "Drone's mainCamera2 unavailable.") }
        startFpConfigTimer(restart: true)
    }

    public func unpause() {
        ULog.i(.tag, "COMMAND: unpause '\(flightPlan?.uuid ?? "")'")
        guard let interface = getPilotingItf(), interface.isPaused else {
            updateState(.activationError(.droneNotReady))
            return
        }
        guard let flightPlan = flightPlan else {
            updateState(.activationError(.noFlightPlan))
            return
        }
        guard case .paused = stateSubject.value else {
            ULog.e(.tag, "Unpause asked for '\(flightPlan.uuid)' while not in pause. Current state: '\(stateSubject.value)'")
            return
        }

        // Let the FP watcher know the FP will be activated
        activeFlightPlanWatcher.flightPlanWillBeActivated(flightPlan)

        // Check if camera settings are updated.
        let camera = currentDroneHolder.drone.getPeripheral(Peripherals.mainCamera2)
        if let camera = camera, !camera.config.updating {
            doResume()
            return
        }

        // Camera is not available or is currently updating his settings, wait before activating the flightplan.
        ULog.i(.tag, "Drone is being configured. Wait before activating flightplan '\(flightPlan.uuid)'")
        if camera == nil { ULog.w(.tag, "Drone's mainCamera2 unavailable.") }
        startFpConfigTimer(restart: false)
    }

    public func catchUp(lastMissionItemExecuted: Int, recoveryResourceId newRecoveryResourceId: String?, duration: TimeInterval) {
        guard let flightPlan = flightPlan else { return }
        ULog.i(.tag, "catchUp '\(flightPlan.uuid)'"
               + " lastMissionItemExecuted(\(lastMissionItemExecuted))"
               + " newRecoveryResourceId(\(newRecoveryResourceId ?? "nil"))"
               + " duration(\(duration))")
        wantedState = .playing
        latestItemExecuted = lastMissionItemExecuted
        recoveryResourceId = newRecoveryResourceId
        durationSubject.value = duration
        // Update the flight plan with `latestItemExecuted`, then inform about the start.
        let updatedFlightPlan = updatedFlightPlan(flightPlan)
        playDidStart(flightPlan: updatedFlightPlan)
    }

    public func pause() {
        ULog.i(.tag, "COMMAND: pause '\(flightPlan?.uuid ?? "")'")
        // Ensure the running timer is stopped (the itf update may not be triggered)
        stopRunningTimer()
        stopFpConfigTimer()
        guard case .playing = stateSubject.value else {
            ULog.e(.tag, "Cannot pause '\(flightPlan?.uuid ?? "")' with state '\(stateSubject.value)'")
            return
        }
        guard let flightPlan = flightPlan else { return }
        activeFlightPlanWatcher.flightPlanDidStop(flightPlan)
        wantedState = .paused
        _ = getPilotingItf()?.deactivate()
    }

    public func stop(forced: Bool = false) {
        ULog.i(.tag, "COMMAND: stop\(forced ? " forced" : "") '\(flightPlan?.uuid ?? "")'")
        // Ensure the running timer is stopped (the itf update may not be triggered)
        stopRunningTimer()
        stopFpConfigTimer()

        guard let flightPlan = flightPlan else { return }

        // If rth is enabled on the current flightplan, the FP has not reached the last WP
        // and we don't want to force to handle the FP as ended,
        // the drone wont stop the execution immediately, but it will execute the rth before.
        if hasRth,
           !forced,
           !flightPlan.hasReachedLastWayPoint {
            switch stateSubject.value {
            case .playing(let droneConnected, _, _), .paused(let droneConnected, _, _):
                if droneConnected {
                    // If the drone is still connected, send stop without disabling the interface.
                    // The UI will display the rth animation instead of going to editable.
                    _ = getPilotingItf()?.stop()
                    return
                }
            default:
                break
            }
        }

        // Otherwise, send stop and pass to editable.
        // If the drone was disconnected, the UI will catch up with the
        // drone once the connection is restored.
        wantedState = .stopped
        _ = getPilotingItf()?.stop()
        handleFlightEnds(flightPlan: flightPlan)
    }

    public func handleTimeout(flightPlan: FlightPlanModel) {
        // Send a stop to the piloting interface in case it's still trying to activate.
        _ = getPilotingItf()?.stop()
        // Inform the active FP watcher that FP activation failed.
        activeFlightPlanWatcher.flightPlanActivationFailed(flightPlan)
    }

    public func setup(flightPlan: FlightPlanModel, mavlinkCommands: [MavlinkStandard.MavlinkCommand]) {
        ULog.i(.tag, "COMMAND: setup '\(flightPlan.uuid)'")
        reset()
        self.flightPlan = flightPlan
        self.mavlinkCommands = mavlinkCommands
        updateState(.idle(flightPlan: flightPlan, startAvailability: startAvailability))
    }

    public func flightPlanWasUpdated(_ flightPlan: FlightPlanModel) {
        guard flightPlan.uuid == self.flightPlan?.uuid else { return }
        ULog.i(.tag, "COMMAND: flightPlanWasUpdated '\(flightPlan.uuid)'")
        self.flightPlan = flightPlan
        // Make sure the state holds the right flight plan value
        switch stateSubject.value {
        case .noFlightPlan:
            break
        case .idle(_, let startAvailability):
            updateState(.idle(flightPlan: flightPlan, startAvailability: startAvailability))
        case .activationError:
            break
        case .playing(let droneConnected, _, let rth):
            updateState(.playing(droneConnected: droneConnected, flightPlan: flightPlan, rth: rth))
        case .rth:
            updateState(.rth(flightPlan: flightPlan))
        case .paused(let droneConnected, _, let startAvailability):
            updateState(.paused(droneConnected: droneConnected,
                                flightPlan: flightPlan, startAvailability: startAvailability))
        case .ended(let completed, let flightPlan):
            updateState(.ended(completed: completed, flightPlan: flightPlan))
        }
    }

    public func reset() {
        ULog.i(.tag, "COMMAND: reset '\(flightPlan?.uuid ?? "")'")
        flightPlan = nil
        wantedState = .none
        mavlinkCommands = []
        distanceSubject.value = 0
        durationSubject.value = 0
        latestItemExecuted = nil
        recoveryResourceId = nil
        progressSubject.value = 0
        navigatingToStartingPointSubject.value = false
        updateState(.noFlightPlan)
    }
}
