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

import XCTest
import GameKit
import Combine

@testable import OpenFlight

class EndedStateTests: XCTestCase {

    var sut: FlightPlanStateMachineImpl!
    var cancellables = Set<AnyCancellable>()
    var fpManagerMock: FlightPlanManagerMock!

    override func setUpWithError() throws {
        sut = FlightPlanStateMachineImpl()
        fpManagerMock = FlightPlanManagerMock()

        let initialState = InitializingState(stateMachineManager: sut)
        let end = EndedState(stateMachineManager: sut, flightPlanManager: fpManagerMock)
        let editable = EditableState(flightPlanManager: fpManagerMock, stateMachineManager: sut)
        let states = [initialState, end, editable]
        sut.stateMachine = GKStateMachine(states: states)
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func testFPCompleteAndReadyToEditOrPlayAgain() throws {
        let expectation = XCTestExpectation(description: "EndedResponse")
        let uuid = UUID().uuidString
        
        // given
        let startedFP = FlightPlanModell(type: "",
                                         uuid: uuid,
                                         version: "",
                                         customTitle: "title",
                                         thumbnailUuid: nil,
                                         projectUuid: UUID().uuidString,
                                         dataStringType: "",
                                         dataString: "",
                                         pgyProjectId: nil,
                                         mediaCustomId: nil,
                                         state: .flying,
                                         lastMissionItemExecuted: 0,
                                         recoveryId: nil,
                                         mediaCount: 0,
                                         uploadedMediaCount: 0,
                                         lastUpdate: Date(),
                                         thumbnail: nil)
        sut.currentFlightPlan = startedFP
        var newState: State = .machineStarted
        sut.statePrivate.sink { (state) in
            switch state {
            case .end:
                newState = state
                expectation.fulfill()
            case .machineStarted: break
            case .editable: break
            default:
                XCTAssertFalse(true)
            }
        }.store(in: &cancellables)

        // when
        sut.stateMachine.enter(EndedState.self)
        wait(for: [expectation], timeout: 10)

        // then
        // end flight plan is published
        XCTAssertTrue(newState == .end)

        // Flightplan should be Completed
        XCTAssertTrue(sut.currentFlightPlan?.state == .completed)
    }

    func testNextPossibleState() throws {
        let end = sut.stateMachine.state(forClass: EndedState.self)
        if let endedState = end {
            // Possible next state
            XCTAssertTrue(endedState.isValidNextState(InitializingState.self))

            // Impossible states
            XCTAssertFalse(endedState.isValidNextState(StartedFlyingState.self))
            XCTAssertFalse(endedState.isValidNextState(EditableState.self))
            XCTAssertFalse(endedState.isValidNextState(StartedNotFlyingState.self))
        } else {
            XCTAssert(false)
        }
    }

}
