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

import GameKit
import Combine

public protocol EditableStateDelegate: AnyObject {
    func flightPlanIsEditable(_ flightPlan: FlightPlanModel, startAvailability: FlightPlanStartAvailability)
}

open class EditableState: GKState {

    private weak var delegate: EditableStateDelegate?
    private let flightPlanManager: FlightPlanManager
    private let projectManager: ProjectManager
    private let startAvailabilityWatcher: FlightPlanStartAvailabilityWatcher
    private let edition: FlightPlanEditionService
    private var cancellables = Set<AnyCancellable>()

    var flightPlan: FlightPlanModel!

    required public init(delegate: EditableStateDelegate,
                         flightPlanManager: FlightPlanManager,
                         projectManager: ProjectManager,
                         startAvailabilityWatcher: FlightPlanStartAvailabilityWatcher,
                         edition: FlightPlanEditionService) {
        self.delegate = delegate
        self.flightPlanManager = flightPlanManager
        self.startAvailabilityWatcher = startAvailabilityWatcher
        self.projectManager = projectManager
        self.edition = edition
        super.init()
    }

    public override func didEnter(from previousState: GKState?) {
        if flightPlan.state != .editable {
            forceEditable()
        }
        edition.setupFlightPlan(flightPlan)
        startAvailabilityWatcher.availabilityForSendingMavlinkPublisher.combineLatest(edition.currentFlightPlanPublisher)
            .sink { [unowned self] in
                let (availability, flightPlan) = $0
                guard let fPlan = flightPlan else { return }
                delegate?.flightPlanIsEditable(fPlan, startAvailability: availability)
            }
            .store(in: &cancellables)
    }

    public func forceEditable() {
        guard flightPlan.state != .editable else { return }
        // there should be only one flightplan in .editable state in one project
        // otherwise delete it

        // get all flight plans which are part of the flightplan project
        let editableFPs = flightPlanManager.editableFlightPlansFor(projectId: flightPlan.projectUuid)
        editableFPs.forEach { (flightplan) in
            flightPlanManager.delete(flightPlan: flightplan)
        }

        // duplicate the flightplan to edit it
        flightPlan = flightPlanManager.newFlightPlan(basedOn: flightPlan, save: true)
        // Reset, if needed, the customTitle to the project title.
        flightPlan = projectManager.resetExecutionCustomTitle(for: flightPlan)
    }

    open func flightPlanWasUpdated(_ flightPlan: FlightPlanModel) {
        self.flightPlan = flightPlan
        edition.setupFlightPlan(flightPlan)
    }

    public override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is StartedNotFlyingState.Type
            || stateClass is IdleState.Type
    }

    public override func willExit(to nextState: GKState) {
        cancellables = []
    }
}
