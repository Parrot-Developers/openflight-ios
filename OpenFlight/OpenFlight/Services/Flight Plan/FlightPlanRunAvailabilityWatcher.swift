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

public enum FlightPlanStartUnavailableReason: Equatable, CustomStringConvertible {
    case pilotingItfUnavailable(Set<FlightPlanUnavailabilityReason>)
    case droneDisconnected

    public var description: String {
        switch self {
        case .droneDisconnected:
            return ".droneDisconnected"
        case .pilotingItfUnavailable(let reasons):
            return ".pilotingItfUnavailable(\(reasons))"
        }
    }
}

/// The availability of the drone to **send the Mavlink** in order to run a flight plan
public enum FlightPlanStartAvailability: Equatable, CustomStringConvertible {
    case available
    case unavailable(FlightPlanStartUnavailableReason)
    case alreadyRunning

    public var description: String {
        switch self {
        case .available:
            return ".available"
        case .alreadyRunning:
            return ".alreadyRunning"
        case .unavailable(let reason):
            return ".unavailable(\(reason.description))"
        }
    }
}

public protocol FlightPlanStartAvailabilityWatcher {
    var availabilityForRunningPublisher: AnyPublisher<FlightPlanStartAvailability, Never> { get }
    var availabilityForSendingMavlinkPublisher: AnyPublisher<FlightPlanStartAvailability, Never> { get }
}

public class FlightPlanStartAvailabilityWatcherImpl {

    private var cancellables = Set<AnyCancellable>()
    private var pilotingItfState: ActivablePilotingItfState = .idle
    private var unavailabilityReasons = Set<FlightPlanUnavailabilityReason>()
    private var droneConnected = false

    private var availabilityForSendingMavlinkSubject = CurrentValueSubject<FlightPlanStartAvailability, Never>(.unavailable(.droneDisconnected))
    private var availabilityForRunningSubject = CurrentValueSubject<FlightPlanStartAvailability, Never>(.unavailable(.droneDisconnected))

    private var itfRef: Ref<FlightPlanPilotingItf>?
    private var deviceStateRef: Ref<DeviceState>?

    init(currentDroneHolder: CurrentDroneHolder) {
        currentDroneHolder.dronePublisher.sink { [unowned self] drone in
            itfRef = drone.getPilotingItf(PilotingItfs.flightPlan) { [unowned self] in
                let oldValue = droneConnected
                guard let itf = $0 else {
                    droneConnected = false
                    unavailabilityReasons = []
                    if oldValue != droneConnected {
                        publishNewState()
                    }
                    return
                }
                if pilotingItfState != itf.state || unavailabilityReasons != itf.unavailabilityReasons {
                    pilotingItfState = itf.state
                    unavailabilityReasons = itf.unavailabilityReasons
                    publishNewState()
                }
            }
            deviceStateRef = drone.getState { [unowned self] state in
                let oldValue = droneConnected
                switch state?.connectionState {
                case .none, .disconnected, .connecting, .disconnecting:
                    droneConnected = false
                    unavailabilityReasons = []
                case .connected:
                    droneConnected = true
                }
                if oldValue != droneConnected {
                    publishNewState()
                }
            }
        }
        .store(in: &cancellables)
    }

    private func publishNewState() {
        guard droneConnected else {
            availabilityForSendingMavlinkSubject.value = .unavailable(.droneDisconnected)
            availabilityForRunningSubject.value = .unavailable(.droneDisconnected)
            return
        }
        switch pilotingItfState {
        case .idle:
            availabilityForSendingMavlinkSubject.value = .available
            availabilityForRunningSubject.value = .available
        case .active:
            availabilityForSendingMavlinkSubject.value = .alreadyRunning
            availabilityForRunningSubject.value = .alreadyRunning
        case .unavailable:
            availabilityForRunningSubject.value = .unavailable(.pilotingItfUnavailable(unavailabilityReasons))
            let filteredReasons = unavailabilityReasons.filter { $0 != .missingFlightPlanFile }
            if filteredReasons.isEmpty {
                availabilityForSendingMavlinkSubject.value = .available
            } else {
                availabilityForSendingMavlinkSubject.value = .unavailable(.pilotingItfUnavailable(filteredReasons))
            }
        }
    }
}

extension FlightPlanStartAvailabilityWatcherImpl: FlightPlanStartAvailabilityWatcher {

    public var availabilityForSendingMavlinkPublisher: AnyPublisher<FlightPlanStartAvailability, Never> {
        availabilityForSendingMavlinkSubject.eraseToAnyPublisher()
    }

    public var availabilityForRunningPublisher: AnyPublisher<FlightPlanStartAvailability, Never> { availabilityForRunningSubject.eraseToAnyPublisher() }

}
