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

// MARK: - Internal Enums
/// Enum for all cameraman state possible.
enum CameramanModeState {
    case selectSubject
    case tracking
    case waitingTakeOff

    // MARK: - Internal Properties
    var title: String {
        switch self {
        case .selectSubject:
            return L10n.cameramanSelectTarget
        case .tracking:
            return L10n.cameramanTracking
        case .waitingTakeOff:
            return L10n.cameramanTakeOff
        }
    }
}

/// State for `CameramanModeViewModel`.
final class CameramanState: ViewModelState, EquatableState, Copying {

    // MARK: - Internal Properties
    fileprivate(set) var currentState: CameramanModeState = .waitingTakeOff

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - currentState: current state of the Cameraman functionality.
    init(currentState: CameramanModeState) {
        self.currentState = currentState
    }

    // MARK: - Internal Funcs
    func isEqual(to other: CameramanState) -> Bool {
        return self.currentState == other.currentState
    }

    // MARK: - Copying
    /// Returns a copy of the object.
    func copy() -> CameramanState {
        let copy = CameramanState(currentState: self.currentState)
        return copy
    }
}

/// ViewModel for the Cameraman bottom bar view.
final class CameramanModeViewModel: DroneWatcherViewModel<CameramanState> {

    // MARK: - Private Properties
    private var stateRef: Ref<DeviceState>?

    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var flyingIndicators: FlyingIndicators? {
        return flyingIndicatorsRef?.value
    }
    private var lookAtPilotingItfRef: Ref<LookAtPilotingItf>?
    private var lookAtPilotingItf: LookAtPilotingItf? {
        return lookAtPilotingItfRef?.value
    }
    private var returnHomePilotingItfRef: Ref<ReturnHomePilotingItf>?
    private var returnHomePilotingItf: ReturnHomePilotingItf? {
        return returnHomePilotingItfRef?.value
    }
    private var onboardTrackerRef: Ref<OnboardTracker>?
    private var onboardTracker: OnboardTracker? {
        return onboardTrackerRef?.value
    }

    private var cameraRef: Ref<MainCamera2>?
    private var camera: MainCamera2? {
        return cameraRef?.value
    }

    private var missionManagerRef: Ref<MissionManager>?
    private var missionManager: MissionManager? {
        return missionManagerRef?.value
    }

    /// Whether onboard tracker is stopping.
    private var isStopping: Bool = false

    // MARK: - Deinit
    deinit {
        clearLookAt()
        removeAllTargets()
        returnHomePilotingItfRef = nil
        onboardTracker?.stopTrackingEngine()
        onboardTrackerRef = nil
        flyingIndicatorsRef = nil
        cameraRef = nil
        missionManagerRef = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        listenDroneState(drone: drone)
    }

    /// Remove all current targets.
    func removeAllTargets() {
        drone?.getPeripheral(Peripherals.onboardTracker)?.removeAllTargets()
        _ = lookAtPilotingItf?.deactivate()
    }
}

// MARK: - Private Funcs
private extension CameramanModeViewModel {

    /// Enables all listeners for the viewmodel.
    ///
    /// - Parameter drone: the current drone
    func enableListeners(drone: Drone) {
        removeListeners()
        listenReturnHomeInterface(drone: drone)
        listenOnboardTracker(drone: drone)
        listenLookAtInterface(drone: drone)
        listenFlyingIndicators(drone: drone)
        listenCamera(drone: drone)
        listenMissionManager(drone: drone)
    }

    /// Removes all listeners for the viewmodel.
    func removeListeners() {
        clearLookAt()
        returnHomePilotingItfRef = nil
        onboardTrackerRef = nil
        flyingIndicatorsRef = nil
        cameraRef = nil
        missionManagerRef = nil
    }

    /// Starts watcher for drone state.
    ///
    /// - Parameter drone: the current drone
    func listenDroneState(drone: Drone) {
        stateRef = drone.getState { [unowned self] droneState in
            if droneState?.connectionState == .connected {
                isStopping = false
                enableListeners(drone: drone)
            } else {
                removeListeners()
            }
        }
    }

    /// Listen the onboard tracker peripheral.
    ///
    /// - Parameter drone: the current drone
    func listenOnboardTracker(drone: Drone) {
        onboardTrackerRef = drone.getPeripheral(Peripherals.onboardTracker) { [unowned self] onboardTracker in
            guard let onboardTracker = onboardTracker else {
                return
            }
            if onboardTracker.trackingEngineState != .activated {
                isStopping = false
            }

            activateOrDeactivateOnboardIfNecessary()
            activateLookAtIfNecessary()
       }
    }

    /// Listen the Look At piloting interface.
    ///
    /// - Parameter drone: the current drone
    func listenLookAtInterface(drone: Drone) {
        lookAtPilotingItfRef = drone.getPilotingItf(PilotingItfs.lookAt) { [unowned self] _ in
            updateState()
            activateOrDeactivateOnboardIfNecessary()
            activateLookAtIfNecessary()
        }
    }

    /// Listen the Return home piloting interface.
    ///
    /// - Parameter drone: the current drone
    func listenReturnHomeInterface(drone: Drone) {
        returnHomePilotingItfRef = drone.getPilotingItf(PilotingItfs.returnHome) { [unowned self] _ in
            activateOrDeactivateOnboardIfNecessary()
            activateLookAtIfNecessary()
        }
    }

    /// Listen flying indicators instrument.
    ///
    /// - Parameter drone: the current drone
    func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [unowned self] flyingIndicator in
            guard flyingIndicator != nil else { return }
            updateState()
            activateOrDeactivateOnboardIfNecessary()
            activateLookAtIfNecessary()
        }
    }

    /// Listen mainCamera2 peripheral
    ///
    /// - Parameter drone: the current drone
    func listenCamera(drone: Drone) {
        cameraRef = drone.getPeripheral(Peripherals.mainCamera2) { [unowned self] _ in
            applyCamera(drone: drone)
            activateOrDeactivateOnboardIfNecessary()
            activateLookAtIfNecessary()
        }
    }

    private func applyCamera(drone: Drone) {
        guard let camera = drone.getPeripheral(Peripherals.mainCamera2), !camera.config.updating else { return }

        let editor = camera.config.edit(fromScratch: true)
        var edited = false
        // switch camera to recording mode, if necessary
        if camera.config[Camera2Params.mode]?.value != .recording {
            // Cameraman depends on mode recording.
            // It will not start if in photo mode.
            editor[Camera2Params.mode]?.value = .recording
            edited = true
        }

        // adjust recording framerate to a value supported in cameraman mode, if necessary
        if let resolution = camera.config[Camera2Params.videoRecordingResolution]?.value,
           let framerate = camera.config[Camera2Params.videoRecordingFramerate]?.value,
           let supportedFrameratesInMission = CameramanCameraRestrictionsModel.Constants.framerates[resolution],
           !supportedFrameratesInMission.contains(framerate) {
            let currentSupportedValues = editor[Camera2Params.videoRecordingFramerate]?.currentSupportedValues
                .intersection(supportedFrameratesInMission)
            let highestFramerate = Camera2RecordingFramerate.sortedCases.reversed()
                .filter { currentSupportedValues?.contains($0) == true }
                .first
            editor[Camera2Params.videoRecordingFramerate]?.value = highestFramerate
            edited = true
        }

        if edited {
            editor.saveSettings(currentConfig: camera.config)
        }
    }

    /// Listen mission manager peripheral
    ///
    /// - Parameter drone: the current drone
    func listenMissionManager(drone: Drone) {
        missionManagerRef = drone.getPeripheral(Peripherals.missionManager) { [unowned self] missionManager in
            guard missionManager != nil else { return }
            activateOrDeactivateOnboardIfNecessary()
            activateLookAtIfNecessary()
        }
    }

    /// Tells if onboard tracker should be activated.
    ///
    /// - Returns: `true` if onboard tracker should be activated
    private func shouldActivateOnboardTracker() -> Bool {
        guard let returnHome = drone?.getPilotingItf(PilotingItfs.returnHome),
              let flyingIndicators = drone?.getInstrument(Instruments.flyingIndicators),
              let camera = drone?.getPeripheral(Peripherals.mainCamera2),
              let missionManager = drone?.getPeripheral(Peripherals.missionManager),
              let missionCameraman = missionManager.missions[CameramanActivationModel().signature.missionUID] else {
            return false
        }
        return returnHome.state != .active
            && flyingIndicators.flyingState.isFlyingOrWaiting
            && camera.mode == .recording
            && missionCameraman.state == .active
    }

    /// Activate or deactivate tracking engine of onboard tracker if necessary.
    private func activateOrDeactivateOnboardIfNecessary() {
        guard let onboardTracker = drone?.getPeripheral(Peripherals.onboardTracker) else {
            return
        }
        if shouldActivateOnboardTracker() {
            isStopping = false

            // TODO: put back a filter to know if command was already sent.
            if onboardTracker.trackingEngineState == .available {
                onboardTracker.startTrackingEngine(boxProposals: true)
            }
        } else {
            if !isStopping, onboardTracker.trackingEngineState == .activated {
                isStopping = true
                onboardTracker.stopTrackingEngine()
            }
        }
    }

    /// Activate look at piloting interface if necessary.
    private func activateLookAtIfNecessary() {
        guard let lookAt = drone?.getPilotingItf(PilotingItfs.lookAt),
              let onboardTracker = drone?.getPeripheral(Peripherals.onboardTracker),
              shouldActivateOnboardTracker() else {
            return
        }
        if lookAt.state == .idle && !onboardTracker.targets.isEmpty {
            _ = lookAt.activate()
        }
    }

    /// Update the current state of the cameraman.
    func updateState() {
        let copy = self.state.value.copy()
        if drone?.getInstrument(Instruments.flyingIndicators)?.flyingState.isFlyingOrWaiting == false {
            copy.currentState = .waitingTakeOff
        } else if drone?.getPilotingItf(PilotingItfs.lookAt)?.state == .active {
            copy.currentState = .tracking
        } else {
            copy.currentState = .selectSubject
        }
        state.set(copy)
    }

    /// Clear every variables of the view model.
    func clearLookAt() {
        _ = lookAtPilotingItf?.deactivate()
        lookAtPilotingItfRef = nil
    }
}
