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

/// Watches flight plan activation and exposes the active flight plan if any
///
/// When publishing any new value, the matching property should already expose this new value (didSet behavior).
/// The active flight plan should be published before the activating one is set to nil
public protocol ActiveFlightPlanExecutionWatcher: AnyObject {
    /// The couple of the active flight plan
    var activeFlightPlan: FlightPlanModel? { get }
    /// Publisher for the active flight plan
    var activeFlightPlanPublisher: AnyPublisher<FlightPlanModel?, Never> { get }
    /// Publisher for an activating flight plan
    var activatingFlightPlanPublisher: AnyPublisher<FlightPlanModel?, Never> { get }
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
}

/// Implementation for ActiveFlightPlanExecutionWatcher
public class ActiveFlightPlanExecutionWatcherImpl {
    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    /// Flight plan repository
    private unowned var flightPlanRepository: FlightPlanRepository
    /// Subject holding active flight plan's id if any
    private var activeFlightPlanUuidSubject = CurrentValueSubject<String?, Never>(nil)
    /// Subject holding activating flight plan if any
    private var activatingFlightPlanUuidSubject = CurrentValueSubject<String?, Never>(nil)

    // MARK: init

    /// Init
    ///
    /// - Parameters:
    ///   - flightPlanRepository: flight plan repository
    public init(flightPlanRepository: FlightPlanRepository) {
        self.flightPlanRepository = flightPlanRepository
    }
}

// MARK: ULogTag
private extension ULogTag {
    /// Tag for this file
    static let tag = ULogTag(name: "ActiveFlightPlanWatcher")
}

// MARK: Private functions
private extension ActiveFlightPlanExecutionWatcherImpl {

    /// Fetch the flight plan for an uuid
    /// - Parameter uuid: the flight plan's uuid
    /// - Returns: the matching flight plan if any
    func flightPlanFor(uuid: String) -> FlightPlanModel? {
        if let flightPlan = flightPlanRepository.loadFlightPlans("uuid", uuid).first {
            return flightPlan
        }
        return nil
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

    public var activatingFlightPlanPublisher: AnyPublisher<FlightPlanModel?, Never> {
        activatingFlightPlanUuidSubject.map({ [unowned self] in
            if let uuid = $0 {
               return flightPlanFor(uuid: uuid)
            }
            return nil
        }).eraseToAnyPublisher()
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
        ULog.i(.tag, "Flight plan will be activated. Uuid: \(flightPlan.uuid)")
        activatingFlightPlanUuidSubject.value = flightPlan.uuid
    }

    public func flightPlanActivationFailed(_ flightPlan: FlightPlanModel) {
        ULog.i(.tag, "Flight plan activation failed. Uuid: \(flightPlan.uuid)")
        activatingFlightPlanUuidSubject.value = nil
    }

    public func flightPlanActivationSucceeded(_ flightPlan: FlightPlanModel) {
        ULog.i(.tag, "Flight plan is active. Uuid: \(flightPlan.uuid)")
        activeFlightPlanUuidSubject.value = flightPlan.uuid
        activatingFlightPlanUuidSubject.value = nil
    }

    public func flightPlanDidStop(_ flightPlan: FlightPlanModel) {
        ULog.i(.tag, "Flight plan did finish. Uuid: \(flightPlan.uuid)")
        activeFlightPlanUuidSubject.value = nil
    }
}
