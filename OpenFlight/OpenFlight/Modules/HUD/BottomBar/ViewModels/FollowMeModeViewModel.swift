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

// MARK: - Public Enums
/// Enum for all follow me state possible.
public enum FollowMeModeState {
    case checkingRequirements
    case notAvailable
    case selectYourself
    case tracking
    case droneDisconnected

    // MARK: - Public Properties
    var title: String {
        switch self {
        case .checkingRequirements:
            return L10n.followMeChecking(0, 0)
        case .selectYourself:
            return L10n.followMeSelectYourself
        case .tracking:
            return L10n.followMeTracking
        case .droneDisconnected:
            return L10n.connectDrone
        default:
            return ""
        }
    }
}

/// State for `FollowMeModeViewModel`.
final class FollowMeState: ViewModelState, Equatable, Copying {

    // MARK: - Internal Properties
    fileprivate(set) var trackingIssuesList: [TrackingIssue] = []
    fileprivate(set) var currentState: FollowMeModeState = .checkingRequirements
    fileprivate(set) var counterRequirement: Int = 0

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - currentState: current state of the FollowMe functionality.
    ///    - counterRequirement: current number of checked requirement.
    init(currentState: FollowMeModeState, counterRequirement: Int) {
        self.currentState = currentState
        self.counterRequirement = counterRequirement
    }

    // MARK: - Internal Funcs
    /// Equatable implementation.
    static func == (lhs: FollowMeState, rhs: FollowMeState) -> Bool {
        return lhs.currentState == rhs.currentState
    }

    /// Returns a copy of the object.
    func copy() -> FollowMeState {
        let copy = FollowMeState(currentState: self.currentState,
                                 counterRequirement: self.counterRequirement)
        return copy
    }
}

/// ViewModel for the FollowMe bottom bar view.
final class FollowMeModeViewModel: DroneWatcherViewModel<FollowMeState>, HUDTargetTrackableMode {
    // MARK: - Internal Properties
    internal var trackerRef: Ref<TargetTracker>?

    // MARK: - Private Properties
    private var followMePilotingItfRef: Ref<FollowMePilotingItf>?
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
        self.listenTrackingIssues(drone: drone)
        self.keepControllerTrackingEnabled(drone: drone)
    }

    /// Remove all current targets.
    func removeAllTargets() {
        self.onboardTracker?.removeAllTargets()
    }
}

// MARK: - Private Funcs
private extension FollowMeModeViewModel {

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
        let copy = state.value.copy()
        self.stateRef = drone.getState { [weak self] state in
            if state?.connectionState == .connected {
                copy.currentState = .checkingRequirements
                self?.enableListeners(drone: drone)
            } else {
                copy.currentState = .droneDisconnected
                self?.removeListeners()
            }
            self?.state.set(copy)
        }
    }

    /// Starts watcher for tracking issues.
    func listenTrackingIssues(drone: Drone) {
        followMePilotingItfRef = drone.getPilotingItf(PilotingItfs.followMe) { [weak self] pilotingItf in
            self?.updateFollowMeState(availabilityIssues: pilotingItf?.availabilityIssues)
        }

        self.updateFollowMeState(availabilityIssues: followMePilotingItfRef?.value?.availabilityIssues)
    }

    /// Starts watcher for onBoard tracker state.
    func listenOnboardTracker(drone: Drone) {
        self.onboardTrackerRef = drone.getPeripheral(Peripherals.onboardTracker) { [weak self] onboardTracker in
            self?.onboardTracker = onboardTracker
            guard let trackingIssues = self?.followMePilotingItfRef?.value?.availabilityIssues else { return }
            self?.updateFollowMeState(availabilityIssues: trackingIssues)

            // Activate FollowMe when the drone is tracking a target.
            let isTracking = onboardTracker?.isTracking == true
            self?.handleFollowMe(drone: drone, enable: isTracking)
        }
    }

    /// Update the current state of the follow me.
    ///
    /// - Parameters:
    ///    - availabilityIssues: follow me tracking issues.
    func updateFollowMeState(availabilityIssues: Set<TrackingIssue>?) {
        let copy = state.value.copy()
        copy.trackingIssuesList = checkRequirement(availabilityIssues: availabilityIssues)
        copy.currentState = copy.trackingIssuesList.isEmpty == true
            ? (self.onboardTracker?.isTracking == true ? .tracking : .selectYourself)
            : .notAvailable
        state.set(copy)
    }

    /// Activate or deactivate Follow Me mode.
    ///
    /// - Parameters:
    ///    - drone: drone on which we want to activate/deactivate follow me mode.
    ///    - enable: Precise if we want to activate or deactivate follow me mode.
    func handleFollowMe(drone: Drone, enable: Bool) {
        let isFollowMeActive = drone.getPilotingItf(PilotingItfs.followMe)?.state == .active

        if enable && !isFollowMeActive {
            _ = drone.getPilotingItf(PilotingItfs.followMe)?.activate()
        } else if !enable && isFollowMeActive {
            _ = drone.getPilotingItf(PilotingItfs.followMe)?.deactivate()
        }
    }

    /// Check follow me requirements.
    ///
    /// - Parameters:
    ///    - availabilityIssues: follow me tracking issues.
    /// - Returns: Required issues sorted by priority.
    func checkRequirement(availabilityIssues: Set<TrackingIssue>?) -> [TrackingIssue] {
        guard let strongAvailabilityIssues = availabilityIssues else { return [] }
        return TrackingIssue.requiredIssues.filter({ strongAvailabilityIssues.contains($0) })
    }

    /// Clear every variables of the view model.
    func clearOnBoardTracking() {
        self.onboardTracker?.removeAllTargets()
        self.onboardTrackerRef = nil
        self.onboardTracker = nil

        guard let drone = self.drone else { return }
        self.handleFollowMe(drone: drone, enable: false)
        self.stopTracking(drone: drone)
    }
}

// MARK: Internal Funcs
extension FollowMeModeViewModel {
    /// Returns a BarButtonState for a specific state.
    ///
    /// - Returns: A BarButtonState.
    func updateBottomBarButtonState() -> BottomBarButtonState {
        guard let firstIssue = self.state.value.trackingIssuesList.first else {
            return BottomBarButtonState(title: L10n.missionModeFollowMe.uppercased(),
                                        subtext: self.state.value.currentState.title)
        }
        return BottomBarButtonState(title: L10n.missionModeFollowMe.uppercased(),
                                    subtext: firstIssue.issueString,
                                    image: Asset.Remote.icErrorUpdate.image)
    }
}
