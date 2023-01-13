//    Copyright (C) 2022 Parrot Drones SAS
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

private extension ULogTag {
    static let tag = ULogTag(name: "MemoryPressureMonitorService")
}

/// The system memory pressure states.
public enum MemoryPressureState {
    case unknown, normal, warning, critical
}

/// The protocol defining the memory pressure monitor service.
public protocol MemoryPressureMonitorService: AnyObject {
    /// The system memory pressure changes publisher.
    var eventsPublisher: AnyPublisher<MemoryPressureState, Never> { get }

    /// The system memory pressure current state.
    /// WARNING: This value may not reflect correctly the current memory pressure state .
    /// The Dispatch Source system seems to not send an event when pressure go back to `.normal` state.
    var state: MemoryPressureState { get }
}

// MARK: - Implementation

/// An implementation of the `MemoryPressureMonitorService` protocol.
class MemoryPressureMonitorServiceImpl {

    // MARK: Private properties

    /// The dispatch source that monitors the system for changes in the memory pressure condition.
    private let dispatchSource = DispatchSource.makeMemoryPressureSource(eventMask: .all)

    /// The system memory pressure state subject.
    private var stateSubject = CurrentValueSubject<MemoryPressureState, Never>(.unknown)

    // MARK: Init

    /// Constructor.
    init() {
        dispatchSource.setEventHandler { [unowned self] in
            // Ensure the DispatchSource has not been cancelled before publishing the event.
            guard !self.dispatchSource.isCancelled else { return }
            stateSubject.value = dispatchSource.data.state
            ULog.i(.tag, "Received memory pressure event: \(stateSubject.value)")
        }
        dispatchSource.activate()
    }
}

// MARK: `MemoryPressureMonitorService` protocol conformance

extension MemoryPressureMonitorServiceImpl: MemoryPressureMonitorService {

    var eventsPublisher: AnyPublisher<MemoryPressureState, Never> { stateSubject.eraseToAnyPublisher() }

    var state: MemoryPressureState { stateSubject.value }
}

// MARK: - Extensions Helpers

extension DispatchSource.MemoryPressureEvent {
    /// The current `MemoryPressureState`.
    var state: MemoryPressureState {
        switch self {
        case .normal:
            return .normal
        case .warning:
            return .warning
        case .critical:
            return .critical
        default:
            return .unknown
        }
    }
}
