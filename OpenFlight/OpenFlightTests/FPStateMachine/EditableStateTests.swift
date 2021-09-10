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
import Combine
import GameKit
@testable import OpenFlight

class EditableStateTests: XCTestCase {

    var sut: FlightPlanStateMachineImpl!
    var fpManagerMock: FlightPlanManagerMock!
    var cancellables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        sut = FlightPlanStateMachineImpl()
        fpManagerMock = FlightPlanManagerMock()

        let initialState = InitializingState(stateMachineManager: sut)
        let editable = EditableState(flightPlanManager: fpManagerMock, stateMachineManager: sut)
        let states = [initialState, editable]
        sut.stateMachine = GKStateMachine(states: states)
    }

    override func tearDownWithError() throws {
        sut = nil
        fpManagerMock = nil
    }

    func testEditable() throws {
        let expectation = XCTestExpectation(description: "EditingResponse")

        let editFlightPlan = FlightPlanModell(type: "",
                                         uuid: UUID().uuidString,
                                         version: "",
                                         customTitle: "title",
                                         thumbnailUuid: nil,
                                         projectUuid: UUID().uuidString,
                                         dataStringType: "",
                                         dataString: "",
                                         pgyProjectId: nil,
                                         mediaCustomId: nil,
                                         state: .editable,
                                         lastMissionItemExecuted: 0,
                                         recoveryId: nil,
                                         mediaCount: 0,
                                         uploadedMediaCount: 0,
                                         lastUpdate: Date(),
                                         thumbnail: nil)

        // given
        sut.open(flightPlan: editFlightPlan)
        
        var newState: State = .machineStarted
        sut.statePrivate.sink { (state) in
            switch state {
            case .editable( _):
                newState = state
                expectation.fulfill()
            case .machineStarted: break
            default:
                XCTAssertFalse(true)
            }
        }.store(in: &cancellables)

        // when
        wait(for: [expectation], timeout: 10)

        // then

        // the statemachine stays in this state
        XCTAssertNotNil(sut.stateMachine.currentState as? EditableState)

        if case .editable(let flightPlan) = newState {
            XCTAssertTrue(flightPlan.uuid == self.sut.currentFlightPlan?.uuid)
        } else {
            XCTAssertFalse(true)
        }
    }

    func testCompletedFP() throws {
        let expectation = XCTestExpectation(description: "EditingResponse")

        let editFlightPlan = FlightPlanModell(type: "",
                                         uuid: UUID().uuidString,
                                         version: "",
                                         customTitle: "title",
                                         thumbnailUuid: nil,
                                         projectUuid: UUID().uuidString,
                                         dataStringType: "",
                                         dataString: "",
                                         pgyProjectId: nil,
                                         mediaCustomId: nil,
                                         state: .completed,
                                         lastMissionItemExecuted: 0,
                                         recoveryId: nil,
                                         mediaCount: 0,
                                         uploadedMediaCount: 0,
                                         lastUpdate: Date(),
                                         thumbnail: nil)

        // given
        sut.open(flightPlan: editFlightPlan, resume: true)

        var newState: State = .machineStarted
        sut.statePrivate.sink { (state) in
            switch state {
            case .editable( _):
                newState = state
                expectation.fulfill()
            case .machineStarted: break
            default:
                XCTAssertFalse(true)
            }
        }.store(in: &cancellables)

        // when
        wait(for: [expectation], timeout: 10)

        // then

        // the statemachine stays in this state
        XCTAssertNotNil(sut.stateMachine.currentState as? EditableState)

        if case .editable(let flightPlan) = newState {
            XCTAssertTrue(flightPlan.uuid == self.sut.currentFlightPlan?.uuid)
            XCTAssertTrue(self.sut.currentFlightPlan?.state == .editable)
        } else {
            XCTAssertFalse(true)
        }
    }

    func testNotEditableWithExistingEditable() throws {
        fpManagerMock.editableFPInTheProject = true
        let expectation = XCTestExpectation(description: "EditingResponse")
        // given
        let flyingFlightPlan = FlightPlanModell(type: "",
                                         uuid: UUID().uuidString,
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
        sut.open(flightPlan: flyingFlightPlan)

        var newState: State = .machineStarted
        sut.statePrivate.sink { (state) in
            if case let .editable(_) = state {
                newState = state
                expectation.fulfill()
            }
        }.store(in: &cancellables)

        // when
        wait(for: [expectation], timeout: 10)

        // then
        // Flightplan not in editing mode needs to be duplicated to be edited
        // uuid has to be different
        if case .editable(let flightPlan) = newState {
            XCTAssertTrue(flightPlan.uuid != flyingFlightPlan.uuid)
            XCTAssertTrue(flightPlan.projectUuid == flyingFlightPlan.projectUuid)
            XCTAssertTrue(flightPlan.state == .editable)
        } else {
            XCTAssertFalse(true)
        }
    }

    func testNotEditableWithNoEditable() throws {
        let expectation = XCTestExpectation(description: "EditingResponse")
        // no editable fp in the project (test purpose only)
        fpManagerMock.editableFPInTheProject = false

        // given
        let editFlightPlan = FlightPlanModell(type: "",
                                         uuid: UUID().uuidString,
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
        sut.open(flightPlan: editFlightPlan)

        var newState: State = .machineStarted
        sut.statePrivate.sink { (state) in
            if case .editable(_) = state {
                newState = state
                expectation.fulfill()
            }
        }.store(in: &cancellables)

        // when
        wait(for: [expectation], timeout: 10)

        // then
        // Flightplan not in editing mode needs to be duplicated to be edited
        // uuid has to be different
        if case .editable(let flightPlan) = newState {
            XCTAssertTrue(flightPlan.uuid != editFlightPlan.uuid)
            XCTAssertTrue(flightPlan.projectUuid == editFlightPlan.projectUuid)
            XCTAssertTrue(flightPlan.state == .editable)
        } else {
            XCTAssertFalse(true)
        }
    }

    func testNextPossibleState() {
        let editableState = sut.stateMachine.state(forClass: EditableState.self)
        if let editable = editableState {

            // Possible next state from EditableState
            XCTAssertTrue(editable.isValidNextState(StartedNotFlyingState.self))

            // Impossible state from EditableState
            XCTAssertFalse(editable.isValidNextState(InitializingState.self))
            XCTAssertFalse(editable.isValidNextState(StartedFlyingState.self))
            XCTAssertFalse(editable.isValidNextState(EndedState.self))

        } else {
            XCTAssert(false)
        }
    }
}
