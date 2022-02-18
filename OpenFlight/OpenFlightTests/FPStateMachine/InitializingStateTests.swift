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

import XCTest
import GameKit
import Combine

@testable import OpenFlight

class InitializingStateTests: XCTestCase {

    var sut: FlightPlanStateMachineImpl!
    var cancellables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        sut = FlightPlanStateMachineImpl()
        let initialState = InitializingState(stateMachineManager: sut)
        let editableState = EditableState(stateMachineManager: sut)
        let states = [initialState, editableState]
        sut.stateMachine = GKStateMachine(states: states)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        sut = nil
    }

    func testOpenFlyingFP() throws {
        // given
        let resumeFlightplan = true
        let openFlightPlan = FlightPlanModell(type: "",
                                         uuid: UUID().uuidString,
                                         version: "",
                                         customTitle: "title",
                                         thumbnailUuid: nil,
                                         projectUuid: UUID().uuidString,
                                         dataStringType: "",
                                         dataString: "",
                                         pgyProjectId: nil,
                                         state: .editable,
                                         lastMissionItemExecuted: 0,
                                         recoveryId: nil,
                                         mediaCount: 0,
                                         uploadedMediaCount: 0,
                                         lastUpdate: Date(),
                                         thumbnail: nil)

        // when
        sut.open(flightPlan: openFlightPlan, resume: resumeFlightplan)

        // then
        XCTAssert(openFlightPlan.uuid == sut.currentFlightPlan?.uuid)

        let currentState = sut.stateMachine.currentState as? EditableState
        XCTAssertNotNil(currentState)
        XCTAssert(sut.resumeFlightPlan == resumeFlightplan)
    }

    func testNextPossibleState() throws {
        let initializingState = sut.stateMachine.state(forClass: InitializingState.self)
        if let initializingState = initializingState {
            // Possible next state
            XCTAssertTrue(initializingState.isValidNextState(EditableState.self))

            // Impossible state
            XCTAssertFalse(initializingState.isValidNextState(StartedFlyingState.self))
            XCTAssertFalse(initializingState.isValidNextState(EndedState.self))
            XCTAssertFalse(initializingState.isValidNextState(StartedNotFlyingState.self))
        } else {
            XCTAssert(false)
        }
    }
}
