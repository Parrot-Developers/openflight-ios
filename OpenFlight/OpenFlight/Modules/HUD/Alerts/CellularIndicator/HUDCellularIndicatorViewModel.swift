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

import GroundSdk
import SwiftyUserDefaults

/// State for `HUDCellularIndicatorViewModel`.
final class HUDCellularIndicatorState: DeviceConnectionState {
    // MARK: - Internal Properties
    /// Returns the cellular state.
    fileprivate(set) var currentCellularState: HUDCellularState = .noState
    /// Returns stack of potential 4G errors.
    fileprivate(set) var cellularErrorStack: Set<HUDCellularStateError> = []
    /// Tells if current alert has been dismissed.
    fileprivate(set) var isCurrentAlertDismissed: Bool = false

    // MARK: - Helpers
    /// Returns the current error regarding its priority.
    var currentAlert: HUDCellularStateError? {
        return cellularErrorStack
            .sorted(by: { $0.rawValue > $1.rawValue })
            .first
    }

    /// Returns true if we need to show connection error.
    var shouldShowCellularAlert: Bool {
        return isConnected()
            && !isCurrentAlertDismissed
            && currentAlert != nil
    }

    /// Returns true if we need to show connection info.
    /// It depends of current link, drone connection and if this alert has been already displayed.
    var shouldShowCellularInfo: Bool {
        return isConnected()
            && !isCurrentAlertDismissed
            && currentCellularState != .noState
    }

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Inits.
    ///
    /// - Parameters:
    ///    - connectionState: device connection state
    ///    - currentCellularState: cellular connection state
    ///    - cellularErrorStack: stack of connection errors
    ///    - isCurrentAlertDismissed: returns true if an alert is dismissed
    init(connectionState: DeviceState.ConnectionState,
         currentCellularState: HUDCellularState,
         cellularErrorStack: Set<HUDCellularStateError>,
         isCurrentAlertDismissed: Bool) {
        super.init(connectionState: connectionState)

        self.currentCellularState = currentCellularState
        self.cellularErrorStack = cellularErrorStack
        self.isCurrentAlertDismissed = isCurrentAlertDismissed
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? HUDCellularIndicatorState else { return false }

        return super.isEqual(to: other)
            && self.currentCellularState == other.currentCellularState
            && self.cellularErrorStack == other.cellularErrorStack
            && self.isCurrentAlertDismissed == other.isCurrentAlertDismissed
    }

    override func copy() -> HUDCellularIndicatorState {
        return HUDCellularIndicatorState(connectionState: connectionState,
                                         currentCellularState: currentCellularState,
                                         cellularErrorStack: cellularErrorStack,
                                         isCurrentAlertDismissed: isCurrentAlertDismissed)
    }
}

/// Observes drone state in order to provide information about 4G on the HUD.
final class HUDCellularIndicatorViewModel: DroneStateViewModel<HUDCellularIndicatorState> {
    // MARK: - Private Properties
    private var returnHomeRef: Ref<ReturnHomePilotingItf>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var cellularRef: Ref<Cellular>?
    private var networkControlRef: Ref<NetworkControl>?

    // MARK: - Deinit
    deinit {
        returnHomeRef = nil
        flyingIndicatorsRef = nil
        cellularRef = nil
        networkControlRef = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenNetworkControl(drone)
        listenCellular(drone)
        updateCellularState()
    }

    override func droneConnectionStateDidChange() {
        super.droneConnectionStateDidChange()

        // Resets error at each disconnection.
        if drone?.isConnected == false {
            resetInfosStack()
            updateAlertVisibility(shouldDismiss: false)
        }
    }

    // MARK: - Internal Funcs
    /// Dismisses current alert.
    func stopProcess() {
        updateAlertVisibility(shouldDismiss: true)
    }

    /// Resumes process.
    func resumeProcess() {
        resetInfosStack()
        updateCellularState()
    }
}

// MARK: - Private Funcs
private extension HUDCellularIndicatorViewModel {
    /// Starts watcher for drone cellular.
    func listenCellular(_ drone: Drone) {
        cellularRef = drone.getPeripheral(Peripherals.cellular) { [weak self] _ in
            self?.updateCellularState()
        }
    }

    /// Starts watcher for drone network control.
    func listenNetworkControl(_ drone: Drone) {
        networkControlRef = drone.getPeripheral(Peripherals.networkControl) { [weak self] _ in
            self?.updateCellularState()
        }
    }

    /// Updates 4G state.
    func updateCellularState() {
        guard let drone = drone else {
            resetInfosStack()
            return
        }

        // Checks if cellular is available.
        // It also checks if current drone is paired.
        guard drone.isConnected,
              Defaults.cellularPairedDronesList.contains(drone.uid),
              let cellular = drone.getPeripheral(Peripherals.cellular) else {
            resetInfosStack()
            return
        }

        // Update current state.
        let networkControl = drone.getPeripheral(Peripherals.networkControl)
        let cellularLink = networkControl?.links.first(where: { $0.type == .cellular })

        let isCellularAvailable = cellular.isAvailable
            && cellular.mode.value == .data
        if cellularLink?.status == .running {
            updateCellularState(with: .cellularConnected)
        } else if isCellularAvailable {
            updateCellularState(with: .cellularConnecting)
        } else if networkControl?.currentLink == .wlan {
            // Returns if current link is not the cellular one.
            // Happens in case of wlan or cellular issue.
            updateCellularState(with: .noState)
        } else {
            // Update errors.
            updateInfosStack(with: .simLocked,
                             shouldAdd: cellular.simStatus == .locked
                                && cellular.pinRemainingTries > 0)
            let hasLinkError: Bool = cellularLink?.error != nil
                || cellularLink?.status != .error
            updateInfosStack(with: .connectionFailed,
                             shouldAdd: hasLinkError)
            let isNotRegistered: Bool = cellular.registrationStatus == .denied || cellular.registrationStatus == .notRegistered
            updateInfosStack(with: .notRegistered,
                             shouldAdd: isNotRegistered)
            updateInfosStack(with: .simBlocked,
                             shouldAdd: cellular.simStatus == .locked
                                && cellular.pinRemainingTries == 0)
            updateInfosStack(with: .networkStatusError,
                             shouldAdd: cellular.networkStatus == .error)
            updateInfosStack(with: .networkStatusDenied,
                             shouldAdd: cellular.networkStatus == .denied)
        }
    }
}

// MARK: - State Update Funcs
private extension HUDCellularIndicatorViewModel {
    /// Updates the infos stack state.
    ///
    /// - Parameters:
    ///     - element: element to add or remove
    ///     - shouldAdd: true if element needs to be added
    func updateInfosStack(with element: HUDCellularStateError, shouldAdd: Bool) {
        let copy = state.value.copy()
        copy.cellularErrorStack.update(element, shouldAdd: shouldAdd)
        state.set(copy)
    }

    /// Updates the cellular state.
    ///
    /// - Parameters:
    ///     - cellularState: current 4G state
    func updateCellularState(with cellularState: HUDCellularState) {
        let copy = state.value.copy()
        copy.currentCellularState = cellularState
        state.set(copy)
    }

    /// Resets entire alerts stack.
    func resetInfosStack() {
        let copy = state.value.copy()
        copy.cellularErrorStack = []
        state.set(copy)
    }

    /// Updates dismissed property.
    ///
    /// - Parameters:
    ///     - shouldDismiss: tells if we dismiss the alert
    func updateAlertVisibility(shouldDismiss: Bool) {
        let copy = state.value.copy()
        copy.isCurrentAlertDismissed = shouldDismiss
        state.set(copy)
    }
}
