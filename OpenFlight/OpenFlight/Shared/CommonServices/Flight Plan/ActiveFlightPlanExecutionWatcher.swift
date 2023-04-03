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

import Foundation
import Combine
import GroundSdk
import Pictor

/// Enum describing the possible Active Flight Plan states.
public enum ActiveFlightPlanState {
    /// No flight plan is currently active or activating.
    case none
    /// Flight Plan is activating.
    case activating(FlightPlanModel)
    /// Flight Plan is active.
    case active(FlightPlanModel)

    /// Whether there is currently no active or activating flight plan.
    var isInactive: Bool {
        if case .none = self { return true }
        return false
    }
}

/// Watches flight plan activation and exposes the active flight plan if any
///
/// When publishing any new value, the matching property should already expose this new value (didSet behavior).
/// The active flight plan should be published before the activating one is set to nil
public protocol ActiveFlightPlanExecutionWatcher: AnyObject {
    /// The couple of the active flight plan
    var activeFlightPlan: FlightPlanModel? { get }
    /// Publisher for the active flight plan
    var activeFlightPlanPublisher: AnyPublisher<FlightPlanModel?, Never> { get }
    /// Publisher for the active flight plan state.
    var activeFlightPlanStatePublisher: AnyPublisher<ActiveFlightPlanState, Never> { get }
    /// Active flight plan state.
    var activeFlightPlanState: ActiveFlightPlanState { get }
    /// Publisher to expose whether a flight plan with time or GPS lapse is being executed
    var hasActiveFlightPlanWithTimeOrGpsLapsePublisher: AnyPublisher<Bool, Never> { get }
    /// Whether a flight plan with time or GPS lapse is being executed
    var hasActiveFlightPlanWithTimeOrGpsLapse: Bool { get }

    /// The component responsible for activating the flight plan should let this watcher know about it
    ///
    /// - Parameter flightPlan: the flight plan being activated
    func flightPlanWillBeActivated(_ flightPlan: FlightPlanModel)

    /// The component responsible for activating the flight plan should let this watcher know when an activation failed
    ///
    /// - Parameter flightPlan: the flight plan
    func flightPlanActivationFailed(_ flightPlan: FlightPlanModel)

    /// The component responsible for activating the flight plan should let this watcher know when an activation succeeded
    ///
    /// - Parameter flightPlan: the flight plan
    func flightPlanActivationSucceeded(_ flightPlan: FlightPlanModel)

    /// The component responsible for activating the flight plan should let this watcher know when an execution ended
    ///
    /// - Parameter flightPlan: the flight plan
    func flightPlanDidStop(_ flightPlan: FlightPlanModel)

    /// The component responsible for keeping the running flight plan up to date should let this watcher know when an execution is updated.
    ///
    /// - Parameter flightPlan: the flight plan
    func flightPlanDidUpdate(_ flightPlan: FlightPlanModel?)
}

/// Implementation for ActiveFlightPlanExecutionWatcher
public class ActiveFlightPlanExecutionWatcherImpl {
    /// Flight plan repository
    private unowned var flightPlanRepository: PictorFlightPlanRepository
    /// Subject holding active flight plan's id if any
    private var activeFlightPlanUuidSubject = CurrentValueSubject<String?, Never>(nil)
    /// Subject holding the active flight plan state.
    var activeFlightPlanStateSubject = CurrentValueSubject<ActiveFlightPlanState, Never>(.none)
    /// Running Flight Plan
    private var runningFlightPlan: FlightPlanModel?

    // MARK: init

    /// Init
    ///
    /// - Parameters:
    ///   - flightPlanRepository: flight plan repository
    public init(flightPlanRepository: PictorFlightPlanRepository) {
        self.flightPlanRepository = flightPlanRepository
    }
}

// MARK: ULogTag
private extension ULogTag {
    /// Tag for this file
    static let tag = ULogTag(name: "FPActiveFlightPlanWatcher")
}

// MARK: Private functions
private extension ActiveFlightPlanExecutionWatcherImpl {

    /// Returns the flight plan for an uuid
    /// - Parameters:
    ///    - uuid: the flight plan's uuid
    ///    - forceDataBaseFetching: whether the data base fetching is needed
    /// - Returns: the matching flight plan if any
    ///
    /// - Description: If not asked via `forceDataBaseFetching`, the local flight plan, if exists, updated by the Run Manager,
    ///                is used instead of fetching the Data Base.
    func flightPlanFor(uuid: String, forceDataBaseFetching: Bool = false) -> FlightPlanModel? {
        // Get the FP from the Data Base when one of the following conditions is met:
        //     • Either a "Force Data Base Fetching" is requested,
        //     • Or the uuid is not the same than the current local `runningFlightPlan`.
        if forceDataBaseFetching
            || runningFlightPlan?.uuid != uuid {
            runningFlightPlan = flightPlanRepository.get(byUuid: uuid)?.flightPlanModel
        }
        return runningFlightPlan
    }

    func isInTimeOrGpsLapse(_ flightPlan: FlightPlanModel?) -> Bool {
        guard let mode = flightPlan?.dataSetting?.captureModeEnum else { return false }
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

    public var activeFlightPlan: FlightPlanModel? {
        if let uuid = activeFlightPlanUuidSubject.value {
           return flightPlanFor(uuid: uuid)
        }
        return nil
    }

    public var activeFlightPlanPublisher: AnyPublisher<FlightPlanModel?, Never> {
        activeFlightPlanUuidSubject
            .map({ [unowned self] in
                if let uuid = $0 {
                   return flightPlanFor(uuid: uuid)
                }
                return nil
            })
            .eraseToAnyPublisher()
    }

    public var activeFlightPlanStatePublisher: AnyPublisher<ActiveFlightPlanState, Never> {
        activeFlightPlanStateSubject.eraseToAnyPublisher()
    }

    public var activeFlightPlanState: ActiveFlightPlanState {
        activeFlightPlanStateSubject.value
    }

    public var hasActiveFlightPlanWithTimeOrGpsLapsePublisher: AnyPublisher<Bool, Never> {
        activeFlightPlanPublisher.map { [unowned self] in
            isInTimeOrGpsLapse($0)
        }.eraseToAnyPublisher()
    }

    public var hasActiveFlightPlanWithTimeOrGpsLapse: Bool {
        if let flightPlan = activeFlightPlan {
            return isInTimeOrGpsLapse(flightPlan)
        }
        return false
    }

    public func flightPlanWillBeActivated(_ flightPlan: FlightPlanModel) {
        ULog.i(.tag, "Flight plan will be activated '\(flightPlan.uuid)'")
        // When a flight plan will be activated, we must reset the current active one if needed.
        activeFlightPlanStateSubject.value = .activating(flightPlan)
    }

    public func flightPlanActivationFailed(_ flightPlan: FlightPlanModel) {
        ULog.i(.tag, "Flight plan activation failed '\(flightPlan.uuid)'")
        activeFlightPlanStateSubject.value = .none
    }

    public func flightPlanActivationSucceeded(_ flightPlan: FlightPlanModel) {
        ULog.i(.tag, "Flight plan is active '\(flightPlan.uuid)'")
        activeFlightPlanUuidSubject.value = flightPlan.uuid
        activeFlightPlanStateSubject.value = .active(flightPlan)
    }

    public func flightPlanDidStop(_ flightPlan: FlightPlanModel) {
        ULog.i(.tag, "Flight plan did finish '\(flightPlan.uuid)'")
        activeFlightPlanUuidSubject.value = nil
        activeFlightPlanStateSubject.value = .none
        runningFlightPlan = nil
    }

    public func flightPlanDidUpdate(_ flightPlan: FlightPlanModel?) {
        ULog.i(.tag, "Flight plan did update '\(flightPlan?.uuid ?? "")'")
        runningFlightPlan = flightPlan
    }
}
