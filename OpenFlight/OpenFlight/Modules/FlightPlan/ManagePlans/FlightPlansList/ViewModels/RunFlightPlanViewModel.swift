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

// MARK: - RunFlightPlanListener
/// Listener for `RunFlightPlanViewModel` state updates.
final class RunFlightPlanListener: NSObject {
    let didChange: RunFlightPlanListenerClosure
    init(didChange: @escaping RunFlightPlanListenerClosure) {
        self.didChange = didChange
    }
}

/// Alias for `RunFlightPlanListener` closure.
typealias RunFlightPlanListenerClosure = (RunFlightPlanState) -> Void

// MARK: - Internal Enum

/// Defines flight plan running state.
enum FlightPlanRunningState {
    case playing
    case paused
    case stopped
    case userStopped
    case uploading

    var isActive: Bool {
        switch self {
        case .playing,
             .paused,
             .uploading:
            return true
        default:
            return false
        }
    }
}

/// State for `RunFlightPlanViewModel`.

final class RunFlightPlanState: DeviceConnectionState {
    // MARK: - Internal Properties
    var isAvailable: Bool {
        return isConnected() &&
            unavailabilityReasons.filter({ $0 != .missingFlightPlanFile }).isEmpty
    }
    var formattedDuration: String? {
        switch runState {
        case .playing,
             .paused:
            return duration.formattedString
        default:
            return nil
        }
    }

    // MARK: - Private Properties
    // MARK: Utility properties
    /// Flight Plan running duration.
    fileprivate var duration: TimeInterval = 0.0
    /// Flight Plan run state.
    fileprivate(set) var runState: FlightPlanRunningState = .stopped {
        didSet {
            if runState == .stopped || runState == .userStopped {
                duration = 0.0
            }
        }
    }
    /// File is up to date, used in complement with isFileKnownByDrone
    /// to make sure the last Flight Plan version is uploaded.
    fileprivate(set) var isFileUpToDate: Bool = false

    // MARK: SDK properties
    /// Activation error.
    fileprivate(set) var activationError: FlightPlanActivationError = .none
    /// Flight Plan piloting state.
    fileprivate(set) var pilotingState: ActivablePilotingItfState = .idle
    /// Flight Plan upload state.
    fileprivate(set) var uploadState: FlightPlanFileUploadState = .none
    /// Unavailability reasons.
    fileprivate(set) var unavailabilityReasons: Set<FlightPlanUnavailabilityReason> = []
    /// File is known by the drone. Returns `true` if the drone has a Flight Plan to run.
    fileprivate(set) var isFileKnownByDrone: Bool = false
    /// Latest mission item executed.
    fileprivate(set) var latestMissionItemExecuted: Int?
    /// MAVLink commands.
    fileprivate(set) var mavlinkCommands: [MavlinkCommand] = []
    /// Whether Flight Plan is completed. Transient state.
    fileprivate(set) var completed: Bool = false

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///     - connectionState: connection state
    ///     - runState: run state
    ///     - activationError: activation error
    ///     - pilotingState: piloting state
    ///     - uploadState: upload state
    ///     - unavailabilityReasons: unavailability reasons
    ///     - isFileKnownByDrone: is file known by drone
    ///     - isFileUpToDate: is file up to date
    ///     - duration: running duration
    ///     - latestMissionItemExecuted: latest mission item executed
    ///     - mavlinkCommands: MAVLink commands for current Flight Plan
    ///     - completed: whether Flight Plan is completed
    init(connectionState: DeviceState.ConnectionState,
         runState: FlightPlanRunningState,
         activationError: FlightPlanActivationError,
         pilotingState: ActivablePilotingItfState,
         uploadState: FlightPlanFileUploadState,
         unavailabilityReasons: Set<FlightPlanUnavailabilityReason>,
         isFileKnownByDrone: Bool,
         isFileUpToDate: Bool,
         duration: TimeInterval,
         latestMissionItemExecuted: Int?,
         mavlinkCommands: [MavlinkCommand],
         completed: Bool) {
        super.init(connectionState: connectionState)
        self.runState = runState
        self.activationError = activationError
        self.uploadState = uploadState
        self.pilotingState = pilotingState
        self.unavailabilityReasons = unavailabilityReasons
        self.isFileKnownByDrone = isFileKnownByDrone
        self.isFileUpToDate = isFileUpToDate
        self.duration = duration
        self.latestMissionItemExecuted = latestMissionItemExecuted
        self.mavlinkCommands = mavlinkCommands
        self.completed = completed
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? RunFlightPlanState else {
            return false
        }
        return super.isEqual(to: other)
            && self.runState == other.runState
            && self.activationError == other.activationError
            && self.uploadState == other.uploadState
            && self.pilotingState == other.pilotingState
            && self.isAvailable == other.isAvailable
            && self.isFileKnownByDrone == other.isFileKnownByDrone
            && self.isFileUpToDate == other.isFileUpToDate
            && self.duration == other.duration
            && self.latestMissionItemExecuted == other.latestMissionItemExecuted
            && self.completed == other.completed
    }

    override func copy() -> RunFlightPlanState {
        return RunFlightPlanState(connectionState: self.connectionState,
                                  runState: self.runState,
                                  activationError: self.activationError,
                                  pilotingState: self.pilotingState,
                                  uploadState: self.uploadState,
                                  unavailabilityReasons: self.unavailabilityReasons,
                                  isFileKnownByDrone: self.isFileKnownByDrone,
                                  isFileUpToDate: self.isFileUpToDate,
                                  duration: self.duration,
                                  latestMissionItemExecuted: self.latestMissionItemExecuted,
                                  mavlinkCommands: self.mavlinkCommands,
                                  completed: self.completed)
    }
}

/// RunFlightPlanViewModel is used to run a Flight Plan on the drone.

final class RunFlightPlanViewModel: DroneStateViewModel<RunFlightPlanState> {
    // MARK: - Private Properties
    private var flightPlanPilotingRef: Ref<FlightPlanPilotingItf>?
    private weak var flightPlanViewModel: FlightPlanViewModel?
    private var runningTimer: Timer?
    private var flightPlanExecution: FlightPlanExecution?

    // MARK: - Private Enums
    private enum Constants {
        static let timerDelay: Double = 1.0
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///     - flightPlanViewModel: Flight Plan view model
    ///     - stateDidUpdate: state did update closure
    init(flightPlanViewModel: FlightPlanViewModel,
         stateDidUpdate: ((RunFlightPlanState) -> Void)? = nil) {
        super.init(stateDidUpdate: stateDidUpdate)
        self.flightPlanViewModel = flightPlanViewModel
    }

    // MARK: - Deinit
    deinit {
        flightPlanPilotingRef = nil
        stopRunningTimer()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenFlightPlanPiloting(drone: drone)
    }

    // MARK: - Internal Funcs
    /// Toggle play/pause.
    func togglePlayPause() {
        let state = self.state.value
        guard state.runState != .uploading,
              state.isConnected()
        else { return }

        state.runState == .playing ? pause() : play()
    }

    /// Stop Flight Plan.
    func stop() {
        if self.getPilotingItf()?.deactivate() ?? false {
            self.flightPlanExecution?.state = FlightPlanExecutionState.stopped
            let copy = self.state.value.copy()
            copy.runState = .userStopped
            self.state.set(copy)
        }
    }

    /// Removes current MAVLink commands and flags the Flight Plan file as not up to date.
    /// Should be called when Flight Plan gets modified.
    func resetMavlinkCommands() {
        let copy = self.state.value.copy()
        copy.mavlinkCommands = []
        copy.isFileUpToDate = false
        self.state.set(copy)
    }
}

// MARK: - Private Funcs
private extension RunFlightPlanViewModel {
    // MARK: - Listen Flight Plan piloting interface
    /// Listen FlightPlan Piloting Interface.
    func listenFlightPlanPiloting(drone: Drone) {
        flightPlanPilotingRef = drone.getPilotingItf(PilotingItfs.flightPlan) { [weak self] flightPlanPiloting in
            guard let pilotingItf = flightPlanPiloting else { return }

            let copy = self?.state.value.copy()
            copy?.activationError = pilotingItf.latestActivationError
            copy?.pilotingState = pilotingItf.state
            copy?.uploadState = pilotingItf.latestUploadState
            copy?.unavailabilityReasons = pilotingItf.unavailabilityReasons
            copy?.isFileKnownByDrone = pilotingItf.flightPlanFileIsKnown
            copy?.latestMissionItemExecuted = pilotingItf.latestMissionItemExecuted

            // If a flight plan is active and reach the first way point, we start a new execution.
            if pilotingItf.state == .active,
               pilotingItf.latestMissionItemExecuted == 1,
               self?.state.value.runState == .playing,
               self?.flightPlanExecution == nil {
                self?.startFlightPlanExecution()
            } else if pilotingItf.state == .idle,
                      self?.state.value.runState == .userStopped {
                self?.saveFlightPlanExecution()
            }

            switch pilotingItf.state {
            case .unavailable:
                // Reset run state.
                copy?.runState = .stopped
            case .idle where self?.state.value.runState == .playing:
                // Ends Flight Plan.
                self?.saveFlightPlanExecution()
                copy?.runState = .stopped
                copy?.completed = true
                DispatchQueue.main.async { [weak self] in
                    let copy = self?.state.value.copy()
                    copy?.completed = false
                    self?.state.set(copy)
                }
            case .active where self?.state.value.runState == .stopped:
                // Handle stop, then start case.
                copy?.runState = .playing
                self?.startRunningTimer(resetStartDate: true)
            default:
                break
            }

            switch pilotingItf.latestUploadState {
            case .uploading where copy?.runState != .stopped:
                copy?.runState = .uploading
            case .uploaded where copy?.runState == .uploading:
                // Try to handle auto play
                // directly via flightPlanPiloting to ease state change.
                if copy?.pilotingState == .idle {
                    // Ends upload: start fight plan.
                    copy?.runState = .playing
                    _ = pilotingItf.activate(restart: true)
                    self?.startRunningTimer(resetStartDate: true)
                }
            case .failed:
                copy?.runState = .stopped
                self?.flightPlanExecution?.state = FlightPlanExecutionState.error
            default:
                break
            }

            self?.state.set(copy)
        }
    }

    // MARK: - Helpers
    /// Helper to retrieve current FlightPlanPilotingItf in a safe way.
    /// - Returns: FlightPlanPilotingItf as optional
    func getPilotingItf() -> FlightPlanPilotingItf? {
        return self.drone?
            .getPilotingItf(PilotingItfs.flightPlan)
    }

    // MARK: - Controls
    /// Plays or uploads Flight Plan regarding state.
    func play() {
        let state = self.state.value
        if state.isFileKnownByDrone,
           state.isFileUpToDate {
            let isPaused = state.runState == .paused
            var type: GroundSdkFlightPlanType = .flightPlan

            if let flightPlan = self.flightPlanViewModel?.flightPlan,
               let fpStringType = flightPlan.type,
               let flightPlanType = FlightPlanTypeManager.shared.typeForKey(fpStringType) {
                type = flightPlanType.mavLinkType
            }

            if self.getPilotingItf()?.activate(restart: !isPaused, type: type) ?? false {
                let copy = self.state.value.copy()
                copy.runState = .playing
                self.state.set(copy)
                startRunningTimer(resetStartDate: !isPaused)
            }
        } else if state.isAvailable {
            self.sendMavlinkToDevice()
        }
    }

    /// Pause Flight Plan.
    func pause() {
        if self.getPilotingItf()?.deactivate() ?? false {
            stopRunningTimer()
            let copy = self.state.value.copy()
            copy.runState = .paused
            self.state.set(copy)
        }
    }

    /// Send mavlink to device.
    func sendMavlinkToDevice() {
        // Generate mavlink file from Flight Plan.
        guard let flightPlan = self.flightPlanViewModel?.flightPlan,
              let path = flightPlan.mavlinkDefaultUrl?.path
        else {
            return
        }
        // Update state, assuming SDK's uploadFlightPlan will work.
        let copy = self.state.value.copy()
        if flightPlan.canGenerateMavlink == false,
           FileManager.default.fileExists(atPath: path) {
            // Do not generate Mavlink, use the stored one.
        } else {
            // Generate Mavlink from flight plan.
            let mavlinkCommands = FlightPlanManager.shared.generateMavlinkCommands(for: flightPlan)
            MavlinkFiles.generate(filepath: path, commands: mavlinkCommands)
            copy.mavlinkCommands = mavlinkCommands
        }
        copy.isFileUpToDate = true
        self.state.set(copy)
        // Send Mavlink to drone.
        self.getPilotingItf()?.uploadFlightPlan(filepath: path)
    }

    // MARK: - Timer
    /// Starts timer for running time.
    ///
    /// - Parameters:
    ///     - resetStartDate: reset start date if true
    func startRunningTimer(resetStartDate: Bool) {
        if resetStartDate {
            let copy = self.state.value.copy()
            copy.duration = 0.0
            self.state.set(copy)
        }
        runningTimer?.invalidate()
        runningTimer = Timer.scheduledTimer(withTimeInterval: Constants.timerDelay,
                                            repeats: true,
                                            block: { [weak self] _ in
                                                self?.updateDuration()
                                            })
        runningTimer?.fire()
    }

    /// Stops timer for running time.
    func stopRunningTimer() {
        runningTimer?.invalidate()
        runningTimer = nil
    }

    /// Update Flight Plan duration.
    func updateDuration() {
        switch self.state.value.runState {
        case .playing where self.state.value.latestMissionItemExecuted ?? 0 > 0:
            let copy = self.state.value.copy()
            copy.duration += Constants.timerDelay
            self.state.set(copy)
        case .userStopped,
             .stopped:
            stopRunningTimer()
        default:
            break
        }
    }

    /// Starts flight plan execution.
    func startFlightPlanExecution() {
        let flightPlanId = flightPlanViewModel?.flightPlan?.uuid
        let flightId = self.drone?.getInstrument(Instruments.flightInfo)?.flightId
        let settings = flightPlanViewModel?.flightPlan?.settings
        let execution = FlightPlanExecution(flightPlanId: flightPlanId,
                                            flightId: flightId,
                                            startDate: Date(),
                                            settings: settings)
        self.flightPlanExecution = execution
        self.flightPlanViewModel?.saveExecution(execution)

        // Sets the custom Id of the drone media meta data with the flight plan execution Id to get media that belong to the flight plan execution.
        if let flightPlanExecutionId = execution.executionId,
           !flightPlanExecutionId.isEmpty {
            self.drone?.getPeripheral(Peripherals.mainCamera2)?.mediaMetadata?.customId = flightPlanExecutionId
        }

        // Sends notification that a flight plan execution has started.
        if let flightPlanTitle = flightPlanViewModel?.state.value.title {
            var notificationDictionary: [AnyHashable: Any] = [:]
            notificationDictionary[FlightPlanConstants.flightPlanNameNotificationKey] = flightPlanTitle
            // TODO: pass executionId instead when execution will be refactered, or better watch core data changes
            notificationDictionary[FlightPlanConstants.fpExecutionNotificationKey] = execution

            NotificationCenter.default.post(name: .flightPlanExecutionDidStart,
                                            object: self,
                                            userInfo: notificationDictionary)
        }
    }

    /// Saves flight plan execution in database.
    func saveFlightPlanExecution() {
        // Reset the custom Id for the drone media meta data.
        self.drone?.getPeripheral(Peripherals.mainCamera2)?.mediaMetadata?.customId = ""

        guard let strongFpExecution = self.flightPlanExecution else { return }

        if strongFpExecution.state == nil {
            strongFpExecution.state = FlightPlanExecutionState.completed
        }
        strongFpExecution.endDate = Date()
        flightPlanViewModel?.saveExecution(strongFpExecution)
        self.flightPlanExecution = nil
    }
}
