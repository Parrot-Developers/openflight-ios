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

// MARK: - Internal Enums
/// Enum for all cameraman state possible.
enum CameramanModeState {
    case selectSubject
    case tracking

    // MARK: - Internal Properties
    var title: String {
        switch self {
        case .selectSubject:
            return L10n.followMeSelectYourself
        case .tracking:
            return L10n.followMeTracking
        }
    }
}

/// State for `CameramanModeViewModel`.
final class CameramanState: ViewModelState, Equatable, Copying {

    // MARK: - Internal Properties
    fileprivate(set) var currentState: CameramanModeState = .selectSubject

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
    /// Equatable implementation.
    static func == (lhs: CameramanState, rhs: CameramanState) -> Bool {
        return lhs.currentState == rhs.currentState
    }

    /// Returns a copy of the object.
    func copy() -> CameramanState {
        let copy = CameramanState(currentState: self.currentState)
        return copy
    }
}

/// ViewModel for the Cameraman bottom bar view.
final class CameramanModeViewModel: DroneWatcherViewModel<CameramanState> {

    // MARK: - Private Properties
    private var onboardTrackerRef: Ref<OnboardTracker>?
    private var onboardTracker: OnboardTracker?
    private var stateRef: Ref<DeviceState>?

    // MARK: - Deinit
    deinit {
        self.clearOnBoardTracking()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        self.listenDroneState(drone: drone)
    }

    /// Remove all current targets.
    func removeAllTargets() {
        self.onboardTracker?.removeAllTargets()
    }
}

// MARK: - Private Funcs
private extension CameramanModeViewModel {

    /// Enables all listeners for the viewmodel.
    func enableListeners(drone: Drone) {
        self.removeListeners()
        self.listenOnboardTracker(drone: drone)
    }

    /// Removes all listeners for the viewmodel.
    func removeListeners() {
        self.clearOnBoardTracking()
    }

    /// Starts watcher for drone state.
    func listenDroneState(drone: Drone) {
        self.stateRef = drone.getState { [weak self] state in
            if state?.connectionState == .connected {
                self?.enableListeners(drone: drone)
            } else {
                self?.removeListeners()
            }
        }
    }

    /// Starts watcher for onBoard tracker state.
    func listenOnboardTracker(drone: Drone) {
        self.onboardTrackerRef = drone.getPeripheral(Peripherals.onboardTracker) { [weak self] onboardTracker in
            self?.onboardTracker = onboardTracker
            self?.updateState()

            // Activate Cameraman when the drone is tracking a target.
            let isTracking = onboardTracker?.isTracking == true
            self?.handleCameraman(drone: drone, enable: isTracking)
        }
    }

    // Update the current state of the cameraman.
    func updateState() {
        let copy = self.state.value.copy()
        copy.currentState = self.onboardTracker?.isTracking == true ? .tracking : .selectSubject
        self.state.set(copy)
    }

    /// Activate or deactivate Cameraman mode.
    ///
    /// - Parameters:
    ///    - drone: drone on which we want to activate/deactivate Cameraman mode.
    ///    - enable: Precise if we want to activate or deactivate Cameraman mode.
    func handleCameraman(drone: Drone, enable: Bool) {
        let isCameramanActive = drone.getPilotingItf(PilotingItfs.lookAt)?.state == .active

        if enable && !isCameramanActive {
            _ = drone.getPilotingItf(PilotingItfs.lookAt)?.activate()
        } else if !enable && isCameramanActive {
            _ = drone.getPilotingItf(PilotingItfs.lookAt)?.deactivate()
        }
    }

    /// Clear every variables of the view model.
    func clearOnBoardTracking() {
        self.onboardTracker?.removeAllTargets()
        self.onboardTrackerRef = nil
        self.onboardTracker = nil

        guard let drone = self.drone else { return }
        self.handleCameraman(drone: drone, enable: false)
    }
}
