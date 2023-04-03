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
import GameKit
import Combine

public protocol ResumableStateDelegate: AnyObject {
    func flightPlanIsResumable(_ flightPlan: FlightPlanModel, startAvailability: FlightPlanStartAvailability)
}

open class ResumableState: GKState {

    private var cancellables = Set<AnyCancellable>()
    private weak var delegate: ResumableStateDelegate?
    private let startAvailabilityWatcher: FlightPlanStartAvailabilityWatcher
    private let edition: FlightPlanEditionService

    var flightPlan: FlightPlanModel!

    init(delegate: ResumableStateDelegate, startAvailabilityWatcher: FlightPlanStartAvailabilityWatcher, edition: FlightPlanEditionService) {
        self.delegate = delegate
        self.startAvailabilityWatcher = startAvailabilityWatcher
        self.edition = edition
    }

    open override func didEnter(from previousState: GKState?) {
        edition.setupFlightPlan(flightPlan)
        startAvailabilityWatcher.availabilityForSendingMavlinkPublisher.sink { [unowned self] in
            delegate?.flightPlanIsResumable(flightPlan, startAvailability: $0)
        }
        .store(in: &cancellables)
    }

    open func flightPlanWasUpdated(_ flightPlan: FlightPlanModel) {
        self.flightPlan = flightPlan
        edition.setupFlightPlan(flightPlan)
    }

    open override func willExit(to nextState: GKState) {
        cancellables = []
    }

    open override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is EditableState.Type
            || stateClass is StartedNotFlyingState.Type
            || stateClass is IdleState.Type
    }
}
