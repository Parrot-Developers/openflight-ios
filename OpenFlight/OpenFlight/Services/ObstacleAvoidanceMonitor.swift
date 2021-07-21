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

import Foundation
import GroundSdk
import Combine
import SwiftyUserDefaults

private extension ULogTag {
    static let tag = ULogTag(name: "OAMonitor")
}

/// Output of `ObstacleAvoidanceMonitor`: exposes which OA mode is applied and the reason why
public enum AppliedObstacleAvoidanceMode: Equatable {
    /// A flight plan is active, the OA mode is applied accordingly to its OA setting
    case flightPlan(mode: ObstacleAvoidanceMode, recoveryId: String)
    /// There's no active flight plan, the OA mode is applied accordingly to the latest user defined preference
    case userDefined(mode: ObstacleAvoidanceMode)
    /// A flight plan is active, but the user overrode its OA setting explicitely. The applied mode is the user's preferred one
    case userOverrideFlightPlan(userMode: ObstacleAvoidanceMode, recoveryId: String, flightPlanMode: ObstacleAvoidanceMode)

    /// Direct access to the applied model
    var mode: ObstacleAvoidanceMode {
        switch self {
        case .flightPlan(mode: let mode, recoveryId: _):
            return mode
        case .userDefined(mode: let mode):
            return mode
        case .userOverrideFlightPlan(userMode: let userMode, recoveryId: _, flightPlanMode: _):
            return userMode
        }
    }
}

/// Service that applies the ObstacleAvoidance preferred mode to the drone
///
/// - handles user requests to change his OA preferred mode
/// - monitors flight plan activity
/// - applies sthe OA mode accordingly
///
/// See `AppliedObstacleAvoidanceMode` that exposes the potential cases and the rules
///
public protocol ObstacleAvoidanceMonitor: AnyObject {
    /// Publisher for applied OA mode depending on monitoring flight plans runs and handling user requests
    var appliedModePublisher: AnyPublisher<AppliedObstacleAvoidanceMode, Never> { get }
    /// Handler for explicit user action to change the OA mode
    func userAsks(mode: ObstacleAvoidanceMode)
}

/// User Defaults keys for internal `ObstacleAvoidanceMonitorImpl` use
private extension DefaultsKeys {
    /// Storage key for user preferred OA mode
    var preferredObstacleAvoidanceMode: DefaultsKey<String?> { .init("key_preferredObstacleAvoidanceMode") }
    /// Storage to remember the last flight plan's id for which the user overrode the OA mode
    var lastFlighPlantWithObstacleAvoidanceOverride: DefaultsKey<String?> { .init("key_lastFlighPlantWithObstacleAvoidanceOverrideRecoveryId") }
}

/// Implementation of `ObstacleAvoidanceMonitor`
public class ObstacleAvoidanceMonitorImpl {

    // MARK: Private properties

    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    /// Active flight plan watcher
    private unowned var activeFlightPlanWatcher: ActiveFlightPlanExecutionWatcher
    /// GroundSdk ref for obstacle avoidance peripheral
    private var oaPeripheralRef: Ref<ObstacleAvoidanceDesc.ApiProtocol>?
    /// Latest obstacle avoidance peripheral
    private weak var oaPeripheral: ObstacleAvoidance?
    /// User defaults stored user preferred obstacle avoidance mode
    private var userPreferredMode: ObstacleAvoidanceMode {
        get {
            if let rawValue = Defaults[\.preferredObstacleAvoidanceMode],
               let value = ObstacleAvoidanceMode(rawValue: rawValue) {
                return value
            }

            return .standard
        }
        set {
            Defaults.preferredObstacleAvoidanceMode = newValue.rawValue
        }
    }
    /// Last flight plan recovery id for which the user explicitely overrode the obstacle avoidance mode
    private var lastFlightPlanOverridenRecoveryId: String? {
        get {
            return Defaults[\.lastFlighPlantWithObstacleAvoidanceOverride]
        }
        set {
            Defaults.lastFlighPlantWithObstacleAvoidanceOverride = newValue
        }
    }

    /// Output of this service representing its chosen OA mode and the reason why
    private var appliedModeSubject = CurrentValueSubject<AppliedObstacleAvoidanceMode, Never>(.userDefined(mode: .standard))

    // MARK: init

    /// Init
    /// - Parameters:
    ///   - currentDroneHolder: drone holder
    ///   - activeFlightPlanWatcher: the active flight plan watcher
    public init(currentDroneHolder: CurrentDroneHolder, activeFlightPlanWatcher: ActiveFlightPlanExecutionWatcher) {
        self.activeFlightPlanWatcher = activeFlightPlanWatcher
        // Listen to drone, OA mode and active FP changes
        listen(dronePublisher: currentDroneHolder.dronePublisher)
        listenActiveFlightPlan()
    }
}

// MARK: Private functions
private extension ObstacleAvoidanceMonitorImpl {

    /// Listen for the current drone
    /// - Parameter dronePublisher: the drone publisher
    func listen(dronePublisher: AnyPublisher<Drone, Never>) {
        dronePublisher.sink { [unowned self] drone in
            listenObstacleAvoidancePeripheral(drone: drone)
        }
        .store(in: &cancellables)
    }

    /// Listen for OA peripheral
    /// - Parameter drone: current drone
    func listenObstacleAvoidancePeripheral(drone: Drone) {
        oaPeripheralRef = drone.getPeripheral(Peripherals.obstacleAvoidance) { [unowned self] oaPeripheral in
            self.oaPeripheral = oaPeripheral
            if oaPeripheral != nil {
                applyRelevantMode()
            }
        }
    }

    /// Listen for active flight plan
    func listenActiveFlightPlan() {
        activeFlightPlanWatcher.activeFlightPlanAndRecoveryIdPublisher.sink { [unowned self] _ in
            applyRelevantMode()
        }
        .store(in: &cancellables)
    }

    /// Convert a flight plan OA activation flag to an OA mode
    /// - Parameter activateBool: the flight plan OA activation flag
    /// - Returns: the OA mode
    func toMode(_ activateBool: Bool?) -> ObstacleAvoidanceMode { activateBool ?? true ? .standard : .disabled }

    /// Change the OA mode of the drone if needed
    /// - Parameter mode: the mode to apply
    func setToDrone(mode: ObstacleAvoidanceMode) {
        guard let oaPeripheral = oaPeripheral, oaPeripheral.mode.preferredValue != mode else { return }
        ULog.i(.tag, "Applying OA mode to drone: \(mode), was \(oaPeripheral.mode.preferredValue)")
        oaPeripheral.mode.preferredValue = mode
    }

    /// Core algorithm to expose what case we're in
    /// - Returns: an enum representing the case and carrying the OA mode to apply
    func selectModeToApply() -> AppliedObstacleAvoidanceMode {
        if let (flightPlan, recoveryId) = activeFlightPlanWatcher.activeFlightPlanAndRecoveryId {
            // We have a flight plan, by default its OA setting should override the user's one
            let flightPlanMode = toMode(flightPlan.obstacleAvoidanceActivated)
            if lastFlightPlanOverridenRecoveryId == recoveryId {
                // The user has already overriden the flight plan's OA setting, let's apply user's mode
                return .userOverrideFlightPlan(userMode: userPreferredMode, recoveryId: recoveryId, flightPlanMode: flightPlanMode)
            } else {
                // There was no user override for this flight plan, let's apply the flight plan OA setting
                return .flightPlan(mode: flightPlanMode, recoveryId: recoveryId)
            }
        } else {
            // No active flight plan, apply user's mode
            return .userDefined(mode: userPreferredMode)
        }
    }

    /// Select and apply the current mode, expose the current choice
    func applyRelevantMode() {
        let modeToApply = selectModeToApply()
        // Anyway ensure the drone has the right mode
        setToDrone(mode: modeToApply.mode)
        // Change the applied mode only if it differs
        if appliedModeSubject.value != modeToApply {
            ULog.i(.tag, "Saving applied mode \(modeToApply)")
            appliedModeSubject.value = modeToApply
        }
    }
}

// MARK: ObstacleAvoidanceMonitor protocol conformance
extension ObstacleAvoidanceMonitorImpl: ObstacleAvoidanceMonitor {

    public var appliedModePublisher: AnyPublisher<AppliedObstacleAvoidanceMode, Never> { appliedModeSubject.eraseToAnyPublisher() }

    public func userAsks(mode: ObstacleAvoidanceMode) {
        // Store the value
        userPreferredMode = mode
        // It there's an executing flight plan, remember we are overriding its OA mode
        if let recoveryId = activeFlightPlanWatcher.activeFlightPlanAndRecoveryId?.1 {
            lastFlightPlanOverridenRecoveryId = recoveryId
        }
        // Apply
        applyRelevantMode()
    }
}
