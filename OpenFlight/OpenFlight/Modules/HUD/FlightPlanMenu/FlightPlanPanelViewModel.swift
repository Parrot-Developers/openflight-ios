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

/// State for `FlightPlanPanelViewModel`.
final class FlightPlanPanelState: DeviceConnectionState {
    // MARK: - Internal Properties
    /// Keeps current mission mode.
    fileprivate(set) var missionMode: MissionMode = FlightPlanMissionMode.standard.missionMode
    /// Flight plan id.
    fileprivate(set) var flightPlanID: String?
    /// Flight plan has WayPoint.
    fileprivate(set) var hasWayPoints: Bool = false
    /// Flight plan estimations.
    fileprivate(set) var flightPlanEstimations: FlightPlanEstimationsModel?
    /// Run Flight plan state.
    fileprivate(set) var runFlightPlanState: RunFlightPlanState?

    /// Boolean describing if a flight plan is currently loaded.
    var isFlightPlanLoaded: Bool {
        return flightPlanID != nil
    }

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: drone connection state
    ///    - flightPlanID: Flight Plan Id
    ///    - hasWayPoints: has wayPoints
    ///    - flightPlanEstimations: estimations for Flight Plan
    ///    - runFlightPlanState: run Flight Plan state
    init(connectionState: DeviceState.ConnectionState,
         flightPlanID: String?,
         hasWayPoints: Bool,
         flightPlanEstimations: FlightPlanEstimationsModel?,
         runFlightPlanState: RunFlightPlanState?) {
        super.init(connectionState: connectionState)

        self.flightPlanID = flightPlanID
        self.hasWayPoints = hasWayPoints
        self.flightPlanEstimations = flightPlanEstimations
        self.runFlightPlanState = runFlightPlanState
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? FlightPlanPanelState else { return false }

        return super.isEqual(to: other)
            && self.missionMode.key == other.missionMode.key
            && self.flightPlanID == other.flightPlanID
            && self.hasWayPoints == other.hasWayPoints
            && self.flightPlanEstimations == other.flightPlanEstimations
            && self.runFlightPlanState == other.runFlightPlanState
    }

    override func copy() -> FlightPlanPanelState {
        let copy = FlightPlanPanelState(connectionState: self.connectionState,
                                        flightPlanID: self.flightPlanID,
                                        hasWayPoints: self.hasWayPoints,
                                        flightPlanEstimations: self.flightPlanEstimations,
                                        runFlightPlanState: self.runFlightPlanState)
        copy.missionMode = missionMode

        return copy
    }
}

/// View model for flight plan menu.
final class FlightPlanPanelViewModel: DroneStateViewModel<FlightPlanPanelState> {
    // MARK: - Private Properties
    private let missionLauncherViewModel = MissionLauncherViewModel()
    private var flightPlanListener: FlightPlanListener?
    private var runFlightPlanViewModelListener: RunFlightPlanListener?
    private var flightPlanViewModel: FlightPlanViewModel?

    // MARK: - Override Funcs
    override init() {
        super.init()

        listenMissionLauncherViewModel()
        initFlightPlanListener()
    }

    // MARK: - Internal Funcs
    /// Sends currently loaded flight plan to drone and starts it.
    func startFlightPlan() {
        flightPlanViewModel?.runFlightPlanViewModel.togglePlayPause()
    }

    /// Stops current runnning flight plan.
    func stopFlightPlan() {
        flightPlanViewModel?.runFlightPlanViewModel.stop()
    }
}

// MARK: - Private Funcs
private extension FlightPlanPanelViewModel {
    /// Inits flight plan listener.
    func initFlightPlanListener() {
        flightPlanListener = FlightPlanManager.shared.register(didChange: { [weak self] flightPlanViewModel in
            // Stop previous Flight Plan if it has one.
            if flightPlanViewModel?.state.value.uuid != self?.state.value.flightPlanID {
                self?.flightPlanViewModel?.runFlightPlanViewModel.stop()
            }

            self?.flightPlanViewModel?.unregisterRunListener(self?.runFlightPlanViewModelListener)
            self?.flightPlanViewModel = flightPlanViewModel

            let copy = self?.state.value.copy()
            copy?.flightPlanID = flightPlanViewModel?.state.value.uuid
            copy?.hasWayPoints = flightPlanViewModel?.isEmpty == false
            copy?.flightPlanEstimations = flightPlanViewModel?.estimations
            self?.state.set(copy)

            self?.runFlightPlanViewModelListener = flightPlanViewModel?.registerRunListener(didChange: { [weak self] state in
                let copy = self?.state.value.copy()
                copy?.runFlightPlanState = nil
                self?.state.set(copy)
                copy?.runFlightPlanState = state
                self?.state.set(copy)
            })
        })
    }

    /// Starts watcher for mission modes.
    func listenMissionLauncherViewModel() {
        self.updateState(with: missionLauncherViewModel.state.value)
        missionLauncherViewModel.state.valueChanged = { [weak self] state in
            self?.updateState(with: state)
        }
    }

    /// Updates state regarding mission mode.
    ///
    /// - Parameters:
    ///    - missionLauncherState: mission launcher state
    func updateState(with missionLauncherState: MissionLauncherState?) {
        if let mode = missionLauncherState?.mode {
            let copy = self.state.value.copy()
            copy.missionMode = mode
            self.state.set(copy)
        }
    }
}
