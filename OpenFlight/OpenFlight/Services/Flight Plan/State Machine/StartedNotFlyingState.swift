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
import GroundSdk

public protocol StartedNotFlyingStateDelegate: AnyObject {

    func mavlinkGenerationStarted(flightPlan: FlightPlanModel)

    func mavlinkSendingStarted(flightPlan: FlightPlanModel)

    func handleMavlinkGenerationError(flightPlan: FlightPlanModel, _ error: MavlinkGenerationError)

    func handleMavlinkSendingError(flightPlan: FlightPlanModel, _ error: MavlinkDroneSenderError)

    func handleMavlinkSendingSuccess(flightPlan: FlightPlanModel, commands: [MavlinkStandard.MavlinkCommand])
}

open class StartedNotFlyingState: GKState {

    private weak var delegate: StartedNotFlyingStateDelegate?
    private let flightPlanManager: FlightPlanManager
    private let projectManager: ProjectManager
    private let mavlinkGenerator: MavlinkGenerator
    private let mavlinkSender: MavlinkDroneSender
    private var stopped = false

    var flightPlan: FlightPlanModel!

    required public init(delegate: StartedNotFlyingStateDelegate,
                         flightPlanManager: FlightPlanManager,
                         projectManager: ProjectManager,
                         mavlinkGenerator: MavlinkGenerator,
                         mavlinkSender: MavlinkDroneSender) {
        self.delegate = delegate
        self.flightPlanManager = flightPlanManager
        self.projectManager = projectManager
        self.mavlinkGenerator = mavlinkGenerator
        self.mavlinkSender = mavlinkSender
        super.init()
    }

    open override func didEnter(from previousState: GKState?) {
        stopped = false

        // if flightPlan is editable, we duplicate the editable flight plan to use like execution.
        if flightPlan.state == .editable {
            // duplicate the flightplan to use like execution
            var newFlightPlan = flightPlanManager.newFlightPlan(basedOn: flightPlan, save: true)
            // update the execution customTitle.
            newFlightPlan = projectManager.updateExecutionCustomTitle(for: newFlightPlan)
            // `newFlightPlan` is no more the project's editable FP.
            // It's the new execution, with the updated custom title, which must be considered as `.flying` state.
            flightPlan = flightPlanManager.update(flightplan: newFlightPlan, with: .flying)
        }

        delegate?.mavlinkGenerationStarted(flightPlan: flightPlan)
        mavlinkGenerator.generateMavlink(for: flightPlan) { [unowned self] in
            guard !stopped else { return }
            switch $0 {
            case .success(let result):
                let flightPlan = result.flightPlan
                delegate?.mavlinkSendingStarted(flightPlan: flightPlan)
                mavlinkSender.sendToDevice(result.path, customFlightPlanId: flightPlan.uuid) { [weak self] in
                    guard let self = self,
                          !self.stopped else {
                        return
                    }
                    switch $0 {
                    case .success:
                        self.delegate?.handleMavlinkSendingSuccess(flightPlan: flightPlan, commands: result.commands)
                    case .failure(let error):
                        self.delegate?.handleMavlinkSendingError(flightPlan: flightPlan, error)
                    }
                }
            case .failure(let error):
                delegate?.handleMavlinkGenerationError(flightPlan: flightPlan, error)
            }
        }
    }

    open func flightPlanWasUpdated(_ flightPlan: FlightPlanModel) {
        self.flightPlan = flightPlan
    }

    open override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is StartedFlyingState.Type
            || stateClass is EditableState.Type
            || stateClass is IdleState.Type
    }

    open override func willExit(to nextState: GKState) {
        stop()
    }

    open func stop() {
        mavlinkSender.cleanup()
        stopped = true
    }
}
