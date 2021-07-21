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
import Combine
import GroundSdk

public enum ActiveFlightPlanState {
    case none
    case activating(flightPlan: SavedFlightPlan)
    case active(flightPlan: SavedFlightPlan, recoveryId: String)
}

/// Watches flight plan activation and exposes the active flight plan if any
///
/// When publishing any new value, the matching property should already expose this new value (didSet behavior).
/// The active flight plan should be published before the activating one is set to nil
public protocol ActiveFlightPlanExecutionWatcher: AnyObject {
    /// The couple of the active flight plan and its recoveryId if any
    var activeFlightPlanAndRecoveryId: (SavedFlightPlan, String)? { get }
    /// Publisher for the active flight plan
    var activeFlightPlanAndRecoveryIdPublisher: AnyPublisher<(SavedFlightPlan, String)?, Never> { get }
    /// Publisher for an activating flight plan
    var activatingFlightPlan: AnyPublisher<SavedFlightPlan?, Never> { get }
    /// Publisher to expose whether a flight plan with time or GPS lapse is being executed
    var hasActiveFlightPlanWithTimeOrGpsLapsePublisher: AnyPublisher<Bool, Never> { get }
    /// Whether a flight plan with time or GPS lapse is being executed
    var hasActiveFlightPlanWithTimeOrGpsLapse: Bool { get }
    /// The component responsible for activating the flight plan should let this watcher know about it
    /// - Parameter flightPlan: the flight plan being activated
    func flightPlanWillBeActivated(_ flightPlan: SavedFlightPlan)
    /// The component responsible for activating the flight plan should let this watcher know when an activation failed
    func flightPlanActivationFailed()
}

/// Implementation for ActiveFlightPlanExecutionWatcher
public class ActiveFlightPlanExecutionWatcherImpl {
    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    /// Flight plan repository (future model: projects)
    private unowned var flightPlanRepository: FlightPlanDataProtocol
    /// Flight plan execution repository (future model: flight plan)
    private unowned var flightPlanExecutionRepository: FlightPlanExecutionDataProtocol
    /// GroundSdk ref for flight plan piloting interface
    private var fpPilotingItfRef: Ref<FlightPlanPilotingItfs.ApiProtocol>?
    /// Subject holding active flight plan's id if any
    private var activeFlightPlanRecoveryIdSubject = CurrentValueSubject<String?, Never>(nil)
    /// Subject holding activating flight plan if any
    private var activatingFlightPlanSubject = CurrentValueSubject<SavedFlightPlan?, Never>(nil)

    // MARK: init

    /// Init
    /// - Parameters:
    ///   - currentDroneHolder: drone holder
    ///   - flightPlanRepository: flight plan repository
    ///   - flightPlanExecutionRepository: the flight plan execution repository
    public init(currentDroneHolder: CurrentDroneHolder,
                flightPlanRepository: FlightPlanDataProtocol,
                flightPlanExecutionRepository: FlightPlanExecutionDataProtocol) {
        self.flightPlanRepository = flightPlanRepository
        self.flightPlanExecutionRepository = flightPlanExecutionRepository
        // Listen to drone, and active FP changes
        listen(dronePublisher: currentDroneHolder.dronePublisher)
    }
}

// MARK: ULogTag
private extension ULogTag {
    /// Tag for this file
    static let tag = ULogTag(name: "ActiveFlightPlanWatcher")
}

// MARK: Private functions
private extension ActiveFlightPlanExecutionWatcherImpl {
    /// Listen for the current drone
    /// - Parameter dronePublisher: the drone publisher
    func listen(dronePublisher: AnyPublisher<Drone, Never>) {
        dronePublisher.sink { [unowned self] drone in
            listenFlightPlanPilotingItf(drone: drone)
        }
        .store(in: &cancellables)
    }

    /// Listen for flight plan piloting itf
    /// - Parameter drone: current drone
    func listenFlightPlanPilotingItf(drone: Drone) {
        // We're interested in monitoring any flightPlan that is being executed
        // ( meaning itf.state == .active ) with a non-nil flight plan id
        fpPilotingItfRef = drone.getPilotingItf(PilotingItfs.flightPlan) { [unowned self] pilotingItf in
            if let pilotingItf = pilotingItf,
               pilotingItf.state == .active,
               // TODO: this shouldn't be this way (there's a proper recovery id exposed by GroundSdk) but we have
               // to match what RunFlightPlanViewModel does (poorly)
               let recoveryId = pilotingItf.flightPlanId,
               flightPlanFor(recoveryId: recoveryId) != nil {
                set(recoveryId: recoveryId)
            } else {
                set(recoveryId: nil)
            }
        }
    }

    func set(recoveryId: String?) {
        guard recoveryId != activeFlightPlanRecoveryIdSubject.value else { return }
        if let recoveryId = recoveryId {
            ULog.i(.tag, "Flight plan is active. RecoveryId: \(recoveryId)")
        } else {
            ULog.i(.tag, "Flight plan is not active.")
        }
        activeFlightPlanRecoveryIdSubject.value = recoveryId
        // If the flight plan was declared as activating, now it's really active so forget about the activating state
        if activatingFlightPlanSubject.value != nil {
            activatingFlightPlanSubject.value = nil
        }
    }

    /// Fetch the flight plan associated with the execution's recoveryId
    /// - Parameter recoveryId: the execution's recoveryId
    /// - Returns: the matching flight plan if any
    func flightPlanFor(recoveryId: String) -> SavedFlightPlan? {
        if let execution = flightPlanExecutionRepository.executions(forRecoveryId: recoveryId).first {
           return flightPlanRepository.savedFlightPlan(for: execution.flightPlanId)
        }
        return nil
    }

    func isInTimeOrGpsLapse(_ flightPlan: (SavedFlightPlan, String)?) -> Bool {
        guard let mode = flightPlan?.0.plan.captureModeEnum else { return false }
        switch mode {
        case .video:
            return false
        case .timeLapse, .gpsLapse:
            return true
        }
    }
}

// MARK: ActiveFlightPlanExecutionWatcher conformance
extension ActiveFlightPlanExecutionWatcherImpl: ActiveFlightPlanExecutionWatcher {

    public var activeFlightPlanAndRecoveryId: (SavedFlightPlan, String)? {
        if let recoveryId = activeFlightPlanRecoveryIdSubject.value,
           let flightPlan = flightPlanFor(recoveryId: recoveryId) {
            return (flightPlan, recoveryId)
        }
        return nil
    }

    public var activeFlightPlanAndRecoveryIdPublisher: AnyPublisher<(SavedFlightPlan, String)?, Never> {
        activeFlightPlanRecoveryIdSubject
            .map({ [unowned self] in
                if let recoveryId = $0,
                   let flightPlan = flightPlanFor(recoveryId: recoveryId) {
                    return (flightPlan, recoveryId)
                }
                return nil
            })
            .eraseToAnyPublisher()
    }

    public var activatingFlightPlan: AnyPublisher<SavedFlightPlan?, Never> { activatingFlightPlanSubject.eraseToAnyPublisher() }

    public var hasActiveFlightPlanWithTimeOrGpsLapsePublisher: AnyPublisher<Bool, Never> {
        activeFlightPlanAndRecoveryIdPublisher.map { [unowned self] in
            isInTimeOrGpsLapse($0)
        }.eraseToAnyPublisher()
    }

    public var hasActiveFlightPlanWithTimeOrGpsLapse: Bool {
        let couple: (SavedFlightPlan, String)?
        if let recoveryId = activeFlightPlanRecoveryIdSubject.value,
           let flightPlan = flightPlanFor(recoveryId: recoveryId) {
            couple = (flightPlan, recoveryId)
        } else {
            couple = nil
        }
        return isInTimeOrGpsLapse(couple)
    }

    public func flightPlanWillBeActivated(_ flightPlan: SavedFlightPlan) {
        activatingFlightPlanSubject.value = flightPlan
    }

    public func flightPlanActivationFailed() {
        activatingFlightPlanSubject.value = nil
    }
}
